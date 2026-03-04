# Goal: Perform a series of ADDI tests and print "PASS!" to the UART.

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    # Get the UART address (0x2004) into t3.
    #    (Using a sequence of addi instructions as before)
    addi t0, x0, 2047
    addi t0, t0, 2047
    addi t0, t0, 2047
    addi t0, t0, 2047
    addi t0, t0, 8      # t3 = 8196 (0x2004)

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
    sb t1, 0(t0)        # Write 'P' to address 0x2004

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
    sb t1, 0(t0)        # Write 'A'
    
    # --- Test 6: Adding to a non-zero register ---
    # Expected result: t1 = 65 + 18 = 83. ASCII for 'S' is 83.
    addi t1, t1, 18
    # Verification Point 3: Print 'S'
    sb t1, 0(t0)       # Write 'S'
    
    # Verification Point 4: Print another 'S'
    sb t1, 0(t0)       # Write 'S'

    # --- Final Test: Create '!' ---
    # Expected result: t1 = 83 - 50 = 33. ASCII for '!' is 33.
    addi t1, t1, -50
    # Verification Point 5: Print '!'
    sb t1, 0(t0)       # Write '!'








