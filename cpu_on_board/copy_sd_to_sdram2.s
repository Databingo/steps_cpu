#`define Sdc_base  32'h0000_3000 (3000-31ff 512 bytes index) sd_cache 
#`define Sdc_addr  32'h0000_3200
#`define Sdc_read  32'h0000_3204
#`define Sdc_write 32'h0000_3208
#`define Sdc_ready 32'h0000_3220
#`define Sdc_dirty 32'h0000_3224
#`define Sdc_avail 32'h0000_3228
# UART 0x2004

.section .text
.globl _start
_start:
    la x5, sbi 
    jal print_string
end:
    j end

print_string:
    li x1, 0x2004
print:
    lb x6, 0(x5)
    beq x6, x0, stop_print
    sb x6, 0(x1)
    addi x5, x5, 1
    j print
stop_print:
    ret

.section .data
msg:
    .string "Hello"
sbi:
    .string "I'm Opensbi"

