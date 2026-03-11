.section .text
.globl _start
_start:

    li x1, 0x2004
    la x5, msg
    addi x2, x5, 5
print_string:
    lb x6, 0(x5)
    sb x6, 0(x1)
    addi x5, x5, 1
    bne x5, x2, print_string
end:
    j end


.section .data
msg:
    .string "Hello"

