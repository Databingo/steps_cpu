# Build Busybox
#git clone --depth 1 https://git.busybox.net/busybox
#cd busybox && CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- make clean  && cd -
#cd busybox && CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- make defconfig && cd -
#cd busybox && CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- make menuconfig && cd -
#cd busybox && CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- make -j $(nproc) && cd -



set -e

export ARCH="riscv"
export CROSS_COMPILE="/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu-"
export CFLAGS="-march=rv64imafd -mabi=lp64d"

#Build kernel
#cd riscv64-linux/linux && make clean && cd -
#cd riscv64-linux/linux && make defconfig && cd -
#cd riscv64-linux/linux && make menuconfig && cd -
cd busybox && make -j $(nproc) && cd -
