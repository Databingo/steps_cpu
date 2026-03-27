# Use re0-re4 shadowed register only
# I-TLB mmu-refill 1:1 identity map
     j mmu
    #lui x1, 0x2     
     addi x1, x1, 0x4              
     addi x2, x0, 91
     sd x2, 0(x1)    #  print [
     lui x3, 0x20000
     sd x1, 0(x3) 
     addi x2, x0, 93
     sd x2, 0(x1)    #  print ]
     mret           
# D-TLB mmu-refill
     j mmu
    #lui x1, 0x2     
     addi x1, x1, 0x4              
     addi x2, x0, 123
     sd x2, 0(x1)    #  print {
     lui x3, 0x20000
     sd x1, 0(x3) 
     addi x2, x0, 125
     sd x2, 0(x1)    #  print }
     mret           


#  I-Cache refill (withoud stap/tlb_hit sensitive)
     lui x4, 0x20001 # base Cache address
     ld x3, 0(x1)    # get data
     sd x3, 0(x4)    # refill line low 64
     ld x3, 8(x1)    # get data
     sd x3, 8(x4)    # refill line high 64  

     lui x3, 0x2     
     addi x3, x3, 0x4  # set print           
     addi x2, x0, 0x25
     sd x2, 0(x3)    #  print %
     mret           

mmu:  # VA 63:39Sign|38:30Vpn[2]|29:21Vpn[1]|20:12Vpn[0]|11:0PageOffset  
   # 1. Get root table address from csr satp Supervisor Address Translation and Protection
     csrr x2, satp   # satp 63:60Mode|59:44Asid(0forSimpleOS)|43:0PPNofRootTable
     slli x2, x2, 20 # clear high mode+Asid Address Space Identifier
     srli x2, x2, 8  # get level_2 ppn(27 bits) + 12 zero positon, point to start of Root Table

   # 2. Level 2 walk
     srli x3, x1, 30 # extract vpn[2] bit 38:30 the first 9 bits
     andi x3, x3, 0x1ff # Mask 9 bits
     slli x3, x3, 3  # Multiple by 8 (PTE size 8 bytes) Page Table Entry 64 bits
     add  x2, x2, x3 # x2 = Address of L2 PTE
     ld x4, 0(x2)    # Load L2 PTE from memory  PTE 63:54Reserved|53:10PPN|9:8RSW|XWRmark|0validBit1

   # 3. Check Leaf
     andi x3, x4, 0xE # bit 3:1 for X/W/R
     bnez x3, FINISH_1GB  # If not zero, it's leaf. We get the address.
     andi x3, x4, 1   # check PTE valid bit
     beqz x3, FAULT

   # 4. Prepare for Level 1
     srli x2, x4, 10 # Extract PPN from L2 PTE
     slli x2, x2, 12 # x2 = Address of L1 Table

   # 5. Level 1 Walk
     srli x3, x1, 21 # Extract VPN[1] bit 29:21
     andi x3, x3, 0x1ff # Mask 9 bits
     slli x3, x3, 3  # Multiple by 8 (PTE size 8 bytes)
     add  x2, x2, x3 # x2 = Address of L1 PTE
     ld x4, 0(x2)    # Load L1 PTE from memory

   # 6. Check Leaf
     andi x3, x4, 0xE # bit 3:1 for X/W/R
     bnez x3, FINISH_2MB   # If not zero, it's leaf. We get the address.
     andi x3, x4, 1   # check PTE valid bit
     beqz x3, FAULT

   # 7. Prepare for Level 0
     srli x2, x4, 10 # Extract PPN from L1 PTE
     slli x2, x2, 12 # x2 = Address of L0 Table

   # 8. Level 0 Walk
     srli x3, x1, 12 # Extract VPN[0] bit 20:12
     andi x3, x3, 0x1ff # Mask 9 bits
     slli x3, x3, 3  # Multiple by 8 (PTE size 8 bytes)
     add  x2, x2, x3 # x2 = Address of L0 PTE
     ld x4, 0(x2)    # Load L0 PTE from memory

   # 9. Check valid
     andi x3, x4, 1   # check PTE valid bit
     beqz x3, FAULT
   # fall to 4KB finish

FINISH_4KB:
     srli x4, x4, 10 
     slli x4, x4, 12 
     j WRITE_TLB
                                            
FINISH_2MB:
     srli x4, x4, 10 
     slli x4, x4, 12 
     li x3, 0x001ff000 # mask for VA[20:12]
     and x3, x3, x1    
     add x4, x4, x3   
     j WRITE_TLB

FINISH_1GB:
     srli x4, x4, 10  # get PPN from PTE(PTE's data struction?)  64:54Reserved 53:10PPN # 9:8RSW 7Dirty 6Accessed 5Global 4User 3Executable 2Write 1Readable 0Valid
     slli x4, x4, 12  # PPN posint [38:12] in satp
     li x3, 0x3ffff000 # mask for VA[29:12]
     and x3, x3, x1    # extrac from VA
     add x4, x4, x3    # add offset to PPN
     j WRITE_TLB
                 

WRITE_TLB:
     # 9. Writ ppn back to hardware mmu trap
     lui x2, 0x20000 # Magic TLB address
     sd x4, 0(x2)
     mv a0, x4

   li a7, 0x1600 # Set stack
   li s11, 0x2004 # UART print 



     call print_reg

     lui x3, 0x2     
     addi x3, x3, 0x4              
     addi x2, x0, 91
     sd x2, 0(x3)    #  print [
     mret


FAULT: # error trap?
     lui x3, 0x2     
     addi x3, x3, 0x4              
     addi x2, x0, 33
     sd x2, 0(x3)    #  print !
     mret
     
#Seems VA has 3 table number, satp has Root Table(vpn[2]) address via PPN(ppn+12 a7ace), the we can find PTE in table 2, and PTE has PPN, we can use table2PPN to find table 1 address plus vpn1 number to find PTE in table1, then we get table1 PPN for table0 address, and together with vpn0 to find PTE in talbe0, this is  the last ppa, by ppn + 12 bit of VA low.




# functions ------

print_reg: # a0
    addi a7, a7, -40
    sd ra, 0(a7)
    sd s0, 8(a7)
    sd s1, 16(a7)
    sd s2, 24(a7)
    sd s3, 32(a7)
    mv s0, a0
    li a0, "0"
    call putchar
    li a0, "x"
    call putchar
    li s1, 60 
p_loop:
    srl s2, s0, s1      # get high nibble
    andi s2, s2, 0xF
    slti s3, s2, 10     # if < 10 number
    beq s3, x0, letter
    addi s2, s2, 48     # 0 is "0" ascii 48
    j print_h
letter:
    addi s2, s2, 55     # 10 is "A" ascii 65 ..
print_h:
    call wait_uart
    sb s2, 0(s11)       # print
    addi s1, s1, -4
    bge s1, x0, p_loop 
    ld ra, 0(a7)
    ld s0, 8(a7)
    ld s1, 16(a7)
    ld s2, 24(a7)
    ld s3, 32(a7)
    addi a7, a7, 40
    ret


putchar:  # a0
    addi a7, a7, -8
    sd ra, 0(a7)
    call wait_uart
    sb a0, 0(s11)
    ld ra, 0(a7)
    addi a7, a7, 8
    ret


puts: # a0 addr
    addi a7, a7, -16
    sd ra, 0(a7)
    sd s0, 8(a7)
    mv s0, a0
puts_loop:
    lbu a0, 0(s0)
    beq a0, x0, stop_puts # \x00 for end of string
    call putchar # a0 char
    addi s0, s0, 1 # next byte
    j puts_loop
stop_puts:
    ld ra, 0(a7)
    ld s0, 8(a7)
    addi a7, a7, 16
    ret


wait_uart:
    addi a7, a7, -16
    sd s0, 0(a7)
    sd ra, 8(a7)
wait_uart_loop:
   #li a0, 65  # A
   #sb a0, 0(s11)
    lw s0, 0(s11)
    bgt zero, s0, wait_uart_loop
    ld s0, 0(a7)
    ld ra, 8(a7)
    addi a7, a7, 16
    ret

print7: # a0, 7 char left one for null
    addi a7, a7, -16
    sd a0, 0(a7)
    sd ra, 8(a7)
    mv a0, a7
    call puts
   #ld a0, 0(a7)
    ld ra, 8(a7)
    addi a7, a7, 16
    ret
