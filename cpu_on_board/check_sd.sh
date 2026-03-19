diskutil list
umount /dev/disk2
sudo dd if=/dev/disk2 count=1 | hexdump -C
