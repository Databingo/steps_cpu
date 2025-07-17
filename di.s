# Define global main symbol
.global main

# Data section for initialized data
.section .data
msg:
    .string "test\n"  # String to print

# Text section for code
.section .text
main:
    # Save ra (return address) for FreeBSD ABI compliance
    addi    sp, sp, -16
    sd      ra, 8(sp)

    # write(1, msg, 5) syscall (FreeBSD: write = 4)
    li      a7, 4          # Syscall number for write
    li      a0, 1          # fd = 1 (stdout)
    la      a1, msg        # Address of "test\n"
    li      a2, 5          # Length of "test\n"
    ecall                  # Make system call

    # Restore ra and stack
    ld      ra, 8(sp)
    addi    sp, sp, 16

    # Return 0 (success) from main
    li      a0, 0
    ret                    # Return to libc's exit handler



