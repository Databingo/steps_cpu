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
#sb      s4, 0(s1)       # write byte to UART register 
#jal     x1, loop

#你x0E4BDA0



#.section .text
#    addi a0, x0, 5
#    addi a0, a0, 1
#
#.section .data
#    .string "Hello, world!"
#



#.section .text
#.globl _start
#
## UART Base Addresses for QEMU (Adjust if different)
#.equ UART_BASE, 0x10000000       # Base address
#.equ UART_RX, UART_BASE + 0      # Receive register
#.equ UART_TX, UART_BASE + 0      # Transmit register
#.equ UART_LSR, UART_BASE + 5     # Line Status Register (LSR)
#
#_start:
#loop:
#    # Wait for data to be ready
#    lui s1, %hi(UART_LSR)        # Load UART_LSR upper 20 bits into s1
#    addi s1, s1, %lo(UART_LSR)   # Load lower 12 bits for UART_LSR
#wait_for_data:
#    lb s2, 0(s1)                 # Load LSR into s2
#    andi s2, s2, 1               # Mask out everything except the "data ready" bit
#    beqz s2, wait_for_data       # Loop until data is ready
#
#    # Load received byte
#    lui s1, %hi(UART_RX)         # Load UART_RX upper 20 bits into s1
#    addi s1, s1, %lo(UART_RX)    # Load lower 12 bits for UART_RX
#    lb s2, 0(s1)                 # Load received byte into s2
#
#    # Echo the byte back
#    lui s1, %hi(UART_TX)         # Load UART_TX upper 20 bits into s1
#    addi s1, s1, %lo(UART_TX)    # Load lower 12 bits for UART_TX
#    sb s2, 0(s1)                 # Write byte to UART TX
#
#lui     s1, 0x10000     # load upper 20 bits
#addi    s1, s1, 0x000   # load lower 12 bits
#addi    s4, x0, 0xE4    # load A 41
#sb      s4, 0(s1)       # write byte to UART register 
#addi    s4, x0, 0xBD  # load A
#sb      s4, 0(s1)       # write byte to UART register 
#addi    s4, x0, 0xA0  # load A
#sb      s4, 0(s1)       # write byte to UART register 
#    #jal x0, wait_for_data #loop                 # Loop to keep reading and echoing
#    jal x0, loop                 # Loop to keep reading and echoing




load_uart_addrs:
# UART  i/o register
lui     s1, 0x10000     # load upper 20 bits
addi    s1, s1, 0x000   # load lower 12 bits

load_lsr_addr:
# UART  line_status_register
lui     s2, 0x10000     # load upper 20 bits
addi    s2, s2, 0x005   # load lower 12 bits

test:
addi    s4, x0, 0xE4    # load A 41
sb      s4, 0(s1)       # write byte to UART register 
addi    s4, x0, 0xBD  # load A
sb      s4, 0(s1)       # write byte to UART register 
addi    s4, x0, 0xA0  # load A
sb      s4, 0(s1)       # write byte to UART register 

loop: 
lui     s2, 0x10000     # load upper 20 bits
addi    s2, s2, 0x005   # load lower 12 bits
wait:
lb      s3, 0(s2)       # load UART_LSR
andi    s3, s3, 1       # bitwise AND only left the "UART data ready" position as it is
beq     x0, s3, wait
lb s4, 0(s1)
sb s4, 0(s1) 
jal x0, loop

