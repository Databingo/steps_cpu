.global trap_handler
trap_handler:
    # 1. save re to stack
    # addi sp, sp, -256
    # sd ra, 0(sp)
    # sd t0, 8(sp)
    # 2. Read mcasue
   #csrr t0, mcause
    # 3. Check & Dispatch
   #li t1, 0x800000000000000B
   #bne t0, t1, not_my_interrupt
handler_external_interrupt:
    # load key base address
   #li t0, 0x00002004
    # load data 
   #ld t1, 0(t0)
    ld t1, 0(x0)
    j end_of_trap
not_my_interrupt:
end_of_trap:
    # 4. restore re from stack
    # ld ra, 0(sp)
    # ld t0, 8(sp)
    # addi sp, sp, 256
    # 5. Return from trap
    mret
