# Physical Memory Map:
# 0x0000 - 0x17FF : BRAM (Micro-SBI lives here)
# 0x8000_0000     : SDRAM (We will put the "S-mode Kernel" here)

.section .text
.globl _start

_start:
    # ---------------------------------------------------------
    # 1. SETUP M-MODE TRAP HANDLER (The SBI Interface)
    # ---------------------------------------------------------
    la t0, sbi_trap_handler
    csrw mtvec, t0

    # ---------------------------------------------------------
    # 2. CONFIGURE PMP (Unlock all memory for S-mode)
    # ---------------------------------------------------------
    # By default, S-mode has 0 permissions. We must grant it.
    li t0, 0xffffffffffffffff
    csrw pmpaddr0, t0       # Cover all memory
    li t0, 0x0f             # Address matching: NAPOT, Permissions: R,W,X
    csrw pmpcfg0, t0

    # ---------------------------------------------------------
    # 3. DELEGATE TRAPS TO S-MODE
    # ---------------------------------------------------------
    # Tell hardware: "If a Page Fault or Breakpoint happens in S-mode, 
    # let S-mode handle it. Don't jump to M-mode."
    li t0, 0xFFFF
    csrw medeleg, t0
    csrw mideleg, t0

    # ---------------------------------------------------------
    # 4. PREPARE TRANSITION TO S-MODE
    # ---------------------------------------------------------
    li t0, (1 << 11)        # mstatus.MPP = 01 (Supervisor Mode)
    csrs mstatus, t0
    
    la t0, s_mode_kernel    # Set destination
    csrw mepc, t0

    # Go!
    mret

# ---------------------------------------------------------
# M-MODE SBI TRAP HANDLER
# This is called when S-mode does an 'ecall'
# ---------------------------------------------------------
.align 4
sbi_trap_handler:
    # Look at a7 to see what function is requested (SBI standard)
    # We will implement SBI_CONSOLE_PUTCHAR (extension 0x01)
    li t0, 1
    beq a7, t0, sbi_putchar
    
    # Otherwise just return
    csrr t0, mepc
    addi t0, t0, 4          # Skip the ecall instruction
    csrw mepc, t0
    mret

sbi_putchar:
    li s11, 0x2004          # UART Addr
wait_uart_sbi:
    lw t1, 0(s11)
    bgt t1, zero, wait_uart_sbi
    sb a0, 0(s11)           # Print char in a0
    
    csrr t0, mepc
    addi t0, t0, 4          # Skip the ecall instruction
    csrw mepc, t0
    mret

# =========================================================
# S-MODE KERNEL (The "Payload")
# =========================================================
.section .text.kernel
s_mode_kernel:
    # We are now in S-mode!
    
    # Test 1: Direct UART Print (Tests PMP)
    li s11, 0x2004
    li t0, 'S'
    sb t0, 0(s11)           # If PMP is broken, this will trap/hang
    
    # Test 2: SBI Call (Tests ecall transition)
    li a0, 'B'              # Character to print
    li a7, 1                # SBI Function: Console Putchar
    ecall                   # Jump to M-mode handler
    
    li a0, 'I'
    li a7, 1
    ecall

    li a0, '!'
    li a7, 1
    ecall

s_mode_loop:
    j s_mode_loop
