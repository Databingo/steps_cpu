.section .text.init
.global _start
_start:
    /* Set up stack pointer */
    la sp, __stack_top

    /* Zero .bss section */
    la t0, __bss_start
    la t1, __bss_end
    beq t0, t1, 2f
1:
    sw zero, 0(t0)
    addi t0, t0, 4
    blt t0, t1, 1b
2:

    /* Call main() */
    call main

    /* Halt if main returns */
1:  j 1b
