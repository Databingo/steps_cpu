# RISC-V Assembly: True Minimal 'lw' Test
# Goal: Write 'P' to RAM, load it back with 'lw', and print the result to UART.
# Instructions used: ONLY addi, sw, lw.

.section .text
.globl _start

_start:
    # --- Setup Phase (using only ADDI) ---

    # 1. Get the RAM address into t0.
    addi t0, x0, 2047
    addi t0, t0, 2047
    addi t0, t0, 2047
    
    # 2. Get the test character 'P' (ASCII 86) into t1.
    addi t1, x0, 80
    
    # --- Write to RAM (using trusted SD) ---
    # Store 'P' at t0
    sw t1, 0(t0)
    
    # --- Action Phase: The Instruction Under Test (LD) ---
    
    # 3. Clear the destination register t2 to ensure we're not seeing a stale value.
    addi t2, x0, 0
    
    # 4. Load the value 
    #    If 'lw' works, t2 shoulw now contain 86.
    lw t2, 0(t0)
    
    # --- Verification Phase: Print the Result ---
    
    # 5. Get the UART address (0x2004) into t3.
    #    (Using a sequence of addi instructions as before)
    addi t3, x0, 2047
    addi t3, t3, 2047
    addi t3, t3, 2047
    addi t3, t3, 2047
    addi t3, t3, 8      # t3 = 8196 (0x2004)
    
    # 6. Store the value we loaded from RAM (now in t2) to the UART.
    sw t2, 0(t3)
