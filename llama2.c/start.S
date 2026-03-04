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
 * Includes M-Mode setup to enable the FPU, configure PMP,
 * and then drop to S-Mode to run the C code.
 */
.section .text.init
.globl _entry // The new, real entry point for the linker

_entry:
  # This code starts in M-Mode.

  # 1. Enable the FPU.
  # Set the FS bits (14:13) in mstatus to 0b01 (Initial).
  li t0, (1 << 13)
  csrs mstatus, t0

  # 2. Configure PMP to grant S-Mode access to all of memory.
  # We will set up pmpaddr0 to cover the entire address space
  # with Read, Write, and Execute permissions.
  li t0, -1
  csrw pmpaddr0, t0
  li t0, 0x1F # A=NAPOT, R=1, W=1, X=1
  csrw pmpcfg0, t0

  # 3. Prepare to drop from M-Mode to S-Mode.
  # We want to jump to the `s_mode_start` label below.
  la t0, s_mode_start
  csrw mepc, t0 // Set Machine Exception Program Counter.

  # Set the previous privilege mode in mstatus to S-Mode (MPP=0b01).
  csrr t0, mstatus
  li t1, ~(3 << 11)   // Create a mask to clear the MPP bits
  and t0, t0, t1
  li t1, 1 << 11      // Set the value for S-Mode
  or t0, t0, t1
  csrw mstatus, t0

  # 4. Execute the privilege drop. This jumps to mepc in S-Mode.
  mret

s_mode_start:
  # We are now running in S-Mode, with FPU enabled and full memory access.
  
  # Initialize the stack pointer.
  la sp, __stack_top

  # Jump to the C main function.
  call main

# If main ever returns, hang in a tight loop.
halt:
  j halt
