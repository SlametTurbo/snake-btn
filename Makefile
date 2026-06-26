# ==============================================================================
# Makefile -- snake-btn (Snake @ Basys3, tombol onboard, OLED SSD1306)
# Project baru, berbagi RTL & toolchain dgn mriscv-spi (parent bersama).
#
#   make synth          - bitstream (spi.bit)
#   make flash          - flash ke board
#   make prog FW=snake_btn   - compile + upload via SPI
#   make build FW=snake_btn  - compile saja
#   make clean | clean-fw
# ==============================================================================
.DEFAULT_GOAL := help

# --- sumber bersama (letak relatif: snake-btn/ dan mriscv-spi/ sejajar) ---
SIBLING      ?= ../mriscv-spi
MRISCV       ?= $(SIBLING)/mriscv
SP32B1024    ?= $(SIBLING)/SP32B1024.v
SPI_PY       ?= $(SIBLING)/cheetah_mriscv.py

# --- variabel openXC7.mk ---
PROJECT      := spi
PART         := xc7a35tcpg236-1
FAMILY       := artix7
BOARD        := basys3
TOP          := basys3_top
TOP_MODULE   := basys3_top
TOP_VERILOG  := basys3_top.v
XDC          ?= basys3_snake.xdc

RTL_DIRS := \
	$(MRISCV)/mriscv_axi/impl_axi \
	$(MRISCV)/mriscv_axi/axi4_interconnect \
	$(MRISCV)/mriscv_axi/AXI_SP32B1024 \
	$(MRISCV)/mriscv_axi/spi_axi_master \
	$(MRISCV)/mriscv_axi/spi_axi_slave \
	$(MRISCV)/mriscv_axi/DAC_interface_AXI \
	$(MRISCV)/mriscv_axi/ADC_interface_AXI \
	$(MRISCV)/mriscv_axi/GPIO \
	$(MRISCV)/mriscv_axi/util \
	$(MRISCV)/mriscvcore \
	$(MRISCV)/mriscvcore/ALU \
	$(MRISCV)/mriscvcore/DECO_INSTR \
	$(MRISCV)/mriscvcore/FSM \
	$(MRISCV)/mriscvcore/IRQ \
	$(MRISCV)/mriscvcore/MEMORY_INTERFACE \
	$(MRISCV)/mriscvcore/MULT \
	$(MRISCV)/mriscvcore/REG_FILE \
	$(MRISCV)/mriscvcore/UTILITIES
RTL_RAW            := $(foreach d,$(RTL_DIRS),$(wildcard $(d)/*.v))
ADDITIONAL_SOURCES := $(SP32B1024) $(filter-out %_tb.v,$(RTL_RAW))

OPENXC7_MK   ?= ../openXC7.mk
CHIPDB       ?= ../chipdb

# --- firmware ---
FW           ?= snake_btn
RISCV_PREFIX ?= riscv64-unknown-elf
CC           := $(RISCV_PREFIX)-gcc
OBJCOPY      := $(RISCV_PREFIX)-objcopy
OBJDUMP      := $(RISCV_PREFIX)-objdump
SIZE         := $(RISCV_PREFIX)-size
CFLAGS       := -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -ffreestanding -Os -Wall -I.

SPI_UPLOAD   := python3 $(SPI_PY)
# kHz; <= ~200 utk core /64
SPI_BITRATE  ?= 100

# --- target ---
.PHONY: synth flash build upload prog clean-fw help check-fw

synth: $(PROJECT).bit
flash: program
build: check-fw $(FW).bin

$(FW).elf: $(FW).c crt0.S link_c.ld mriscv.h
	@echo "==== COMPILE: $(FW).c ===="
	$(CC) $(CFLAGS) -T link_c.ld crt0.S $(FW).c -o $@
	@$(SIZE) $@

$(FW).bin: $(FW).elf
	$(OBJCOPY) -O binary $< $@
	@echo "[OK] $(FW).bin  ($$(wc -c < $@) byte)"

upload: check-fw
	@[ -f "$(FW).bin" ] || { echo "[ERR] $(FW).bin tidak ada. Jalankan: make build"; exit 1; }
	$(SPI_UPLOAD) --bitrate $(SPI_BITRATE) upload $(FW).bin

prog: build upload

clean-fw:
	rm -f *.elf *.bin
	@echo "[OK] firmware bersih."

check-fw:
	@[ -f "$(FW).c" ] || { echo "[ERR] $(FW).c tidak ada."; exit 1; }

help:
	@echo ""
	@echo "snake-btn -- Snake @ Basys3 (btnU/D/L/R + OLED)"
	@echo "================================================"
	@echo "  make synth              bitstream -> spi.bit"
	@echo "  make flash              flash ke board (JTAG)"
	@echo "  make prog               compile + upload snake_btn"
	@echo "  make build FW=snake_btn compile saja"
	@echo "  make clean | clean-fw"
	@echo ""
	@echo "RTL dari  : $(MRISCV)"
	@echo "openXC7.mk: $(OPENXC7_MK)"
	@echo "chipdb    : $(CHIPDB)"
	@echo "SPI upload: $(SPI_PY)"
	@echo ""

include $(OPENXC7_MK)