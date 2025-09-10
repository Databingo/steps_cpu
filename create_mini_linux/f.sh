rm -rf my_rootfs
mkdir -p  my_rootfs/{bin,sbin,etc,proc,sys,dev}
cd my_rootfs
cp ../buzybox  bin/busybox
cp ../init init
chmod +x bin/busybox
chmod +x init

find . | cpio -H newc -o | gzip > ../rootfs.cpio.gz 

