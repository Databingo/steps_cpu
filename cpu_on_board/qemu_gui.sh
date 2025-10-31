#qemu-system-x86_64 \
#  -accel hvf \
#  -m 4096 \
#  -cdrom lubuntu-24.04-desktop-amd64.iso \
#  -boot d \
#  -vga virtio \
#  -display default,show-cursor=on \
#  -usb -device usb-tablet



#qemu-system-x86_64 \
#  -accel hvf \
#  -m 4096 -smp 4 \
#  -drive file=~/Download/debian-13-nocloud-amd64.qcow2,format=qcow2 \
#  -boot c \
#  -vga virtio \
#  -display cocoa,gl=on,show-cursor=on \
#  -usb -device usb-tablet \
#  -nic user,model=virtio-net-pci

qemu-system-x86_64 \
  -accel hvf \
  -m 4096 -smp 4 \
  -drive file=~/Downloads/debian-13-nocloud-amd64.qcow2,format=qcow2 \
  -vga virtio \
  -display cocoa,show-cursor=on \
  -usb -device usb-tablet \
  -nic user,model=virtio-net-pci


