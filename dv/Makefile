TOP = cnn_top
TB  = tb_cnn

VERILOG_SOURCES = \
	../rtl/pe.v \
	../rtl/mac_array.v \
	../rtl/relu.v \
	../rtl/cnn_regs.v \
	../rtl/cnn_top.v

all: lint sim

sim: $(TB).vvp
	timeout 2 vvp $(TB).vvp 2>&1 || true

$(TB).vvp: $(TB).v $(VERILOG_SOURCES)
	iverilog -g2012 -o $(TB).vvp $(TB).v $(VERILOG_SOURCES)

waves:
	gtkwave tb_cnn.fst &

lint:
	verilator --lint-only -Wall -Wpedantic -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL --top-module $(TOP) $(VERILOG_SOURCES) 2>&1

gls: $(TB)_gls.vvp
	timeout 2 vvp $(TB)_gls.vvp 2>&1 || true

$(TB)_gls.vvp: tb_gls.v ../syn/synthesized/$(TOP)_synth_gls.v /tmp/yosys-extracted/usr/share/yosys/simcells.v
	iverilog -g2012 -o $(TB)_gls.vvp tb_gls.v \
		../syn/synthesized/$(TOP)_synth_gls.v \
		/tmp/yosys-extracted/usr/share/yosys/simcells.v

clean:
	rm -f *.vvp *.fst *.vcd

.PHONY: all lint sim gls waves clean
