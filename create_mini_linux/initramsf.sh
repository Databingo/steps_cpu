## Create initramfs 
#rm -rf my_rootfs
#mkdir -p my_rootfs/{bin,sbin,home,mnt,usr,tmp,etc,proc,sys,dev}
#mkdir -p my_rootfs/usr/{bin,sbin}
#mkdir -p my_rootfs/proc/sys/kernel
#
#cd my_rootfs
#cp ../buzybox2  bin/busybox
#cp ../init init
#chmod +x bin/busybox
#chmod +x init
#
#find . | cpio -H newc -o | gzip > ../rootfs.cpio.gz 
#
#
#
mkdir initrd

