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
# ADDI
# -------
# Limitation: imm is in -2048:2047
# Test 1 add number decimal positive 
#addi x31, x0, 1 
#addi x31, x0, 2 
#addi x31, x0, 3 
# Test 2 add number 0b positive 
#addi x31, x0, 0b1 
#addi x31, x0, 0b10
#addi x31, x0, 0b11 
# Test 3 add number 0x positive 
#addi x31, x0, 0x1 
#addi x31, x0, 0x2
#addi x31, x0, 0x3
# Test 4 add number decimal negative
#addi x31, x0, -1 
#addi x31, x0, -2 
#addi x31, x0, -3 
# Test 5 add number 0b negative
#addi x31, x0, -0b1 
#addi x31, x0, -0b10
#addi x31, x0, -0b11 
# Test 6 add number 0x negative
#addi x31, x0, -0x1 
#addi x31, x0, -0x2
#addi x31, x0, -0x3
# Test 7 add number 0x positive then turn to negative
#addi x30, x0, -0x1 
#addi x31, x0, -0x1 
#addi x31, x30, 0x2 
# Test 8 minimal and maximal number
#addi x31, x0,  0b11111111111 # maximal 2047
#addi x31, x0, -0b00000000000 # minimal -2048
# Test 9 0verflow 12 bits
#addi x31, x0,  0b111111111111 # overflow
#addi x31, x0, -0b111111111111 # overflow
# Test 10 add 0 as mv
#addi x30, x0, 0x05
#addi x31, x30, 0
# Test 11 pseduo li
#addi x31, x0, 0xB 
# Test 12 write to x0 for discard
#addi x0, x0, 0x2
#addi x31, x0, 0
#addi x31, x0, 2
#addi x0, x0, 0x2
#addi x31, x0, 3
# Test 13 NOP
#addi x0, x0, 0
# Test 14 maximal positive to minimal negative int64
#addi x31, x0,-1 
### x31 now is 0xffffffffffffffff # -1
#srli x31, x31, 1
### x31 now is 0x7fffffffffffffff # Max int64 +2**63-1 = 9,223,372,036,854,775,807
#addi x31, x31, 1
### x31 now is 0x8000000000000000 # Min int64 -2**63 = -9,223,372,036,854,775,808
#addi x31, x31, -1
### x31 now is 0x7fffffffffffffff # Max overflow 
#addi x31, x31, 2
### x31 now is 0x8000000000000001 
#addi x31, x31, -1
### x31 now is 0x8000000000000000 
# SRLI
# -------
# Limitation: shamt is in 0:63, padding always 0
# Test 1 basic positive number
#addi x31, x0, 0xf0
#srli x31, x31, 4
## Now  x31 is 0xf
# Test 1 basic negative number
#addi x31, x0, -1
#srli x31, x31, 1
#srli x31, x31, 3 # padding 0 at left ignore the 1 negative head number
# Test 2 shift 0
#addi x31, x0, -1
#srli x31, x31, 0
# Test 3 shift maximal shamt 63
addi x31, x0, -1
srli x31, x31, 63 






