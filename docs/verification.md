# Verification Guide

## RTL Lint

Run:

```sh
cd dv
make lint
```

This invokes:

```sh
verilator --lint-only -Wall -Wpedantic -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL --top-module cnn_top ...
```

The active source list is limited to the modules used by `cnn_top`.

Observed in this workspace: lint passes.

## RTL Simulation

Run:

```sh
cd dv
make sim
```

This builds `tb_cnn.vvp` using Icarus Verilog and runs it through `vvp`.

Test scenarios in `dv/tb_cnn.v`:

| Test | Weights | Input | Expected result |
| --- | --- | --- | --- |
| Identity selection | one hot per lane | `05040302` | `05040302` |
| Scale by 2 | diagonal weight `2` per lane | `05040302` | `0a080604` |
| ReLU negative clamp | diagonal weight `-1` per lane | `05040302` | `00000000` |

Observed in this workspace: simulation passes all tests. Icarus Verilog emits this warning:

```text
rtl/cnn_regs.v:59: sorry: constant selects in always_* processes are not currently supported (all bits will be included).
```

The warning does not prevent the current testbench from passing.

## PE Testbench

`dv/tb_pe.v` is a focused standalone testbench for `pe`, but `dv/Makefile` does not expose a target for it. It loads `wdata=32'h00000002`, uses `idata=32'h05040302`, enables compute for four cycles, and prints the result.

Manual build command:

```sh
cd dv
iverilog -g2012 -o tb_pe.vvp tb_pe.v ../rtl/pe.v
vvp tb_pe.vvp
```

## Gate-Level Simulation

Run:

```sh
cd dv
make gls
```

This compiles `dv/tb_gls.v` with `syn/synthesized/cnn_top_synth_gls.v` and `/tmp/yosys-extracted/usr/share/yosys/simcells.v`.

The test scenarios mirror `tb_cnn.v` without the detailed debug printing. The command depends on the hard-coded Yosys `simcells.v` path.

## Formal BMC

Run:

```sh
cd dv/fv
make bmc DEPTH=60
```

`run_bmc.sh`:

1. reads active RTL with `-D FORMAL`,
2. flattens `cnn_top`,
3. runs `async2sync` and `dffunmap`,
4. writes `cnn_top.smt2`,
5. runs `yosys-smtbmc` with Z3.

Formal assumptions embedded in `rtl/cnn_top.v`:

- memory grant arrives within 7 cycles,
- read response arrives within 3 cycles of a read grant.

Formal assertions embedded in `rtl/cnn_top.v` include:

- FSM state remains in range,
- `done_o` implies `DONE_ST`,
- `busy_o` mirrors `fsm != IDLE`,
- compute counter does not exceed 4,
- selected outputs are not unknown,
- `load_w` and `comp_en` occur only in the expected phases.

`dv/fv/cnn_top_formal.v` is a separate formal wrapper with similar assumptions/assertions. It contains an inline note that one FSM monotonicity assertion was an overspecification and should be skipped; the code under that comment still contains an assertion, so treat this wrapper as review-needed before relying on it as the primary proof harness.

Observed in this workspace: `make bmc DEPTH=20` fails because `/tmp/yosys-extracted/usr/bin/yosys` is absent.
