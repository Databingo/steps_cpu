#!/bin/sh
#
# build.sh - Final version with memory model fix and linking the math library.
#
set -e

# --- Toolchain Paths ---
# IMPORTANT: Point this to the 'bin' directory of your xpack toolchain.
# Replace this path with the actual path on your system.
XPACK_TOOLCHAIN_BIN="/usr/local/projects/bin/xpack-riscv-none-elf-gcc-14.2.0-3/bin"

if [ ! -f "${XPACK_TOOLCHAIN_BIN}/riscv-none-elf-gcc" ]; then
    echo "Error: riscv-none-elf-gcc not found in ${XPACK_TOOLCHAIN_BIN}"
    echo "Please edit the XPACK_TOOLCHAIN_BIN variable in this script."
    exit 1
fi

TARGET_PREFIX="${XPACK_TOOLCHAIN_BIN}/riscv-none-elf-"

# --- Compiler Flags ---
# -mcmodel=medany handles large distances between code and data.
#
CFLAGS="-march=rv64gc -mabi=lp64d -g -O3 -ffreestanding -nostdlib -mcmodel=medany"

# --- Linker Flags ---
# We keep -nostdlib to avoid the full C library, but we add -lm
# to specifically request the math library for functions like sqrtf, expf.
#
LDFLAGS="-T linker.ld -nostdlib -lm"

echo "--- Compiling C and Assembly Code using xpack GCC ---"

"${TARGET_PREFIX}gcc" $CFLAGS -c start.S -o start.o
"${TARGET_PREFIX}gcc" $CFLAGS -c run.c -o run.o

echo "--- Linking Executable using xpack GCC/LD ---"

# Use GCC as the linker driver. Pass LDFLAGS at the end.
# GCC knows how to find its own libm.a when you pass -lm.
"${TARGET_PREFIX}gcc" $CFLAGS -o kernel.elf start.o run.o $LDFLAGS

echo "--- Creating Flat Binary using xpack objcopy ---"

"${TARGET_PREFIX}objcopy" -O binary kernel.elf kernel.bin

echo "--- Build successful! kernel.bin is ready. ---"
