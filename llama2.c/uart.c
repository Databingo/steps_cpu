/* uart.c */
#include <stdarg.h>

// QEMU 'virt' machine UART is at this memory address
#define UART_BASE 0x10000000
#define UART_THR *(volatile unsigned char *)(UART_BASE + 0x00) // Transmit
#define UART_LSR *(volatile unsigned char *)(UART_BASE + 0x05) // Line Status

void uart_putc(char c) {
    // Wait until the transmit buffer is empty
    while ((UART_LSR & 0x20) == 0);
    UART_THR = c;
}

void uart_puts(const char *s) {
    while (*s) {
        uart_putc(*s++);
    }
}
