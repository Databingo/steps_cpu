# RISC-V Assembly: Comprehensive R-Type Instruction Test
# Goal: Verify and, or, xor, sll, srl, sra, sltu.
# Instructions used: All previously verified helpers.

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    li t0, 0x2004       # UART address

    # --- Test 1: AND ---
    # We expect 0x0F0F & 0x00FF = 0x000F
    li t1, 0x0F0F
    li t2, 0x00FF
    and t3, t1, t2
    li t4, 0x000F
    bne t3, t4, fail

    # --- Test 2: OR ---
    # We expect 0x0F00 | 0x000F = 0x0F0F
    li t1, 0x0F00
    li t2, 0x000F
    or t3, t1, t2
    li t4, 0x0F0F
    bne t3, t4, fail

    # --- Test 3: XOR ---
    # We expect 0xFFFF ^ 0x00FF = 0xFF00
    li t1, 0xFFFF
    li t2, 0x00FF
    xor t3, t1, t2
    li t4, 0xFF00
    bne t3, t4, fail

    # --- Test 4: SLL (Shift Left Logical by variable) ---
    # We expect 0xA << 3 = 0x50 (80)
    li t1, 0xA          # The value to shift
    li t2, 3            # The shift amount
    sll t3, t1, t2
    li t4, 0x50
    bne t3, t4, fail
    
    # --- Test 5 & 6: SRL vs SRA (Shift Right Logical vs Arithmetic) ---
    # This is the most important test.
    # Create a negative number: -8 (0xFF...F8)
    li t1, -8
    li t2, 1            # The shift amount

    # a) Perform SRL. Should fill with 0.
    #    -8 >> 1 (logical) = 0x7FF...FC
    srl t3, t1, t2
    li t4, 0x7FFFFFFFFFFFFFFC # The expected large positive number.
    bne t3, t4, fail

    # b) Perform SRA. Should fill with 1 (sign bit).
    #    -8 >> 1 (arithmetic) = -4
    sra t3, t1, t2
    li t4, -4
    bne t3, t4, fail

    # --- Test 7: SLTU (Set if Less Than Unsigned) ---
    li t1, -1           # The largest unsigned number (0xFF...FF)
    li t2, 5            # A small positive number (0x00...05)
    
    # We expect (-1 < 5) unsigned to be FALSE, because 0xFF...FF > 5.
    sltu t3, t1, t2
    beq t3, x0, all_tests_passed # If result is 0, we pass.

    # If we fall through here, one of the tests failed.
fail:
    beq x0, x0, fail

all_tests_passed:
    # If all tests succeed, print 'P'.
    li t1, 80           # ASCII 'P'
    sd t1, 0(t0)
    
pass_loop:
    beq x0, x0, pass_loop
