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
//#include <unistd.h>
//#include <fcntl.h>
//#include <sys/mount.h>
//#include <sys/stat.h>
//
//int main() {
//    // Step 1: Create the folder
//    mkdir("/dev", 0755);
//    
//    // Step 2: Mount the hardware devices
//    mount("devtmpfs", "/dev", "devtmpfs", 0, NULL);
//
//    // Step 3: Open the console directly
//    int fd = open("/dev/console", O_RDWR);
//    if (fd < 0) {
//        // Fallback if console isn't named right
//        fd = open("/dev/hvc0", O_RDWR); 
//    }
//
//    if (fd >= 0) {
//        // Step 4: Link the hardware to our program
//        dup2(fd, 0); // stdin
//        dup2(fd, 1); // stdout
//        dup2(fd, 2); // stderr
//        
//        // Step 5: Print success!
//        write(1, "\r\n*** OK ***\r\n", 14);
//    }
//
//    char c;
//    while(1) {
//        // Step 6: Echo loop
//        if (read(0, &c, 1) > 0) {
//            write(1, "U", 1);
//        }
//    }
//    return 0;
//} 


//#include <stdio.h>
//#include <fcntl.h>
//#include <unistd.h>
//#include <sys/stat.h>
//#include <sys/sysmacros.h>
//
//int main() {
//    // 1. Create the /dev directory (if it doesn't exist)
//    mkdir("/dev", 0755);
//    
//    // 2. Create the kmsg node (Major 1, Minor 11)
//    // Even if devtmpfs is mounted, creating it again won't hurt
//    mknod("/dev/kmsg", S_IFCHR | 0600, makedev(1, 11));
//
//    // 3. Open the kernel log for writing
//    int fd = open("/dev/kmsg", O_WRONLY);
//    if (fd < 0) {
//        return 2; // If panic exitcode is 0x0200, it failed to open /dev/kmsg
//    }
//
//    // 4. Write to kernel log! 
//    // <1> is the KERN_ALERT prefix to ensure it ignores loglevel filters
//    // earlycon=sbi will automatically flush this to the screen
//    int ret = write(fd, "<1>HELLO FROM USERSPACE!\n", 25);
//    if (ret < 0) {
//        return 3; // If panic exitcode is 0x0300, it failed to write
//    }
//
//    // Hang forever so it doesn't panic
//    while(1) { sleep(1); }
//    return 0;
//}


#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#include <errno.h>

int main() {
    // 1. Create the /dev directory
    mkdir("/dev", 0755);
    
    // 2. Create the system console node (Major 5, Minor 1)
    // Because you boot with console=hvc0, this will automatically link to the working SBI console!
    mknod("/dev/console", S_IFCHR | 0600, makedev(5, 1));

    // 3. Open the console
    int fd = open("/dev/console", O_WRONLY);
    if (fd < 0) {
        return 2; // Failed to open
    }

    // 4. Write to the console
    int ret = write(fd, "\n\n================================\nSUCCESS! HELLO FROM USER SPACE!\n================================\n\n", 99);
    
    // 5. If it fails, return the exact Linux error code!
    if (ret < 0) {
        return errno; 
    }

    // Success! Hang forever so it doesn't panic
    while(1) { sleep(1); }
    return 0;
}
