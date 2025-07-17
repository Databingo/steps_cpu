# di.s: A minimal "Hello, world" for FreeBSD/riscv64

# The .global directive makes _start visible to the linker.
.global _start

# The .section .rodata is for "read-only data" like constant strings.
.section .rodata
msg:
    .string "Hello from RISC-V on FreeBSD!\n"
    # Let the assembler calculate the length for us.
    # '.' means the current address. So . - msg is the length.
    .set msg_len, . - msg

# The .section .text contains the executable code.
.section .text
_start:
    # System call to write(stdout, msg, msg_len)
    # FreeBSD/riscv64 uses the same ABI as Linux for syscalls:
    # a7 = syscall number
    # a0, a1, a2, ... = arguments
    li      a7, 4           # syscall number for write() is 4
    li      a0, 1           # a0 = file descriptor 1 (stdout)
    la      a1, msg         # a1 = address of the string
    li      a2, msg_len     # a2 = length of the string
    ecall                   # Make the system call

    # System call to exit(0)
    li      a7, 1           # syscall number for exit() is 1
    li      a0, 0           # a0 = exit code 0 (success)
    ecall                   # Make the system call

# There is no 'ret' because the exit syscall never returns.
# The program terminates here.
