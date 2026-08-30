# Open questions

The binary is explained down to the last byte and it reassembles into the ROM.
That does not mean everything is understood. What is still open, said plainly:

## The archer's six sprite records

`COLOCA_LAS_SEIS_FICHAS` (0x5E4D) copies the 24 bytes at 0x5E59 into 0xE0C4 with
no arithmetic at all: six sprite records with X 0xE4 and 0xE8, at the right edge
of the screen, and patterns 0x64, 0x68, 0x6C, 0x70 and 0x18. Drawn from the ROM,
0x68 and 0x74 are a figure with its arms out, and 0x70 and 0x78 look like legs;
`ALTERNA_DOS_PATRONES` (0x5E35) swaps between the two pairs every eight frames.
It looks like a figure running, but the moment it appears on screen has not been
caught, so this site does not claim what it is.

## What 0xE075 holds

`ELIGE_LA_CATEGORIA` (0x75F7) walks the eight weight classes in a ring, and when
it wraps it does not go back to zero: it takes the value at 0xE075. Which class
that is, and who writes it, is not settled.

## The two motors of the archery

0xE147 picks between two routines that move the same thing: `AVANZA_Y_REMATA`
(0x5DE8) and `ANDA_DE_UN_LADO_A_OTRO` (0x5BDB). Both are commented for what they
do, one instruction at a time, but which one runs in which situation has not
been watched happening.

## The fourth graphics record and the third background

The table at 0x6C3A has **four** records of three pointers; the one at 0x42A0,
which holds the name-table backgrounds, has **three** words. The fourth graphics
record is the records screen, which never asks for a background — but if
0xE080 & 3 ever reached 3 with `CAMBIA_DE_PRUEBA` running, the background table
would be read one word past its end, at 0x42A6, which is the first instruction
of `APAGA_EL_PRIMER_SPRITE`. Reading the state machine it does not look
reachable: the `bit 2` test at 0x41FB bumps 0xE080 past that value first. It has
not been proved by running it.

## What the demo does

Bit 6 of 0xE002 marks the demo, and 0xE1AB makes a shot only count without
breaking anything. How long the demo lasts, and what it plays, has not been
timed.

## The name of the third of the three alphabets

`tools/textos.py` reads the cartridge's text with three tile bases: 0x21, 0x51
and 0xD1 all stand for `A`. The first two are the two halves of the scoreboard
font; where the third one is used has not been pinned down beyond the title
screen's `PUSH SPACE KEY TO START`.

---

If you can close any of these, the listing is set up so that an answer is one
line in `src/hypersports2.notes` and a `make`.
