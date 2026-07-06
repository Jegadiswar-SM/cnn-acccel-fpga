#!/bin/bash
# Run bounded model checking on cnn_top
set -euo pipefail

YOSYS=/tmp/yosys-extracted/usr/bin/yosys
YOSYS_SMTBMC=/tmp/yosys-extracted/usr/bin/yosys-smtbmc
Z3=/home/bolter/.local/bin/z3
SHARE=/tmp/yosys-extracted/usr/local/share/yosys

TOP=cnn_top
FV_DIR=$(dirname "$0")
RTL_DIR=$(dirname "$0")/../../rtl
SMT2=${FV_DIR}/${TOP}.smt2
DEPTH=${1:-60}

echo "=== Generating SMT2 for cnn_top (depth=$DEPTH) ==="
YOSYS_SHARE=$SHARE $YOSYS -Q 2>&1 <<EOF | grep -v '^$' | grep -v 'suppressed'
    read_verilog -sv -D FORMAL $RTL_DIR/pe.v
    read_verilog -sv -D FORMAL $RTL_DIR/mac_array.v
    read_verilog -sv -D FORMAL $RTL_DIR/relu.v
    read_verilog -sv -D FORMAL $RTL_DIR/cnn_regs.v
    read_verilog -sv -D FORMAL $RTL_DIR/cnn_top.v
    prep -top $TOP -flatten
    async2sync
    dffunmap
    write_smt2 $SMT2
EOF

echo ""
echo "=== Running BMC (depth=$DEPTH) with z3 ==="
PYTHONPATH=/tmp/yosys-extracted/usr/share/yosys \
YOSYS_SHARE=$SHARE \
PATH="/home/bolter/.local/bin:$PATH" \
$YOSYS_SMTBMC \
    -t $DEPTH \
    -s z3 \
    -m $TOP \
    $SMT2 2>&1

echo ""
echo "=== BMC complete ==="
