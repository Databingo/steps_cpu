#!/bin/bash
set -e
 
mkdir -p initramfs
cd initramfs

mkdir -p dev bin sbin etc proc sys usr/bin usr/sbin
#mknod dev/console c 5 1
#mknod dev/null c 1 3
cp ../bybox bin/
cp ../init  . 
ln -s bin/bybox ls
find . | cpio --quiet --reproducible -o -H newc > ../initramfs.cpio
cd ..
