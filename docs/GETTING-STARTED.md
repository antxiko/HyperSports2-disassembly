# Getting started

A commented disassembly of **Hyper Sports 2**, Konami's RC-717 for the MSX: a
16 KB cartridge that maps into page 1 (0x4000-0x7FFF). It reassembles into the
exact ROM, byte for byte, and every one of its 16,384 bytes is accounted for.

## The cartridge is not here

No repository ships the game. Put your own dump in the root as
`hypersports2.rom`, 16384 bytes, sha256

    f4273f5290edb8b55a319bdfc40d99c0f7863a4cbd93b75519508cb129d288f6

`make comprueba` checks it.

## What each command does

    make            trace the flow, build the listing, reassemble it, run the tests
    make verify     the test that decides: reassembling has to give the ROM back
    make sanity     that not one byte is left unexplained, and no data reads as code
    make densidad   how much is commented, routine by routine
    make textos     read the cartridge's texts, which are tile lists and not ASCII
    make web        rebuild this website from the ROM and the notes

## How it is put together

The listing is not hand-edited. `tools/mkasm.py` builds it from a flow trace and
a file of notes anchored to addresses, so the comments survive a re-trace:

* `src/hypersports2.entries` — the entry points the tracer cannot deduce on its
  own: the interrupt hook, the ten inline dispatch tables, and the four return
  addresses this cartridge pushes on the stack instead of calling. Each one has
  its reason written next to it.
* `src/hypersports2.nocode` — the ten word tables glued right behind their
  `call`. A tracer that walks straight through them eats them as instructions
  and reports coverage it has not earned.
* `src/hypersports2.notes` — one line per annotation: `L` names a routine, `C`
  comments an instruction, `B` a block, `D` a data range and `F` the width of a
  record inside it.

## What the numbers mean

`make sanity` prints the budget: 6,956 bytes of traced code and 9,428 bytes of
data in named ranges, 0 unexplained, 16,384 in total. `make densidad` prints the
comment density: 3,680 instructions, 828 line comments, 22.5%, and not one
routine below 10%.

Every figure on this site comes from those two commands, not from an estimate.
