/* uart.c */
//#include <stdarg.h>

// QEMU 'virt' machine UART is at this memory address
#define UART_BASE 0x10000000
#define UART_THR *(volatile unsigned char *)(UART_BASE + 0x00) // Transmit|Receive
#define UART_LSR *(volatile unsigned char *)(UART_BASE + 0x05) // Line Status


void uart_putc(char c) {
    // Wait until the transmit buffer is empty
    while ((UART_LSR & 0x20) == 0);
    UART_THR = c;
}

void uart_puts(const char *s) {
    while (*s) {
      if (*s == '\n') {
        uart_putc('\r');
      }
        uart_putc(*s++);
    }
}


// Add these to uart.c
char uart_getc() {
    // Wait until a character is received
    while ((UART_LSR & 0x01) == 0);
    return UART_THR;
}

void uart_init() {
    // Basic initialization if needed by your UART
}
