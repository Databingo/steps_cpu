#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/reboot.h>

int main() {
    printf("Minimal initramfs running\n");
    system("/bin/sh");
    reboot(RB_POWER_OFF);
    return 0;
}
