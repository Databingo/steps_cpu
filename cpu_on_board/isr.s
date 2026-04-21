isr_router:        
     # x0-x10 are shadowed by hardware, safe to use
     li sp, 0x1500 # Set stack shadowed sp(x2)
     li x7, 0x2004 # UART print 
     # x8 trap_type no change
     # x9 addr  # x9 keep the address need manage, no change x9
     # x689 setting

    ## software fix for 7ffff... address:
    #slli x3, x9, 25
    #srai x3, x3, 35
    #mv x9, x3
    #csrr x3, mepc
    #slli x4, x3, 25
    #srai x4, x4, 25
    #csrw mepc, x4
    #csrr x3, sepc
    #slli x4, x3, 25 
    #srai x4, x4, 25
    #csrw sepc, x4
     


     # x1(ra)2(sp)3456,x10(a0) operating
     li x3, 12 
     beq x8, x3, mmu_i    # i-tlb-refill Fetch

     li x3, 13 
     beq x8, x3, mmu_d    # d-tlb-refill Load

     li x3, 14 
     beq x8, x3, mmu_d    # d-tlb-refill Store

     li x3, 1 
     beq x8, x3, i_cache_refill

    #li x3, 17 
    #beq x8, x3, bus_error_strap

     li x3, 18 
     beq x8, x3, debug

i_cache_refill:
     lui x4, 0x20001 # base Cache address
     ld x3, 0(x9)    # get data
     sd x3, 0(x4)    # refill line low 64
     ld x3, 8(x9)    # get data
     sd x3, 8(x4)    # refill line high 64  

    #lui x3, 0x2     
    #addi x3, x3, 0x4  # set print           
    #addi x6, x0, 0x25
    #sd x6, 0(x3)    #  print %

    #mv a0, x9
    #call print_reg

    #li a0, "ICAre:"
    #call print7
    #mv a0, x9
    #call print_reg

     addi x8, x0, 0  # success x8=0
     j return

mmu_i:
    #li a0, "\n[i"
    #call print7
     j mmu
mmu_d:
    #li a0, "\n[d"
    #call print7
     j mmu

mmu:  # VA 63:39Sign|38:30Vpn[2]|29:21Vpn[1]|20:12Vpn[0]|11:0PageOffset  
   # 1. Get root table address from csr satp Supervisor Address Translation and Protection
     csrr x6, satp   # satp 63:60Mode|59:44Asid(0forSimpleOS)|43:0PPNofRootTable
     slli x6, x6, 20 # clear high mode+Asid Address Space Identifier
     srli x6, x6, 8  # get level_2 ppn(27 bits) + 12 zero positon, point to start of Root Table

   # 2. Level 2 walk
     srli x3, x9, 30 # extract vpn[2] bit 38:30 the first 9 bits
     andi x3, x3, 0x1ff # Mask 9 bits
     slli x3, x3, 3  # Multiple by 8 (PTE size 8 bytes) Page Table Entry 64 bits
     add  x6, x6, x3 # x2 = Address of L2 PTE
     ld x4, 0(x6)    # Load L2 PTE from memory  PTE 63:54Reserved|53:10PPN|9:8RSW|XWRmark|0validBit1

   # 3. Check Leaf
     andi x3, x4, 1   # check PTE valid bit
     beqz x3, FAULT
    #andi x3, x4, 0b10000000 # bit 7 Dirty
     andi x3, x4, 0xE # bit 3:1 for X/W/R
     bnez x3, FINISH_1GB  # If not zero, it's leaf. We get the address.

   # 4. Prepare for Level 1
     slli x6, x4, 10 # clear top 10 reserved bits
     srli x6, x6, 20 # Extract PPN from L2 PTE
     slli x6, x6, 12 # x2 = Address of L1 Table

   # 5. Level 1 Walk
     srli x3, x9, 21 # Extract VPN[1] bit 29:21
     andi x3, x3, 0x1ff # Mask 9 bits
     slli x3, x3, 3  # Multiple by 8 (PTE size 8 bytes)
     add  x6, x6, x3 # x2 = Address of L1 PTE
     ld x4, 0(x6)    # Load L1 PTE from memory

   # 6. Check Leaf
     andi x3, x4, 1   # check PTE valid bit
     beqz x3, FAULT
     andi x3, x4, 0xE # bit 3:1 for X/W/R 1110
     bnez x3, FINISH_2MB   # If not zero, it's leaf. We get the address.

   # 7. Prepare for Level 0
     slli x6, x4, 10 # clear top 10 reserved bits
     srli x6, x6, 20 # Extract PPN from L1 PTE
     slli x6, x6, 12 # x2 = Address of L0 Table

   # 8. Level 0 Walk
     srli x3, x9, 12 # Extract VPN[0] bit 20:12
     andi x3, x3, 0x1ff # Mask 9 bits
     slli x3, x3, 3  # Multiple by 8 (PTE size 8 bytes)
     add  x6, x6, x3 # x2 = Address of L0 PTE
     ld x4, 0(x6)    # Load L0 PTE from memory

   # 9. Check valid
     andi x3, x4, 1   # check PTE valid bit
     beqz x3, FAULT
     andi x3, x4, 0xE # bit 3:1 for X/W/R 1110
     beqz x3, FAULT   # It should be leaf not 0


   # fall to 4KB finish

FINISH_4KB:
     jal x5, CHECK_PERM_AND_AD
     slli x4, x4, 10  # mask out reserved bits
     srli x4, x4, 20 
     slli x4, x4, 12 
     j WRITE_TLB
                                            
FINISH_2MB:
     jal x5, CHECK_PERM_AND_AD
     slli x4, x4, 10  # mask out reserved bits
     srli x4, x4, 20 
     slli x4, x4, 12 
     li x3, 0x001ff000 # mask for VA[20:12]
     and x3, x3, x9    
     add x4, x4, x3   
     j WRITE_TLB

FINISH_1GB:
     jal x5, CHECK_PERM_AND_AD
     slli x4, x4, 10  # mask out reserved bits
     srli x4, x4, 20  # get PPN from PTE(PTE's data struction?)  64:54Reserved 53:10PPN # 9:8RSW 7Dirty 6Accessed 5Global 4User 3Executable 2Write 1Readable 0Valid
     slli x4, x4, 12  # PPN posint [38:12] in satp
     li x3, 0x3ffff000 # mask for VA[29:12]
     and x3, x3, x9    # extrac from VA
     add x4, x4, x3    # add offset to PPN
     j WRITE_TLB

# --- Permissions, U-Bit and A/D Bits --
CHECK_PERM_AND_AD:                
     # 1. Check U-Bit based on VA sign (x9)
     andi x3, x4, 0x10 # Extract U-bit (Bit 4)
     bltz x9, check_kernel_u
check_user_u:
     beqz x3, PERM_FAULT # User VA (>=0) requires U=1
     j check_permissions
check_kernel_u:
     bnez x3, PERM_FAULT # Kernel VA (<0) requires U=0
check_permissions:
     # 2. CHECK R/W/X permissions
     li x3, 14
     beq x8, x3, check_store
     li x3, 12
     beq x8, x3, check_fetch
check_load:
     andi x3, x4, 2 # PET.R (bit 1)
     beqz x3, PERM_FAULT
     j update_ad
check_store:
     andi x3, x4, 4 # PET.W (bit 2)
     beqz x3, PERM_FAULT
     j update_ad
check_fetch:
     andi x3, x4, 8 # PET.X (bit 8)
     beqz x3, PERM_FAULT
update_ad:
     # 3. Update A/D bits
     ori x4, x4, 0x40  # set Accessed bit (bit 6)
     li x3, 14
     bne x8, x3, write_pte
     ori x4, x4, 0x80  # set Dirty bit (bit 7) if store
write_pte:
     sd x4, 0(x6) # write updated PTE back to memory
     jalr x0, 0(x5)  # return to leaf formatter
    
    
# -- Hardware writeback --
WRITE_TLB:
     # 9. Writ ppn back to hardware mmu trap
     lui x6, 0x20000 # Magic TLB address
     sd x4, 0(x6)

    #li a0, "TLBre:"
    #call print7
    #mv a0, x9
    #call print_reg
 
    #mv a0, x4
    #call print_reg

    #addi x6, x0, 93
    #sd x6, 0(x7)    #  print ]

     addi x8, x0, 0  # success x8=0
     j return


FAULT: # error trap?

    #li a0, "TLBfl:"
    #call print7
    #mv a0, x9
    #call print_reg

    #addi x6, x0, 33
    #sd x6, 0(x7)    #  print !

     j return
#FAULT:
PERM_FAULT:
    # force the trap cuase to trigger a real S-mode fualt for linux
    li x3, 14
    bne x8, x3, trigger_trap
    li x8, 15  # Convert to Store Page Fault (15)
trigger_trap:
    # leaving x8 != 0
    j return

return:    
     mret

#Seems VA has 3 table number, satp has Root Table(vpn[2]) address via PPN(ppn+12 space), the we can find PTE in table 2, and PTE has PPN, we can use table2PPN to find table 1 address plus vpn1 number to find PTE in table1, then we get table1 PPN for table0 address, and together with vpn0 to find PTE in talbe0, this is  the last ppa, by ppn + 12 bit of VA low.



debug:
     li a0, "\nDEBUG" 
     call print7

     li a0, "|ir:" 
     call print7
    #csrr a0, 0xF11 # mvendorid/ir
     csrr a0, mvendorid # mvendorid/ir
     call print_reg

     li a0, "|ppc:" 
     call print7
    #csrr a0, 0xF12 # marchid/ppc
     csrr a0, marchid # marchid/ppc
     call print_reg

     li a0, "|pda:" 
     call print7
    #csrr a0, 0xF13 # mimpid/pda
     csrr a0, mimpid # mimpid/pda
     call print_reg

    li a0, "|mhtid:" 
    call print7
    csrr a0, mhartid
    call print_reg

   #li a0, "|mstas:" 
   #call print7
   #csrr a0, mstatus
   #call print_reg


     li a0, "|" 
     call putchar


     
     addi x8, x0, 0  # success x8=0
     j return







# -------------- use ra(x1), x2-x5, a0(x10) have to save in stack and restore -------
print_reg: # a0
    addi sp, sp, -40
    sd ra, 0(sp)
    sd x6, 8(sp)
    sd x3, 16(sp)
    sd x4, 24(sp)
    sd x5, 32(sp)
    mv x6, a0
    li a0, "0"
    call putchar
    li a0, "x"
    call putchar
    li x3, 60 
p_loop:
    srl x4, x6, x3      # get high nibble
    andi x4, x4, 0xF
    slti x5, x4, 10     # if < 10 number
    beq x5, x0, letter
    addi x4, x4, 48     # 0 is "0" ascii 48
    j print_h
letter:
    addi x4, x4, 55     # 10 is "A" ascii 65 ..
print_h:
    call wait_uart
    sb x4, 0(x7)       # print
    addi x3, x3, -4
    bge x3, x0, p_loop 
    ld ra, 0(sp)
    ld x6, 8(sp)
    ld x3, 16(sp)
    ld x4, 24(sp)
    ld x5, 32(sp)
    addi sp, sp, 40
    ret


putchar:  # a0
    addi sp, sp, -8
    sd ra, 0(sp)
    call wait_uart
    sb a0, 0(x7)
    ld ra, 0(sp)
    addi sp, sp, 8
    ret


puts: # a0 addr
    addi sp, sp, -16
    sd ra, 0(sp)
    sd x6, 8(sp)
    mv x6, a0
puts_loop:
    lbu a0, 0(x6)
    beq a0, x0, stop_puts # \x00 for end of string
    call putchar # a0 char
    addi x6, x6, 1 # next byte
    j puts_loop
stop_puts:
    ld ra, 0(sp)
    ld x6, 8(sp)
    addi sp, sp, 16
    ret


wait_uart:
    addi sp, sp, -16
    sd x6, 0(sp)
    sd ra, 8(sp)
wait_uart_loop:
   #li a0, 65  # A
   #sb a0, 0(x7)
    lw x6, 0(x7)
    bgt zero, x6, wait_uart_loop
    ld x6, 0(sp)
    ld ra, 8(sp)
    addi sp, sp, 16
    ret

print7: # a0, 7 char left one for null
    addi sp, sp, -16
    sd a0, 0(sp)
    sd ra, 8(sp)
    mv a0, sp
    call puts
    ld a0, 0(sp)
    ld ra, 8(sp)
    addi sp, sp, 16
    ret
