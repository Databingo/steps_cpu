.globl _start

.section .data
msg_boot:
    .string "--Full instructions test for run Linux Kernel--"
mem_test_var:
    .dword 0x0000000000000000


# Bootloader/copy4 --> firmware/BIOS/opensib/mini_sbi2 --> OS/linux/kernal
.section .text
_start:  
  j main # like linux kernel

s_trap_handler:
  #li a0, "\n"
  #li a7, 1
  #ecall   # here ecall was not delegated to s_mode, so go to mtvec to find m-mode ecall handler
  #li a0, "S_TRAP"
  #call sbi_print7

   csrr t1, scause
   li t2, 0x8000000000000005 # bit 63 set + code 5 (Supervisor Timer)
   beq t1, t2, timer_found

  #bltz a0, handle_interrupt
   # handle exception
  #call sbi_print_reg
  #csrr a0, stval
  #call sbi_print_reg
  #csrr a0, sepc
  #call sbi_print_reg
  #csrr a0, sstatus
  #call sbi_print_reg
  #exception s-done
   csrr t2, sepc
   addi t2, t2, 4 # skip ecall/ebreak instruction
   csrw sepc, t2
   sret

timer_found:
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
   li t0, 1000
check_clock:
   csrr a0, time
   call sbi_print_reg
   addi t0, t0, -1
   bnez t0, check_clock

  #sub t0, s1, s0
  #li t1, 100000
  #blt t0, t1, check_clock

   
   # Step 1 test ecall (sbi) print
  #la a0, msg_boot
  #call sbi_puts

   # Step 2 test S-Mode trap hander # Opensbi delegate Ebreak to OS, so we set our handler address to stvec
   la t0, s_trap_handler
  #andi t0, t0, -4 # Align to 4 bytes
   csrw stvec, t0
   ebreak
  #li a0, "\nStrpOK"
  #call sbi_print7


  ## Set Timer
   li t0, 0x20 # enable STIE bit 5
   csrs sie, t0
   csrsi sstatus, 2  # enable global SIE bit 1
  
   csrr a0, time # read time
  #li t0, 10000000 # 1 second
   li t0, 100000 # 1 second
   add a0, a0, t0
   li a7, 0  # SBI Set Timer ID
   ecall

#wait_for_timer: # wait strap_handler print timecmp trap
#   wfi
#   j wait_for_timer









   # Step 3 test MMU
   # 1.Build SV39 root table in sdram (4KB per table 2**9=512*8=4096) vpn2 4KB map 512*4k=2MBram; all vpn1=4*512=2Mb map 512*2M=1Gram, all vpn0=512*512=262144*4kb=1GB map 512Gram,total VPNs 4KB+2MB+1024MB
   li t0, 0x80700000 # set base address of MMU root table

   # 2. map vma 0x0000_0000 to ppa 0x0000_0000, ppn =  ppa >> 12 = 0, for UART/CLINT/PLIC .etc
   li t1, 0xcf       # pte = ppn << 10 | flags valid0 read1 write2 exec3 accessed6 dirty7 0b11001111=0xcf
   sd t1, 0(t0) 

   # 3. map vma 0x8000_0000 to ppa 0x8000_0000, ppn =  ppa >> 12 = 0x80000 pte = ppn << 10 | flags, for RAM/Code
   li t1, 0x200000cf # pte = ppn << 10 | flags valid0 read1 write2 exec3 accessed6 dirty7 0b11001111=0xcf
   sd t1, 16(t0)     # Index=va[38:30]=0b00000010=2, 8 bytes per PTE = 16, 

   # satp need ppn of root table rt 0x80700000 
   # satp = satp[63:60].MODE(0:bare, 8:sv39, 9:sv48)|satp[59:44].asid|satp[43:0].rootpage_physical_addr(vpn2:9|vpn1:9|vpn0:9|offseet12)
   # ppn = rt >> 12 = 0x80700
   # mode = 3 sv39
   li t0, 0x8000000000080700
   # Turn MMU SV39
   csrw satp, t0 # write mode and root table address to satp CSR register
   sfence.vma ## <--- start use TLB I/D hitting

  #li a0, "\nMMUOK"
  #call sbi_print7
 
   # ======================================
   # Chain test for riscv64ima instructions
   # Accumulator register: s11
   # ======================================

   # 1 Lui
   lui s11, 0x12345         # s11 = 0x0000000012345000

   # 3/4 ls
   la a2, mem_test_var
   # Test Byte (sb/lb/lbu)
   li t4, 0x8F  # A negative-looking byte
   sb t4, 0(a2)
   lb t5, 0(a2) # 0xFFFFFFFFFFFFFF8F
   lbu t6, 0(a2)# 0x000000000000008F
   li t1, 0x8F
   bne t6, t1, fail_chain

   # Test Half (sh/lh/lhu)
   li t4, 0x8FEE  # A negative-looking half
   sh t4, 0(a2)
   lh t5, 0(a2) # 0xFFFFFFFFFFFF8FEE
   lhu t6, 0(a2)# 0x0000000000008FEE
   li t1, 0x8FEE
   bne t6, t1, fail_chain

   # Test Word (sw/lw/lwu)
   li t4, 0x8FEEDCBA  # A negative-looking word
   sw t4, 0(a2)
   lw t5, 0(a2) # 0xFFFFFFFF8FEEDBCA
   lwu t6, 0(a2)# 0x000000008FEEDBCA`
   li t1, 0x8FEEDCBA
   bne t6, t1, fail_chain

   # Test Doube Word (sd/ld)
   sd s11, 0(a2)
   ld s11, 0(a2)
  #li a0, "\nLSOK"
  #call sbi_print7

   # 5 math-i (addi, xori, andi, ori, slli, srli, srai, slti, sltiu)
   addi s11, s11, 0x678     # s11 = 0x12345678
   xori s11, s11, 0x111     # s11 = 0x12345769
   andi s11, s11, 0xFFF     # s11 = 0x12345769
   ori s11, s11, 0x800      # s11 = 0xFFFFFFFFFFFFFF69
   li a2, 0xFFF 
   and s11, s11, a2         # s11 = 0x0000000000000F69
   li t1, 0x0000000000000F69
   bne s11, t1, fail_chain
  #li a0, "\nMthiOK"
  #call sbi_print7

   slli s11, s11, 4         # s11 = 0x0000F690
   srli s11, s11, 4         # s11 = 0x00000F69
   srai s11, s11, 0         # s11 = 0x00000F69 (MSB is 0)
   slti a3, s11, 0         # a3 = 0
   add  s11, s11, a3        # s11 = 0x00000F69
   sltiu a3, s11, 0        # a3 = 0
   add  s11, s11, a3        # s11 = 0x00000F69
   li t1,  0x00000F69
   bne s11, t1, fail_chain
  #li a0, "\nShifOK"
  #call sbi_print7

   # 6 math-iw (addiw, slliw, srliw, sraiw)
   addiw s11, s11, 1        # s11 = 0x00000F6A
   slliw s11, s11, 16       # s11 = 0x0F6A0000
   srliw s11, s11, 16       # s11 = 0x00000F6A
   sraiw s11, s11, 0        # s11 = 0x00000F6A
   li t1,  0x00000F6A
   bne s11, t1, fail_chain
  #li a0, "\nMthiwK"
  #call sbi_print7

   # 7 mathr (add, sub, xor, and, or, sll, srl, sra, slt, sltu)
   li a2, 0x111
   add s11, s11, a2          # s11 = 0x107B
   sub s11, s11, a2          # s11 = 0x0F6A
   xor s11, s11, a2          # s11 = 0x0E7B
   and s11, s11, s11          # s11 = 0x0E7B
   or  s11, s11, a2          # s11 = 0x0F7B
   li a2, 4
   sll s11, s11, a2          # s11 = 0x0F7B0
   srl s11, s11, a2          # s11 = 0x00F7B
   sra s11, s11, a2          # s11 = 0x000F7
   li a2, 0
   slt a3, a2, s11          # a3 = 1
   add s11, s11, a3          # s11 = 0x000F8
   sltu a3, a2, s11         # a3 = 1
   add s11, s11, a3          # s11 = 0x000F9
   li t1,  0x000F9
   bne s11, t1, fail_chain
  #li a0, "\nMthrOK"
  #call sbi_print7

   # 8 math-rw (addw, subw, sllw, srlw, sraw)
   li a2, 1
   addw s11, s11, a2         # s11 = 0x000FA
   subw s11, s11, a2         # s11 = 0x000F9
   li a2, 4
   sllw s11, s11, a2         # s11 = 0x00F90
   srlw s11, s11, a2         # s11 = 0x000F9
   sraw s11, s11, a2         # s11 = 0x0000F
   li t1,  0x000F
   bne s11, t1, fail_chain
   li a0, "\nMthrwK"
   call sbi_print7

   # 9 jump
   jal a2, jump_target_1
jump_target_1:
   addi s11, s11, 1          # s11 = 0x00010
   la a2, jump_target_2
   jalr a2, 0(a2)
jump_target_2:
   addi s11, s11, 1          # s11 = 0x00011
  #li a0, "\nJumpOK"
  #call sbi_print7

   # 10 branch (beq, bne, blt, bge, bltu, bgeu)
   beq s11, s11, branch_target_3
branch_target_3:
   addi s11, s11, 1
   li a2, 0
   bne s11, a2, branch_target_4
branch_target_4:
   addi s11, s11, 1
   blt a2, s11, branch_target_5
branch_target_5:
   addi s11, s11, 1
   bge s11, a2, branch_target_6
branch_target_6:
   addi s11, s11, 1
   bltu a2, s11, branch_target_7
branch_target_7:
   addi s11, s11, 1
   bgeu s11, a2, branch_target_8
branch_target_8:
   addi s11, s11, 1
   li t1,  0x17
   bne s11, t1, fail_chain
   li a0, "\nBrJOK"
   call sbi_print7

  # 11 CSR
  csrw sscratch, s11
  csrr s11, sscratch
  csrrs a3, sscratch, zero
  csrrc a3, sscratch, zero
  csrrwi a3, sscratch, 0
  csrrsi a3, sscratch, 0
  csrrci a3, sscratch, 0
  li a0, "\nCSROK"
  call sbi_print7

   # 12 Atomic
   la a2, mem_test_var

   lr.w t3, (a2)
   sc.w t4, s11, (a2)
   ld s11, 0(a2)

   lr.d a3, (a2)
   sc.d a4, s11, (a2)
   ld s11, 0(a2)           # s11 = 0x00017

   li t1,  0x17
   bne s11, t1, fail_chain
  #li a0, "\nAtomOK"
  #call sbi_print7
  
   amoswap.w t3, s11, (a2) # M[a2]=0x17, t3=0x17
   amoadd.w  t3, s11, (a2) # M[a2]=0x2E, t3=0x17
   amoxor.w  t3, s11, (a2) # M[a2]=0x39, t3=0x2E
   amoand.w  t3, s11, (a2) # M[a2]=0x11, t3=0x39
   amoor.w   t3, s11, (a2) # M[a2]=0x17, t3=0x11
   amomax.w  t3, s11, (a2) # M[a2]=0x17, t3=0x17
   amomin.w  t3, s11, (a2) # M[a2]=0x17, t3=0x17
   amomaxu.w t3, s11, (a2) # M[a2]=0x17, t3=0x17
   amominu.w t3, s11, (a2) # M[a2]=0x17, t3=0x17
  #lw s11, 0(a2)           # s11 = 0x00017
  #li t0, 0x17
  #bne s11, t0, fail_chain
  #li a0, "\nAmowOK"
  #call sbi_print7

   amoswap.d t3, s11, (a2) # M[a2]=0x17, t3=0x17
   amoadd.d  t3, s11, (a2) # M[a2]=0x2E, t3=0x17
   amoxor.d  t3, s11, (a2) # M[a2]=0x39, t3=0x2E
   amoand.d  t3, s11, (a2) # M[a2]=0x11, t3=0x39
   amoor.d   t3, s11, (a2) # M[a2]=0x17, t3=0x11
   amomax.d  t3, s11, (a2) # M[a2]=0x17, t3=0x17
   amomin.d  t3, s11, (a2) # M[a2]=0x17, t3=0x17
   amomaxu.d t3, s11, (a2) # M[a2]=0x17, t3=0x17
   amominu.d t3, s11, (a2) # M[a2]=0x17, t3=0x17
   ld s11, 0(a2)           # s11 = 0x00017
   li t0, 0x17
   bne s11, t0, fail_chain
  #li a0, "\nAmodOK"
  #li a0, "\nAmoOK"
  #call sbi_print7

   # 13 Mul
   li a2, 2
   mul s11, s11, a2  # s11 = 23 * 2 = 46
  #nop
   mulh a3, s11, a2 # a3 = High 64 bit of 92 = 0
   add s11, s11, a3  # s11 = 46
   mulw s11, s11, a2 # s11 = 46 * 2 = 92 (0x5C)

   li t1, 94
   sub s11, s11, t1    # s11 = 92-94 =-2
   li a2, -3
   mulh a3, s11, a2   # a3=0  -2*-3=6, High 64 is 0
   add s11, s11, a3    # s11 = -2 + 0 = -2
   mulhu a3, s11, a2  # a3 = -5  usign*usign H is -5
   add s11, s11, a3    # s11 = -2 + (-5)  -7
   mulhsu a3, s11, a2 # a3 = -7  sign*unsign H is -7
   add s11, s11, a3    # s11 = -7 + (-7) = -14
   addi s11, s11, 106

   li t1, 0x000000000000005C 
   bne s11, t1, fail_chain
  #li a0, "\nMulOK"
  #call sbi_print7

  # 14 Div
   # div/rem
   li a2, 3        # s11 = 0x000000000000005C 
   div a3, s11, a2  # a3 = 0x000000000000001E
  #mv a0, a3
  #call sbi_print_reg
   rem a4, s11, a2  # a4 = 0x0000000000000002
  #mv a0, a4
  #call sbi_print_reg
   add s11, s11, a3  # s11 = 92+30=122
   add s11, s11, a4  # s11 = 122+2=124

   # divw/remw
   li t1, 0x80000000
   add s11, s11, t1  # s11 = 0x8000007C
   li a2, 2
   divw a3, s11, a2  # a3 = 0xFFFFFFFFC000003E
  #mv a0, a3
  #call sbi_print_reg
   remw a4, s11, a2  # a4 = 0
  #mv a0, a4
  #call sbi_print_reg
   add s11, s11, a3  # s11 = 0x8000007C +  0xFFFFFFFFC000003E = 0x400000BA
   add s11, s11, a4  # s11
  #mv a0, s11
  #call sbi_print_reg

   # divu/remu
   lui t1, 0x40000
   addi t1, t1, 0x100  # t1 = 0x40000100
   sub s11, s11, t1 # s11 =  0x400000BA - 0x40000100 = 0xFFFFFFFFFFFFFFBA = -70
   li a2, 3
   divu a3, s11, a2  # a3 = 0x555555555555553E
  #mv a0, a3
  #call sbi_print_reg
   remu a4, s11, a2  # a4 = 0
   add s11, s11, a3  # s11 = 0xFFFFFFFFFFFFFFBA + 0x555555555555553E = 0x55555555555554F8
   add s11, s11, a4  # s11
  #mv a0, s11
  #call sbi_print_reg

   # divuw/remuw
   li t1, -1
   slli t1, t1, 31 # t1 = 0xFFFFFFFF80000000
   add s11, s11, t1 # s11 =  0x55555555555554F8 +  0xFFFFFFFF80000000 = 0x55555554D55554F8
   li a2, 5
   divuw a3, s11, a2  # a3 = 0x000000002AAAAA98
  #mv a0, a3
  #call sbi_print_reg
   remuw a4, s11, a2  # a4 = 0
   add s11, s11, a3  # s11 =  0x55555554D55554F8 +  0x000000002AAAAA98 = 0x55555554FFFFFF90
   add s11, s11, a4  # s11

   li t1, 0x55555554FFFFFF90
   bne s11, t1, fail_chain
   li a0, "\nDivOK"
   call sbi_print7

   li s11, 0x0000000080000000 
   # div by 0 = -1
   li a2, 5
   li a3, 0
   div t1, a2, a3
   li t2, -1
   bne t1, t2, fail_chain
   
   # rem by 0 = rem
   rem t1, a2, a3
   bne t1, a2, fail_chain
  
   # Overflow INT_MIN/-1 = INT_MIN
   li a2, 1
   slli a2, a2, 63 # a2 = 0x8000000000000000
   li a3, -1
   div t1, a2, a3
   bne t1, a2, fail_chain

   li a0, "\nExtrOK"
   call sbi_print7

   
   fence
   fence.i
  #li a0, "\nFencOK"
  #call sbi_print7

   # FINAL CHECK
   li t1, 0x0000000080000000
   bne s11, t1, fail_chain

   # Success
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



