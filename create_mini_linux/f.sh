#mkdir my_rootfs
#cd my_rootfs
#mkdir -p bin sbin etc proc sys dev
#cd ../busybox && make CONFIG_PREFIX=../my_rootfs install && cd -
#cd my_rootfs
#ln -s bin/sh init
#sudo mknod -m 660 dev/console c 5 1
cd my_rootfs && find . | cpio -H newc -o | gzip > ../rootfs.cpio.gz 

