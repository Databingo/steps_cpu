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
   # ----- 1. MUL / MULH / MULHU / MULHSU -----
   # Basic positive
   li s11, 0x1111
   li a2,  0x2222
   mul t1, s11, a2
   li t2, 0x2468642
   bne t1, t2, fail_chain

   # Negative * Positive (64-bit)
   li s11, -10
   li a2,  20
   mul t1, s11, a2
   li t2, -200
   bne t1, t2, fail_chain

   # Negative * Negative High (MULH)
   li s11, -3
   li a2,  -3
   mulh t1, s11, a2
   li t2, 0
   bne t1, t2, fail_chain

   # Unsigned High (MULHU)
   li s11, -1  # 0xFFFFFFFFFFFFFFFF
   li a2,  2
   mulhu t1, s11, a2
   li t2, 1    # (2^64 - 1)*2 = 2^65 - 2, High 64 is 1
   bne t1, t2, fail_chain

   # Signed * Unsigned High (MULHSU)
   li s11, -2  # Signed
   li a2, 3    # Unsigned
   mulhsu t1, s11, a2
   li t2, -1   # -6 = 0xFFFFFFFFFFFFFFFA, High is -1
   bne t1, t2, fail_chain

   # Word Multiplication (MULW)
   li s11, 0x100000000  # > 32 bit
   addi s11, s11, 5
   li a2, 3
   mulw t1, s11, a2     # Should truncate, 5 * 3 = 15
   li t2, 15
   bne t1, t2, fail_chain

   li s11, 0x40000000   # 2^30
   li a2, 2
   mulw t1, s11, a2     # 2^31, sign extended -> 0xFFFFFFFF80000000
   li t2, -1
   slli t2, t2, 31
   bne t1, t2, fail_chain


   # ----- 2. DIV / REM (64-bit) -----
   # Basic division and remainder
   li s11, 100
   li a2, 33
   div t1, s11, a2
   li t2, 3
   bne t1, t2, fail_chain
   rem t1, s11, a2
   li t2, 1
   bne t1, t2, fail_chain

   # Negative division (round to zero)
   li s11, -100
   li a2, 33
   div t1, s11, a2
   li t2, -3
   bne t1, t2, fail_chain
   rem t1, s11, a2
   li t2, -1
   bne t1, t2, fail_chain

   li s11, 100
   li a2, -33
   div t1, s11, a2
   li t2, -3
   bne t1, t2, fail_chain
   rem t1, s11, a2
   li t2, 1      # Sign of remainder = Sign of dividend
   bne t1, t2, fail_chain

   li s11, -100
   li a2, -33
   div t1, s11, a2
   li t2, 3
   bne t1, t2, fail_chain
   rem t1, s11, a2
   li t2, -1
   bne t1, t2, fail_chain

   # Unsigned division (DIVU / REMU)
   li s11, -100  # Huge positive number when unsigned
   li a2, 10
   divu t1, s11, a2
   li t2, 0x199999999999998F # (-100 / 10) unsigned
   bne t1, t2, fail_chain


   # ----- 3. DIVW / REMW (32-bit Word Division) -----
   # Positive 32-bit overflow check
   li s11, 0x100000000  # 2^32
   addi s11, s11, 10    # Bottom 32 is 10
   li a2, 3
   divw t1, s11, a2     # 10 / 3 = 3
   li t2, 3
   bne t1, t2, fail_chain

   # Sign extension of 32-bit result
   li s11, 0x80000000   # -2147483648 (INT32_MIN)
   li a2, 2
   divw t1, s11, a2     # Result should be -1073741824, sign extended to 64
   li t2, 0xFFFFFFFFC0000000
   bne t1, t2, fail_chain

   # DIVUW / REMUW
   li s11, 0x80000000
   li a2, 2
   divuw t1, s11, a2    # Treated as +2147483648, result is +1073741824
   li t2, 0x0000000040000000
   bne t1, t2, fail_chain


   # ----- 4. CORNER CASES (Div by Zero & Overflow) -----
   # Divide by zero
   li s11, 55
   li a2, 0
   div t1, s11, a2
   li t2, -1           # RISC-V spec: div by 0 returns -1
   bne t1, t2, fail_chain

   rem t1, s11, a2
   bne t1, s11, fail_chain # RISC-V spec: rem by 0 returns dividend

   divu t1, s11, a2
   li t2, -1
   bne t1, t2, fail_chain

   # Overflow (INT_MIN / -1)
   li s11, 1
   slli s11, s11, 63   # INT64_MIN
   li a2, -1
   div t1, s11, a2
   bne t1, s11, fail_chain # RISC-V spec: overflow returns INT_MIN

   rem t1, s11, a2
   li t2, 0
   bne t1, t2, fail_chain # RISC-V spec: overflow rem returns 0

   # Word Overflow (INT32_MIN / -1)
   li s11, 0x80000000
   li a2, -1
   divw t1, s11, a2
   li t2, 0xFFFFFFFF80000000 # Sign extended INT32_MIN
   bne t1, t2, fail_chain

   remw t1, s11, a2
   li t2, 0
   bne t1, t2, fail_chain

   # Set s11 back to indicator if pass
   li s11, 0x0000000080000000 

# ----- 5. LINUX VFS HASHING (64-bit / 32-bit wrapping) -----
   # Linux hash_64() requires exact behavior for val * 0x9e37fffffffc0001
   li s11, 0x9e37fffffffc0001
   li a2, 2
   mul t1, s11, a2
   li t2, 0x3c6ffffffff80002
   bne t1, t2, fail_chain

   # Max 64-bit multiplication wrapping (-1 * -1)
   li s11, -1 # 0xFFFFFFFFFFFFFFFF
   li a2, -1
   mul t1, s11, a2
   li t2, 1
   bne t1, t2, fail_chain

   # 64-bit extreme power wrapping (2^63 * 2^63 should wrap strictly to 0)
   li s11, 1
   slli s11, s11, 63 # 0x8000000000000000
   mv a2, s11
   mul t1, s11, a2
   li t2, 0
   bne t1, t2, fail_chain

   # 32-bit Unsigned x 32-bit Unsigned into 64-bit Unsigned via MUL
   li s11, 0xFFFFFFFF
   li a2,  0xFFFFFFFF
   mul t1, s11, a2
   li t2, 0xFFFFFFFE00000001
   bne t1, t2, fail_chain

   # ----- 6. CRITICAL REMUW / DIVUW CORNER CASES -----
   # RISC-V SPEC: REMUW must sign-extend the 32-bit remainder to 64-bit.
   # If remainder has the 31st bit set, it MUST extend with FFs.
   li s11, 0x80000000   # 2147483648 Unsigned
   li a2,  0x80000001   # 2147483649 Unsigned
   remuw t1, s11, a2    # 2147483648 / 2147483649 = 0, Remainder = 0x80000000
   li t2, 0xFFFFFFFF80000000 # Critical: Must be Sign Extended!
   bne t1, t2, fail_chain

   # DIVUW division by zero
   li s11, 0x12345678
   li a2, 0
   divuw t1, s11, a2
   li t2, -1            # Spec requires returning all 1s (0xFFFFFFFFFFFFFFFF)
   bne t1, t2, fail_chain

   # REMUW division by zero 
   li s11, 0x80000005
   li a2, 0
   remuw t1, s11, a2
   li t2, 0xFFFFFFFF80000005 # Spec requires sign-extended dividend!
   bne t1, t2, fail_chain

   # ----- 7. UNSIGNED OVERFLOW ILLUSIONS -----
   # INT64_MIN / -1 but Unsigned. 
   # This is NOT an overflow, it's just 2^63 / (2^64 - 1)
   li s11, 1
   slli s11, s11, 63    # 0x8000000000000000
   li a2, -1            # 0xFFFFFFFFFFFFFFFF
   divu t1, s11, a2
   li t2, 0             # 2^63 < (2^64 - 1), so quotient is 0
   bne t1, t2, fail_chain
   
   remu t1, s11, a2
   bne t1, s11, fail_chain # Remainder is the dividend (0x8000000000000000)

# ----- 8. PIPELINE & DATA FORWARDING HAZARDS -----
   # 1. Immediate Back-to-Back Dependency
   # Tests if your CPU correctly stalls/forwards the result of a long division
   li s11, 100
   li a2, 10
   div t1, s11, a2    # t1 takes many cycles to become 10
   mul t2, t1, a2     # immediately requires t1! t2 = 100
   bne t2, s11, fail_chain

   # 2. DIV / REM paired execution hazard
   # Linux GCC compilers frequently put DIV and REM back-to-back.
   # If your CPU shares the same hardware divider, this can cause a structural hazard.
   li s11, 23
   li a2, 5
   div t1, s11, a2    # t1 = 4
   rem t2, s11, a2    # t2 = 3 (Should wait for divider to free up)
   add t3, t1, t2     # immediately use both (4 + 3 = 7)
   li t4, 7
   bne t3, t4, fail_chain

   # 3. Write to x0 (Zero Register Trap Check)
   # Linux sometimes uses instructions with x0 destination to discard data.
   # If your divider writes back to x0, it must not corrupt the zero register!
   li s11, 55
   li a2, 2
   div x0, s11, a2    # Should do nothing, must not crash
   mul x0, s11, a2    # Should do nothing, must not crash
   bne x0, x0, fail_chain # x0 MUST still be 0!



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



