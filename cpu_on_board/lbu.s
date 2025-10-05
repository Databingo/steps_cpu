# RISC-V Assembly: Lbu

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    # Get UART address (0x2004) into t0.
    lui t0, 0x2
    addi t0, t0, 4      # t0 = 0x2004

    # We expect t1 = 0xFFFFFFFFFFFFFFFF
    addi t1, x0, -1

    sb t1, -16(t0) # save 0xFF
    sh t1, -12(t0) # save 0xFFFF
    sw t1, -8(t0) # save  0xFFFFFFFF

    lbu t2, -16(t0) # load 0xFF
    srli t2, t2, 2  # be 0x3F ascii "?"
    sb t2, 0(t0) 
    
    lhu t2, -12(t0) # load 0xFFFF
    srli t2, t2, 10  # be 0x3F ascii  "?"
    sb t2, 0(t0) 

    lwu t2, -8(t0) # load 0xFFFFFFFF
    srli t2, t2, 26  # be 0x3F ascii  "?"
    sb t2, 0(t0) 
