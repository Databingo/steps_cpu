#include <unistd.h>
#include <fcntl.h>
#include <sys/mount.h>
#include <sys/stat.h>

int main() {
    mkdir("/dev", 0755);
    mount("devtmpfs", "/dev", "devtmpfs", 0, NULL);
    int fd=open("/dev/hvc0", O_RDWR);
    dup2(fd, 0);
    dup2(fd, 1);
    dup2(fd, 2);


    write(1, "OK\r\n", 4);

    char c;
    while(1) {
	if (read(0, &c, 1) > 0) { write(1, "U", 1); }
	}
    return 0;
}

  
  
