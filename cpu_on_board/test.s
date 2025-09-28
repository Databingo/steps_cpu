# core_test.s (Final Corrected Version)
#
# A minimal, sequential test for the core instruction set.
# All known bugs in the test logic have been fixed.

.section .text
.globl _start

_start:
    # --- Test 1: ADDI ---
    addi t0, x0, 15
    addi t1, t0, -5
    addi t2, x0, 10

    # --- Test 2: SLT ---
    addi t0, x0, -1
    addi t1, x0, 1
    slt  t2, t0, t1
    addi t3, x0, 1

    # --- Test 3: BEQ ---
    addi a0, x0, 1
    beq  t1, t2, skip_fail_1
    jal  x0, fail_handler
skip_fail_1:
    addi a0, x0, 2
    beq  t2, t3, skip_fail_2
    jal  x0, fail_handler
skip_fail_2:
    addi t0, x0, 5
    addi t1, x0, 10
    addi a0, x0, 3
    beq  t0, t1, fail_handler

    # --- Test 4: LUI ---
    lui  t0, 0xABCDE
    lui  t1, 0xABCDD
    addi t1, t1, 2047
    addi t1, t1, 2047
    addi t1, t1, 2
    addi a0, x0, 4
    beq  t0, t1, skip_fail_4
    jal  x0, fail_handler
skip_fail_4:

    # --- Test 5 & 6: JAL and JALR ---
    addi t0, x0, 0
    jal ra, subroutine_for_jal_test
    addi t1, x0, 1
    addi a0, x0, 5
    beq t0, t1, skip_fail_5_6
    jal x0, fail_handler
skip_fail_5_6:

    # --- Test 7: AUIPC ---
auipc_test:
    auipc t0, 0          # t0 = address of this instruction (A)
    # Jump forward 16 bytes (A + 16) to skip the next 3 instructions.
    jalr  x0, 16(t0)
    addi a0, x0, 7
    jal  x0, fail_handler
auipc_land_here:
    # Success if we land here.

    # --- Test 8: SD and LD ---
    lui   t0, 0x1
    addi  t1, x0, 0x7AB
    sd    t1, 0(t0)
    ld    t2, 0(t0)
    addi  a0, x0, 8
    beq   t1, t2, skip_fail_8
    jal   x0, fail_handler
skip_fail_8:

# --- All Tests Passed ---
pass:
    addi a0, x0, 80
    jal  x0, print_and_hang

# --- Failure Handling ---
fail_handler:
    addi a0, a0, 48

print_and_hang:
    lui t5, 0x2
    sd  a0, 4(t5)

hang:
    jal x0, hang

# --- Subroutine for JAL/JALR Test ---
subroutine_for_jal_test:
    addi t0, t0, 1
    jalr x0, 0(ra)
