TOP = cnn_top
DEPTH ?= 60

.PHONY: all bmc clean

all: bmc

bmc:
	bash run_bmc.sh $(DEPTH)

clean:
	rm -f *.smt2 *.log
