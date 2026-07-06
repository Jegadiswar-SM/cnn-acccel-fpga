# Getting Started

## Prerequisites

The repository does not include a package manager file. Install tools using your host package manager or project-specific toolchain setup:

| Tool | Used by |
| --- | --- |
| `iverilog` and `vvp` | RTL simulation and gate-level simulation |
| `verilator` | Lint |
| `gtkwave` | Waveform viewing |
| Yosys | Generic synthesis and formal SMT2 generation |
| `yosys-smtbmc` | Formal BMC |
| Z3 | Formal solver |
| Docker | OpenROAD-flow-scripts physical-design flow |

Hard-coded paths in the current repository:

- `syn/Makefile` uses `/tmp/yosys-extracted/usr/bin/yosys`.
- `dv/fv/run_bmc.sh` uses `/tmp/yosys-extracted/usr/bin/yosys`, `/tmp/yosys-extracted/usr/bin/yosys-smtbmc`, and `/home/bolter/.local/bin/z3`.
- `dv/Makefile` gate-level simulation uses `/tmp/yosys-extracted/usr/share/yosys/simcells.v`.

If those paths do not exist, lint and RTL simulation can still run when `verilator`, `iverilog`, and `vvp` are on `PATH`, but synthesis/formal/GLS commands will fail until the paths are fixed or the tools are installed there.

## First Run

```sh
cd dv
make lint
make sim
```

`make sim` builds `dv/tb_cnn.vvp`, runs it with `vvp`, and writes `dv/tb_cnn.fst`. The testbench prints debug traces and should end with:

```text
[TB] ALL TESTS PASSED
```

## Open Waveforms

```sh
cd dv
make waves
```

This runs `gtkwave tb_cnn.fst &`.

## Build Outputs

Generated or committed outputs include:

- `dv/*.vvp`: compiled simulation executables.
- `dv/*.fst`: waveform dumps.
- `dv/fv/*.smt2`: formal SMT2 output.
- `syn/synthesized/*`: generic synthesis outputs and reports.
- `flow/results/sky130hd/cnn_top/*`: OpenROAD flow outputs and logs.

The repository currently tracks several generated outputs. Avoid editing generated netlists by hand; regenerate them from the corresponding flow instead.
