#git clone --depth 1 --branch v6.12 https://github.com/torvalds/linux.git 
# unFPU unCompressedIR PageTablLevel3 bootcommand
#cd linux && make clean && cd -
 
#cp config linux/.config
#cd linux && make ARCH=riscv CROSS_COMPILE=/usr/local/projects/steps_cpu/create_mini_linux/buildroot-2026.02/output/host/bin/riscv64-buildroot-linux-musl- menuconfig && cd -
#cp linux/.config config 

cd linux && make ARCH=riscv CROSS_COMPILE=/usr/local/projects/steps_cpu/create_mini_linux/buildroot-2026.02/output/host/bin/riscv64-buildroot-linux-musl- -j$(nproc)
