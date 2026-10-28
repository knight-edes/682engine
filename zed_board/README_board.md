# ZedBoard hardware test (unpipelined PRINCE @ 25 MHz)

New files (add to the repo next to the existing rtl/, sim/, scripts/, constr/):
  rtl/zed_top.v, rtl/debounce.v      board harness (MMCM 100->25 MHz, buttons, LEDs, KAT ROM, BIST)
  sim/tb_zed_top.v                   presses buttons in simulation and checks LEDs
  constr/zedboard.xdc                pins + clock (switch/button IOSTANDARD assumes VADJ = 1.8 V)
  scripts/run_board_sim.tcl          xsim of the harness
  scripts/build_bitstream.tcl        synth + impl + bitstream -> build/zed_top.bit
  scripts/program_fpga.tcl           JTAG programming

Flow:
  vivado -mode batch -source scripts/run_board_sim.tcl     # expect "board harness simulation PASSED"
  vivado -mode batch -source scripts/build_bitstream.tcl   # expect WNS, WHS >= 0 and a .bit
  vivado -mode batch -source scripts/program_fpga.tcl      # board on, JTAG USB (J17) connected

Controls: SW0 mode | SW3..1 vector 0-4 | SW6..4 byte | SW7 view | BTNC KAT | BTNR BIST | BTNL fault | BTNU reset
Status LEDs (SW7=0): LD7 KAT pass, LD6 KAT fail, LD5 BIST pass, LD4 BIST fail,
                     LD3 BIST busy, LD2 fault on, LD1 mode of last KAT, LD0 heartbeat
