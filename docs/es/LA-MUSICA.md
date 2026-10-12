# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`CORRE_EL_SONIDO`, 0x7696, y `ARRANCA_EL_EFECTO`, 0x7844, que le reparte los canales; lo llama la interrupción) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la pieza 0x9C, sus primeros 295 cuadros de 296, tal como el juego la pide;
- «preparados» (0x99) entero, 50 cuadros;
- la pantalla de récords (0xAB), sus primeros 220 cuadros.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`ARRANCA_EL_EFECTO` recibe el número en A y reparte el sonido entre los canales que le tocan, sin pisar a otro de más peso; `SUENA_SI_SE_PUEDE` hace lo mismo solo con partida (bit 6 de 0xE002). Los números bajos son efectos y del 0x9A en adelante hay música de tres voces. Las voces ocupan 12 bytes cada una desde 0xE010 y 0xE034 guarda la copia del mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la tabla» están en la tabla de pistas pero ninguna rutina las pide con un `ld a`.

## Las músicas

**Preparados** (0x99)

Lo pide `SKEET_PASO_0`, `WEIGHT_PASO_2` y `SUENA_AL_LLEGAR`; dura 0,8 s.

<audio controls preload="none" src="../audio/musica_99.mp3?v=a76c5a81"></audio>

**La música del 0x9C** (0x9C)

Lo pide `ESTADO_03_SUB1`: sonido 0x9C y 80 fotogramas de espera; dura 4,9 s.

<audio controls preload="none" src="../audio/musica_9C.mp3?v=3381bd8f"></audio>

**El aviso de fin** (0x9F)

Lo pide `AVISA_Y_ESPERA`; dura 3,5 s.

<audio controls preload="none" src="../audio/musica_9F.mp3?v=7b3a4a29"></audio>

**El rótulo con créditos** (0xA2)

Lo pide `MIRA_SI_SIGUE`; dura 3,7 s.

<audio controls preload="none" src="../audio/musica_A2.mp3?v=8dfeb48a"></audio>

**La pieza del 0x4201** (0xA5)

Lo pide `L_4201`; dura 2,8 s.

<audio controls preload="none" src="../audio/musica_A5.mp3?v=91002160"></audio>

**El aviso o la fanfarria** (0xA8)

Lo pide `SKEET_PASO_5_FIN`; dura 2,4 s.

<audio controls preload="none" src="../audio/musica_A8.mp3?v=10995e20"></audio>

**La pantalla de récords** (0xAB)

Lo pide `RECORDS_PASO_0`; dura 19,1 s.

<audio controls preload="none" src="../audio/musica_AB.mp3?v=23f38938"></audio>

**Pista 0x9A de la tabla** (0x9A)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,9 s.

<audio controls preload="none" src="../audio/musica_9A.mp3?v=3903d8bb"></audio>

**Pista 0x9B de la tabla** (0x9B)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,9 s.

<audio controls preload="none" src="../audio/musica_9B.mp3?v=b7927e39"></audio>

**Pista 0x9D de la tabla** (0x9D)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,4 s.

<audio controls preload="none" src="../audio/musica_9D.mp3?v=3feb1b04"></audio>

**Pista 0x9E de la tabla** (0x9E)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,4 s.

<audio controls preload="none" src="../audio/musica_9E.mp3?v=9f2f12d7"></audio>

**Pista 0xA0 de la tabla** (0xA0)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 3,7 s.

<audio controls preload="none" src="../audio/musica_A0.mp3?v=93ff331a"></audio>

**Pista 0xA1 de la tabla** (0xA1)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 3,7 s.

<audio controls preload="none" src="../audio/musica_A1.mp3?v=ed98cac0"></audio>

**Pista 0xA3 de la tabla** (0xA3)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 3,7 s.

<audio controls preload="none" src="../audio/musica_A3.mp3?v=0ac5c3d0"></audio>

**Pista 0xA4 de la tabla** (0xA4)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 3,7 s.

<audio controls preload="none" src="../audio/musica_A4.mp3?v=a9474ee2"></audio>

**Pista 0xA6 de la tabla** (0xA6)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 2,8 s.

<audio controls preload="none" src="../audio/musica_A6.mp3?v=179d61f1"></audio>

**Pista 0xA7 de la tabla** (0xA7)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 2,8 s.

<audio controls preload="none" src="../audio/musica_A7.mp3?v=f79cd4d6"></audio>

**Pista 0xA9 de la tabla** (0xA9)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 19,1 s.

<audio controls preload="none" src="../audio/musica_A9.mp3?v=deab769d"></audio>

**Pista 0xAA de la tabla** (0xAA)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 19,1 s.

<audio controls preload="none" src="../audio/musica_AA.mp3?v=3f6c094b"></audio>

**Pista 0xAC de la tabla** (0xAC)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 19,1 s.

<audio controls preload="none" src="../audio/musica_AC.mp3?v=148fc2d9"></audio>

**Pista 0xAD de la tabla** (0xAD)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 18,3 s.

<audio controls preload="none" src="../audio/musica_AD.mp3?v=11915be3"></audio>
