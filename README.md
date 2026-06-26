# snake-btn

Snake game running on mriscv RV32I soft-core processor, Digilent Basys3 FPGA,
displayed on SSD1306 OLED 128x64 via I2C bit-bang.

## Hardware
- Digilent Basys3 (Xilinx Artix-7 XC7A35T)
- OLED SSD1306 128x64 (Pmod JC: SCL=K17, SDA=M18)
- Controls: onboard buttons btnU / btnD / btnL / btnR

## Toolchain
- openXC7 (Yosys + nextpnr-xilinx + fasm2frames + xc7frames2bit)
- RISC-V GCC (rv32i, -nostdlib)
- SPI program loader via Total Phase Cheetah

## Quick start
```bash
make synth      # build bitstream (spi.bit)
make flash      # flash to board via JTAG
make prog       # compile + upload game via SPI
```

## Directory structure
Expects the following siblings in `~/demo-projects/`:
- `openXC7.mk` and `chipdb/` from openXC7/demo-projects
- `mriscv-spi/mriscv/` — RTL source (onchipuis/mriscv)
- `mriscv-spi/SP32B1024.v`, `cheetah_mriscv.py`
