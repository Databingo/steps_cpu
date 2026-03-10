.section .text
.globl _start
_start:

    la x5, msg
    lb x6, 0(x5)
    j _start


.section .data
msg:
    .string "Hello"

