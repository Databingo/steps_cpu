go run assembler.go kernel.s
#/usr/local/projects/xpack-qemu-riscv-7.2.5-1/bin/qemu-system-riscv64 -M virt -bios none -serial stdio -display none -kernel add.o
#./qemu-system-riscv64 -M virt -bios none -serial stdio -display none -kernel add.o
./xpack-qemu-riscv-7.2.5-1/bin/qemu-system-riscv64 -M virt -bios none -serial stdio -display none -kernel add.o

