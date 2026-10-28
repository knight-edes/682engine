# Simulate the board harness (tb_zed_top) with xsim, outside the project.
#   vivado -mode batch -source scripts/run_board_sim.tcl
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
set wd   [file join $root build xsim_board]
file mkdir $wd
cd $wd
set srcs [concat $core_srcs [glob [file join $root rtl *.v]] [list [file join $root sim tb_zed_top.v]]]

proc run {args} {
    set cmd [auto_execok [lindex $args 0]]
    if {$cmd eq ""} { puts "ERROR: [lindex $args 0] not on PATH"; exit 1 }
    if {[catch {exec {*}$cmd {*}[lrange $args 1 end] 2>@1} out]} { puts $out; return -code error }
    return $out
}
run xvlog {*}$srcs
run xelab tb_zed_top -s tb_zed_top_sim -debug off
set log [run xsim tb_zed_top_sim -R]
puts $log
if {[string first "ALL TESTS PASSED" $log] >= 0} {
    puts "RESULT: board harness simulation PASSED"
} else {
    puts "RESULT: board harness simulation FAILED"; exit 1
}
