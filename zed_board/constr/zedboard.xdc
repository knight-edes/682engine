## ZedBoard pin constraints for zed_top
## Pins from the Avnet/Digilent Zedboard-Master.xdc.
## Banks 34 (buttons) and 35 (switches) run at VADJ: LVCMOS25 assumes the J18
## jumper is on 1.8 V (factory default). If yours is on 2.5 V use LVCMOS25.

## 100 MHz clock - Bank 13
set_property -dict {PACKAGE_PIN Y9  IOSTANDARD LVCMOS33} [get_ports gclk]
create_clock -period 10.000 -name gclk [get_ports gclk]

## User LEDs - Bank 33 (3.3 V)
set_property -dict {PACKAGE_PIN T22 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN T21 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN U22 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN U21 IOSTANDARD LVCMOS33} [get_ports {led[3]}]
set_property -dict {PACKAGE_PIN V22 IOSTANDARD LVCMOS33} [get_ports {led[4]}]
set_property -dict {PACKAGE_PIN W22 IOSTANDARD LVCMOS33} [get_ports {led[5]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {led[6]}]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {led[7]}]

## Push buttons - Bank 34 (VADJ)
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS25} [get_ports btnc]
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS25} [get_ports btnl]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS25} [get_ports btnr]
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS25} [get_ports btnu]

## Slide switches - Bank 35 (VADJ)
set_property -dict {PACKAGE_PIN F22 IOSTANDARD LVCMOS25} [get_ports {sw[0]}]
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS25} [get_ports {sw[1]}]
set_property -dict {PACKAGE_PIN H22 IOSTANDARD LVCMOS25} [get_ports {sw[2]}]
set_property -dict {PACKAGE_PIN F21 IOSTANDARD LVCMOS25} [get_ports {sw[3]}]
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS25} [get_ports {sw[4]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS25} [get_ports {sw[5]}]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS25} [get_ports {sw[6]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS25} [get_ports {sw[7]}]

## Switches and buttons are asynchronous and synchronised in RTL; LEDs are slow.
set_false_path -from [get_ports {sw[*] btnc btnl btnr btnu}]
set_false_path -to   [get_ports {led[*]}]
