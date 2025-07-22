///* start.S */
//.section .text.init
//.global _start
//_start:
//    /* Set up stack pointer */
//    la sp, __stack_top
//
//    /* Zero .bss section */
//    la t0, __bss_start
//    la t1, __bss_end
//    beq t0, t1, 2f
//1:
//    sw zero, 0(t0)
//    addi t0, t0, 4
//    blt t0, t1, 1b
//2:
//
//    /* Call main() */
//    call main
//
//    /* Halt if main returns */
//    1: j 1b


/*
 * start.S - Final, simplified version.
 * The .bss clear has been removed as it is too slow for our large arena
 * and not strictly necessary for this program's logic.
 */
.section .text.init
.globl _start

_start:
  # Initialize the stack pointer. This is the only essential setup.
  la sp, __stack_top

  # Jump directly to the C main function
  call main

# If main ever returns, hang in a tight loop.
halt:
  j halt
