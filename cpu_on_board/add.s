# RISC-V Assembly: 'add' Test (Pure BEQ Version)
# Goal: Verify the functionality of the add instruction.
# Instructions used: add (under test), lui, li, addi, sw, beq (trusted helpers).

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    # Get UART address (0x2004) into t0.
    addi t0, x0, 2047   # t0 = 2047
    addi t0, t0, 2047   # t0 = 4094
    addi t0, t0, 2047   # t0 = 6141
    addi t0, t0, 2047   # t0 = 8188 (0x1FFC)
    addi t0, t0, 8      # t0 = 0x2004. UART address is ready.

    # --- Test 1: Positive + Positive ---
    addi t1, x0, 100
    addi t2, x0, 50
    add t3, t1, t2      # t3 = 100 + 50 = 150.
    addi t4, x0, 150          # Expected value.
    beq t3, t4, test_2  # If 150 == 150, continue to the next test.
    # If not equal, fall through to the fail loop.
fail_loop_1:
    beq x0, x0, fail_loop_1

test_2:
    # --- Test 2: Positive + Negative (Subtraction) ---
    addi t1, x0, 100
    addi t2, x0, -30
    add t3, t1, t2      # t3 = 100 + (-30) = 70.
    addi t4, x0, 70           # Expected value.
    beq t3, t4, test_3  # If 70 == 70, continue to the next test.
    # If not equal, fall through to the fail loop.
fail_loop_2:
    beq x0, x0, fail_loop_2

test_3:
    # --- Test 3: Adding to x0 (Register Move) ---
    lui t1, 0x3
    addi t1, t1, 0x39
    add t3, t1, x0      # t3 = 12345 + 0 = 12345.
    lui t4, 0x3
    addi t4, t4, 0x39
    beq t3, t4, test_4  # If 12345 == 12345, continue.
    # If not equal, fall through.
fail_loop_3:
    beq x0, x0, fail_loop_3

test_4:
    # --- Test 4: Chaining additions ---
    addi t1, x0, 10
    addi t2, x0, 20
    addi t3, x0, 30
    add t4, t1, t2      # t4 = 10 + 20 = 30
    add t4, t4, t3      # t4 = 30 + 30 = 60
    addi t5, x0, 60           # Expected value.
    beq t4, t5, all_tests_passed # If 60 == 60, we are done!
    # If not equal, fall through.
fail_loop_4:
    beq x0, x0, fail_loop_4

all_tests_passed:
    # If all tests succeed, we end up here.
    # Print 'P' for Pass.
    addi t1, x0, 80           # ASCII for 'P'
    sw t1, 0(t0)        # Write 'P' to UART.
    
pass_loop:
    # Halt on success.
    beq x0, x0, pass_loop
