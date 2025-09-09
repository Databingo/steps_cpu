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
    
    printf("Welcome to STEPS_CPU!\n");
    // 设置控制台
    //int console = open("/dev/console", O_RDWR);
    //if (console >= 0) {
    //    dup2(console, 0); // 标准输入
    //    dup2(console, 1); // 标准输出
    //    dup2(console, 2); // 标准错误
    //    close(console);
    //}
    
    // 设置环境变量
    //setenv("PATH", "/bin:/sbin:/usr/bin:/usr/sbin", 1);
   // 
   // printf("Simple init program started successfully!\n");
   // printf("Mounting completed. Starting shell...\n");
   // 
   // system("/bin/busybox --install -s");

   // // 启动 shell
    execl("/bin/busybox", "busybox", "sh", NULL);


   // // 如果 execl 失败，执行备用方案
   // perror("Failed to start shell");
   // printf("Trying alternative approach...\n");
   // 
   // // 尝试直接执行 busybox sh
   // system("/bin/busybox sh");
   // 
   // // 如果所有方法都失败，挂起系统
   // printf("All startup methods failed. System will hang.\n");
   // while(1) {
   //     sleep(10);
   // }
    
    return 0;
}
