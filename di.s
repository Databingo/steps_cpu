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
#    # Load the address of msg into t0 (a0 for syscall)
#    # 'la' is a pseudo-instruction handled by assembler/linker
#    la      a1, msg
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
    li      a7, 4          # write syscall number = 4
    li      a0, 1           # fd = 1 (stdout)
    la      a1, msg
    li      a2, 2          # length = 13 (bytes in "H\n")
    ecall                   # Make the system call

    # Prepare for exit(0) syscall
    li      a7, 1          # exit syscall number = 1
    li      a0, 0           # exit code 0
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
