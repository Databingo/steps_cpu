# Directive: Define global symbols (visible to linker)
.global main
.global msg

# Directive: Switch to data section for initialized data
.section .data
msg:
    # Directive: Define a null-terminated string
    .string "Hello RISC-V\n"

# Directive: Switch to text section for code
.section .text
main:
    # Prepare for write(1, message_addr, length) syscall (FreeBSD RV64)
    li      a7, 4          # write syscall number = 4
    li      a0, 1           # fd = 1 (stdout)
    la      a1, msg
    li      a2, 13          # length = 13 (bytes in "Hello RISC-V\n")
    ecall                   # Make the system call
    
    # Check if write failed (return value < 0)
    bltz    a0, write_error
    
    # Prepare for exit(0) syscall
    li      a7, 1          # exit syscall number = 1
    li      a0, 0           # exit code 0
    ecall                   # Make the system call

write_error:
    # If write failed, exit with error code 1
    li      a7, 1          # exit syscall number = 1
    li      a0, 1           # exit code 1 (error)
    ecall                   # Make the system call
    ret
