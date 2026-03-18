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
byte_per_sec:
    .word 0
root_dir_sector_start:
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

   ## print
   #la a0, sbi 
   #call puts

# ---------------------- SD card -------------------
la a0, read_sd_sector 
call puts
li a0, 0   
call sd_read_sector  # use a2 as sector no.

la a0, prt_sector
call puts
call print_sector

li a0, 43       # +
call putchar

# -- Parse BPB -- little-endian  Bios Parameter Block : sector 0
# reserved_sectors offset 0x0e-0x0f 2 bytes (including root sector 0)
li t0, "resSec:" # 7 char left on for null
addi sp, sp, -8
sd t0, 0(sp)
mv a0, sp
call puts
addi sp, sp, 8

la a1, reserved_sec
lbu t0, 0x0e(s1)
lbu t1, 0x0f(s1)
slli t1, t1, 8
or a0, t1, t0 

sd a0, 0(a1)
ld a0, 0(a1)
call print_reg
# -------------------------------------
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
call print_reg

# -------------------------------------
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
lh a0, 0(a1)
call print_reg

# -------------------------------------
# byte_per_sec offset 0x0b-0x0c 2 bytes
li t0, "bysPsec" # 7 char left on for null
addi sp, sp, -8
sd t0, 0(sp)
mv a0, sp
call puts
addi sp, sp, 8

la a1, byte_per_sec
lbu t0, 0x0b(s1)
lbu t1, 0x0c(s1)
slli t1, t1, 8
or a0, t1, t0 

sh a0, 0(a1)
lh a0, 0(a1)
call print_reg


# -------------------------------------
# root_dir_sector_start = reserved_sectors + (num_fats * sectors_per_fat16)
li t0, "rootdS0" # 7 char left on for null
addi sp, sp, -8
sd t0, 0(sp)
mv a0, sp
call puts
addi sp, sp, 8

la a1, num_fats
lw t1, 0(a1)
la a1, sec_per_fat
lw t2, 0(a1)
la a1, reserved_sec
lw t0, 0(a1)

mul a0, t1, t2
add a0, a0, t0
la t3, root_dir_sector_start
sw a0, 0(t3)
lw a0, 0(t3)
call print_reg

li a0, 43       # +
call putchar

la t3, root_dir_sector_start
lw a0, 0(t3)
call sd_read_sector  # use a0 as sector no.
call print_sector

# -------------------------------------
# entries per secter = byte_per_sec/32  srli 5
li t0, "EntrPse"
addi sp, sp, -8
sd t0, 0(sp)
mv a0, sp
call puts
addi sp, sp, 8

la a1, byte_per_sec
lw a0, 0(a1)  # two byts, use lw, ld will get other word together!
call print_reg

la a1, byte_per_sec
lw a0, 0(a1)
srli a0, a0, 5  # calc entries_per_sector
mv s7, a0
#li t1, 32
#div a0, a0, t1
call print_reg

## Test mul #22D2B8
#li t1, 2324
#li t2, 982
#mul a0, t1, t2
#call print_reg


la t3, root_dir_sector_start
lw a0, 0(t3)
call sd_read_sector  # use a0 as sector no.

# -------------------------------------
# Scan Entries of Root Dir first sector
# s7 entry_per_sector
li s8, 0 # entry_index
li s9, "MUSIC"
addi sp, sp, -8
sd s9, 0(sp)
mv a0, sp
call puts
addi sp, sp, 8



entry_loop:
bge s8, s7, done_entries
# entry_addr = s1 + (entry_index * 32)
slli t1, s8, 5
add t3, s1, t1 # t3 = address of entry

# 1. Quick Validity Check
# load first byte of entry
lbu t4, 0(t3)
beq t4, x0, done_entries # 0x00 no more entries in dir
li t1, 0xE5
beq t4, t1, next_entry # 0xE5 deleted entry, skip
    
# 2. Attribute Check # attribute at 0x0B( offset 11)
lbu t5, 11(t3)
li t1, 0x0F
beq t5, t1, next_entry # 0x0F LFN(Long File Name) entry, skip

andi t6, t5, 0x18  # Mask for Volume Label(0x08) and Directory (0x10)
bne t6, x0, next_entry # skip 

# 3. Compare Filename(First 8 bytes)
# load name 8 bytes
li t2, 0
addi t4, t3, 7
load_name_loop:
lbu t0, 0(t4)
slli t2, t2, 8
xor t2, t2, t0
addi t4, t4, -1
bge t4, t3, load_name_loop

## keep 5 char
#slli t2, t2, 24
#srli t2, t2, 24

# -- Print Name --- 
addi sp, sp, -16
sd t2, 0(sp)
sb x0, 8(sp)
mv a0, sp
call puts
addi sp, sp, 16
# -----------------

bne t2, s9, next_entry

nend:
  j nend

## 4. FOUND! Extract File Info
#mv a0, t2
#call puts


next_entry:
addi s8, s8, 1
j entry_loop

done_entries:
   j done_entries




print_reg: # a0
    addi sp, sp, -8
    sd ra, 0(sp)
    addi sp, sp, -8
    sd s0, 0(sp)
    addi sp, sp, -8
    sd s1, 0(sp)
    addi sp, sp, -8
    sd s2, 0(sp)
    addi sp, sp, -8
    sd s3, 0(sp)
    mv s0, a0
    li a0, "0"
    call putchar
    li a0, "x"
    call putchar
    li s1, 60 
p_loop:
    srl s2, s0, s1      # get high nibble
    andi s2, s2, 0xF
    slti s3, s2, 10     # if < 10 number
    beq s3, x0, letter
    addi s2, s2, 48     # 0 is "0" ascii 48
    j print_h
letter:
    addi s2, s2, 55     # 10 is "A" ascii 65 ..
print_h:
    call wait_uart
    sb s2, 0(s11)       # print
    addi s1, s1, -4
    bge s1, x0, p_loop 
    ld s3, 0(sp)
    addi sp, sp, 8
    ld s2, 0(sp)
    addi sp, sp, 8
    ld s1, 0(sp)
    addi sp, sp, 8
    ld s0, 0(sp)
    addi sp, sp, 8
    ld ra, 0(sp)
    addi sp, sp, 8
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


# functions ------

putchar:  # a0
    addi sp, sp, -8
    sd s0, 0(sp)
putchar_wait:
    lw s0, 0(s10)
    srli s0, s0, 16   # 31:16 WSPACE = 0 fully
    beq s0, x0, putchar_wait
    sb a0, 0(s11)

    ld s0, 0(sp)
    addi sp, sp, 8
    ret


puts: # a0 addr
    addi sp, sp, -16
    sd ra, 0(sp)
    sd s0, 8(sp)
    mv s0, a0
puts_loop:
    lbu a0, 0(s0)
    beq a0, x0, stop_puts # \x00 for end of string
    call putchar # a0 char
    addi s0, s0, 1 # next byte
    j puts_loop
stop_puts:
    ld ra, 0(sp)
    ld s0, 8(sp)
    addi sp, sp, 16
    ret

wait_uart:
    addi sp, sp, -8
    sd s0, 0(sp)
wait_uart_loop:
    lw s0, 0(s10)
    srli s0, s0, 16   # 31:16 WSPACE = 0 fully
    beq s0, x0, wait_uart_loop

    ld s0, 0(sp)
    addi sp, sp, 8
    ret


