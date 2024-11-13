# toolchains.bootlin.com/downloads


#qemu-system-riscv64 -M virt -bios /builds/bootlin/toolchains-builder/test/output/images/fw_jump.elf -kernel /builds/bootlin/toolchains-builder/test/output -append "rootwait root=/dev/vda ro " -drive file=/ootlin/toolchains-builder/test/output/images/rootfs.ext2,format=raw,id=hd0 -device virtio-blk-device,drive=hd0 -netdev user,id=net0 -device virtio-net-device,netdev=net0 -nographic  -nographic

#/usr/local/projects/xpack-qemu-riscv-7.2.5-1/bin/qemu-system-riscv64 -M virt -bios fw_jump.elf -kernel riscv64-lp64d--glibc--bleeding-edge-2021.11-1-Image -append "rootwait root=/dev/vda ro " -drive file=riscv64-lp64d--glibc--bleeding-edge-2021.11-1-rootfs.ext2,format=raw,id=hd0 -device virtio-blk-device,drive=hd0 -netdev user,id=net0 -device virtio-net-device,netdev=net0 -nographic  -nographic

#/usr/local/projects/xpack-qemu-riscv-7.2.5-1/bin/qemu-system-riscv64 -M virt -bios  riscv64-lp64d--glibc--bleeding-edge-2021.11-1-fw_jump.elf -kernel riscv64-lp64d--glibc--bleeding-edge-2021.11-1-Image -append "rootwait root=/dev/vda ro " -drive file=riscv64-lp64d--glibc--bleeding-edge-2021.11-1-rootfs.ext2,format=raw,id=hd0 -device virtio-blk-device,drive=hd0  -nographic  -nographic

#/usr/local/projects/xpack-qemu-riscv-7.2.5-1/bin/qemu-system-riscv64 -M virt -bios  riscv64-lp64d--glibc--bleeding-edge-2021.11-1-fw_jump.elf -kernel riscv64-lp64d--glibc--bleeding-edge-2021.11-1-Image -append "console=ttyS0" -initrd initramfs/initramfs.cpio.gz  -nographic

#/usr/local/projects/xpack-qemu-riscv-7.2.5-1/bin/qemu-system-riscv64 -M virt -bios  riscv64-lp64d--glibc--bleeding-edge-2024.05-1-fw_jump.elf -kernel riscv64-lp64d--glibc--bleeding-edge-2024.05-1-Image -append "rootwait root=/dev/vda ro " -drive file=riscv64-lp64d--glibc--bleeding-edge-2024.05-1-rootfs.ext2,format=raw,id=hd0 -device virtio-blk-device,drive=hd0  -nographic  -nographic

../qemu-system-riscv64 -M virt -bios  riscv64-lp64d--glibc--bleeding-edge-2024.05-1-fw_jump.elf -kernel riscv64-lp64d--glibc--bleeding-edge-2024.05-1-Image -append "rootwait root=/dev/vda ro " -drive file=riscv64-lp64d--glibc--bleeding-edge-2024.05-1-rootfs.ext2,format=raw,if=none,id=hd0 -device virtio-blk-device,drive=hd0  -netdev user,id=net0 -device virtio-net-device,netdev=net0 -nographic  -nographic

# git clone qemu
# mkdir build
# python3 -m pip install sphinx==5.3.0    
# python3 -m pip install sphinx_rtd_theme>=0.5
# cd build
# ../cofigure
# make
