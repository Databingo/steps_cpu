## beq.s
## A simple test for the BEQ (Branch if Equal) instruction.
##
## It prints 'P' to a simulated UART at address 0x2004 if the test passes,
## otherwise it prints 'F'.
#
#.section .text
#.globl _start
#
#_start:
#    # 1. Setup the test condition.
#    # Load two registers with the same value.
#    addi t0, x0, 25      # t0 = 25
#    addi t1, x0, 25      # t1 = 25
#
#    # 2. Execute the instruction under test.
#    # If beq works, it will see t0 == t1 and branch to `pass_label`.
#    beq t0, t1, pass_label
#
## --- Fail Section ---
## This code should be skipped by the branch.
## If the program executes this, the test has failed.
#fail_label:
#    addi a0, x0, 70      # Load ASCII for 'F' (Fail)
#    lui  t2, 0x2         # t2 = 0x2000
#    sd   a0, 4(t2)       # Store 'F' to address 0x2004
#    j hang               # Go to infinite loop
#
## --- Pass Section ---
## The program should jump here upon a successful beq.
#pass_label:
#    addi a0, x0, 80      # Load ASCII for 'P' (Pass)
#    lui  t2, 0x2         # t2 = 0x2000
#    sd   a0, 4(t2)       # Store 'P' to address 0x2004
#
## --- End of Program ---
## Infinite loop to halt the CPU.
#hang:
#    j hang


# RISC-V Assembly: 'beq' Test (Purest Version - only beq)

.section .text
.globl _start

_start:
    li t0, 0x2004       # UART address

    # --- Test 1: Registers are equal, branch should be TAKEN ---
    li t1, 123
    li t2, 123
    # If t1 == t2, jump over the fail loop.
    beq t1, t2, test_2
fail_loop_1:
    beq x0, x0, fail_loop_1 # Fail loop 1

test_2:
    # --- Test 2: Registers are NOT equal, branch should NOT be taken ---
    li t1, 456
    li t2, 789
    # If t1 == t2, jump into the fail loop. Should not be taken.
    beq t1, t2, fail_loop_2
    # Success case falls through.

    # --- Test 3: Backwards branch ---
    # This is a bit trickier. We create a simple countdown loop.
    li t1, 3            # Loop counter
test_3_loop:
    addi t1, t1, -1     # Decrement counter
    # If t1 == x0, the branch is NOT taken, and the loop ends.
    beq t1, x0, all_tests_passed
    # If t1 != x0, branch back to the start of the loop.
    beq x0, x0, test_3_loop # Unconditional jump back

fail_loop_2:
    beq x0, x0, fail_loop_2 # Fail loop 2

all_tests_passed:
    li t1, 80           # ASCII 'P'
    sd t1, 0(t0)        # Write 'P' to UART.
pass_loop:
    beq x0, x0, pass_loop # Halt on success.
