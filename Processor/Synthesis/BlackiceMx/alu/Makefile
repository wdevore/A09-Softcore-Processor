TOP_FILE = top.v

SUB_MODULES_FILES = ../../../Modules/constants.v \
	../../../Modules/alu.v \
	../../../Modules/register.v

MODULES_FILES = ${TOP_FILE} ${SUB_MODULES_FILES}

BUILD_BIN = /media/RAMDisk

ICESTORM_TOOLCHAIN = /usr/local

# You can add verilog generation if you use: ...top; write_verilog;
YOSYS_COMMAND = "synth_ice40 -blif ${BUILD_BIN}/chip.blif -json ${BUILD_BIN}/hardware.json -top top"

# The Tiny shows up as generally ACM0 or ACM1 depending on what other
# devices you have connected. Be sure to run "dmesg -w" and see what
# the device name is.
TARGET_PORT = /dev/ttyACM0

PINS_CONSTRAINTS = pins.pcf

.PHONY: all

all: build route upload

build: ${MODULES_FILES} ${PINS_CONSTRAINTS}
	@echo "##### Building..."
	${ICESTORM_TOOLCHAIN}/bin/yosys -p ${YOSYS_COMMAND} \
	-l ${BUILD_BIN}/yo.log \
	-DUSE_STATIC \
	-q \
	-defer \
	${MODULES_FILES}

route: ${BUILD_BIN}/hardware.json
	@echo "##### Routing..."
	${ICESTORM_TOOLCHAIN}/bin/nextpnr-ice40 --hx8k \
	-q \
	--package tq144:4k \
	--pcf ${PINS_CONSTRAINTS} \
	-l ${BUILD_BIN}/next.log \
	--json ${BUILD_BIN}/hardware.json \
	--asc ${BUILD_BIN}/hardware.asc

upload: ${BUILD_BIN}/hardware.asc
	@echo "##### Packing..."
	${ICESTORM_TOOLCHAIN}/bin/icepack ${BUILD_BIN}/hardware.asc ${BUILD_BIN}/hardware.bin
	@echo "##### Uploading..."
	stty -F ${TARGET_PORT} raw
	cat ${BUILD_BIN}/hardware.bin >${TARGET_PORT}

