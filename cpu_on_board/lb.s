# RISC-V Assembly: 'lb' (Load Byte) Alignment and Sign-Extension Test
# Goal: Verify that 'lb' works correctly for all four byte offsets within a word.

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    li t0, 0x1000       # RAM base address for our test data
    li t5, 0x2004       # UART address

    # 1. Construct and store our 32-bit test pattern: 0x807F108A
    li t1, 0x807F108A
    sw t1, 0(t0)        # Use 'sw' to store the 32-bit word.
    
    # --- Test Phase ---

    # --- Test 1: Load from offset 0 (Byte value 0x8A -> -118) ---
    lb t2, 0(t0)
    li t3, -118
    bne t2, t3, fail

    # --- Test 2: Load from offset 1 (Byte value 0x10 -> 16) ---
    lb t2, 1(t0)
    li t3, 16
    bne t2, t3, fail

    # --- Test 3: Load from offset 2 (Byte value 0x7F -> 127) ---
    lb t2, 2(t0)
    li t3, 127
    bne t2, t3, fail

    # --- Test 4: Load from offset 3 (Byte value 0x80 -> -128) ---
    lb t2, 3(t0)
    li t3, -128
    bne t2, t3, fail

    # If we get here, all four alignment tests passed.
pass:
    li t6, 80           # ASCII 'P'
    sd t6, 0(t5)
pass_loop:
    beq x0, x0, pass_loop

fail:
    # Optional: Print 'F' to know that a failure occurred.
    li t6, 70
    sd t6, 0(t5)
fail_loop:
    beq x0, x0, fail_loop

