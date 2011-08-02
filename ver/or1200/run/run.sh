#!/bin/sh

#
# OR1200-QMEM testbench run file.
# Needs Icarus Verilog & GTKWave
#


# defines
BIN_DIR=../out/bin
HEX_DIR=../out/hex
LOG_DIR=../out/log
WAV_DIR=../out/wav

echo "Starting or1200 testbench ..."

# clean
rm -rf ../out/*

# create dirs
mkdir -p ../out/{bin,hex,log,wav}

# build fw
make -C ../../../fw/
cp ../../../fw/out/fw.hex ../out/hex/

# compile
iverilog -Wall -Wno-timescale -I../../../rtl/or1200 -o $BIN_DIR/or1200_tb -crtl_files.lst 2>&1 | tee $LOG_DIR/iverilog.log

# run sim
$BIN_DIR/or1200_tb -fst

# start gtkwave
gtkwave $WAV_DIR/or1200_tb_waves.fst gtkwave.sav &

# done
echo "DONE."

