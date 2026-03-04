#!/bin/sh
set -e
XPACK_TOOLCHAIN_BIN="/usr/local/projects/bin/xpack-riscv-none-elf-gcc-14.2.0-3/bin"
TARGET_PREFIX="${XPACK_TOOLCHAIN_BIN}/riscv-none-elf-"
CFLAGS="-march=rv64gc -mabi=lp64d -g -O3 -ffreestanding -nostdlib -mcmodel=medany"
LDFLAGS="-T linkert.ld -nostdlib -lm"

echo "--- Compiling FPU bare-metal test C code ---"
"${TARGET_PREFIX}gcc" $CFLAGS -c sta.S -o start.o
"${TARGET_PREFIX}gcc" $CFLAGS -c fpu_baremetal_test.c -o fpu_test.o

echo "--- Linking Executable ---"
"${TARGET_PREFIX}gcc" $CFLAGS -o fpu_test.elf start.o fpu_test.o $LDFLAGS

echo "--- Creating Flat Binary ---"
"${TARGET_PREFIX}objcopy" -O binary fpu_test.elf fpu_test.bin

echo "--- Build successful! fpu_test.bin is ready. ---" 
