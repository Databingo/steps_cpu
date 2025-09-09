mkdir initramfs
cd initramfs

# 创建 init 脚本
cat > init << 'EOF'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
exec /bin/sh
EOF
chmod +x init

# 打包为 cpio 镜像
find . | cpio -H newc -o > ../initramfs.cpio
cd ..
