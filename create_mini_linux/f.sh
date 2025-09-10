rm -rf my_rootfs
mkdir -p  my_rootfs/{bin,sbin,etc,proc,sys,dev}
cd my_rootfs
#cp ../bx  bin/busybox
cp ../buzybox  bin/busybox
chmod +x bin/busybox
ln -s bin/busybox init
chmod +x init

#sudo mknod -m 622 dev/console c 5 1
#sudo mknod -m 666 dev/null c 1 3
#sudo mknod -m 666 dev/tty c 5 0


find . | cpio -H newc -o | gzip > ../rootfs.cpio.gz 

