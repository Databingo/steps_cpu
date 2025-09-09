# Build init
/usr/local/projects/bin/riscv64-lp64d--glibc--bleeding-edge-2025.08-1/bin/riscv64-buildroot-linux-gnu-gcc -static init.c -o init

# Create initramfs 
rm -rf my_rootfs
mkdir -p  my_rootfs/{bin,sbin,etc,proc,sys,dev}
cd my_rootfs
cp ../buzybox  bin/busybox
#cp ../init init
chmod +x bin/busybox
#chmod +x init

ln -s /bin/busybox  bin/ls
ln -s /bin/busybox  bin/mv
ln -s /bin/busybox  bin/cp
ln -s /bin/busybox  bin/rm
ln -s /bin/busybox  bin/cat

ln -s /bin/busybox init

find . | cpio -H newc -o | gzip > ../rootfs.cpio.gz 
