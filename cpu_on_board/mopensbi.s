# set mtvec to trap handler
la t0, tran_handler
csrw mtvec, t0

tran_handler:
    mret

