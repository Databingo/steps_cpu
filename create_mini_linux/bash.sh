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
#
# in LXQT linux
curl --output toolchain.tar.xz https://toolchains.bootlin.com/downloads/releases/toolchains/riscv64-lp64d/tarballs/riscv64-lp64d--glibc--bleeding-edge-2025.08-1.tar.xz
#sudo apt install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev 
#cd riscv64-linux/linux && make ARCH=riscv CROSS_COMPILE=/usr/local/projects/bin/x86-64--glibc--bleeding-edge-2025.08-1/bin/x86_64-linux- defconfig
#cd riscv64-linux/linux && make ARCH=riscv CROSS_COMPILE=/usr/local/projects/bin/x86-64--glibc--bleeding-edge-2025.08-1/bin/x86_64-linux- -j $(nproc)

