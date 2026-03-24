.section .data
# Strings for labeling output
t_amo_old:  
   .string "\nAMO_O:"
t_amo_new:  
   .string "\nAMO_N:"
t_sc_succ:  
   .string "\nSC_S?:"
t_sc_mem:   
   .string "\nSC_M:"
t_sc_fail:  
   .string "\nSC_F?:"

.section .text
.globl _start

_start:
    # 1. Setup Stack and UART
    li sp, 0x80001800   # Set stack in SDRAM (aligned to 0x80000000)
    li s11, 0x2004      # UART Data
    li s10, 0x2008      # UART Status
    
    # 2. Setup SD Card Registers
    li s1,  0x3000      # SD base
    li s2,  0x3200      # SD address
    li s3,  0x3204      # SD trigger read
    li s5,  0x3220      # SD ready
    li s6,  0x3228      # SD cache available

    # 3. Setup SDRAM Test Pointer (Now 0x80000000)
    lui s0, 0x80000     # s0 = 0x8000_0000

    # =========================================================
    # ATOMIC EXTENSION TEST
    # =========================================================

    # --- Initialize Memory ---
    li t0, 10
    sw t0, 0(s0)        # Store 10 at 0x8000_0000

    # --- TEST 1: AMOADD.W ---
    li t0, 5            # Value to add
    # amoadd.w rd, rs2, (rs1) -> t1 = old_val, mem = old_val + t0
    amoadd.w t1, t0, (s0) 
    
    # Print Result of AMO
    la a0, t_amo_old
    call puts
    mv a0, t1           # Expect 0xA (10)
    call print_reg

    la a0, t_amo_new
    call puts
    lw a0, 0(s0)        # Expect 0xF (15)
    call print_reg

    # --- TEST 2: LR.W / SC.W (Success Case) ---
    # 1. Load Reserved
    lr.w t2, (s0)       # t2 = 15
    addi t2, t2, 20     # t2 = 35 (0x23)
    
    # 2. Store Conditional
    # sc.w rd, rs2, (rs1) -> t3 = 0 if success, mem = t2
    sc.w t3, t2, (s0)

    la a0, t_sc_succ
    call puts
    mv a0, t3           # Expect 0x0 (Success)
    call print_reg

    la a0, t_sc_mem
    call puts
    lw a0, 0(s0)        # Expect 0x23 (35)
    call print_reg

    # --- TEST 3: LR.W / SC.W (Failure Case) ---
    # 1. Load Reserved
    lr.w t2, (s0)

    # 2. Simulate "Interference"
    # A normal store to the same address must break the reservation
    li t4, 99
    sw t4, 0(s0)

    # 3. Store Conditional
    # Should fail because of the 'sw' above
    sc.w t3, t2, (s0)

    la a0, t_sc_fail
    call puts
    mv a0, t3           # Expect 0x1 (Failure)
    call print_reg

    # =========================================================
    # CONTINUE TO SD CARD LOGIC
    # =========================================================
    li a0, "\nATOM_OK"
    call print7

    # ... [Your existing SD Card / FAT16 code continues here] ...
    # Make sure to update any logic that used 0x10000000 to 0x80000000

# ---------------------------------------------------------
# HELPER FUNCTIONS (Your originals)
# ---------------------------------------------------------

print_reg: # a0
    addi sp, sp, -40
    sd ra, 0(sp)
    sd s0, 8(sp)
    sd s1, 16(sp)
    sd s2, 24(sp)
    sd s3, 32(sp)
    mv s0, a0
    li a0, '0'
    call putchar
    li a0, 'x'
    call putchar
    li s1, 60 
p_loop:
    srl s2, s0, s1      # get high nibble
    andi s2, s2, 0xF
    slti s3, s2, 10     
    beq s3, x0, letter
    addi s2, s2, 48     
    j print_h
letter:
    addi s2, s2, 55     
print_h:
    call wait_uart
    sb s2, 0(s11)       
    addi s1, s1, -4
    bge s1, x0, p_loop 
    ld ra, 0(sp)
    ld s0, 8(sp)
    ld s1, 16(sp)
    ld s2, 24(sp)
    ld s3, 32(sp)
    addi sp, sp, 40
    ret

putchar:  # a0
    addi sp, sp, -8
    sd ra, 0(sp)
    call wait_uart
    sb a0, 0(s11)
    ld ra, 0(sp)
    addi sp, sp, 8
    ret

puts: # a0 addr
    addi sp, sp, -16
    sd ra, 0(sp)
    sd s0, 8(sp)
    mv s0, a0
puts_loop:
    lbu a0, 0(s0)
    beq a0, x0, stop_puts 
    call putchar 
    addi s0, s0, 1 
    j puts_loop
stop_puts:
    ld ra, 0(sp)
    ld s0, 8(sp)
    addi sp, sp, 16
    ret

wait_uart:
    lw t0, 0(s11)       # Read SiFive UART status/data
    bgt zero, t0, wait_uart_loop # Check if TX is full
    ret
wait_uart_loop:
    j wait_uart

print7: # a0 string pointer
    addi sp, sp, -16
    sd ra, 8(sp)
    call puts
    ld ra, 8(sp)
    addi sp, sp, 16
    ret
