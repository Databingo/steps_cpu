volatile unsigned int * const OUTPUT_ADDR = (volatile unsigned int *)0x1000;

void _start() {
    unsigned int a = 42;
    unsigned int b = 58;
    unsigned int result = a + b;

    // Store result to memory-mapped output
    *OUTPUT_ADDR = result;

    // Infinite loop to halt
    while (1) {}
}
