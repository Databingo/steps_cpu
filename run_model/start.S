/* start.S */
.section .text.init
.globl _start

_start:
  # Initialize the stack pointer.
  # The linker script defines __stack_top.
  la sp, __stack_top

  # Clear the .bss section (for uninitialized global variables)
  la a0, __bss_start
  la a1, __bss_end
  bgeu a0, a1, .bss_done
.bss_loop:
  sd zero, (a0)
  addi a0, a0, 8
  bltu a0, a1, .bss_loop
.bss_done:

  # Jump to the C main function
  call main

  # If main returns, hang forever
halt:
  j halt
