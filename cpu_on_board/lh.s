# Lw test

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    # Get the UART address (0x2004) into t3.
    #    (Using a sequence of addi instructions as before)
    lui t0, 0x2
    addi t0, t0, 4      # t0 = 8196 (0x2004)


    # --- Action Phase ---
    # Construct the test value 0x50417353 ('P' 'A' 's' 'S') in register t1. 'P' = 0x50, 'A' = 0x41, 'S' = 0x53.
    lui t1, 0x50417
    addi t1, t1, 0x353  # t1 = 0x50417353.

    sw t1, -16(t0)   # save t1 value to ram -16(t0) aligned
    addi t1, x0, 0   # clean t1 to 0
    lh t1, -16(t0)    # loab back low16 'sS'
    lh t6, -14(t0)    # loab back high16 'PA'


    # -- Print 'PA' --
    srli t4, t6, 8     
    sb t4, 0(t0)        # Print 'P' 
    sb t6, 0(t0)        # Print 'A'
    
    # -- Print 'sS' --
    srli t2, t1, 8      
    sb t2, 0(t0)        # Print 's'
    sb t1, 0(t0)        # Print 'S'
