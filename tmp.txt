#/bin/sh

#mkdir -p /usr/local/etc/pkg/repos &&
#echo 'FressBSD:{url:"https://mirrors.ustc.edu.cn/freebsd-pkg/${ABI}/latest",mirror_type:"NONE"}' > /usr/local/etc/pkg/repos/FreeBSD.conf &&

# sysctl kern.geom.debugflags=16
# gpart resize -i 4 -s 20G -a 4k vtbd0
# gpart recover vtbd0
# growfs /dev/vtbd0p4 # for ufs
# service growfs onestart
# zpool online -e root /dev/vtbd0p4 # for zfs

#pkg install git
#pkg install go

# if system check failed:
# fsck -y
# reboot



