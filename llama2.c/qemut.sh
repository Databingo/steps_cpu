#!/bin/sh
qemu-system-riscv64 \
    -cpu sifive-u54 \
    -machine virt \
    -nographic \
    -m 2G \
    -bios none \
    -icount shift=7,align=off,sleep=off \
    -kernel fpu_test.bin 
