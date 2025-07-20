#!/bin/bash
set -e

# The prefix for the cross-compiler
TARGET=riscv64-unknown-elf

# Compile all C and Assembly files into object files
$TARGET-gcc -c start.S -o start.o -march=rv64gc -mabi=lp64d
$TARGET-gcc -c run.c -o run.o -O3 -march=rv64gc -mabi=lp64d -nostdlib -nostartfiles -ffreestanding -I.

# Link all object files into a single ELF file
$TARGET-ld -T linker.ld -o kernel.elf start.o run.o

# Convert the ELF file to a flat binary for QEMU
$TARGET-objcopy kernel.elf -O binary kernel.bin

echo "Build successful! kernel.bin is ready."
