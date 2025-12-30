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
    lbu t2, 0(s0)         # test sdram lbu
    
    # Print it
    sb t2, 0(t0)         # Should print 'X'
    sb t2, 0(t0)         # Should print 'X'
    sh t2, 0(t0)         # Should print 'X'
    
    # Write 4 byte
    li t1, 0x44434241    # 'DCBA'
    sw t1, 0(s0)         # test sdram sw
    
    # Read it back
    lhu t3, 0(s0) # A    # test sdram lhu lwu
    lbu t4, 1(s0) # B
    lwu t5, 2(s0) # C
    lbu t6, 3(s0) # D
    
    # Print it
    sb t3, 0(t0)         # Should print 'A'
    sb t4, 0(t0)         # Should print 'B'
    sb t5, 0(t0)         # Should print 'C'
    sb t6, 0(t0)         # Should print 'D'
    sb t2, 0(t0)         # Should print 'X'

    ## MMU enabled
    #li a1, 8              
    #slli a1, a1, 60          # mmu mode sv39 #li a1, 0x8000000000000000 # mmu mode sv39
    #csrrw a3, satp, a1      # set satp csr index 0x180


    # Write 8 byte
    li t1, 0x4847464544434241         # 'HGFEDCBA'
    sd t1, 0(s0)         # test sdram sd

    # Read it back
    lbu a0, 0(s0) # A
    lbu a1, 1(s0) # B
    lbu a2, 2(s0) # C
    lbu a3, 3(s0) # D
    lbu a4, 4(s0) # E
    lbu a5, 5(s0) # F
    lbu a6, 6(s0) # G
    lbu a7, 7(s0) # H

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

    ## MMU enabled
    #li a1, 8              
    #slli a1, a1, 60          # mmu mode sv39 #li a1, 0x8000000000000000 # mmu mode sv39
    #csrrw a3, satp, a1      # set satp csr index 0x180

    li t3, 124 # |
    sb t3, 0(t0) # mmu settled

    # Write 4 byte
    li t1, 0x44434241    # 'DCBA'

    li t3, 58 # :
    sb t3, 0(t0) # start read sw to sdram

    sw t1, 0(s0)         # test sdram sw

    # Read it back
    lhu t3, 0(s0) # A    # test sdram lhu lwu
    lbu t4, 1(s0) # B
    lwu t5, 2(s0) # C
    lbu t6, 3(s0) # D
    
    # Print it
    sb t3, 0(t0)         # Should print 'A'
    sb t4, 0(t0)         # Should print 'B'
    sb t5, 0(t0)         # Should print 'C'
    sb t6, 0(t0)         # Should print 'D'
    sb t2, 0(t0)         # Should print 'X'


#wait_loop:
#    j wait_loop
#

    # Write 8 byte
    li t1, 0x4847464544434241         # 'HGFEDCBA'
    sd t1, 0(s0)         

    # Read it back
    lbu a0, 0(s0) # A
    lbu a1, 1(s0) # B
    lbu a2, 2(s0) # C
    lbu a3, 3(s0) # D
    lbu a4, 4(s0) # E
    lbu a5, 5(s0) # F
    lbu a6, 6(s0) # G
    lbu a7, 7(s0) # H

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


    ## MMU enabled
    #li a1, 8              
    #slli a1, a1, 60          # mmu mode sv39 #li a1, 0x8000000000000000 # mmu mode sv39
    #csrrw a3, satp, a1      # set satp csr index 0x180


    lb a0, 1(s0)         # test sdram ld+1
    sb a0, 0(t0)         # Should print 'B'
    
    ## MMU un-enabled
    #li a1, 0              
    #slli a1, a1, 60          # mmu mode sv39 #li a1, 0x8000000000000000 # mmu mode sv39
    #csrrw a3, satp, a1      # set satp csr index 0x180

    li t3, 124 # |
    sb t3, 0(t0) # to plic

    # -----PLIC TEST---
    li t0, 0x2004 # UART data

    # Enable UART read from terminal as irq
    li t1, 1
    sw t1, 4(t0) # write 1 to 0x2008 UART control means readable

    li t3, 48 # 0
    sb t3, 0(t0)

    # Set handler
    la t2, irq_handler
    csrw mtvec, t2

    li t3, 49 # 1
    sb t3, 0(t0)

    # PLIC setting
    # Set priority[1] = 1 # [1] is UART
    li t2, 0x0C000004 # `define Plic_base 32'h0C00_0000  # PRIORITY(id) = base + 4 * id
    li t3, 1
    sw t3, 0(t2)
   
    li t3, 50 # 2
    sb t3, 0(t0)

    # Set enable bits = irq_id, so enable bit = (1 << id) ctx 0
    li t2, 0x0C002000
    li t1, 2 #( 1<<1 = 2)
    sw t1, 0(t2)

    li t3, 51 # 3
    sb t3, 0(t0)

    ## Set enable bits = irq_id, so enable bit = (1 << id) ctx 1
    #li t2, 0x0C002080
    #li t1, 2 #( 1<<1 = 2)
    #sw t1, 0(t2)

    #li t3, 51 # 3
    #sb t3, 0(t0)

    # Set shreshold 0
    li t2, 0x0C200000  # base +0x200000+hard_id<<12
    li t1, 0 
    sw t1, 0(t2)

    li t3, 52 # 4
    sb t3, 0(t0)
  
    # Set shreshold 1
    li t2, 0x0C201000  # base +0x200000+hard_id<<12
    li t1, 0 
    sw t1, 0(t2)

    li t3, 53 # 5
    sb t3, 0(t0)

    # Enable MEIE (mie.MEIE enternal interrupt)
    li t2, 0x800 # bit 11=MEIE
    csrs mie, t2

    li t3, 54 # 6
    sb t3, 0(t0)

    # Enalbe MIE
    li t2, 8  # (bit 3 mstatus.MIE)
    csrs mstatus, t2

    li t3, 55 # 7
    sb t3, 0(t0) # to plic

wait_loop:
    j wait_loop

irq_handler:
   li t0, 0x2004 # UART data for print/read
   li t2, 0x0C200004  # PLIC Claim context 0 register

   li t3, 124 # |
   sb t3, 0(t0) # print |

   # Read claim
   lw t1, 0(t2)
   mv t5, t1

   beqz t1, exit_irq

   addi t4, t1, 48 
   sb t4, 0(t0) # show interrupt id
   li t3, 46 # .
   sb t3, 0(t0) 

   # Handle
   lw t3, 0(t0) # read from UART FIFO
   sw t3, 0(t0) # print key value

   sw t5, 0(t2) # write id back to ctx0claim to clear pending id
   li t3, 47 # /
   sb t3, 0(t0) #  finished

exit_irq:
   li t3, 69 # E
   sb t3, 0(t0) #  Exit irq
   mret 
