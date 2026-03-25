.section .text
.globl _start

_start:
   la t0, m_trap_router      # 1. setup m-mode trap handler (sbi interface)
   csrw mtvec, t0

   la t0, s_trap_handler     # 2. setup s-mode trap handler
   csrw stvec, t0


   li t0, 0xffffffffffffffff # 3. Unlock PMP (Physical Memory Protection) which prevent S-mode to touch hardware
   csrw pmpaddr0, t0
   li t0, 0x0f               # NAPOT mode, Read/Write/Execute permissions
   csrw pmpcfg0, t0

   csrw medeleg, zero        # No delegation (let M-mode handler take care)
   #li t0, 0b1000            # Delegate breakpoint to s-mode
   #csrw medeleg, t0

   li t0, 0b100000000000     # 4. prepare the jump to S-mode # set mstatus.MPP to 1, Bit 11 is MPP
   csrs mstatus, t0
   la t0, s_mode_kernel      # set mepc to the address of our S-mode kernel
   csrw mepc, t0
   mret                      # 5. Drop to S-mode go to s_kernel


m_trap_router:
   #sd t0, 0x300(zero)
   #sd t1, 0x308(zero)



   csrr t0, mcause  # check type
   li t1, 9  # ecall from S-mode
   beq t0, t1, m_ecall_router

   li t1, 3 # breakpoint
   beq t0, t1, m_ebreak_handler

   j m_done

m_ecall_router:  # a7 Extension 1 putchar, 2 getchar, 0 settimer; a0 is the first argument a1..a5  # look a7 to see function is requested(sbi standard)
   li t0, 1
   beq a7, t0, m_handler_putchar  # (SBI_CONSOLE_PUTCHAR ( a7 = 0x01)

   li t0, 0
   beq a7, t0, m_handler_timer

   li t0, 0x10
   beq a7, t0, m_handler_deleg

   li a0, -1  # unknow SBI_ERR_NOT_SUPPORTED = -1
   j m_done

m_ebreak_handler:
   li a0, "M"
   li s11, 0x2004
wait_uart_m:
   lw t1, 0(s11)
   blt t1, zero, wait_uart_m  # sifive uart negetive is full
   sb a0, 0(s11)
   li a0, 0     # return success
   j m_done
   
m_handler_putchar:
   li s11, 0x2004
wait_uart_sbi:
   lw t1, 0(s11)
   blt t1, zero, wait_uart_sbi  # sifive uart negetive is full
   sb a0, 0(s11)
   li a0, 0     # return success
   j m_done

m_handler_timer:
   li t1, 0x2004000  # riscv use MMIP for mtimecmp
   sd a0, 0(t1)      # S-mode passes new time in a0
   li a0, 0          # Success return a0=0
   j m_done

m_handler_deleg:
   #li t0, 0x800 # 0b1000
   li t0, 0b1000            # Delegate breakpoint to s-mode
   csrw medeleg, t0 
   li a0, 0
   j m_done

m_done: 
   csrr t0, mepc
   addi t0, t0, 4 # skip ecall/ebreak instruction
   csrw mepc, t0
   #ld t0, 0x900(zero)
   #ld t1, 0x908(zero)
   mret


s_trap_handler:
   li a0, "S"
   li a7, 1
   ecall
   #j s_done
   jr t2

s_done: 
   csrr t2, sepc
   addi t2, t2, 4 # skip ecall/ebreak instruction
   csrw sepc, t2
   sret



s_mode_kernel:
   ebreak   # M

   li a0, "H"
   li a7, 1
   ecall

   li a0, "i"
   li a7, 1
   ecall
 
   li a7, 0x10
   ecall  # turn delegate

   la t2, s_mode_done
   ebreak # S

s_mode_done:
   j s_mode_done


