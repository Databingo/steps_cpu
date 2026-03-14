#`define Sdc_base  32'h0000_3000 (3000-31ff 512 bytes index) sd_cache 
#`define Sdc_addr  32'h0000_3200
#`define Sdc_read  32'h0000_3204
#`define Sdc_write 32'h0000_3208
#`define Sdc_ready 32'h0000_3220
#`define Sdc_dirty 32'h0000_3224
#`define Sdc_avail 32'h0000_3228
# UART 0x2004

.globl _start

# -- Define data --
.section .data
msg:
    .string "Hello"
sbi:
    .string "I'm test Opensbi add update ram read=on1"
wait_sd_ready:
    .string "wait_sd_ready:"
read_sd_sector:
    .string "read_sd_sector:"

# -- Start program main function _start --
.section .text
# -- Global setup --
_start:
    #  a1 for print symbol addr
    li a0 0x2004 # UART print 

    li s0 0x3000 # SD base
    li s1 0x3200 # SD address
    li s2 0x3204 # SD trigger read
    li s3 0x3208 # SD trigger write
    li s4 0x3220 # SD ready for rd/wr
    li s5 0x3228 # SD cache available

    la a1, sbi  # a0 for print addr
    #jal fun_print_string
    call fun_print_string

    



# fake_opensbi  ------------------
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


# ---------------------- SD card -------------------

# UART base (for print_char)
lui t0, 0x2
addi t0, t0, 4      # t0 = 0x2004

# SD controller base
lui a1, 0x3         # a1 = 0x3000 base

li t1, 65        # A
sb t1, 0(t0)     # print
# -- Wait SD ready
sd_ready:
lw a2, 0x220(a1)    # a2 0x3220 ready
li t1, 0x60        # `
sb t1, 0(t0)     # print
beq a2, x0, sd_ready

# -- Read Boot Sector 0 -- 
li a2, 0
jal sd_read_sector

li t1, 65        # A
sw t1, 0(t0)     # print

jal print_sector

li t1, 124       # |
sb t1, 0(t0)     # print

# -- Parse BPB -- little-endian


# ---  sd_read_sector ---
sd_read_sector:
sw a2, 0x200(a1) # Write Sector index value to address 0x3200
li t1, 1
sw t1, 0x204(a1) # Trigger read at 0x3204
wait_ready:
lw t2, 0x220(a1)    # t2 0x3220 ready
beq t2, x0, wait_ready
wait_cache:
lw t2, 0x228(a1)    # t2 0x3228 cache_avaible
beq t2, x0, wait_cache

li t1, 70        # F
sw t1, 0(t0)     # print
ret



# print sector 0 512 bytes
print_sector:
li a5, 0x2008 # uart control
li t1, 0   # byte index
li t6, 511 # max byte index
print_loop:
#li a3, 32     # space 
#sw a3, 0(t0)  # print start space per byte
add a4, a1, t1 
addi t1, t1, 1
#lw t2, 0(a4)           # load byte at 0x3000 a1+t1
lb t2, 0(a4)           # load byte at 0x3000 a1+t1
andi t2, t2, 0xFF   # Isolate byte value
srli t3, t2, 4      # get high nibble
slti t5, t3, 10     # if < 10 number
beq t5, x0, letter_h
addi t3, t3, 48     # 0 is "0" ascii 48
j print_h_hex
letter_h:
addi t3, t3, 55     # 10 is "A" ascii 65 ..
print_h_hex:

wait_uart_tx_h:
lw t5, 0(a5)
srli t5, t5, 16   # 31:16 WSPACE = 0 full
beq t5, x0, wait_uart_tx_h

sw t3, 0(t0)
andi t4, t2, 0x0F      # get low nibble
slti t5, t4, 10     # if < 10 number
beq t5, x0, letter_l
addi t4, t4, 48     # 0 is "0" ascii 48
j print_l_hex
letter_l:
addi t4, t4, 55        # 10 is "A" ascii 65 ..
print_l_hex:

wait_uart_tx_l:
lw t5, 0(a5)
srli t5, t5, 16
beq t5, x0, wait_uart_tx_l

sw t4, 0(t0)
bge t6, t1, print_loop
ret
# -- end print_sector --


# funciton print_bin(a0) print 8 bits of a0 at t0 UART
print_bin_f:
li t1, 8 # number of bits
print_binf_loop:
addi t1, t1, -1
srl t2, a0, t1
andi t2, t2, 1
addi t2, t2, 48  # 0 to "0"
sw t2, 0(t0)     # print
bne t1, x0, print_binf_loop
# clean middle re
addi t1, x0, 0
addi t2, x0, 0
ret



# print_hex_b(t2)
print_hex_b:
andi t2, t2, 0xFF   # Isolate byte value

srli t3, t2, 4      # get high nibble
slti t5, t3, 10     # if < 10 number
beq t5, x0, letterh
addi t3, t3, 48     # 0 is "0" ascii 48
j print_hhex
letterh:
addi t3, t3, 55     # 10 is "A" ascii 65 ..
print_hhex:
sw t3, 0(t0)

andi t4, t2, 0x0F      # get low nibble
slti t5, t4, 10     # if < 10 number
beq t5, x0, letterl
addi t4, t4, 48     # 0 is "0" ascii 48
j print_lhex
letterl:
addi t4, t4, 55        # 10 is "A" ascii 65 ..
print_lhex:
sw t4, 0(t0)

# clean middle re
addi t3, x0, 0
addi t4, x0, 0
addi t5, x0, 0
ret


# functions ------
fun_print_string:
    li a0 0x2004 # UART print 
print:
    lb a1, 0(a1)
    beq a1, x0, stop_fun_print
    sb a1, 0(a0)
    addi a1, a1, 1
    j print
stop_fun_print:
    ret

