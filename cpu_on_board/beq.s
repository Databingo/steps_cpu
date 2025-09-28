# beq.s
# A simple test for the BEQ (Branch if Equal) instruction.
#
# It prints 'P' to a simulated UART at address 0x2004 if the test passes,
# otherwise it prints 'F'.

.section .text
.globl _start

_start:
    # 1. Setup the test condition.
    # Load two registers with the same value.
    addi t0, x0, 25      # t0 = 25
    addi t1, x0, 25      # t1 = 25

    # 2. Execute the instruction under test.
    # If beq works, it will see t0 == t1 and branch to `pass_label`.
    beq t0, t1, pass_label

# --- Fail Section ---
# This code should be skipped by the branch.
# If the program executes this, the test has failed.
fail_label:
    addi a0, x0, 70      # Load ASCII for 'F' (Fail)
    lui  t2, 0x2         # t2 = 0x2000
    sd   a0, 4(t2)       # Store 'F' to address 0x2004
    j hang               # Go to infinite loop

# --- Pass Section ---
# The program should jump here upon a successful beq.
pass_label:
    addi a0, x0, 80      # Load ASCII for 'P' (Pass)
    lui  t2, 0x2         # t2 = 0x2000
    sd   a0, 4(t2)       # Store 'P' to address 0x2004

# --- End of Program ---
# Infinite loop to halt the CPU.
hang:
    j hang
