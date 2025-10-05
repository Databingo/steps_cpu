# RISC-V Assembly: Comprehensive ALU Immediate Instruction Test
# Goal: Verify srai, ori, andi, xori, slti, sltiu.
# Instructions used: All previously verified helpers.

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    li t0, 0x2004       # UART address

    # --- Test 1: ANDI (And Immediate) ---
    # Isolate the lower 8 bits of 0xABCDEF
    li t1, 0xABCDEF
    andi t1, t1, 0xFF   # t1 should now be 0xEF
    li t2, 0xEF
    bne t1, t2, fail

    # --- Test 2: ORI (Or Immediate) ---
    # Set the upper 8 bits of 0xEF
    li t1, 0xEF
    ori t1, t1, 0xA500  # t1 should now be 0xA5EF
    li t2, 0xA5EF
    bne t1, t2, fail

    # --- Test 3: XORI (Xor Immediate) ---
    # Flip the lower 4 bits.
    li t1, 0xA5EF       # Binary ...1110 1111
    xori t1, t1, 0xF    # Binary ...0000 1111
    # Expected result: ...1110 0000 -> 0xA5E0
    li t2, 0xA5E0
    bne t1, t2, fail

    # --- Test 4: SLTI (Set if Less Than Immediate, Signed) ---
    li t1, -10          # t1 is negative
    li t2, 5            # t2 is positive
    # Test case 1: -10 < 5 ? Should be true (result = 1).
    slti t3, t1, 5
    li t4, 1
    bne t3, t4, fail
    # Test case 2: 5 < -10 ? Should be false (result = 0).
    slti t3, t2, -10
    beq t3, x0, sltiu_test # Use beq to check for 0

    # If we fall through, slti failed.
    j fail
    
sltiu_test:
    # --- Test 5: SLTIU (Set if Less Than Immediate, Unsigned) ---
    # The value -1 (0xFFFF...) is a VERY LARGE unsigned number.
    li t1, -1
    # Test case 1: -1 < 5 (unsigned)? Should be false. (0xFFFF... is not less than 5).
    sltiu t3, t1, 5
    beq t3, x0, srai_test # Check for 0.

    # If we fall through, sltiu failed.
    j fail

srai_test:
    # --- Test 6: SRAI (Shift Right Arithmetic Immediate) ---
    # This is the most critical test.
    # Create a negative number: -16 (0xFF...F0)
    li t1, -16
    
    # a) Perform a LOGICAL shift right (srli). Upper bits should become 0.
    srli t2, t1, 2      # Expected: 0x3FF...FC
    
    # b) Perform an ARITHMETIC shift right (srai). Upper bits should remain 1.
    srai t3, t1, 2      # Expected: 0xFFF...FC (-4)
    
    # Check the srli result. We expect a large positive number.
    # We can't easily check it, but we can prove it's NOT the same as srai.
    beq t2, t3, fail    # If logical and arithmetic shifts are the same, it's a bug.

    # Now, check the srai result. It should be -4.
    li t4, -4
    beq t3, t4, all_tests_passed # If srai result is -4, we succeed.
    
    # If we fall through, srai failed.
    j fail

all_tests_passed:
    # If all tests succeed, print 'P'.
    li t1, 80           # ASCII 'P'
    sd t1, 0(t0)
    
pass_loop:
    beq x0, x0, pass_loop

fail:
    # You can optionally print 'F' here to see a failure.
    # li t1, 70
    # sd t1, 0(t0)
fail_loop:
    beq x0, x0, fail_loop
