# RISC-V Assembly: Comprehensive Branch Instruction Test
# Goal: Verify bne, blt, bge, bltu, bgeu.

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    li t0, 0x2004       # UART address

    # --- Test 1: BNE (Branch if Not Equal) ---
    # a) Branch NOT taken
    li t1, 100
    li t2, 100
    li t6, 49          # 1
    sd t6, 0(t0)
    bne t1, t2, fail    # Should NOT be taken.
    # b) Branch TAKEN
    li t2, 101
    li t6, 50
    sd t6, 0(t0)
    bne t1, t2, test_blt # Should BE taken, skipping the fail loop.
    j fail

test_blt:
    # --- Test 2: BLT (Branch if Less Than, SIGNED) ---
    li t1, -1           # A negative number
    li t2, 5            # A positive number
    # We expect (-1 < 5) to be TRUE.
    li t6, 51
    sd t6, 0(t0)
    blt t1, t2, test_bge # Should BE taken.
    j fail

test_bge:
    # --- Test 3: BGE (Branch if Greater/Equal, SIGNED) ---
    # We expect (5 >= -1) to be TRUE.
    li t6, 52
    sd t6, 0(t0)
    bge t2, t1, test_bltu # Should BE taken.
    j fail

test_bltu:
    # --- Test 4: BLTU (Branch if Less Than, UNSIGNED) ---
    # This is the critical test.
    # t1 holds -1 (0xFF...FF), t2 holds 5.
    # As unsigned numbers, 0xFF...FF is MUCH LARGER than 5.
    # So, (t1 < t2) unsigned should be FALSE.
    li t6, 53
    sd t6, 0(t0)
    bltu t1, t2, fail   # Should NOT be taken.
    # If we fall through, the test passed.

test_bgeu:
    # --- Test 5: BGEU (Branch if Greater/Equal, UNSIGNED) ---
    # We expect (t1 >= t2) unsigned to be TRUE.
    li t6, 54
    sd t6, 0(t0)
    bgeu t1, t2, all_tests_passed # Should BE taken.
    j fail


all_tests_passed:
    # If all tests succeed, print 'P'.
    li t6, 80           # ASCII 'P'
    sd t6, 0(t0)
    
pass_loop:
    beq x0, x0, pass_loop

fail:
    # You can optionally print a character here, e.g. 'F',
    # to know a failure occurred.
    li t6, 70           # ASCII 'F'
    sd t6, 0(t0)
    beq x0, x0, fail
