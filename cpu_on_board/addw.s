# RISC-V Assembly: R-Type Word Instruction Test (addw, subw, sllw, srlw, sraw)
# Goal: Verify the functionality of the 32-bit register-register operations.

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    li t0, 0x2004       # UART address

    # --- Test 1: ADDW (32-bit overflow) ---
    # 0x7FFFFFFF + 1 should result in 0x80000000 (32-bit), which is
    # then sign-extended to 0xFFFFFFFF_80000000 (64-bit).
    li t1, 0x7FFFFFFF
    li t2, 1
    addw t3, t1, t2
    li t4, 0xFFFFFFFF80000000 # Expected 64-bit result
    bne t3, t4, fail

    # --- Test 2: SUBW (32-bit underflow) ---
    # 0x80000000 - 1 should result in 0x7FFFFFFF (32-bit), which is
    # then sign-extended to 0x00000000_7FFFFFFF (64-bit).
    li t1, 0xFFFFFFFF80000000
    li t2, 1
    subw t3, t1, t2
    li t4, 0x7FFFFFFF
    bne t3, t4, fail

    # --- Test 3: SLLW (Shift Left Word) ---
    # 0x0000000F << 28 should result in 0xF0000000 (32-bit), a negative number.
    # This must be sign-extended to 0xFFFFFFFF_F0000000 (64-bit).
    li t1, 0xF
    li t2, 28
    sllw t3, t1, t2
    li t4, 0xFFFFFFFFF0000000
    bne t3, t4, fail

    # --- Test 4: SRLW (Shift Right Logical Word) ---
    # We start with the 32-bit value 0xF0000000.
    li t1, 0xFFFFFFFFF0000000
    li t2, 4
    srlw t3, t1, t2     # Shift the 32-bit part logically.
    # 32-bit result: 0x0F000000 (positive).
    # This must be sign-extended (with zeros) to 0x00000000_0F000000.
    li t4, 0x0F000000
    bne t3, t4, fail

    # --- Test 5: SRAW (Shift Right Arithmetic Word) ---
    # Use the same starting value: 0xF0000000.
    li t1, 0xFFFFFFFFF0000000
    li t2, 4
    sraw t3, t1, t2     # Shift the 32-bit part arithmetically.
    # 32-bit result: 0xFF000000 (negative).
    # This must be sign-extended (with ones) to 0xFFFFFFFF_FF000000.
    li t4, 0xFFFFFFFFFF000000
    bne t3, t4, fail

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
