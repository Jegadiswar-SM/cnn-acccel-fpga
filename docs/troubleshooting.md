# Troubleshooting

## `rg: command not found`

The workspace used to write this documentation did not have `rg`. Use `find` and `grep` as a fallback.

## Icarus Verilog Constant Select Warning

`make sim` may print:

```text
rtl/cnn_regs.v:59: sorry: constant selects in always_* processes are not currently supported (all bits will be included).
```

This comes from Icarus Verilog handling of the `always_comb` read mux in `cnn_regs.v`. The current RTL simulation still passes all tests.

## `make synth` Cannot Find Yosys

Failure:

```text
/bin/sh: 1: /tmp/yosys-extracted/usr/bin/yosys: not found
```

Cause: `syn/Makefile` hard-codes the Yosys path.

Fix options:

- install/extract Yosys at `/tmp/yosys-extracted/usr/bin/yosys`, or
- edit `syn/Makefile` and related scripts to use a Yosys on `PATH`.

## Formal BMC Cannot Find Yosys or Z3

`dv/fv/run_bmc.sh` hard-codes:

```text
/tmp/yosys-extracted/usr/bin/yosys
/tmp/yosys-extracted/usr/bin/yosys-smtbmc
/home/bolter/.local/bin/z3
```

Update these variables or provide tools at those paths before running:

```sh
cd dv/fv
make bmc DEPTH=60
```

## Gate-Level Simulation Cannot Find `simcells.v`

`dv/Makefile` uses:

```text
/tmp/yosys-extracted/usr/share/yosys/simcells.v
```

Install/extract Yosys at that path or update the makefile to point to your local `simcells.v`.

## OpenROAD CTS Ends with Illegal Instruction

The committed `flow/results/sky130hd/cnn_top/cts.log` ends with:

```text
Error: cts.tcl, 83 child killed: illegal instruction
```

The log shows CTS had created clock buffers and run timing repair before the process died. The repository does not contain enough information to determine the exact CPU/tool-image incompatibility. Try a different host CPU, a different `openroad/orfs` image version, or an OpenROAD build compatible with the host.

## `systolic_array` Does Not Compile With Current `pe`

`rtl/systolic_array.v` instantiates `pe` with ports that do not exist on `rtl/pe.v`. This module is not in the active source lists. Do not add it to a build without first reconciling the PE interface.
