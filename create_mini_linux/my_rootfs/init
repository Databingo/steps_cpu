#!/bin/busybox sh

/bin/busybox --install -s /bin

mount -t devtmpfs none /dev
mount -t proc none /proc
mount -t sysfs none /sys
mount -t tmpfs none /tmp

# finx busyboxy tty
setsid cttyhack sh

echo /sbin/mdev > /proc/sys/kernel/hotplug
mdev -s

sh
