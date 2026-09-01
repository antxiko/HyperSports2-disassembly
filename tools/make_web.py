#!/usr/bin/env python3
"""Genera la portada de la web, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Las imagenes NO son ilustraciones ni capturas: se dibujan a partir de los
propios bytes de la ROM por tools/graficos.py, ejecutando en Python el mismo
descompresor de rachas, el mismo pintador de listas y el mismo guion del
titulo que corre el Z80. Ninguna se ha retocado.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras salen de contar sobre el listado generado, no de escribirlas a ojo:
# 16384 = 6956 + 9428, que es lo que imprime tools/presupuesto.py (make sanity).
# RUTINAS son las etiquetas de codigo con nombre propio (directiva L del .notes).
# PRUEBAS son las tres del cartucho: SKEET SHOOTING, ARCHERY y WEIGHT LIFTING.
CODIGO = 6956
DATOS = 9428
RUTINAS = 308
PRUEBAS = 3


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Hyper Sports 2 — desensamblado comentado",
        aviso="<b>Aquí no hay ninguna ilustración ni captura.</b> Las pantallas "
              "están <b>dibujadas desde los bytes de la ROM</b>, ejecutando en "
              "Python el mismo descompresor de rachas, el mismo pintador de "
              "listas y el mismo guión del título que corre el Z80. El listado "
              "y las cifras salen del binario y se reproducen con "
              "<code>make</code>.",
        claim="Las tres pruebas de puntería y fuerza de Hyper Sports en un "
              "cartucho de 16 KB: tiro al plato, tiro con arco y halterofilia, "
              "con el juego entero corriendo dentro de la interrupción de cada "
              "cuadro.",
        ficha=["Konami · <b>© Konami 1984</b>",
               "Cartucho <b>RC-717</b>, 16 KB",
               "MSX1 · <b>página 1</b>", "Volcado <b>f4273f52…</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El código"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("EN-EL-EMULADOR.html", "En el emulador"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El cartucho en cifras", h_find="Lo que apareció al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(RUTINAS), "rutinas bautizadas"),
                (str(PRUEBAS), "pruebas"),
                (mil(CODIGO, "es"), "bytes de código"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Debajo de la imagen está de dónde sale y qué se está viendo.",
        pie_leg="Esto es trabajo de documentación y preservación: el código y "
                "los gráficos siguen siendo de sus autores y de Konami, y la "
                "imagen del cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Hyper Sports 2 — a commented disassembly",
        aviso="<b>There is not one illustration or capture here.</b> The "
              "screens are <b>drawn from the bytes of the ROM</b>, by running "
              "in Python the same run-length decompressor, the same list "
              "painter and the same title script the Z80 runs. The listing and "
              "the numbers come from the binary and are reproducible with "
              "<code>make</code>.",
        claim="The three aiming and strength events of Hyper Sports in a 16 KB "
              "cartridge: skeet shooting, archery and weight lifting, with the "
              "whole game running inside the per-frame interrupt.",
        ficha=["Konami · <b>© Konami 1984</b>",
               "An <b>RC-717</b> 16 KB cartridge",
               "MSX1 · <b>page 1</b>", "Dump <b>f4273f52…</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("IN-THE-EMULATOR.html", "In the emulator"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The cartridge in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(RUTINAS), "routines named"),
                (str(PRUEBAS), "events"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Under the picture is where it comes from and what is on it.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Konami, and the "
                "cartridge image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ("Las tres luces del jurado deciden el levantamiento",
         "<p>Con la barra arriba, 0x6F78 enciende <b>una luz cada 0x20 "
         "cuadros</b> en la columna 2, debajo del rótulo <code>JUDGE</code>; a "
         "la tercera pone 0xE071 y 0xE1A3 a uno y el levantamiento vale. Ese "
         "0xE1A3 es luego el que decide el color de la figura, si se copian "
         "unos bytes u otros a la VRAM y qué cifra se pinta: <b>el mismo byte "
         "manda en cinco sitios distintos</b>.</p>"),
        ("El arco acierta con Pitágoras y sin raíz cuadrada",
         "<p>0x5CCF eleva al cuadrado las dos distancias al centro de la diana "
         "(0xBC, 0x53) con ocho sumas y desplazamientos, las suma, y compara "
         "ese cuadrado contra la tabla de 0x5D03, que son <b>los radios de los "
         "nueve anillos ya elevados al cuadrado</b>: 1, 6, 16, 25, 64, 96, 144, "
         "196 y 289. El último no cabe en un byte, y por eso el bucle le pone "
         "el 1 de arriba a mano con un <code>xor a / djnz / inc a</code>.</p>"),
        ("Los platos no salen al azar: están escritos bit a bit",
         "<p>El lanzador lee hacia dónde sale cada plato de la tabla de 0x583E "
         "<b>bit a bit</b>, y su altura de la de 0x5866 <b>de dos en dos "
         "bits</b>, cada una con su propio contador. No hay ninguna semilla ni "
         "ningún reloj de por medio: el cartucho lanza siempre igual.</p>"),
        ("Una octava de doce notas, y las demás doblando",
         "<p>El reproductor guarda <b>doce periodos</b> en 0x7832 —de 0x6A a "
         "0x38— y saca las otras octavas doblando el periodo en 0x7815, que es "
         "exactamente lo que significa bajar una octava. Con el reloj del PSG, "
         "el 0x6A da 1.055 Hz y el 0x38 da 1.998: el do y el si de la misma "
         "octava.</p>"),
        ("Ocho categorías de peso, con sus kilos",
         "<p>En 0x7587 hay ocho nombres de catorce tiles —FLY, BANTAM, FEATHER, "
         "LIGHT y MIDDLE WEIGHT, MIDDLE HEAVY, HEAVY WEIGHT y SUPER HEAVY— y en "
         "0x6F48 sus ocho pesos en BCD: 150, 165, 180, 195, 210, 225, 240 y 260 "
         "kilos. El ángulo del arco, en la otra prueba, sube de <b>0,28 en 0,28 "
         "grados</b> y da la vuelta a los 4,00.</p>"),
        ("No lleva la marca oculta de Konami",
         "<p>Muchos cartuchos de la casa esconden al final de la ROM su número "
         "de catálogo y el título en katakana; lo descubrió <b>Manuel Pazos</b> "
         "(<a href=\"https://twitter.com/ManuelPazosMSX\">@ManuelPazosMSX</a>). "
         "Aquí no está: los últimos 25 bytes son 0xFF de relleno, sin el 0xAA "
         "que cierra la marca. El RC-717 viene del catálogo, no del "
         "binario.</p>"),
    ],
    "en": [
        ("Three judges' lights decide the lift",
         "<p>With the bar up, 0x6F78 turns <b>one light on every 0x20 "
         "frames</b> in column 2, under the <code>JUDGE</code> sign; on the "
         "third it sets 0xE071 and 0xE1A3 to one and the lift is good. That "
         "0xE1A3 then decides the figure's colour, which bytes get copied to "
         "VRAM and which digit is painted: <b>one byte ruling in five different "
         "places</b>.</p>"),
        ("The bow scores with Pythagoras and no square root",
         "<p>0x5CCF squares the two distances to the centre of the target "
         "(0xBC, 0x53) with eight adds and shifts, adds them up, and compares "
         "that square against the table at 0x5D03, which holds <b>the radii of "
         "the nine rings already squared</b>: 1, 6, 16, 25, 64, 96, 144, 196 "
         "and 289. The last one does not fit in a byte, which is why the loop "
         "supplies its top 1 by hand with an <code>xor a / djnz / inc a</code>."
         "</p>"),
        ("The clays are not random: they are written bit by bit",
         "<p>The launcher reads which way each clay goes from the table at "
         "0x583E <b>one bit at a time</b>, and its height from the one at "
         "0x5866 <b>two bits at a time</b>, each with its own counter. There is "
         "no seed and no clock anywhere: the cartridge always throws the "
         "same.</p>"),
        ("One octave of twelve notes, and the rest by doubling",
         "<p>The player keeps <b>twelve periods</b> at 0x7832 —from 0x6A to "
         "0x38— and gets the other octaves by doubling the period at 0x7815, "
         "which is exactly what dropping an octave means. With the PSG clock, "
         "0x6A gives 1,055 Hz and 0x38 gives 1,998: C and B of the same "
         "octave.</p>"),
        ("Eight weight classes, with their kilos",
         "<p>At 0x7587 there are eight names of fourteen tiles each —FLY, "
         "BANTAM, FEATHER, LIGHT and MIDDLE WEIGHT, MIDDLE HEAVY, HEAVY WEIGHT "
         "and SUPER HEAVY— and at 0x6F48 their eight weights in BCD: 150, 165, "
         "180, 195, 210, 225, 240 and 260 kilos. The bow's angle, in the other "
         "event, goes up <b>0.28 degrees at a time</b> and wraps round at "
         "4.00.</p>"),
        ("It does not carry Konami's hidden mark",
         "<p>Many of the house's cartridges hide their catalogue number and the "
         "title in katakana at the end of the ROM; <b>Manuel Pazos</b> "
         "(<a href=\"https://twitter.com/ManuelPazosMSX\">@ManuelPazosMSX</a>) "
         "found it. Here it is absent: the last 25 bytes are 0xFF filler, with "
         "no 0xAA to close the mark. RC-717 comes from the catalogue, not the "
         "binary.</p>"),
    ],
}

GALERIA = [
    ("titulo.png",
     "La pantalla de presentación, montada como la monta el cartucho: los tiles "
     "del logotipo salen del flujo de 0x4AB5, el dibujo del guión de 0x4A2F y "
     "del flujo de 0x4862, y los rótulos de las listas de 0x480C y 0x47C1. Los "
     "tres nombres de prueba son tres filas de dieciséis tiles seguidos desde "
     "0x4791",
     "The title screen, built the way the cartridge builds it: the logo tiles "
     "come from the stream at 0x4AB5, the drawing from the script at 0x4A2F and "
     "the stream at 0x4862, and the labels from the lists at 0x480C and 0x47C1. "
     "The three event names are three rows of sixteen consecutive tiles from "
     "0x4791"),
    ("pantalla_skeet.png",
     "Tiro al plato. El fondo es el flujo de 0x6C52 descomprimido en la tabla "
     "de nombres desde la fila 8; los tiles y sus colores, los dos primeros "
     "punteros de su registro en 0x6C3A; y el marcador de arriba, el flujo de "
     "0x4749 con la lista de rótulos de 0x4712 encima",
     "Skeet shooting. The background is the stream at 0x6C52 decompressed into "
     "the name table from row 8; the tiles and their colours are the first two "
     "pointers of its record at 0x6C3A; and the scoreboard on top is the stream "
     "at 0x4749 with the label list at 0x4712 over it"),
    ("pantalla_archery.png",
     "Tiro con arco, con sus tres marcadores: <code>ANGLE</code> en la fila 10, "
     "<code>WIND</code> abajo y <code>SCORE</code> a su lado. La diana está "
     "centrada en la X 0xBC y la Y 0x53, que son exactamente las dos constantes "
     "contra las que 0x5CCF mide cada flecha",
     "Archery, with its three readouts: <code>ANGLE</code> on row 10, "
     "<code>WIND</code> at the bottom and <code>SCORE</code> beside it. The "
     "target is centred on X 0xBC and Y 0x53, which are exactly the two "
     "constants 0x5CCF measures every arrow against"),
    ("pantalla_weight.png",
     "Halterofilia. A la izquierda, debajo de <code>JUDGE</code>, la columna de "
     "las tres luces que enciende 0x6F78; abajo la barra <code>POWER</code> que "
     "pinta 0x6E24 en la fila 23; en el centro el cartel "
     "<code>CHOOSE CLASS</code> donde 0x756D escribe la categoría; y a la "
     "derecha el de los kilos",
     "Weight lifting. On the left, under <code>JUDGE</code>, the column of "
     "three lights that 0x6F78 turns on; at the bottom the <code>POWER</code> "
     "bar that 0x6E24 paints on row 23; in the middle the "
     "<code>CHOOSE CLASS</code> sign where 0x756D writes the class; and on the "
     "right the one with the kilos"),
    ("sprites_weight.png",
     "Los sprites de la halterofilia, descomprimidos en la tabla de patrones de "
     "sprites tal como los deja el cartucho. Los dos primeros son <b>los dos "
     "discos de la barra</b>: son los que 0x6FCE deja cayendo desde la Y 0x4A "
     "cuando el levantamiento se acaba",
     "The weight lifting sprites, decompressed into the sprite pattern table "
     "just as the cartridge leaves them. The first two are <b>the two plates of "
     "the barbell</b>: they are the ones 0x6FCE drops from Y 0x4A when the lift "
     "is over"),
    ("sprites_archery.png",
     "Los del tiro con arco: los brazos del arco, la flecha y las piezas con "
     "las que se arma el tirador. Salen del flujo de 0x6318, que es el tercer "
     "puntero de su registro en 0x6C3A",
     "The archery ones: the limbs of the bow, the arrow and the pieces the "
     "archer is built from. They come from the stream at 0x6318, the third "
     "pointer of its record at 0x6C3A"),
]


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    # El "logotipo" de la cabecera no es un montaje ni una captura: es el rotulo
    # que el propio cartucho pinta en su pantalla de titulo, sacado ejecutando
    # su lista de 0x480C (graficos.py). Si el PNG no esta, se cae al texto.
    ruta_logo = os.path.join(imgdir, "rotulo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Hyper Sports 2">'
                if os.path.exists(ruta_logo) else "<h1>Hyper Sports 2</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' · '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
