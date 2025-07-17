# Minimal RISC-V 64-bit assembly program to print a string on FreeBSD

.section .data
msg:    .ascii  "Hello, FreeBSD!\n"  # String to print
msg_len = . - msg                    # Length of the string

.section .text
.global _start

_start:
    # Prepare arguments for write syscall
    li a0, 1            # File descriptor 1 (stdout)
    la a1, msg          # Address of the string
    li a2, msg_len      # Length of the string
    li a7, 4            # Syscall number for write on FreeBSD
    ecall               # Make the syscall

    # Exit program
    li a0, 0            # Exit status 0
    li a7, 1            # Syscall number for exit on FreeBSD
    ecall               # Make the syscall
