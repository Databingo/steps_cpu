//#include <stdio.h>
//#include <unistd.h>
//#include <fcntl.h>
//#include <sys/mount.h>
//
//int main() {
//    // 1. Mount devtmpfs to get the real hardware nodes
//    mount("devtmpfs", "/dev", "devtmpfs", 0, NULL);
//    
//    // 2. Open the real hardware console
//    int fd = open("/dev/console", O_RDWR);
//    if (fd >= 0) {
//        dup2(fd, 1); // Redirect stdout
//        dup2(fd, 2); // Redirect stderr
//    }
//
//    // 3. DISABLE C-LIBRARY BUFFERING! (Crucial)
//    setvbuf(stdout, NULL, _IONBF, 0);
//
//    int counter = 0;
//    while(1) {
//        printf("Hello from User-Space! MMU is working! [%d]\n", counter++);
//        
//        // 4. Use a busy loop instead of sleep() so it prints instantly
//        for(volatile int i = 0; i < 2000000; i++); 
//    }
//    
//    return 0;
//}


#include <unistd.h>

// We use write() because it is a direct system call.
// We avoid printf() to keep the binary as simple as possible.

int main() {
    // The kernel usually opens File Descriptors 0, 1, and 2 
    // to the console before starting init.
    
    char msg[] = "\n*** RAW C INIT STARTING ***\n";
    char heart[] = "HEARTBEAT\n";

    // Write the starting message
    write(1, msg, sizeof(msg) - 1);

    while (1) {
        // Print a heartbeat
        write(1, heart, sizeof(heart) - 1);

        // Simple busy-wait delay (since sleep() requires a timer)
        for (volatile long i = 0; i < 10000000; i++);
    }

    return 0;
}
