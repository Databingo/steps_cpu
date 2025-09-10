#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/reboot.h>

int main() {
    printf("\n");
    printf("=========================================\n");
    printf("Testing BusyBox functionality...\n");
    printf("=========================================\n");
    printf("\n");
    
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
