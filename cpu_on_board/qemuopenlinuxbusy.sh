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

## Work ima_liunx_busybox_default_uart_page5
#qemu-system-riscv64 -nographic \
#    -machine virt \
#    -cpu rv64,f=off,d=off,c=off,h=off,g=off,zfa=off,zfh=off,zba=off,zbb=off \
#    -bios fw_jump_ima.bin \
#    -kernel /usr/local/projects/steps_cpu/create_mini_linux/riscv64-linux/Image_default_uart_page5 \
#    -initrd /usr/local/projects/steps_cpu/create_mini_linux/riscv64-linux/rootfs.cpio \
#    -append "console=ttyS0"
#

## Work turn to page 3 with same Image of linux (ctrl-a c infor registers satp 8...)
#qemu-system-riscv64 -nographic \
#    -machine virt \
#    -cpu rv64,f=off,d=off,c=off,h=off,g=off,zfa=off,zfh=off,zba=off,zbb=off \
#    -bios fw_jump_ima.bin \
#    -kernel /usr/local/projects/steps_cpu/create_mini_linux/riscv64-linux/Image_default_uart_page5 \
#    -initrd /usr/local/projects/steps_cpu/create_mini_linux/riscv64-linux/rootfs.cpio \
#    -append "console=ttyS0"

# Work
#qemu-system-riscv64 -nographic \
#    -machine virt \
#    -cpu rv64,f=off,d=off,c=off,h=off,g=off,zfa=off,zfh=off,zba=off,zbb=off \
#    -bios fw_jump_ima.bin \
#    -kernel /usr/local/projects/steps_cpu/create_mini_linux/riscv64-linux/Image_addsbi01uart_bootcmd_no4lvl
#    -initrd /usr/local/projects/steps_cpu/create_mini_linux/riscv64-linux/rootfs.cpio \
#    -append "earlycon=sbi console=hvc0"
#   #-append "console=ttyS0"
 
## Work with 1fs-bootcmd-sbi01uart
#qemu-system-riscv64 -nographic \
#    -machine virt \
#    -cpu rv64,f=off,d=off,c=off,h=off,g=off,zfa=off,zfh=off,zba=off,zbb=off \
#    -bios fw_jump_ima.bin \
#    -kernel /usr/local/projects/steps_cpu/create_mini_linux/riscv64-linux/Image_fs_nou8250_only_hvc0

## Work with no-defaultuart-noblock
#qemu-system-riscv64 -nographic \
#    -machine virt \
#    -cpu rv64,f=off,d=off,c=off,h=off,g=off,zfa=off,zfh=off,zba=off,zbb=off \
#    -bios fw_jump_ima.bin \
#    -kernel /usr/local/projects/steps_cpu/create_mini_linux/riscv64-linux/Image_noblock

## Work with no-defaultuart-noblock-novirdriver-xzramfs
#qemu-system-riscv64 -nographic \
#    -machine virt \
#    -cpu rv64,f=off,d=off,c=off,h=off,g=off,zfa=off,zfh=off,zba=off,zbb=off \
#    -bios fw_jump_ima.bin \
#    -kernel /usr/local/projects/steps_cpu/create_mini_linux/riscv64-linux/Image_novir

# Test smaller image
qemu-system-riscv64 -nographic \
    -machine virt \
    -m 35M \
    -cpu rv64,f=off,d=off,c=off,h=off,g=off,zfa=off,zfh=off,zba=off,zbb=off \
    -bios fw_jump_ima.bin \
    -append "mem=8M"  \
    -kernel /usr/local/projects/steps_cpu/create_mini_linux/riscv64-linux/Image

## In one bin
#qemu-system-riscv64 -nographic \
#    -machine virt \
#     -m 8M \
#    -cpu rv64,f=off,d=off,c=off,h=off,g=off,zfa=off,zfh=off,zba=off,zbb=off \
#    -bios fw_jump_pad.bin \
#   #-bios opensbi/build/platform/generic/firmware/fw_jump.bin \
#   #-bios opensbi/build/platform/generic/firmware/fw_payload.bin \
#   #-bios fw_jump.bin \


# 1. qemu-ima test jump
# 2. test payload
# 3. test qemu linux
# 4. test linux
