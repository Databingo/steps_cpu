#`define Sdc_base  32'h0000_3000 (3000-31ff 512 bytes index) sd_cache 
#`define Sdc_addr  32'h0000_3200
#`define Sdc_read  32'h0000_3204
#`define Sdc_write 32'h0000_3208
#`define Sdc_ready 32'h0000_3220
#`define Sdc_dirty 32'h0000_3224
#`define Sdc_avail 32'h0000_3228
# UART 0x2004

# Boot Sector: Sector 0 LBA
# root_dir_sector = reserved_sectors + (num_FATs * sectors_per_FAT)


.globl _start
_start:

# Get UART address (0x2004) into t6.
lui t0, 0x2
addi t0, t0, 4      # t0 = 0x2004

# SD base
lui a1, 0x3         # a1 = 0x3000 base

# Wait SD ready, then read boot sector (LBA-0)
sd_ready:
lw a2, 0x220(a1)    # a2 0x3220 ready
beq a2, x0, sd_ready

# -- Read Boot Sector 0 -- 
li a2, 0
jal sd_read_sector

#li t1, 'A'
addi t1, x0, 65  # A
sw t1, 0(t0)     # print

# -- Parse BPB -- little-endian

# bytes_per_sector offset 0x0b-0x0c 2 bytes
addi t1, a1, 0x0B 
lw t2, 0(t1)
andi t2, t2, 0xff

addi t1, a1, 0x0C  
lw t3, 0(t1)
andi t3, t3, 0xff

slli t3, t3, 8
or t2, t2, t3
mv s0, t2    
 
# sec per clus offset 0x0d 1 byte
addi t1, a1, 0x0D
lw t2, 0(t1)
andi t2, t2, 0xff
mv s1, t2    

# reserved_sectors offset 0x0e-0x0f 2 bytes
addi t1, a1, 0x0E
lw t2, 0(t1)
andi t2, t2, 0xff

addi t1, a1, 0x0F 
lw t3, 0(t1)
andi t3, t3, 0xff

slli t3, t3, 8
or t2, t2, t3
mv s2, t2    


# num_fats offset 0x10 1 bytes
addi t1, a1, 0x10
lw t2, 0(t1)
andi t2, t2, 0xff
mv s3, t2  


# root_entries offset 0x11-0x12 2 bytes
addi t1, a1, 0x11
lw t2, 0(t1)
andi t2, t2, 0xff

addi t1, a1, 0x12
lw t3, 0(t1)
andi t3, t3, 0xff

slli t3, t3, 8
or t2, t2, t3
mv s4, t2    

# sectors_per_fat16 high offset 0x16-0x17 2 bytes
addi t1, a1, 0x16
lw t2, 0(t1)
andi t2, t2, 0xff

addi t1, a1, 0x17
lw t3, 0(t1)
andi t3, t3, 0xff

slli t3, t3, 8
or t2, t2, t3
mv s5, t2    

# BPB (BIOS Parameter Block) in sector 0
# offset size FAT16 FAT32 filed 
# 0x0b 2    512   512   bytes per secter
# 0x0d 2                sectors per cluster 
# 0x0e 2    1     32    reserverd sectors
# 0x10 1    2     2     numbers of FATs
# 0x11 2    512   0     root entries
# 0x16 2    9     0     sectors per FAT
# 0x24 4    0     0x9f0 sectors per FAT (fat32 only)
# 0x2c                  root cluster (fat32 only)
# 0x36 8    FAT16 FAT32 FAT label string 

# Entries 32 bytes  FAT16 8.3 format for name.extension
# offset size meaning 
# 0x00 8 name 
# 0x80 3 extension
# 0x0B 1 attributes
# 0x0E 2 time last modified
# 0x10 2 date
# 0x1A 2 first cluster
# 0x1C 4 file size bytes

## Detect FAT type
#beq s3, x0, is_fat32  # root_entries == 0
#beq s4, x0, is_fat32  #  sectors_per_fat == 0

# -- compute Root Dir Start sector
# root_dir_start_sector = reserved_sectors + (num_fats * sectors_per_fat16)
# s2 + s3 * s5
mul t3, s3, s5
add t3, t3, s2
mv s6, t3     # s6 = root_start_sector

# -- Read Root Dir first sector --
mv a2, s6
jal sd_read_sector

li t1, 66 # B
sw t1, 0(t0)     # print

# -- Scan Entries --
# div







#
#li a0, 79 # O
#jal print_char
#mv a0, s6
#jal print_bin_f
#
## set SD read address
#sw s6, 0x200(a1)
#li a3, 1
#sw a3, 0x204(a1)
#
#sd_ready_3:
#lw a2, 0x220(a1)    # a2 0x3220 ready
#beq a2, x0, sd_ready_3
#
#addi t1, x0, 68  # D
#sw t1, 0(t0)     # print
#
## Wait for cache available
#avail_3:
#lw a2, 0x228(a1)    # a2 0x3228 cache_avaible
#beq a2, x0, avail_3
#
#addi t1, x0, 69  # E
#sw t1, 0(t0)     # print
#
#
#
#
#
#
## print sector 0 512 bytes
#
#li t1, 0   # byte index
#li t6, 511 # max byte index
#
#print_loop:
#add a4, a1, t1 
#addi t1, t1, 1
#
#
#lw t2, 0(a4)        # load byte at 0x3000 a1+t1
#andi t2, t2, 0xFF   # Isolate byte value
#
#
#srli t3, t2, 4      # get high nibble
#slti t5, t3, 10     # if < 10 number
#beq t5, x0, letter_h
#addi t3, t3, 48     # 0 is "0" ascii 48
#j print_h_hex
#letter_h:
#addi t3, t3, 55     # 10 is "A" ascii 65 ..
#print_h_hex:
#sw t3, 0(t0)
#
#
#andi t4, t2, 0x0F      # get low nibble
#slti t5, t4, 10     # if < 10 number
#beq t5, x0, letter_l
#addi t4, t4, 48     # 0 is "0" ascii 48
#j print_l_hex
#letter_l:
#addi t4, t4, 55        # 10 is "A" ascii 65 ..
#print_l_hex:
#sw t4, 0(t0)
#
#bge t6, t1, print_loop
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#j print_name
#
## -- FAT 32 --
#
#print_name:
#li t1,0 # offset
#li t6,7 # 8 chars
#
#print_loop_n:
#add a4, a1, t1
#lw t2, 0(a4)
#andi t2, t2, 0xff
#sw t2, 0(t0)
#addi t1, t1, 1
#ble t1, t6, print_loop_n
#done:
#j done
#
#
#
#
#
#
#
#
##li t1, 0   # byte index
##li t6, 511 # max byte index
##
##print_loop:
##add a4, a1, t1 
##addi t1, t1, 1
##
##
##lw t2, 0(a4)           # load byte at 0x3000 a1+t1
##andi t2, t2, 0xFF   # Isolate byte value
##
##
##srli t3, t2, 4      # get high nibble
##slti t5, t3, 10     # if < 10 number
##beq t5, x0, letter_h
##addi t3, t3, 48     # 0 is "0" ascii 48
##j print_h_hex
##letter_h:
##addi t3, t3, 55     # 10 is "A" ascii 65 ..
##print_h_hex:
##sw t3, 0(t0)
##
##
##andi t4, t2, 0x0F      # get low nibble
##slti t5, t4, 10     # if < 10 number
##beq t5, x0, letter_l
##addi t4, t4, 48     # 0 is "0" ascii 48
##j print_l_hex
##letter_l:
##addi t4, t4, 55        # 10 is "A" ascii 65 ..
##print_l_hex:
##sw t4, 0(t0)
##
##
##bge t6, t1, print_loop
#
#
#
## funciton print_bin(a0) print 9 bits of a0 at t0 UART
#print_bin_f:
#li t1, 8 # number of bits
#print_binf_loop:
#addi t1, t1, -1
#srl t2, a0, t1
#andi t2, t2, 1
#addi t2, t2, 48  # 0 to "0"
#sw t2, 0(t0)     # print
#bne t1, x0, print_binf_loop
#ret
## ---------
#
## function print_char(a0)
#print_char:
#sw a0, 0(t0)
#ret



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
ret
