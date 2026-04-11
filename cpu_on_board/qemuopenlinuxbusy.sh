#qemu-system-riscv64  \
#    -M virt \
#    -m 64M \
#    -cpu rv64,f=off,d=off,c=off,h=off,g=off,zfa=off,zfh=off,zba=off,zbb=off \
#    -nographic \
#    -dtb my_board_qemu.dtb \
#    -bios opensbi/build/platform/generic/firmware/fw_jump.bin \
#   #-bios opensbi/build/platform/generic/firmware/fw_payload.bin \
#   #-bios fw_jump_qemu.bin \
#
#qemu-system-riscv64 -nographic \
#    -machine virt \
#    -cpu rv64,f=off,d=off,c=off,h=off,g=off,zfa=off,zfh=off,zba=off,zbb=off \
#    -bios opensbi/build/platform/generic/firmware/fw_payload.bin \
##   -append "console=hvc0 earlycon=sbi"

# Work
#qemu-system-riscv64 -nographic \
#    -machine virt \
#    -bios default \
#    -kernel /usr/local/projects/steps_cpu/create_mini_linux/riscv64-linux/Image \
#    -initrd /usr/local/projects/steps_cpu/create_mini_linux/riscv64-linux/rootfs.cpio \
#    -append "console=ttyS0"
#

qemu-system-riscv64 -nographic \
    -machine virt \
    -cpu rv64,f=off,d=off,c=off,h=off,g=off,zfa=off,zfh=off,zba=off,zbb=off \
    -bios fw_jump_ima.bin \
    -kernel /usr/local/projects/steps_cpu/create_mini_linux/riscv64-linux/Image \
    -initrd /usr/local/projects/steps_cpu/create_mini_linux/riscv64-linux/rootfs.cpio \
    -append "console=ttyS0"



# 1. qemu-ima test jump
# 2. test payload
# 3. test qemu linux
# 4. test linux
