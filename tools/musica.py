#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `ARRANCA_EL_EFECTO` (0x7844, A = numero; `SUENA_SI_SE_PUEDE`,
0x783E, solo suena en partida) y corre `CORRE_EL_SONIDO` (0x7696), que la
interrupcion llama cada cuadro. Tres voces de 12 bytes desde 0xE010; la copia
del registro 7 del PSG, en 0xE034.
Uso:  musica.py registros 0x9C [cuadros] | mp3 0x9C f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xFF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

TABLA = "ninguna llamada directa: está en la tabla de pistas"

PIEZAS = [
    P(0x99, "Preparados", "Get ready",
      "`SKEET_PASO_0`, `WEIGHT_PASO_2` y `SUENA_AL_LLEGAR`"),
    P(0x9C, "La música del 0x9C", "The tune at 0x9C",
      "`ESTADO_03_SUB1`: sonido 0x9C y 80 fotogramas de espera"),
    P(0x9F, "El aviso de fin", "The end warning", "`AVISA_Y_ESPERA`"),
    P(0xA2, "El rótulo con créditos", "The sign with credits",
      "`MIRA_SI_SIGUE`"),
    P(0xA5, "La pieza del 0x4201", "The tune at 0x4201", "`L_4201`"),
    P(0xA8, "El aviso o la fanfarria", "The warning or the fanfare",
      "`SKEET_PASO_5_FIN`"),
    P(0xAB, "La pantalla de récords", "The records screen",
      "`RECORDS_PASO_0`"),
] + [P(n, "Pista 0x%02X de la tabla" % n, "Table track 0x%02X" % n, TABLA)
     for n in (0x9A, 0x9B, 0x9D, 0x9E, 0xA0, 0xA1, 0xA3, 0xA4, 0xA6, 0xA7,
               0xA9, 0xAA, 0xAC, 0xAD)]

PAGINA = motor_musica.pagina_basica(
    "`CORRE_EL_SONIDO`, 0x7696, y `ARRANCA_EL_EFECTO`, 0x7844, que le reparte "
    "los canales; lo llama la interrupción",
    "`CORRE_EL_SONIDO`, 0x7696, and `ARRANCA_EL_EFECTO`, 0x7844, which hands "
    "it the channels; the interrupt calls it",
    "C-BIOS MSX1 japonés",
    [("la pieza 0x9C, sus primeros 295 cuadros de 296, tal como el juego la "
      "pide",
      "tune 0x9C, its first 295 frames of 296, just as the game asks for it"),
     ("«preparados» (0x99) entero, 50 cuadros",
      "\"get ready\" (0x99), whole, 50 frames"),
     ("la pantalla de récords (0xAB), sus primeros 220 cuadros",
      "the records screen (0xAB), its first 220 frames")],
    [("Cómo se pide una pieza",
      "`ARRANCA_EL_EFECTO` recibe el número en A y reparte el sonido entre "
      "los canales que le tocan, sin pisar a otro de más peso; `SUENA_SI_SE_"
      "PUEDE` hace lo mismo solo con partida (bit 6 de 0xE002). Los números "
      "bajos son efectos y del 0x9A en adelante hay música de tres voces. Las "
      "voces ocupan 12 bytes cada una desde 0xE010 y 0xE034 guarda la copia "
      "del mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de "
      "la tabla» están en la tabla de pistas pero ninguna rutina las pide "
      "con un `ld a`.",
      "How a piece is asked for",
      "`ARRANCA_EL_EFECTO` takes the number in A and shares the sound among "
      "the channels it needs, without overriding a heavier one; "
      "`SUENA_SI_SE_PUEDE` does the same only in a game (bit 6 of 0xE002). "
      "Low numbers are effects and from 0x9A up there is three-voice music. "
      "The voices take 12 bytes each from 0xE010 and 0xE034 holds the copy "
      "of the PSG mixer, which start-up leaves at 0xB8. The tracks marked "
      "«in the table» are in the track table but no routine asks for them "
      "with an `ld a`.")])

CFG = dict(rom="hypersports2.rom", org=0x4000, frame=0x7696, pide=0x7844,
           ram=(0xE010, 0xE037), ram0=[(0xE034, 0xB8)],
           excluye=[0xE019, 0xE025, 0xE031], hz=60, psg0={7: 0xB8},
           piezas=PIEZAS, pagina=PAGINA,
           cotejado=[(0x9C, 296, None), (0x99, 50, None)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
