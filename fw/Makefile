# fw makefile

### tools ###

# tools path
ifndef OR32_OLD_TOOLCHAIN_PATH
OR32_OLD_TOOLCHAIN_PATH=~/Dropbox/work/electronics/fpga/jpegdec/sw/or32-toolchain-3.2-old/bin/
endif

ifndef OR32_TOOLCHAIN_PATH
OR32_TOOLCHAIN_PATH=~/Dropbox/work/electronics/fpga/jpegdec/sw/or32-elf-1.0rc1/bin/
endif

ifndef CROSS_COMPILE
CROSS_COMPILE = $(OR32_TOOLCHAIN_PATH)or32-elf-
endif


# programs
AS	= $(CROSS_COMPILE)as
LD	= $(CROSS_COMPILE)ld
CC	= $(CROSS_COMPILE)gcc
AR	= $(CROSS_COMPILE)ar
NM	= $(CROSS_COMPILE)nm
STRIP	= $(CROSS_COMPILE)strip
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
RANLIB	= $(CROSS_COMPILE)ranlib


# flags
CFLAGS +=   -W -Wall -std=gnu99 \
            -Os \
            -fomit-frame-pointer -ffreestanding -static -combine -fwhole-program \
            -fno-strict-aliasing \
            -fno-builtin -nostdlib \
            -Wl,--relax \
            -mhard-mul -mhard-div

LDFLAGS +=


### variables ###
BUILD_USER=\"$(USER)\"
BUILD_T=$$(date +%Y-%m-%d)
BUILD_TIME=\"$(BUILD_T)\"
BUILD_NUM=$$(cat build_num.txt)


### fw specific ###

# include dirs
CINCLUDES += -I.

# headers
HEADERS=

# asm sources
ASM_SOURCES=fw.S

# common sources
COMMON_SOURCES=

# all sources
ALL_SOURCES = $(ASM_SOURCES) $(COMMON_SOURCES)

# linker script
ROM_LD=rom.ld
RAM_LD=ram.ld


### build specific ###

# default fw source
FW_SOURCES=


### build rules ###

# all
all: out/fw.hex

out/firmware.or32: $(RAM_LD) $(ALL_SOURCES) $(FW_SOURCES)
	@echo out/firmware.or32
	@#mkdir out
	@$(CC) -D__BUILD_USER=$(BUILD_USER) -D__BUILD_TIME=$(BUILD_TIME) -D__BUILD_NUM=$(BUILD_NUM) $(CFLAGS) $(CINCLUDES) $(ALL_SOURCES) $(FW_SOURCES) -T$(RAM_LD) -o out/firmware.or32
	@echo $$(($$(cat build_num.txt) + 1)) > build_num.txt
	@$(OBJDUMP) -DSx out/firmware.or32 > out/firmware.dis.S

# bin file
out/firmware.bin: out/firmware.or32
	@echo out/firmware.bin
	@$(OBJCOPY) -O binary out/firmware.or32 out/firmware.bin

# hex file
out/fw.hex: out/firmware.bin
	@echo out/fw.hex
	@xxd -ps -c 4 out/firmware.bin > out/fw.hex

# clean
clean:
	@echo clean
	@rm -rf ./out/*

