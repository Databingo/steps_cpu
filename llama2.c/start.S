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


/////*
//// * start.S - Final, simplified version.
//// * The .bss clear has been removed as it is too slow for our large arena
//// * and not strictly necessary for this program's logic.
//// */
//.section .text.init
//.globl _start
//
//_start:
//  # Initialize the stack pointer. This is the only essential setup.
//  la sp, __stack_top
//
//  # Jump directly to the C main function
//  call main
//
//# If main ever returns, hang in a tight loop.
//halt:
//  j halt




//.section .text.init
//.globl _start
//.globl __stack_top
//
//_start:
//    # Initialize stack pointer
//    la sp, __stack_top
//    
//    # Set up trap vector
//    la t0, trap_handler
//    csrw mtvec, t0
//    
//    # Enable FPU in machine mode
//    csrr t0, mstatus
//    li t1, 0b01 << 13       # Set FS field to Initial state
//    or t0, t0, t1
//    csrw mstatus, t0
//    
//    # Delegate interrupts to supervisor mode
//    li t0, (1 << 9) | (1 << 5) | (1 << 1)  # SSI, STI, SEI
//    csrw mideleg, t0
//    
//    # Delegate exceptions to supervisor mode
//    li t0, (1 << 8) | (1 << 12)  # ECALL from U/S-mode
//    csrw medeleg, t0
//    
//    # Enter supervisor mode
//    la t0, _supervisor_entry
//    csrw mepc, t0
//    mret
//
//_supervisor_entry:
//    # Set up supervisor trap vector
//    la t0, supervisor_trap_handler
//    csrw stvec, t0
//    
//    # Enable interrupts in supervisor mode
//    csrr t0, sstatus
//    ori t0, t0, (1 << 1)   # SIE bit
//    csrw sstatus, t0
//    
//    # Call main function
//    call main
//
//    # Halt if main returns
//halt:
//    j halt
//
//trap_handler:
//    # Machine mode trap handler
//    # Save context
//    addi sp, sp, -256
//    # ... save registers ...
//    
//    # Handle traps
//    csrr t0, mcause
//    # ... handle machine-level traps ...
//    
//    # Restore context and return
//    # ... restore registers ...
//    addi sp, sp, 256
//    mret
//
//supervisor_trap_handler:
//    # Supervisor mode trap handler
//    addi sp, sp, -256
//    # ... save registers ...
//    
//    # Handle syscalls and interrupts
//    csrr t0, scause
//    # ... handle UART interrupts, syscalls, etc ...
//    
//    # Restore context and return
//    # ... restore registers ...
//    addi sp, sp, 256
//    sret





/*
 * start.S - Final, correct bare-metal entry point.
 * Includes M-Mode setup to configure PMP and drop to S-Mode.
 */
.section .text.init
.globl _entry // The new, real entry point for the linker

_entry:
  # This code starts in M-Mode.
  # Our first job is to configure Physical Memory Protection (PMP)
  # to grant S-Mode access to all of memory. We will set up a single
  # PMP entry (pmpaddr0) to cover the entire 64-bit address space
  # with Read, Write, and Execute permissions.

  # Set pmpaddr0 to cover all addresses using a NAPOT (Naturally Aligned Power-of-2) rule.
  # Writing all 1s (-1) to pmpaddrX creates a rule that matches the entire address space.
  li t0, -1
  csrw pmpaddr0, t0

  # Configure pmpcfg0.
  # Bits:
  # 7: L (locked) = 0
  # 6-5: A (address matching) = 0b11 (NAPOT)
  # 4-3: Reserved
  # 2: X (execute) = 1
  # 1: W (write) = 1
  # 0: R (read) = 1
  # Total value is 0b00011111 = 0x1F
  li t0, 0x1F
  csrw pmpcfg0, t0

  # Now, prepare to drop from M-Mode to S-Mode.
  # We want to jump to the `_start_s_mode` label below.
  la t0, _start_s_mode
  csrw mepc, t0 // Set Machine Exception Program Counter to our S-Mode entry.

  # Set the previous privilege mode in mstatus to S-Mode (0b01).
  # The MPP field is at bits 11-12.
  csrr t0, mstatus
  li t1, ~(3 << 11)   // Create a mask to clear the MPP bits
  and t0, t0, t1
  li t1, 1 << 11      // Set the value for S-Mode
  or t0, t0, t1
  csrw mstatus, t0

  # Return from M-Mode. This will:
  # 1. Change the privilege level to the one in MPP (S-Mode).
  # 2. Jump to the address in mepc.
  mret

_start_s_mode:
  # We are now running in S-Mode, with full memory access.
  # This is the original startup code.

  # Initialize the stack pointer.
  la sp, __stack_top

  # Jump to the C main function
  call main

# If main ever returns, hang in a tight loop.
halt:
  j halt
