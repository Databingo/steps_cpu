#!/bin/sh
#
# build.sh - Final version with memory model fix.
#
set -e

# --- Toolchain Paths ---
XPACK_TOOLCHAIN_BIN="/usr/local/projects/bin/xpack-riscv-none-elf-gcc-14.2.0-3/bin"

if [ ! -f "${XPACK_TOOLCHAIN_BIN}/riscv-none-elf-gcc" ]; then
    echo "Error: riscv-none-elf-gcc not found in ${XPACK_TOOLCHAIN_BIN}"
    exit 1
fi

TARGET_PREFIX="${XPACK_TOOLCHAIN_BIN}/riscv-none-elf-"

# --- Compiler Flags ---
#
# Added -mcmodel=medany to handle large distances between code and data.
# This generates different, more flexible address loading instructions.
#
CFLAGS="-march=rv64gc -mabi=lp64d -g -O3 -ffreestanding -nostdlib -mcmodel=medany"

# --- Linker Flags ---
LDFLAGS="-T linker.ld"

echo "--- Compiling C and Assembly Code using xpack GCC ---"

"${TARGET_PREFIX}gcc" $CFLAGS -c start.S -o start.o
"${TARGET_PREFIX}gcc" $CFLAGS -c run.c -o run.o

echo "--- Linking Executable using xpack GCC/LD ---"

"${TARGET_PREFIX}gcc" $CFLAGS -o kernel.elf start.o run.o $LDFLAGS

echo "--- Creating Flat Binary using xpack objcopy ---"

"${TARGET_PREFIX}objcopy" -O binary kernel.elf kernel.bin

echo "--- Build successful! kernel.bin is ready. ---"
