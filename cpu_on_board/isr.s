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
     
#Seems VA has 3 table number, satp has Root Table(vpn[2]) address via PPN(ppn+12 space), the we can find PTE in table 2, and PTE has PPN, we can use table2PPN to find table 1 address plus vpn1 number to find PTE in table1, then we get table1 PPN for table0 address, and together with vpn0 to find PTE in talbe0, this is  the last ppa, by ppn + 12 bit of VA low.
