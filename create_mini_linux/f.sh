mkdir -p  my_rootfs/{bin,sbin,etc,proc,sys,dev}
cd my_rootfs
cp ../bybox  bin/
cp ../init  init
chmod +x init
chmod +x bin/bybox
find . | cpio -H newc -o | gzip > ../rootfs.cpio.gz 

