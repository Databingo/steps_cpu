#export EGOS=$PWD
export EGOS=/usr/local/projects/egos
echo $EGOS
export PATH=$PATH:$EGOS/riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-apple-darwin/bin
export PATH=$PATH:$EGOS/riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-apple-darwin/lib/gcc
export PATH=$PATH:$EGOS/xpack-qemu-riscv-7.2.5-1/bin
../egos/riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-apple-darwin/bin/riscv64-unknown-elf-gcc -Wall -Wextra -c -mcmodel=medany kernel.c -o kernel.o -ffreestanding
../egos/riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-apple-darwin/bin/riscv64-unknown-elf-as -c entry.S -o entry.o
../egos/riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-apple-darwin/bin/riscv64-unknown-elf-ld -T linker.ld -nostdlib kernel.o entry.o -o kernel.elf

../egos/xpack-qemu-riscv-7.2.5-1/bin/qemu-system-riscv64 -machine virt -bios none -kernel kernel.elf -serial mon:stdio

