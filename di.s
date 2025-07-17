# di.s
.global _start

.section .rodata
msg:
    .string "Hello from RISC-V on FreeBSD!\n"
.set msg_len, . - msg

.section .text
_start:
    # write(stdout, msg, msg_len)
    li      a7, 4
    li      a0, 1
    la      a1, msg
    li      a2, msg_len
    ecall

    # exit(0)
    li      a7, 1
    li      a0, 0
    ecall
