.global _start

.section .data
msg: 
   .string "ASM INIT STARTING\n"
dev_path: 
   .string "/dev/hvc0"
buf: 
   .word 0


.section .text
_start:
    # openat(AT_FDCWD, "/dev/hvc0", O_RDWR)
    li a0, -100 # AT_FDCWD 
    la a1, dev_path
    li a2, 2    # O_RDWR
    li a7, 56   # syscall openat
    ecall 
 
    mv t0, a0 # save ecall returned value

    # if t0 negative, open failed
    bltz t0, open_failed_barcode
    
    # dup2(fd, 0) - stdin
    mv a0, t0
    li a1, 0
    li a7, 24
    ecall
   
    # dup2(fd, 1) - stdout
    mv a0, t0
    li a1, 1
    li a7, 24
    ecall


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

open_failed_barcode:
    addi x0, x0, 0xee  # 0x0ee00013
    addi x0, x0, 0xff  # 0x0ff00013
    j open_failed_barcode

