#`define Sdc_base  32'h0000_3000 (3000-31fc 128*32 = 512 bytes readed)
#`define Sdc_addr  32'h0000_3200
#`define Sdc_read  32'h0000_3204
#`define Sdc_write 32'h0000_3208
#`define Sdc_ready 32'h0000_3220
#`define Sdc_dirty 32'h0000_3224
#`define Sdc_avail 32'h0000_3228

.globl _start
_start:

# Get UART address (0x2004) into t6.
lui t0, 0x2
addi t0, t0, 4      # t0 = 0x2004

# SD base
lui a1, 0x3         # a1 = 0x3000 base


sd_ready:
lw a2, 0x220(a1)    # a2 0x3220 ready
beq a2, x0, sd_ready

addi t1, x0, 65  # A
sw t1, 0(t0)     # print

# Sector address value to address 0x3200
sw x0, 0x200(a1)

# Trigger read at 0x3204
addi a3, x0, 1
sw a3, 0x204(a1)

sd_ready_2:
lw a2, 0x220(a1)    # a2 0x3220 ready
beq a2, x0, sd_ready_2

addi t1, x0, 66  # B
sw t1, 0(t0)     # print

avail:
lw a4, 0x228(a1)    # a2 0x3228 byte_avaible
lw a2, 0x228(a1)    # a2 0x3228 byte_avaible
beq a2, x4, avail

addi t1, x0, 67  # C
sw t1, 0(t0)     # print

lw t2, 0(a1)           # load first byte at 0x3000
andi t2, t2, 0xFF   # Isolate byte value

srli t3, t2, 4      # get high nibble
addi t3, t3, 55     # 10 is "A" ascii 65 ..
sw t3, 0(t0)

andi t4, t2, 0x0F      # get low nibble
addi t4, t4, 55        # 10 is "A" ascii 65 ..
sw t4, 0(t0)






