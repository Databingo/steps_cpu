#`define Sdc_base  32'h0000_3000 (3000-31ff 512 bytes index) sd_cache 
#`define Sdc_addr  32'h0000_3200
#`define Sdc_read  32'h0000_3204
#`define Sdc_write 32'h0000_3208
#`define Sdc_ready 32'h0000_3220
#`define Sdc_dirty 32'h0000_3224
#`define Sdc_avail 32'h0000_3228
# UART 0x2004

.section .text
.globl _start
_start:
    la a0, sbi  # a0 for print addr
    jal fun_print_string

# ---------------------- SD card -------------------
# -- Wait SD ready --
la a0, wait_sd_ready
jal fun_print_string
lui a1, 0x3         # a1 = 0x3000 SD controller base
sd_ready:
lw a2, 0x220(a1)    # a2 0x3220 SD ready map
li t1, 0x60        # `
sb t1, 0(t0)       # print
beq a2, x0, sd_ready

# -- Read Boot Sector 0 -- 
la a0, read_sd_sector
jal fun_print_string
li a2, 0         # sector 0
jal sd_read_sector
jal print_sector
end:
    j end







# functions ------
fun_print_string:
    li t1, 0x2004
print:
    lb a1, 0(a0)
    beq a1, x0, stop_fun_print
    sb a1, 0(t1)
    addi a0, a0, 1
    j print
stop_fun_print:
    ret

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
li t0, 0x2004 # uart data
sw t1, 0(t0)     # print
ret

# --- print sector x 512 bytes ---
print_sector:
li t0, 0x2004 # uart data
li a5, 0x2008 # uart control
li t1, 0   # counter byte index
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




.section .data
msg:
    .string "Hello"
sbi:
    .string "I'm test Opensbi"

wait_sd_ready:
    .string "wait_sd_ready\n"
read_sd_sector:
    .string "read_sd_sector\n"
