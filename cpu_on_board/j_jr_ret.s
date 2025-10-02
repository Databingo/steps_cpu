# RISC-V Assembly: 'j', 'jr', 'ret' Test (Definitive Pure Version)
# Goal: Verify assembler expansion of j, jr, and ret without using 'li'.
# Instructions used: j, jr, ret (under test), and all previously verified helpers.

.section .text
.globl _start

_start:                     # Addr 0x00
    lui t0, 0x2
    addi t0, t0, 4          # Addr 0x04. UART t0 = 0x2004.
    j main_test_routine     # Addr 0x08.

fail_loop_1:                # Addr 0x0C
    beq x0, x0, fail_loop_1
my_function:                # Addr 0x10
    ret

main_test_routine:          # Addr 0x14
    jal ra, my_function
    lui t1 0x1
    addi t1, t1, 44       # Addr 0x18. Load the REAL address of 'pass'.
    jr t1                   # Addr 0x1C. Jump to address 44 + ram base 0x1000

fail_loop_2:                # Addr 0x20
    beq x0, x0, fail_loop_2
pass:                       # Addr 0x24
    addi t1, x0, 80         # ASCII 'P'
    sd t1, 0(t0)            # Write 'P' to UART.
    
pass_loop:
    
