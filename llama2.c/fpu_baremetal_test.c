#include "uart.c"

volatile float a = 1.5f, b = 2.5f, c;
char buf[32];

void itoa(int n, char* b) {
    if(n==0){b[0]='0';b[1]='\0';return;}
    int i=0, neg=0;
    if(n<0){neg=1;n=-n;}
    while(n!=0){b[i++]=(n%10)+'0';n/=10;}
    if(neg)b[i++]='-';
    int s=0,e=i-1; while(s<e){char t=b[s];b[s]=b[e];b[e]=t;s++;e--;} b[i]='\0';
}

// Enable FPU in machine mode
void enable_fpu() {
    asm volatile (
        "csrr t0, mstatus\n"
        "li t1, 0b01 << 13\n"   // Set FS field to Initial state
        "or t0, t0, t1\n"
        "csrw mstatus, t0\n"
        "fssr x0\n"             // Clear FPU state
    );
}

int main() {
    enable_fpu();  // MUST be first executable statement!
    uart_puts("Bare-metal FPU test for RISC-V\n");
    c = a * b;
    uart_puts("Result bits: ");
    int* ival = (int*)&c;
    itoa(*ival, buf);
    uart_puts(buf);
    uart_puts("\n");
    //while(1);
    return 0;
} 
