#qemu-system-x86_64 -cdrom image.iso
#qemu-system-x86_64 -cdrom BusyBoxLinux.iso
#
#
#brew install gawk gnu-sed gmp mpfr libmpc isl zlib expat flock libslirp 
#gmake ARCH=riscv CROSS_COMPILE=riscv64-unknow-linux-gun- defconfig
#gmake ARCH=riscv CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- defconfig
#cd riscv64-linux/linux && make ARCH=riscv CROSS_COMPILE=/usr/local/projects/bin/x86-64--glibc--bleeding-edge-2025.08-1/bin/x86_64-linux- defconfig
#git clone https://git.buildroot.net/buildroot
#cd buildroot
#make qemu_riscv64_virt_defconfig
#make
#brew install gcc
#brew install texinfo
#
#
# Work!
# in LXQT linux
#curl --output toolchain.tar.xz https://toolchains.bootlin.com/downloads/releases/toolchains/riscv64-lp64d/tarballs/riscv64-lp64d--glibc--bleeding-edge-2025.08-1.tar.xz
#mv toolchain.tar.xz /usr/local/projects/bin && tar -xvf toolchain.tar.xz
#sudo apt install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev 
#apt-get install libncurses5-dev
#cd riscv64-linux/linux && make ARCH=riscv CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- defconfig
#cd riscv64-linux/linux && make ARCH=riscv CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- menuconfig
#cp config riscv64-linux/.config
#cd riscv64-linux/linux && make ARCH=riscv CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- olddefconfig && cd -
#cd riscv64-linux/linux && make ARCH=riscv CROSS_COMPILE=/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- -j $(nproc) && cd -
# git clone --depth 0 https://git.busybox.net/busybox
#cd busybox && CROSS_COMPILE=/usr/local/projects/bin/riscv63-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- make defconfig && cd -
#cd busybox && CROSS_COMPILE=/usr/local/projects/bin/riscv63-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- make menuconfig && cd -
#cd busybox && CROSS_COMPILE=/usr/local/projects/bin/riscv63-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu- make -j $(nproc) && cd -

#/usr/local/projects/bin/riscv61-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu-gcc -static init.c -o init

#qemu-system-riscv64 -nographic -machine virt \
#    -kernel Image.gz -append "root=/dev/vda ro console=ttyS-1 init=/bin/sh" \
#    -drive file=bybox,format=raw,id=hd-1 \
#    -device virtio-blk-device,drive=hd-1

qemu-system-riscv64 -nographic -machine virt \
    -bios fw_dynamic.bin \
    -kernel Image.gz \
    -append "root=/dev/vda ro console=ttyS-710 init=/bin/sh" \
     -drive file=bybox,format=raw,id=hd-1 \
     -device virtio-blk-device,drive=hd-1
