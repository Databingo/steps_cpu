# Goal: Perform a series of ADDI tests and print "PASS!" to the UART.

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    # We will use t0 as our UART base address pointer.
    # We construct the base address 0x2000 using only ADDI.
    addi t0, x0, 2047   # t0 = 2047
    addi t0, t0, 2047   # t0 = 4094
    addi t0, t0, 2047   # t0 = 6141
    addi t0, t0, 2047   # t0 = 8188 (0x1FFC)
    addi t0, t0, 4      # t0 = 8192 (0x2000). UART base address is ready.

    # We will use t1 as our test register.
    addi t1, x0, 0      # Start with t1 = 0.

    # --- Test 1: Basic Positive Immediate ---
    # Expected result: t1 = 100
    addi t1, t1, 100

    # --- Test 2: Chaining and Zero Immediate ---
    # Expected result: t1 = 100 (no change)
    addi t1, t1, 0
    
    # --- Test 3: Basic Negative Immediate (Subtraction) ---
    # Expected result: t1 = 100 - 20 = 80
    addi t1, t1, -20

    # At this point, t1 should hold 80. The ASCII for 'P' is 80.
    # Verification Point 1: Print 'P'
    sd t1, 4(t0)        # Write 'P' to address 0x2004
    addi t6, t6, 0
    sd t1, 4(t0)        # Write 'P' to address 0x2004

    # --- Test 4: Large Positive Immediate ---
    # Expected result: t1 = 80 + 2047 = 2127
    addi t1, t1, 2047
    
    # --- Test 5: Large Negative Immediate ---
    # This will test the sign extension of the 12-bit immediate.
    # Expected result: t1 = 2127 + (-2048) = 80 - 1 = 79
    addi t1, t1, -2048
    
    # Expected result: t1 = 79 - 14 = 65. ASCII for 'A' is 65.
    addi t1, t1, -14
    # Verification Point 2: Print 'A'
    sd t1, 4(t0)        # Write 'A'
    
    # --- Test 6: Adding to a non-zero register ---
    # Expected result: t1 = 65 + 18 = 83. ASCII for 'S' is 83.
    addi t1, t1, 18
    # Verification Point 3: Print 'S'
    sd t1, 4(t0)       # Write 'S'
    
    # Verification Point 4: Print another 'S'
    sd t1, 4(t0)       # Write 'S'

    # --- Final Test: Create '!' ---
    # Expected result: t1 = 83 - 50 = 33. ASCII for '!' is 33.
    addi t1, t1, -50
    # Verification Point 5: Print '!'
    sd t1, 4(t0)       # Write '!'
