.globl _start

.section .data
mem_test_var:
    .dword 0x0000000000000000


# Bootloader/copy4 --> firmware/BIOS/opensib/mini_sbi2 --> OS/linux/kernal
.section .text
_start:  
  j main # like linux kernel

s_trap_handler:
   csrr t1, scause
   li t2, 0x8000000000000005 # bit 63 set + code 5 (Supervisor Timer)
   beq t1, t2, timer_found_stip

   li t2, 0x8000000000000001 # bit 63 set + code 1 (Soft ware Interrupt)
   beq t1, t2, timer_found_ssip

   csrr t2, sepc
   addi t2, t2, 4 # skip ecall/ebreak instruction
   csrw sepc, t2
   sret

timer_found_stip:
    addi a0, x0, 84  # T
    call sbi_putchar
   #li a0, -1 # Clear timer by max
   #li a7, 0 # SBI set timer
   #ecall

   csrr a0, time
  #li t0, 10000000 # 1 second
   li t0, 100000 # 1 second
   add a0, a0, t0
   li a7, 0  # SBI Set Timer ID
   ecall

    sret
timer_found_ssip:
    addi a0, x0, 83  # S
    call sbi_putchar
    li t2, 0x02  # clear ssip
    csrc sip, t2

    sret


sbi_putchar:  # a0
    addi sp, sp, -8
    sd ra, 0(sp)
    li a7, 1 # SBI Putchar ID
    ecall
    ld ra, 0(sp)
    addi sp, sp, 8
    ret

sbi_puts: # a0 addr
    addi sp, sp, -24
    sd ra, 0(sp)
    sd a0, 8(sp)
    sd s1, 16(sp)
    mv s1, a0
    sbi_puts_loop:
    lbu a0, 0(s1)
    beq a0, x0, sbi_stop_puts # \x00 for end of string
    li a7, 1 # SBI Putchar ID
    ecall
    addi s1, s1, 1 # next byte
    j sbi_puts_loop
    sbi_stop_puts:
    ld ra, 0(sp)
    ld a0, 8(sp)
    ld s1, 16(sp)
    addi sp, sp, 24
    ret

sbi_print7: # a0, 7 char left one for null
    addi sp, sp, -16
    sd a0, 0(sp)
    sd ra, 8(sp)
    mv a0, sp
    call sbi_puts
    ld a0, 0(sp)
    ld ra, 8(sp)
    addi sp, sp, 16
    ret

sbi_print_reg: # a0
    addi sp, sp, -40
    sd ra, 0(sp)
    sd s0, 8(sp)
    sd s1, 16(sp)
    sd s2, 24(sp)
    sd s3, 32(sp)
    mv s0, a0
    li a0, "0"
    call sbi_putchar
    li a0, "x"
    call sbi_putchar
    li s1, 60 
    p_loop:
    srl s2, s0, s1      # get high nibble
    andi s2, s2, 0xF
    slti s3, s2, 10     # if < 10 number
    beq s3, x0, letter
    addi a0, s2, 48     # 0 is "0" ascii 48
    j print_h
    letter:
    addi a0, s2, 55     # 10 is "A" ascii 65 ..
    print_h:
    call sbi_putchar    # print
    addi s1, s1, -4
    bge s1, x0, p_loop 
    ld ra, 0(sp)
    ld s0, 8(sp)
    ld s1, 16(sp)
    ld s2, 24(sp)
    ld s3, 32(sp)
    addi sp, sp, 40
    ret


main:

   li sp, 0x80700000 # Set stack # 80000000-80800000 sdram as 8M ram, we start sp from 0x80700000<-, MMU from 0x80700000->

   # Test time
  #csrr s0, time
   li t0, 100
check_clock:
   csrr a0, time
   call sbi_print_reg
   addi t0, t0, -1
   bnez t0, check_clock

   # Step 2 test S-Mode trap hander # Opensbi delegate Ebreak to OS, so we set our handler address to stvec
   la t0, s_trap_handler
  #andi t0, t0, -4 # Align to 4 bytes
   csrw stvec, t0
   ebreak
  #li a0, "\nStrpOK"
  #call sbi_print7


#   # Step 3 test MMU
#   # 1.Build SV39 root table in sdram (4KB per table 2**9=512*8=4096) vpn2 4KB map 512*4k=2MBram; all vpn1=4*512=2Mb map 512*2M=1Gram, all vpn0=512*512=262144*4kb=1GB map 512Gram,total VPNs 4KB+2MB+1024MB
#   li t0, 0x80700000 # set base address of MMU root table
#
#   # 2. map vma 0x0000_0000 to ppa 0x0000_0000, ppn =  ppa >> 12 = 0, for UART/CLINT/PLIC .etc
#   li t1, 0xcf       # pte = ppn << 10 | flags valid0 read1 write2 exec3 accessed6 dirty7 0b11001111=0xcf
#   sd t1, 0(t0) 
#
#   # 3. map vma 0x8000_0000 to ppa 0x8000_0000, ppn =  ppa >> 12 = 0x80000 pte = ppn << 10 | flags, for RAM/Code
#   li t1, 0x200000cf # pte = ppn << 10 | flags valid0 read1 write2 exec3 accessed6 dirty7 0b11001111=0xcf
#   sd t1, 16(t0)     # Index=va[38:30]=0b00000010=2, 8 bytes per PTE = 16, 
#
#   # satp need ppn of root table rt 0x80700000 
#   # satp = satp[63:60].MODE(0:bare, 8:sv39, 9:sv48)|satp[59:44].asid|satp[43:0].rootpage_physical_addr(vpn2:9|vpn1:9|vpn0:9|offseet12)
#   # ppn = rt >> 12 = 0x80700
#   # mode = 3 sv39
#   li t0, 0x8000000000080700
#   # Turn MMU SV39
#   csrw satp, t0 # write mode and root table address to satp CSR register
#   sfence.vma ## <--- start use TLB I/D hitting
#
#  #li a0, "\nMMUOK"
#  #call sbi_print7



   # AAA================= 
#   la a2, mem_test_var
#   sd zero, 0(a2)
#
#   # ----- 1. BIT-MASKING (Used for Mount Flags) -----
#   li s11, 0xA10       # Test AMOOR / AMOAND Bit-masking
#   li t1, 0x0000FF00
#   sd t1, 0(a2)
#   li t2, 0x00FF0000
#   amoor.d t3, t2, (a2) # Old was 0xFF00, New should be 0xFFFF00
#   ld t4, 0(a2)
#   li t5, 0x00FFFF00
#   bne t4, t5, fail_chain
#
#   li t2, 0x000000FF
#   amoand.d t3, t2, (a2) # New should be 0 because 0xFFFF00 & 0xFF = 0
#   ld t4, 0(a2)
#   bne t4, zero, fail_chain
#
#   # ----- 2. RESERVATION GRANULARITY (Critical for bit-fields) -----
#   # Linux often uses 'sb' (store byte) to update a flag next to a locked word.
#   # A store to ANY byte in the reserved 64-bit word MUST break the reservation.
#   li s11, 0xA11
#   li t1, 0x11223344
#   sd t1, 0(a2)
#   lr.d t2, (a2)       # Reserve the whole 64-bit dword
#   
#   li t3, 0x99
#   sb t3, 1(a2)        # Store to just ONE BYTE inside that dword
#   
#   li t4, 0x55
#   sc.d t5, t4, (a2)   # This MUST fail (t5 != 0) because of the 'sb'
#   beq t5, zero, fail_chain 
#
#   # ----- 3. SC TO DIFFERENT ADDRESS (Security/Stability) -----
#   # If you LR address A, then SC to address B, it MUST fail.
#   li s11, 0xA12
#   la a3, mem_test_var
#   addi a4, a3, 8      # A different address
#   lr.d t1, (a3)       # Reserve A
#   sc.d t2, t1, (a4)   # Store to B
#   beq t2, zero, fail_chain # Must fail!
#
#   # ----- 4. LR/SC LIVELOCK / INTERRUPT CHECK -----
#   # Linux spinlocks loop until SC succeeds. 
#   # If a Timer Interrupt happens between LR and SC, the SC MUST fail,
#   # but it must NOT stay failed forever.
#   li s11, 0xA13
#   li t1, 0
#   sd t1, 0(a2)
#lr_sc_loop:
#   lr.d t2, (a2)
#   addi t2, t2, 1
#   # If your timer (T) prints here, it's good! It forces SC to fail once.
#   sc.d t3, t2, (a2)
#   bnez t3, lr_sc_loop # Linux loops. If your CPU hangs here, it's a bug.
#   
#   ld t4, 0(a2)
#   li t5, 1
#   bne t4, t5, fail_chain
#
#   # ----- 5. SIGN EXTENSION (The 'W' rule) -----
#   li s11, 0xA14
#   li t1, 0x7FFFFFFF
#   sw t1, 0(a2)
#   li t2, 1
#   amoadd.w t3, t2, (a2) # 0x7FFFFFFF + 1 = 0x80000000
#   # t3 (old value) should be 0x000000007FFFFFFF
#   # Memory should now contain 0x80000000
#   lw t4, 0(a2)
#   li t5, -0x80000000    # Sign extended 32-bit 0x80000000
#   bne t4, t5, fail_chain


#  For linux mountpoint-cache test
   # Use stack-relative address for alignment and to avoid SD-card buffer overlap
   addi s10, sp, -16   
   sd zero, 0(s10)     
   fence

   # ----- 1. M-EXTENSION: VFS HASH [ID: 0x501] -----
   li s11, 0x501       
   li a1, 0x9e37fffffffc0001
   li a2, 2
   mul t1, a1, a2
   li t2, 0x3c6ffffffff80002 
   bne t1, t2, fail_chain

   # ----- 2. A-EXTENSION: BITWISE OR [ID: 0xA01] -----
   li s11, 0xA01
   li t1, 0x00FF0000
   sd t1, 0(s10)
   li t2, 0x0000FF00
   amoor.d t3, t2, (s10) 
   ld t4, 0(s10)
   li t5, 0x00FFFF00
   bne t4, t5, fail_chain # Memory update failed
   bne t3, t1, fail_chain # Return value (old) failed

   # ----- 3. A-EXTENSION: SPINLOCK SWAP [ID: 0xA02] -----
   li s11, 0xA02
   li t1, 1            
   sw zero, 0(s10)      
   amoswap.w t2, t1, (s10) 
   lw t3, 0(s10)        
   bne t2, zero, fail_chain # Did not return 0
   li t4, 1
   bne t3, t4, fail_chain    # Memory not set to 1

   # ----- 4. A-EXTENSION: NEIGHBOR BUG [ID: 0xA03] -----
   # IF SOC FAILS HERE: Your Hardware Reservation logic is too narrow!
   li s11, 0xA03
   sd zero, 0(s10)
   lr.d t1, (s10)       
   li t2, 0xFF
   sb t2, 1(s10)        # Store to neighbor byte
   li t3, 0xCC
   sc.d t4, t3, (s10)   # SC MUST FAIL (t4 != 0)
   beq t4, zero, fail_chain

   # ----- 5. A-EXTENSION: SIGN EXTENSION [ID: 0xA04] -----
   # IF SOC FAILS HERE: Your pipeline is dropping sign-bits between MUL and AMO
   li s11, 0xA04
   li a1, 0x40000000   
   li a2, 2            
   mulw t1, a1, a2      # t1 = 0xFFFFFFFF80000000 (sign extended)
   sw zero, 0(s10)
   amoadd.w t2, t1, (s10)
   lw t3, 0(s10)
   
   # Build 0xFFFFFFFF80000000 for comparison
   addi t4, zero, -1
   slli t4, t4, 31     
   bne t3, t4, fail_chain

   li s11, 0x0000000080000000 





   # BBB================= 
   li a0, "\nPASS"
   call sbi_print7
   j wait_for_key
  #j key_test
  #j end

fail_chain:
   mv a0, s11
   call sbi_print_reg
   li a0, "\nFAIL"
   call sbi_print7

wait_for_key:
   li a7, 2  # SBI Getchar ID
   ecall
   bltz a0, wait_for_key  # if a0 is negative, no key press
   mv s3, a0
   mv a0, s3
   li a7, 1 # SBI Putchar ID
   ecall 
   j wait_for_key

end:
  j end



