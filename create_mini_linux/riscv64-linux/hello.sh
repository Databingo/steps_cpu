#/usr/local/projects/steps_cpu/create_mini_linux/buildroot-2026.02/output/host/bin/riscv64-buildroot-linux-musl-gcc -static hello.c -o hello
/usr/local/projects/steps_cpu/create_mini_linux/buildroot-2026.02/output/host/bin/riscv64-buildroot-linux-musl-gcc -static -nostdlib -Wl,--no-relax hello.s -o hello
chmod 777 hello
cp hello unpacked_rootfs/
