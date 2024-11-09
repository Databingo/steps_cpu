

#export ARCH=/usr/local/projects/egos/riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-apple-darwin/bin/riscv64-unknown-elf
#export ARCH=/usr/local/projects/steps_cpu/riscv_gcc_bin/riscv64-unknown-elf
#export ARCH=/usr/local/projects/bin/riscv64-unknown-elf
export ARCH=/usr/local/projects/riscv64-unknown-elf-toolchain-10.2.0-2020.12.8-x86_64-apple-darwin/bin/riscv64-unknown-elf
export CC=$ARCH-gcc
export LD=$ARCH-ld
export OBJCOPY=$ARCH-objcopy
export FLAGS='-nostartfiles -g'
export kernel=hello

echo "cc"
$CC -v $FLAGS -c  $kernel.s -o $kernel.o
echo "ld"
$LD -T link.ld -o $kernel.elf $kernel.o
echo "ob"
$OBJCOPY $kernel.elf -I binary $kernel.img # only machine code without ELF headers/metadata

qemu-system-riscv64 -M virt -bios none -serial stdio -display none -kernel $kernel.img



