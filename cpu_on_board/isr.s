    lui t1, 0x2
    #ld t0, 0(t1)
    addi t1, t1, 0x4
    #sd t0, 0(t1)

    li t3, 91 # [
    sb t3, 0(t0) # to plic
    mret
