#include <stdio.h>
#include <unistd.h>

int main() {
    int counter = 0;
    while(1) {
	printf("hello from user-space! mmu ok [%d]\n", counter++);
	sleep(1);
    }
    return 0;
}
