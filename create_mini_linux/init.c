#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/reboot.h>

int main() {
    // 挂载必要的文件系统
    system("/bin/busybox mount -t proc none /proc");
    system("/bin/busybox mount -t sysfs none /sys");
    system("/bin/busybox mount -t devtmpfs none /dev");
    system("/bin/busybox --install -s");
    
    printf("Welcome to STEPS_CPU!\n");

    // 启动 shell
    execl("/bin/busybox", "busybox", "sh", NULL);

    return 0;
}
