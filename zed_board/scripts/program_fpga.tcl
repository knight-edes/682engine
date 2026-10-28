# Program the ZedBoard PL over JTAG (USB cable on the PROG/J17 port).
#   vivado -mode batch -source scripts/program_fpga.tcl
set root [file normalize [file join [file dirname [info script]] ..]]
set bit  [file join $root build zed_top.bit]
if {![file exists $bit]} { puts "ERROR: $bit not found - run build_bitstream.tcl first"; exit 1 }

open_hw_manager
connect_hw_server
open_hw_target
set dev [lindex [get_hw_devices xc7z020*] 0]
if {$dev eq ""} { puts "ERROR: no xc7z020 found on the JTAG chain: [get_hw_devices]"; exit 1 }
current_hw_device $dev
set_property PROGRAM.FILE $bit $dev
program_hw_devices $dev
puts "RESULT: programmed $dev with $bit (DONE LED on the board should be lit)"
close_hw_target
disconnect_hw_server
close_hw_manager
