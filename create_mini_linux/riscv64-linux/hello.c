//include <stdio.h>
//include <unistd.h>
//include <fcntl.h>
//include <sys/mount.h>
//
//nt main() {
//   // 1. Mount devtmpfs to get the real hardware nodes
//   mount("devtmpfs", "/dev", "devtmpfs", 0, NULL);
//   
//   // 2. Open the real hardware console
//   int fd = open("/dev/console", O_RDWR);
//   if (fd >= 0) {
//       dup2(fd, 1); // Redirect stdout
//       dup2(fd, 2); // Redirect stderr
//   }
//
//   // 3. DISABLE C-LIBRARY BUFFERING! (Crucial)
//   setvbuf(stdout, NULL, _IONBF, 0);
//
//   int counter = 0;
//   while(1) {
//       printf("Hello from User-Space! MMU is working! [%d]\n", counter++);
//       
//       // 4. Use a busy loop instead of sleep() so it prints instantly
//       for(volatile int i = 0; i < 2000000; i++); 
//   }
//   
//   return 0;
//
#include <unistd.h>

void print(const char *s, int len) {
    // Syscall 64 is 'write' in RISC-V 64-bit
    // fd 1 is stdout
    write(1, s, len);
}

int main() {
    char buf[1];
    print("\r\n*** USER SPACE STARTED SUCCESSFULLY ***\r\n", 42);
    print("Echo Test: Type something and I will repeat it.\r\n", 48);

    while(1) {
        // Syscall 63 is 'read'
        // fd 0 is stdin
        if (read(0, buf, 1) > 0) {
            // Echo back to stdout
            write(1, buf, 1);
        }
    }
    return 0;
}
