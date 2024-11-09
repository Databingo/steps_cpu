#../egos/riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-apple-darwin/bin/riscv64-unknown-elf-objdump -d rvasm64I
# EFI extensible firmware interface
# UEFI unified extensible firmware interface (add security\miniGUI\PS2\USB\keyboard\mouse
# ELF executable and Linking Format for read/run binary files
#../egos/riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-apple-darwin/bin/riscv64-unknown-elf-gcc -nostdlib -o minimal_os.elf minimal_os.c startup.s
#../egos/xpack-qemu-riscv-7.2.5-1/bin/qemu-system-riscv64 -machine virt -m 128 -bios none -nographic -kernel minimal_os.elf
#../egos/riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-apple-darwin/bin/riscv64-unknown-elf-gcc -nostdlib -march=rv64imac -mabi=lp64 -T linker.ld -o minimal_os.elf minimal_os.c 
#../egos/riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-apple-darwin/bin/riscv64-unknown-elf-gcc -T linker.ld -o minimall_os.elf startup.o minimal_os.elf
../egos/riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-apple-darwin/bin/riscv64-unknown-elf-as -march=rv64imac -mabi=lp64 -o startup.o startup.s
../egos/riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-apple-darwin/bin/riscv64-unknown-elf-gcc  -nostdlib -march=rv64imac -mabi=lp64 -T linker.ld -o minimal_os.elf startup.o minimal_os.c 
../egos/riscv64-unknown-elf-gcc-8.3.0-2020.04.1-x86_64-apple-darwin/bin/riscv64-unknown-elf-objcopy -O binary minimal_os.elf minimal_os.bin

../egos/xpack-qemu-riscv-7.2.5-1/bin/qemu-system-riscv64 -machine virt -m 128M -bios none -nographic -kernel minimal_os.elf

