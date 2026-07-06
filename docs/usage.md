# Usage Guide

## Programming Model

Software configures the accelerator through the APB-like register interface:

1. Write `IMG_BASE` with the byte address of the packed input word.
2. Write `WGT_BASE` with the byte address of four consecutive packed weight words.
3. Write `RES_BASE` with the byte address for the packed output word.
4. Write `CONTROL.start = 1`.
5. Poll `STATUS.busy`/`STATUS.done` or observe `done_o`.
6. Read the result from memory at `RES_BASE`.

`done_o` is a one-FSM-state pulse. `cnn_regs` clears the stored `start` bit when `done` is observed.

## Memory Layout

All addresses used by `cnn_top` are byte addresses. The testbench memory indexes words by `mem_addr[13:2]`.

| Address | Access | Meaning |
| --- | --- | --- |
| `WGT_BASE + 0` | read | Weight word for PE lane 0 |
| `WGT_BASE + 4` | read | Weight word for PE lane 1 |
| `WGT_BASE + 8` | read | Weight word for PE lane 2 |
| `WGT_BASE + 12` | read | Weight word for PE lane 3 |
| `IMG_BASE` | read | Packed input word shared by all PE lanes |
| `RES_BASE` | write | Packed output `{relu_3,relu_2,relu_1,relu_0}` |

Packed word format:

```text
word[7:0]   = element 0
word[15:8]  = element 1
word[23:16] = element 2
word[31:24] = element 3
```

Weights are interpreted as signed 8-bit values. Input bytes are cast through `$signed(idata[...])` in `pe`, so each byte is also treated as signed during multiplication.

## Worked Example

Identity-like lane selection from `dv/tb_cnn.v`:

```text
memory[0]  = 00000001  -> PE0 uses w0 = 1
memory[1]  = 00000100  -> PE1 uses w1 = 1
memory[2]  = 00010000  -> PE2 uses w2 = 1
memory[3]  = 01000000  -> PE3 uses w3 = 1
memory[64] = 05040302  -> input bytes are 2, 3, 4, 5
```

With `IMG_BASE=256`, `WGT_BASE=0`, and `RES_BASE=2048`, the output word at testbench memory index `512` is:

```text
05040302
```

## Register Access Tasks in Testbench

`dv/tb_cnn.v` implements:

```verilog
task apb_write(input [7:0] addr, input [31:0] data);
```

The task drives `psel`, `pwrite`, `paddr`, and `pwdata`, then asserts `penable` for the write phase. There is no APB read task in the current testbench.
