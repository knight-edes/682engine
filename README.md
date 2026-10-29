# 682engine

Single-switch PRINCE encrypt/decrypt engine on the ZedBoard (Zynq-7000 XC7Z020-CLG484-1).
EEC-300 project, Department of Electrical Engineering, IIT Roorkee.

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

## 3. Timing and utilisation (out-of-context)
(Superseded: see "Command reference" below for the current synth_ooc.tcl options.)
Batch: vivado -mode batch -source scripts/synth_ooc.tcl
Prints "RESULT: WNS = ..." and writes reports/util_routed.rpt,
reports/timing_routed.rpt, reports/power_routed.rpt.
WNS >= 0 means the single-cycle core closes at 100 MHz. If negative, the
next step is a pipeline register after the middle layer.

## Regenerate vectors (optional)
    python model/prince_ref.py sim/vectors_rand.mem 256

---

# Command reference

All commands are for **Git Bash** (Windows) or a Linux shell with Vivado 2025.1
on the PATH. Paths below are relative to the repository root.

```
682engine/
├── prince_vivado/prince_vivado/   PRINCE core: rtl/, sim/, scripts/, constr/, model/, reports/
└── zed_board/                     board harness: rtl/, sim/, scripts/, constr/, tools/, build/
```

## 0. One-time setup

```bash
# Vivado on PATH (Linux; adjust version/path). On Windows, open Git Bash after installing
# Vivado, or use the "Vivado 2025.1 Tcl Shell" from the Start menu.
source /tools/Xilinx/Vivado/2025.1/settings64.sh
which vivado                         # must print a path

git clone https://github.com/knight-edes/682engine.git
cd 682engine
```

Three ways to run any script:

| Mode | Command | Use |
|---|---|---|
| Batch | `vivado -mode batch -source <script>.tcl [-tclargs ...]` | run and exit (no window) |
| Tcl | `vivado -mode tcl -source <script>.tcl -tclargs ... gui` | run, then switch to the GUI (`gui` argument) |
| GUI console | open Vivado, Tcl Console: `cd <folder>` then `source scripts/<script>.tcl` | inside an open GUI |

Do **not** run `source scripts/x.tcl` in bash itself; bash cannot execute Tcl.

## 1. PRINCE core (`prince_vivado/prince_vivado`)

```bash
cd prince_vivado/prince_vivado
```

### 1.1 Create the Vivado project (once, or after moving the folder)
```bash
vivado -mode batch -source scripts/create_project.tcl
vivado vivado_proj/prince_zed.xpr                  # open it in the GUI
```

### 1.2 Behavioural simulation (xsim)
```bash
vivado -mode batch -source scripts/run_sim.tcl                 # pass/fail only
vivado -mode tcl   -source scripts/run_sim.tcl -tclargs gui    # on pass, open GUI with waveforms
```
Pass: `RESULT: ALL TESTS PASSED (errors = 0)`. Checks: unit properties, 5 published
test vectors (enc + dec), 256 golden-model vectors, 1,000 round trips.

### 1.3 Out-of-context synthesis + implementation of `prince_top`
```bash
vivado -mode batch -source scripts/synth_ooc.tcl -tclargs period=40        # 25 MHz (default)
vivado -mode batch -source scripts/synth_ooc.tcl -tclargs period=25        # 40 MHz
vivado -mode batch -source scripts/synth_ooc.tcl -tclargs period=24        # near Fmax (~42 MHz)
vivado -mode tcl   -source scripts/synth_ooc.tcl -tclargs period=40 gui    # + open GUI on routed design
vivado reports/routed_unpiped_40ns.dcp                                      # reopen a finished run
```
Outputs in `reports/`: `util_unpiped_<P>ns.rpt`, `timing_unpiped_<P>ns.rpt`,
`power_unpiped_<P>ns.rpt`, `routed_unpiped_<P>ns.dcp`. The log ends with
`RESULT: ... WNS=... WHS=...` and `setup MET, hold MET`.
Fmax is only meaningful from a run whose period is tight (WNS close to 0).

### 1.4 Golden model (optional, needs Python 3)
```bash
python model/prince_ref.py                          # checks the 5 published vectors
python model/prince_ref.py sim/vectors_rand.mem 256 # regenerate random vectors
```

## 2. ZedBoard harness (`zed_board`)

```bash
cd zed_board          # from the repo root
```
The scripts read the core RTL from `../prince_vivado/prince_vivado/rtl` automatically.
Elsewhere: add `-tclargs prince_rtl=C:/path/to/rtl` to `run_board_sim.tcl` / `build_bitstream.tcl`.

### 2.1 Simulate the harness (buttons, LEDs, OLED)
```bash
vivado -mode batch -source scripts/run_board_sim.tcl
```
Pass: `RESULT: tb_zed_top PASSED` and `RESULT: tb_oled PASSED`.
OLED frames are dumped to `build/xsim_board/frame_*.hex`; render them with
```bash
python tools/render.py build/xsim_board/frame_idle.hex build/xsim_board/frame_enc4.hex oled.png
```

### 2.2 Build the bitstream
```bash
vivado -mode batch -source scripts/build_bitstream.tcl
vivado -mode tcl   -source scripts/build_bitstream.tcl -tclargs gui   # + open GUI
vivado build/zed_top_routed.dcp                                         # reopen later
```
Writes `build/zed_top.bit` only if WNS and WHS are both >= 0. Reports:
`build/util_zed_top.rpt`, `build/timing_zed_top.rpt`, `build/drc_zed_top.rpt`.

**VADJ jumper (J18):** button/switch pins use `LVCMOS25` in `constr/zedboard.xdc`,
matching J18 = 2.5 V. If J18 is on 1.8 V:
```bash
sed -i 's/LVCMOS25/LVCMOS18/g' constr/zedboard.xdc
```
Rebuild the bitstream after any XDC change.

### 2.3 Program the board
Board powered, micro-USB in the **PROG** port (J17):
```bash
vivado -mode batch -source scripts/program_fpga.tcl
```
Expect `RESULT: programmed ...`, the blue DONE LED on, LD0 blinking.

### 2.4 Operating the board
| Control | Function |
|---|---|
| SW0 | mode: down = encrypt, up = decrypt |
| SW3 SW2 SW1 | test vector 0-4 (binary) |
| SW7 | LEDs: down = status, up = byte view (SW6..SW4 select byte) |
| BTNC | run the selected known-answer test |
| BTNR | built-in self-test, 2^20 random encrypt-then-decrypt blocks |
| BTNL | fault injection on/off (flips one key bit on decrypt) |
| BTNU | reset |

OLED lines: mode/vector/KAT result, input, output, `BIST:<state>  F:<fault>`.
Status LEDs: LD7 KAT pass, LD6 KAT fail, LD5 BIST pass, LD4 BIST fail,
LD3 BIST busy, LD2 fault on, LD1 last mode, LD0 heartbeat.

Expected for vector 4 (SW3 up): encrypt `0123456789ABCDEF` -> `AE25AD3CA8FA9CCF`,
decrypt the reverse; `KAT:PASS` both ways. BTNR -> `BIST:PASS`; BTNL then BTNR -> `BIST:FAIL  F:ON`.

## 3. Typical full run

```bash
cd prince_vivado/prince_vivado
vivado -mode batch -source scripts/run_sim.tcl
vivado -mode batch -source scripts/synth_ooc.tcl -tclargs period=40
cd ../../zed_board
vivado -mode batch -source scripts/run_board_sim.tcl
vivado -mode batch -source scripts/build_bitstream.tcl
vivado -mode batch -source scripts/program_fpga.tcl
```

## 4. Troubleshooting

| Symptom | Fix |
|---|---|
| `bash: create_project: command not found` | you ran `source x.tcl` in bash; use `vivado -mode batch -source x.tcl` |
| GUI does not open with `gui` | use `-mode tcl`, not `-mode batch` |
| `could not load vectors_rand.mem` | re-run `create_project.tcl`; the .mem must be in the sim fileset |
| `prince_top.v not found` | pass `-tclargs prince_rtl=<path to core rtl>` |
| `no xc7z020 found on the JTAG chain` | board on, USB in PROG port, power-cycle; set boot jumpers to JTAG |
| OLED text mirrored / upside down / garbled | in `rtl/oled_display.v` set `SEG_REMAP=8'hA0` / `COM_SCAN=8'hC0` / `COM_CFG=8'h20`, rebuild |
| Hold violations (WHS < 0) only in OOC runs | out-of-context I/O artifact; use the current `synth_ooc.tcl` (no I/O delays) |

## 5. Git

```bash
git add .
git commit -m "message"
git pull --no-rebase        # if the push is rejected
git push
```
Generated output is ignored via `.gitignore` (`vivado_proj/`, `*.log`, `*.jou`, `*.dcp` in reports).