//// minimal_os.c
//#include <stdint.h>
//
//// CLINT core local interruptor
//#define CLINT_BASE 0x02000000  // Base address of CLINT
//#define MTIME    (*(volatile uint64_t *)(CLINT_BASE + 0xBFF8)) // volatile
//易变内存（硬件可改） #define MTIMECMP (*(volatile uint64_t *)(CLINT_BASE +
// 0x4000)) // mtimecmp register (in ram)
//
//// UART universal asynchronous receiver/transmitter 通用异步接收器/发送器
//#define UART_BASE 0x10000000
//#define UART_TX  (*(volatile uint8_t *)(UART_BASE))
//
// void put_char(char c) {
//    while ((UART_TX & 0x80) == 0 ); // Wait until UART is ready
//    UART_TX = c;
//}
//
// void print(const char *str) {
//    while (*str) put_char(*str++);
//}
//
// void set_timer(uint64_t ticks){
// MTIMECMP = MTIME + ticks; // Set mtimecmp to current mtime + ticks(schedule
// timer interrupt)
//}
//
// int main() {
//   print("Minimal RISC-V OS starting...\n");
//   set_timer(500000); // Set timer interrupt after some ticks
//
//   // Infinite loop - OS will wait for timer interrupts
//   while(1) {
//    // Here could be more backgroun tasks
//   }
//}
//
// void timer_handler() {
//    print("Timer Interrupt\n");
//    set_timer(500000);
//}

#include <stddef.h>
#include <stdint.h>

//声明的时候，*str 表示字符串指针，引用的时候，*str 指取值，str 是指针地址, str++ 是地址加一

unsigned char *uart = (unsigned char *)0x10000000;
void putchar(char c) {
  *uart = c;
  return;
}

void print(const char *str) {
  while (*str != '\0') {
    putchar(*str);
    str++;
  }
  return;
}

void kmain(void) {
  print("Hello world! 你好世界！\r\n");
  while (1) {
    putchar(*uart);
    //putchar('T');
  }
  return;
}
