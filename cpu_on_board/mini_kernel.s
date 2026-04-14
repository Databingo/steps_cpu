.globl _start

.section .data
msg_boot:
    .string "--S-Mode_mini_Kernel_boot--"
msg_mmu:
    .string "--MMU_test--"
msg_rx:
    .string "key_press: "
mem_test_var:
    .dword 0x0000000000000000


# Bootloader/copy4 --> firmware/BIOS/opensib/mini_sbi2 --> OS/linux/kernal
.section .text
_start:  # like linux kernel

   li sp, 0x80700000 # Set stack # 80000000-8080000 sdram as 8M ram, we start sp from 0x80700000<-, MMU from 0x80700000->
 
   # Step 1 test ecall (sbi) print
   la a0, msg_boot
   call sbi_puts
   # --- 1 ok

   # Step 2 test A-Extension Atomics
   la t0, mem_test_var
   li t1, 1
   amoadd.w t2, t1, (t0)
   li a0, "\nAtomok"
   call sbi_print7


   # Step 3 test S-Mode trap hander
   # Opensbi delegate Ebreak to OS, so we set our handler address to stvec
   la t0, s_trap_handler
   andi t0, t0, -4 # Align to 4 bytes
   csrw stvec, t0
   ebreak
   li a0, "\nStrpok"
   call sbi_print7


   # Step 4 test MMU
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

   la a0, msg_mmu   # trigger I-TLB miss
   call sbi_puts
 

   # ALU
   lui t0, 0x12345
   addi t0, t0, 0x678   
   li t1, 0x11111111
   add t2, t0, t1  # 0x23456789
   sub t3, t2, t1
   li a0, "\nF_alu"
   bne t0, t3, fail_alu

   xori t4, t0, 0xFFF
   ori t5, t4, 0xF00
   andi t6, t5, 0x0FF
   li t1, 0x87
   li a0, "\nF_alux"
   bne t6, t1, fail_alu

   li t0, -10
   li t1, 5
   slt t2, t0, t1 #1
   sltu t3, t0, t1 #0
   slti t4, t1, 10 #1
   sltiu t5, t0, 10 #0
   add t6, t2, t4 #2
   add t6, t6, t3 #2
   add t6, t6, t5 #2
   li t1, 2
   li a0, "\nF_alus"
   bne t6, t1, fail_alu

li t0, 0x0F
slli t1, t0, 4 #0xF0
srl t2, t1, t0
li t3, 0xF0000000
mv a0, t3
call sbi_print_reg
sraiw t4, t3, 4 #0xFF000000
mv a0, t4
call sbi_print_reg
li t5, 0xFFFFFFFFFF000000
li a0, "\nF_alur"
bne t4, t5, fail_alu


  
# ========================================================
   # THE "ONELINE" SEQUENTIAL EXECUTION TEST (Fixed for rvas.go)
   # Accumulator register: a1
   # ========================================================

   # [1] U-Type: Lui
   lui a1, 0x12345        # a1 = 0x0000000012345000
   
   # [2] U-Type: Auipc (Test it executes, doesn't ruin a1)
   auipc a2, 0

   # [3/4] Memory: Store then Load
   la a2, mem_test_var
   sd a1, 0(a2)           # Store 0x12345000
   ld a1, 0(a2)           # Load  0x12345000

   # [5] Math-I (addi, xori, andi, ori, slli, srli, srai, slti, sltiu)
   addi a1, a1, 0x678     # a1 = 0x12345678
   xori a1, a1, 0x111     # a1 = 0x12345769
   andi a1, a1, 0xFFF     # a1 = 0x00000769
   ori  a1, a1, 0x800     # a1 = 0x00000F69
   slli a1, a1, 4         # a1 = 0x0000F690
   srli a1, a1, 4         # a1 = 0x00000F69
   srai a1, a1, 0         # a1 = 0x00000F69 (MSB is 0)
   slti a3, a1, 0         # a3 = 0 (0xF69 is not < 0)
   add  a1, a1, a3        # a1 = 0x00000F69
   sltiu a3, a1, 0        # a3 = 0
   add  a1, a1, a3        # a1 = 0x00000F69

   # [6] Math-I Word (addiw, slliw, srliw, sraiw)
   addiw a1, a1, 1        # a1 = 0x00000F6A
   slliw a1, a1, 16       # a1 = 0x0F6A0000
   srliw a1, a1, 16       # a1 = 0x00000F6A
   sraiw a1, a1, 0        # a1 = 0x00000F6A

   # [7] Math-R (add, sub, xor, and, or, sll, srl, sra, slt, sltu)
   li a2, 0x111
   add a1, a1, a2         # a1 = 0x107B
   sub a1, a1, a2         # a1 = 0x0F6A
   xor a1, a1, a2         # a1 = 0x0E7B
   and a1, a1, a1         # a1 = 0x0E7B
   or  a1, a1, a2         # a1 = 0x0F7B
   li a2, 4
   sll a1, a1, a2         # a1 = 0x0F7B0
   srl a1, a1, a2         # a1 = 0x00F7B
   sra a1, a1, a2         # a1 = 0x000F7
   li a2, 0
   slt a3, a2, a1         # a3 = 1 (0 < 0xF7)
   add a1, a1, a3         # a1 = 0x000F8
   sltu a3, a2, a1        # a3 = 1 (0 < 0xF8)
   add a1, a1, a3         # a1 = 0x000F9

   # [8] Math-R Word (addw, subw, sllw, srlw, sraw)
   li a2, 1
   addw a1, a1, a2        # a1 = 0x000FA
   subw a1, a1, a2        # a1 = 0x000F9
   li a2, 4
   sllw a1, a1, a2        # a1 = 0x00F90
   srlw a1, a1, a2        # a1 = 0x000F9
   sraw a1, a1, a2        # a1 = 0x0000F

   # [9] Jump (jal, jalr)
   jal a2, jump_target_1             
jump_target_1: 
   addi a1, a1, 1         # a1 = 0x00010
   la a2, jump_target_2
   jalr a2, 0(a2)         
jump_target_2: 
   addi a1, a1, 1         # a1 = 0x00011

   # [10] Branch (beq, bne, blt, bge, bltu, bgeu)
   beq a1, a1, branch_target_3         
branch_target_3: 
   addi a1, a1, 1         # a1 = 0x00012
   li a2, 0
   bne a1, a2, branch_target_4         
branch_target_4: 
   addi a1, a1, 1         # a1 = 0x00013
   blt a2, a1, branch_target_5         
branch_target_5: 
   addi a1, a1, 1         # a1 = 0x00014
   bge a1, a2, branch_target_6         
branch_target_6: 
   addi a1, a1, 1         # a1 = 0x00015
   bltu a2, a1, branch_target_7        
branch_target_7: 
   addi a1, a1, 1         # a1 = 0x00016
   bgeu a1, a2, branch_target_8        
branch_target_8: 
   addi a1, a1, 1         # a1 = 0x00017

#  # [11] System-CSR (Write to mscratch so we don't break privileges)
#  csrw mscratch, a1      # mscratch = 0x17
#  csrr a1, mscratch      # a1 = 0x17
#  csrrs a3, mscratch, zero
#  csrrc a3, mscratch, zero
#  csrrwi a3, mscratch, 0
#  csrrsi a3, mscratch, 0
#  csrrci a3, mscratch, 0 
#  # a1 is still 0x17
# [11] System-CSR (Use sscratch because mscratch traps in S-mode!)
   csrw sscratch, a1      # sscratch = 0x17
   csrr a1, sscratch      # a1 = 0x17
   csrrs a3, sscratch, zero
   csrrc a3, sscratch, zero
   csrrwi a3, sscratch, 0
   csrrsi a3, sscratch, 0
   csrrci a3, sscratch, 0 
   # a1 is still 0x17



   # [12] Atomic
   la a2, mem_test_var
   lr.d a3, (a2)          
   sc.d a4, a1, (a2)      
   ld a1, 0(a2)           # a1 = 0x00017

   # [13] M-Mul
   li a2, 2
   mul a1, a1, a2         # a1 = 0x17 * 2 = 0x2E
   mulh a3, a1, a2        # a3 = 0
   add a1, a1, a3         # a1 = 0x2E
   mulw a1, a1, a2        # a1 = 0x2E * 2 = 0x5C

   # [14] M-Div
   div a1, a1, a2         # a1 = 0x5C / 2 = 0x2E
   rem a3, a1, a2         # a3 = 0x2E % 2 = 0
   add a1, a1, a3         # a1 = 0x2E
   divw a1, a1, a2        # a1 = 0x2E / 2 = 0x17
   remw a3, a1, a2        # a3 = 0x17 % 2 = 1
   add a1, a1, a3         # a1 = 0x17 + 1 = 0x18

   # ========================================================
   # FINAL CHECK
   # ========================================================
   mv a0, a1
   call sbi_print_reg
   li t2, 0x0000000000000018
   bne a1, t2, fail_chain

   # Success!
   li a0, "\nChainOK"
   call sbi_print7
   j end_of_chain_test

fail_chain:
   # Failed! Print register to see exactly where it broke
   mv a0, a1
   call sbi_print_reg
   li a0, "\nFAIL!!"
   call sbi_print7
halt_loop_chain: 
   j halt_loop_chain

end_of_chain_test:



pause:
j pause

fail_alu:
  call sbi_print7



















 
   # Step 5 test Typing 
   li a0, "\ntyping"
   call sbi_print7

wait_for_key:
   li a7, 2  # SBI Getchar ID
   ecall
   bltz a0, wait_for_key  # if a0 is negative, no key press
   mv s3, a0

   la a0, msg_rx
   call sbi_puts
  
   mv a0, s3
   li a7, 1 # SBI Putchar ID
   ecall 
   
   li a0, "\n\r"
   call sbi_print7

j wait_for_key
end:
j end




s_trap_handler:
   li a0, "\n"
   li a7, 1
   ecall   # here ecall was not delegated to s_mode, so go to mtvec to find m-mode ecall handler
   li a0, "strap.."
   call sbi_print7
   j s_done

s_done: 
   csrr s2, sepc
   addi s2, s2, 4 # skip ecall/ebreak instruction
   csrw sepc, s2
   sret


sbi_puts: # a0 addr
    addi sp, sp, -16
    sd ra, 0(sp)
    sd s0, 8(sp)
    mv s0, a0
    sbi_puts_loop:
    lbu a0, 0(s0)
    beq a0, x0, sbi_stop_puts # \x00 for end of string
    li a7, 1 # SBI Putchar ID
    ecall
   #call putchar # a0 char
    addi s0, s0, 1 # next byte
    j sbi_puts_loop
    sbi_stop_puts:
    ld ra, 0(sp)
    ld s0, 8(sp)
    addi sp, sp, 16
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

sbi_putchar:  # a0
    addi sp, sp, -8
    sd ra, 0(sp)
    li a7, 1 # SBI Putchar ID
    ecall
    ld ra, 0(sp)
    addi sp, sp, 8
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

