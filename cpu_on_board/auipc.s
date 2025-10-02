# RISC-V Assembly: 'auipc' Test (Simple & Pure Version)
# Goal: Verify that auipc correctly calculates PC + immediate.
# Instructions used: auipc (under test), addi, jalr, sd, beq.

.section .text
.globl _start

# We need to know the address of the 'pass' label. Let's calculate:
# _start:       0x00
# lui:          0x00
# addi:         0x04
# auipc:        0x08
# addi:         0x0C
# jalr:         0x10
# fail_loop:    0x14
# pass:         0x18 (decimal 24)

_start:
    lui t0, 0x2
    addi t0, t0, 4      # t0 = 0x2004 (UART Address)
    auipc t1, 0         # t1 = PC + 0 = 0x08.
    addi t1, t1, 16     # t1 should now hold the absolute address of 'pass' 24.
    jalr x0, 0(t1)

fail_loop:
    beq x0, x0, fail_loop

pass:
    addi t2, x0, 80         # ASCII 'P'
    sd t2, 0(t0)        # Print 'P'.

pass_loop:
    beq x0, x0, pass_loop
