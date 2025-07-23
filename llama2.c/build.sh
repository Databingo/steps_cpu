
#!/bin/sh
set -e
XPACK_TOOLCHAIN_BIN="/usr/local/projects/bin/xpack-riscv-none-elf-gcc-14.2.0-3/bin"
TARGET_PREFIX="${XPACK_TOOLCHAIN_BIN}/riscv-none-elf-"
#CFLAGS="-march=rv64gcv -mabi=lp64d -g -O3 -ffreestanding -nostdlib -mcmodel=medany"
CFLAGS="-march=rv64gc -mabi=lp64d -g -O3 -ffreestanding -nostdlib -mcmodel=medany"
LDFLAGS="-T linker.ld -nostdlib -lm"

echo "--- Compiling QUANTIZED C and Assembly Code run ---"
"${TARGET_PREFIX}gcc" $CFLAGS -c start.S -o start.o
"${TARGET_PREFIX}gcc" $CFLAGS -c run_baremetal.c -o run.o
#"${TARGET_PREFIX}gcc" $CFLAGS -c rq.c -o runq.o

echo "--- Linking Executable ---"
"${TARGET_PREFIX}gcc" $CFLAGS -o kernel.elf start.o run.o $LDFLAGS

echo "--- Creating Flat Binary ---"
"${TARGET_PREFIX}objcopy" -O binary kernel.elf kernel.bin

echo "--- Build successful! kernel.bin is ready. ---"
