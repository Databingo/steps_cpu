# RISC-V Assembly: 'slli' Test (Purest Version - No 'li')
# Goal: Verify the slli instruction without using any 'li' pseudo-instructions.
# Instructions used: slli (under test), add, beq, lui, addi, sd (trusted helpers).

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    # Get UART address (0x2004) into t0.
    lui t0, 0x2
    addi t0, t0, 4      # t0 = 0x2004

    # --- Test 1: Basic Shift ---
    # We expect t1 = 2 << 3 = 16.
    addi t1, x0, 2
    slli t1, t1, 3      # t1 should now be 16.
    addi t2, x0, 16     # Load expected value.
    beq t1, t2, test_2  # If 16 == 16, continue.
fail_loop_1:
    beq x0, x0, fail_loop_1

test_2:
    # --- Test 2: Shift by Zero ---
    # We expect t1 = 16 << 0 = 16.
    slli t1, t1, 0      # t1 should still be 16.
    addi t2, x0, 16     # Expected value is unchanged.
    beq t1, t2, test_3  # If 16 == 16, continue.
fail_loop_2:
    beq x0, x0, fail_loop_2

test_3:
    # --- Test 3: Shifting to the top of the 32-bit range ---
    # We will construct 0xABC and shift it to 0xABC00000.
    
    # Construct 0xABC manually. 0xA00 + 0xB0 + 0xC
    addi t1, x0, 0xA00
    addi t2, x0, 0xB0
    add  t1, t1, t2
    addi t2, x0, 0xC
    add  t1, t1, t2     # t1 now holds 0xABC
    
    # Perform the shift.
    slli t1, t1, 20     # t1 should now be 0xABC00000
    
    # Build the expected value with LUI.
    lui t2, 0xABC00     # t2 = 0xABC00000
    beq t1, t2, test_4  # If equal, continue.
fail_loop_3:
    beq x0, x0, fail_loop_3

test_4:
    # --- Test 4: Shifting all bits out ---
    # We expect t1 = (any value) << 64 (or more) = 0.
    lui t1, 0xDEADB     # t1 = 0xDEADB000
    addi t1, t1, 0xEEF  # t1 = 0xDEADBEEF
    
    slli t1, t1, 63     # Shift all but one bit out.
    slli t1, t1, 1      # Shift the last bit out. t1 should be 0.
    beq t1, x0, all_tests_passed # Compare with the zero register.
fail_loop_4:
    beq x0, x0, fail_loop_4

all_tests_passed:
    # If all tests succeed, print 'P'.
    addi t1, x0, 80     # ASCII 'P'
    sd t1, 0(t0)
    
pass_loop:
    beq x0, x0, pass_loop # Halt on success.
