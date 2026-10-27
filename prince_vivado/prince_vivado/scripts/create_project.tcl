# Creates the Vivado project for the PRINCE engine on ZedBoard.
# Usage (from the repo root, in the Vivado Tcl Console or Tcl Shell):
#   source scripts/create_project.tcl
set root [file normalize [file join [file dirname [info script]] ..]]
set part xc7z020clg484-1

create_project prince_zed [file join $root vivado_proj] -part $part -force

# Use the ZedBoard board part if its board files are installed (version varies by Vivado release)
set bp [lindex [lsort [get_board_parts -quiet *zedboard*]] end]
if {$bp ne ""} {
    set_property board_part $bp [current_project]
    puts "INFO: board part set to $bp"
} else {
    puts "WARNING: ZedBoard board files not found; using bare part $part (fine for now)"
}

# Design sources
add_files -norecurse [glob [file join $root rtl *.v]]
set_property top prince_top [get_filesets sources_1]

# Timing constraints; synthesize prince_top out of context (no I/O pins yet)
add_files -fileset constrs_1 -norecurse [file join $root constr prince_ooc.xdc]
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} \
    -objects [get_runs synth_1]

# Simulation sources. The .mem file is copied into the xsim run directory.
add_files -fileset sim_1 -norecurse [list [file join $root sim tb_prince.v] \
                                          [file join $root sim vectors_rand.mem]]
set_property top tb_prince [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {200us} -objects [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "INFO: project created at [file join $root vivado_proj prince_zed.xpr]"
