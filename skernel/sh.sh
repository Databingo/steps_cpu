#EFI for QEMU
#https://releases.linaro.org/components/kernel/uefi-linaro/latest/release/qemu64/QEMU_EFI.fd
#https://wiki.gentoo.org/wiki/QEMU/Linux_guest#Hard_drive

#More space potentail
#qemu-img resize xx.qcow2 +19G

## start system
#qemu-system-x86_64 \
#-bios QEMU_EFI.fd -nographic \
##-bios none \
##-m 3G \
##-cpu cortex-a72 \
##-smp 2 \
#-M virt \
#-drive if=none,file=./Arch-Linux-x86_64-basic.qcow2,id=hd0 \
#-device virtio-blk-device,drive=hd0 \
#-device virtio-scsi-device \
#-net nic -net user,hostfwd=tcp::2222-:22,hostfwd=tcp::7777-:7777,hostfwd=tcp::7778-:7778 \


#qemu-system-x86_64 \
#  -M pc \
#  -m 3G \
#  -smp 2 \
#  -bios QEMU_EFI.fd -nographic \
#  -drive if=virtio,file=./Arch-Linux-x86_64-basic.qcow2,id=hd0 \
#  -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::7777-:7777,hostfwd=tcp::7778-:7778 \
#  -device e1000,netdev=net0         # Network card compatible with x86


qemu-system-x86_64 -d strace \
  -accel hvf \
  -M pc \
  -m 2G \
  -cpu host \
  -smp cores=2 \
  -drive file=./fedora-coreos-41.20241027.3.0-qemu.x86_64.qcow2,format=qcow2
  -device virtio-blk-device,drive=hd0   \
  -device virtio-net-device,netdev=net0 -nographic  -nographic
  -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::7777-:7777,hostfwd=tcp::7778-:7778 \
# -netdev user,id=net0  \
 #-device e1000,netdev=net0         # Network card compatible with x86
# -accel kmv \ for linux
 #-drive file=./Arch-Linux-x86_64-basic.qcow2,format=qcow2
