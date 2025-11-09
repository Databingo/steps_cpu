# RISC-V Assembly: 'lb' Test 
# Instructions used: lb (under test), addi, sw.

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
    addi t0, t0, 8      # t0 = 8196 (0x2004)
    
    li t1, 0x53734150 # set t1 = SsAP
    sw t1, -16(t0)        # Store PAsS to address 0x2004-16.
    lh t2, -16(t0)        # Load P to t2
    sw t2, 0(t0)          # Print  

    lb t2, -15(t0)        # Load A to t2
    sw t2, 0(t0)          # Print  

    lhu t2, -14(t0)        # Load s to t2
    sw t2, 0(t0)          # Print  

    lbu t2, -13(t0)        # Load S to t2
    sw t2, 0(t0)          # Print  
