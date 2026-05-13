#include <unistd.h>

int main() {
    // Stage 100: Program started
    volatile int stage = 100;
    
    // Pointer to the UART register
    volatile unsigned int *uart_tx = (volatile unsigned int *)0x2004;

    // --- STEP 1: Attempt to write 'A' ---
    // If this hangs, the CPU is stuck inside the Store instruction logic.
    *uart_tx = 'A';
    stage = 111; // Reached Stage 111 (0x6F)

    // --- STEP 2: Attempt to write 'B' ---
    // If this hangs, the first write worked, but the second one is stuck 
    // waiting for a 'ready' bit that never comes.
    *uart_tx = 'B';
    stage = 112; // Reached Stage 112 (0x70)

    // --- STEP 3: Final Calculation ---
    volatile int x = 100;
    volatile int y = 23;
    if ((x + y) == 123) {
        stage = 123; // Reached FINAL Stage 123 (0x7B)
    }

    // This return triggers the Kernel Panic exitcode
    return stage; 
}
