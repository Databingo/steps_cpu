.globl _start

.section .data
msg:
    .string "Hello, minimal ELF!\n"

.section .text
_start:
    # write(1, msg, 20)
    li      a0, 1          # fd = 1 (stdout)
    la      a1, msg        # buf = msg
    li      a2, 20         # count = 20 (length of string)
    li      a7, 4          # syscall: write (FreeBSD RISC-V)
    ecall

    # exit(0)
    li      a0, 0
    li      a7, 93         # syscall: exit
    ecall

