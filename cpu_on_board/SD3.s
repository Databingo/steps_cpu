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


# -- Compute Root Dir Start sector
# root_dir_start_sector = reserved_sectors + (num_fats * sectors_per_fat16) # s2 + s3 * s5
mul t4, s3, s5
add t4, t4, s2
mv s6, t4     # s6 = root_start_sector

# -- Read Root Dir first sector --
mv a2, s6
jal sd_read_sector

li t1, 66 # B
sw t1, 0(t0)     # print

# -- Scan Entries --
# entries_per_sector = bytes_per_sector / 32 -> srli 5
srli s7, s0, 5 # s7 = entries_per_sector (512/32=16)
li s8, 0       # s8 = entry_index

# attribute at 0x0B(11)
#| Attribute | Meaning               | Example entry        |
#| :-------: | :-------------------- | :------------------- |
#|   `0x0F`  | Long file name (LFN)  | `xx xx xx xx ... 0F` |
#|   `0x20`  | Archive (normal file) | `"MUSIC   WAV"`      |
#|   `0x10`  | Directory             | `"FOLDER  "`         |
#|   `0x08`  | Volume label          | `"NO NAME "`         |
#|   `0x00`  | Unused entry          | empty/deleted        |

#| Bit | Mask   | Meaning          |
#| --- | ------ | ---------------- |
#| 0   | `0x01` | Read-only        |
#| 1   | `0x02` | Hidden           |
#| 2   | `0x04` | System           |
#| 3   | `0x08` | **Volume label** |
#| 4   | `0x10` | Subdirectory     |
#| 5   | `0x20` | Archive          |
#| 6   | `0x40` | Device (unused)  |
#| 7   | `0x80` | Unused           |
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

# attribute at +11
lw t5, 11(t3)
li t1, 0x0F
beq t5, t1, next_entry # 0x0F LFN entry, skip

andi t6, t5, 0x08
bne t6, x0, next_entry # Bit 3 set Volume lable, skip 

# print 8.3 name
li a3, 0 # a3 = name char index
li a6, 8 # a6 = exit char index
print_name_loop:
add a4, t3, a3 # a4 = name char address
lw a5, 0(a4)   # a5 = name char
sw a5, 0(t0)
addi a3, a3, 1
blt a3, a6, print_name_loop

next_entry:
addi s8, s8, 1
j entry_loop

done_entries:
li t1, 90  # Z
sw t1, 0(t0)
j done_entries


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


# Entry of Root Directory Sector
#| Offset | Size    | Field             | Description                                           |
#| ------ | ------- | ----------------- | ----------------------------------------------------- |
#| `0x00` | 8 bytes | **Name**          | File or directory name (padded with spaces `' '`)     |
#| `0x08` | 3 bytes | **Extension**     | File extension (padded with spaces `' '`)             |
#| `0x0B` | 1 byte  | **Attribute**     | File attributes (bits for read-only, directory, etc.) |
#| `0x1A` | 2 bytes | **First cluster** | Starting cluster number                               |
#| `0x1C` | 4 bytes | **File size**     | In bytes                                              |
