mkdir -p  my_rootfs/{bin,sbin,etc,proc,sys,dev}
cd my_rootfs
cp ../bybox  bin/
ln -s bin/bybox  init
find . | cpio -H newc -o | gzip > ../rootfs.cpio.gz 

