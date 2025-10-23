#`define Sdc_base  32'h0000_3000 (3000-31fc 128*32 = 512 bytes readed)
#`define Sdc_addr  32'h0000_3200
#`define Sdc_read  32'h0000_3204
#`define Sdc_write 32'h0000_3208
#`define Sdc_ready 32'h0000_3220
#`define Sdc_dirty 32'h0000_3224
.globl _start
_start:

# Get UART address (0x2004) into t6.
lui t6, 0x2
addi t6, t6, 4      # t0 = 0x2004

lui t0, 0x3
addi t0, t0, 0x200  # address operator 0x3200   
addi t1, x0, 0 # sector 0
sw t1, 0(t0)  # set address setctor 0

lui t3, 0x3
addi t3, t3, 0x204  # read operator 0x3204
addi t2, x0, 0x1
sw t2, 0(t3) # do a read


cache_ready:
lui a1, 0x3
addi a1, a1, 0x220  # ready operator 0x3220
lw a2, 0(a1)
addi a3, x0, 1
bne a2, a3, cache_ready


lui t4, 0x3
addi t4, t4, 0x000  # read cache
lw t5, 0(t4) # read 8 bytes


sw t5, 0(t6) # print
