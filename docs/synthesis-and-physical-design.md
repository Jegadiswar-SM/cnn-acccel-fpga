# Synthesis and Physical Design

## Generic Yosys Synthesis

Entry points:

- `syn/Makefile`
- `syn/synth.ys`
- `syn/synth_gls.ys`
- `syn/synth.tcl`

Run:

```sh
cd syn
make synth
```

`syn/synth.ys` reads:

```text
../rtl/pe.v
../rtl/mac_array.v
../rtl/relu.v
../rtl/cnn_regs.v
../rtl/cnn_top.v
```

Then it checks hierarchy, runs flattened generic synthesis, optimization, FSM handling, memory mapping, technology mapping, ABC mapping to `AND`, `OR`, and `XOR`, and writes:

- `syn/synthesized/cnn_top_synth.v`
- `syn/synthesized/cnn_top_synth.json`
- `syn/synthesized/cnn_top_stats.rpt`

The committed `cnn_top_stats.rpt` reports:

| Metric | Value |
| --- | ---: |
| Wires | 16,207 |
| Wire bits | 18,927 |
| Public wires | 139 |
| Public wire bits | 1,912 |
| Ports | 19 |
| Port bits | 208 |
| Cells | 16,969 |
| `$_AND_` | 7,172 |
| `$_DFFE_PN0P_` | 704 |
| `$_DFFE_PN1P_` | 3 |
| `$_DFF_PN0_` | 5 |
| `$_NOT_` | 822 |
| `$_OR_` | 3,529 |
| `$_XOR_` | 4,724 |
| `$scopeinfo` | 10 |

Observed in this workspace: `make synth` fails because `/tmp/yosys-extracted/usr/bin/yosys` is absent.

## Gate-Level Netlist

`syn/synth_gls.ys` preserves hierarchy and writes:

```text
syn/synthesized/cnn_top_synth_gls.v
```

`dv/Makefile` uses this file for `make gls`.

## OpenROAD Flow

Entry points:

- `flow/Makefile`
- `flow/designs/sky130hd/cnn_top/config.mk`
- `flow/designs/sky130hd/cnn_top/constraint.sdc`
- `flow/designs/src/cnn_top/*.v`

Run a stage:

```sh
cd flow
make synth
make floorplan
make place
make cts
make route
make finish
```

`flow/Makefile` runs the `openroad/orfs` Docker image and mounts:

| Host path | Container path |
| --- | --- |
| `flow/designs` | `/OpenROAD-flow-scripts/flow/designs` |
| `flow/results` | `/OpenROAD-flow-scripts/flow/results` |

The full `make all` target runs:

```text
synth floorplan place cts route finish
```

## Physical Constraints

`constraint.sdc`:

- current design: `cnn_top`
- clock name: `core_clock`
- clock port: `clk`
- clock period: `20.0 ns`
- input delay: `20%` of clock period
- output delay: `20%` of clock period

## Committed OpenROAD Results

The repository includes logs and database artifacts under `flow/results/sky130hd/cnn_top`.

Observed committed log status:

- `synth.log`: synthesis completed and wrote `1_synth.odb`/SDC outputs.
- `floorplan.log`: floorplan completed; final floorplan report shows design area around `100620 um^2` at `40%` utilization before later tap/PDN stages.
- `place.log`: placement completed; detailed place report shows design area around `106406 um^2` at `43%` utilization.
- `cts.log`: CTS created clock-tree buffers and reported no setup/hold violations during repair, then failed with `Error: cts.tcl, 83 child killed: illegal instruction`.

The CTS failure appears environment/tool-runtime related from the log text; the repository does not contain enough information to determine the processor instruction or Docker host compatibility issue.
