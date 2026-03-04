#!/bin/sh
qemu-system-riscv64 \
    -cpu sifive-u54 \
    -machine virt \
    -nographic \
    -m 1G \
    -bios none \
    -icount shift=7,align=off,sleep=off \
    -kernel kernel_f.bin \
    -serial mon:stdio \
#   -d in_asm,cpu

