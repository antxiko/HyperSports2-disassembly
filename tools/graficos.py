#!/usr/bin/env python3
"""Dibuja para la web lo que el cartucho lleva DENTRO, desde sus propios bytes.

Ninguna de estas imagenes es una captura del emulador ni una ilustracion: se
montan ejecutando en Python los MISMOS pasos que da el Z80 del cartucho.

  - el descompresor de 0x43FB (un byte de cuenta: el 0x00 acaba, el 0x80 trae
    otra direccion de VRAM, con el bit 7 puesto copia n&0x7F bytes literales y
    sin el repite n veces el byte que sigue),
  - el pintador de listas de 0x4050 ([casilla][tiles...], 0xFE salta a otra
    casilla y 0xFF acaba),
  - y el guion del titulo de 0x423C (cada byte una cuenta: con el bit 7 rellena
    ocho casillas y sin el repite el mismo tile).

Luego se lee la VRAM que sale igual que la lee el VDP en SCREEN 2: tabla de
nombres en 0x3800, patrones en 0x2000 y colores en 0x0000, cada uno con sus
TRES TERCIOS independientes. Si algun rango o algun formato estuviera mal, lo
que saldria seria ruido.

No se escribe ninguna direccion a mano: los bloques se buscan por su NOMBRE en
las anotaciones (`D <inicio> <fin> <nombre> ...`), y los flujos de cada prueba
salen de seguir las dos tablas de punteros del propio cartucho.

Uso: graficos.py <rom> <org> <notas> <docs/imagenes>
"""
import os
import re
import struct
import sys
import zlib

# La paleta del TMS9918 tal como la miden las tablas al uso.
PALETA = [
    (0, 0, 0), (0, 0, 0), (62, 184, 73), (116, 208, 125),
    (89, 85, 224), (128, 118, 241), (185, 94, 81), (101, 219, 239),
    (219, 101, 89), (255, 137, 125), (204, 195, 94), (222, 208, 135),
    (58, 162, 65), (183, 102, 181), (204, 204, 204), (255, 255, 255),
]
FONDO = (0x20, 0x20, 0x30)
TINTA = (0xF0, 0xF0, 0xE0)
REJA = (0x38, 0x38, 0x4A)

NOMBRES = 0x3800
PATRONES = 0x2000
COLORES = 0x0000


def png(w, h, px, fn):
    filas = b"".join(b"\x00" + bytes(px[y * w * 3:(y + 1) * w * 3]) for y in range(h))

    def trozo(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)

    with open(fn, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(trozo(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)))
        f.write(trozo(b"IDAT", zlib.compress(filas, 9)))
        f.write(trozo(b"IEND", b""))


class Cartucho:
    def __init__(self, rom, org, notas):
        self.rom = rom
        self.org = org
        self.bloques = {}
        for linea in open(notas, encoding="utf-8"):
            m = re.match(r"^D\s+0x([0-9A-Fa-f]+)\s+0x([0-9A-Fa-f]+)\s+(\S+)", linea)
            if m:
                self.bloques.setdefault(m.group(3), (int(m.group(1), 16), int(m.group(2), 16)))

    def bloque(self, nombre):
        if nombre not in self.bloques:
            raise SystemExit("  no hay ningun bloque llamado %r en las anotaciones" % nombre)
        return self.bloques[nombre]

    def b(self, a):
        return self.rom[a - self.org]

    def w(self, a):
        return self.b(a) | (self.b(a + 1) << 8)


class Pantalla:
    """Una VRAM de 16 KB y las tres operaciones que el cartucho sabe hacer."""

    def __init__(self, cart):
        self.c = cart
        self.v = bytearray(0x4000)

    # --- descompresor de 0x43FB -------------------------------------------
    def flujo(self, p, vram):
        c = self.c
        while True:
            n = c.b(p)
            cuenta = n & 0x7F
            p += 1
            if n == 0:
                return p
            if n == 0x80:                       # otra direccion de VRAM
                vram = c.w(p) & 0x3FFF
                p += 2
                continue
            if n & 0x80:                        # copia literal
                for i in range(cuenta):
                    self.v[(vram + i) & 0x3FFF] = c.b(p + i)
                p += cuenta
            else:                               # relleno
                x = c.b(p)
                p += 1
                for i in range(cuenta):
                    self.v[(vram + i) & 0x3FFF] = x
            vram = (vram + cuenta) & 0x3FFF

    def flujo_con_direccion(self, p):
        """Entrando por 0x43F5: el flujo trae delante su destino."""
        return self.flujo(p + 2, self.c.w(p) & 0x3FFF)

    def repite_en_tercios(self, p, vram, cuantos):
        for k in range(cuantos):
            self.flujo(p, (vram + k * 0x800) & 0x3FFF)

    # --- pintador de listas de 0x4050 -------------------------------------
    def lista(self, p):
        c = self.c
        while True:
            vram = c.w(p) & 0x3FFF
            p += 2
            while True:
                x = c.b(p)
                p += 1
                if x == 0xFF:
                    return p
                if x == 0xFE:
                    break
                self.v[vram] = x
                vram += 1

    # --- guion del titulo de 0x423C ---------------------------------------
    def guion(self, p, vram):
        """Cada byte es una cuenta. Con el bit 7 puesto rellena ocho casillas
        con el byte que sigue; sin el, repite ocho bytes (un tile entero) esa
        cantidad de veces. El 0x00 lo cierra."""
        c = self.c
        while True:
            n = c.b(p)
            p += 1
            if n == 0:
                return
            if n & 0x80:
                x = c.b(p)
                for _ in range(n - 0x80):
                    for i in range(8):
                        self.v[(vram + i) & 0x3FFF] = x
                    vram += 8
                p += 1
            else:
                for _ in range(n):
                    for i in range(8):
                        self.v[(vram + i) & 0x3FFF] = c.b(p + i)
                    vram += 8
                p += 8

    def rellena(self, vram, cuantos, x):
        for i in range(cuantos):
            self.v[(vram + i) & 0x3FFF] = x

    def copia(self, origen, vram, cuantos):
        for i in range(cuantos):
            self.v[(vram + i) & 0x3FFF] = self.c.b(origen + i)

    # --- lo que ve el VDP --------------------------------------------------
    def dibuja(self, fn, esc=2):
        w, h = 256 * esc, 192 * esc
        px = bytearray(w * h * 3)
        for fila in range(24):
            tercio = fila // 8
            for col in range(32):
                t = self.v[NOMBRES + fila * 32 + col]
                pb = PATRONES + tercio * 0x800 + t * 8
                cb = COLORES + tercio * 0x800 + t * 8
                for f in range(8):
                    linea = self.v[pb + f]
                    color = self.v[cb + f]
                    tinta, papel = PALETA[color >> 4], PALETA[color & 15]
                    for x in range(8):
                        c = tinta if (linea >> (7 - x)) & 1 else papel
                        for dy in range(esc):
                            base = (((fila * 8 + f) * esc + dy) * w + (col * 8 + x) * esc) * 3
                            for dx in range(esc):
                                px[base + dx * 3:base + dx * 3 + 3] = bytes(c)
        png(w, h, px, fn)


def hoja_de_sprites(v, fn, cols=8, esc=3, margen=1):
    """Los sprites de 16x16 de la tabla de patrones, en blanco y negro: el
    color no vive con el dibujo, viene en la ficha de cada sprite."""
    n = 64
    celda = 16 * esc + margen
    w, h = cols * celda + margen, (n // cols) * celda + margen
    px = bytearray(bytes(REJA) * (w * h))

    def pon(x, y, c):
        if 0 <= x < w and 0 <= y < h:
            i = (y * w + x) * 3
            px[i:i + 3] = bytes(c)

    for k in range(n):
        gx = margen + (k % cols) * celda
        gy = margen + (k // cols) * celda
        base = 0x1800 + k * 4 * 8
        for f in range(16):
            izq, der = v[base + f], v[base + 16 + f]
            for c in range(16):
                bit = (izq >> (7 - c)) & 1 if c < 8 else (der >> (15 - c)) & 1
                col = TINTA if bit else FONDO
                for a in range(esc):
                    for b in range(esc):
                        pon(gx + c * esc + b, gy + f * esc + a, col)
    png(w, h, px, fn)


def fuente_y_patrones(p, cart):
    """CARGA_LA_FUENTE (0x43D8) y CARGA_LOS_PATRONES (0x4428), en ese orden."""
    fuente = cart.bloque("flujo_4521")[0] + 2      # el flujo, sin su cabecera
    colores = cart.bloque("colores_de_la_fuente")[0]
    p.flujo(fuente, 0x2200)
    p.rellena(0x0200, 0x180, 0x80)
    p.flujo_con_direccion(cart.bloque("rle_466E")[0])
    p.flujo_con_direccion(cart.bloque("rle_46F5")[0])
    p.repite_en_tercios(fuente, 0x2080, 3)
    p.repite_en_tercios(colores, 0x0080, 3)


def main(argv):
    if len(argv) < 5:
        print(__doc__)
        return 2
    rom = open(argv[1], "rb").read()
    org = int(argv[2], 0)
    cart = Cartucho(rom, org, argv[3])
    destino = argv[4]
    os.makedirs(destino, exist_ok=True)

    # --- el titulo ---------------------------------------------------------
    # ESTADO_00: MONTA_LA_PANTALLA (0x421B) y luego PINTA_LOS_ROTULOS (0x437E).
    p = Pantalla(cart)
    # PREPARA_LA_CORTINILLA (0x4A65): los tiles del logotipo en los tres tercios
    p.repite_en_tercios(cart.bloque("tiles_del_logotipo")[0], 0x2300, 3)
    for k in range(3):
        p.rellena(0x0300 + k * 0x800, 0xD0, 0xF0)
    fuente_y_patrones(p, cart)
    p.flujo_con_direccion(cart.bloque("flujo_4521")[0])
    p.rellena(0x1600, 0x180, 0x70)
    p.guion(cart.bloque("guion_del_titulo")[0], 0x0600)
    p.flujo_con_direccion(cart.bloque("flujo_del_titulo")[0])
    p.lista(cart.bloque("lista_480C")[0])
    p.lista(cart.bloque("lista_47C1")[0])
    filas = cart.bloque("nombres_de_las_pruebas")[0]
    for i in range(3):                             # tres filas, dos de separacion
        p.copia(filas + i * 16, 0x3968 + i * 0x40, 16)
    p.dibuja(os.path.join(destino, "titulo.png"))
    print("  titulo.png: la pantalla de presentacion, montada con el guion de 0x4A2F")

    # --- las tres pruebas --------------------------------------------------
    pruebas = cart.bloque("tabla_de_las_pruebas")[0]
    fondos = cart.bloque("tabla_de_tres_palabras")[0]
    marcador = cart.bloque("rle_4749")[0]
    rotulos = cart.bloque("lista_4712")[0]
    for i, nombre in enumerate(("skeet", "archery", "weight")):
        p = Pantalla(cart)
        fuente_y_patrones(p, cart)
        # CARGA_LOS_TRES_FLUJOS (0x6C0A): patrones, colores y sprites
        p.repite_en_tercios(cart.w(pruebas + i * 6), 0x2A00, 2)
        p.repite_en_tercios(cart.w(pruebas + i * 6 + 2), 0x0A00, 2)
        p.flujo(cart.w(pruebas + i * 6 + 4), 0x1800)
        # PINTA_EL_MARCADOR (0x42FD) y PINTA_EL_FONDO_DE_LA_PRUEBA (0x4288)
        p.flujo_con_direccion(marcador)
        p.lista(rotulos)
        p.flujo(cart.w(fondos + i * 2), 0x3900)
        p.dibuja(os.path.join(destino, "pantalla_%s.png" % nombre))
        hoja_de_sprites(p.v, os.path.join(destino, "sprites_%s.png" % nombre))
        print("  pantalla_%s.png y sprites_%s.png: los tres flujos de la prueba %d"
              % (nombre, nombre, i))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
