# save registers
csrrw a0, mscratch, a0  # save a0, a &temp pointer to a0; pointer was set by software
sw a1, 0(a0)            # save a1
sw a2, 4(a0)            # save a2
sw a3, 8(a0)            # save a3
sw a4, 12(a0)            # save a4
