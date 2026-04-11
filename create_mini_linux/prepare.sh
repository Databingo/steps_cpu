# On linux to compile busybox with lp64
# Need gcc .etc:
#
# apt install gcc-riscv64-linux-gnu build-essential libncurses-dev bison flex libssl-dev libelf-dev
# cd busybox
# make distclean
# make defconfig
# make menuconfig
# Settings Build static binary (no shared libs)
# Settings Additional CFLAGS: -march=rv64ima_zicsr_zifencei -mabi=lp64
# make CROSS_COMPILE=riscv64-linux-gnu- -j $(nproc)
# make CROSS_COMPILE=riscv64-linux-gnu- install
#
#
#
#wget https://buildroot.org/downloads/buildroot-2026.02.tar.gz
#tar -zxvf buildroot-2026.02.tar.gz
cd buildroot-2026.02

cat <<EOF > ima_defconfig
BR2_riscv=y
BR2_RISCV_64=y
BR2_riscv_custom=y
BR2_RISCV_ISA_CUSTOM_RVM=y
BR2_RISCV_ISA_CUSTOM_RVA=y
BR2_RISCV_ISA_CUSTOM_EXTENSIONS="-march=rv64ima_zicsr_zifencei_zalrsc_zaamo"
BR2_RISCV_ABI_LP64=y
BR2_TOOLCHAIN_BUILDROOT_MUSL=y
BR2_TARGET_ROOTFS_CPIO=y
EOF



LD_LIBRARY_PATH= make clean
LD_LIBRARY_PATH= make defconfig BR2_DEFCONFIG=ima_defconfig
LD_LIBRARY_PATH= FORCE_UNSAFE_CONFIGURE=1 make -j$(nproc)

# build process
# binutils (rv assembler/linker)
# gcc pass1 (no libc yet)
# musl headers
# libgcc (rv64ima/lp640
# musl libc fully
# gcc pass2(linked musl)
