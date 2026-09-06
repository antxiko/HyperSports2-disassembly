# Findings

Everything here is measured against the binary. Where a number appears, the
address it came from is next to it.

## The three secrets, and what exactly triggers each one

The cartridge hides one bonus in each event. None of them is random: all three
hang off a byte that can be pointed at.

**Skeet — the octopus and the bird.** `SUELTA_EL_PLATO` (0x5757) only ever
writes poses 1, 2 and 3 into a slot: the 100, 500 and 1000 clays. Poses 4 and 5
come from two routines hidden at the end of the ROM, `SUELTA_EL_PULPO` (0x761A)
and `SUELTA_EL_PAJARO` (0x762F), which fill the slot by hand from nine bytes
written in the cartridge — pose, Y 0x60, X 0xE8 and a velocity of 0xFC00 that
carries them leftwards.

0x4F59 calls them when a round ends with the three slots empty, counting the
rounds in 0xE19A: the octopus on the first, the bird on the second. But
0x762F's first instruction reads 0xE179, and the only thing that ever sets that
byte is 0x5AC1, **when the clay just broken was pose 4 — the octopus — and
0xE178 says the shot came from the upper barrel**. 0xE178 is written by
`UN_DISPARO` (0x5A10): zero for the lower barrel (0xE0C0, aiming around Y 0x90)
and non-zero for the upper one (0xE0C4, around Y 0x60). So hitting the octopus
is not enough — it has to be the upper barrel.

There is also a way to lose both. Every time 0x58EF retires a clay while 0xE179
is clear, 0x591D sets 0xE199; and with 0xE199 set, 0x4F59 calls neither routine
and 0x4F75 stops raising the difficulty.

What each one pays comes from the table that starts at the `ret` of 0x5B0A, in
BCD: 01, 05, 10, **30** and 10 for poses 1 to 5. The octopus is worth 3000 and
the bird 1000, and the little number that floats up is the pattern from the
table at 0x5AA5: 0x14, 0x18, 0x1C, **0x3C** — the `3000` sign — and 0x1C.

**Archery — the apple and the penguin.** 0xE145 starts at 3 (0x4C32).
`CUENTA_ATRAS_DEL_TIRO` (0x65D1) takes one off it as a shot ends, but only when
the arrow landed in **ring 9**. Ring 9 is not the outer ring: 0x5CFF numbers
them from 0 at the rim to 9 at the centre, and the table at 0x5D37 pays 10 for
ring 0 and 600 for ring 9. Ring 9 is the bullseye.

On the third bullseye 0xE145 hits zero, and `REMATA_EL_PASO` (0x5C22) takes the
other branch: instead of the usual ending it copies the six sprite entries at
0x5E59 to 0xE0C4 — the apple and the penguin. Hitting the penguin (0x5E0F)
leaves pattern 0x7C, which is the `3000` sign, and 0x0030 in BCD at 0xE11D:
another 3000 points.

**Weight lifting — the flowers.** This one is not a sprite at all. The judges
pass the lift at 0x6F98, setting 0xE1A3; from then on `WEIGHT_PASO_5` (0x523E)
raises 0xE132 by one for every frame the button is held. When 0xE132 reaches 5,
`REMATE_DEL_WEIGHT` (0x5065) fills twelve cells of row 16 with tile 0x91 and
twelve of row 17 with tile 0x92 — the flower bed over the podium — and 0x524B
adds 2000 points in BCD on top.

## A sprite pattern has no colour: the entry does

None of the three could be drawn from the pattern table alone. On the MSX1 the
colour of a sprite lives in its **entry**, one byte per sprite, and a figure is
usually several sprites stacked.

The penguin is the clearest case: the six entries at 0x5E59 put **three sprites
on the same cell**, pattern 0x68 in colour 0x04, 0x6C in 0x0F and 0x70 in 0x0A
— blue, white and yellow. Three one-colour sprites making one three-coloured
bird. 0x5E35 then swaps two of those patterns every eight frames (0x68 for 0x74,
0x70 for 0x78) and the penguin walks.

The clays and their creatures have no fixed entry: 0x5108 looks their pattern
**and colour** up in the pairs table at 0x511D, indexed by the slot's pose.
Poses 1 to 3 are the same pattern 0x00 in three colours — 0x0F, 0x04 and 0x06 —
and from 4 on come 0x2C/0x0F for the octopus and 0x30/0x04 and 0x38/0x04 for
the bird, the two patterns 0x50FC alternates so that it flaps its wings.

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
