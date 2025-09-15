# Compile init.c
#/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu-gcc -static init.c -o init
#
# Now use init bash
#
# Create initramfs 
rm -rf my_rootfs
mkdir -p my_rootfs/{bin,sbin,home,mnt,usr,tmp,etc,proc,sys,dev}
mkdir -p my_rootfs/usr/{bin,sbin}
mkdir -p my_rootfs/proc/sys/kernel

cd my_rootfs
cp ../buzybox  bin/busybox
cp ../init.sh init
chmod +x bin/busybox
chmod +x init

find . | cpio -H newc -o | gzip > ../rootfs.cpio.gz 




