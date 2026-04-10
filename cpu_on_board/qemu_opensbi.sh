#qemu-system-riscv64 -M virt -m 64M -nographic -bios fw_jump_soc.bin -dtb my_board_soc.dtb
qemu-system-riscv64  \
    -M virt \
    -m 64M \
    -cpu rv64,f=off,d=off,c=off,h=off,g=off,zfa=off,zfh=off,zba=off,zbb=off \
    -nographic \
    -bios fw_jump_qemu.bin \
    -dtb my_board_qemu.dtb \



# 1. qemu-ima test jump
# 2. test payload
# 3. test qemu linux
# 4. test linux
