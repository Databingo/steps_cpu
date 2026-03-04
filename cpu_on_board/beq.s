# RISC-V Assembly: 'beq' Test (Purest Version - only beq)

.section .text
.globl _start

_start:
    addi t0, x0, 2047   # t0 = 2047
    addi t0, t0, 2047   # t0 = 4094
    addi t0, t0, 2047   # t0 = 6141
    addi t0, t0, 2047   # t0 = 8188 (0x1FFC)
    addi t0, t0, 8      # t0 = 0x2004. UART address is ready.

    # --- Test 1: Registers are equal, branch should be TAKEN ---
    addi t1, x0, 123
    addi t2, x0, 123
    # If t1 == t2, jump over the fail loop.
    beq t1, t2, test_2
fail_loop_1:
    beq x0, x0, fail_loop_1 # Fail loop 1

test_2:
    # --- Test 2: Registers are NOT equal, branch should NOT be taken ---
    addi t1, x0, 456
    addi t2, x0, 789
    # If t1 == t2, jump into the fail loop. Should not be taken.
    beq t1, t2, fail_loop_2
    # Success case falls through.

    # --- Test 3: Backwards branch ---
    # This is a bit trickier. We create a simple countdown loop.
    addi t1, x0, 3            # Loop counter
test_3_loop:
    addi t1, t1, -1     # Decrement counter
    # If t1 == x0, the branch is NOT taken, and the loop ends.
    beq t1, x0, all_tests_passed
    # If t1 != x0, branch back to the start of the loop.
    beq x0, x0, test_3_loop # Unconditional jump back

fail_loop_2:
    beq x0, x0, fail_loop_2 # Fail loop 2

all_tests_passed:
    addi t1, x0, 80           # ASCII 'P'
    sb t1, 0(t0)        # Write 'P' to UART.
pass_loop:
    beq x0, x0, pass_loop # Halt on success.
