# hello.s: A minimal RISC-V 64-bit program for FreeBSD.
# Prints "Hello, RISC-V on FreeBSD!\n" to standard output.

.section .data
# The string to be printed. .string automatically adds a null terminator,
# but we will calculate the length without it.
msg:
    .string "Hello, RISC-V on FreeBSD!\n"
# Calculate the length of the string at assembly time.
# 'end_msg' is a label at the end of the string.
# '.' represents the current address, so '.-msg' is the length.
msg_len = . - msg - 1 # Subtract 1 to exclude the null terminator.


.section .text
.global _start      # The entry point for the linker.

_start:
    # --- System call 1: write ---
    # ssize_t write(int fd, const void *buf, size_t count);
    # Syscall number for write on FreeBSD is 4.

    li a0, 1            # a0: argument 0, file descriptor (1 = stdout)
    la a1, msg          # a1: argument 1, pointer to the string (buffer)
    li a2, msg_len      # a2: argument 2, length of the string (count)
    li a7, 4            # a7: syscall number for sys_write

    ecall               # Make the system call to write to the screen

    # --- System call 2: exit ---
    # void exit(int status);
    # Syscall number for exit on FreeBSD is 1.

    li a0, 0            # a0: argument 0, exit status (0 = success)
    li a7, 1            # a7: syscall number for sys_exit

    ecall               # Make the system call to exit the program
