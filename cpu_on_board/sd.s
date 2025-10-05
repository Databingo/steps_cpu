# RISC-V Assembly: Sd 

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    # Get UART address (0x2004) into t0.
    lui t0, 0x2
    addi t0, t0, 4      # t0 = 0x2004

    # --- Test 1: Basic Shift ---
    # We expect t1 = 0x5373415050417353 SsAPPAsS
    lui  t1, 0x53734
    addi t1, t1, 0x150
    slli t1, t1, 8   
    addi t1, t1, 0x50 
    slli t1, t1, 8   
    addi t1, t1, 0x41 
    slli t1, t1, 8   
    addi t1, t1, 0x73 
    slli t1, t1, 8   
    addi t1, t1, 0x53 
   
    sd t1, -16(t0) # save
    lw t2, -16(t0) # load back low 4 bytes
    lw t3, -12(t0) # load back higt 4 bytes 

    
    srli t4, t2, 24 # P
    sb t4, 0(t0) 
    srli t4, t2, 16 # A
    sb t4, 0(t0)
    srli t4, t2, 8  # s
    sb t4, 0(t0)
    sb t2, 0(t0)    # S


    srli t4, t3, 24 # S
    sb t4, 0(t0) 
    srli t4, t3, 16 # s
    sb t4, 0(t0)
    srli t4, t3, 8  # A
    sb t4, 0(t0)
    sb t3, 0(t0)    # P
