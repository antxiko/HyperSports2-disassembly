# The cartridge

16,384 bytes that map into page 1 of the MSX, 0x4000-0x7FFF. The header at
0x4000 is the usual one: the `AB` mark and, of the four vectors, only INIT is
filled in, pointing at 0x4064.

## What the 16 KB are

| | bytes | share |
|---|---:|---:|
| traced code | 6,956 | 42.46% |
| identified data | 9,428 | 57.54% |
| unexplained | 0 | 0.00% |

The data is not one lump: it is 151 named ranges, each closed against what
reads it. `make sanity` is what prints this table, and it fails if a single byte
is left over.

## The video chip

`MANDA_LOS_REGISTROS_DEL_VDP` (0x4476) writes the eight bytes at 0x4487 one by
one through the BIOS. They put the machine in SCREEN 2 with 16x16 sprites and
lay the memory out like this:

| table | address |
|---|---|
| names | 0x3800 |
| colours | 0x0000 |
| patterns | 0x2000 |
| sprite attributes | 0x3B00 |
| sprite patterns | 0x1800 |

The border is black. Patterns and colours have their three thirds independent,
and the cartridge uses that: the font goes into all three, and each event only
replaces the two lower ones.

## How the graphics are stored

Nothing is stored as a screen. There are three interpreters:

* **The run-length stream** (0x43FB). One count byte rules: 0x00 ends it, 0x80
  brings a new VRAM address in the two bytes that follow, with bit 7 set it
  copies `n & 0x7F` literal bytes, and without it, it repeats the next byte `n`
  times. Entering at 0x43F5 the stream carries its own destination in front.
* **The tile list** (0x4050). Two bytes with the name-table cell and then the
  tiles; 0xFE jumps to another cell, 0xFF ends.
* **The title script** (0x423C). Each byte is a count: with bit 7 it fills eight
  cells with the byte that follows, and without it, it repeats the same eight —
  one whole tile — that many times.

Every picture on this site is drawn by running those three in Python, in
`tools/graficos.py`. If a range or a format were wrong, what would come out is
noise.

## Where each event's graphics live

The table at 0x6C3A holds **four records of three pointers**: patterns to VRAM
0x2A00, colours to 0x0A00 and sprites to 0x1800, indexed by (0xE080) & 3 times
six. The fourth record is the records screen, which shares its sprites with the
archery. The backgrounds are somewhere else: three words at 0x42A0, straight
into the name table from row 8.

## The sound

Three channels of twelve bytes each from 0xE010: the note counter, how long it
lasts, the state — which is the number of the effect playing, with bit 7 for the
long commands and bit 6 for noise —, the pointer into the stream, the octave,
the background volume, the volume sounding, the fade count, the pitch and the
detune.

`CORRE_EL_SONIDO` (0x7696) steps the three every frame and leaves in 0xE036 the
OR of the three states: that is the "something is playing" flag half the
cartridge waits on. There are 48 effects and short tunes in the table at 0x78AC,
and the tone table is one octave of twelve periods — the rest come from doubling.

## The RAM

0xE000 is the state and 0xE001 the sub-state; 0xE003 the frame counter, 0xE004
the general wait. 0xE043-0xE048 hold the joystick as read and as it was.
0xE063 keeps the points in BCD, 0xE080 the event and 0xE0C0 the sprite records that
go up to the VDP in one block. The stack starts at 0xE400.
