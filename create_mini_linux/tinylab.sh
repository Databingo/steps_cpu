set -e

export ARCH="riscv"
export CROSS_COMPILE="/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu-"
export CFLAGS="-march=rv64imafd -mabi=lp64d"

mkdir initrd

$CROSS_COMPILE"gcc" -static init.c -o initrd/init
chmod +x initrd/init

mkdir initrd/dev
sudo mknod initrd/dev/console c 5 1



#Build kernel
#cd riscv64-linux/linux && make clean && cd -
#cd riscv64-linux/linux && make defconfig && cd -
cd riscv64-linux/linux && make tinyconfig && cd -
cd riscv64-linux/linux && make menuconfig && cd -
#cd riscv64-linux/linux && make olddefconfig && cd -
cd riscv64-linux/linux && make -j $(nproc) && cd -
