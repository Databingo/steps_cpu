.globl _start

.section .data
msg:
    .string "Hello Virtual World!"

.section .text
_start:
    # ---------------------------------------------------------
    # PART 1: BUILD THE SV39 PAGE TABLE IN RAM
    # We will use 0x10000 for the Level 2 (Root) Table.
    # We will use 0x11000 for the Level 1 Table.
    # ---------------------------------------------------------

    # Step A: Link Root Table (L2) to Level 1 Table (L1)
    # We want Virtual Address 0x4000_0000.
    # L2 Index for 0x4000_0000 is 1. (0x4000_0000 >> 30 = 1).
    # Entry address = 0x10000 + (1 * 8 bytes) = 0x10008.
    li t0, 0x10008
    
    # We point this entry to the L1 table at physical address 0x11000.
    # PPN = 0x11000 >> 12 = 0x11.
    # Flags = Valid (0x01). No R/W/X means "Keep walking down the tree".
    # PTE = (0x11 << 10) | 0x01 = 0x4401.
    li t1, 0x4401
    sd t1, 0(t0)

    # Step B: Create a 2MB "Leaf" Page in the Level 1 Table
    # L1 Index for 0x4000_0000 is 0. ((0x4000_0000 >> 21) & 0x1FF = 0).
    # Entry address = 0x11000 + (0 * 8 bytes) = 0x11000.
    li t0, 0x11000
    
    # Let's point this Virtual Address to Physical Address 0x0000_0000 
    # (So 0x4000_0000 is just an alias for your physical RAM base).
    # PPN = 0x0 >> 12 = 0x0.
    # Flags = Valid(1), Read(2), Write(4), Exec(8), Accessed(64), Dirty(128).
    # Total Flags = 0xCF.
    # PTE = (0x0 << 10) | 0xCF = 0xCF.
    li t1, 0xCF
    sd t1, 0(t0)


    # ---------------------------------------------------------
    # PART 2: TURN ON THE MMU
    # ---------------------------------------------------------
    # Step C: Create a 1GB Identity Map for the code itself
    # L2 Index for 0x0000_0000 is 0.
    # Entry address = 0x10000 + (0 * 8 bytes) = 0x10000.
    li t0, 0x10000
    
    # We point this Virtual Address to Physical Address 0x0000_0000.
    # PPN = 0x0 >> 12 = 0.
    # Flags = Valid(1), Read(2), Write(4), Exec(8), Accessed(64), Dirty(128).
    # Because R/W/X are not zero, this is a 1GB Superpage (Leaf)!
    # PTE = (0x0 << 10) | 0xCF = 0xCF.
    li t1, 0xCF
    sd t1, 0(t0) 



 
    # satp needs the Physical Page Number of the Root Table (0x10000).
    # PPN = 0x10000 >> 12 = 0x10.
    # Mode = 8 (Sv39). We shift 8 to the very top (bit 60).
    li t0, 0x8000000000000010
    csrw satp, t0
    sfence.vma          # Flush the TLB
    
    # <--- AT THIS EXACT MOMENT, THE CPU WILL TRAP TO YOUR WALKER!
    # Your walker at PC=0 will read satp, walk to 0x10000, then 0x11000,
    # find the PPN, write it to your Hardware TLB, and mret back here!


    # ---------------------------------------------------------
    # PART 3: TEST THE VIRTUAL ADDRESS
    # ---------------------------------------------------------
    
    # Normally, msg is at Physical Address 0x0000_XXXX.
    # But because we mapped Virtual 0x4000_0000 to Physical 0x0000_0000,
    # we can add 0x4000_0000 to the pointer and it will STILL WORK!
    
    la a0, msg
    li t1, 0x40000000
    add a0, a0, t1      # a0 is now a VIRTUAL address!
    
    call puts           # The puts loop will trigger D-TLB misses!
    
    ebreak
