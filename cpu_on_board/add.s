# RISC-V Assembly: 'add' Test (Pure BEQ Version)
# Goal: Verify the functionality of the add instruction.
# Instructions used: add (under test), lui, li, addi, sd, beq (trusted helpers).

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    # Get UART address (0x2004) into t0.
    li t0, 0x2004

    # --- Test 1: Positive + Positive ---
    li t1, 100
    li t2, 50
    add t3, t1, t2      # t3 = 100 + 50 = 150.
    li t4, 150          # Expected value.
    beq t3, t4, test_2  # If 150 == 150, continue to the next test.
    # If not equal, fall through to the fail loop.
fail_loop_1:
    beq x0, x0, fail_loop_1

test_2:
    # --- Test 2: Positive + Negative (Subtraction) ---
    li t1, 100
    li t2, -30
    add t3, t1, t2      # t3 = 100 + (-30) = 70.
    li t4, 70           # Expected value.
    beq t3, t4, test_3  # If 70 == 70, continue to the next test.
    # If not equal, fall through to the fail loop.
fail_loop_2:
    beq x0, x0, fail_loop_2

test_3:
    # --- Test 3: Adding to x0 (Register Move) ---
    li t1, 12345
    add t3, t1, x0      # t3 = 12345 + 0 = 12345.
    li t4, 12345        # Expected value.
    beq t3, t4, test_4  # If 12345 == 12345, continue.
    # If not equal, fall through.
fail_loop_3:
    beq x0, x0, fail_loop_3

test_4:
    # --- Test 4: Chaining additions ---
    li t1, 10
    li t2, 20
    li t3, 30
    add t4, t1, t2      # t4 = 10 + 20 = 30
    add t4, t4, t3      # t4 = 30 + 30 = 60
    li t5, 60           # Expected value.
    beq t4, t5, all_tests_passed # If 60 == 60, we are done!
    # If not equal, fall through.
fail_loop_4:
    beq x0, x0, fail_loop_4

all_tests_passed:
    # If all tests succeed, we end up here.
    # Print 'P' for Pass.
    li t1, 80           # ASCII for 'P'
    sd t1, 0(t0)        # Write 'P' to UART.
    
pass_loop:
    # Halt on success.
    beq x0, x0, pass_loop
