.section .text
.globl _start

_start:
   # 1. setup m-mode trap handler (sbi interface)
   la t0, sbi_trap_handler
   csrw mtvec, t0


sbi_trap_handler:  # a7 Extension 1 putchar, 2 getchar, 0 settimer; a0 is the first argument a1..a5
   li t0, 1 # look a7 to see function is requested(sbi standard)
   beq a7, t0, sbi_handler_putchar  # (SBI_CONSOLE_PUTCHAR ( a7 = 0x01)

   li t0, 0
   beq a7, t0, sbi_hander_timer

   li a0, -1  # unknow SBI_ERR_NOT_SUPPORTED = -1
   j ecall_done
  
sbi_handler_putchar:
   li s11, 0x2004
wait_uart_sbi:
   lw t1, 0(s11)
   blt t1, zero, wait_uart_sbi  # sifive uart negetive is full
   sb a0, 0(s11)
   j ecall_done

sbi_hander_timer:
   csrw mtimecmp, a0 # S-mode passes new time in a0
   li a0, 0          # Success return a0=0
   j ecall_done
   


ecall_done: 
   csrr r0, mepc
   addi t0, t0, 4 # skip ecall instruction
   csrw mepc, t0
   mret
   




