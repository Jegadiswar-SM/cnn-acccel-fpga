TOP = cnn_top

VERILOG_SOURCES = \
	../rtl/pe.v \
	../rtl/mac_array.v \
	../rtl/relu.v \
	../rtl/cnn_regs.v \
	../rtl/cnn_top.v

all: synth

synth: synthesized/$(TOP)_synth.v

synthesized/$(TOP)_synth.v: synth.ys $(VERILOG_SOURCES) | synthesized
	YOSYS_SHARE=/tmp/yosys-extracted/usr/local/share/yosys \
	/tmp/yosys-extracted/usr/bin/yosys -s $< 2>&1 | tee synthesized/synth.log

synthesized:
	mkdir -p synthesized

clean:
	rm -rf synthesized

.PHONY: all synth clean
