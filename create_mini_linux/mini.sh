#Build kernel
#cd riscv64-linux/linux && make clean && cd -
#cd riscv64-linux/linux && make ARCH=riscv CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- tinyconfig && cd -
#cd riscv64-linux/linux && make ARCH=riscv CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- menuconfig && cd -
cd riscv64-linux/linux && make ARCH=riscv CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- olddefconfig && cd -
 
cd riscv64-linux/linux && make ARCH=riscv CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- -j $(nproc) && cd -
