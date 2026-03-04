.section .text
.globl _start

_start:
    # --- Setup Phase ---
    li t0, 0x2004       # UART address

    # Use 'li' to load a full 64-bit constant.
    li t1, 0x123456780ABCDEF0

    # Set answer
    lui  t3, 0x12345
    addi t3, t3, 0x678      # t3 = 0x12345678
    slli t3, t3, 32         # t3 should now be 0x12345678_00000000
    lui  t4, 0xABCE
    addi t4, t4, -272       # t4 = 0xABCE000 - 0x110 = 0x0ABCDEF0
    add t2, t3, t4          # t2 = 0x12345678_00000000 + 0x0ABCDEF0 = 0x12345678_0ABCDEF0

    beq t1, t2, pass
fail:
    beq x0, x0, fail

pass:
    li t1, 80               # ASCII for 'P'
    sd t1, 0(t0)            # Write 'P' to UART.
    
pass_loop:
    beq x0, x0, pass_loop
