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
#li t1, 0x60        # `
#sb t1, 0(t0)     # print
beq a2, x0, sd_ready

li t1, 0x58          # 'X'
sb t1, 0(t0)         # test

# -- Read Boot Sector 0 -- 
li a2, 0
jal sd_read_sector

li t1, 65        # A
sw t1, 0(t0)     # print

#jal print_sector

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



# ---  sd_read_sector ---
sd_read_sector:
wait_ready:
lw t2, 0x220(a1)    # t2 0x3220 ready
beq t2, x0, wait_ready

sw a2, 0x200(a1) # Write Sector index value to address 0x3200
li t1, 1
sw t1, 0x204(a1) # Trigger read at 0x3204
wait_cache:
lw t2, 0x228(a1)    # t2 0x3228 cache_avaible
beq t2, x0, wait_cache
ret


# BPB
#Field,Value
#Jump Instruction,EB3C90
#OEM Name,BSD  4.4
#Bytes per Sector,512
#Sectors per Cluster,64
#Reserved Sectors,1
#Number of FATs,2
#Root Directory Entries,512
#Total Sectors (small),0
#Media Descriptor,0xF0
#Sectors per FAT,256
#Sectors per Track,32
#Number of Heads,255
#Hidden Sectors,0
#Total Sectors (large),4194144
#Drive Number,0
#Reserved,0
#Extended Boot Signature,0x29
#Volume ID,0x31761C09
#Volume Label,NO NAME
#File System Type,FAT16
#Error Message,\r\nNon-system disk\r\nPress any key to reboot\r\n
#Boot Signature,55AA


#| Entry | Type    | Short Name          | Attribute | Notes                                             |
#| :---: | :------ | :------------------ | :-------: | :------------------------------------------------ |
#|   0   | Invalid | –                   |    0x0F   | garbage / deleted LFN                             |
#|   1   | LFN     | (part of SPOTLIGHT) |    0x0F   | Unicode chars `.Spotlight-`                       |
#|   2   | Short   | `SPOTLI~1`          |    0x12   | Short name for `.Spotlight-`                      |
#|   3   | LFN     | (part of FSEVEN)    |    0x0F   | Unicode chars `fsseven`                           |
#|   4   | Short   | `FSEVEN~1`          |    0x12   | short name for that                               |
#|   5   | Short   | `MUSIC   WAV`       |    0x20   | ✅ file MUSIC.WAV, cluster 5B62, size 32 146 bytes |
#|   6   | LFN     | (part of _MUSIC...) |    0x0F   | Unicode sequence `_music.wav`                     |
#|   7   | Short   | `_MUSIC~1.WAV`      |    0x22   | Hidden/Archive                                    |
#|   8   | LFN     | (part of TRASHE)    |    0x0F   | Unicode “Trashes”                                 |
#|   9   | Short   | `TRASHE~1`          |    0x12   | Hidden+archive (macOS trash)                      |
#|  10+  | Empty   | —                   |    0x00   | end of directory                                  |


# FAT16 Raw Construction
# ReservedSectors(including root sector 0)|FAT|rootDirectorySectors(entry32bytes*cnt/512=sectores)|Clusters(First cluster is 2)
# sector0 = initial information
# root_dir_sector = reserved_sectors + (num_FATs * sectors_per_FAT)
# RootDirEntry0x1A-0x1B = file's firstClusterNumber(N)
# DataRegionStart(FirstDataSector) = root_dir_start_sector + root_dir_sectors
# FirstSectorOfCluster(N)=FirstDataSector + (N - 2) * SectorsPerCluster


# FAT16 Raw Data Layout
#| Region                     | Description                                                    | Formula / Range                                                     |
#| :------------------------- | :------------------------------------------------------------- | :------------------------------------------------------------------ |
#| **Boot Sector (BPB)**      | Sector 0 — contains BIOS Parameter Block (filesystem metadata) | Sector 0                                                            |
#| **Reserved Sectors**       | Includes boot sector + any reserved sectors                    | 0 → (ReservedSectors − 1)                                           |
#| **FAT Region**             | Contains cluster chain tables                                  | `ReservedSectors → ReservedSectors + (NumFATs * SectorsPerFAT) − 1` |
#| **Root Directory Region**  | Contains fixed 32-byte directory entries                       | `RootDirStartSector = ReservedSectors + (NumFATs * SectorsPerFAT)`  |
#| **Data Region (Clusters)** | File and directory data stored here                            | `DataRegionStart = RootDirStartSector + RootDirSectors`             |

#RootDirSectors = RootEntries * 32 /BytesPerSector

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

# Attribute at 0x0B(11)
#| Attribute | Meaning               | Example entry        |
#| :-------: | :-------------------- | :------------------- |
#|   `0x0F`  | Long file name (LFN)  | `xx xx xx xx ... 0F` |
#|   `0x20`  | Archive (normal file) | `"MUSIC   WAV"`      |
#|   `0x10`  | Directory             | `"FOLDER  "`         |
#|   `0x08`  | Volume label          | `"NO NAME "`         |
#|   `0x00`  | Unused entry          | empty/deleted        |

# Attribute Type Bits(0x0B)
#| Bit | Mask | Meaning               |
#| :-- | :--- | :-------------------- |
#| 0   | 0x01 | Read-only             |
#| 1   | 0x02 | Hidden                |
#| 2   | 0x04 | System                |
#| 3   | 0x08 | Volume label          |
#| 4   | 0x10 | Subdirectory          |
#| 5   | 0x20 | Archive (normal file) |
#| 6   | 0x40 | Device (unused)       |
#| 7   | 0x80 | Unused                |

# FAT Table(Cluster->NextCluster Map) Each entry (2 bytes) in FAT corresponds to one cluster in the data area.
#|No| Next Cluster      | Meaning of FAT entry (16-bit value) |
#|- | :---------------- | :---------------------------------- |
#|0 | `0x0000`          | Reserved Media description          |
#|1 | `0x0000`          | Reserved                            |
#|x | `0x0002`          | First uasble cluster                |
#|2 | `0x0003`          | Second uasble cluster               |
#|4.| `0x0004`–`0xFFEF` | Next cluster number in chain        |
#|x | `0xFFF0`–`0xFFF6` | Reserved values                     |
#|x | `0xFFF7`          | Bad cluster                         |
#|x | `0xFFF8`–`0xFFFF` | End of file (EOF marker)            |

# FATEntryOffset = N * 2
# Which sector contained this FAT entry:
# FATSector = ReservedSectors + (FATEntryOffset / BytesPerSector)
# OffsetInSector = FATEntryOffset % BytesPerSector

# root_dir_sector_start = reserved_sectors + (num_FATs * sectors_per_FAT)
# root_dir_sectors = RootEntryCount * 32 + BytesPerSector -1 )/ BytesPerSector
# FirstDataSector = root_dir_sector_start + root_dir_sectors 
# FirstSectorOfCluster(N)=FirstDataSector + (N - 2) * SectorsPerCluster







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


# sector 0:
# EB3C904253442020342E3400024001000200020000F000012000FF000000000060FF3F00000029091C76314E4F204E414D45202020204641543136202020FA31C08ED0BC007CFB8ED8E800005E83C619BB0700FCAC84C07406B40ECD10EBF530E4CD16CD190D0A4E6F6E2D73797374656D206469736B0D0A507265737320616E79206B657920746F207265626F6F740D0A000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055AA

# raw root_dir_sector_start:
#42300030000000FFFFFFFF0F0021FFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF012E00530070006F0074000F00216C0069006700680074002D0000005600310053504F544C497E312020201200591AA44E5B4E5B00001AA44E5B020000000000412E0066007300650076000F00DA65006E0074007300640000000000FFFFFFFF46534556454E7E3120202012009B7AA6625B625B00007AA6625B0400000000004D555349432020205741562018277D924E5B625B00007D924E5BBD00C4E10F00412E005F006D00750073000F004C690063002E0077006100760000000000FFFF5F4D5553497E31205741562200280CB24F5B625B00000CB24F5BBC0000100000412E0054007200610073000F00256800650073000000FFFFFFFF0000FFFFFFFF5452415348457E312020201200BBE1B14F5B4F5B0000E1B14F5B1B0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000B00�
#| Offset | Bytes                     | Meaning                                              |
#| ------ | ------------------------- | ---------------------------------------------------- |
#| 00–07  | `4D 55 53 49 43 20 20 20` | “MUSIC   ”                                           |
#| 08–0A  | `57 41 56`                | “WAV”                                                |
#| 0B     | `20`                      | Attribute 0x20 → normal file                         |
#| 0C–0D  | `18 27`                   | creation time/date (not relevant now)                |
#| 1A–1B  | `BD 00`                   | **First cluster = 0x00BD = 189 = 10111101 **         |
#| 1C–1F  | `C4 E1 0F 00`             | **File size = 0x000FE1C4 = 651,076 bytes (~636 KB)** |



# file_cluster_start_number
# bytes_per_sector
# sectors_per_cluster
# root_entries
# root_dir_sectors
# file first sector
# {00BD}[0200][40][0200][43FF](7434) 


#sudo dd if=/dev/disk2 bs=512 skip=12513 count=1 |hexdump -C
#512 bytes transferred in 0.001376 secs (372116 bytes/sec)
#00000000  52 49 46 46 bc e1 0f 00  57 41 56 45 66 6d 74 20  |RIFF....WAVEfmt |
#00000010  10 00 00 00 01 00 02 00  44 ac 00 00 10 b1 02 00  |........D.......|
#00000020  04 00 10 00 64 61 74 61  98 e1 0f 00 3d f7 fb f6  |....data....=...|
#00000030  f7 f7 3e f7 b7 f8 83 f7  7b f9 cc f7 3e fa 1c f8  |..>.....{...>...|
#00000040  fd fa 74 f8 b5 fb d5 f8  62 fc 45 f9 ff fc c6 f9  |..t.....b.E.....|
#00000050  8a fd 5a fa 05 fe fb fa  71 fe a2 fb d0 fe 49 fc  |..Z.....q.....I.|
#00000060  25 ff e8 fc 76 ff 78 fd  cc ff f3 fd 2d 00 58 fe  |%...v.x.....-.X.|
#00000070  9c 00 a9 fe 19 01 e8 fe  a6 01 18 ff 44 02 42 ff  |............D.B.|
#00000080  f0 02 6d ff a1 03 a2 ff  53 04 e5 ff 04 05 38 00  |..m.....S.....8.|
#00000090  ad 05 9b 00 49 06 0b 01  d5 06 85 01 51 07 01 02  |....I.......Q...|
#000000a0  c1 07 7d 02 24 08 f9 02  7a 08 74 03 c3 08 ec 03  |..}.$...z.t.....|
#000000b0  ff 08 64 04 2c 09 e0 04  49 09 60 05 59 09 e2 05  |..d.,...I.`.Y...|
#000000c0  60 09 63 06 5e 09 e1 06  53 09 58 07 41 09 c2 07  |`.c.^...S.X.A...|
#000000d0  2b 09 1a 08 14 09 5d 08  f9 08 8c 08 da 08 aa 08  |+.....].........|
#000000e0  b8 08 b7 08 94 08 b5 08  6b 08 a7 08 3d 08 95 08  |........k...=...|
#000000f0  0a 08 82 08 d3 07 71 08  97 07 64 08 56 07 5d 08  |......q...d.V.].|
#00000100  12 07 5f 08 cb 06 6a 08  7d 06 7c 08 26 06 95 08  |.._...j.}.|.&...|
#00000110  c7 05 b5 08 5f 05 d9 08  e9 04 f8 08 5f 04 0b 09  |...._......._...|
#00000120  bf 03 0d 09 0a 03 fb 08  3c 02 ce 08 55 01 80 08  |........<...U...|
#00000130  56 00 08 08 49 ff 64 07  36 fe 93 06 26 fd 92 05  |V...I.d.6...&...|
#00000140  1f fc 62 04 2a fb 06 03  52 fa 84 01 9b f9 e6 ff  |..b.*...R.......|
#00000150  08 f9 3a fe 97 f8 8e fc  47 f8 f0 fa 12 f8 6b f9  |..:.....G.....k.|
#00000160  ef f7 0a f8 d6 f7 d4 f6  bc f7 ce f5 98 f7 f9 f4  |................|
#00000170  68 f7 51 f4 29 f7 d1 f3  da f6 73 f3 80 f6 2f f3  |h.Q.).....s.../.|
#00000180  22 f6 01 f3 ca f5 e5 f2  7e f5 db f2 41 f5 e5 f2  |".......~...A...|
#00000190  16 f5 ff f2 05 f5 2c f3  10 f5 6d f3 37 f5 c2 f3  |......,...m.7...|
#000001a0  76 f5 26 f4 c9 f5 94 f4  30 f6 08 f5 ac f6 81 f5  |v.&.....0.......|
#000001b0  37 f7 f9 f5 ce f7 6b f6  69 f8 d5 f6 08 f9 37 f7  |7.....k.i.....7.|
#000001c0  a6 f9 96 f7 3e fa f6 f7  cb fa 5d f8 4a fb d2 f8  |....>.....].J...|
#000001d0  b9 fb 58 f9 19 fc ef f9  67 fc 97 fa a0 fc 49 fb  |..X.....g.....I.|
#000001e0  c5 fc 01 fc db fc b8 fc  e8 fc 67 fd f5 fc 09 fe  |..........g.....|
#000001f0  07 fd 9c fe 27 fd 21 ff  58 fd 9b ff 9d fd 0c 00  |....'.!.X.......|
# Minimal SDRAM test
.section .text
.globl _start

_start:
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
