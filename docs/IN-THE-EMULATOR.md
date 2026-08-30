# In the emulator

The listing and every number on this site come from the binary and are
reproducible with `make`. Nothing here was measured by eye. The emulator is for
checking that what the listing says is what the cartridge does.

## Running it

    openmsx -machine Philips_VG_8020 -cart hypersports2.rom

An MSX1 machine is enough: the cartridge maps into page 1 and drives everything
from the frame interrupt.

## What to watch

| address | what it holds |
|---|---|
| 0xE000 | the state; 0xE001 the sub-state |
| 0xE005 | the latch that keeps the interrupt from re-entering |
| 0xE036 | non-zero while any of the three channels is playing |
| 0xE080 | the event: 0 skeet, 1 archery, 2 weight lifting, 3 records |
| 0xE1A1 | the step inside the event |
| 0xE1A3 | in the weight lifting, the lift given as good |
| 0xE063 | the points, three bytes of BCD |

To confirm a timing, put a breakpoint at a routine's entry and another at its
`ret`, and take the difference of `machine_info time` — times 3579545 for Z80
cycles.

## A session that checks the events

`tools/omsx_capturas.tcl` boots the cartridge, presses keys through the key
matrix and takes screenshots. Its log writes the time, the PC and the state next
to each shot, so a capture can be tied to the listing:

    t=   21.91  foto tiro_03.png  PC=0x58F3  estado=2
    t=   44.92  foto tiro_05.png  PC=0x445A  estado=2

The first PC falls inside `MIRA_LOS_IMPACTOS` (0x58E3), the skeet's; the second
inside the VDP write helper, with the archery on screen. That is what settles
the order of 0xE080: skeet first, archery second — and the `ANGLE 0.00` and
`WIND` readouts confirm which event is which without having to reason about it.

## Traps already paid for

* Launched with `-script`, the emulator starts with the renderer
  `uninitialized`, and `screenshot` returns a **black PNG with a return code of
  zero**. It has to be turned on by hand with `set renderer SDLGL-PP`.
* With `set throttle off` the machine runs flat out and the renderer skips
  frames: ask for the capture with the throttle **on** and with
  `after realtime`, which is wall clock.
* `type space` types the word "space". The trigger is row 8 of the key matrix:
  `keymatrixdown 8 0x01` for the bar, 0x10, 0x20, 0x40 and 0x80 for the four
  arrows.
* Output paths in any Tcl script must be Windows paths, never `/tmp`.
