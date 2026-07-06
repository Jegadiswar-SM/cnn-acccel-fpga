# Development Guide

## Source of Truth

The canonical human-authored RTL is under `rtl/`. The OpenROAD flow uses a mirrored copy under `flow/designs/src/cnn_top/`. At the time this documentation was written, the two trees are byte-for-byte identical.

When changing active RTL, update every relevant source list:

- `dv/Makefile`
- `syn/Makefile`
- `syn/synth.ys`
- `syn/synth_gls.ys`
- `syn/synth.tcl`
- `dv/fv/run_bmc.sh`
- `flow/designs/src/cnn_top/` or `flow/designs/sky130hd/cnn_top/config.mk`

## Coding Style Observed

- Active-low asynchronous reset named `rst_n`.
- `always_ff` and `always_comb` are used in RTL source files.
- Packed bytes use little-element order: low byte is element 0.
- Registers and FSM state are initialized in reset branches.
- Testbenches use Verilog tasks for APB writes and result checking.

## Change Workflow

1. Modify RTL in `rtl/`.
2. Mirror RTL into `flow/designs/src/cnn_top/` if the OpenROAD flow should see the same change.
3. Run lint:

   ```sh
   cd dv
   make lint
   ```

4. Run RTL simulation:

   ```sh
   make sim
   ```

5. If the top-level interface or FSM changes, update formal properties and run BMC when Yosys/Z3 paths are available:

   ```sh
   cd fv
   make bmc DEPTH=60
   ```

6. Regenerate synthesis outputs when Yosys is available:

   ```sh
   cd ../../syn
   make synth
   ```

7. Update documentation for any changed register, port, memory, or flow behavior.

## Debugging

- Use `dv/tb_cnn.v` debug prints for FSM and datapath state.
- Use `dv/tb_cnn.fst` with GTKWave for signal-level inspection.
- Use `fsm_state_o` for external observation of top-level state.
- For memory protocol issues, inspect `mem_req`, `mem_gnt`, `mem_we`, `mem_rvalid`, `mem_addr`, and `mem_rdata`.

## Generated Files

Do not hand-edit generated outputs:

- `dv/*.vvp`
- `dv/*.fst`
- `dv/fv/*.smt2`
- `syn/synthesized/*`
- `flow/results/*`

Regenerate these through the documented make targets.
