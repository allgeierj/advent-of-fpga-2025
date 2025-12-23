# Input args
set DAY [lindex $argv 0] 

# Build list of defines
#set DEFINES {}
#lappend DEFINES "ROM_DEPTH=$ROM_DEPTH"

# Target part
set PART xc7a35tcpg236-1

# Read RTL
read_verilog -sv common/defines.svh
read_verilog -sv [glob common/*.sv]
read_verilog -sv [glob $DAY/rtl/*.sv]
set_property file_type SystemVerilog [get_files *.sv]

# Elaboration + basic RTL checks (lint-ish)
synth_design -top top -part $PART -rtl

# Full synthesis
synth_design -top top -part $PART

# Save synthesized design
write_checkpoint -force synth.dcp

# Implementation
opt_design
place_design
route_design

# Save implemented design
write_checkpoint -force impl.dcp

# Reports
#report_utilization -file impl_util.rpt
#report_timing_summary -file impl_timing.rpt