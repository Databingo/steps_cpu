#   # 1. Get root table address from csr satp
#     csrr x5, satp
#     slli x5, x5, 20 # clear high mode+Asid
#     srli x5, x5, 8  # get level_2 ppn(27 bits) + 12 zero positon
#
#   # 2. Level 2 walk
#     srli x6, x9, 30 # extract vpn[2] bit 38:30 the first 9 bits
#     andi x6, x6, 0x1ff # Mask 9 bits
#     slli x6, x6, 3  # Multiple by 8 (PTE size 8 bytes)
#     add  x5, x5, x6 # x5 = Address of L2 PTE
#     ld x7, 0(x5)    # Load L2 PTE from memory
#
#   # 3. Check Leaf
#     andi x6, x7, 0xE # bit 3:1 for X/W/R
#     bnez x6, FINISH   # If not zero, it's leaf. We get the address.
#
#   # 4. Prepare for Level 1
#     srli x5, x7, 10 # Extract PPN from L2 PTE
#     slli x5, x5, 12 # x5 = Address of L1 Table
#
#   # 5. Level 1 Walk
#     srli x6, x9, 21 # Extract VPN[1] bit 29:21
#     andi x6, x6, 0x1ff # Mask 9 bits
#     slli x6, x6, 3  # Multiple by 8 (PTE size 8 bytes)
#     add  x5, x5, x6 # x5 = Address of L1 PTE
#     ld x7, 0(x5)    # Load L1 PTE from memory
#
#   # 6. Check Leaf
#     andi x6, x7, 0xE # bit 3:1 for X/W/R
#     bnez x6, FINISH   # If not zero, it's leaf. We get the address.
#
#   # 7. Prepare for Level 0
#     srli x5, x7, 10 # Extract PPN from L1 PTE
#     slli x5, x5, 12 # x5 = Address of L0 Table
#
#   # 8. Level 0 Walk
#     srli x6, x9, 12 # Extract VPN[0] bit 20:12
#     andi x6, x6, 0x1ff # Mask 9 bits
#     slli x6, x6, 3  # Multiple by 8 (PTE size 8 bytes)
#     add  x5, x5, x6 # x5 = Address of L0 PTE
#     ld x7, 0(x5)    # Load L0 PTE from memory
#
#FINISH:
#     srli x7, x7, 10  # get PPN from PTE(PTE's data struction?)  64:54Reserved 53:10PPN 
#                      # 9:8RSW 7Dirty 6Accessed 5Global 4User 3Executable 2Write 1Readable 0Valid
#     slli x7, x7, 12  # PPN posint [38:12] in satp
#     
#     # 9. Writ ppn back to hardware mmu trap
#     lui x8, 0xF0002 # Magic TLB address
#     sd x7, 0(x8)
#     mret
     

# I-TLB mmu-refill 1:1 identity map
     lui x1, 0x2     
     addi x1, x1, 0x4              
     addi x2, x0, 0x2a
     sd x2, 0(x1)    #  print *
     lui x8, 0x20000
     sw x9, 0(x8) 
     addi x2, x0, 0x2d
     sd x2, 0(x1)    #  print -
     mret           
# D-TLB mmu-refill
     lui x1, 0x2     
     addi x1, x1, 0x4              
     addi x2, x0, 0x5e
     sd x2, 0(x1)    #  print ^
     lui x8, 0x20000
     sw x9, 0(x8) 
     mret           
## I-Cache mmu-refill
#     lui x1, 0x2     
#     addi x1, x1, 0x4              
#     addi x2, x0, 0x2d
#     sd x2, 0(x1)    #  print -
#     # get data
#
#     lui x8, 0x20001 
#     sw x9, 0(x8)    # refill line low 64
#
#     # get data
#
#     lui x8, 0x20001
#     addi x8, x8, 0x8 
#     sw x9, 0(x8)    # refill line high 64  
#     mret           
