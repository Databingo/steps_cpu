rm -rf my_rootfs
mkdir -p  my_rootfs/{bin,sbin,etc,proc,sys,dev}
cd my_rootfs
cp ../buzybox  bin/busybox
cp ../init init
chmod +x bin/busybox
chmod +x init
ln -s /bin/busybox  bin/ls
ln -s /bin/busybox  bin/sh
ln -s /bin/busybox  bin/cat

find . | cpio -H newc -o | gzip > ../rootfs.cpio.gz 

