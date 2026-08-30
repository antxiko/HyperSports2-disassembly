#!/usr/bin/env python3
"""Lee los textos del cartucho, que no estan en ASCII sino en tiles.

    python3 tools/textos.py            todas las listas declaradas
    python3 tools/textos.py 0x4791     una sola

El cartucho no guarda una cadena de caracteres: guarda LISTAS DE TILES, y el
numero de tile no es el ASCII. Hay TRES alfabetos, uno por juego de tiles, y
cada uno empieza su A en un sitio:

    0x21 = A ... 0x3A = Z      con los digitos en 0x10-0x19   (blanco, grande)
    0x51 = A ... 0x6A = Z      con los digitos en 0x40-0x49   (el marcador)
    0xD1 = A ... 0xEA = Z      con los digitos en 0xC0-0xC9   (cyan)

y el 0x00 es el espacio en los tres. Se descubre comparando lo que se ve en
pantalla con los bytes: "SCORE" son los tiles 63 53 5F 62 55, y de ahi sale que
la S del alfabeto del marcador es el 0x63.

El formato de la lista lo pone PINTA_LISTA (0x4050): dos bytes con la casilla
de la VRAM donde empieza, luego los tiles, un 0xFE para saltar a otra casilla
(con su palabra detras) y un 0xFF para acabar.
"""
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(RAIZ, "hypersports2.rom")
NOTAS = os.path.join(RAIZ, "src", "hypersports2.notes")
ORG = 0x4000

# (primera letra, primer digito) de cada alfabeto
ALFABETOS = ((0x21, 0x10), (0x51, 0x40), (0xD1, 0xC0))


def caracter(b):
    """El caracter de un tile, probando los tres alfabetos. None si no es letra."""
    if b == 0x00:
        return " "
    for letra, digito in ALFABETOS:
        if letra <= b <= letra + 25:
            return chr(ord("A") + b - letra)
        if digito <= b <= digito + 9:
            return chr(ord("0") + b - digito)
    return None


def lee_lista(rom, a):
    """Devuelve (texto, fin). Los tiles que no son letra salen como punto."""
    p = a - ORG + 2
    out = ""
    while True:
        if p >= len(rom):
            return out, None
        v = rom[p]
        p += 1
        if v == 0xFF:
            return out, p + ORG
        if v == 0xFE:
            p += 2
            out += " / "
            continue
        c = caracter(v)
        out += c if c else "."


def main():
    rom = open(ROM, "rb").read()
    if len(sys.argv) > 1:
        for a in sys.argv[1:]:
            t, f = lee_lista(rom, int(a, 0))
            print("0x%s -> 0x%04X: %s" % (a.replace("0x", "").upper(), f or 0, t))
        return 0
    # todas las listas declaradas en las notas
    n = 0
    for l in open(NOTAS, encoding="utf-8"):
        m = re.match(r"^D (0x[0-9A-Fa-f]+) (0x[0-9A-Fa-f]+) (\S*lista\S*)", l)
        if not m:
            continue
        a = int(m.group(1), 0)
        t, f = lee_lista(rom, a)
        letras = sum(1 for c in t if c.isalnum())
        if letras < 3:
            continue
        print("0x%04X  %s" % (a, t.strip()))
        n += 1
    print("%d listas con texto" % n)
    return 0


if __name__ == "__main__":
    sys.exit(main())
