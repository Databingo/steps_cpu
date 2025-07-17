.section .data
msg:    .asciz "Hello, RISC-V FreeBSD!\n"

.section .text
.global _start

_start:
    # a0 = file descriptor (1 = stdout)
    li      a0, 1

    # a1 = pointer to string
    la      a1, msg

    # a2 = length of string
    li      a2, 22  # length of "Hello, RISC-V FreeBSD!\n"

    # a7 = syscall number (write = 4 for FreeBSD)
    li      a7, 4

    ecall

    # exit(0)
    li      a0, 0      # exit code
    li      a7, 93     # syscall number for exit
    ecall
