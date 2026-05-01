sudo sh -c 'cpio -idv < ../rootfs.cpio'
cd dev
sudo mknod -m 600 console c 5 1
sudo mknod -m 666 null c 1 3
