# Limitations and Known Issues

## Current Functional Limits

- `cnn_top` performs one packed 4-lane MAC/ReLU operation per `start`; it does not iterate over image rows, columns, kernels, or channels.
- The configured `mode`, `img_rows`, and `img_cols` registers are not consumed by `cnn_top`.
- Base addresses are 16-bit registers zero-extended to 32-bit memory addresses.
- The top-level memory protocol has no error response, retry counter, timeout, burst support, byte enables, or backpressure on write data beyond `mem_gnt`.
- `done_o` is a short FSM-state pulse, not a sticky interrupt/status bit. The register block exposes `done` in STATUS only while the top-level signal is high.
- There is no software driver, firmware example, or host API in the repository.

## Incomplete or Unused Components

- `ctrl_fsm`, `line_buffer`, `pooling`, `systolic_array`, and `weight_buffer` are not instantiated by `cnn_top`.
- `systolic_array` is incompatible with the current `pe` port list.
- `dv/tb_pe.v` exists but has no make target.
- `dv/fv/cnn_top_formal.v` includes a comment marking one assertion as an overspecification, but the assertion remains in code.

## Tooling Limits

- Several flows hard-code tool paths under `/tmp/yosys-extracted` and `/home/bolter/.local/bin`.
- The OpenROAD flow depends on Docker and the `openroad/orfs` image.
- The committed CTS log ends in an illegal-instruction failure.

## Security Considerations

- No hardware security boundary, privilege model, register access control, memory address validation, or secure reset behavior beyond normal register reset is implemented.
- The external memory interface trusts the connected memory system to return valid data and grant requests.
- The repository does not include a license file, so reuse rights cannot be inferred.

## Performance Considerations

- The active datapath has four PE lanes and computes one 4-element dot product per lane after loading weights and input.
- Each operation performs five read transactions/waits before compute: four weight reads and one input read.
- The FSM asserts compute for five cycles although `pe.result` updates after the fourth step value; the extra cycle advances the internal 2-bit `step` back around.
- OpenROAD constraints target a `20.0 ns` clock period in the committed SDC.
- The committed generic synthesis report shows 704 enabled async-reset flip-flops of type `$_DFFE_PN0P_` plus a small number of other DFF cells after generic mapping.

## Inferred Roadmap

Only implementation-backed roadmap items are listed here:

- Integrate or remove the unused convolution-oriented modules.
- Reconcile `systolic_array` with the current `pe` interface if a true 4x4 systolic datapath is intended.
- Parameterize or document tool paths instead of hard-coding local extraction directories.
- Add a make target for `tb_pe.v`.
- Decide whether generated artifacts should remain tracked or be ignored and regenerated.
