# Non-project OOC synthesis + place + route of the UNPIPELINED prince_top.
#
#   vivado -mode batch -source scripts/synth_ooc.tcl -tclargs period=40        ;# 25 MHz
#   vivado -mode tcl   -source scripts/synth_ooc.tcl -tclargs period=40 gui    ;# + open GUI on routed design
#
# period = clock constraint in ns (default 40 ns = 25 MHz)
set root [file normalize [file join [file dirname [info script]] ..]]
set part xc7z020clg484-1
set out  [file join $root reports]
file mkdir $out

proc arg {name default} {
    foreach a $::argv { if {[string match "$name=*" $a]} { return [lindex [split $a =] 1] } }
    return $default
}
set period [arg period 40]
set tag    "unpiped_${period}ns"

# Constraints written per run so the period always matches the argument
set xdc [file join $out "ooc_${tag}.xdc"]
set fh [open $xdc w]
puts $fh "create_clock -period $period -name clk \[get_ports clk\]"
puts $fh "set_property HD.CLK_SRC BUFGCTRL_X0Y0 \[get_ports clk\]   ;# model clock insertion delay in OOC"
# No set_input_delay/set_output_delay: in OOC with the clock tree modelled, a 0 ns
# input delay makes every port->register path a fake hold violation. Leaving the
# ports unconstrained characterises what matters here: register-to-register paths.
close $fh

read_verilog [glob [file join $root rtl *.v]]
read_xdc -mode out_of_context $xdc
synth_design -top prince_top -part $part -mode out_of_context
opt_design
place_design
route_design

report_utilization    -file [file join $out "util_${tag}.rpt"]
report_timing_summary -file [file join $out "timing_${tag}.rpt"] -max_paths 10
report_power          -file [file join $out "power_${tag}.rpt"]
write_checkpoint -force [file join $out "routed_${tag}.dcp"]

set wns [get_property SLACK [get_timing_paths -setup -max_paths 1 -nworst 1]]
set whs [get_property SLACK [get_timing_paths -hold  -max_paths 1 -nworst 1]]
set u   [report_utilization -return_string]
set luts ?; set regs ?
regexp {Slice LUTs\*?\s*\|\s*(\d+)}  $u -> luts
regexp {Slice Registers\s*\|\s*(\d+)} $u -> regs
set tmin [expr {$period - $wns}]
puts "RESULT: period=${period}ns ([format %.1f [expr {1000.0/$period}]] MHz) WNS=$wns WHS=$whs LUTs=$luts FFs=$regs"
puts "RESULT: setup [expr {$wns >= 0 ? {MET} : {NOT MET}}], hold [expr {$whs >= 0 ? {MET} : {NOT MET}}];\
      critical path ~[format %.2f $tmin] ns at this constraint"
puts "NOTE:   Fmax is only meaningful when the period is tight (WNS near 0);\
      with a loose period the tools stop optimising the path."
puts "RESULT: reports and routed_${tag}.dcp in $out"

if {[lsearch -exact $::argv gui] >= 0} {
    if {[catch {start_gui} err]} {
        puts "WARNING: start_gui failed ($err). Use -mode tcl, or later: vivado [file join $out routed_${tag}.dcp]"
    }
}
