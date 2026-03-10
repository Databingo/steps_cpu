.section .text
.globl _start
_start:

    li x1, 0x2004
    la x5, msg
    lb x6, 0(x5)
    j _start


.section .data
msg:
    .string "Hello"

