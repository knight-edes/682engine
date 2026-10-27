# Non-project OOC synthesis + implementation of prince_top; writes reports.
# Usage:  vivado -mode batch -source scripts/synth_ooc.tcl
set root [file normalize [file join [file dirname [info script]] ..]]
set part xc7z020clg484-1
set out  [file join $root reports]
file mkdir $out

read_verilog [glob [file join $root rtl *.v]]
read_xdc -mode out_of_context [file join $root constr prince_ooc.xdc]

synth_design -top prince_top -part $part -mode out_of_context
report_utilization    -file [file join $out util_synth.rpt]

opt_design
place_design
route_design

report_utilization     -file [file join $out util_routed.rpt]
report_timing_summary  -file [file join $out timing_routed.rpt] -max_paths 10
report_power           -file [file join $out power_routed.rpt]

set wns [get_property SLACK [get_timing_paths -setup -max_paths 1 -nworst 1]]
set fmax [format %.1f [expr {1000.0 / (10.0 - $wns)}]]
puts "RESULT: WNS = $wns ns at 10 ns target -> estimated Fmax ~ $fmax MHz"
puts "RESULT: reports written to $out"
