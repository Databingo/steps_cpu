# RISC-V Assembly: Minimal 'srli' Test (Corrected)
# Goal: Verify that 'srli' correctly performs a logical shift right.
# Instructions used: srli (under test), addi, sw, beq (trusted helpers).

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    # Get UART address (0x2004) into t0.
    addi t0, x0, 2047
    addi t0, t0, 2047
    addi t0, t0, 2047
    addi t0, t0, 2047
    addi t0, t0, 8      # t0 = 8196 (0x2004)
    
    # 1. Create the test value -2 in register t1.
    #    In 64 bits, this is 0xFF...FE
    addi t1, x0, -2
    
    # --- Action Phase: The Instruction Under Test (srli) ---

    # 2. Shift the value in t1 right by 60 bits.
    #    - The upper 4 bits of the original value (1111) will remain.
    #    - The new upper 60 bits MUST be filled with zeros.
    #    - Expected result in t1: 0x0000000F (decimal 15).
    srli t1, t1, 60
    
    # --- Verification Phase: Print the Result ---
    
    # 3. Adjust the result to a printable ASCII character.
    #    15 + 65 = 80 (ASCII for 'P')
    addi t1, t1, 65
    
    sw t1, 0(t0)        # This should print 'P'.
