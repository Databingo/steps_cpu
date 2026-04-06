.globl _start

.section .data
msg:
    .string "Hello"


.section .text
_start:
   li sp, 0x80700000 # Set stack # 80000000-8080000 sdram as 8M ram, we start sp from 0x80700000<-, MMU from 0x80700000->
   li s11, 0x2004 # UART print 
   li s10, 0x2008 # UART controller
   # function use stacked s 
   # handlers use s
   # kernel use t

   la t0, m_trap_router      # 1. setup m-mode trap handler
   andi t0, t0, -4 # align 4 byte for directory mode of tvec
   csrw mtvec, t0

   la t0, s_trap_handler     # 2. setup s-mode trap handler
   andi t0, t0, -4
   csrw stvec, t0


   li t0, 0xffffffffffffffff # 3. Unlock PMP (Physical Memory Protection) which prevent S-mode to touch hardware -1
   csrw pmpaddr0, t0
   li t0, 0x1f               # 4. config TOR mode, Read/Write/Execute permissions L(0), A(01=TOR), X(1), W(1), R(1)=00011111=31=0x1f
   csrw pmpcfg0, t0

   csrw medeleg, zero        # No delegation (let M-mode handler take care)
   #li t0, 0b1000            # Do delegate breakpoint to s-mode
   #csrw medeleg, t0

  #li t1, 0xB109             # Excepitons medeleg mask (Ecall,PageFaults...)
  #csrw medeleg, t1
  #li t1, 0x222              # Interrupts medeleg mask (SSI,STI,SEI)
  #csrw mideleg, t1



                            # 5. prepare the jump to S-mode 
   li t0, 0b100000000000    # set mstatus.MPP to 01 (S-mode), Bit 11:12 is MPP
   csrs mstatus, t0
   la t0, s_mode_kernel      # set mepc to the address of our S-mode kernel
   csrw mepc, t0

   li t1, 62 # >
   sw t1, 0(s11)
   mret                      # 6. Drop to S-mode go to s_kernel


s_mode_kernel:
   ebreak   # M  test m-mode ebreak

   #li a0, "H"
   #li a7, 1
   #ecall

   #li a0, "i"
   #li a7, 1
   #ecall
 
   li a7, 0x10
   ecall  # turn delegate (test 3 breakpoint)

   ebreak # S ebreak was delegeted to s-mode, so use stvec to find s-handler for break


   # test MMU
   li a0, "\nMMU:" 
   call print7
   
   # simple test
   #li t0, 1
   #slli t0, t0, 63 # sv39 satp[63:60] MODE to 8
   #csrw satp, t0
   ## <--- start TLB I/D hitting

   # real test
   # 1.Build SV39 root table in sdram (4KB per table 2**9=512*8=4096) vpn2 4KB map 512*4k=2MBram; all vpn1=4*512=2Mb map 512*2M=1Gram, all vpn0=512*512=262144*4kb=1GB map 512Gram,total VPNs 4KB+2MB+1024MB
   li t0, 0x80700000 # set base address of MMU root table

   # 2. map vma 0x0000_0000 to ppa 0x0000_0000, ppn =  ppa >> 12 = 0, for UART/CLINT
   li t1, 0xcf       # pte = ppn << 10 | flags valid0 read1 write2 exec3 accessed6 dirty7 0b11001111=0xcf
   sd t1, 0(t0) 

   # 3. map vma 0x8000_0000 to ppa 0x8000_0000, ppn =  ppa >> 12 = 0x80000 pte = ppn << 10 | flags
   li t1, 0x200000cf # pte = ppn << 10 | flags valid0 read1 write2 exec3 accessed6 dirty7 0b11001111=0xcf
   sd t1, 16(t0)     # Index=va[38:30]=0b00000010=2, 8 bytes per PTE = 16, 

   # satp need ppn of root table rt 0x80700000 
   # satp = satp[63:60].MODE(0:bare, 8:sv39, 9:sv48)|satp[59:44].asid|satp[43:0].rootpage_physical_addr(vpn2:9|vpn1:9|vpn0:9|offseet12)
   # ppn = rt >> 12 = 0x80700
   # mode = 3 sv39
   li t0, 0x8000000000080700
  #call print_reg
  #testf  #B
   csrw satp, t0 # write mode and root table address to satp CSR register
  #testf 
   sfence.vma
   ## <--- start use TLB I/D hitting


   testf 


   #la a0, msg   # trigger I-TLB miss
   #call print_reg

   la a0, msg   # trigger I-TLB miss
   call puts
   



s_mode_done:
  j s_mode_done



m_trap_router:
   #sd t0, 0x300(zero)
   #sd t1, 0x308(zero)

   csrr s0, mcause  # check type

   # 63 bit 1 interrupt
   # 63 bit 0 exception

   # Exception 0
   # 0 pc is not aligned to 4 bytes
   # 1 instruction is not accessable
   # 2 illegal instruction
   # 3 breakpoint
   # 4 load address not aligned lw!=4  ld!=8 lh!=2?
   # 5 load access fault
   # 6 store/amo address not aligned
   # 7 store/amo access fault
   # 8 ecall from u-mode
   # 9 ecall from s-mode
   # 10 --(reserved)
   # 11 ecall from m-mode
   # 12 instruciton page fault
   # 13 load page fault
   # 14 --
   # 15 store/amo page fault
   # 16+ --

   # Interrupt 1
   # 0 user software interrupt
   # 1 supervisor software interrupt
   # 2 -- 
   # 3 machine software interrupt
   # 4 user timer software interrupt
   # 5 supervisor timer software interrupt
   # 6 --
   # 7 machine timer interrupt
   # 8 user external interrupt
   # 9 supervisor external interrupt
   # 10 --
   # 11 machine external interrupt
   # 12-15 --
   # 16+ local define interrupt


   li s1, 9  # ecall from S-mode
   beq s0, s1, m_ecall_router

   li s1, 2 # illegal instruction
   beq s0, s1, m_ex_illegal_ir

   li s1, 3 #  ebreak
   beq s0, s1, m_ebreak_handler

   

   j m_done

m_ecall_router:  # a7 Extension 1 putchar, 2 getchar, 0 settimer; a0 is the first argument a1..a5  # look a7 to see function is requested(sbi standard)

   li s0, 0
   beq a7, s0, m_handler_set_timer

   li s0, 1
   beq a7, s0, m_handler_putchar  # (SBI_CONSOLE_PUTCHAR ( a7 = 0x01)

   li s0, 2
   beq a7, s0, m_handler_getchar  

   li s0, 3
   beq a7, s0, m_handler_get_timer

   li s0, 0x10
   beq a7, s0, m_handler_deleg

   li a0, -1  # unknow SBI_ERR_NOT_SUPPORTED = -1
   j m_done

m_ebreak_handler:
   li a0, "M"
   li s11, 0x2004
   wait_uart_m:
   lw s9, 0(s11)
   blt s9, zero, wait_uart_m  # sifive uart negetive is full
   sb a0, 0(s11)
   li a0, 0     # return success
   j m_done
   
m_handler_putchar:
   li s11, 0x2004
   wait_uart_sbi:
   lw s9, 0(s11)
   blt s9, zero, wait_uart_sbi  # sifive uart negetive is full
   sb a0, 0(s11)
   li a0, 0     # return success
   j m_done

m_handler_set_timer:
   li s1, 0x2004000  # riscv use MMIP for mtimecmp
   sd a0, 0(s1)      # S-mode passes new time in a0
   li a0, 0          # Success return a0=0
   j m_done

m_handler_get_timer:
   li s1, 0x200bff8  # riscv mtime
   ld a0, 0(s1)      # S-mode passes new time in a0
   j m_done

m_handler_deleg:
   #li t0, 0x800 # 0b1000
   li s0, 0b1000            # Delegate breakpoint bit3 to s-mode, ecall is bit9 not delegate yet
   csrw medeleg, s0 
   li a0, 0
   j m_done

m_ex_illegal_ir:
  #li a0, "I"
  #call putchar
   li a0, "\n{ILLir"
   call print7
   csrr a0, mtval
   call print_reg
   li a0 "}"
   call putchar
   j m_done

m_done: 
   csrr s0, mcause
   li s1, 12
   bge s0, s1, return_same_pc # Page_Fault 12/13/14/15 give mepc to Trap


   csrr s0, mepc
   addi s0, s0, 4 # skip ecall/ebreak instruction
   csrw mepc, s0
   #ld s0, 0x900(zero)
   #ld s1, 0x908(zero)
   return_same_pc:
   mret





s_trap_handler:
   li a0, "S"
   li a7, 1
   ecall   # here ecall was not delegated to s_mode, so go to mtvec to find m-mode ecall handler
   j s_done

s_done: 
   csrr s2, sepc
   addi s2, s2, 4 # skip ecall/ebreak instruction
   csrw sepc, s2
   sret


















# functions ------

print_reg: # a0
    addi sp, sp, -40
    sd ra, 0(sp)
    sd s0, 8(sp)
    sd s1, 16(sp)
    sd s2, 24(sp)
    sd s3, 32(sp)
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
    beq a0, x0, stop_puts # \x00 for end of string
    call putchar # a0 char
    addi s0, s0, 1 # next byte
    j puts_loop
    stop_puts:
    ld ra, 0(sp)
    ld s0, 8(sp)
    addi sp, sp, 16
    ret


wait_uart:
    addi sp, sp, -16
    sd s0, 0(sp)
    sd ra, 8(sp)
    wait_uart_loop:
    lw s0, 0(s11)
    bgt zero, s0, wait_uart_loop
    ld s0, 0(sp)
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
