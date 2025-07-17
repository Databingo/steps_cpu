.globl _start

    .section .data
msg:
    .string "Hello, syscall!\n"

    .section .text
_start:
    li      a0, 1          # fd = 1 (stdout)
    la      a1, msg        # buf = msg
    li      a2, 15         # count = 15 (length of string)
    li      a7, 4          # syscall: write (FreeBSD RISC-V)
    ecall

    li      a0, 0          # exit code
    li      a7, 93         # syscall: exit
    ecall
