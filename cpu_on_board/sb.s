# RISC-V Assembly: 'sb' (Store Byte) Alignment Test
# Goal: Verify that 'sb' correctly modifies each of the four byte positions within a word.

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    li t0, 0x1000       # RAM base address for our test data
    li t5, 0x2004       # UART address

    # 1. Construct and store a background pattern: 0xCCCCCCCC
    li t1, 0xCCCCCCCC
    sw t1, 0(t0)        # Write the background pattern to address 0x1000.
    
    # --- Action Phase: Test each byte position ---

    # --- Test 1: Store to offset 0 ---
    # Memory should become: 0xCCCCCC11
    li t1, 0x11
    sb t1, 0(t0)

    # --- Test 2: Store to offset 1 ---
    # Memory should become: 0xCCCC2211
    li t1, 0x22
    sb t1, 1(t0)

    # --- Test 3: Store to offset 2 ---
    # Memory should become: 0xCC332211
    li t1, 0x33
    sb t1, 2(t0)
    
    # --- Test 4: Store to offset 3 ---
    # Memory should become: 0x44332211
    li t1, 0x44
    sb t1, 3(t0)

    # --- Verification Phase ---
    
    # 1. Load the entire modified word back from memory.
    lw t2, 0(t0)
    
    # 2. Manually construct the final expected value: 0x44332211
    li t3, 0x44332211
    
    # 3. Compare the loaded word (t2) with the expected value (t3).
    beq t2, t3, pass

fail:
    # If the values are not equal, the program gets stuck here.
    # This means one of the 'sb' operations corrupted an adjacent byte
    # or failed to write to the correct position.
    li t6, 70           # ASCII 'F'
    sw t6, 0(t5)
    sw t2, 0(t5)        # lowest byte of t2
    beq x0, x0, fail

pass:
    # If the values are equal, all tests succeeded. Print 'P'.
    li t6, 80           # ASCII 'P'
    sd t6, 0(t5)
pass_loop:
    beq x0, x0, pass_loop
