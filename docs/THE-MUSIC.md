# The music

Everything you hear here comes from running the cartridge's own sound engine (`CORRE_EL_SONIDO`, 0x7696, and `ARRANCA_EL_EFECTO`, 0x7844, which hands it the channels; the interrupt calls it) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- tune 0x9C, its first 295 frames of 296, just as the game asks for it;
- "get ready" (0x99), whole, 50 frames;
- the records screen (0xAB), its first 220 frames.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`ARRANCA_EL_EFECTO` takes the number in A and shares the sound among the channels it needs, without overriding a heavier one; `SUENA_SI_SE_PUEDE` does the same only in a game (bit 6 of 0xE002). Low numbers are effects and from 0x9A up there is three-voice music. The voices take 12 bytes each from 0xE010 and 0xE034 holds the copy of the PSG mixer, which start-up leaves at 0xB8. The tracks marked «in the table» are in the track table but no routine asks for them with an `ld a`.

## The tunes

**Get ready** (0x99)

Asked for by `SKEET_PASO_0`, `WEIGHT_PASO_2` y `SUENA_AL_LLEGAR`; lasts 0.8 s.

<audio controls preload="none" src="audio/musica_99.mp3?v=a76c5a81"></audio>

**The tune at 0x9C** (0x9C)

Asked for by `ESTADO_03_SUB1`: sonido 0x9C y 80 fotogramas de espera; lasts 4.9 s.

<audio controls preload="none" src="audio/musica_9C.mp3?v=3381bd8f"></audio>

**The end warning** (0x9F)

Asked for by `AVISA_Y_ESPERA`; lasts 3.5 s.

<audio controls preload="none" src="audio/musica_9F.mp3?v=7b3a4a29"></audio>

**The sign with credits** (0xA2)

Asked for by `MIRA_SI_SIGUE`; lasts 3.7 s.

<audio controls preload="none" src="audio/musica_A2.mp3?v=8dfeb48a"></audio>

**The tune at 0x4201** (0xA5)

Asked for by `L_4201`; lasts 2.8 s.

<audio controls preload="none" src="audio/musica_A5.mp3?v=91002160"></audio>

**The warning or the fanfare** (0xA8)

Asked for by `SKEET_PASO_5_FIN`; lasts 2.4 s.

<audio controls preload="none" src="audio/musica_A8.mp3?v=10995e20"></audio>

**The records screen** (0xAB)

Asked for by `RECORDS_PASO_0`; lasts 19.1 s.

<audio controls preload="none" src="audio/musica_AB.mp3?v=23f38938"></audio>

**Table track 0x9A** (0x9A)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.9 s.

<audio controls preload="none" src="audio/musica_9A.mp3?v=3903d8bb"></audio>

**Table track 0x9B** (0x9B)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.9 s.

<audio controls preload="none" src="audio/musica_9B.mp3?v=b7927e39"></audio>

**Table track 0x9D** (0x9D)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.4 s.

<audio controls preload="none" src="audio/musica_9D.mp3?v=3feb1b04"></audio>

**Table track 0x9E** (0x9E)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.4 s.

<audio controls preload="none" src="audio/musica_9E.mp3?v=9f2f12d7"></audio>

**Table track 0xA0** (0xA0)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 3.7 s.

<audio controls preload="none" src="audio/musica_A0.mp3?v=93ff331a"></audio>

**Table track 0xA1** (0xA1)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 3.7 s.

<audio controls preload="none" src="audio/musica_A1.mp3?v=ed98cac0"></audio>

**Table track 0xA3** (0xA3)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 3.7 s.

<audio controls preload="none" src="audio/musica_A3.mp3?v=0ac5c3d0"></audio>

**Table track 0xA4** (0xA4)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 3.7 s.

<audio controls preload="none" src="audio/musica_A4.mp3?v=a9474ee2"></audio>

**Table track 0xA6** (0xA6)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 2.8 s.

<audio controls preload="none" src="audio/musica_A6.mp3?v=179d61f1"></audio>

**Table track 0xA7** (0xA7)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 2.8 s.

<audio controls preload="none" src="audio/musica_A7.mp3?v=f79cd4d6"></audio>

**Table track 0xA9** (0xA9)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 19.1 s.

<audio controls preload="none" src="audio/musica_A9.mp3?v=deab769d"></audio>

**Table track 0xAA** (0xAA)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 19.1 s.

<audio controls preload="none" src="audio/musica_AA.mp3?v=3f6c094b"></audio>

**Table track 0xAC** (0xAC)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 19.1 s.

<audio controls preload="none" src="audio/musica_AC.mp3?v=148fc2d9"></audio>

**Table track 0xAD** (0xAD)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 18.3 s.

<audio controls preload="none" src="audio/musica_AD.mp3?v=11915be3"></audio>
