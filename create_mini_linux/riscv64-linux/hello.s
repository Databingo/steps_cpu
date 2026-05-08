.section .text
.global _start

_start:
    # write(1, msg, 18)
    li a0, 1            # fd = 1
    la a1, msg          # buf
    li a2, 18           # len
    li a7, 64           # syscall write
    ecall

loop:
    # read(0, buf, 1)
    li a0, 0            # fd = 0
    la a1, buf          # buf
    li a2, 1            # len
    li a7, 63           # syscall read
    ecall

    # write(1, buf, 1)
    li a0, 1            # fd = 1
    la a1, buf          # buf
    li a2, 1            # len
    li a7, 64           # syscall write
    ecall

    j loop

.section .data
msg: .ascii "ASM INIT STARTING\n"
buf: .byte 0
