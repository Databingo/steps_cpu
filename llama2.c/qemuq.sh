#!/bin/sh
qemu-system-riscv64 \
    -machine virt \
    -nographic \
    -m 1024M \
    -bios none \
    -icount shift=7,align=off,sleep=off \
    -kernel kernel_q80.bin

  

