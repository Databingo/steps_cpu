    .section .rodata
msg:
    .asciz "Hello from assembly main!\n"

    .text
    .globl main
main:
    # write(1, msg, 24)
    li      a0, 1          # fd = 1 (stdout)
    la      a1, msg        # buf = msg
    li      a2, 24         # count = 24
    li      a7, 4          # syscall: write
    ecall

    # return 0
    li      a0, 0
    ret
