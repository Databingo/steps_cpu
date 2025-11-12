# RISC-V Assembly: Ld 

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    # Get UART address (0x2004) into t0.
    lui t0, 0x2
    addi t0, t0, 4      # t0 = 0x2004

    # --- Test 1: Basic Shift ---
    # We expect t1 = 0x5373415050417353 SsAPPAsS
   #lui  t1, 0x53734
   #addi t1, t1, 0x150
   #slli t1, t1, 8   
   #addi t1, t1, 0x50 
   #slli t1, t1, 8   
   #addi t1, t1, 0x41 
   #slli t1, t1, 8   
   #addi t1, t1, 0x73 
   #slli t1, t1, 8   
   #addi t1, t1, 0x53 

   
   #sd t1, -16(t0) # save
   #ld t2, -16(t0) # load back to t2

   #srli t4, t2, 24 # P
   #sb t4, 0(t0) 
   #srli t4, t2, 16 # A
   #sb t4, 0(t0)
   #srli t4, t2, 8  # s
   #sb t4, 0(t0)
   #sb t2, 0(t0)    # S


   #srli t4, t2, 56 # S
   #sb t4, 0(t0) 
   #srli t4, t2, 48 # s
   #sb t4, 0(t0)
   #srli t4, t2, 40  # A
   #sb t4, 0(t0)
   #srli t4, t2, 32  # P
   #sb t4, 0(t0)    

    li t1, 0x6162636465666768 #abcdefjh
    sd t1, -16(t0) # save
    addi t6, x0, 0

    lb t2, -16(t0) #  h load back to t2
    sb t2, 0(t0)    
    lb t2, -15(t0)  # j
    sb t2, 0(t0)    
    lb t2, -14(t0)  # f
    sb t2, 0(t0)    
    lb t2, -13(t0)  # e
    sb t2, 0(t0)    
    lb t2, -12(t0)  # d
    sb t2, 0(t0)    
    lb t2, -11(t0)  # c
    sb t2, 0(t0)    
    lb t2, -10(t0)  # b
    sb t2, 0(t0)    
    lb t2, -9(t0)  # a
    sb t2, 0(t0)    





