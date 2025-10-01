.section .text
.globl _start

_start:
    addi a0, x0, 5            # Put the argument (5) into the first argument register, a0.
    addi a1, x0, 10           # Put the right result (10) into a1.
    lui t0, 2           # Put 0x2000 to t0 for UART address hi20
    jal ra, add_five    # Call the function.
    beq a0, a1, print_p # The return value is now in a0. a0 should be 10.
print_f:
    addi t1, x0, 70         # ASCII F
    sd t1, 4(t0)
print_p:
    addi t1, x0, 80         # ASCII P
    sd t1, 4(t0)
hang:
    j hang
add_five:
    addi a0, a0, 5      # a0 = a0 + 5. (5 + 5 = 10). The result is now in a0.
    ret                 # 'ret' is a pseudo-instruction for 'jalr x0, ra, 0'.
