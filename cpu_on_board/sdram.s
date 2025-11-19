# Minimal SDRAM test
.section .text
.globl _start

_start:
    lui t0, 0x2
    addi t0, t0, 4       # UART = 0x2004
    
    lui s0, 0x10000      # SDRAM = 0x10000000
    
    # Write one byte
    li t1, 0x58          # 'X'
    sh t1, 0(s0)
    
    # Read it back
    lbu t2, 0(s0)
    
    # Print it
    sb t2, 0(t0)         # Should print 'X'
    sb t2, 0(t0)         # Should print 'X'
    sh t2, 0(t0)         # Should print 'X'
    
    # Write one byte
    li t1, 0x44434241         # 'DCBA'
    sw t1, 0(s0)         
    
    # Read it back
    lbu t3, 0(s0)
    lbu t4, 1(s0)
    lbu t5, 2(s0)
    lbu t6, 3(s0)
    
    # Print it
    sb t3, 0(t0)         # Should print 'A'
    sb t4, 1(t0)         # Should print 'B'
    sb t5, 2(t0)         # Should print 'C'
    sb t6, 3(t0)         # Should print 'D'
    sb t2, 0(t0)         # Should print 'X'
done:
    j done
