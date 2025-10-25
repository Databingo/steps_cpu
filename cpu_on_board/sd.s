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

sd_ready:
lui a1, 0x3
addi a1, a1, 0x220  # ready map
lw a2, 0(a1)
addi a3, x0, 1
bne a2, a3, sd_ready

sw a2, 0(t6) # print
