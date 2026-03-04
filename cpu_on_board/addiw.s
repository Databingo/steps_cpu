# RISC-V Assembly: Word-Immediate Instruction Test (addiw, slliw, srliw, sraiw)
# Goal: Verify the functionality of the 32-bit immediate operations.

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    li t0, 0x2004       # UART address

    # --- Test 1: ADDIW (32-bit overflow and sign-extension) ---
    # Load the max positive 32-bit integer.
    li t1, 0x7FFFFFFF
    # Add 1. This should overflow to the max negative 32-bit integer.
    addiw t1, t1, 1     # 32-bit result should be 0x80000000.
    # The 64-bit register should hold the sign-extended value.
    # Expected t1 = 0xFFFFFFFF_80000000.
    li t2, 0xFFFFFFFF80000000 # Load expected 64-bit value.
    bne t1, t2, fail

    # --- Test 2: SLLIW (32-bit shift left) ---
    li t1, 0x0000000F
    slliw t1, t1, 28    # 32-bit shift. Result should be 0xF0000000.
    # This is a negative 32-bit number, so it should be sign-extended.
    # Expected t1 = 0xFFFFFFFF_F0000000.
    li t2, 0xFFFFFFFFF0000000
    bne t1, t2, fail

    # --- Test 3: SRLIW (32-bit shift right LOGICAL) ---
    # Use the result from the previous test: 0xF0000000
    # We are shifting the 32-bit value t1[31:0].
    srliw t1, t1, 4     # Logical shift. Should fill with zeros.
    # 32-bit result should be 0x0F000000.
    # This is a positive 32-bit number, so it should be sign-extended with zeros.
    # Expected t1 = 0x00000000_0F000000.
    li t2, 0x0F000000
    bne t1, t2, fail

    # --- Test 4: SRAIW (32-bit shift right ARITHMETIC) ---
    # Use the same starting value: 0xF0000000
    li t1, 0xFFFFFFFFF0000000
    sraiw t1, t1, 4     # Arithmetic shift. Should fill with ones.
    # 32-bit result should be 0xFF000000.
    # This is a negative 32-bit number, so it should be sign-extended with ones.
    # Expected t1 = 0xFFFFFFFF_FF000000.
    li t2, 0xFFFFFFFFFF000000
    bne t1, t2, fail

    # If all tests pass...
pass:
    li t6, 80           # ASCII 'P'
    sd t6, 0(t0)
pass_loop:
    beq x0, x0, pass_loop

fail:
    li t6, 70           # ASCII 'F'
    sd t6, 0(t0)
    beq x0, x0, fail
