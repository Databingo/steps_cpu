.section .text
.globl _start

_start:
    li sp, 0x1800       # Let's put the stack at the top of a small RAM region, e.g., 0x1800.
    li a0, 5            # Put the argument (5) into the first argument register, a0.
    li a1, 10           # Put the right result (10) into a1.
    lui t0, 2           # Put 0x2000 to t0 for UART address hi20
    jal ra, add_five    # Call the function.
    beq a0, a1, print_p # The return value is now in a0. a0 should be 10.
print_f:
    addi t1, x0, 70         # ASCII F
    sd t1, 4(t0)
print_p:
    addi t1, x0, 80         # ASCII P
    sd t1, 4(t0)
add_five:
    addi sp, sp, -8     # sp now points to 0x17F8. We have a frame of 8 bytes.
    sd ra, 0(sp)        # Store the value of 'ra' at the address pointed to by sp.
    addi a0, a0, 5      # a0 = a0 + 5. (5 + 5 = 10). The result is now in a0.
    ld ra, 0(sp)        # Load the value from address sp back into the 'ra' register.
    addi sp, sp, 8      # sp is now back at 0x1800.
    ret                 # 'ret' is a pseudo-instruction for 'jalr x0, ra, 0'.
