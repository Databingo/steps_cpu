# Lw test

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


    # --- Action Phase ---
    # Construct the test value 0x50415353 ('P' 'A' 'S' 'S') in register t1. 'P' = 0x50, 'A' = 0x41, 'S' = 0x53.
    lui t1, 0x50415
    addi t1, t1, 0x353  # t1 = 0x50415353.

    sw t1, -14(t0)   # save t1 value to ram -14(t0) unaligned
    addi t1, x0, 0   # clean t1 to 0
    lw t1, -14(t0)    # loab back the saved value from -14(t0) to t1


    # -- Print 'P' --
    srli t2, t1, 24     # Isolate 'P' (0x50)
    sb t2, 0(t0)        # Print 'P'
    
    # -- Print 'A' --
    srli t3, t1, 16     # Isolate 'A' (0x41)
    sb t3, 0(t0)        # Print 'A'
    
    # -- Print 'S' --
    srli t4, t1, 8      # Isolate 'S' (0x53)
    sb t4, 0(t0)        # Print 'S'
    
    # -- Print final 'S' --
    sb t1, 0(t0)        # Print the lowest byte 'S'
