addi x3, x0, 3
add  x1, x3, x0 
add  x2, x0, x0 
csrrw x1, mscratch, x1  
csrrw x2, mscratch, x2  # now x2=x3 ms=0


addi x5, x0, 4
csrrs x2, mscratch, x2 
csrrs x5, mscratch, x5 
csrrw x7, mscratch, x7  


##csrrc x3, mscratch, x3  # save a0, a &temp pointer to a0; pointer was set by software
##csrrwi x3, mscratch, 29  # save a0, a &temp pointer to a0; pointer was set by software
##csrrwi x3, mscratch, 29  # save a0, a &temp pointer to a0; pointer was set by software
##csrrsi x3, mscratch, 29  # save a0, a &temp pointer to a0; pointer was set by software
##csrrci x3, mscratch, 29  # save a0, a &temp pointer to a0; pointer was set by software
##sw a1, 0(a0)            # save a1
##sw a2, 4(a0)            # save a2
##sw a3, 8(a0)            # save a3
