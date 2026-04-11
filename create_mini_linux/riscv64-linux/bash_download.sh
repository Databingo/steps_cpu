#git clone --depth 1 --branch v6.12 https://github.com/torvalds/linux.git 
# unFPU unCompressedIR PageTablLevel3
#cd linux && make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- menuconfig
#cd linux && make ARCH=riscv HOSTCC=gcc menuconfig
#cd linux && make ARCH=riscv  CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- CC=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu-gcc menuconfig
#cd linux && make ARCH=riscv  CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu-  menuconfig
cp ../config.up5_fix_lp64 linux/.config
cd linux && make ARCH=riscv CROSS_COMPILE=../buildroot-2026.02/output/host/bin/riscv64-buildroot-linux-musl- menuconfig
