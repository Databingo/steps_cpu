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




#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>

// --- UPDATE THIS TO YOUR EXACT `Art_base` ADDRESS ---
#define UART_PHYS_BASE 0x20000000 

int main() {
    // 1. Create /dev/mem node (Major 1, Minor 1)
    mkdir("/dev", 0755);
    mknod("/dev/mem", S_IFCHR | 0600, makedev(1, 1));

    // 2. Open physical memory
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        return 1; // Failed to open memory
    }

    // 3. Map the 4KB page containing your UART into User-Space
    void *map_base = mmap(0, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, fd, UART_PHYS_BASE & ~0xFFF);
    if (map_base == (void *) -1) {
        return 1; // Failed to map
    }

    // 4. Calculate the exact pointer to the SiFive txdata register (offset 0x00)
    volatile uint32_t *uart_tx = (volatile uint32_t *)((uint8_t *)map_base + (UART_PHYS_BASE & 0xFFF));

    // 5. WRITE DIRECTLY TO FPGA HARDWARE FROM U-MODE!
    *uart_tx = 'A';
    *uart_tx = '\n';

    // Hang forever
    while(1) { sleep(1); }
    return 0;
}
