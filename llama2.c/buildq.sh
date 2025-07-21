
#!/bin/sh
set -e
XPACK_TOOLCHAIN_BIN="/usr/local/projects/bin/xpack-riscv-none-elf-gcc-14.2.0-3/bin"
TARGET_PREFIX="${XPACK_TOOLCHAIN_BIN}/riscv-none-elf-"
CFLAGS="-march=rv64gcv -mabi=lp64d -g -O3 -ffreestanding -nostdlib -mcmodel=medany"
LDFLAGS="-T linker.ld -nostdlib -lm"

echo "--- Compiling QUANTIZED C and Assembly Code ---"
"${TARGET_PREFIX}gcc" $CFLAGS -c start.S -o start.o
#"${TARGET_PREFIX}gcc" $CFLAGS -c runq_baremetal.c -o runq.o
"${TARGET_PREFIX}gcc" $CFLAGS -c rq.c -o runq.o

echo "--- Linking Executable ---"
"${TARGET_PREFIX}gcc" $CFLAGS -o kernel_q80.elf start.o runq.o $LDFLAGS

echo "--- Creating Flat Binary ---"
"${TARGET_PREFIX}objcopy" -O binary kernel_q80.elf kernel_q80.bin

echo "--- Build successful! kernel_q80.bin is ready. ---"
