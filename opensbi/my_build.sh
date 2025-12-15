#make PLATFORM=generic FW_OPTIONS=0 FW_JUMP=y FW_TEXT_START=0x80000000 FW_ENABLE_SMP=n FW_ENABLE_PMP=n FW_ENABLE_DEBUG=n EXTRA_CFLAGS="-Os" CROSS_COMPILE=riscv64-buildroot-linux-gnu- -j$(nproc)
make PLATFORM=generic menuconfig
