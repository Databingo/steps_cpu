# set mtvec to trap handler
la t0, tran_handler
csrw mtvec, t0

tran_handler:
    mret

# Delegate exceptions/interrupts
li t0, 0xb1af # medeleg
csrw medeleg, t0
li t0, 0x222  # mideleg
csrw mideleg, t0

# Enable interrupts (mie)
li t0, 100010001000 # MSIE, MTIE, MEIE
csrw mie, t0

