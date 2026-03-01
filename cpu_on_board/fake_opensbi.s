# Print "I am opensbi"
.section .text
.globl _start

_start:
    lui t0, 0x2
    addi t0, t0, 4       # UART = 0x2004
    
    # Print one byte
    li t1, 0x58          # 'X'
    sb t1, 0(t0)         # test
    
    # Load 4 byte
    li t1, 0x49    # I
    sb t1, 0(t0)    
    li t1, 0x20    # space
    sb t1, 0(t0)   
    li t1, 0x61    # a
    sb t1, 0(t0)   
    li t1, 0x6d    # m
    sb t1, 0(t0)   
    li t1, 0x20    # space
    sb t1, 0(t0)   
    li t1, 0x6f    # o
    sb t1, 0(t0)   
    li t1, 0x70    # p
    sb t1, 0(t0)   
    li t1, 0x65    # e
    sb t1, 0(t0)   
    li t1, 0x6e    # n
    sb t1, 0(t0)   
    li t1, 0x73    # s
    sb t1, 0(t0)   
    li t1, 0x62    # b
    sb t1, 0(t0)   
    li t1, 0x69    # i
    sb t1, 0(t0)   
    
end_loop:
    j end_loop
