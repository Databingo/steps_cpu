
#!/bin/sh
set -e
XPACK_TOOLCHAIN_BIN="/usr/local/projects/bin/xpack-riscv-none-elf-gcc-14.2.0-3/bin"
TARGET_PREFIX="${XPACK_TOOLCHAIN_BIN}/riscv-none-elf-"
#CFLAGS="-march=rv64gcv -mabi=lp64d -g -O3 -ffreestanding -nostdlib -mcmodel=medany"
CFLAGS="-march=rv64gc -mabi=lp64d -g -O3 -ffreestanding -nostdlib -mcmodel=medany"
LDFLAGS="-T linker.ld -nostdlib -lm"

echo "--- Compiling C and Assembly Code ---"
"${TARGET_PREFIX}gcc" $CFLAGS -c start.S -o start.o
"${TARGET_PREFIX}gcc" $CFLAGS -c run_f.c -o run_f.o

echo "--- Linking Executable ---"
"${TARGET_PREFIX}gcc" $CFLAGS -o kernel_f.elf start.o run_f.o $LDFLAGS

echo "--- Creating Flat Binary ---"
"${TARGET_PREFIX}objcopy" -O binary kernel_f.elf kernel_f.bin

echo "--- Build successful! kernel_q80.bin is ready. ---"
