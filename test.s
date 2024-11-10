#.section .text # .text .data .bss .rodata .test.unlikely .mydata .text.debug .init .fini
## .data .byte .word .half .asciz .ascii .string .float .double .align .skip .set 
#addi x1, x0, 1
#addi x2, x0, 8
#add  x6, x0, x0 # 0
#add  x5, x2, x0 # 加数
#add  x3, x2, x0 # 8
#add  x4, x3, x0 # 8
#loop1: sub  x3, x3, x1 # loop 1
#sub  x4, x3, x0 # loop 2
#loop2: 
#sub  x4, x4, x1
#add  x6, x6, x5 
#blt  x0, x4, loop2
#add  x5, x6, x0 # 加数
#add  x2, x6, x0 # 结果
#add  x6, x0, x0 # 0
#blt  x1, x3, loop1



#.section .text
#    addi a0, x0, 5
#    addi a0, a0, 1
#
#.section .data
#    .string "Hello, world!"



#lui     s1, 0x10000     # load upper 20 bits
#addi    s1, s1, 0x000   # load lower 12 bits
#addi    s4, x0, 0xE4    # load A 41
#sb      s4, 0(s1)       # write byte to UART register 
#addi    s4, x0, 0xBD  # load A
#sb      s4, 0(s1)       # write byte to UART register 
#addi    s4, x0, 0xA0  # load A
#sb      s4, 0(s1)       # write byte to UART register 
#
#loop: 
#lui     s2, 0x10000     # load upper 20 bits
#addi    s2, s2, 0x004   # load lower 12 bits
#lb      s4, 0(s2)       # load received byte to s4
#sb      s4, 0(s1)       # write byte to UART register 
#jal     x0, loop

#你x0E4BDA0
#_start:
#    # Initialize UART output
#    lui s1, 0x10000             # Load UART base address upper bits into s1
#    addi s1, s1, 0x000          # Load lower bits for UART RX address
#
#    # Send three characters: 0xE4, 0xBD, 0xA0
#    addi s4, x0, 0xE4           # Load 0xE4 into s4
#    sb s4, 0(s1)                # Write byte to UART transmit register
#    addi s4, x0, 0xBD           # Load 0xBD into s4
#    sb s4, 0(s1)                # Write byte to UART transmit register
#    addi s4, x0, 0xA0           # Load 0xA0 into s4
#    sb s4, 0(s1)                # Write byte to UART transmit register
#
#loop:
#    # Wait until data is ready in the receive register
#    lui s2, 0x10000             # Load UART base address upper bits into s2
#    addi s2, s2, 0x000          # Load lower bits for UART RX address
#
#    lb s4, 0(s2)                # Load received byte into s4
#
#    lui s1, 0x10000             # Load UART base address upper bits into s1
#    addi s1, s1, 0x000          # Load lower bits for UART RX address
#
#    sb s4, 0(s1)                # Echo byte back to UART transmit register
#
#    jal x0, loop                # Jump to 'loop' (infinite loop without return)

loop:
    # Poll the UART receive register for data
    lui s1,   0x10000        # Load UART RX register upper 20 bits into s1
    addi s1, s1, 0x000     # Load lower 12 bits for UART RX register

    lb s2, 0(s1)                 # Load received byte into s2 (assume any byte means data available)
    
    # Echo the received byte to the UART transmit register
    lui s1, 0x10000         # Load UART TX register upper 20 bits into s1
    addi s1, s1, 0x000    # Load lower 12 bits for UART TX register
    sb s2, 0(s1)                 # Write byte to UART transmit register

    # Repeat the loop
    jal x0, loop                 # Infinite loop
