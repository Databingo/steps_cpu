#EFI for QEMU
#https://releases.linaro.org/components/kernel/uefi-linaro/latest/release/qemu64/QEMU_EFI.fd
#https://wiki.gentoo.org/wiki/QEMU/Linux_guest#Hard_drive

#More space potentail
#qemu-img resize xx.qcow2 +19G

#sysctl -a|grep brand
#machdep.cpu.brand: 0
#machdep.cpu.brand_string: Intel(R) Core(TM) i5-4260U CPU @ 1.40GHz
# Haswell x86_64-v3

# FreeBSD
# pkg install port-mgmt/fastest_pkg
# mkdir -p /usr/local/etc/pkg/repos
# echo 'FressBSD:{url:"https://mirrors.ustc.edu.cn/freebsd-pkg/${ABI}/latest",mirror_type:"NONE"}' > /usr/local/etc/pkg/repos/FreeBSD.conf
# vi /boot/default/load.conf
#kern.vty = sc  # color but [[
#kern.vty = vt  # no-color
#hw.vga.textmode = 2
#kern.vt.fb.default_mode="1920x1080"


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


# for arch
#qemu-system-x86_64 \
#  -M pc \
#  -m 3G \
#  -smp 2 \
#  -bios QEMU_EFI.fd -nographic \
#  -drive if=virtio,file=./Arch-Linux-x86_64-basic.qcow2,id=hd0 \
#  -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::7777-:7777,hostfwd=tcp::7778-:7778 \
#  -device e1000,netdev=net0         # Network card compatible with x86


# for fedora
#qemu-system-x86_64 -d strace \
#  -accel hvf \
#  -M pc \
#  -m 2G \
#  -cpu host \
#  -smp cores=2 \
#  -drive file=./fedora-coreos-41.20241027.3.0-qemu.x86_64.qcow2,format=qcow2
#  -device virtio-blk-device,drive=hd0   \
#  -device virtio-net-device,netdev=net0 -nographic  -nographic
#  -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::7777-:7777,hostfwd=tcp::7778-:7778 \


# for Gentoo
#qemu-img create -f qcow2 Gentoo-VM.img 15G 
#qemu-system-x86_64 -d strace \
#  -M pc \
#  -accel hvf \
#  -cpu host \
#  -drive file=Gentoo-VM.img,format=qcow2,if=virtio \
#  -netdev user,id=vmnic,hostname=Gentoo-VM,hostfwd=tcp::2222-:22,hostfwd=tcp::7777-:7777,hostfwd=tcp::7778-:7778 \
#  -device virtio-net,netdev=vmnic \
#  -device virtio-rng-pci \
#  -m 2G \
#  -smp cores=2 \
#  -name "Gentoo VM" \
#  -boot d \
#  -cdrom  ~/Downloads/admincd-amd64-20241110T170333Z.iso
#  #-monitor stdio \


# for alpine
#qemu-img create -f qcow2 Alpine.img 15G 
#qemu-system-x86_64 -d strace \
#  -M pc \
#  -accel hvf \
#  -cpu host \
#  -drive file=Alpine.img,format=qcow2,if=virtio \
#  -netdev user,id=vmnic,hostname=Gentoo-VM,hostfwd=tcp::2222-:22,hostfwd=tcp::7777-:7777,hostfwd=tcp::7778-:7778 \
#  -device virtio-net,netdev=vmnic \
#  -device virtio-rng-pci \
#  -m 2G \
#  -smp cores=2 \
#  -name "Alpine" \
#  -boot d \
#  -cdrom  /Volumes/Ventoy/alpine-extended-3.20.3-x86_64.iso



# for CentOS qcow2
#qemu-system-x86_64 -d strace \
#  -accel hvf \
#  -M pc \
#  -m 2G \
#  -cpu host \
#  -smp cores=2 \
#  -drive file=/Users/chengang/Downloads/CentOS-Stream-GenericCloud-x86_64-9-latest.x86_64.qcow2,id=hd0,if=virtio \
#  -netdev user,id=vmnic,hostfwd=tcp::2222-:22,hostfwd=tcp::7777-:7777,hostfwd=tcp::7778-:7778 \
#  -device virtio-net,netdev=vmnic \


#qemu-img resize FreeBSD-14.1-RELEASE-amd64.qcow2 +19G
#qemu-img create -f qcow2 new10G.img 10G
#sysctl -n hw.logicalcpu
# qemu-img info FreeBSD-14.1-RELEASE-amd64.qcow2
# gpart recover vtbd0
# sysctl kern.geom.debugflags=16
# gpart resize -i 4 -s 20G -a 4k vtbd0
# growfs /dev/vtbd0p4 # for ufs
# service growfs onestart
# zpool online -e root /dev/vtbd0p4 # for zfs

# for freebsd
qemu-system-x86_64 -d strace \
  -monitor stdio \
  -accel hvf \
  -M pc \
  -m 3G \
  -cpu host \
  -smp cores=4 \
  -drive file=FreeBSD-14.1-RELEASE-amd64.qcow2,id=hd0,if=none \
  -device virtio-blk-pci,drive=hd0 \
  -netdev user,id=vmnic,hostfwd=tcp::2222-:22,hostfwd=tcp::7777-:7777,hostfwd=tcp::7778-:7778 \
  -device virtio-net,netdev=vmnic \
  -drive file=new10G.img,id=new10G,format=qcow2,if=none \
  -device virtio-blk-pci,drive=new10G \
  -vga std \
  -display cocoa \
  -usbdevice host:05dc:a81d \
 #-nic user,id=nic0,smb=/usr/local/public \
 #-full-screen \
