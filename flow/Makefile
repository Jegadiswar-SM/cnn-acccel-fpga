TOP = cnn_top
PLATFORM = sky130hd
ORFS = /OpenROAD-flow-scripts
ORFS_FLOW = $(ORFS)/flow
FLOW_DIR = $(CURDIR)
DESIGNS_DIR = $(FLOW_DIR)/designs
RESULTS_DIR = $(FLOW_DIR)/results

.PHONY: all synth floorplan place cts route finish gds clean clean_all shell

all: synth floorplan place cts route finish

synth floorplan place cts route finish gds:
	mkdir -p $(RESULTS_DIR)/$(PLATFORM)/$(TOP)
	docker run --rm -i \
		-v $(DESIGNS_DIR):$(ORFS_FLOW)/designs \
		-v $(RESULTS_DIR):$(ORFS_FLOW)/results \
		openroad/orfs \
		bash -c '\
			source $(ORFS)/env.sh && \
			cd $(ORFS_FLOW) && \
			DESIGN_CONFIG=./designs/$(PLATFORM)/$(TOP)/config.mk \
			make $@ 2>&1 | tee ./results/$(PLATFORM)/$(TOP)/$@.log \
		'

shell:
	mkdir -p $(RESULTS_DIR)/$(PLATFORM)/$(TOP)
	docker run --rm -it \
		-v $(DESIGNS_DIR):$(ORFS_FLOW)/designs \
		-v $(RESULTS_DIR):$(ORFS_FLOW)/results \
		openroad/orfs \
		bash -c '\
			source $(ORFS)/env.sh && \
			cd $(ORFS_FLOW) && \
			exec bash \
		'

clean:
	rm -rf results/*

clean_all: clean
	rm -rf designs/src/cnn_top
