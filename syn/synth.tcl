# Yosys synthesis script for cnn_top
# Usage: yosys -c synth.tcl

set top cnn_top
set rtl_dir ../rtl

puts "=== Reading RTL ==="
read_verilog -sv $rtl_dir/pe.v
read_verilog -sv $rtl_dir/mac_array.v
read_verilog -sv $rtl_dir/relu.v
read_verilog -sv $rtl_dir/cnn_regs.v
read_verilog -sv $rtl_dir/cnn_top.v

puts "=== Hierarchy ==="
hierarchy -top $top
hierarchy -check

puts "=== Generic synthesis ==="
synth -top $top -flatten

# Translate processes (always blocks) to netlist
proc -noopt
opt

# Extract FSM and optimize
fsm
opt

# Memory mapping
memory
opt

# Coarse-grain tech mapping
techmap
opt

# Standard cell mapping via ABC
puts "=== ABC technology mapping ==="
abc -g AND,OR,XOR
opt

# Remove unused cells
clean

puts "=== Statistics ==="
stat -width

puts "=== Write netlist ==="
write_verilog -noattr -noexpr synthesized/${top}_synth.v
write_json  synthesized/${top}_synth.json

puts "=== Area report ==="
tee -a synthesized/${top}_area.rpt stat -width

puts "=== Hierarchy after synthesis ==="
hierarchy -check

puts "=== Done ==="
