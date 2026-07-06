export DESIGN_NAME  = cnn_top
export DESIGN_NICKNAME = cnn_top
export PLATFORM     = sky130hd

export VERILOG_FILES = $(DESIGN_HOME)/src/$(DESIGN_NICKNAME)/*.v
export SDC_FILE      = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_NICKNAME)/constraint.sdc

export CORE_UTILIZATION = 40
export TNS_END_PERCENT  = 100

export CTS_BUF_DISTANCE = 0
export CTS_CLUSTER_SIZE = 1
export CTS_CLUSTER_DIAMETER = 0
export CTS_ARGS = -repair_clock_nets
