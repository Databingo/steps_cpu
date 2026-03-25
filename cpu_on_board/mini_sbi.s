.section .text
.globl _start

_start:
   # 1. setup m-mode trap handler (sbi interface)
   la t0, sbi_trap_handler
   csrw mtvec, t0

   la t0, s_trap_handler # setup s-mode trap handler
   csrw stvec, t0



   # 2. unlock PMP (Physical Memory Protection) which prevent S-mode to touch hardware
   li t0, 0xffffffffffffffff
   csrw pmpaddr0, t0
   li t0, 0x0f    # NAPOT mode, Read/Write/Execute permissions
   csrw pmpcfg0, t0
 
   # 3. prepare the jump to S-mode
   #li t0, (1<<11) # set mstatus.MPP to 1, Bit 11 is MPP
   li t0, 0b100000000000 # set mstatus.MPP to 1, Bit 11 is MPP
   csrs mstatus, t0
   # set mepc to the address of our S-mode kernel
   la t0, s_mode_kernel
   csrw mepc, t0

   # Look at mstatus.MPP but see S-mode, jump to mepc then transition to S-mode
   mret













sbi_trap_handler:  # a7 Extension 1 putchar, 2 getchar, 0 settimer; a0 is the first argument a1..a5
   li t0, 1 # look a7 to see function is requested(sbi standard)
   beq a7, t0, sbi_handler_putchar  # (SBI_CONSOLE_PUTCHAR ( a7 = 0x01)

   li t0, 0
   beq a7, t0, sbi_handler_timer

   li a0, -1  # unknow SBI_ERR_NOT_SUPPORTED = -1
   j ecall_done
  
sbi_handler_putchar:
   li s11, 0x2004
wait_uart_sbi:
   lw t1, 0(s11)
   blt t1, zero, wait_uart_sbi  # sifive uart negetive is full
   sb a0, 0(s11)
   li a0, 0     # return success
   j ecall_done

sbi_handler_timer:
   li t1, 0x2004000  # riscv use MMIP for mtimecmp
   sd a0, 0(t1)      # S-mode passes new time in a0
   li a0, 0          # Success return a0=0
   j ecall_done
   


ecall_done: 
   csrr t0, mepc
   addi t0, t0, 4 # skip ecall instruction
   csrw mepc, t0
   mret
   

s_mode_kernel:
   li a0, "H"
   li a7, 1
   ecall

   li a0, "i"
   li a7, 1
   ecall

   li t0, 0b1000  # delegate breakpoint to s-mode
   csrw medeleg, t0
   ebreak

halt:
   j halt

s_mode_done:
   j s_mode_done


s_trap_handler:
   li a0, "S"
   li a7, 1
   ecall
   j halt

