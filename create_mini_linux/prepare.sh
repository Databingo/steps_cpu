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
