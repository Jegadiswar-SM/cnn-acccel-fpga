# Module Reference

## Active Integrated RTL

The active simulation and generic synthesis source lists include:

```text
rtl/pe.v
rtl/mac_array.v
rtl/relu.v
rtl/cnn_regs.v
rtl/cnn_top.v
```

### `cnn_top`

Top-level accelerator. Responsibilities:

- instantiates `cnn_regs`,
- sequences weight/input reads and result writes,
- stores four packed weight words and one packed input word,
- drives `mac_array`,
- applies four `relu` instances,
- exposes `done_o`, `busy_o`, and `fsm_state_o`.

Internal FSM states:

| State | Value | Purpose |
| --- | --- | --- |
| `IDLE` | 0 | Wait for `start` |
| `LD_W0_RQ` / `LD_W0` | 1 / 2 | Request and capture first weight word |
| `LD_W1_RQ` / `LD_W1` | 3 / 4 | Request and capture second weight word |
| `LD_W2_RQ` / `LD_W2` | 5 / 6 | Request and capture third weight word |
| `LD_W3_RQ` / `LD_W3` | 7 / 8 | Request and capture fourth weight word |
| `LD_DAT_RQ` / `LD_DATA` | 9 / 10 | Request and capture packed input |
| `COMPUTE` | 11 | Assert `comp_en`; leave after `comp_cnt == 4` |
| `STORE_RQ` / `STORE` | 12 / 13 | Write packed ReLU result and wait for grant |
| `DONE_ST` | 14 | Pulse done and return to idle |

### `cnn_regs`

Register block for APB-like control/status/configuration. `pready` is tied high. Writes are sampled on `psel && penable && pwrite`; reads are combinational.

It exposes `mode`, `img_rows`, and `img_cols`, but those outputs are intentionally left unconnected in `cnn_top`.

### `mac_array`

Thin wrapper around four `pe` instances. Each lane receives its own `wdata_N` and the shared `idata`. Outputs are the four PE results.

### `pe`

Processing element. Stores four signed 8-bit weights on `load_w`, clears accumulator state on `clr`, and accumulates one signed byte multiply per `en` cycle. `result` is updated on step `3`.

### `relu`

Combinational saturating ReLU:

- signed negative input -> `0`
- input with any upper bits set -> `255`
- otherwise -> `data_in[7:0]`

## Present but Not Integrated in `cnn_top`

These RTL modules are present in `rtl/` and mirrored under `flow/designs/src/cnn_top/`, but they are not instantiated by `cnn_top` and are not included in `dv/Makefile` or `syn/Makefile` source lists.

### `ctrl_fsm`

A broader controller with FC/Conv mode concepts, kernel count, kernel size, ReLU, pooling, and store phases. It is not wired to memory or the active datapath.

### `line_buffer`

Three-line buffer that produces a 3x3 byte window from streaming input. `rows` is an input but is not used in the implementation; `cols` controls pointer wrap.

### `pooling`

2x2-style max pooling helper with a four-phase collection sequence. The `max4` function takes five inputs and includes both `p11` and current `data_in`; because nonblocking assignment updates `p11` after the expression, the current sample is included through the fifth argument.

### `systolic_array`

Defines a 4x4 PE mesh, but it instantiates `pe` using ports named `w_in`, `data_in`, `acc_in`, `w_out`, `data_out`, and `acc_out`. The actual `rtl/pe.v` module has ports `wdata`, `idata`, and `result`. As written, `systolic_array` is incompatible with the current `pe` interface and is not buildable with the active PE.

### `weight_buffer`

4x4 byte weight buffer with column load/select behavior. It is not used by the active top-level.

## Flow Source Mirrors

`flow/designs/src/cnn_top/*.v` is byte-for-byte identical to `rtl/*.v` at the time this documentation was written. OpenROAD uses the mirrored flow source tree through:

```make
export VERILOG_FILES = $(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/*.v
```

If RTL changes are made under `rtl/`, mirror them into `flow/designs/src/cnn_top/` before running the OpenROAD flow, or update the OpenROAD config to point at the canonical RTL directory.
