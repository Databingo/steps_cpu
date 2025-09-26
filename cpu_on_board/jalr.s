_start:
    jal ra, my_subroutine
after_call:
    addi a0, x0, 75  # ASCII for 'K'
    lui  t1, 0x2
    sd   a0, 4(t1)
    j hang
my_subroutine:
    addi a0, x0, 79  # ASCII for 'O'
    lui  t1, 0x2
    sd   a0, 4(t1)
    jalr x0, 0(ra)
hang:
    j hang
