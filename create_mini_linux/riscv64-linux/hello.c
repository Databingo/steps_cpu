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
    // Try to create /dev and mount it
    if (mkdir("/dev", 0755) == 0) write(1, "d", 1); // 'd' means directory created
    if (mount("devtmpfs", "/dev", "devtmpfs", 0, NULL) == 0) write(1, "m", 1); // 'm' means mount success

    int fd = open("/dev/hvc0", O_RDWR);
    if (fd < 0) {
        write(1, "E", 1); // 'E' means Error: Could not open /dev/hvc0
        while(1); // Stop here so we don't spam
    }

    dup2(fd, 0);
    dup2(fd, 1);
    
    write(1, "OK\r\n", 4);

    char c;
    while(1) {
        if (read(0, &c, 1) > 0) {
            write(1, "U", 1);
        }
    }
    return 0;
}
