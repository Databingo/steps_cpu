call pass_target
base_label:
    addi a0, x0, 70  # ASCII for 'F' for Fail
    lui t1, 0x2
    sw  a0, 4(t1)
    # This instruction is at base_label + 4. Also skipped.
    j hang
pass_target:
    # The `jalr` from _start should land EXACTLY here (base_label + 8).
    addi a0, x0, 80  # ASCII for 'P' for Pass
    lui t1, 0x2
    sw  a0, 4(t1)
hang:
    j hang
