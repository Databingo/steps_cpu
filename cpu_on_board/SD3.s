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

# UART base (for print_char)
lui t0, 0x2
addi t0, t0, 4      # t0 = 0x2004

# SD controller base
lui a1, 0x3         # a1 = 0x3000 base

# -- Wait SD ready
sd_ready:
lw a2, 0x220(a1)    # a2 0x3220 ready
beq a2, x0, sd_ready

# -- Read Boot Sector 0 -- 
li a2, 0
jal sd_read_sector

li t1, 65        # A
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
mv s0, t2    # s0 = bytes_per_sector offset 0x0b-0x0c 2 bytes
 
# sectors per cluster offset 0x0d 1 byte
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
#jal print_sector

li t1, 66 # B
sw t1, 0(t0)     # print

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
mv t2, s10
jal print_hex_b
srli t2, t2, 8
jal print_hex_b
li t1, 125  # }
sw t1, 0(t0) # print



# s0 = bytes_per_sector
# s1 = sectors per cluster
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

# root_dir_sector_start = reserved_sectors + (num_FATs * sectors_per_FAT)
# root_dir_sectors = (RootEntryCount * 32 + BytesPerSector -1 )/ BytesPerSector
# FirstDataSector = root_dir_sector_start + root_dir_sectors 
# FirstSectorOfCluster(N)=FirstDataSector + (N - 2) * SectorsPerCluster

# calculate root_dir_sectors 
li t1, 32
mul t2, s4, t1
add t2, t2, s0
addi t2, t2, -1
div t3, t2, s0
mv s11, t3 # s11 = root_dir_sectors

# calculate first data sector
add t1, s6, s11

# calculate file's first sector
addi t2, s10, -2
mul t3, t2, s1
add t4, t1, t3 # t4 = file's first sector

# print file first sector
li t1, 123  # {
sw t1, 0(t0) # print
mv t2, t4
jal print_hex_b
srli t2, t2, 8
jal print_hex_b
li t1, 125  # }
sw t1, 0(t0) # print



# read & print
mv a2, t4
jal sd_read_sector
j print_sector



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







print_sector:
# print sector 0 512 bytes
li t1, 0   # byte index
li t6, 511 # max byte index
print_loop:
li a3, 32     # space 
sw a3, 0(t0)  # print start space per byte
add a4, a1, t1 
addi t1, t1, 1
lw t2, 0(a4)           # load byte at 0x3000 a1+t1
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
ret



# print_hex_b(t2)
print_hex_b:
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
ret



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



