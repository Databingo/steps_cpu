#.global _start

#_start:
#    
#    # run only one instance
#   #csrr    t0, mhartid # 0xF14
#    csrrs   t0, mhartid, x0
#   #bnez    t0, forever
#    bne     t0, x0, forever
#    
#    # prepare for the loop
#   #li      s1, 0x10000000  # UART output register NS16550A  # conventional of QEMU
#    lui     s1, 0x10000     # load upper 20 bits
#    addi    s1, s1, 0x000   # load lower 12 bits
#    la      s2, hello       # load string start addr into s2
#    addi    s3, s2, 13      # set up string end addr in s3
#
#loop:
#    lb      s4, 0(s2)       # load next byte at s2 into s4
#    sb      s4, 0(s1)       # write byte to UART register 
#    addi    s2, s2, 1       # increase s2
#    blt     s2, s3, loop    # branch back until end addr (s3) reached
#
#forever:
#    wfi
#    j       forever
#
#
#.section .data
#
#hello:
#  #.string "hello world!\n"
#  .string "你好世界!\n"
#  

addi    s4, x0, 0x41    # load A
lui     s1, 0x10000     # load upper 20 bits
addi    s1, s1, 0x000   # load lower 12 bits
sb      s4, 0(s1)       # write byte to UART register 

#.section .text
#    addi a0, x0, 5
#    addi a0, a0, 1
#
#.section .data
#    .string "Hello, world!"
#
