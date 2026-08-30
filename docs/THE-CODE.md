# The code

## The main program does nothing

INIT (0x4064) sets the stack at 0xE400, zeroes the game's RAM, writes a
`jp 0x4022` into the H.KEYI hook, sets up the VDP and the PSG, loads twelve
starting values into 0xE053 — and then falls into a `jr` to itself at 0x40A0 and
stays there for ever.

Everything happens inside the interrupt. Each frame it steps the sound (0x7696),
reads the controls (0x44AD) and gives the game **one step** (0x40AB). 0xE005 is
the latch: if the previous step has not finished, the interrupt only moves the
sound and leaves.

## The state machine

0xE000 is the state and 0xE001 the sub-state. The state indexes an eleven-word
table and the sub-state splits each handler with a `djnz` chain, so a handler
reads like a list of numbered sub-states.

    0  title, curtain and labels        6  the event's frame
    1  wait                             7  end of attempt
    2  change of event                  8  end of the event
    3  prepare the game                 9  change of event
    4  set the event up                10  the table of records
    5  prepare the attempt

## The dispatcher, and its ten tables

Every jump by index goes through the same seven instructions at 0x4046:

    add a,a
    pop hl          ; the return address is the table
    call HL_MAS_A
    ld e,(hl)
    inc hl
    ld d,(hl)
    ex de,hl
    jp (hl)

The word table is **glued right behind the `call`**, and the dispatcher pops it
off the stack. There are ten of them (0x40C8, 0x4B80, 0x4BB1, 0x4CD0, 0x4DFE,
0x4EC4, 0x5054, 0x5151, 0x5297, 0x547C), and each one is declared in
`src/hypersports2.nocode`. A tracer that walks past a `call DESPACHA` eats the
table as instructions and reports coverage it has not earned: the size of each
table is fixed by its lowest forward destination, and every one of them closes
exactly against it.

## What runs after a state that never returns

Because the dispatcher jumps and never comes back, whatever has to run
afterwards is **pushed on the stack beforehand**:

    ld hl,04cc8h
    push hl
    ld a,(0e080h)
    call DESPACHA

Four addresses reach the listing that way and no other: 0x4CC8, 0x521C, 0x44E6
and 0x4F87. Two of them were sitting in the notes as data until the pattern was
searched for on purpose — a `ld hl,NN` and a `push hl` with up to three
instructions in between.

## Three events, one set of steps

Each event has its own step table — seven words for the archery (0x5297),
eleven for the weight lifting (0x5151) — and both of them **reuse the skeet's
steps** for what does not change: saving the mark (0x4FD6), checking against the
qualifying score (0x4FEA), the end (0x501A) and finishing the event (0x50DC).
Four of the eleven weight lifting steps and four of the archery's seven are the
skeet's, pointed at from another table and untouched.

## The listing

`tools/mkasm.py` builds it from the trace and the notes. Two guards run on every
build:

* `check_trace.py` and `check_datos_como_codigo.py`: no byte declared as data
  may come out as an instruction. Reassembling cannot catch this — the bytes are
  the same either way, only what we say about them changes.
* `check_entradas.py`: no entry point may fall inside a data range.

And `presupuesto.py` refuses to pass if a single byte of the 16,384 is left
unassigned.
