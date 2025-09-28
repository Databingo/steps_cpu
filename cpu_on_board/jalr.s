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

_start: 
    jal t0, get_pc_helper
get_pc_helper: 
    addi t0, t0, 24   # t0 now holds the absolute address of 'target_address'
    jalr ra, 0(t0)
after_jump: 
    addi a0, x0, 80     # ASCII for 'P'
    lui  t1, 0x2
    sd   a0, 4(t1)
    j hang
target_address: 
    ret # This is `jalr x0, 0(ra)`
hang: 
    j hang




#-------------
# jalr_offset_test.s
# Goal: Prove that 'jalr' correctly calculates the target address as rs1 + offset.
# It will jump to 'base_label + 8', skipping a "Fail" instruction.
# Expected UART Output: "P" (for Pass)

#_start:
#    jal t0, get_pc_helper
#get_pc_helper:
#    addi t0, t0, 16   # t0 now holds the absolute address of 'base_label'
#    jalr x0, 8(t0)
#    # This part should not be executed.
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
