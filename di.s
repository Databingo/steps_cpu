# Directive: Define global symbols (visible to linker)
.global main
.global msg

# Directive: Switch to data section for initialized data
.section .data
msg:
    # Directive: Define a null-terminated string
    .string "Hello RISC-V\n"
.section .text
main:
    # --- Write the string ---
    li      a7, 4          # syscall: write
    li      a0, 1          # fd: stdout
    la      a1, msg
    li      a2, 13
    ecall

    # --- Force a flush of stdout ---
    li      a7, 82         # syscall: fsync (FreeBSD syscall number)
    li      a0, 1          # fd: stdout (the same one we wrote to)
    ecall

    # --- Exit cleanly ---
    li      a7, 1          # syscall: exit
    li      a0, 0
    ecall



