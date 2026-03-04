##// startup.s
#
#.section .text
#.global _start
#.global timer_handler
#
#_start:
#    #// Set stack pointer
#    la sp, stack_top
#    
#    #// Set up mtvec to point to trap_handler
#    csrw mtvec, t0
#
#    #// Enable timer interrupts in mie (Machine Interrupt Enable)
#    li t0, 0x80
#    csrs mie, t0
#
#    #// Enable global interrupts in mstatus
#    li t0, 0x80
#    csrs mstatus, t0
#
#    #// Jump to main
#    call main
#
#trap_handler:
#    #// Read mcause to determine the interrupt type
#    csrr t0, mcause
#   
#    #// Check if the cause is a timer interrupt (0x8000000000000007) 
#    beq t0, t1, timer_interrupt
#    
#    #// If not timer interrupt, just return
#    mret
#
#timer_interrupt:
#    #// Call time handler
#    call timer_handler
#
#    #// Return from trap
#    mret
#
#.section .bss  #// 未初始化的全局变量
#.balign 4  #// 补全到 4 倍数地址
#stack_top:
#    .space 1024 #// 1KB stack


.section .init

.option norvc

.type start, @function
.global start
start:
    .cfi_startproc

.option push
.option norelax
    la gp, global_pointer
.option pop

    csrw satp, zero
    la sp, stack_top
    la t5, bss_start
    la t6, bss_end
bss_clear:
    sd zero, (t5)
    addi t5, t5, 8
    bltu t5, t6, bss_clear

    la t0, kmain
    csrw mepc, t0
    tail kmain
    .cfi_endproc

.end











