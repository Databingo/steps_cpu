#include <sbi/sbi_platform.h>
#include <sbi/sbi_console.h>
#include <sbi_utils/timer/aclint_mtimer.h>

/* --- 1. MEMORY MAP CONFIGURE --- */
#define RAM_BASE      0x80000000 // Replace with your `Ram_base` from header.vh
#define ART_BASE      0x10000000 // Replace with your `Art_base` from header.vh

/* JTAG UART Addresses (using your swapped ~bus_address[2] logic) */
#define JUART_CONTROL ((volatile uint32_t *)(ART_BASE + 0x00))
#define JUART_DATA    ((volatile uint32_t *)(ART_BASE + 0x04))

/* --- 2. JTAG UART DRIVER --- */
static void altera_jtag_uart_putc(char ch) {
    // Wait until JTAG UART FIFO has space (top 16 bits > 0)
    while ((*JUART_CONTROL & 0xFFFF0000) == 0);
    *JUART_DATA = ch;
}

static struct sbi_console_device jtag_console = {
    .name = "altera_jtag_uart",
    .console_putc = altera_jtag_uart_putc,
    .console_getc = NULL
};

/* --- 3. TIMER DRIVER --- */
static struct aclint_mtimer_data mtimer = {
    .mtime_freq    = 50000000,   // 50 MHz (matches your CLOCK_50 / clock_1hz)
    .mtime_addr    = 0x0200BFF8, // Matches your Verilog: mtime
    .mtime_size    = 8,
    .mtimecmp_addr = 0x02004000, // Matches your Verilog: mtimecmp
    .mtimecmp_size = 8,
    .has_64bit_mmio = true,
};

/* --- 4. OPENSBI INITIALIZATION HOOKS --- */
static int my_board_early_init(bool cold_boot) {
    if (cold_boot) {
        sbi_console_set_device(&jtag_console);
    }
    return 0;
}

static int my_board_timer_init(bool cold_boot) {
    if (cold_boot) {
        aclint_mtimer_cold_init(&mtimer, NULL);
    }
    return 0;
}

const struct sbi_platform_operations platform_ops = {
    .early_init = my_board_early_init,
    .timer_init = my_board_timer_init,
    // ipi_init is intentionally left out (NULL) since we don't need it yet!
};

/* --- 5. PLATFORM DEFINITION --- */
const struct sbi_platform platform = {
    .opensbi_version = OPENSBI_VERSION,
    .platform_version = SBI_PLATFORM_VERSION(0x1, 0x00),
    .name = "My Custom FPGA RISC-V",
    .features = SBI_PLATFORM_DEFAULT_FEATURES,
    .hart_count = 1,
    .hart_stack_size = 4096,
    .platform_ops_addr = (unsigned long)&platform_ops
};
