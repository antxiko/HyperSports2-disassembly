# Findings

Everything here is measured against the binary. Where a number appears, the
address it came from is next to it.

## Three judges' lights, and one byte ruling five places

The lift is not decided by the power bar. With the bar up, `CUENTA_LAS_LUCES_DEL_JURADO`
(0x6F78) turns **one light on every 0x20 frames** in column 2, right under the
`JUDGE` sign, and at the third it sets 0xE071 and 0xE1A3 to one.

That 0xE1A3 is then read in five different places: it decides whether the mark
is copied into the attempt's points (0x520B), whether the posture can be raised
(0x5231), which of two sixteen-byte blocks goes to VRAM (0x50AF), which pattern
blinks (0x50C8) and whether the digit painted is one or another (0x5266). One
byte, five consequences.

## The bow scores with Pythagoras and no square root

`QUE_ANILLO_HA_TOCADO` (0x5CCF) takes the two distances from the arrow to the
centre of the target — X 0xBC, Y 0x53 — squares each of them with eight adds and
shifts (0x5D0C), adds the two squares, and compares that against the table at
0x5D03.

That table is **the radii of the nine rings, already squared**: 1, 6, 16, 25,
64, 96, 144, 196 and 289. No root is ever taken. And the last radius does not
fit in a byte, so the loop supplies its top 1 by hand with a trick worth reading
twice:

    xor a           ; the high byte is 0...
    djnz L_5CF1
    inc a           ; ...except on the ninth, where it is 1

## The clays are not random: they are written bit by bit

The launcher (0x5738) reads which way each clay goes from the table at 0x583E
**one bit at a time**, and its height from the one at 0x5866 **two bits at a
time**, each with its own counter. There is no seed, no clock and no refresh
register anywhere near it: the same cartridge throws the same clays in the same
order, every time.

## One octave of twelve notes, and the rest by doubling

The sound player keeps exactly twelve periods at 0x7832 — 0x6A, 0x64, 0x5F,
0x59, 0x54, 0x50, 0x4B, 0x47, 0x43, 0x3F, 0x3C and 0x38 — and gets every other
octave by doubling the period at 0x7815, which is precisely what dropping an
octave means. With the PSG clock (111,861 Hz divided by the period), 0x6A gives
1,055 Hz and 0x38 gives 1,998: C and B of the same octave, with the eleven
semitones in between falling where they should.

## Eight weight classes, and an angle in hundredths

At 0x7587 there are eight names of fourteen tiles each — FLY, BANTAM, FEATHER,
LIGHT and MIDDLE WEIGHT, MIDDLE HEAVY, HEAVY WEIGHT and SUPER HEAVY — and at
0x6F48 their eight weights in BCD: 150, 165, 180, 195, 210, 225, 240 and 260
kilos.

The archery's angle, in the other event, is a two-byte BCD number that rises
0x28 on each press — that is 0.28 degrees, as the `ANGLE 0.00` readout on row 10
shows — and wraps round when the hundreds byte reaches 4.

## Two tables that start on a `ret`

0x5AA6 and 0x5B0B are read as tables, but the code that indexes them points one
byte earlier, at 0x5AA5 and 0x5B0A — and those two bytes are the `ret` of the
routine just above. Entry 0 of each table is 0xC9, and it is never used: the
index always comes in from 1. The listing declares them as what they are, with
the `equ` that lets the whole thing assemble.

## The same byte written twice

`ELIGE_LA_CATEGORIA` (0x75F7) leaves the chosen class with

    ld (hl),a
    ld (0e110h),a

and HL was already pointing at 0xE110. Three bytes and thirteen cycles a frame
that do nothing.

## It does not carry Konami's hidden mark

Many of the house's cartridges hide their catalogue number and the title in
katakana at the end of the ROM — something **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)) found. This one does
not: the last 25 bytes are 0xFF filler, and there is no 0xAA anywhere near them
to close the mark. RC-717 comes from the catalogue, not from the binary. Hyper
Sports 1 (RC-715) does not carry it either, while its cousins Hyper Olympic 1
and 2 do.
