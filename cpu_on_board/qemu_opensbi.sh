qemu-system-riscv64 -M virt -m 64M -nographic -bios fw_jump.bin -dtb my_board.dtb

# 1. qemu-ima test jump
# 2. test payload
# 3. test qemu linux
# 4. test linux
