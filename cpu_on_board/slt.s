# slt.s
# A minimal test for the SLT (Set on Less Than, signed) instruction.
#
# It prints 'P' to a simulated UART at address 0x2004 if the test passes,
# otherwise it prints 'F'.

.section .text
.globl _start

_start:
    # --- Test 1: Signed comparison where rs1 < rs2 should be TRUE ---
    # Compare -1 and 1. The result in t2 should be 1.
    addi t0, x0, -1      # t0 = -1 (0xFF...FF)
    addi t1, x0, 1       # t1 = 1
    slt  t2, t0, t1      # t2 = (t0 < t1) ? 1 : 0.  Since -1 < 1, t2 should be 1.

    # Check if the result is 1.
    addi t3, x0, 1       # Load 1 into t3 for comparison
    bne  t2, t3, fail_label # If result is NOT 1, branch to fail.

    # --- Test 2: Signed comparison where rs1 < rs2 should be FALSE ---
    # Compare 1 and -1. The result in t2 should be 0.
    slt  t2, t1, t0      # t2 = (t1 < t0) ? 1 : 0. Since 1 is NOT < -1, t2 should be 0.

    # Check if the result is 0.
    bne  t2, x0, fail_label # If result is NOT 0 (x0), branch to fail.

# --- Pass Section ---
# If we reached here without branching, all tests passed.
pass_label:
    addi a0, x0, 80      # Load ASCII for 'P' (Pass)
    lui  t2, 0x2         # t2 = 0x2000
    sd   a0, 4(t2)       # Store 'P' to address 0x2004
    j hang               # Go to infinite loop

# --- Fail Section ---
fail_label:
    addi a0, x0, 70      # Load ASCII for 'F' (Fail)
    lui  t2, 0x2         # t2 = 0x2000
    sd   a0, 4(t2)       # Store 'F' to address 0x2004

# --- End of Program ---
# Infinite loop to halt the CPU.
hang:
    j hang
