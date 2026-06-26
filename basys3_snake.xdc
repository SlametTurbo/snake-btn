## Clock 100 MHz
set_property -dict { PACKAGE_PIN W5  IOSTANDARD LVCMOS33 } [get_ports clk100]
create_clock -add -name sys_clk -period 10.00 [get_ports clk100]

## Reset (btnC tengah)
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports btnC]

## Tombol arah onboard Basys3
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports btnU]
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports btnD]
set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports btnL]
set_property -dict { PACKAGE_PIN T17 IOSTANDARD LVCMOS33 } [get_ports btnR]

## SPI loader (Pmod JA)
set_property -dict { PACKAGE_PIN J1  IOSTANDARD LVCMOS33 } [get_ports spi_sclk]
set_property -dict { PACKAGE_PIN L2  IOSTANDARD LVCMOS33 } [get_ports spi_mosi]
set_property -dict { PACKAGE_PIN J2  IOSTANDARD LVCMOS33 } [get_ports spi_ceb]
set_property -dict { PACKAGE_PIN G2  IOSTANDARD LVCMOS33 } [get_ports spi_miso]

## OLED SSD1306 I2C (Pmod JC) -- open-drain + pull-up internal
## SCL -> JC1 (K17),  SDA -> JC2 (M18)
set_property -dict { PACKAGE_PIN K17 IOSTANDARD LVCMOS33 PULLUP true } [get_ports oled_scl]
set_property -dict { PACKAGE_PIN M18 IOSTANDARD LVCMOS33 PULLUP true } [get_ports oled_sda]

## LED onboard
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {led[3]}]
set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports {led[4]}]
set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 } [get_ports {led[5]}]
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports {led[6]}]
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports {led[7]}]
