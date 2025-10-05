# RISC-V Assembly: 'slli' Test (Purest Version - No 'li')

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    # Get UART address (0x2004) into t0.
    lui t0, 0x2
    addi t0, t0, 4      # t0 = 0x2004

    # --- Test 1: Basic Shift ---
    # We expect t1 = 0x50417353 PAsS
    addi t1, x0, 0x50 
    slli t1, t1, 8   
    addi t1, t1, 0x41 
    slli t1, t1, 8   
    addi t1, t1, 0x73 
    slli t1, t1, 8   
    addi t1, t1, 0x53 

    
    srli t2, t1, 24 # P
    sb t2, 0(t0) 
    srli t2, t1, 16 # A
    sb t2, 0(t0)
    srli t2, t1, 8  # s
    sb t2, 0(t0)
    sb t1, 0(t0)    # S
