.section .text
.globl _start

_start:
   li sp, 0x1800 # Set stack
   li s11, 0x2004 # UART print 
   li s10, 0x2008 # UART controller

   la t0, m_trap_router      # 1. setup m-mode trap handler
   andi t0, t0, -4 # align 4 byte for directory mode of tvec
   csrw mtvec, t0

   la t0, s_trap_handler     # 2. setup s-mode trap handler
   andi t0, t0, -4
   csrw stvec, t0


   li t0, 0xffffffffffffffff # 3. Unlock PMP (Physical Memory Protection) which prevent S-mode to touch hardware
   csrw pmpaddr0, t0
   li t0, 0x0f               # 4. config NAPOT mode, Read/Write/Execute permissions
   csrw pmpcfg0, t0

   csrw medeleg, zero        # No delegation (let M-mode handler take care)
   #li t0, 0b1000            # Delegate breakpoint to s-mode
   #csrw medeleg, t0

   li t0, 0b100000000000     # 5. prepare the jump to S-mode # set mstatus.MPP to 1, Bit 11 is MPP
   csrs mstatus, t0
   la t0, s_mode_kernel      # set mepc to the address of our S-mode kernel
   csrw mepc, t0
   mret                      # 6. Drop to S-mode go to s_kernel


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

   li a0, 0x8888
   call print_reg

   csrr a0, medeleg
   call print_reg

   #la t2, s_mode_done
   ebreak # S

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
   li t0, 0b1000            # Delegate breakpoint bit3 to s-mode, ecall is bit9 not delegate yet
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
   j s_done
   #jr t2

s_done: 
   csrr t2, sepc
   addi t2, t2, 4 # skip ecall/ebreak instruction
   csrw sepc, t2
   sret




s_mode_done:
   #li s11, 0x2004
   #li t0, 65
   #lb t0, 0(s11)
   
   j s_mode_done





# functions ------

print_reg: # a0
    addi sp, sp, -40
    sd ra, 0(sp)
    sd s0, 8(sp)
    sd s1, 16(sp)
    sd s2, 24(sp)
    sd s3, 32(sp)
    mv s0, a0
    li a0, "0"
    call putchar
    li a0, "x"
    call putchar
    li s1, 60 
p_loop:
    srl s2, s0, s1      # get high nibble
    andi s2, s2, 0xF
    slti s3, s2, 10     # if < 10 number
    beq s3, x0, letter
    addi s2, s2, 48     # 0 is "0" ascii 48
    j print_h
letter:
    addi s2, s2, 55     # 10 is "A" ascii 65 ..
print_h:
    call wait_uart
    sb s2, 0(s11)       # print
    addi s1, s1, -4
    bge s1, x0, p_loop 
    ld ra, 0(sp)
    ld s0, 8(sp)
    ld s1, 16(sp)
    ld s2, 24(sp)
    ld s3, 32(sp)
    addi sp, sp, 40
    ret


putchar:  # a0
    addi sp, sp, -8
    sd ra, 0(sp)
    call wait_uart
    sb a0, 0(s11)
    ld ra, 0(sp)
    addi sp, sp, 8
    ret


puts: # a0 addr
    addi sp, sp, -16
    sd ra, 0(sp)
    sd s0, 8(sp)
    mv s0, a0
puts_loop:
    lbu a0, 0(s0)
    beq a0, x0, stop_puts # \x00 for end of string
    call putchar # a0 char
    addi s0, s0, 1 # next byte
    j puts_loop
stop_puts:
    ld ra, 0(sp)
    ld s0, 8(sp)
    addi sp, sp, 16
    ret


wait_uart:
    addi sp, sp, -16
    sd s0, 0(sp)
    sd ra, 8(sp)
wait_uart_loop:
   #li a0, 65  # A
   #sb a0, 0(s11)
    lw s0, 0(s11)
    bgt zero, s0, wait_uart_loop
    ld s0, 0(sp)
    ld ra, 8(sp)
    addi sp, sp, 16
    ret

print7: # a0, 7 char left one for null
    addi sp, sp, -16
    sd a0, 0(sp)
    sd ra, 8(sp)
    mv a0, sp
    call puts
   #ld a0, 0(sp)
    ld ra, 8(sp)
    addi sp, sp, 16
    ret
