# Synthesise, implement and write the bitstream for the ZedBoard test harness.
#   vivado -mode batch -source scripts/build_bitstream.tcl
#   vivado -mode tcl   -source scripts/build_bitstream.tcl -tclargs gui   ;# open GUI afterwards
set root [file normalize [file join [file dirname [info script]] ..]]
# Board files live in .../682engine/zed_board; the PRINCE core RTL lives in
# .../682engine/prince_vivado/prince_vivado/rtl. Override with -tclargs prince_rtl=<path>.
set prince_rtl [file normalize [file join $root .. prince_vivado prince_vivado rtl]]
foreach a $::argv { if {[string match "prince_rtl=*" $a]} { set prince_rtl [file normalize [string range $a 11 end]] } }
if {![file exists [file join $prince_rtl prince_top.v]]} {
    puts "ERROR: prince_top.v not found in $prince_rtl"
    puts "       pass the folder explicitly: -tclargs prince_rtl=C:/path/to/rtl"
    exit 1
}
set core_srcs [glob [file join $prince_rtl prince_*.v]]
puts "INFO: PRINCE core RTL from $prince_rtl"
set part xc7z020clg484-1
set out  [file join $root build]
file mkdir $out

read_verilog [concat $core_srcs [glob [file join $root rtl *.v]]]
read_xdc [file join $root constr zedboard.xdc]

synth_design -top zed_top -part $part
opt_design
place_design
route_design

report_utilization    -file [file join $out util_zed_top.rpt]
report_timing_summary -file [file join $out timing_zed_top.rpt] -max_paths 10
report_drc            -file [file join $out drc_zed_top.rpt]
write_checkpoint -force [file join $out zed_top_routed.dcp]

set wns [get_property SLACK [get_timing_paths -setup -max_paths 1 -nworst 1]]
set whs [get_property SLACK [get_timing_paths -hold  -max_paths 1 -nworst 1]]
puts "RESULT: WNS=$wns WHS=$whs ns (both must be >= 0)"
if {$wns < 0 || $whs < 0} {
    puts "ERROR: timing not met - not writing a bitstream. See build/timing_zed_top.rpt"
    if {[lsearch -exact $::argv gui] < 0} { exit 1 }
} else {
    write_bitstream -force [file join $out zed_top.bit]
    puts "RESULT: bitstream written to [file join $out zed_top.bit]"
}
if {[lsearch -exact $::argv gui] >= 0} { catch {start_gui} }
