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

# Set mstatus.MIE
csrr t0, mstatus
ori t0, t0, 1000
csrw mstatus, t0

# Drop to S-mode (MPP=01)
csrr t0, mstatus
li t1, 0011111111111 
and t0, t0, t1
li t1, 100000000000
or t0, t0, t1
csrw mstatus, t0

# Set mepc to OS entry
la t0, os_entry
csrw mepc, t0

# mret
mret

os_entry:
# In S-mode set stvec
la t0, s_trap_handler
csrw stvec, t0

# Enable SIE
csrr t0, sstatus
ori t0, t0, 10
csrw sstatus, t0

# Test ecall
ecall 

# Loop
j os_entry

s_trap_handler:
csrr t0, scause
csrr t1, sepc
addi t1, t1, 4
csrw sepc, t1
sret

