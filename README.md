# Hyper Sports 2 (Konami, RC-717) — commented disassembly

A commented disassembly of the 16 KB MSX cartridge, reproducible byte for byte.

**[Read the write-up →](https://antxiko.github.io/HyperSports2-disassembly/)**
· [En castellano](README.es.md)

    make            # trace, generate the listing, reassemble it and run the tests
    make verify     # the test that decides: reassembling has to give the ROM back
    make sanity     # that not one byte is left unexplained
    make densidad   # how much is commented, routine by routine
    make textos     # read the cartridge's texts, which are tile lists and not ASCII
    make web        # rebuild the website

The ROM is **not distributed here**. It goes in the root as `hypersports2.rom`,
16384 bytes, sha256

    f4273f5290edb8b55a319bdfc40d99c0f7863a4cbd93b75519508cb129d288f6

`make comprueba` checks it.

## Where it stands

| | |
|---|---|
| reassembles byte for byte | yes |
| bytes explained | 16,384 of 16,384 (100 %) |
| traced code | 6,956 bytes, 3,680 instructions |
| identified data | 9,428 bytes in 151 named ranges |
| commented | 837 line comments, 22.7 % |
| thin routines (under 10 %) | 0 of 500 |

The annotations live apart from the listing, anchored to the address they
describe, so they survive a re-trace. What the `.notes` file holds:

| | |
|---|---|
| named labels | 314 |
| anchored comments | 829 |
| explained data ranges | 151 |

## What is in here

- `src/hypersports2.asm` — the listing; generated, not hand-edited
- `src/hypersports2.notes` — the annotations, anchored to addresses
- `src/hypersports2.entries` — the entry points, each one justified
- `src/hypersports2.nocode` — the ten dispatch tables glued behind their `call`
- `docs/` — the website, in English and Spanish
- `tools/` — the tracer, the listing generator, the data walkers, and the three
  interpreters (run-length streams, tile lists and the title script) that draw
  the website's pictures from the ROM

## The write-up

| | |
|---|---|
| [Getting started](docs/GETTING-STARTED.md) | what you need and what each command does |
| [The game](docs/THE-GAME.md) | skeet shooting, archery and weight lifting |
| [The cartridge](docs/THE-CARTRIDGE.md) | the header, the memory map and the screen |
| [The code](docs/THE-CODE.md) | the state machine, the dispatcher and the sound |
| [Findings](docs/FINDINGS.md) | what the binary says |
| [In the emulator](docs/IN-THE-EMULATOR.md) | what can be measured, and how |
| [Open questions](docs/OPEN-QUESTIONS.md) | what is still not settled |

See `LEGAL-NOTICE.md`.
