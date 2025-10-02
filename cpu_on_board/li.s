# RISC-V Assembly: 64-bit 'li' Pseudo-Instruction Test (Corrected)
# Goal: Verify the assembler correctly expands 'li' for a full 64-bit value.
# Instructions used: li (under test), lui, addi, add, slli, sd, beq (trusted).

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    li t0, 0x2004       # UART address

    # --- Action Phase: The Pseudo-Instruction Under Test (li 64-bit) ---

    # 1. Use 'li' to load a full 64-bit constant.
    li t1, 0x123456780ABCDEF0

    # --- Verification Phase ---

    # 2. Manually construct the *exact same* 64-bit constant in t2.
    
    #   a) Construct the upper 32 bits (0x12345678) in a temporary register t3.
    lui  t3, 0x12345
    addi t3, t3, 0x678      # t3 = 0x12345678
    
    #   b) Shift the upper bits into their final position.
    slli t3, t3, 32         # t3 should now be 0x12345678_00000000
    
    #   c) Construct the lower 32 bits (0x0ABCDEF0) in a temporary register t4.
    #      This is the corrected sequence.
    lui  t4, 0xABCE
    addi t4, t4, -272       # t4 = 0xABCE000 - 0x110 = 0x0ABCDEF0
    
    #   d) Combine the upper and lower halves into our final expected value in t2.
    add t2, t3, t4          # t2 = 0x12345678_00000000 + 0x0ABCDEF0
                            # t2 should now be 0x12345678_0ABCDEF0

    # 3. Compare the 'li'-generated value (t1) with our manually constructed value (t2).
    beq t1, t2, pass
    
fail:
    # If the values are not equal, hang here.
    beq x0, x0, fail

pass:
    # If the values are equal, the test succeeds. Print 'P'.
    li t1, 80               # ASCII for 'P'
    sd t1, 0(t0)            # Write 'P' to UART.
    
pass_loop:
    beq x0, x0, pass_loop
