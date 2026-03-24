.section .text
.globl _start

_start:
    # --- 1. Use your original BRAM stack ---
    li sp, 0x1800       # Stack is in 6KB BRAM (0x0000 - 0x17FF)
    
    # --- 2. Setup your original UART/SD addresses ---
    li s11, 0x2004      # UART Data
    li s10, 0x2008      # UART Status
    li s1,  0x3000      # SD base
    # ... (rest of your SD addresses)

    # --- 3. Pointer to SDRAM for the Atomic Test ---
    lui s0, 0x10000     # s0 = 0x1000_0000 (SDRAM)

    # =========================================================
    # ATOMIC TEST (On SDRAM)
    # =========================================================
    li t0, 10
    sw t0, 0(s0)        # memory[0x1000_0000] = 10

    # Test AMO (Atomic Add 5)
    li t0, 5
    amoadd.w t1, t0, (s0) 
    
    # Print 'Old' (Expect 0xA)
    mv a0, t1
    call print_reg      

    # Print 'New' (Expect 0xF)
    lw a0, 0(s0)
    call print_reg

    # Test SC.W Failure Case
    lr.w t2, (s0)       # Set reservation
    li t4, 99
    sw t4, 0(s0)        # Break reservation with normal store
    sc.w t3, t2, (s0)   # Attempt SC

    # Print Result (Expect 0x1 for failure)
    mv a0, t3
    call print_reg

    # =========================================================
    # START YOUR SD COPY LOGIC
    # =========================================================
    # Now continue with your existing code...
