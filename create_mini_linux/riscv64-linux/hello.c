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


//#include <stdio.h>
//#include <fcntl.h>
//#include <unistd.h>
//#include <sys/stat.h>
//#include <sys/sysmacros.h>
//#include <errno.h>
//
//int main() {
//    // 1. Create the /dev directory
//    mkdir("/dev", 0755);
//    
//    // 2. Create the system console node (Major 5, Minor 1)
//    // Because you boot with console=hvc0, this will automatically link to the working SBI console!
//    mknod("/dev/console", S_IFCHR | 0600, makedev(5, 1));
//
//    // 3. Open the console
//    int fd = open("/dev/console", O_WRONLY);
//    if (fd < 0) {
//        return 2; // Failed to open
//    }
//
//    // 4. Write to the console
//    int ret = write(fd, "\n\n================================\nSUCCESS! HELLO FROM USER SPACE!\n================================\n\n", 99);
//    
//    // 5. If it fails, return the exact Linux error code!
//    if (ret < 0) {
//        return errno; 
//    }
//
//    // Success! Hang forever so it doesn't panic
//    while(1) { sleep(1); }
//    return 0;
//}


//#include <stdio.h>
//#include <fcntl.h>
//#include <unistd.h>
//#include <sys/stat.h>
//#include <sys/sysmacros.h>
//#include <errno.h>
//
//int main() {
//    // 1. Create the dev directory
//    mkdir("/dev", 0755);
//    
//    // 2. Create the console node
//    mknod("/dev/console", S_IFCHR | 0600, makedev(5, 1));
//
//    // 3. MAGIC TRICK: Open with O_NONBLOCK!
//    // This strictly forbids Linux from going to sleep to wait for your broken PLIC!
//    int fd = open("/dev/console", O_WRONLY | O_NONBLOCK);
//    if (fd < 0) {
//        return 2; // Failed to open
//    }
//    
//        // Because of NONBLOCK, this will bypass the PLIC completely and print to your screen!
//    int ret =   write(fd, "\n====================\nSUCCESS: A\n====================\n", 53);
//    if (ret < 0) {
//        return errno;
//    }
//
//    // Hang forever
//    while(1) { sleep(1); }
//    return 0;
//}


//#include <stdio.h>
//#include <fcntl.h>
//#include <sys/mman.h>
//#include <unistd.h>
//#include <stdint.h>
//#include <sys/stat.h>
//#include <sys/sysmacros.h>
//#include <errno.h>
//
//// Based on your header.vh: `define Art_base 64'h0000_2004
//#define UART_PHYS_ADDR 0x2004
//
//int main() {
//    // 1. Create /dev/mem node (Major 1, Minor 1)
//    mkdir("/dev", 0755);
//    mknod("/dev/mem", S_IFCHR | 0600, makedev(1, 1));
//
//    // 2. Open physical memory
//    int fd = open("/dev/mem", O_RDWR | O_SYNC);
//    if (fd < 0) {
//        return 100 + errno; // If exitcode is 0x6500 (101), no permission
//    }
//
//    // 3. Map the page (mmap must be 4096-byte aligned)
//    // We map 8KB starting at 0x0000 to cover the 0x2004 address
//    void *map_ptr = mmap(NULL, 8192, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
//    if (map_ptr == MAP_FAILED) {
//        return 200 + errno; // If exitcode is 0x??00, mmap failed
//    }
//
//    // 4. Calculate exact hardware pointer
//    // map_ptr points to 0x0000. Address is 0x2004.
//    volatile uint32_t *uart_tx = (volatile uint32_t *)((char *)map_ptr + UART_PHYS_ADDR);
//
//    // 5. HARDWARE POKE! 
//    // This writes directly to your FPGA logic, bypassing all drivers.
//    *uart_tx = 'A'; 
//    *uart_tx = '\n';
//    *uart_tx = 'G';
//    *uart_tx = 'O';
//    *uart_tx = 'O';
//    *uart_tx = 'D';
//    *uart_tx = '\n';
//
//    // Success! Hang forever.
//    while(1) {
//        sleep(1);
//    }
//    return 0;
//}
  
  
//#include <unistd.h>
//#include <fcntl.h>
//#include <sys/stat.h>
//#include <sys/sysmacros.h>
//#include <errno.h>
//#include <stdint.h>
//
//// Based on your header.vh: Art_base 64'h2004
//#define UART_TX_ADDR 0x2004
//
//int main() {
//    // 1. Setup /dev/mem
//    mkdir("/dev", 0755);
//    mknod("/dev/mem", S_IFCHR | 0600, makedev(1, 1));
//
//    // 2. Open /dev/mem
//    int fd = open("/dev/mem", O_RDWR);
//    if (fd < 0) return 100 + errno;
//
//    // 3. Move the file pointer directly to the UART TX register
//    if (lseek(fd, UART_TX_ADDR, SEEK_SET) == -1) {
//        return 200 + errno;
//    }
//
//    // 4. THE HARDWARE POKE: Write 4 bytes (32-bit store)
//    // We write 'A' and then a newline.
//    uint32_t val;
//    
//    val = 'A';
//    if (write(fd, &val, 4) < 0) return 300 + errno;
//    
//    val = '\n';
//    write(fd, &val, 4);
//
//    val = 'O';
//    write(fd, &val, 4);
//    val = 'K';
//    write(fd, &val, 4);
//    val = '\n';
//    write(fd, &val, 4);
//
//    // 5. Success! Hang forever.
//    while(1) {
//        sleep(1);
//    }
//    return 0;
//} 
    


//#include <unistd.h>
//#include <fcntl.h>
//#include <stdint.h>
//#include <errno.h>
//#include <sys/stat.h>
//#include <sys/sysmacros.h>
//
//// Based on header.vh: Art_base 64'h2004
//#define UART_PHYS_ADDR 0x2004
//
//int main() {
//    // 1. Ensure the /dev directory exists
//    mkdir("/dev", 0755);
//
//    // 2. Refresh the /dev/mem node
//    unlink("/dev/mem"); 
//    if (mknod("/dev/mem", S_IFCHR | 0600, makedev(1, 1)) < 0) {
//        // If this fails, we want to know why (e.g., EEXIST is fine, others are bad)
//        if (errno != 17) return 50 + errno; 
//    }
//
//    // 3. Open /dev/mem (Use O_RDWR for hardware access)
//    int fd = open("/dev/mem", O_RDWR);
//    if (fd < 0) return 100 + errno;
//
//    // 4. Move the file pointer to 0x2004
//    // We use lseek instead of pwrite for better compatibility
//    if (lseek(fd, UART_PHYS_ADDR, SEEK_SET) == (off_t)-1) {
//        return 200 + errno;
//    }
//
//    // 5. HARDWARE POKE: Write 4 bytes (32-bit Store Word)
//    // Writing 4 bytes ensures the FPGA sees a single 32-bit bus transaction.
//    uint32_t val = 'A';
//    if (write(fd, &val, 4) != 4) {
//        return 300 + errno;
//    }
//
//    // Success! Send a few more to be visible
//    val = '\n'; write(fd, &val, 4);
//    val = 'O';  write(fd, &val, 4);
//    val = 'K';  write(fd, &val, 4);
//    val = '\n'; write(fd, &val, 4);
//
//    // 6. Hang forever so init doesn't exit
//    while(1) {
//        sleep(1);
//    }
//    
//    return 0;
//}
  
  
//#include <stdio.h>
//#include <fcntl.h>
//#include <unistd.h>
//
//int main() {
//    // Write to the standard output
//    // This will get 'stuck' in the kernel buffer because of the PLIC bug.
//    printf("\n\n*** IF YOU SEE THIS, PRESS A KEY TO CONTINUE ***\n\n");
//    fflush(stdout);
//
//    // After you see the kernel 'hang', tap 'Enter' or 'p' on your keyboard.
//    // The keypress will trigger a new interrupt edge, which will 
//    // flush the printf buffer above to your screen.
//    
//    while(1) { sleep(1); }
//    return 0;
//} 
//
  
//#include <fcntl.h>
//#include <unistd.h>
//#include <sys/stat.h>
//#include <sys/sysmacros.h>
//#include <errno.h>
//#include <string.h>
//
//int main() {
//    // 1. Ensure /dev exists and create the kmsg node (Major 1, Minor 11)
//    mkdir("/dev", 0755);
//    // If it already exists, errno 17 (EEXIST) is fine.
//    mknod("/dev/kmsg", S_IFCHR | 0600, makedev(1, 11));
//
//    // 2. Open the kernel log buffer
//    int fd = open("/dev/kmsg", O_WRONLY);
//    if (fd < 0) {
//        // Exit code 0x6500 (101) = Permission/No Node
//        // Exit code 0x6600 (102) = ENOENT
//        return 100 + errno;
//    }
//
//    // 3. Write "A" to the kernel log.
//    // Using "<1>" (KERN_ALERT) ensures it bypasses most loglevel filters.
//    const char *msg = "<1>USERSPACE SUCCESS: A\n";
//    if (write(fd, msg, strlen(msg)) < 0) {
//        return 200 + errno;
//    }
//
//    // 4. Hang forever so the kernel doesn't panic
//    while(1) {
//        sleep(1);
//    }
//
//    return 0;
//} 
//
 

//#include <fcntl.h>
//#include <unistd.h>
//#include <sys/stat.h>
//#include <sys/sysmacros.h>
//#include <errno.h>
//
//int main() {
//    // 1. Ensure /dev exists
//    mkdir("/dev", 0755);
//
//    // 2. Create the ttyprintk node
//    // Major 5, Minor 3 is the standard for ttyprintk
//    mknod("/dev/ttyprintk", S_IFCHR | 0600, makedev(5, 3));
//
//    // 3. Open ttyprintk
//    // We use O_WRONLY because we only want to print
//    int fd = open("/dev/ttyprintk", O_WRONLY);
//    if (fd < 0) {
//        // If exitcode is 0x6500+ (100+), the node creation or open failed
//        return 100 + errno;
//    }
//
//    // 4. WRITE "A"
//    // Since this goes to printk, it bypasses the SiFive UART's TTY "sleep" logic.
//    // It will be printed using the same SBI path as the kernel boot messages.
//    if (write(fd, "USER-SPACE: A\n", 14) < 0) {
//        // If exitcode is 0xC800+ (200+), the write was rejected
//        return 200 + errno;
//    }
//
//    // Hang forever
//    while(1) {
//        sleep(1);
//    }
//    return 0;
//}


#define _GNU_SOURCE
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#include <sys/mount.h>
#include <errno.h>
#include <fcntl.h>

int main() {
    // 1. Create the dev directory
    mkdir("/dev", 0755);
    
    // 2. Create the console node
    //mknod("/dev/console", S_IFCHR | 0600, makedev(5, 1));
      
      
      
    int t = mount("devtmpfs", "/dev", "devtmpfs", 0, NULL);
    if (t < 0) { return 51;} 
    //int r = mknod("/dev/hvc0", S_IFCHR | 0600, makedev(229, 0));
    //if (r < 0) {}

    close(0);
    close(1);
    close(2);



    // 3. MAGIC TRICK: Open with O_NONBLOCK!
    // This strictly forbids Linux from going to sleep to wait for your broken PLIC!
    //int fd = open("/dev/console", O_WRONLY | O_NONBLOCK);
    //int fd = open("/dev/hvc0", O_RDWR | O_NONBLOCK);
    ////return fd;  // 3
    //if (fd < 0) { 
    //    fd = open("/dev/console", O_RDWR | O_NONBLOCK);
    //    if (fd < 0) return 52; // Failed to open
    //}

    int fd0 = open("/dev/hvc0", O_RDWR | O_NONBLOCK);
    int fd1 = open("/dev/hvc0", O_RDWR | O_NONBLOCK);
    int fd2 = open("/dev/hvc0", O_RDWR | O_NONBLOCK);

    if (fd1 != 1) { return 900+fd1; }

    int flags = fcntl(1, F_GETFL);
    if (flags < 0) return 800 + errno;


    char test_char = 'A';
    if (write(1, &test_char, 1) < 0){
	return 700 + errno;
    }

    //if (fd > 2) close(fd);


    int ret =   write(1, "\n====================\nSUCCESS: A\n====================\n", 54);
    if (ret < 0) {
        return 600 + errno;
    }

    printf("OK\n");


    // Hang forever
    while(1) { sleep(1); }
    return 0;
}
