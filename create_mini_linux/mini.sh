#Build kernel
#cd riscv64-linux/linux && make clean && cd -
#cd riscv64-linux/linux && make ARCH=riscv CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- tinyconfig && cd -
#cd riscv64-linux/linux && make ARCH=riscv CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- menuconfig && cd -
 
# Stage A
./riscv64-linux/linux/scripts/config --set-val CONFIG_LOG_BUF_SHIFT 15
./riscv64-linux/linux/scripts/config --set-val CONFIG_SERIAL_8250_NR_UARTS 1
./riscv64-linux/linux/scripts/config --set-val CONFIG_SERIAL_8250_RUNTIME_UARTS 1
./riscv64-linux/linux/scripts/config --disable CONFIG_SERIAL_8250_16550A_VARIANTS
./riscv64-linux/linux/scripts/config --disable CONFIG_SERIAL_8250_DW
./riscv64-linux/linux/scripts/config --disable CONFIG_SERIAL_8250_DWLIB
./riscv64-linux/linux/scripts/config --disable CONFIG_VIRTIO_CONSOLE
./riscv64-linux/linux/scripts/config --disable CONFIG_DUMMY_CONSOLE

## Stage B
#./scripts/config --disable CONFIG_XZ_DEC
#./scripts/config --disable CONFIG_XZ_DEC_RISCV
#./scripts/config --disable CONFIG_XZ_DEC_BCJ
#./scripts/config --disable CONFIG_HAVE_KERNEL_LZ4
#./scripts/config --disable CONFIG_HAVE_KERNEL_LZO
#./scripts/config --disable CONFIG_HAVE_KERNEL_ZSTD
#
## Stage C
#./scripts/config --disable CONFIG_VIRTIO_BALLOON
#./scripts/config --disable CONFIG_VIRTIO_INPUT
#./scripts/config --disable CONFIG_VIRTIO_MENU
#./scripts/config --disable CONFIG_VHOST_MENU
#./scripts/config --disable CONFIG_VHOST_ENABLE_FORK_OWNER_CONTROL
#./scripts/config --disable CONFIG_COMMON_CLK
#
## Stage D (optional)
#./scripts/config --disable CONFIG_GOLDFISH
#./scripts/config --disable CONFIG_EEPROM_93CX6
#./scripts/config --disable CONFIG_EDAC_SUPPORT
#./scripts/config --disable CONFIG_PWM
#./scripts/config --disable CONFIG_MAILBOX

 
 
 
cd riscv64-linux/linux && make ARCH=riscv CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- olddefconfig && cd -
cd riscv64-linux/linux && make ARCH=riscv CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- -j $(nproc) && cd -

ls -ahl .
