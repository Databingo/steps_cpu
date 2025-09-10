mkdir -p  my_rootfs/{bin,sbin,etc,proc,sys,dev}
cd my_rootfs
cp ../buzybox  bin/
cp ../init  init
chmod +x init
chmod +x bin/buzybox
find . | cpio -H newc -o | gzip > ../rootfs.cpio.gz 

