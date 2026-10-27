# Behavioural simulation of tb_prince in xsim; reports PASS/FAIL from the
# testbench's error counter and, on pass, can open the Vivado GUI.
#
# Usage:
#   vivado -mode batch -source scripts/run_sim.tcl                 ;# pass/fail only
#   vivado -mode tcl   -source scripts/run_sim.tcl -tclargs gui    ;# + switch to GUI with waveforms on pass
#     (must be -mode tcl: a batch-mode Vivado exits when the script ends and
#      takes any GUI it started with it)
#   (inside the GUI Tcl Console:  source scripts/run_sim.tcl)
set root [file normalize [file join [file dirname [info script]] ..]]
set xpr  [file join $root vivado_proj prince_zed.xpr]
set want_gui [expr {[lsearch -exact $::argv gui] >= 0}]

if {[catch {current_project}]} { open_project $xpr }

# The sim_1 runtime property (200 us) already covers the whole test
# ($finish at ~78 us), so no extra "run all" is needed.
launch_simulation -simset sim_1 -mode behavioral

# Ask the simulator for the testbench's own error counter (no log parsing).
# errors stays 0 only if every unit test, KAT, golden vector and round trip passed
# AND the vector file loaded.
if {[catch {get_value -radix unsigned /tb_prince/errors} nerr]} {
    puts "ERROR: could not read /tb_prince/errors ($nerr)"
    set nerr -1
}

if {$nerr eq "0"} {
    puts "RESULT: ALL TESTS PASSED (errors = 0)"
    if {$want_gui} {
        # start_gui turns this same Vivado process (launched with -mode tcl)
        # into the GUI, keeping the project and the loaded simulation.
        if {[catch {start_gui} err]} {
            puts "WARNING: start_gui failed ($err)."
            puts "         Launch with -mode tcl (not batch), or open manually: vivado $xpr"
        }
    }
} else {
    puts "RESULT: TESTS FAILED (errors = $nerr) - see simulate.log; GUI not opened"
    close_sim -force
    if {$want_gui} { exit 1 }   ;# non-zero exit code for batch runs
}
