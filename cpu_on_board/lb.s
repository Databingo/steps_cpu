# RISC-V Assembly: 'lb' Test 
# Instructions used: lb (under test), addi, sb.

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
    
    addi t1, x0, 80
    sb t1, -16(t0)        # Store 80 P to address 0x2004-16.
    lb t2, -16(t0)        # Load 80 to t2
    sb t2, 0(t0)          # Print  

    addi t1, x0, 41
    sb t1, -15(t0)        # Store 41 A to address 0x2004-15.
    lb t2, -15(t0)        # Load 41 to t2
    sb t2, 0(t0)          # Print  
