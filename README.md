<<<<<<< HEAD
# PRINCE encrypt/decrypt engine — Vivado flow (ZedBoard, xc7z020clg484-1)

## Layout
rtl/      synthesizable Verilog (S-layer, M', SR, rounds, core, prince_top)
sim/      tb_prince.v + vectors_rand.mem (256 golden-model vectors)
constr/   prince_ooc.xdc (100 MHz clock, timing only, no pins)
scripts/  create_project.tcl, run_sim.tcl, synth_ooc.tcl
model/    prince_ref.py (Python golden model; only needed to regenerate vectors)

## 1. Create the project (once)
Vivado Tcl Console or Tcl Shell, from this folder:
    cd <path-to-this-folder>
    source scripts/create_project.tcl
Windows paths: use forward slashes in `cd`, e.g. cd C:/work/prince_vivado

## 2. Behavioural simulation (xsim)
GUI:   Flow Navigator > Run Simulation > Run Behavioral Simulation, then `run all`
Batch: vivado -mode batch -source scripts/run_sim.tcl
Pass:  Tcl console / vivado.log ends with "ALL TESTS PASSED".
If you see "could not load vectors_rand.mem", the .mem was not copied into
vivado_proj/prince_zed.sim/sim_1/behav/xsim/ — copy it there and rerun.

## 3. Timing and utilization (out-of-context)
Batch: vivado -mode batch -source scripts/synth_ooc.tcl
Prints "RESULT: WNS = ..." and writes reports/util_routed.rpt,
reports/timing_routed.rpt, reports/power_routed.rpt.
WNS >= 0 means the single-cycle core closes at 100 MHz. If negative, the
next step is a pipeline register after the middle layer.

## Regenerate vectors (optional)
    python model/prince_ref.py sim/vectors_rand.mem 256
=======
# 682engine
>>>>>>> fc247edb30fdddbdd2722932b834a95428e0fd23
