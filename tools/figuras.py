#!/usr/bin/env python3
"""Dibuja las FIGURAS del cartucho con su color, no los patrones sueltos.

En el MSX1 un patron de sprite no tiene color: el color va en la FICHA, un
byte por sprite. Y casi ninguna figura del juego es un sprite solo; el
pinguino del tiro con arco son TRES superpuestos en la misma casilla, uno azul,
otro blanco y otro amarillo. Una hoja de los 64 patrones en blanco y negro
ensena piezas sueltas: esto ensena lo que se ve en la pantalla.

De donde sale cada cosa, sin escribir una sola direccion a mano:

  - los PATRONES, del tercer puntero del registro de la prueba en la tabla de
    0x6C3A, descomprimido en la VRAM 0x1800 igual que hace 0x6C0A;
  - las FICHAS (posicion, patron y color), de los mismos bytes que el cartucho
    copia con sus ldir: 0x4BF3 la escopeta, 0x4C3D el arquero y 0x5E59 la
    manzana y el pinguino;
  - y para los platos y los bichos del tiro al plato, que no tienen ficha fija,
    de la tabla de parejas (patron, color) de 0x511D que 0x5108 indexa por la
    postura de la ranura.

El orden importa: en el MSX1 manda el sprite de numero MAS BAJO, asi que se
pintan del ultimo al primero para que el primero quede encima.

Uso: figuras.py <rom> <org> <notas> <docs/imagenes>
"""
import os
import sys

import graficos as G

FONDO = (0x20, 0x20, 0x30)
REJA = (0x38, 0x38, 0x4A)


def patrones_de_la_prueba(cart, i):
    """La tabla de patrones de sprites de la prueba i, como la deja 0x6C0A."""
    p = G.Pantalla(cart)
    p.flujo(cart.w(cart.bloque("tabla_de_las_pruebas")[0] + i * 6 + 4), 0x1800)
    return p.v


def fichas(cart, inicio, cuantas):
    """Lee `cuantas` fichas de sprite seguidas de la ROM: Y, X, patron, color."""
    return [tuple(cart.b(inicio + k * 4 + j) for j in range(4))
            for k in range(cuantas)]


def pinta_figura(v, fichas, esc=6, margen=8, ancho=None, alto=None, y0=None, x0=None):
    """Las fichas dadas, con sus Y y X relativas y cada una con SU color.

    Devuelve (w, h, px) listo para graficos.png()."""
    vivas = [f for f in fichas if f[0] < 0xC0 and f[3] & 0x0F]
    if not vivas:
        raise SystemExit("  no hay ninguna ficha visible")
    if y0 is None:
        y0 = min(f[0] for f in vivas)
    if x0 is None:
        x0 = min(f[1] for f in vivas)
    if ancho is None:
        ancho = max(f[1] for f in vivas) - x0 + 16
    if alto is None:
        alto = max(f[0] for f in vivas) - y0 + 16

    w, h = ancho * esc + margen * 2, alto * esc + margen * 2
    px = bytearray(bytes(FONDO) * (w * h))

    def pon(x, y, c):
        if 0 <= x < w and 0 <= y < h:
            i = (y * w + x) * 3
            px[i:i + 3] = bytes(c)

    # Del ultimo al primero: en el MSX1 el sprite de numero mas bajo va encima
    for y, x, patron, color in reversed(vivas):
        col = G.PALETA[color & 0x0F]
        base = 0x1800 + (patron & 0xFC) * 8
        for f in range(16):
            izq, der = v[base + f], v[base + 16 + f]
            fila = (izq << 8) | der
            for c in range(16):
                if not (fila >> (15 - c)) & 1:
                    continue
                gx = margen + (x - x0 + c) * esc
                gy = margen + (y - y0 + f) * esc
                for a in range(esc):
                    for b in range(esc):
                        pon(gx + b, gy + a, col)
    return w, h, px


def tira(v, piezas, fn, esc=5, hueco=20, margen=10):
    """Varias figuras una al lado de otra, cada una con su propio marco."""
    trozos = [pinta_figura(v, f, esc=esc, margen=0) for _, f in piezas]
    w = sum(t[0] for t in trozos) + hueco * (len(trozos) - 1) + margen * 2
    h = max(t[1] for t in trozos) + margen * 2
    px = bytearray(bytes(FONDO) * (w * h))
    x = margen
    for tw, th, tpx in trozos:
        oy = margen + (h - margen * 2 - th) // 2
        for y in range(th):
            i = ((oy + y) * w + x) * 3
            px[i:i + tw * 3] = tpx[y * tw * 3:(y + 1) * tw * 3]
        x += tw + hueco
    G.png(w, h, px, fn)
    return [n for n, _ in piezas]


def main(argv):
    if len(argv) < 5:
        print(__doc__)
        return 2
    rom = open(argv[1], "rb").read()
    cart = G.Cartucho(rom, int(argv[2], 0), argv[3])
    destino = argv[4]
    os.makedirs(destino, exist_ok=True)

    # --- tiro al plato: el plato, el pulpo y el pajaro ---------------------
    # Los tres no tienen ficha fija: 0x5108 saca su (patron, color) de la tabla
    # de 0x511D indexando por la postura de la ranura, y la Y y la X salen de la
    # propia ranura. Las del pulpo y el pajaro estan escritas en la ROM.
    v = patrones_de_la_prueba(cart, 0)
    pares = cart.bloque("patron_y_color_por_postura")[0]

    def por_postura(n, y=0, x=0):
        return (y, x, cart.b(pares + n * 2), cart.b(pares + n * 2 + 1))

    tira(v, [("plato", [por_postura(1)]),
             ("pulpo", [por_postura(4)]),
             ("pajaro", [por_postura(5)]),
             ("pajaro batiendo", [por_postura(7)]),
             ("la otra ranura", [por_postura(6)])],
         os.path.join(destino, "secreto_skeet.png"))
    print("  secreto_skeet.png: el plato, el pulpo y el pajaro, con el color"
          " que les da la tabla de 0x511D")

    # --- tiro con arco: la manzana y el pinguino ---------------------------
    # Las seis fichas que 0x5E4D copia con un ldir a 0xE0C4. La manzana va sola;
    # el pinguino son tres fichas en la MISMA casilla, cada una de un color.
    v = patrones_de_la_prueba(cart, 1)
    seis = fichas(cart, cart.bloque("las_fichas_del_secreto")[0], 6)
    manzana, pinguino = seis[0:1], seis[1:4]
    # 0x5E35 alterna el cuerpo (0x68/0x74) y las patas (0x70/0x78) cada ocho
    # fotogramas: la otra mitad del paso del pinguino
    otro = [(y, x, {0x68: 0x74, 0x70: 0x78}.get(p, p), c)
            for y, x, p, c in pinguino]
    tira(v, [("manzana", manzana),
             ("pinguino", pinguino),
             ("el otro paso", otro),
             ("los tres sueltos", [(y, x + i * 18, p, c)
                                   for i, (y, x, p, c) in enumerate(pinguino)])],
         os.path.join(destino, "secreto_archery.png"))
    print("  secreto_archery.png: la manzana y el pinguino de las seis fichas"
          " de 0x5E59, y sus tres capas por separado")

    # --- las dos figuras fijas, para que se vea que no es cosa del secreto --
    v = patrones_de_la_prueba(cart, 1)
    arquero = fichas(cart, cart.bloque("treinta_y_dos_a_e0c0")[0], 8)
    v0 = patrones_de_la_prueba(cart, 0)
    escopeta = fichas(cart, cart.bloque("ocho_a_e0c0")[0], 2)
    trozos = [pinta_figura(v, arquero[1:7], esc=5, margen=0),
              pinta_figura(v0, escopeta, esc=5, margen=0)]
    w = sum(t[0] for t in trozos) + 6 + 16
    h = max(t[1] for t in trozos) + 16
    px = bytearray(bytes(FONDO) * (w * h))
    x = 8
    for tw, th, tpx in trozos:
        oy = 8 + (h - 16 - th) // 2
        for y in range(th):
            i = ((oy + y) * w + x) * 3
            px[i:i + tw * 3] = tpx[y * tw * 3:(y + 1) * tw * 3]
        x += tw + 6
    G.png(w, h, px, os.path.join(destino, "figuras_por_capas.png"))
    print("  figuras_por_capas.png: el arquero de 0x4C3D y la escopeta de"
          " 0x4BF3, montados con las capas y los colores de sus fichas")

    # --- halterofilia: las flores -----------------------------------------
    # El tercer secreto no son sprites, son TILES: REMATE_DEL_WEIGHT (0x5065)
    # rellena doce casillas de la fila 16 con el tile 0x91 y doce de la 17 con
    # el 0x92, y ahi aparece el arriate sobre el podio.
    pruebas = cart.bloque("tabla_de_las_pruebas")[0]
    fondos = cart.bloque("tabla_de_tres_palabras")[0]
    p = G.Pantalla(cart)
    G.fuente_y_patrones(p, cart)
    p.repite_en_tercios(cart.w(pruebas + 2 * 6), 0x2A00, 2)
    p.repite_en_tercios(cart.w(pruebas + 2 * 6 + 2), 0x0A00, 2)
    p.flujo(cart.w(pruebas + 2 * 6 + 4), 0x1800)
    p.flujo(cart.w(fondos + 2 * 2), 0x3900)
    for k in range(12):                        # 0x5071: fila 16, columna 7
        p.v[0x3A07 + k] = 0x91
        p.v[0x3A27 + k] = 0x92                 # 0x5079: la fila de al lado
    p.recorta(os.path.join(destino, "secreto_weight.png"), 14, 19, 4, 22, 6)
    print("  secreto_weight.png: las flores que REMATE_DEL_WEIGHT (0x5065)"
          " pinta sobre el podio con los tiles 0x91 y 0x92")
    return 0


if __name__ == "__main__":
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    sys.exit(main(sys.argv))
