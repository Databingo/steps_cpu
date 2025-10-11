





#debian-live-12.11.0-amd64-lxqt
#
#
#qemu-system-aarch64 \
#  -accel hvf \
#  -machine virt,highmem=off \
#  -cpu cortex-a72 \
#  -m 4096 \
#  -device virtio-gpu-pci \
#  -device usb-mouse -device usb-kbd \
#  -display default,show-cursor=on \
#  -cdrom debian-12.5.0-arm64-netinst.iso \
#  -boot d
#
#
#
#qemu-system-aarch64 \
#  -accel hvf \
#  -machine virt,highmem=off \
#  -cpu cortex-a72 \
#  -m 4096 \
#  -device virtio-gpu-pci \
#  -display default,show-cursor=on \
#  -drive file=debian.qcow2,if=virtio
#
#
#
## for freebsd
#qemu-system-x86_64 -d strace \
#  -monitor stdio \
#  -accel hvf \
#  -M pc \
#  -m 3G \
#  -cpu host \
#  -smp cores=4 \
#  -drive file=FreeBSD-14.1-RELEASE-amd64.qcow2,id=hd0,if=none \
#  -device virtio-blk-pci,drive=hd0 \
#  -netdev user,id=vmnic,hostfwd=tcp::2222-:22,hostfwd=tcp::7777-:7777,hostfwd=tcp::7778-:7778 \
#  -device virtio-net,netdev=vmnic \
#  -drive file=new10G.img,id=new10G,format=qcow2,if=none \
#  -device virtio-blk-pci,drive=new10G \
#  -vga std \
#  -display cocoa \
#  -usbdevice host:05dc:a81d \
# #-nic user,id=nic0,smb=/usr/local/public \
# #-full-screen \
#
#
#
#
#

#qemu-system-x86_64 -d strace \
#  -monitor stdio \
#  -accel hvf \
#  -M pc \
#  -m 3G \
#  -cpu host \
#  -smp cores=4 \
#  -drive file=/Volumes/macos/DebianLXQt.utm/Data/24EA8109-75A9-4A08-8579-EAF7552786D7.qcow2,id=hd0,if=none \
#  -device virtio-blk-pci,drive=hd0 \
#  -netdev user,id=vmnic,hostfwd=tcp::2222-:22,hostfwd=tcp::7777-:7777,hostfwd=tcp::7778-:7778 \
#  -device virtio-net,netdev=vmnic \
#  #-drive file=new10G.img,id=new10G,format=qcow2,if=none \
#  -device virtio-blk-pci,drive=new10G \
#  -vga std \
#  -display cocoa \
#  -usbdevice host:05dc:a81d \
# #-nic user,id=nic0,smb=/usr/local/public \
# #-full-screen \
#
#
#
#qemu-system-x86_64 -hda /Volumes/macos/DebianLXQt.utm/Data/24EA8109-75A9-4A08-8579-EAF7552786D7.qcow2 -m 4G
#




#qemu-system-x86_64 \
#  -accel hvf \
#  -cpu host \
#  -machine q35 \
#  -m 4096 \
#  -smp 4 \
#  -device qemu-xhci,id=xhci \
#  -device usb-tablet,bus=xhci.0 \
#  -device usb-kbd,bus=xhci.0 \
#  -device virtio-gpu-pci \
#  -display cocoa,show-cursor=on \
#  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
#  -device virtio-net-pci,netdev=net0 \
#  -drive file=/Volumes/macos/debian-13-nocloud-amd64.qcow2,if=virtio \
#  -boot c


# install
qemu-system-x86_64 \
  -accel hvf \
  -machine q35 \
  -cpu host \
  -smp 4 \
  -m 4096 \
  -device virtio-gpu-pci \
  -display cocoa \
  -device qemu-xhci,id=xhci \
  -device usb-tablet,bus=xhci.0 \
  -device usb-kbd,bus=xhci.0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -drive file=debian-lxqt.qcow2,if=virtio,format=qcow2 \
  -cdrom ~/Downloads/debian-live-12.11.0-amd64-lxqt.iso \
  -boot d


# run
qemu-system-x86_64 \
  -accel hvf \
  -machine q35 \
  -cpu host \
  -smp 4 \
  -m 4096 \
  -device virtio-gpu-pci \
  -display cocoa \
  -device qemu-xhci,id=xhci \
  -device usb-tablet,bus=xhci.0 \
  -device usb-kbd,bus=xhci.0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -drive file=debian-lxqt.qcow2,if=virtio,format=qcow2 \
  -boot c








 
 
 
 
