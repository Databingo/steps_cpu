#.section .text # .text .data .bss .rodata .test.unlikely .mydata .text.debug .init .fini
## .data .byte .word .half .asciz .ascii .string .float .double .align .skip .set 

#.section .text
#    addi a0, x0, 5
#    addi a0, a0, 1
#
#.section .data
#    .string "Hello, world!"


load_uart_addrs:
# UART  i/o register
lui     s1, 0x10000     # load upper 20 bits
addi    s1, s1, 0x000   # load lower 12 bits

load_lsr_addr:
# UART  line_status_register
lui     s2, 0x10000     # load upper 20 bits
addi    s2, s2, 0x005   # load lower 12 bits

test:
addi    s4, x0, 0xE4    # load
sb      s4, 0(s1)       # write byte to UART register 
addi    s4, x0, 0xBD  # load 
sb      s4, 0(s1)       # write byte to UART register 
addi    s4, x0, 0xA0  # load 
sb      s4, 0(s1)       # write byte to UART register 

loop: 
lb      s3, 0(s2)       # load UART_LSR
andi    s3, s3, 1       # bitwise AND only left the "UART data ready" position as it is
beq     x0, s3, loop
lb s4, 0(s1)
sb s4, 0(s1) 
#addi    s4, x0, 0x41  # load A
#sb      s4, 0(s1)       # write byte to UART register 
bltu    x0, s3, loop
#jal x0, loop # jal to 2440 ? bug?

