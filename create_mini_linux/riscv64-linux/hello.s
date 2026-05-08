.global _start

.section .data
msg: 
   .string "ASM INIT STARTING\n"
dev_path: 
   .string "/dev"
devtmpfs_str: 
   .string "devtmpfs"
console_path: 
   .string "/dev/console"
buf: 
   .word 0


.section .text
_start:
    # mount devtmpfs to /dev
    la a0, devtmpfs_str
    la a1, dev_path
    la a2, devtmpfs_str
    li a3, 0
    li a4, 0
    li a7, 40 # syscall mount
    ecall 

    # openat(AT_FDCWD, "/dev/console", O_RDWR)
    li a0, -100 # AT_FDCWD 
    la a1, console_path
    li a2, 2    # O_RDWR
    li a7, 56   # syscall openat
    ecall 
 
    mv s1, a0 # save ecall returned value

    # if s1 negative, open failed
    bltz s1, open_failed_barcode
    
    # dup3(fd, 0, 0) - stdin
    mv a0, s1 
    li a1, 0
    li a2, 0
    li a7, 24 # syscall dup3
    ecall
   
    # dup2(fd, 1, 0) - stdout
    mv a0, s1 
    li a1, 1
    li a2, 0
    li a7, 24
    ecall

    # write(1, msg, 18) # welcome
    li a0, 1            # fd = 1
    la a1, msg          # buf
    li a2, 18           # len
    li a7, 64           # syscall write
    ecall

loop:
    # read(0, buf, 1)   # read keypress
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

