# The game

Three events, in this order, written into the ROM at 0x4791 as three rows of
sixteen tiles each: **SKEET SHOOTING**, **ARCHERY** and **WEIGHT LIFTING**. The
byte at 0xE080 says which one is running, and its two low bits index every
table that splits by event.

## Skeet shooting

Two crosshairs and a clock. `LANZA_UN_PLATO` (0x5738) releases a clay every 0x18
frames into whichever of the three slots at 0xE100 is free; each slot is sixteen
bytes with the clay's posture, its 16-bit X and Y and its two speeds.
`CAEN_LOS_PLATOS` adds gravity, and the gravity is bigger the higher the clay
is, so the arc tightens as it falls.

The trigger fires the top barrel with bit 3 of the joystick and the bottom one
with bits 2 and 4. `MIRA_LOS_IMPACTOS` (0x58E3) walks the three slots and, for
each pellet, allows six points of slack in X and six in Y — and only postures 0
to 3 can be broken.

## Archery

The readouts are three, and the screen names them: `ANGLE` on row 10, `WIND` at
the bottom and `SCORE` beside it.

* The **angle** rises 0.28 degrees on each press of the button and wraps round
  at 4.00 (0x5B42, in BCD, with the hundreds byte compared against 4).
* The **wind** is not random either: `SIGUIENTE_VIENTO` (0x5BB8) walks sixteen
  values at 0x5BCB in a ring, bit 7 for the side and the low nibble for the
  strength. As the arrow rises, `CORRIGE_LA_DERIVA` (0x5B8C) bends it one point
  per stretch of the table at 0x5BB0.
* The **hit** is decided by `QUE_ANILLO_HA_TOCADO` (0x5CCF) against a target
  centred on X 0xBC and Y 0x53 — the same two constants you can see on the
  screen — and each ring pays what the ten-word BCD table at 0x5D37 says: 10,
  100, 170, 210, 250, 290, 320, 350, 400 and 600.

## Weight lifting

First you pick a class. `ELIGE_LA_CATEGORIA` (0x75F7) steps through eight of
them with any direction and takes it with the button; `PINTA_LA_CATEGORIA`
(0x756D) writes its name, fourteen tiles from 0x7587, into the `CHOOSE CLASS`
sign, and `PINTA_LOS_KILOS` (0x6F25) puts its weight in the `KG` board: 150,
165, 180, 195, 210, 225, 240 and 260 kilos.

Then the `POWER` bar on row 23 (0x6E24), which the table at 0x6E77 drains every
frame and the joystick feeds. The bar rises through the 36 heights at 0x6ED4,
and once it is up, **three judges' lights** come on in column 2, one every 0x20
frames (0x6F78). At the third the lift is good, and 0x6FA2 drops the two plates
of the barbell from Y 0x4A, two points per frame.

## The scoreboard, and what carries over

The top of every screen is the same: `SCORE`, `HI`, `YOU`, `WORLD RECORD`,
`QUALIFY` and the three `1st TRY` / `2nd TRY` / `3rd TRY` rows, painted from the
stream at 0x4749 with the label list at 0x4712 over it. Points are three bytes
of BCD at 0xE063 and top out at 999999.

After the third event comes the records screen, and then the cycle starts again:
0xE080 counts 0, 1, 2, 3 and at 3 the table of records takes over — except that
bit 2 of the same byte skips it every other round.
