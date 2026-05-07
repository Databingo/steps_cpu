.global _start

.section .data
msg: 
   .string "ASM INIT STARTING\n"
buf: 
   .word 0


.section .text
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
    
    # Sign
    addi x0, x0, 0x11  # 0x01100013
    addi x0, x0, 0x22  # 0x02200013
    addi x0, x0, 0x33  # 0x03300013

    j loop

