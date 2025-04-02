#.section .text # .text .data .bss .rodata .test.unlikely .mydata .text.debug .init .fini
## .data .byte .word .half .asciz .ascii .string .float .double .align .skip .set 

#.section .text
#    addi a0, x0, 5
#    addi a0, a0, 1
#
#.section .data
#    .string "Hello, world!"


#load_uart_addrs: # UART 每次传输一个字节, 根据 16550 UART 标准 THR 偏移量为 0，LSR 偏移量为 5
## UART  Transmit Holding Register|i/o register # UART 数据寄存器 THR s1
#lui     s1, 0x10000     # load upper 20 bits
#addi    s1, s1, 0x000   # load lower 12 bits
#
#load_lsr_addr:  
## UART  line_status_register # UART 行状态寄存器 LSR s2
#lui     s2, 0x10000     # load upper 20 bits
#addi    s2, s2, 0x005   # load lower 12 bits
#
## 0xE4BDA0 你
#test:
#addi    s4, x0, 0xE4    # load 
#sb      s4, 0(s1)       # write byte to UART register 
#addi    s4, x0, 0xBD  # load
#sb      s4, 0(s1)       # write byte to UART register 
#addi    s4, x0, 0xA0  # load 
#sb      s4, 0(s1)       # write byte to UART register 
#
## keystroke
#loop: 
#lb      s3, 0(s2)       # load UART_LSR
#andi    s3, s3, 1       # bitwise AND 1 only left the "UART data ready" position as it is
#beq     x0, s3, loop    # if DR is 0, keep loop for waiting
#lb s4, 0(s1)            # read byte from THR
#sb s4, 0(s1)            # write byte back to THR for stdio to output
##addi    s4, x0, 0x41  # load A
##sb      s4, 0(s1)       # write byte to UART register 
##bltu    x0, s3, loop     # if DR is 1 then s3 > 0 then jump to loop for waiting new keystroke
##jal x0, loop # jal to loop
#addi x30, x0, 111
#addi x31, x30, 666
#addi x31, x31, 1

# Test Instruction
# ADDI  |imm.12|rs1.5|000.3|rd.5|0010011.7|  add sign-extend imm.12 to sr1, send overflow ingnored result to rd
# add positive number decimal
#addi x31, x0, 1 
#addi x31, x0, 2 
#addi x31, x0, 3 
# add positive number 0b
#addi x31, x0, 0b1 
#addi x31, x0, 0b10
#addi x31, x0, 0b11 
# add positive number 0x
#addi x31, x0, 0x1 
#addi x31, x0, 0x2
#addi x31, x0, 0x3
# add positive number decimal negetive
addi x31, x0, -1 
addi x31, x0, -2 
addi x31, x0, -3 

#addi x31, x0, 0b011111111111
#addi x31, x0, 0b111111111111
#addi x31, x0, -1
#addi x31, x0, -2
#addi x31, x0, 2
#addi x31, x0, 0b01
#addi x30, x0, -2
#addi x31, x30, 3
# Load
#lui  x31, 0x10000     # load upper 20 bits










