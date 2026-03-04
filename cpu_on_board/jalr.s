#_start:
#    jal ra, my_subroutine
#after_call:
#    addi a0, x0, 75  # ASCII for 'K'
#    lui  t1, 0x2
#    sd   a0, 4(t1)
#    j hang
#my_subroutine:
#    addi a0, x0, 79  # ASCII for 'O'
#    lui  t1, 0x2
#    sd   a0, 4(t1)
#    jalr x0, 0(ra)
#hang:
#    j hang

# -----------------
# jalr_link_test.s
# Goal: Prove that 'jalr' saves a link address to rd when rd != x0.
# It jumps to 'target_address' and should save the address of 'after_jump' in 'ra'.
# It then proves this by using 'ra' to return correctly.
# Expected UART Output: "P" (for Pass)

#_start: 
#    jal t0, get_pc_helper
#get_pc_helper: 
#    addi t0, t0, 24   # t0 now holds the absolute address of 'target_address'
#    jalr ra, 0(t0)
#after_jump: 
#    addi a0, x0, 80     # ASCII for 'P'
#    lui  t1, 0x2
#    sd   a0, 4(t1)
#    j hang
#target_address: 
#    ret # This is `jalr x0, 0(ra)`
#hang: 
#    j hang




#-------------
# jalr_offset_test.s
# Goal: Prove that 'jalr' correctly calculates the target address as rs1 + offset.
# It will jump to 'base_label + 8', skipping a "Fail" instruction.
# Expected UART Output: "P" (for Pass)

#_start:
#    jal t0, get_pc_helper
#get_pc_helper:
#    addi t0, t0, 28   # t0 now holds the absolute address of 'base_target'
#    jalr x0, 0(t0)
#    j hang
#base_label:
#    addi a0, x0, 70  # ASCII for 'F' for Fail
#    lui t1, 0x2
#    sd  a0, 4(t1)
#    # This instruction is at base_label + 4. Also skipped.
#    j hang
#pass_target:
#    # The `jalr` from _start should land EXACTLY here (base_label + 8).
#    addi a0, x0, 80  # ASCII for 'P' for Pass
#    lui t1, 0x2
#    sd  a0, 4(t1)
#hang:
#    j hang




# RISC-V Assembly: 'jalr' Test (Jump then Link Verification)
# Goal: Verify both the jump and link operations of jalr separately.
# Instructions used: jalr (under test), and all previously verified helpers.

.section .text
.globl _start

_start:
    lui t0, 0x2
    addi t0, t0, 4          # UART t0 = 0x2004
    lui t5, 1
    addi t1, t5, 24
    jalr x0, 0(t1)          # Jump to address 0x1000 + 24, 0x1000 is ram base

jump_fail_loop:
    beq x0, x0, jump_fail_loop # Should be skipped.

jump_target:                  # Address should be 20
    addi t2, x0, 74           # ASCII for 'J'
    sd t2, 0(t0)              # Write 'J' to UART.

link_test_start:              # Part 2: Verify the LINK operation
    addi t1, t5, 48 
    jalr t3, 0(t1)            # Jump to link_target, save PC+4 into t3
    
link_success_return:          # Address should be 44
    beq x0, x0, done          # All tests passed, just loop here.

link_fail_loop:
    beq x0, x0, link_fail_loop

link_target:
    addi t4, t5, 40 # 2c. Manually construct the expected return address in t4.
    beq t3, t4, print_link_success # If they match, the link is correct.
    beq x0, x0, link_fail_loop # This is an unconditional jump to the fail loop.

print_link_success:
    addi t2, x0, 76         # ASCII for 'L'
    sd t2, 0(t0)            # Write 'L' to UART.
    jalr x0, 0(t3)          # Return to 'link_success_return'.

done:
    beq x0, x0, done
