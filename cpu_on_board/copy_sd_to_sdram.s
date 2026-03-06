#`define Sdc_base  32'h0000_3000 (3000-31ff 512 bytes index) sd_cache 
#`define Sdc_addr  32'h0000_3200
#`define Sdc_read  32'h0000_3204
#`define Sdc_write 32'h0000_3208
#`define Sdc_ready 32'h0000_3220
#`define Sdc_dirty 32'h0000_3224
#`define Sdc_avail 32'h0000_3228
# UART 0x2004

.globl _start
_start:

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

li t1, 45        # -
sw t1, 0(t0)     # print

jal print_sector

li t1, 124       # |
sb t1, 0(t0)     # print

pause:
j pause

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
mv s0, t2    # s0 = bytes_per_sector offset 0x0b-0x0c 2 bytes
 
# sectors_per_cluster offset 0x0d 1 byte
addi t1, a1, 0x0D
lw t2, 0(t1)
andi t2, t2, 0xff
mv s1, t2    # s1 = sectors per cluster offset 0x0d 1 byte

# reserved_sectors offset 0x0e-0x0f 2 bytes (including root sector 0)
addi t1, a1, 0x0E
lw t2, 0(t1)
andi t2, t2, 0xff

addi t1, a1, 0x0F 
lw t3, 0(t1)
andi t3, t3, 0xff

slli t3, t3, 8
or t2, t2, t3
mv s2, t2    # s2 = reserved_sectors offset 0x0e-0x0f 2 bytes (including root sector 0)

# num_fats offset 0x10 1 bytes
addi t1, a1, 0x10
lw t2, 0(t1)
andi t2, t2, 0xff
mv s3, t2  # s3 = num_fats offset 0x10 1 bytes

# root_entries offset 0x11-0x12 2 bytes
addi t1, a1, 0x11
lw t2, 0(t1)
andi t2, t2, 0xff

addi t1, a1, 0x12
lw t3, 0(t1)
andi t3, t3, 0xff

slli t3, t3, 8
or t2, t2, t3
mv s4, t2    # s4 = root_entries offset 0x11-0x12 2 bytes

# sectors_per_fat16 high offset 0x16-0x17 2 bytes
addi t1, a1, 0x16
lw t2, 0(t1)
andi t2, t2, 0xff

addi t1, a1, 0x17
lw t3, 0(t1)
andi t3, t3, 0xff

slli t3, t3, 8
or t2, t2, t3
mv s5, t2    # s5 = sectors_per_fat16 high offset 0x16-0x17 2 bytes

# root_dir_sector_start = reserved_sectors + (num_fats * sectors_per_fat16)
mul t4, s3, s5
add t4, t4, s2
mv s6, t4     # s6 = root_dir_sector_start

# -- Read Root Dir first sector --
mv a2, s6
jal sd_read_sector

li t1, 66 # B
sw t1, 0(t0)     # print
#jal print_sector

# -- Scan Entries --
# entries_per_sector = bytes_per_sector / 32 -> srli 5
srli s7, s0, 5 # s7 = entries_per_sector (512/32=16)
li s8, 0       # s8 = entry_index

entry_loop:
bge s8, s7, done_entries

# entry_addr = a1 + (entry_index * 32)
li t1, 32
mul t2, s8, t1 # t2 = offset
add t3, a1, t2 # t3 = address of entry

# first byte of entry
lw t4, 0(t3)
beq t4, x0, done_entries # 0x00 no more entries in dir
li t1, 0xE5
beq t4, t1, next_entry # 0xE5 deleted entry, skip

# attribute at 0x0B(11)
lw t5, 11(t3)
li t1, 0x0F
beq t5, t1, next_entry # 0x0F LFN entry, skip

andi t6, t5, 0x08
bne t6, x0, next_entry # Bit 3 set Volume lable, skip 

# first cluster at 0x1A-0x1B 2 bytes
# file size at 0x1C-0x1D-0x1E-0x1F 4 bytes

# print 8.3 name
li a3, 0 # a3 = name char index
li a6, 8 # a6 = exit char index
li a7, 0 # name_chars
li a2, 0x4D55534943202020  # MUSIC___

print_name_loop:
add a4, t3, a3 # a4 = name char address
lw a5, 0(a4)   # a5 = name char
sw a5, 0(t0)

slli a7, a7, 8
or a7, a7, a5
addi a3, a3, 1
blt a3, a6, print_name_loop
beq a7, a2, find_file_entry

next_entry:
addi s8, s8, 1
j entry_loop

done_entries:
li t1, 90  # Z
sw t1, 0(t0)
j done_entries

find_file_entry:
li t1, 89  # Y
sw t1, 0(t0)
#j find_file

# file size at 0x1C-0x1D-0x1E-0x1F 4 bytes
addi t1, t3, 0x1C
lw t2, 0(t1)
andi t2, t2, 0xff

addi t1, t3, 0x1D
lw t4, 0(t1)
andi t4, t4, 0xff
slli t4, t4, 8
or t2, t2, t4

addi t1, t3, 0x1E
lw t4, 0(t1)
andi t4, t4, 0xff
slli t4, t4, 16
or t2, t2, t4

addi t1, t3, 0x1F
lw t4, 0(t1)
andi t4, t4, 0xff
slli t4, t4, 24
or t2, t2, t4
mv s9, t2   # s9 = file_size_bytes  


# first cluster at 0x1A-0x1B 2 bytes
addi t1, t3, 0x1A
lw t2, 0(t1)
andi t2, t2, 0xff

addi t1, t3, 0x1B
lw t4, 0(t1)
andi t4, t4, 0xff
slli t4, t4, 8
or t2, t2, t4
mv s10, t2   # s10 = file_cluster_start_number

# print file_cluster_start_number
li t1, 123  # {
sw t1, 0(t0) # print
srli t2, s10, 8
jal print_hex_b
mv t2, s10
jal print_hex_b
li t1, 125  # }
sw t1, 0(t0) # print

# s0 = bytes_per_sector
# s1 = sectors_per_cluster
# s2 = reserved_sectors
# s3 = num_fats
# s4 = root_entries
# s5 = sectors_per_fat16
# s6 = root_dir_sector_start
# s7 = entries_per_sector (512/32=16)
# s8 = entry_index
# s9 = file_size_bytes  
# s10 = file_cluster_start_number
# s11 = root_dir_sectors

# print bytes_per_sector
li t1, 91  # [
sw t1, 0(t0) # print
srli t2, s0, 8
jal print_hex_b
mv t2, s0
jal print_hex_b
li t1, 93  # ]
sw t1, 0(t0) # print

# print  sectors_per_cluster
li t1, 91  # [
sw t1, 0(t0) # print
mv t2, s1
jal print_hex_b
li t1, 93  # ]
sw t1, 0(t0) # print

# print root_entries
li t1, 91  # [
sw t1, 0(t0) # print
srli t2, s4, 8
jal print_hex_b
mv t2, s4
jal print_hex_b
li t1, 93  # ]
sw t1, 0(t0) # print

# root_dir_sector_start = reserved_sectors + (num_FATs * sectors_per_FAT)
# root_dir_sectors = (RootEntryCount * 32 + BytesPerSector -1 )/ BytesPerSector
# FirstDataSector = root_dir_sector_start + root_dir_sectors 
# FirstSectorOfCluster(N)=FirstDataSector + (N - 2) * SectorsPerCluster

#(.4000)(41FF)()
# ------
# print RootEntryCount * 32
li t1, 32
mul t6, s4, t1

li t1, 40  # (
sw t1, 0(t0) # print
li t1, 46  # .
sw t1, 0(t0) # print
srli t2, t6, 8
jal print_hex_b
mv t2, t6
jal print_hex_b
li t1, 41  # )
sw t1, 0(t0) # print

# ------ (41ff 16895)
# print  t6 + 512 - 1
add t6, t6, s0
addi t6, t6, -1

li t1, 40  # (
sw t1, 0(t0) # print
srli t2, t6, 8
jal print_hex_b
mv t2, t6
jal print_hex_b
li t1, 41  # )
sw t1, 0(t0) # print


# calculate root_dir_sectors 
li t1, 32
mul t4, s4, t1
addi t3, s0, -1
add t4, t4, t3
divu t3, t4, s0
mv s11, t3 # s11 = root_dir_sectors



# file_cluster_start_number
# bytes_per_sector
# sectors_per_cluster
# root_entries
# root_dir_sectors
# file_first_sector
# {00BD}[0200][40][0200][41FF](30E1) 
# s10     s0   s1  s4    s11


# print root_dir_sectors 0x0020
li t1, 91  # [
sw t1, 0(t0) # print
srli t2, s11, 8
jal print_hex_b
mv t2, s11
jal print_hex_b
li t1, 93  # ]
sw t1, 0(t0) # print

# calculate first data sector
add t1, s6, s11

# calculate file_first_sector
addi t2, s10, -2
mul t3, t2, s1
add t6, t1, t3 # t6 = file's first sector

# print file_first_sector 0x30E1)
li t1, 40  # (
sw t1, 0(t0) # print
srli t2, t6, 8
jal print_hex_b
mv t2, t6
jal print_hex_b
li t1, 41  # )
sw t1, 0(t0) # print

# read & print file_first_sector 
mv a2, t6
jal sd_read_sector
jal print_sector

j sdram_test



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
sw t3, 0(t0)
andi t4, t2, 0x0F      # get low nibble
slti t5, t4, 10     # if < 10 number
beq t5, x0, letter_l
addi t4, t4, 48     # 0 is "0" ascii 48
j print_l_hex
letter_l:
addi t4, t4, 55        # 10 is "A" ascii 65 ..
print_l_hex:
li t1, 126           # '~'
sb t1, 0(t0)         # print_sector finish print 512 byte

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










# Minimal SDRAM test
sdram_test:

    lui t0, 0x2
    addi t0, t0, 4       # UART = 0x2004
    
    lui s0, 0x10000      # SDRAM = 0x10000000
    
    # Write one byte
    li t1, 0x58          # 'X'
    sb t1, 0(s0)         # test sdram sb/sh
    
    # Read it back
    lbu t2, 0(s0)         # test sdram lbu
    
    # Print it
    sb t2, 0(t0)         # Should print 'X'
    sb t2, 0(t0)         # Should print 'X'
    sh t2, 0(t0)         # Should print 'X'
    
    # Write 4 byte
    li t1, 0x44434241    # 'DCBA'
    sw t1, 0(s0)         # test sdram sw
    
    # Read it back
    lhu t3, 0(s0) # A    # test sdram lhu lwu
    lbu t4, 1(s0) # B
    lwu t5, 2(s0) # C
    lbu t6, 3(s0) # D
    
    # Print it
    sb t3, 0(t0)         # Should print 'A'
    sb t4, 0(t0)         # Should print 'B'
    sb t5, 0(t0)         # Should print 'C'
    sb t6, 0(t0)         # Should print 'D'
    sb t2, 0(t0)         # Should print 'X'

    ## MMU enabled
    #li a1, 8              
    #slli a1, a1, 60          # mmu mode sv39 #li a1, 0x8000000000000000 # mmu mode sv39
    #csrrw a3, satp, a1      # set satp csr index 0x180


    # Write 8 byte
    li t1, 0x4847464544434241         # 'HGFEDCBA'
    sd t1, 0(s0)         # test sdram sd

    # Read it back
    lbu a0, 0(s0) # A
    lbu a1, 1(s0) # B
    lbu a2, 2(s0) # C
    lbu a3, 3(s0) # D
    lbu a4, 4(s0) # E
    lbu a5, 5(s0) # F
    lbu a6, 6(s0) # G
    lbu a7, 7(s0) # H

    # Print it
    sb a0, 0(t0)         # Should print 'A'
    sb a1, 0(t0)         # Should print 'B'
    sb a2, 0(t0)         # Should print 'C'
    sb a3, 0(t0)         # Should print 'D'
    sb a4, 0(t0)         # Should print 'E'
    sb a5, 0(t0)         # Should print 'F'
    sb a6, 0(t0)         # Should print 'G'
    sb a7, 0(t0)         # Should print 'H'
    sb t2, 0(t0)         # Should print 'X'

    # Read it back       # test sdram ld
    ld a0, 0(s0)

    sb a0, 0(t0)         # Should print 'A'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'B'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'C'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'D'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'E'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'F'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'G'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'H'
    sb t2, 0(t0)         # Should print 'X'



    # MMU enabled
    li a1, 8              
    slli a1, a1, 60          # mmu mode sv39 #li a1, 0x8000000000000000 # mmu mode sv39
    csrrw a3, satp, a1      # set satp csr index 0x180



    li t3, 124 # |
    sb t3, 0(t0) # mmu settled

    # Write 4 byte
    li t1, 0x44434241    # 'DCBA'

    li t3, 58 # :
    sb t3, 0(t0) # start read sw to sdram

    sw t1, 0(s0)         # test sdram sw

    # Read it back
    lhu t3, 0(s0) # A    # test sdram lhu lwu
    lbu t4, 1(s0) # B
    lwu t5, 2(s0) # C
    lbu t6, 3(s0) # D
    
    # Print it
    sb t3, 0(t0)         # Should print 'A'
    sb t4, 0(t0)         # Should print 'B'
    sb t5, 0(t0)         # Should print 'C'
    sb t6, 0(t0)         # Should print 'D'
    sb t2, 0(t0)         # Should print 'X'


#wait_loop:
#    j wait_loop
#

    # Write 8 byte
    li t1, 0x4847464544434241         # 'HGFEDCBA'
    sd t1, 0(s0)         

    # Read it back
    lbu a0, 0(s0) # A
    lbu a1, 1(s0) # B
    lbu a2, 2(s0) # C
    lbu a3, 3(s0) # D
    lbu a4, 4(s0) # E
    lbu a5, 5(s0) # F
    lbu a6, 6(s0) # G
    lbu a7, 7(s0) # H

    # Print it
    sb a0, 0(t0)         # Should print 'A'
    sb a1, 0(t0)         # Should print 'B'
    sb a2, 0(t0)         # Should print 'C'
    sb a3, 0(t0)         # Should print 'D'
    sb a4, 0(t0)         # Should print 'E'
    sb a5, 0(t0)         # Should print 'F'
    sb a6, 0(t0)         # Should print 'G'
    sb a7, 0(t0)         # Should print 'H'
    sb t2, 0(t0)         # Should print 'X'

    # Read it back       # test sdram ld
    ld a0, 0(s0)

    sb a0, 0(t0)         # Should print 'A'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'B'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'C'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'D'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'E'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'F'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'G'
    srli a0, a0, 8
    sb a0, 0(t0)         # Should print 'H'
    sb t2, 0(t0)         # Should print 'X'

    # Write one byte
    li t1, 0x41          # 'A'
    sb t1, 0(s0)         # test sdarm sb
    li t1, 0x42          # 'B'
    sb t1, 1(s0)         # test sdarm sb+1

    # Read it back       
    lb a0, 0(s0)         # test sdram ld
    sb a0, 0(t0)         # Should print 'A'


    ## MMU enabled
    #li a1, 8              
    #slli a1, a1, 60          # mmu mode sv39 #li a1, 0x8000000000000000 # mmu mode sv39
    #csrrw a3, satp, a1      # set satp csr index 0x180


    lb a0, 1(s0)         # test sdram ld+1
    sb a0, 0(t0)         # Should print 'B'
    
    ## MMU un-enabled
    #li a1, 0              
    #slli a1, a1, 60          # mmu mode sv39 #li a1, 0x8000000000000000 # mmu mode sv39
    #csrrw a3, satp, a1      # set satp csr index 0x180

    li t3, 124 # |
    sb t3, 0(t0) # to plic

    # -----PLIC TEST---
    li t0, 0x2004 # UART data

    # Enable UART read from terminal as irq
    li t1, 1
    sw t1, 4(t0) # write 1 to 0x2008 UART control means readable

    li t3, 48 # 0
    sb t3, 0(t0)

    # Set handler
    la t2, irq_handler
    csrw mtvec, t2

    li t3, 49 # 1
    sb t3, 0(t0)

    # PLIC setting
    # Set priority[1] = 1 # [1] is UART
    li t2, 0x0C000004 # `define Plic_base 32'h0C00_0000  # PRIORITY(id) = base + 4 * id
    li t3, 1
    sw t3, 0(t2)
   
    li t3, 50 # 2
    sb t3, 0(t0)

    # Set enable bits = irq_id, so enable bit = (1 << id) ctx 0
    li t2, 0x0C002000
    li t1, 2 #( 1<<1 = 2)
    sw t1, 0(t2)

    li t3, 51 # 3
    sb t3, 0(t0)

    ## Set enable bits = irq_id, so enable bit = (1 << id) ctx 1
    #li t2, 0x0C002080
    #li t1, 2 #( 1<<1 = 2)
    #sw t1, 0(t2)

    #li t3, 51 # 3
    #sb t3, 0(t0)

    # Set shreshold 0
    li t2, 0x0C200000  # base +0x200000+hard_id<<12
    li t1, 0 
    sw t1, 0(t2)

    li t3, 52 # 4
    sb t3, 0(t0)
  
    # Set shreshold 1
    li t2, 0x0C201000  # base +0x200000+hard_id<<12
    li t1, 0 
    sw t1, 0(t2)

    li t3, 53 # 5
    sb t3, 0(t0)

    # Enable MEIE (mie.MEIE enternal interrupt)
    li t2, 0x800 # bit 11=MEIE
    csrs mie, t2

    li t3, 54 # 6
    sb t3, 0(t0)

    # Enalbe MIE
    li t2, 8  # (bit 3 mstatus.MIE)
    csrs mstatus, t2

    li t3, 55 # 7
    sb t3, 0(t0) # to plic

wait_loop:
    j wait_loop

irq_handler:
   li t0, 0x2004 # UART data for print/read
   li t2, 0x0C200004  # PLIC Claim context 0 register

   li t3, 124 # |
   sb t3, 0(t0) # print |

   # Read claim
   lw t1, 0(t2)
   mv t5, t1

   beqz t1, exit_irq

   addi t4, t1, 48 
   sb t4, 0(t0) # show interrupt id
   li t3, 46 # .
   sb t3, 0(t0) 

   # Handle
   lw t3, 0(t0) # read from UART FIFO
   sw t3, 0(t0) # print key value

   sw t5, 0(t2) # write id back to ctx0claim to clear pending id
   li t3, 47 # /
   sb t3, 0(t0) #  finished

exit_irq:
   li t3, 69 # E
   sb t3, 0(t0) #  Exit irq
   mret 
