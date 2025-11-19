# Minimal SDRAM test
.section .text
.globl _start

_start:
    lui t0, 0x2
    addi t0, t0, 4       # UART = 0x2004
    
    lui s0, 0x10000      # SDRAM = 0x10000000
    
    # Write one byte
    li t1, 0x58          # 'X'
    sb t1, 0(s0)         # test sdram sb/sh
    
    # Read it back
    lb t2, 0(s0)         # test sdram lb
    
    # Print it
    sb t2, 0(t0)         # Should print 'X'
    sb t2, 0(t0)         # Should print 'X'
    sh t2, 0(t0)         # Should print 'X'
    
    # Write 4 byte
    li t1, 0x44434241    # 'DCBA'
    sw t1, 0(s0)         # test sdram sw
    
    # Read it back
    lh t3, 0(s0) # A    # test sdram lh lw
    lb t4, 1(s0) # B
    lw t5, 2(s0) # C
    lb t6, 3(s0) # D
    
    # Print it
    sb t3, 0(t0)         # Should print 'A'
    sb t4, 0(t0)         # Should print 'B'
    sb t5, 0(t0)         # Should print 'C'
    sb t6, 0(t0)         # Should print 'D'
    sb t2, 0(t0)         # Should print 'X'

    # Write 8 byte
    li t1, 0x4847464544434241         # 'HGFEDCBA'
    sd t1, 0(s0)         # test sdram sd

    # Read it back
    lb a0, 0(s0) # A
    lb a1, 1(s0) # B
    lb a2, 2(s0) # C
    lb a3, 3(s0) # D
    lb a4, 4(s0) # E
    lb a5, 5(s0) # F
    lb a6, 6(s0) # G
    lb a7, 7(s0) # H

    # Print it
    sb a0, 0(t0)         # Should print 'A'
    sb a1, 0(t0)         # Should print 'B'
    sb a2, 0(t0)         # Should print 'C'
    sb a3, 0(t0)         # Should print 'D'
    sb a4, 0(t0)         # Should print 'E'
    sb a5, 0(t0)         # Should print 'F'
    sb a6, 0(t0)         # Should print 'G'
    sb a7, 0(t0)         # Should print 'H'
    sb t2, 0(t0)         # Should print 'X'

    # Write one byte
    li t1, 0x4847464544434241         # 'HGFEDCBA'
    sd t1, 0(s0)         

    # Read it back       # test sdram ld
    ld a0, 0(s0)


    sb a0, 0(t0)         # Should print 'A'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'B'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'C'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'D'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'E'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'F'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'G'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'H'
    sb t2, 0(t0)         # Should print 'X'

    # Write one byte
    li t1, 0x41          # 'A'
    sb t1, 0(s0)         # test sdarm sb
    li t1, 0x42          # 'B'
    sb t1, 1(s0)         # test sdarm sb+1

    # Read it back       
    lb a0, 0(s0)         # test sdram ld
    sb a0, 0(t0)         # Should print 'A'
    lb a0, 1(s0)         # test sdram ld+1
    sb a0, 0(t0)         # Should print 'B'

done:
    j done
