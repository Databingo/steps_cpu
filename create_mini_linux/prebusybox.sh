cd buildroot-2026.02
LD_LIBRARY_PATH= make busybox-menuconfig 
LD_LIBRARY_PATH= FORCE_UNSAFE_CONFIGURE=1 make busybox-rebuild
LD_LIBRARY_PATH= FORCE_UNSAFE_CONFIGURE=1 make 
#LD_LIBRARY_PATH= FORCE_UNSAFE_CONFIGURE=1 make busybox-update-config

