# RISC-V Assembly: 'jal' Test (Jump then Link Verification)
# Goal: Verify both the PC-relative jump and link operations of jal.
# Instructions used: jal (under test), and all previously verified helpers.

.section .text
.globl _start

_start:                     # Addr 0x00
    # --- Setup Phase ---
    lui t0, 0x2
    addi t0, t0, 4          # Addr 0x04. UART t0 = 0x2004.
    jal x0, jump_target     # Addr 0x08.
jump_fail_loop:             # Addr 0x0C (12)
    beq x0, x0, jump_fail_loop
jump_target:                # Addr 0x10 (16)
    addi t2, x0, 74         # ASCII for 'J'
    sd t2, 0(t0)            # Write 'J' to UART.
link_test_start:            # Addr 0x18 (24)
    jal t3, link_target     # Jump to link_target, save PC+4 into t3.
link_success_return:        # Addr 0x1C (28)
    beq x0, x0, done        # All tests passed, just loop here.
link_fail_loop:             # Addr 0x20 (32)
    beq x0, x0, link_fail_loop
link_target:                
    lui t4, 1
    addi t4, t4, 28
    beq t3, t4, print_link_success
    beq x0, x0, link_fail_loop
print_link_success:
    addi t2, x0, 76         # ASCII 'L'
    sd t2, 0(t0)            # Print 'L' to UART.
    jalr x0, 0(t3)
done:
    beq x0, x0, done
