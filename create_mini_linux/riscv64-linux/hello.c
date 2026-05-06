//#include <unistd.h>
//#include <fcntl.h>
//#include <sys/mount.h>
//#include <sys/stat.h>
//
//int main() {
//    mkdir("/dev", 0755);
//    mount("devtmpfs", "/dev", "devtmpfs", 0, NULL);
//    int fd=open("/dev/hvc0", O_RDWR);
//    dup2(fd, 0);
//    dup2(fd, 1);
//    dup2(fd, 2);
//
//
//    write(1, "OK\r\n", 4);
//
//    char c;
//    while(1) {
//	if (read(0, &c, 1) > 0) { write(1, "U", 1); }
//	}
//    return 0;
//}
//
//  
//  
#include <unistd.h>
#include <fcntl.h>
#include <sys/mount.h>
#include <sys/stat.h>

int main() {
    // Step 1: Create the folder
    mkdir("/dev", 0755);
    
    // Step 2: Mount the hardware devices
    mount("devtmpfs", "/dev", "devtmpfs", 0, NULL);

    // Step 3: Open the console directly
    int fd = open("/dev/console", O_RDWR);
    if (fd < 0) {
        // Fallback if console isn't named right
        fd = open("/dev/hvc0", O_RDWR); 
    }

    if (fd >= 0) {
        // Step 4: Link the hardware to our program
        dup2(fd, 0); // stdin
        dup2(fd, 1); // stdout
        dup2(fd, 2); // stderr
        
        // Step 5: Print success!
        write(1, "\r\n*** OK ***\r\n", 14);
    }

    char c;
    while(1) {
        // Step 6: Echo loop
        if (read(0, &c, 1) > 0) {
            write(1, "U", 1);
        }
    }
    return 0;
} 
