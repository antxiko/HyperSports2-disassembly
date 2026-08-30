#!/usr/bin/env python3
"""Recorre los bloques de datos con el MISMO formato que usa el cartucho.

    python3 tools/recorre.py

Un rango de datos no se declara porque sobre: se declara porque hay una
instruccion que lo lee y porque, leido con el formato que esa instruccion
espera, CIERRA donde tiene que cerrar.

Los consumidores de este cartucho, sacados del listado:

    0x43C9  COPIA_A_VRAM     DE origen, HL la VRAM, BC cuantos
    0x43B2  RELLENA_VRAM     no lee ROM (rellena con A)
    0x43FB  RLE_EN_HL        DE el flujo, HL la VRAM ya puesta
    0x43F5  RLE_CON_DIRECCION  DE apunta a [VRAM][flujo]
    0x4050  PINTA_LISTA      HL = [VRAM][tiles...] con 0xFE para saltar y 0xFF
                             para acabar

El flujo comprimido va asi: un byte de cuenta; el 0x00 acaba; el 0x80 arranca
otra direccion de VRAM (que viene en las dos siguientes); con el bit 7 puesto
se copian n&0x7F bytes tal cual, y sin el se repite n veces el byte siguiente.

La salida son lineas `D` listas para el fichero de notas, cada una con la
instruccion que la justifica.
"""
import json
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(AQUI)
sys.path.insert(0, AQUI)
from z80trace import Tracer                                   # noqa: E402

ORG, FIN = 0x4000, 0x8000
ROM = os.path.join(RAIZ, "hypersports2.rom")
TRAZA = os.path.join(RAIZ, "work", "hypersports2.trace.json")

COPIA = 0x43C9
RELLENA = 0x43B2
RLE_EN_HL = 0x43FB
RLE_CON_DIR = 0x43F5
PINTA_LISTA = 0x4050

LD_INM = {0x21: "hl", 0x11: "de", 0x01: "bc"}


def instrucciones(rom, traza):
    t = Tracer(rom, ORG)
    out = []
    for k, a, b in json.load(open(traza))["blocks"]:
        if k != "c":
            continue
        p = a
        while p < b:
            n = t.ilen(p)
            if not n or p + n > b:
                break
            out.append((p, n))
            p += n
    return out


def rle(rom, p, con_direccion):
    """Devuelve (fin, bytes de VRAM escritos) o (None, motivo)."""
    esc = 0
    if con_direccion:
        p += 2
    while True:
        if not 0 <= p - ORG < len(rom):
            return None, "se sale del cartucho"
        n = rom[p - ORG]
        p += 1
        c = n & 0x7F
        if n == 0:
            return p, esc
        if n == 0x80:
            p += 2                      # otra direccion de VRAM
            continue
        if n & 0x80:
            p += c
        else:
            p += 1
        esc += c


def lista(rom, p):
    """[VRAM][tiles...]: 0xFE arranca otra, 0xFF acaba."""
    p += 2
    n = 0
    while True:
        if not 0 <= p - ORG < len(rom):
            return None, "se sale del cartucho"
        v = rom[p - ORG]
        p += 1
        if v == 0xFF:
            return p, n
        if v == 0xFE:
            p += 2
            continue
        n += 1


def main():
    rom = open(ROM, "rb").read()
    ins = instrucciones(rom, TRAZA)

    def antes(i, reg, cuantas=14):
        for j in range(i - 1, max(-1, i - cuantas) - 1, -1):
            a, n = ins[j]
            if LD_INM.get(rom[a - ORG]) == reg and n == 3:
                return rom[a - ORG + 1] | (rom[a - ORG + 2] << 8)
        return None

    salida = []
    for i, (a, n) in enumerate(ins):
        if rom[a - ORG] != 0xCD:
            continue
        dst = rom[a - ORG + 1] | (rom[a - ORG + 2] << 8)
        if dst == COPIA:
            src, cuantos = antes(i, "de"), antes(i, "bc")
            vram = antes(i, "hl")
            if src is None or cuantos is None or not ORG <= src < FIN:
                continue
            salida.append((src, src + cuantos, "copia", a,
                           "%d bytes que 0x%04X copia a la VRAM 0x%04X"
                           % (cuantos, a, vram or 0)))
        elif dst in (RLE_EN_HL, RLE_CON_DIR):
            src = antes(i, "de")
            if src is None or not ORG <= src < FIN:
                continue
            fin, esc = rle(rom, src, dst == RLE_CON_DIR)
            if fin is None:
                continue
            vram = antes(i, "hl")
            salida.append((src, fin, "rle", a,
                           "flujo comprimido que 0x%04X suelta en %d bytes de VRAM%s"
                           % (a, esc,
                              (" desde 0x%04X" % vram) if dst == RLE_EN_HL and vram else
                              ", con su direccion delante")))
        elif dst == PINTA_LISTA:
            src = antes(i, "hl")
            if src is None or not ORG <= src < FIN:
                continue
            fin, cuantos = lista(rom, src)
            if fin is None:
                continue
            salida.append((src, fin, "lista", a,
                           "lista de %d tiles con su VRAM delante, la pinta 0x%04X"
                           % (cuantos, a)))

    vistos = {}
    for ini, fin, clase, sitio, texto in salida:
        vistos.setdefault((ini, fin, clase), []).append((sitio, texto))
    print("%d bloques distintos, de %d llamadas\n" % (len(vistos), len(salida)))
    for (ini, fin, clase) in sorted(vistos):
        sitios = vistos[(ini, fin, clase)]
        print("D 0x%04X 0x%04X %s_%04X %s   <- %s"
              % (ini, fin, clase, ini, sitios[0][1],
                 " ".join("0x%04X" % s for s, _ in sitios)))


if __name__ == "__main__":
    main()
