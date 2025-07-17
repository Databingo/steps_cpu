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
    # ... your write syscall ...
    li      a7, 4
    li      a0, 1
    la      a1, msg
    li      a2, 13
    ecall

    # --- ADD THIS DELAY LOOP ---
    li      t0, 1000000   # Load a large number into a temporary register
delay_loop:
    addi    t0, t0, -1      # Decrement the counter
    bnez    t0, delay_loop  # If not zero, loop again
    # -------------------------

    # Prepare for exit(0) syscall
    li      a7, 1
    li      a0, 0
    ecall


