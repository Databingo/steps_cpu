# Directive: Define global symbols (visible to linker)
.global _start
.global my_message

# Directive: Switch to data section for initialized data
.section .data
my_message:
    # Directive: Define a null-terminated string
    .string "Hello RISC-V\n"

# Directive: Switch to text section for code
.section .text
_start:
#    # Load the address of my_message into t0 (a0 for syscall)
#    # 'la' is a pseudo-instruction handled by assembler/linker
#    la      a1, my_message
#    nop
#    call _start
#    tail _start
#    j _start
#    jr x9
#    jal _start
#    jalr x9
#    mv x1, x2
#    not x1, x3
#    lb x1, _start
#    lh x1, _start
#    lw x1, _start
#    ld x1, _start
#    sb x1, _start, x2
#    sh x1, _start, x2
#    sw x1, _start, x2
#    sd x1, _start, x2

    # Prepare for write(1, message_addr, length) syscall (Linux RV64)
    li      a0, 1           # fd = 1 (stdout)
    li      a2, 13          # length = 13 (bytes in "Hello RISC-V\n")
    li      a7, 64          # write syscall number = 64
    ecall                   # Make the system call

    # Prepare for exit(0) syscall
    li      a0, 0           # exit code 0
    li      a7, 93          # exit syscall number = 93
    ecall                   # Make the system call


#auipc a1, 0
#addi  a1, a1, 0
#li    a0, 1
#li    a2, 1
#li    a7, 4
#ecall
#li    a0, 0
#li    a7, 1 
#ecall
