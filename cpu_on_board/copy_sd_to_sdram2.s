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
    la t6, sbi 
    jal print_string
end:
    j end

print_string:
    li t1, 0x2004
print:
    lb t5, 0(t6)
    beq t5, x0, stop_print
    sb t5, 0(t1)
    addi t6, t6, 1
    j print
stop_print:
    ret

.section .data
msg:
    .string "Hello"
sbi:
    .string "I'm Opensbi"

