#!/bin/sh
qemu-system-riscv64 \
    -machine virt \
    -nographic \
    -m 128M \
    -bios none \
    -kernel kernel_q80.bin
