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
root_ent_cnt:
    .word 0
sec_per_clus:
    .word 0
data_start_sec:
    .word 0
entries_per_sector:
    .word 0
total_sectors:
    .word 0
file_size:
    .word 0
file_first_cluster:
    .word 0




# -- Start program main function _start --
.section .text
# -- Global setup --
_start:
    li sp, 0x1000 # Set stack
    li s11, 0x2004 # UART print 
    li s10, 0x2008 # UART controller
    li s1,  0x3000 # SD base
    li s2,  0x3200 # SD address
    li s3,  0x3204 # SD trigger read
    li s4,  0x3208 # SD trigger write
    li s5,  0x3220 # SD ready for rd/wr
    li s6,  0x3228 # SD cache available
    # a0 for function call default parameter

# ---------------------- SD card -------------------
# Sector 0 Layout # BPB (BIOS Parameter Block) in sector 0
#| Offset | Size | Field                           | Meaning                        | Example (FAT16) |
#| :----- | :--- | :------------------------------ | :----------------------------- | :-------------- |
#| `0x00` | 3    | Jump Instruction                | JMP to boot code               | EB 3C 90        |
#| `0x03` | 8    | OEM Name                        | Text label                     | "MSDOS5.0"      |
#| `0x0B` | 2    | **Bytes per sector**            | Usually 512                    | 0x0200          |
#| `0x0D` | 1    | **Sectors per cluster**         | Cluster size (e.g. 1,2,4,8,16) | 1               |
#| `0x0E` | 2    | **Reserved sectors**            | Includes boot sector           | 1               |
#| `0x10` | 1    | **Number of FATs**              | Typically 2                    | 2               |
#| `0x11` | 2    | **Root entries**                | Count of directory entries     | 512             |
#| `0x13` | 2    | **Total sectors (16-bit)**      | If zero, use 0x20–0x23         | 2880            |
#| `0x15` | 1    | **Media descriptor**            | 0xF8 (fixed disk)              | F8              |
#| `0x16` | 2    | **Sectors per FAT**             | FAT size                       | 9               |
#| `0x18` | 2    | **Sectors per track**           | BIOS info                      | 18              |
#| `0x1A` | 2    | **Number of heads**             | BIOS info                      | 2               |
#| `0x1C` | 4    | **Hidden sectors**              | Partition offset               | 0               |
#| `0x20` | 4    | **Total sectors (32-bit)**      | Large volumes                  | 0               |
#| `0x24` | —    | (More fields in FAT32 only)     | —                              | —               |
#| `0x36` | 11   | Volume Label / File System Type | "NO NAME    " / "FAT16   "     | —               |
#| :----- | :--- | :------------------------------ | :----------------------------- | :-------------- |

# ----------Read BPB sector 0 -----
la a0, read_sd_sector 
call puts
li a0, 0   
call sd_read_sector  # use a2 as sector no.

la a0, prt_sector
call puts
call print_sector

#li a0, 43       # +
#call putchar

# -- Parse BPB -- little-endian  Bios Parameter Block : sector 0
# -------------------------------------
# byte_per_sec offset 0x0b-0x0c 2 bytes
li a0, "\nBPsec:" # 7 char left on for null
call print7

la a1, byte_per_sec
lbu t0, 0x0b(s1)
lbu t1, 0x0c(s1)
slli t1, t1, 8
or a0, t1, t0 
#lh a0, 0x0b(s1)

sh a0, 0(a1)
lh a0, 0(a1)
call print_reg

# -------------------------------------
# Sectors per cluster 0x0d 1 byte
li a0, "\nsePcl:" # 7 char left on for null
call print7

la a1, sec_per_clus
lbu a0, 0x0d(s1)
sh a0, 0(a1)
lh a0, 0(a1)
call print_reg


# -------------------------------------
# reserved_sectors offset 0x0e-0x0f 2 bytes (including root sector 0)
li a0, "\nrevSe:" # 7 char left on for null
call print7

la a1, reserved_sec
lh a0, 0x0e(s1)
sd a0, 0(a1)
ld a0, 0(a1)
call print_reg

# -------------------------------------
# num_fats offset 0x10 1 bytes
li a0, "\nnuFat:" # 7 char left on for null
call print7

la a1, num_fats
lbu a0, 0x10(s1)
sw a0, 0(a1)
lw a0, 0(a1)
call print_reg


# -------------------------------------
# root_entries offset 0x11-0x12 2 bytes
li a0, "\nReCnt:"
call print7

la a1, root_ent_cnt
lbu t0, 0x11(s1)
lbu t1, 0x12(s1)
slli t1, t1, 8
or a0, t1, t0 

sh a0, 0(a1)
lh a0, 0(a1)
call print_reg

# -------------------------------------
# total sectors offset 0x13 2 bytes if 0 find 0x20 4 bytes for large volumes
li a0, "\nToSec:"
call print7
la a1, total_sectors
#lbu t0, 0x13(s1)
#lbu t1, 0x14(s1)
#slli t1, t1, 8
#or a0, t1, t0 
lwu a0, 0x20(s1)

sw a0, 0(a1)
lwu a0, 0(a1)
call print_reg

# -------------------------------------
# Media descriptor offset 0x15 1 byte


# -------------------------------------
# sectors_per_fat16 high offset 0x16-0x17 2 bytes
li a0, "\nsePft:" # 7 char left on for null
call print7

la a1, sec_per_fat
#lbu t0, 0x16(s1)
#lbu t1, 0x17(s1)
#slli t1, t1, 8
#or a0, t1, t0 
lh a0, 0x16(s1)

sh a0, 0(a1)
lh a0, 0(a1)
call print_reg


## ---------Calcauted ----------------------------
# root_dir_sector_start = reserved_sectors + (num_fats * sectors_per_fat16)
li a0, "\nrtdS0:" # 7 char left on for null
call print7

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

# -------------------------------------
# entries_per_sector =  byte_per_sec/32
li a0, "\nEtPse:"
call print7
  
la a1, byte_per_sec
lw a0, 0(a1)
mv s7, a0
#srli a0, a0, 5  # calc entries_per_sector
li t1, 32
div a0, a0, t1

la t3,  entries_per_sector
sw a0, 0(t3)
lw a0, 0(t3)
call print_reg


# ------------------------
# data_start_sec = 








li a0, 43       # +
call putchar

# ---------- Read Root dir Secotr 0 -----
la t3, root_dir_sector_start
lw a0, 0(t3)
call sd_read_sector  # use a0 as sector no.
call print_sector

la t3, root_dir_sector_start
lw a0, 0(t3)
call sd_read_sector  # use a0 as sector no.

# -------------------------------------
# Scan Entries of Root Dir first sector
# s7 entry_per_sector
li s8, 0 # entry_index
li s9, "MUSIC"
mv a0, s9
call print7



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

# keep 5 char
slli t2, t2, 24
srli t2, t2, 24

# -- Print Name --- 
addi sp, sp, -16
sd t2, 0(sp)
sb x0, 8(sp)
mv a0, sp
call puts
addi sp, sp, 16
# -----------------

bne t2, s9, next_entry

## 4. FOUND! Extract File Info
li a0, "FOUND!"
call print7

done_entries:
   j read_file

next_entry:
addi s8, s8, 1
j entry_loop


# root_dir_sector_start = reserved_sectors + (num_FATs * sectors_per_FAT)
# root_dir_sectors = (RootEntryCount * 32 + BytesPerSector -1 )/ BytesPerSector  ceiling division
# FirstDataSector = root_dir_sector_start + root_dir_sectors 
# FirstSectorOfCluster(N)=FirstDataSector + (N - 2) * SectorsPerCluster

# Entry Layout(in Root Directory)
#| Offset | Size | Field                             | Description                  | Example      |
#| :----- | :--- | :-------------------------------- | :--------------------------- | :----------- |
#| `0x00` | 8    | **Filename**                      | 8 chars (space padded)       | `"MUSIC   "` | FAT16 8.3 format for name.extension
#| `0x08` | 3    | **Extension**                     | 3 chars (space padded)       | `"WAV"`      |
#| `0x0B` | 1    | **Attributes**                    | Bit flags (see below)        | 0x20         |
#| `0x0C` | 1    | Reserved                          | For Windows NT               | 0            |
#| `0x0D` | 1    | Creation time (tenths)            | Optional                     | —            |
#| `0x0E` | 2    | Creation time                     | —                            | —            |
#| `0x10` | 2    | Creation date                     | —                            | —            |
#| `0x12` | 2    | Last access date                  | —                            | —            |
#| `0x14` | 2    | High word of cluster (FAT32 only) | —                            | —            |
#| `0x16` | 2    | Last modified time                | —                            | —            |
#| `0x18` | 2    | Last modified date                | —                            | —            |
#| `0x1A` | 2    | **First cluster (low word)**      | Cluster number (starts at 2) | 0x0002       |
#| `0x1C` | 4    | **File size (bytes)**             | File length                  | 4096         |

read_file:
## file size at 0x1C-0x1D-0x1E-0x1F 4 bytes
li a0, "\nFSize:"
call print7
lwu a0, 0x1c(t3)
la a1, file_size
sw a0, 0(a1)
lwu a0, 0(a1)
call print_reg

# file_first_cluster at 0x1A-0x1B 2 bytes
li a0, "\nF0cls:"
call print7
#lhu a0, 0x1a(t3)
#la a1, file_first_cluster
#sh a0, 0(a1)
#lhu a0, 0(a1)
#call print_reg








end: 
j end






# functions ------

print_reg: # a0
    addi sp, sp, -40
    sd ra, 0(sp)
    sd s0, 8(sp)
    sd s1, 16(sp)
    sd s2, 24(sp)
    sd s3, 32(sp)
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
    ld ra, 0(sp)
    ld s0, 8(sp)
    ld s1, 16(sp)
    ld s2, 24(sp)
    ld s3, 32(sp)
    addi sp, sp, 40
    ret


# ---  sd_read_sector ---
sd_read_sector:  #  a0 sector index
    addi sp, sp, -24
    sd s7, 0(sp)
    sd s8, 8(sp)
    sd ra, 16(sp)
    sw a0, 0(s2) # Write Sector index value to address 0x3200
wait_ready:
    lw s7, 0(s5)   # 0x3220 ready
    li a0, 96      # `
    call putchar
    beq s7, x0, wait_ready
    li s8, 1
    sw s8, 0(s3)   # Trigger read at 0x3204
wait_cache:
    lw s7, 0(s6)   # s7 0x3228 cache_avaible
    beq s7, x0, wait_cache
    ld s7, 0(sp)
    ld s8, 8(sp)
    ld ra, 16(sp)
    addi sp, sp, 24
    ret


# print sector 0 512 bytes
print_sector:
    addi sp, sp, -64
    sd ra, 0(sp)
    sd s4, 8(sp)
    sd s5, 16(sp)
    sd s6, 24(sp)
    sd s7, 32(sp)
    sd s8, 40(sp)
    sd s9, 48(sp)
    sd s3, 56(sp)
    li s7, 0   # byte index
    li s8, 511 # max byte index
print_loop:
    add s6, s1, s7 
    addi s7, s7, 1
    lbu s9, 0(s6)       # load byte at 0x3000 a1+t1
    andi s9, s9, 0xFF   # Isolate byte value
    srli s3, s9, 4      # get high nibble
    slti s5, s3, 10     # if < 10 number
    beq s5, x0, letter_h
    addi s3, s3, 48     # 0 is "0" ascii 48
    j print_h_hex
letter_h:
    addi s3, s3, 55     # 10 is "A" ascii 65 ..
print_h_hex:
    call wait_uart 
    sb s3, 0(s11)
    andi s4, s9, 0x0F   # get low nibble
    slti s5, s4, 10     # if < 10 number
    beq s5, x0, letter_l
    addi s4, s4, 48     # 0 is "0" ascii 48
    j print_l_hex
letter_l:
    addi s4, s4, 55     # 10 is "A" ascii 65 ..
print_l_hex:
    call wait_uart 
    sb s4, 0(s11)
    bge s8, s7, print_loop
    ld ra, 0(sp)
    ld s4, 8(sp)
    ld s5, 16(sp)
    ld s6, 24(sp)
    ld s7, 32(sp)
    ld s8, 40(sp)
    ld s9, 48(sp)
    ld s3, 56(sp)
    addi sp, sp, 64
    ret
# -- end print_sector --


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

print7: # a0, 7 char left one for null
    addi sp, sp, -16
    sd a0, 0(sp)
    sd ra, 8(sp)
    mv a0, sp
    call puts
   #ld a0, 0(sp)
    ld ra, 8(sp)
    addi sp, sp, 16
    ret
