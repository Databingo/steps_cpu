#!/bin/busybox sh
#
/bin/busybox mount -t devtmpfs dev /dev

/bin/busybox echo ">ksmg" > /dev/kmsg
/bin/busybox echo ">ttyprintk" > /dev/ttyprintk
/bin/busybox echo ">console"
/bin/busybox sleep 10

