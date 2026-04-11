#qemu-system-riscv64  \
#    -M virt \
#    -m 64M \
#    -cpu rv64,f=off,d=off,c=off,h=off,g=off,zfa=off,zfh=off,zba=off,zbb=off \
#    -nographic \
#    -dtb my_board_qemu.dtb \
#    -bios opensbi/build/platform/generic/firmware/fw_payload.bin \
#   #-bios fw_jump_qemu.bin \
#
#qemu-system-riscv64 -nographic \
#    -machine virt \
#    -bios opensbi/build/platform/generic/firmware/fw_payload.bin \


# 1. qemu-ima test jump
# 2. test payload
# 3. test qemu linux
# 4. test linux
