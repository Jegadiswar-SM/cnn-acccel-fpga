# Configuration Reference

## Register Map

Implemented in `rtl/cnn_regs.v`.

| Offset | Register | Access | Reset | Bits |
| --- | --- | --- | --- | --- |
| `0x00` | CONTROL | R/W | `0x00000000` | `[0] start` |
| `0x04` | STATUS | R | `0x00000000` | `[0] busy`, `[1] done` |
| `0x08` | CONFIG | R/W | mode `0`, rows `4`, cols `4` | `[0] mode`, `[15:8] img_rows`, `[23:16] img_cols` |
| `0x10` | IMG_BASE | R/W | `0x00000000` | `[15:0] img_base` |
| `0x14` | WGT_BASE | R/W | `0x00000000` | `[15:0] wgt_base` |
| `0x18` | RES_BASE | R/W | `0x00000100` | `[15:0] res_base` |

`CONFIG.mode`, `CONFIG.img_rows`, and `CONFIG.img_cols` are exposed by `cnn_regs` but are left unconnected in `cnn_top`.

## Top-Level Ports

Implemented in `rtl/cnn_top.v`.

| Port | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | input | 1 | Clock |
| `rst_n` | input | 1 | Active-low asynchronous reset |
| `psel` | input | 1 | Register select |
| `penable` | input | 1 | Register enable phase |
| `pwrite` | input | 1 | Register write enable |
| `paddr` | input | 32 | Register address; low byte selects implemented registers |
| `pwdata` | input | 32 | Register write data |
| `prdata` | output | 32 | Register read data |
| `pready` | output | 1 | Always high |
| `mem_req` | output reg | 1 | Memory request valid |
| `mem_gnt` | input | 1 | Memory request grant |
| `mem_addr` | output reg | 32 | Byte address |
| `mem_we` | output reg | 1 | Write enable; low means read |
| `mem_wdata` | output reg | 32 | Write data |
| `mem_rvalid` | input | 1 | Read data valid |
| `mem_rdata` | input | 32 | Read data |
| `done_o` | output | 1 | High while FSM is in `DONE_ST` |
| `busy_o` | output | 1 | High while FSM is not `IDLE` |
| `fsm_state_o` | output reg | 4 | Low four bits of the internal FSM state |

## Make Variables

### `dv/Makefile`

| Variable | Value | Meaning |
| --- | --- | --- |
| `TOP` | `cnn_top` | Lint top module |
| `TB` | `tb_cnn` | RTL simulation testbench |
| `VERILOG_SOURCES` | `pe`, `mac_array`, `relu`, `cnn_regs`, `cnn_top` | Active RTL source list |

### `syn/Makefile`

| Variable | Value | Meaning |
| --- | --- | --- |
| `TOP` | `cnn_top` | Synthesis top |
| `VERILOG_SOURCES` | `pe`, `mac_array`, `relu`, `cnn_regs`, `cnn_top` | Active RTL source list |

### `flow/Makefile`

| Variable | Value | Meaning |
| --- | --- | --- |
| `TOP` | `cnn_top` | OpenROAD design nickname/top |
| `PLATFORM` | `sky130hd` | OpenROAD platform |
| `ORFS` | `/OpenROAD-flow-scripts` | Path inside the Docker image |
| `ORFS_FLOW` | `$(ORFS)/flow` | Flow root inside the Docker image |

### OpenROAD Design Config

`flow/designs/sky130hd/cnn_top/config.mk` sets:

| Variable | Value |
| --- | --- |
| `DESIGN_NAME` | `cnn_top` |
| `DESIGN_NICKNAME` | `cnn_top` |
| `PLATFORM` | `sky130hd` |
| `VERILOG_FILES` | `$(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/*.v` |
| `SDC_FILE` | `$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/constraint.sdc` |
| `CORE_UTILIZATION` | `40` |
| `TNS_END_PERCENT` | `100` |
| `CTS_BUF_DISTANCE` | `0` |
| `CTS_CLUSTER_SIZE` | `1` |
| `CTS_CLUSTER_DIAMETER` | `0` |
| `CTS_ARGS` | `-repair_clock_nets` |

The SDC creates a `20.0 ns` clock named `core_clock` on port `clk` and applies input/output delays of 20% of the clock period.
