# Documentation Index

This documentation describes the repository as implemented. It distinguishes the active `cnn_top` accelerator path from RTL modules that are present but not wired into the current top-level flow.

## Start Here

- [Getting Started](getting-started.md): local tool expectations, first commands, and generated artifacts.
- [Architecture](architecture.md): system overview, datapath, control flow, and design decisions.
- [Usage Guide](usage.md): how software programs the accelerator and how memory is laid out.
- [Configuration Reference](configuration.md): register map, top-level ports, memory protocol, and flow variables.

## Engineering References

- [Module Reference](modules.md): RTL modules, active source lists, and unused/incomplete modules.
- [Verification Guide](verification.md): lint, simulation, gate-level simulation, and formal checks.
- [Synthesis and Physical Design](synthesis-and-physical-design.md): Yosys and OpenROAD flows.
- [Development Guide](development.md): coding conventions and change workflow.
- [Troubleshooting](troubleshooting.md): known command failures and debugging steps.
- [Limitations and Known Issues](limitations.md): implementation limits, missing integrations, and inferred roadmap items.

## Primary Entry Points

| Area | Entry point |
| --- | --- |
| Top-level RTL | `rtl/cnn_top.v` |
| Register block | `rtl/cnn_regs.v` |
| MAC datapath | `rtl/mac_array.v`, `rtl/pe.v`, `rtl/relu.v` |
| RTL testbench | `dv/tb_cnn.v` |
| Gate-level testbench | `dv/tb_gls.v` |
| Formal wrapper | `dv/fv/cnn_top_formal.v` |
| Generic synthesis | `syn/Makefile`, `syn/synth.ys` |
| OpenROAD flow | `flow/Makefile`, `flow/designs/sky130hd/cnn_top/config.mk` |
