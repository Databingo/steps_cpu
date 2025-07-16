##!/bin/bash
#set -e
#
## The prefix for the cross-compiler
#TARGET=riscv64-unknown-elf
#
## Compile all C and Assembly files into object files
#$TARGET-gcc -c start.S -o start.o -march=rv64gc -mabi=lp64d
#$TARGET-gcc -c run.c -o run.o -O3 -march=rv64gc -mabi=lp64d -nostdlib -nostartfiles -ffreestanding -I.
#
## Link all object files into a single ELF file
#$TARGET-ld -T linker.ld -o kernel.elf start.o run.o
#
## Convert the ELF file to a flat binary for QEMU
#$TARGET-objcopy kernel.elf -O binary kernel.bin
#
#echo "Build successful! kernel.bin is ready."
#


#!/bin/sh
#
# build.sh for compiling a bare-metal RISC-V executable
# using the native FreeBSD clang toolchain.
#
set -e

# --- Compiler Flags ---
# These flags are CRUCIAL. They tell clang to forget about FreeBSD
# and build for a generic, bare-metal ELF target.
#
# -target riscv64-unknown-elf: The master switch. Changes the target ABI.
# -march=rv64gc:              Specify the RISC-V architecture with standard extensions.
# -mabi=lp64d:                Specify the 64-bit ABI with double-precision float.
# -g:                         Include debug information.
# -O3:                        Enable optimizations.
# -ffreestanding:             We have no standard library.
# -nostdlib:                  Do not link against ANY standard libraries.
#
CFLAGS="-target riscv64-unknown-elf -march=rv64gc -mabi=lp64d -g -O3 -ffreestanding -nostdlib"

# --- Linker Flags ---
# -T linker.ld:               Use our custom memory map.
# --no-dynamic-linker:        Ensure it doesn't try to link against a system loader.
# -nostdlib:                  Repeated for the linker stage to be certain.
#
LDFLAGS="-T linker.ld --no-dynamic-linker -nostdlib"

echo "--- Compiling C and Assembly Code ---"

# Compile start.S using clang's integrated assembler
clang $CFLAGS -c start.S -o start.o

# Compile our modified run.c
clang $CFLAGS -c run.c -o run.o

echo "--- Linking Executable ---"

# Use clang as the linker driver. It will call `lld` internally.
clang $CFLAGS $LDFLAGS start.o run.o -o kernel.elf

echo "--- Creating Flat Binary ---"

# Use the system's objcopy to convert the ELF to a raw binary.
# This is the file QEMU will run.
objcopy -O binary kernel.elf kernel.bin

echo "--- Build successful! kernel.bin is ready. ---"
