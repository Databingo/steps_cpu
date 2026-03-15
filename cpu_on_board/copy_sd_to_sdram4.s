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
reserved_sec:
    .word 0
num_fats:
    .word 0
sec_per_fat:
    .word 0

# -- Start program main function _start --
.section .text
# -- Global setup --
_start:
    li sp, 0x1000 # Set stack
    # a0 for function call default parameter

    li s11, 0x2004 # UART print 
    li s10, 0x2008 # UART controller

    li s1, 0x3000 # SD base
    li s2, 0x3200 # SD address
    li s3, 0x3204 # SD trigger read
    li s4, 0x3208 # SD trigger write
    li s5, 0x3220 # SD ready for rd/wr
    li s6, 0x3228 # SD cache available

    # print
    la a0, sbi 
    call puts

# ---------------------- SD card -------------------
la a0, read_sd_sector 
call puts
li a0, 0   
call sd_read_sector  # use a2 as sector no.

li t1, 124       # |
sb t1, 0(s11)     # print

la a0, prt_sector
call puts
call print_sector

li a0, 43       # +
call putchar
li a0, 45       # -
call putchar

# -- Parse BPB -- little-endian  Bios Parameter Block : sector 0
# reserved_sectors offset 0x0e-0x0f 2 bytes (including root sector 0)
#addi t1, s1, 0x0E
#lw t2, 0(t1)
#andi t2, t2, 0xff
#
#addi t1, s1, 0x0F 
#lw t3, 0(t1)
#andi t3, t3, 0xff
#
#slli t3, t3, 8
#or t2, t2, t3
#mv a2, t2    # a2 = reserved_sectors offset 0x0e-0x0f 2 bytes (including root sector 0)


lbu a0, 0x0f(s1)
call print_hex_b
lbu a0, 0x0e(s1)
call print_hex_b

li a0, 126       # ~
call putchar

la t0, reserved_sec
lw a0, 0(t0)
call print_hex_b

# root_dir_sector_start = reserved_sectors + (num_fats * sectors_per_fat16)

# reserved_sectors offset 0x0e-0x0f 2 bytes (including root sector 0)
li t0, "resSec:" # 7 char left on for null
addi sp, sp, -8
sd t0, 0(sp)
mv a0, sp
call puts
addi sp, sp, 8

la a1, reserved_sec
lbu a0, 0x0e(s1)
mv a2, a0
call print_hex_b
lbu a0, 0x0f(s1)
mv a3, a0
call print_hex_b

slli a3, a3, 8
and a4, a3, a2
srli  a0, a4, 0
call print_hex_b
srli a0, a4, 8
call print_hex_b

xend:
    j xend

slli t1, t1, 8
or a0, t1, t0

sh a0, 0(a1)
lb a0, 1(a1)
call print_hex_b
lb a0, 0(a1)
call print_hex_b

# num_fats offset 0x10 1 bytes
li t0, "numFat:" # 7 char left on for null
addi sp, sp, -8
sd t0, 0(sp)
mv a0, sp
call puts
addi sp, sp, 8

la a1, num_fats
lbu a0, 0x10(s1)
sw a0, 0(a1)
lw a0, 0(a1)
call print_hex_b

# sectors_per_fat16 high offset 0x16-0x17 2 bytes
li t0, "secPfat" # 7 char left on for null
addi sp, sp, -8
sd t0, 0(sp)
mv a0, sp
call puts
addi sp, sp, 8

la a1, sec_per_fat

lbu t0, 0x16(s1)
lbu t1, 0x17(s1)
slli t1, t1, 8
or a0, t1, t0

sh a0, 0(a1)
lb a0, 0(a1)
call print_hex_b
lb a0, 1(a1)
call print_hex_b

end:
    j end



# -- function --
print_hex_b:  # a0
    andi a0, a0, 0xFF   # Isolate byte value
    
    srli t3, a0, 4      # get high nibble
    slti t5, t3, 10     # if < 10 number
    beq t5, x0, letterh
    addi t3, t3, 48     # 0 is "0" ascii 48
    j print_hhex
letterh:
    addi t3, t3, 55     # 10 is "A" ascii 65 ..
print_hhex:
    mv t0, ra
    call wait_uart
    mv ra, t0
    sb t3, 0(s11)
    
    andi t4, a0, 0x0F      # get low nibble
    slti t5, t4, 10     # if < 10 number
    beq t5, x0, letterl
    addi t4, t4, 48     # 0 is "0" ascii 48
    j print_lhex
letterl:
    addi t4, t4, 55        # 10 is "A" ascii 65 ..
print_lhex:
    mv t0, ra
    call wait_uart
    mv ra, t0
    sb t4, 0(s11)
    ret


# ---  sd_read_sector ---
sd_read_sector:  #  a0 sector index
    sw a0, 0(s2) # Write Sector index value to address 0x3200
wait_ready:
    lw t2, 0(s5)   # 0x3220 ready
    li a0, 96      # `
    mv t0, ra
    call putchar
    mv ra, t0
    beq t2, x0, wait_ready
    li t1, 1
    sw t1, 0(s3)   # Trigger read at 0x3204
wait_cache:
    lw t2, 0(s6)   # t2 0x3228 cache_avaible
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
    lw t5, 0(s10)
    srli t5, t5, 16   # 31:16 WSPACE = 0 full
    beq t5, x0, wait_uart_tx_h
    
    sb t3, 0(s11)
    andi t4, t2, 0x0F      # get low nibble
    slti t5, t4, 10     # if < 10 number
    beq t5, x0, letter_l
    addi t4, t4, 48     # 0 is "0" ascii 48
    j print_l_hex
letter_l:
    addi t4, t4, 55        # 10 is "A" ascii 65 ..
print_l_hex:
wait_uart_tx_l:
    lw t5, 0(s10)
    srli t5, t5, 16
    beq t5, x0, wait_uart_tx_l
    
    sb t4, 0(s11)
    bge t6, t1, print_loop
    ret
# -- end print_sector --




# funciton print_bin(s11) print 8 bits of s11 at s11 UART
print_bin_f:
li t1, 8 # number of bits
print_binf_loop:
addi t1, t1, -1
srl t2, s11, t1
andi t2, t2, 1
addi t2, t2, 48  # 0 to "0"
sb t2, 0(s11)     # print
bne t1, x0, print_binf_loop
# clean middle re
addi t1, x0, 0
addi t2, x0, 0
ret



# functions ------

putchar:  # a0
   lw t2, 0(s10)
   srli t2, t2, 16   # 31:16 WSPACE = 0 fully
   beq t2, x0, putchar
   sb a0, 0(s11)
   ret


puts: # a0 addr
    addi sp, sp, -16
    sd ra, 0(sp)
    sd a0, 8(sp)
    mv t1, a0
puts_loop:
    lb a0, 0(t1)
    beq a0, x0, stop_puts # \x00 for end of string
    call putchar # a0 char
    addi t1, t1, 1 # next byte
    j puts_loop
stop_puts:
    ld ra, 0(sp)
    ld a0, 8(sp)
    addi sp, sp, 16
    ret

wait_uart:
    lw a6, 0(s10)
    srli a6, a6, 16   # 31:16 WSPACE = 0 fully
    beq a6, x0, wait_uart
    ret

