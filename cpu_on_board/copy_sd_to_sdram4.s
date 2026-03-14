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
prt_sector:
    .string "print_sector:"

# -- Start program main function _start --
.section .text
# -- Global setup --
_start:
    li a0 0x2004 # UART print # a1 for print symbol addr
    li a7 0x2008 # UART controller

    li s1 0x3000 # SD base
    li s2 0x3200 # SD address
    li s3 0x3204 # SD trigger read
    li s4 0x3208 # SD trigger write
    li s5 0x3220 # SD ready for rd/wr
    li s6 0x3228 # SD cache available

    # print
    la a1, sbi 
    call puts

# ---------------------- SD card -------------------

# -- Read Boot Sector 0 -- 
la a1, read_sd_sector 
call puts
li a2, 0   
jal sd_read_sector  # use a2 as sector no.

li t1, 124       # |
sb t1, 0(a0)     # print

la a1, prt_sector
call puts
call print_sector

li t1, 43       # +
sb t1, 0(a0)     # print
call wait_uart
li t1, 45       # -
sb t1, 0(a0)     # print

#end:
#    j end

# -- Parse BPB -- little-endian  Bios Parameter Block : sector 0
# reserved_sectors offset 0x0e-0x0f 2 bytes (including root sector 0)
addi t1, s1, 0x0E
lw t2, 0(t1)
andi t2, t2, 0xff

addi t1, s1, 0x0F 
lw t3, 0(t1)
andi t3, t3, 0xff

slli t3, t3, 8
or t2, t2, t3
mv a2, t2    # a2 = reserved_sectors offset 0x0e-0x0f 2 bytes (including root sector 0)

mv t2, a2
call print_hex_b

li a1, 126       # ~
call putchar

end:
    j end





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
sw t3, 0(a0)

andi t4, t2, 0x0F      # get low nibble
slti t5, t4, 10     # if < 10 number
beq t5, x0, letterl
addi t4, t4, 48     # 0 is "0" ascii 48
j print_lhex
letterl:
addi t4, t4, 55        # 10 is "A" ascii 65 ..
print_lhex:
sw t4, 0(a0)

ret






# --------------------  --------------------  --------------------


# ---  sd_read_sector ---
sd_read_sector: #  a2 sector index
sw a2, 0(s2) # Write Sector index value to address 0x3200
wait_ready:
lw t2, 0(s5)    # 0x3220 ready
#li t1, 96      # `
#sb t1, 0(a0)   # print
beq t2, x0, wait_ready

li t1, 1
sw t1, 0(s3) # Trigger read at 0x3204
wait_cache:
lw t2, 0(s6)    # t2 0x3228 cache_avaible
beq t2, x0, wait_cache
ret



# print sector 0 512 bytes
print_sector:
li t1, 0   # byte index
li t6, 511 # max byte index
print_loop:
add a4, s1, t1 
addi t1, t1, 1
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
lw t5, 0(a7)
srli t5, t5, 16   # 31:16 WSPACE = 0 full
beq t5, x0, wait_uart_tx_h

sw t3, 0(a0)
andi t4, t2, 0x0F      # get low nibble
slti t5, t4, 10     # if < 10 number
beq t5, x0, letter_l
addi t4, t4, 48     # 0 is "0" ascii 48
j print_l_hex
letter_l:
addi t4, t4, 55        # 10 is "A" ascii 65 ..
print_l_hex:

wait_uart_tx_l:
lw t5, 0(a7)
srli t5, t5, 16
beq t5, x0, wait_uart_tx_l

sw t4, 0(a0)
bge t6, t1, print_loop
ret
# -- end print_sector --




# funciton print_bin(a0) print 8 bits of a0 at a0 UART
print_bin_f:
li t1, 8 # number of bits
print_binf_loop:
addi t1, t1, -1
srl t2, a0, t1
andi t2, t2, 1
addi t2, t2, 48  # 0 to "0"
sw t2, 0(a0)     # print
bne t1, x0, print_binf_loop
# clean middle re
addi t1, x0, 0
addi t2, x0, 0
ret



# functions ------
puts: # a1
    lb a2, 0(a1)
    beq a2, x0, stop_puts # \x00 for end of string
    call putchar
    addi a1, a1, 1 # next byte
    j puts
stop_puts:
    ret

wait_uart:
    lw a6, 0(a7)
    srli a6, a6, 16   # 31:16 WSPACE = 0 fully
    beq a6, x0, wait_uart
    ret

putchar:  # a2
   lw t2, 0(a7)
   srli t2, t2, 16   # 31:16 WSPACE = 0 fully
   beq t2, x0, putchar
   sb a2, 0(a0)
   ret
