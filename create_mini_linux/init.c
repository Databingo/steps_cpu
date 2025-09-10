//#include <stdlib.h>
//#include <stdio.h>
//#include <unistd.h>
//#include <sys/reboot.h>
//
//int main() {
//    printf("\n");
//    printf("=========================================\n");
//    printf("Testing BusyBox functionality...\n");
//    printf("=========================================\n");
//    printf("\n");
//    
//    // 测试 BusyBox 的 ls 命令
//    printf("Testing 'ls' command:\n");
//    system("/bin/busybox ls /");
//    printf("\n");
//    
//    // 测试 BusyBox 的 echo 命令
//    printf("Testing 'echo' command:\n");
//    system("/bin/busybox echo 'Hello from BusyBox!'");
//    printf("\n");
//    
//    // 挂起系统，保持输出可见
//    printf("BusyBox test completed. System will hang.\n");
//    while(1) {
//        sleep(10);
//    }
//    
//    return 0;
//}


#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/reboot.h>

int main() {
    printf("\n");
    printf("=========================================\n");
    printf("Testing BusyBox functionality...\n");
    printf("=========================================\n");
    printf("\n");

    // 关键修复：在调用任何命令前，重新打开标准流到控制台
    int console_fd = open("/dev/console", O_RDWR);
    if (console_fd >= 0) {
        dup2(console_fd, STDIN_FILENO);   // 标准输入
        dup2(console_fd, STDOUT_FILENO);  // 标准输出
        dup2(console_fd, STDERR_FILENO);  // 标准错误
        close(console_fd);
    }

    // 测试 BusyBox 的 ls 命令
    printf("Testing 'ls' command:\n");
    system("/bin/busybox ls /");
    printf("\n");

    // 测试 BusyBox 的 echo 命令
    printf("Testing 'echo' command:\n");
    system("/bin/busybox echo 'Hello from BusyBox!'");
    printf("\n");

    // 挂起系统，保持输出可见
    printf("BusyBox test completed. System will hang.\n");
    while(1) {
        sleep(10);
    }
    return 0;
}
