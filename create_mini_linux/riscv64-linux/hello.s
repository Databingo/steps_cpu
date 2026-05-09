.global _start

.section .text
_start:
    # mkdirat(AT_FDCWD, "/dev", 0755)
    li a0, -100
    la a1, dev_path
    li a2, 493
    li a7, 34 # syscall mkdir
    ecall 
   #bltz a0, fail_mkdir


    # mount devtmpfs to /dev
    la a0, devtmpfs_str
    la a1, dev_path
    la a2, devtmpfs_str
    li a3, 0
    li a4, 0
    li a7, 40 # syscall mount
    ecall 
    bltz a0, fail_mount

    # openat(AT_FDCWD, "/dev/console", O_RDWR)
    # open for stdin fd 0
    li a0, -100 # AT_FDCWD 
    la a1, console_path
    li a2, 2    # O_RDWR
    li a7, 56   # syscall openat
    ecall 
    bltz a0, fail_open  
   #mv s1, a0   # save ecall returned value
   #bltz s1, fail_open  # if s1 negative, open failed
     
    # open for stdout fd 1
    li a0, -100 # AT_FDCWD 
    la a1, console_path
    li a2, 2    # O_RDWR
    li a7, 56   # syscall openat
    ecall 
    bltz a0, fail_open  
     

    # open for stderr fd 2
    li a0, -100 # AT_FDCWD 
    la a1, console_path
    li a2, 2    # O_RDWR
    li a7, 56   # syscall openat
    ecall 
    bltz a0, fail_open  

   ## dup3(fd, 0, 0) - stdin
   #mv a0, s1 
   #li a1, 0
   #li a2, 0
   #li a7, 24 # syscall dup3
   #ecall
   #bltz a0, fail_dup
 
   ## dup2(fd, 1, 0) - stdout
   #mv a0, s1 
   #li a1, 1
   #li a2, 0
   #li a7, 24
   #ecall
   #bltz a0, fail_dup

    # write(1, msg, 18) # welcome
    li a0, 1            # fd = 1
    la a1, msg          # buf
    li a2, 18           # len
    li a7, 64           # syscall write
    ecall

loop:
   ## write(1, buf, 1)
   #li a0, 1            # fd = 1
   #la a1, buf          # buf
   #li a2, 1            # len
   #li a7, 64           # syscall write
   #ecall

    # read(0, buf, 1)   # read keypress
    li a0, 0            # fd = 0
    la a1, buf          # buf
    li a2, 1            # len
    li a7, 63           # syscall read
    ecall

    
    # Sign
    addi x0, x0, 0x11  # 0x01100013
    addi x0, x0, 0x22  # 0x02200013
    addi x0, x0, 0x33  # 0x03300013

    j loop

fail_mkdir:
    addi x0, x0, 0xaa  
    j fail_mkdir
fail_mount:
    addi x0, x0, 0xbb  
    j fail_mount
fail_open:
    addi x0, x0, 0xcc  
    j fail_open
fail_dup:
    addi x0, x0, 0xdd  
    j fail_dup



.section .data
msg: 
   .string "ASM iNIT STARTING\n"
dev_path: 
   .string "/dev"
devtmpfs_str: 
   .string "devtmpfs"
console_path: 
   .string "/dev/hvc0"
.align 3
buf: 
   .word 0


