#.section .text # .text .data .bss .rodata .test.unlikely .mydata .text.debug .init .fini
## .data .byte .word .half .asciz .ascii .string .float .double .align .skip .set 

#.section .text
#    addi a0, x0, 5
#    addi a0, a0, 1
#
#.section .data
#    .string "Hello, world!"


#load_uart_addrs: # UART 每次传输一个字节, 根据 16550 UART 标准 THR 偏移量为 0，LSR 偏移量为 5
## UART  Transmit Holding Register|i/o register # UART 数据寄存器 THR s1
#lui     s1, 0x10000     # load upper 20 bits
#addi    s1, s1, 0x000   # load lower 12 bits
#
#load_lsr_addr:  
## UART  line_status_register # UART 行状态寄存器 LSR s2
#lui     s2, 0x10000     # load upper 20 bits
#addi    s2, s2, 0x005   # load lower 12 bits
#
## 0xE4BDA0 你
#test:
#addi    s4, x0, 0xE4    # load 
#sb      s4, 0(s1)       # write byte to UART register 
#addi    s4, x0, 0xBD  # load
#sb      s4, 0(s1)       # write byte to UART register 
#addi    s4, x0, 0xA0  # load 
#sb      s4, 0(s1)       # write byte to UART register 
#
## keystroke
#loop: 
#lb      s3, 0(s2)       # load UART_LSR
#andi    s3, s3, 1       # bitwise AND 1 only left the "UART data ready" position as it is
#beq     x0, s3, loop    # if DR is 0, keep loop for waiting
#lb s4, 0(s1)            # read byte from THR
#sb s4, 0(s1)            # write byte back to THR for stdio to output
##addi    s4, x0, 0x41  # load A
##sb      s4, 0(s1)       # write byte to UART register 
##bltu    x0, s3, loop     # if DR is 1 then s3 > 0 then jump to loop for waiting new keystroke
##jal x0, loop # jal to loop
#addi x30, x0, 111
#addi x31, x30, 666
#addi x31, x31, 1

# Test Instruction
# ADDI
# -------
# Limitation: imm is in -2048:2047
# Test 1 add number decimal positive 
#addi x31, x0, 1 
#addi x31, x0, 2 
#addi x31, x0, 3 
# Test 2 add number 0b positive 
#addi x31, x0, 0b1 
#addi x31, x0, 0b10
#addi x31, x0, 0b11 
# Test 3 add number 0x positive 
#addi x31, x0, 0x1 
#addi x31, x0, 0x2
#addi x31, x0, 0x3
# Test 4 add number decimal negative
#addi x31, x0, -1 
#addi x31, x0, -2 
#addi x31, x0, -3 
# Test 5 add number 0b negative
#addi x31, x0, -0b1 
#addi x31, x0, -0b10
#addi x31, x0, -0b11 
# Test 6 add number 0x negative
#addi x31, x0, -0x1 
#addi x31, x0, -0x2
#addi x31, x0, -0x3
# Test 7 add number 0x positive then turn to negative
#addi x30, x0, -0x1 
#addi x31, x0, -0x1 
#addi x31, x30, 0x2 
# Test 8 minimal and maximal number
#addi x31, x0,  0b11111111111 # maximal 2047
#addi x31, x0, -0b00000000000 # minimal -2048
# Test 9 0verflow 12 bits
#addi x31, x0,  0b111111111111 # overflow
#addi x31, x0, -0b111111111111 # overflow
# Test 10 add 0 as mv
#addi x30, x0, 0x05
#addi x31, x30, 0
# Test 11 pseduo li
#addi x31, x0, 0xB 
# Test 12 write to x0 for discard
#addi x0, x0, 0x2
#addi x31, x0, 0
#addi x31, x0, 2
#addi x0, x0, 0x2
#addi x31, x0, 3
# Test 13 NOP
#addi x0, x0, 0
# Test 14 maximal positive to minimal negative int64
#addi x31, x0,-1 
### x31 now is 0xffffffffffffffff # -1
#srli x31, x31, 1
### x31 now is 0x7fffffffffffffff # Max int64 +2**63-1 = 9,223,372,036,854,775,807
#addi x31, x31, 1
### x31 now is 0x8000000000000000 # Min int64 -2**63 = -9,223,372,036,854,775,808
#addi x31, x31, -1
### x31 now is 0x7fffffffffffffff # Max overflow 
#addi x31, x31, 2
### x31 now is 0x8000000000000001 
#addi x31, x31, -1
### x31 now is 0x8000000000000000 

# LUI
#-----------
# Limitation: 20 bits signed [-0x100000:0x7ffff], auto-sext in rv64
# Load arbitrary int32 by LUI, i.e. 0x12345805 
# say, LUI has auto sext, ADDI/ADDIW has 12 signed immediate, so, if highest 1, it is substruct because 0xfffff805 is negative, so when 0x12345000 need plus positive 0x805 it actually substruct ~0x805, so we need 0x12345 + 0x805 + ~0x805 then substruct ~0x805 to keep the result correct, then 0x805 + ~0x805 = x1000, so 0x12345 should be 0x12346, the left step is 0x12346 + 0xfffff805 in marchine code, in assembler should pass -~0x805+1 , so the LUI should put 0x12346 on high 20 bit. 
## load 0x12345002 positive
#lui x31, 0x12345
#addi x31, x31, 0x002  
## load 0x12345802 0x802 -> 1000 0000 0010 -> 0111 1111 1101 + 1 -> 0111 1111 1110 ->  0x7fe
#lui x31, 0x12346
#addi x31, x31, -0x7fe
## load -0x77313779 negative -> 0x88cec887
#lui x31, -0x77313
#addi x31, x31, -0x779
## load -0x77313879 negative cut negative-> 0x88cec787 多减1加上补码 (补码=反码加一)
#lui x31, -0x77314
#addi x31, x31, 0x787
## load 0x77313779 positive 
#lui x31, 0x77313
#addi x31, x31, 0x779
## load 0x77313879 positive cut negative 多加1减去补码(补码=反码加一)
#lui x31, 0x77314
#addi x31, x31, -0x787
# Load arbitrary int64 by LUI, i.e. 0x12345805_12345805
# load 0x12345002 positive
#lui x31, 0x12345
#addi x31, x31, 0x002  # get 0x12345002
#slli x31, x31, 32     # get  0x12345002_00000000
#lui x30, 0x12345
#addi x30, x30, 0x002  # get 0x12345002
#add x31, x31, x30     # get 0x12345002_12345002
# Test 1 load 0
#lui x31, 0x0
## Test 2 load 1
#lui x31, 0x1 # get 0x00000000_00001000
## Test 3 load max 0x7ffff
#lui x31, 0x7ffff # get 0x00000000_7ffff000
## Test 5 load mim normal -0x7ffff  80000000
#lui x31, -0x80000 # get 0xffffffff_80000000
## Test 4 load mim -0x00000
##lui x31, -4096 # get 0x10000000_00000000
#lui x31, -0b000  # get 0xffffffff_ffff8000
#lui x31, -0b0000 # get 0xffffffff_ffff0000
#lui x31, -0x00 # get 0xffffffff_ffff00000
##lui x31, -0x00000 # get 0xffffffff_ffff0000
##lui x31, -0x00000 # get 0xffffffff_ffff0000
##lui x31, -0x1 # get 0xffffffff_fffff000
#lui x0, 0x1 # get 0


# SRLI
# -------
# Limitation: shamt 6bits in 0:63, padding always 0, shame borrow 1 bit from func7[0]
# Test 1 basic positive number
#addi x31, x0, 0xf0
#srli x31, x31, 4
## Now  x31 is 0xf
# Test 1 basic negative number
#addi x31, x0, -1
#srli x31, x31, 1
#srli x31, x31, 3 # padding 0 at left ignore the 1 negative head number
# Test 2 shift 0
#addi x31, x0, -1
#srli x31, x31, 0
# Test 3 shift maximal shamt 63
#addi x31, x0, -1
#srli x31, x31, 63 
# Test 4 shift tobe 0
#addi x31, x0, 0b100 
#srli x31, x31, 2 
# Test 5 shift 0
#addi x31, x0, 0
#srli x31, x31, 0 
# Test 6 shift to x0
#addi x31, x0, 0b11 
#srli x0, x31, 1 

# SLLI
# -------
# Limitation: shamt 6bits in 0:63, padding always 0
# Test 1 basic positive number
#addi x31, x0, 0b1
#slli x31, x31, 1
# Test 2 basic negative number
#addi x31, x0, -1
#slli x31, x31, 1
# Test 3 shift 0
#addi x31, x0, -1
#slli x31, x31, 0
# Test 4 shift maximal shamt 63
#addi x31, x0, 1
#slli x31, x31, 63 
# Test 5 shift tobe 0
#addi x31, x0, 1
#slli x31, x31, 63 
#slli x31, x31, 1 
# Test 6 shift 0
#addi x31, x0, 1
#slli x31, x31, 0 
# Test 7 shift to x0
#addi x31, x0, 0b11 
#slli x0, x31, 1 

# SRAI
# -------
# Limitation: shamt 6bits in 0:63, padding according to +- sign bit
# Test 1 basic positive number
#addi x31, x0, 0b11
#srai x31, x31, 1
# Test 2 basic negative number
#addi x31, x0, -256
#srai x31, x31, 4 # get -16
#srai x31, x31, 4 # get -1
# Test 3 shift 0
#addi x31, x0, -1
#srai x31, x31, 0
# Test 4 shift maximal shamt 63
#addi x31, x0, -1
#slli x31, x31, 63 # get 0x800...
#srai x31, x31, 63 # get -1
# Test 5 shift tobe 0
#addi x31, x0, 1
#srai x31, x31, 1 
# Test 6 shift 0
#addi x31, x0, 1
#srai x31, x31, 0 
# Test 7 shift to x0
#addi x31, x0, 0b11 
#srai x0, x31, 1 

#ADDIW
# -------
# Limitation: only on 64 for 32, imm is in -2048:2047, extend to 64 bits rather than ADDI's 32 bits
# Test 1 add number positive 
#addiw x31, x0, 0x7ff
#addiw x31, x0, 0b10
#addiw x31, x0, 0x3 
# Test 2 add number negative
#addiw x31, x0, -1 
#addiw x31, x0, -0b10
#addiw x31, x0, -0x3 
# Test 3 add number positive then turn to negative
#addiw x30, x0, -1 
#addiw x31, x0, -0b1 
#addiw x31, x30, 0x2 
# Test 8 minimal and maximal number
#addiw x31, x0,  0b11111111111 # maximal 2047
#addiw x31, x0, -0b00000000000 # minimal -2048
# Test 9 0verflow 12 bits
#addiw x31, x0,  0b111111111111 # overflow # error of assembler
#addiw x31, x0, -0b111111111111 # overflow # error of assembler
# Test 64bit s1 be cut to 32bit 
#addiw x31, x0, 0b1
#slli x31, x31, 62 
#addiw x31, x0, 0b1
# Test fullfill maximal int64
#addiw x31, x0, -1
#srli x31, x31, 1
# Test negative 32b sext to 64b
#lui x31, 0x1
#slli x31, x31, 20 
#addi x31, x31, -1
# or
#addi x31, x0, -1
#slli x31, x31, 32
#srli x31, x31, 32 # load 0xffffffff
#addiw x31, x31, 1 # no sext
#addi x31, x0, 0x1 
#slli x31, x31, 31 # construct 0x80000000
#addiw x31, x31, -1 # get 0x000000007fffffff
#addi x31, x0, 0x1 
#slli x31, x31, 31 # construct 0x80000000
#addi x31, x31, 0x1 # construct 0x80000001
#addiw x31, x31, -1 # get 0xffffffff80000000
# Test 32 0 result is 64 0 result
#addi x31, x0, -1
#slli x31, x31, 32
#srli x31, x31, 32 # load 0xffffffff -1 in 32 bit
#addiw x31, x31, 1 # get 0
# Test 32 -1 result is 64 -1 result
#addi x31, x0, -1
#slli x31, x31, 32
#srli x31, x31, 32 # load 0xffffffff -1 in 32 bit
#addiw x31, x31, 0 # get -1 in 0xffffffffffffffff
# Test ignore hight 32b
# load 0x12345002 positive
#lui x31, 0x12345
#addi x31, x31, 0x002  # get 0x12345002
#slli x31, x31, 32     # get  0x12345002_00000000
#lui x30, 0x12345
#addi x30, x30, 0x002  # get 0x12345002
#add x31, x31, x30     # get 0x12345002_12345002
#addiw x31, x31, -2    # get 0x00000000_12345000
# Test 10 add 0 as mv
#addiw x30, x0, 0x05
#addiw x31, x30, 0
# Test 11 write to x0 for discard
#addiw x0, x0, 0x2
# Test 13 NOP
#addiw x0, x0, 0
# Test 14 maximal positive cut to int32 sext to int64
#addiw x31, x0,-1 
#### x31 now is 0xffffffffffffffff # -1 addiw will add sext(imm).32 to s1.low32, cut to 32 sext to 64.
#srli x31, x31, 1
#### x31 now is 0x7fffffffffffffff # Max int64 +2**63-1 = 9,223,372,036,854,775,807
#addiw x31, x31, 1
#### x31 now is 0x0000000000000000 # Cut 0xffffffff + 1 to 0x00000000 sext to 0x0000000000000000
#addiw x31, x0,-1 
##### x31 now is 0xffffffffffffffff # -1 addiw will add sext(imm).32 to s1.low32, cut to 32 sext to 64.
#srli x31, x31, 1
##### x31 now is 0x7fffffffffffffff # Max int64 +2**63-1 = 9,223,372,036,854,775,807
#addiw x31, x31, -1
#### x31 now is 0xfffffffffffffffe # Cut 0xffffffff - 1 to 0xfffffffe sext to 0xfffffffffffffffe
#addiw x31, x31, 3
### x31 now is 0x0000000000000000  # Cut 0xfffffffe + 3 to 0x00000001 sext to 0x0000000000000001

# SLLIW
#-------
# Limitation: only shift 32 bits and sext to 64 bits
## load 0x12345002 cut positive
#lui x31, 0x12345
#addi x31, x31, 0x002  
#slliw x31, x31, 4   # get 0x0000000023450020
### load 0x1f345002 cut negative
#lui x31, 0x1f845
#addi x31, x31, 0x002  
#slliw x31, x31, 4  # get 0xfffffffff8450020
#slliw x31, x31, 4  # get 0xffffffff84500200

# SRLIW
#-------
# Limitation: only shift 32 bits and sext to 64 bits; only negative shift 0 sext 1; shamt is unsign 5bits maximal 31
## load 0x12345002 cut positive
#lui x31, 0x12345
#addi x31, x31, 0x002  
#srliw x31, x31, 4   # get 0x0000000001234500
### load 0x1f345002 cut negative but shift no-0
#lui x31, -0x80000
#addi x31, x31, 0x002  
#srliw x31, x31, 4  # get 0x0000000008000000
#### load -0x1f345002 cut negative and shift 0
#lui x31, -0x1f345
#addi x31, x31, -0x002  
#srliw x31, x31, 0  # get 0xfffffffffe0cbaffe
#### load -0x1f345002 cut negative and shift more than 31
#lui x31, -0x1f345
#addi x31, x31, -0x002  
#srliw x31, x31, 32 # get assember error

# SRAIW
# -----
# Limitation: max 31, sext 32 to 64 
## load 0x12345002 cut positive
#lui x31, 0x12345
#addi x31, x31, 0x002  
#sraiw x31, x31, 4   # get 0x0000000001234500
## load negative cut positive but shift no-0
#lui x31, -0x80000
#addi x31, x31, -0x002  
#sraiw x31, x31, 4  # get 0x000000007ffffff
#lui x31, -0xfffff
#sraiw x31, x31, 8  
### load negative cut negative but shift no-0
#lui x31, -0x80000
#addi x31, x31, 0x001  
#sraiw x31, x31, 4  # get 0xfffffffff8000000
### load negative cut negative shift 0
#lui x31, -0x80000
#addi x31, x31, 0x001  
#sraiw x31, x31, 0  # get 0xffffffff80000001

# ANDI
#-----
# limiation: 12 signed imm sext to 64 AND with s1 to rd
# Test positive with positive imm
#lui x31, 0x7ffff
#addi x31, x31, 0x7ff
#andi x31, x31, 0x0b2
## Test positive with negative imm
#lui x31, 0x7ffff
#addi x31, x31, 0x7ff
#andi x31, x31, -0x002
## Test negative with positive imm
#addi x31, x0, 0
#lui x31, -0x80000  # 0xf80000
#addi x31, x31, -0x7ef #ffffff901   
#andi x31, x31, 0x011
## Test negative with negasitive imm
#addi x31, x0, 0
#lui x31, -0x80000  # 0xf80000
#addi x31, x31, -0x7ef #ffffff811 # 0xfffffff7ffff811   
#andi x31, x31, -0x011 #                         ffef
## Test negative with 0 imm
#addi x31, x0, 0
#lui x31, -0x80000  # 0xf80000
#addi x31, x31, -0x7ef #ffffff811 # 0xfffffff7ffff811   
#andi x31, x31, 0x1 #                         
#andi x31, x31, 0x0 #                         

# ORI
#-----
# limiation: 12 signed imm sext to 64 OR with s1 to rd
# Test 
#li x31, -0x100000000   #-4294967296
#ori x31, x31, 2
#li x31, 0x7
#ori x31, x31, 0b11011
#li x31, -0x100000000   #-4294967296
#ori x31, x31, 0x7ff
#li x31, 0x7ffffffe   #-4294967296
#ori x31, x31, 0x7ff
#ori x31, x31, -0x1

# XORI
#-----
# limiation: 12 signed imm sext to 64 XORI with s1 to rd
#li x31, 0x100000000   #-4294967296
#xori x31, x31, 0b10101
#li x31, 0x100000000   #-4294967296
#xori x31, x31, 0x7fe

# SLTI
#-----
# limiation: 12 signed imm sext to 64, both signed, s1 < imm => 1 rd 
#li x31, 0x100000000   
#li x31, -0x100
#slti x31, x31, -0xff
#li x31, 2046
#slti x31, x31, 2047 
#li x31, -2047
#slti x31, x31, -2048 
#slti x31, x0, 2047 
#addi x31, x31, 0xfff

# SLTIU
#-----
# limiation: 12 signed imm sext to 64, both unsigned, s1 < imm => 1 rd 
#li x30, 0x3
#sltiu x31, x30, 0x4

# AUIPC
# limiation: 12 signed imm sext to 64
#auipc x31, -0x1  
#auipc x31, 0x3  
#auipc x31, 0x3  
#auipc x0, 0x3  
#auipc x31, -0x3  

# LB
# limiation: 8 bits sext 
#li x30, -0x1
#lb x4, 5(x30)
#lb x1, 1(x0)
#lb x2, 2(x0)
#lb x3, 3(x0)
#add x31, x2, x1
#add x31, x31,x3
#add x31, x31,x4

# LBU
# limiation: 
#li x30, -0x1
#lbu x31, 5(x30)
#lbu x4, 5(x30)
#lbu x1, 1(x0)
#lbu x2, 2(x0)
#lbu x3, 3(x0)
#lbu x4, 4(x0)
#add x31, x2, x1
#add x31, x31,x3
#add x31, x31,x4

# LH
# limiation: 16 bits sext 
#li x30, -0x1
#lh x31, 5(x30)

# LHU
# limiation: 
#li x30, -0x1
#lhu x31, 5(x30)

# LW
# limiation: 32 bits sext 
#li x30, -0x1
#lw x31, 2(x30)

# LWU
# limiation: 
#li x30, -0x1
#lwu x31, 5(x30)

# LD
# limiation: 
#li x30, -0x1
#ld x31, 6(x30)
 
# SB
# limiation: 
#li x30, -0x556
#sb x30, 6(x0)
#lb x31, 6(x0)

# SH
# limiation: 
#li x30, -0x556
#sh x30, 6(x0)
#lh x31, 6(x0)


# SW
# limiation: 
#li x30, 0x77777787
#sw x30, 6(x0)
#lb x31, 6(x0)

# SD
# limiation: 
#li x30, -0x0fffffff77777787
#sd x30, 6(x0)
#ld x31, 6(x0)

# ADD
#li x31, -0x7fffffffffffffff
#li x29, 0x1
#add x31, x31, x29
#li x31, 0x7
#li x29, -0x6
#add x31, x31, x29

# ADDW
#li x30, 0x7ffffffffffffffe
#li x29, 0x1
#addw x31, x30, x29

# SUB
#li x31, -0x7fffffffffffffff
#li x29, 0x1
#sub x31, x29, x31

# SUBW
#li x29, 0x1
#li x30, 0x7fffffff7fffffff
#subw x31, x29, x30

# SLT
#li x29, 0x1
#li x30, -0x7fffffff7fffffff
#slt x31, x29, x30

# SLTU
#li x29, 0x2
#li x30, 0x3
#sltu x31, x29, x30

# OR
#li x29, 0b100110010010
#li x30, 0b000000000001
#or x31, x29, x30

# AND
#li x29, 0b100110010010
#li x30, 0b000000011111
#and x31, x29, x30

# XOR
#li x29, 0b100110010010
#li x30, 0b000000011111
#xor x31, x29, x30

# SLL 
#li x29, 1
#li x30, 5 
#sll x31, x29, x30

# SLLW
#li x29, -1
#li x30, 5 
#sllw x31, x29, x30

# SRL 
#li x29, 0b100000
#li x30, 4 
#srl x31, x29, x30

# SRLW
#li x30, 0x7fffffff
#srlw x31, x30, x0

# SRA 
#li x29, -0b110000
#li x30, 4 
#sra x31, x29, x30

# SRA 
#li x29, 0x7fffffff
#li x30, 4 
#sraw x31, x29, x30

# BEQ
#start: li x29, 4
#li x31, 3 
#li x31, 4 
#beq x31, x29, end
#li x31, 5 
#li x31, 6 
#end: li x31, 2 

# BNE
#start: li x29, 1
#li x31, 3 
#li x31, 4 
#bne x31, x29, end
#li x31, 5 
#li x31, 6 
#end: li x31, 2 

# BNE
#start: li x29, 1
#li x31, 3 
#li x31, 4 
#bne x31, x29, end
#li x31, 5 
#li x31, 6 
#end: li x31, 2 


# BLT
#start: li x29, 100
#li x31, 3 
#li x31, 4 
#blt x31, x29, end
#li x31, 5 
#li x31, 6 
#end: li x31, 2 


# BGE
#start: li x29, 5
#li x31, 3 
#li x31, 4 
#bge x31, x29, end
#li x31, 5 
#li x31, 6 
#end: li x31, 2 


# BLTU
#start: li x30, -0b1 
#li x31, 3 
#li x31, 0b011 
#bltu x31, x30, end
#li x31, 5 
#li x31, 6 
#end: li x31, 2 


# BGEU
#start: li x30, 0b1 
#li x31, 3 
#li x31, 0b011 
#bgeu x31, x30, end
#li x31, 5 
#li x31, 6 
#end: li x31, 2 

#JAL
# limitation: in (-2^19)*2 : (2^19 -1)*2  = -1047576:1046574 bytes 
#start: li x30, 0b1 
#li x31, 3 
#li x31, 0b011 
#bgeu x31, x30, end
#li x31, 5 
#li x31, 6 
#end: li x31, 2 
#li x31, 4 
#jal x31, end 


#JALR
#start: li x30, 0b1 
#end: li x31, 2 
#li x31, 0 
##jalr x30, x31, 0
#li x2, 8
#li x1, 1
#li x1, 0
#addi x27, x27, 8
#addi x30, x30, 0
#jalr x31, x30, 16 
#addi x30, x30, 3
#addi x30, x30, 2 
#li x2, 12 # right answer to x2
#li x1, 1 # indicate for compare
#li x1, 0 # clean for next test


#_start:
#    # Initialize common registers if needed (optional)
#    li x3, 0
#    li x4, 0
#    li x5, 0
#    # x1 = signal, x2 = golden, x31 = result
#
##--------------------------------------------
## Immediate Arithmetic Tests
##--------------------------------------------
#
## TEST: ADDI (Positive)
#    li x3, 1000
#    addi x31, x3, 123   # x31 = 1000 + 123 = 1123
#    li x2, 1123         # Golden
#    li x1, 1            # Signal Compare
#    li x1, 0            # Clear Signal
#
## TEST: ADDI (Negative)
#    li x3, 1000
#    addi x31, x3, -23   # x31 = 1000 - 23 = 977
#    li x2, 977          # Golden
#    li x1, 1            # Signal Compare
#    li x1, 0            # Clear Signal
#.section .text
#.global _start

_start:
    # Initialize common registers if needed (optional)
    li x3, 0
    li x4, 0
    li x5, 0
    # x1 = signal, x2 = golden, x31 = result

#--------------------------------------------
# Immediate Arithmetic Tests
#--------------------------------------------

# TEST: ADDI (Positive)
    li x3, 1000
    addi x31, x3, 123   # x31 = 1000 + 123 = 1123
    li x2, 1123         # Golden
    li x1, 1            # Signal Compare
    li x1, 0            # Clear Signal

# TEST: ADDI (Negative)
    li x3, 1000
    addi x31, x3, -23   # x31 = 1000 - 23 = 977
    li x2, 977          # Golden
    li x1, 1            # Signal Compare
    li x1, 0            # Clear Signal

# TEST: ADDI (Zero)
    li x3, 1000
    addi x31, x3, 0     # x31 = 1000 + 0 = 1000
    li x2, 1000         # Golden
    li x1, 1            # Signal Compare
    li x1, 0            # Clear Signal

# TEST: SLTI (Less Than - True)
    li x3, -50
    slti x31, x3, 100   # x31 = (signed(-50) < signed(100)) ? 1 : 0 -> 1
    li x2, 1            # Golden
    li x1, 1            # Signal Compare
    li x1, 0            # Clear Signal

# TEST: SLTI (Less Than - False)
    li x3, 150
    slti x31, x3, 100   # x31 = (signed(150) < signed(100)) ? 1 : 0 -> 0
    li x2, 0            # Golden
    li x1, 1            # Signal Compare
    li x1, 0            # Clear Signal

# TEST: SLTI (Equal - False)
    li x3, 100
    slti x31, x3, 100   # x31 = (signed(100) < signed(100)) ? 1 : 0 -> 0
    li x2, 0            # Golden
    li x1, 1            # Signal Compare
    li x1, 0            # Clear Signal

# TEST: SLTIU (Less Than Unsigned - True)
    li x3, 50
    sltiu x31, x3, 100  # x31 = (unsigned(50) < unsigned(100)) ? 1 : 0 -> 1
    li x2, 1            # Golden
    li x1, 1            # Signal Compare
    li x1, 0            # Clear Signal

# TEST: SLTIU (Less Than Unsigned - False, comparing with -1 = max_unsigned)
    li x3, 50
    sltiu x31, x3, -1   # x31 = (unsigned(50) < unsigned(-1)) ? 1 : 0 -> 1 (since -1 is max uint)
    li x2, 1            # Golden
    li x1, 1            # Signal Compare
    li x1, 0            # Clear Signal

# TEST: SLTIU (Immediate 1 -> True)
    li x3, 0
    sltiu x31, x3, 1    # x31 = (unsigned(0) < unsigned(1)) ? 1 : 0 -> 1
    li x2, 1            # Golden
    li x1, 1            # Signal Compare
    li x1, 0            # Clear Signal

# TEST: ANDI
    li x3, 0x0F0F0F0F
    andi x31, x3, 0xFF  # x31 = 0x0F0F0F0F & 0x...00FF = 0x0F
    li x2, 0x0F
    li x1, 1
    li x1, 0

# TEST: ORI
    li x3, 0x0F0F0F0F
    ori x31, x3, 0xF0   # x31 = 0x0F0F0F0F | 0x...00F0 = 0x0F0F0FFF
    li x2, 0x0F0F0FFF
    li x1, 1
    li x1, 0

# TEST: XORI
    li x3, 0xAAAA5555
    xori x31, x3, 0xFFF # x31 = 0xAAAA5555 ^ 0x...0FFF = 0xAAAA5AAA
    li x2, 0xAAAA5AAA
    li x1, 1
    li x1, 0

#--------------------------------------------
# Immediate Shift Tests
#--------------------------------------------

# TEST: SLLI (64-bit)
    li x3, 0x1111222233334444
    slli x31, x3, 4     # x31 = 0x1112222333344440
    li x2, 0x1112222333344440
    li x1, 1
    li x1, 0

# TEST: SRLI (64-bit)
    li x3, 0xF111222233334444
    srli x31, x3, 4     # x31 = 0x0F11122223333444 (logical shift, zero fill)
    li x2, 0x0F11122223333444
    li x1, 1
    li x1, 0

# TEST: SRAI (64-bit, Positive)
    li x3, 0x0111222233334444
    srai x31, x3, 4     # x31 = 0x0011122223333444 (arithmetic shift, sign bit 0)
    li x2, 0x0011122223333444
    li x1, 1
    li x1, 0

# TEST: SRAI (64-bit, Negative)
    li x3, 0xF111222233334444 # Sign bit is 1
    srai x31, x3, 4     # x31 = 0xFF11122223333444 (arithmetic shift, sign bit 1 replicated)
    li x2, 0xFF11122223333444
    li x1, 1
    li x1, 0

#--------------------------------------------
# Upper Immediate Tests
#--------------------------------------------

# TEST: LUI
    lui x31, 0xBADF0     # x31 = 0xBADF0000. Sign extend? No. = 0x00000000BADF0000
    li x2, 0xBADF0000
    li x1, 1
    li x1, 0

# TEST: AUIPC (Result depends on PC!)
    # Assume this instruction is at PC = 0x100 for calculation
    # Need to adjust golden value based on actual assembled address
    auipc x31, 0xBEEF   # x31 = PC + (0xBEEF << 12) = 0x100 + 0xBEEF0000 = 0x00000000BEEF0100
    li x2, 0xBEEF0100   # ** ADJUST GOLDEN VALUE BASED ON ACTUAL PC **
    li x1, 1
    li x1, 0

#--------------------------------------------
# Register Arithmetic Tests
#--------------------------------------------

# TEST: ADD
    li x3, 0x1000
    li x4, 0x2345
    add x31, x3, x4     # x31 = 0x1000 + 0x2345 = 0x3345
    li x2, 0x3345
    li x1, 1
    li x1, 0

# TEST: SUB
    li x3, 0x3000
    li x4, 0x1111
    sub x31, x3, x4     # x31 = 0x3000 - 0x1111 = 0x1EEE
    li x2, 0x1EEE
    li x1, 1
    li x1, 0

# TEST: SLT (Signed Less Than - True)
    li x3, -10
    li x4, 10
    slt x31, x3, x4     # x31 = (signed(-10) < signed(10)) ? 1 : 0 -> 1
    li x2, 1
    li x1, 1
    li x1, 0

# TEST: SLT (Signed Less Than - False)
    li x3, 10
    li x4, -10
    slt x31, x3, x4     # x31 = (signed(10) < signed(-10)) ? 1 : 0 -> 0
    li x2, 0
    li x1, 1
    li x1, 0

# TEST: SLTU (Unsigned Less Than - True)
    li x3, 10
    li x4, 20
    sltu x31, x3, x4    # x31 = (unsigned(10) < unsigned(20)) ? 1 : 0 -> 1
    li x2, 1
    li x1, 1
    li x1, 0

# TEST: SLTU (Unsigned Less Than - False, comparing -1)
    li x3, -1           # Max unsigned value
    li x4, 10
    sltu x31, x3, x4    # x31 = (unsigned(-1) < unsigned(10)) ? 1 : 0 -> 0
    li x2, 0
    li x1, 1
    li x1, 0

# TEST: AND
    li x3, 0xF0F0F0F0
    li x4, 0x00FF00FF
    and x31, x3, x4     # x31 = 0x00F000F0
    li x2, 0x00F000F0
    li x1, 1
    li x1, 0

# TEST: OR
    li x3, 0xF0F0F0F0
    li x4, 0x00FF00FF
    or x31, x3, x4      # x31 = 0xF0FFF0FF
    li x2, 0xF0FFF0FF
    li x1, 1
    li x1, 0

# TEST: XOR
    li x3, 0xF0F0F0F0
    li x4, 0x00FF00FF
    xor x31, x3, x4     # x31 = 0xF00FF00F
    li x2, 0xF00FF00F
    li x1, 1
    li x1, 0

#--------------------------------------------
# Register Shift Tests
#--------------------------------------------

# TEST: SLL (Shift amount < 64)
    li x3, 0x1111222233334444
    li x4, 4
    sll x31, x3, x4     # x31 = 0x1112222333344440
    li x2, 0x1112222333344440
    li x1, 1
    li x1, 0

# TEST: SRL (Shift amount < 64)
    li x3, 0xF111222233334444
    li x4, 4
    srl x31, x3, x4     # x31 = 0x0F11122223333444
    li x2, 0x0F11122223333444
    li x1, 1
    li x1, 0

# TEST: SRA (Shift amount < 64, Negative)
    li x3, 0xF111222233334444
    li x4, 4
    sra x31, x3, x4     # x31 = 0xFF11122223333444
    li x2, 0xFF11122223333444
    li x1, 1
    li x1, 0

#--------------------------------------------
# Immediate Word Arithmetic Tests (RV64I)
#--------------------------------------------

# TEST: ADDIW (Positive 32b result)
    li x3, 0x7FFFFFF0    # Positive 32-bit value
    addiw x31, x3, 5     # x31 = sign_extend(0x7FFFFFF0 + 5) = sign_extend(0x7FFFFFF5) -> 0x7FFFFFF5
    li x2, 0x7FFFFFF5
    li x1, 1
    li x1, 0

# TEST: ADDIW (Negative 32b result)
    li x3, 5
    addiw x31, x3, -10   # x31 = sign_extend(5 - 10) = sign_extend(-5 = 0xFFFFFFFB) -> 0xFFFFFFFFFFFFFFFB
    li x2, -5
    li x1, 1
    li x1, 0

# TEST: ADDIW (Overflow 32b positive -> negative)
    li x3, 0x7FFFFFFF
    addiw x31, x3, 1     # x31 = sign_extend(0x7FFFFFFF + 1) = sign_extend(0x80000000 = -2147483648) -> 0xFFFFFFFF80000000
    li x2, 0xFFFFFFFF80000000
    li x1, 1
    li x1, 0

#--------------------------------------------
# Immediate Word Shift Tests (RV64I)
#--------------------------------------------

# TEST: SLLIW
    li x3, 0xFFFFFFFFABCD1234 # Lower 32 bits are ABCD1234
    slliw x31, x3, 4     # x31 = sign_extend( (ABCD1234 << 4) & 0xFFFFFFFF ) = sign_extend(BCDA2340) -> 0xFFFFFFFFBCDA2340 (sign bit 1)
    li x2, 0xFFFFFFFFBCDA2340
    li x1, 1
    li x1, 0

# TEST: SRLIW
    li x3, 0xFFFFFFFFABCD1234 # Lower 32 bits are ABCD1234
    srliw x31, x3, 4     # x31 = sign_extend( (ABCD1234 >> 4) & 0xFFFFFFFF ) = sign_extend(0ABCD123) -> 0x000000000ABCD123 (sign bit 0)
    li x2, 0x0ABCD123
    li x1, 1
    li x1, 0

# TEST: SRAIW (Positive 32-bit)
    li x3, 0x000000007BCD1234 # Lower 32 bits positive
    sraiw x31, x3, 4     # x31 = sign_extend( signed(7BCD1234) >>> 4 ) = sign_extend(07BCD123) -> 0x07BCD123
    li x2, 0x07BCD123
    li x1, 1
    li x1, 0

# TEST: SRAIW (Negative 32-bit)
    li x3, 0xFFFFFFFFABCD1234 # Lower 32 bits negative
    sraiw x31, x3, 4     # x31 = sign_extend( signed(ABCD1234) >>> 4 ) = sign_extend(FABCD123) -> 0xFFFFFFFFFABCD123
    li x2, 0xFFFFFFFFFABCD123
    li x1, 1
    li x1, 0

#--------------------------------------------
# Register Word Arithmetic Tests (RV64I)
#--------------------------------------------

# TEST: ADDW
    li x3, 0x10000000A       # Lower 32-bit is 0xA
    li x4, 0x200000005       # Lower 32-bit is 0x5
    addw x31, x3, x4    # x31 = sign_extend(0xA + 0x5) = sign_extend(0xF) -> 0xF
    li x2, 0xF
    li x1, 1
    li x1, 0

# TEST: SUBW
    li x3, 0xFFFFFFFF8000000A # Lower 32-bit is neg (-ve large + 10)
    li x4, 0x0000000000000005 # Lower 32-bit is 5
    subw x31, x3, x4    # x31 = sign_extend(0x8000000A - 5) = sign_extend(0x80000005) -> 0xFFFFFFFF80000005
    li x2, 0xFFFFFFFF80000005
    li x1, 1
    li x1, 0

#--------------------------------------------
# Register Word Shift Tests (RV64I)
#--------------------------------------------

# TEST: SLLW
    li x3, 0xFFFFFFFFABCD1234
    li x4, 4
    sllw x31, x3, x4    # x31 = sign_extend( (ABCD1234 << 4) & 0xFFFFFFFF ) -> 0xFFFFFFFFBCDA2340
    li x2, 0xFFFFFFFFBCDA2340
    li x1, 1
    li x1, 0

# TEST: SRLW
    li x3, 0xFFFFFFFFABCD1234
    li x4, 4
    srlw x31, x3, x4    # x31 = sign_extend( (ABCD1234 >> 4) & 0xFFFFFFFF ) -> 0x000000000ABCD123
    li x2, 0x0ABCD123
    li x1, 1
    li x1, 0

# TEST: SRAW (Negative 32-bit)
    li x3, 0xFFFFFFFFABCD1234
    li x4, 4
    sraw x31, x3, x4    # x31 = sign_extend( signed(ABCD1234) >>> 4 ) -> 0xFFFFFFFFFABCD123
    li x2, 0xFFFFFFFFFABCD123
    li x1, 1
    li x1, 0

#--------------------------------------------
# Load/Store Tests (Require Memory Setup)
#--------------------------------------------
#.section .data
#.align 3 # Ensure 8-byte alignment for LD/SD
#test_byte:   .byte 0xAA
#test_half:   .half 0xBBCC
#test_word:   .word 0xDDEECCBB
#test_dword:  .dword 0x1122334455667788
#test_store:  .dword 0 # Location to test stores
#
#.section .text
## TEST: LB (Negative byte value)
#    la x3, test_byte      # Load address of test_byte (value 0xAA = -86)
#    lb x31, 0(x3)         # x31 = sign_extend(0xAA) -> 0xFFFFFFFFFFFFFFAA
#    li x2, -86            # Golden (0xFFFFFFFFFFFFFFAA)
#    li x1, 1
#    li x1, 0
#
## TEST: LBU (Positive byte value)
#    la x3, test_byte      # Load address of test_byte (value 0xAA = 170)
#    lbu x31, 0(x3)        # x31 = zero_extend(0xAA) -> 0x00000000000000AA
#    li x2, 170            # Golden (0xAA)
#    li x1, 1
#    li x1, 0
#
## TEST: LH (Negative half value)
#    la x3, test_half      # Load address of test_half (value 0xBBCC = -17204)
#    lh x31, 0(x3)         # x31 = sign_extend(0xBBCC) -> 0xFFFFFFFFFFFFBBCC
#    li x2, -17204         # Golden
#    li x1, 1
#    li x1, 0
#
## TEST: LHU (Positive half value)
#    la x3, test_half      # Load address of test_half (value 0xBBCC = 48076)
#    lhu x31, 0(x3)        # x31 = zero_extend(0xBBCC) -> 0x000000000000BBCC
#    li x2, 48076          # Golden
#    li x1, 1
#    li x1, 0
#
## TEST: LW (Negative word value)
#    la x3, test_word      # Load address of test_word (value 0xDDEECCBB = neg)
#    lw x31, 0(x3)         # x31 = sign_extend(0xDDEECCBB) -> 0xFFFFFFFFDDEECCBB
#    li x2, 0xFFFFFFFFDDEECCBB # Golden
#    li x1, 1
#    li x1, 0
#
## TEST: LWU (Positive word value)
#    la x3, test_word      # Load address of test_word (value 0xDDEECCBB = pos)
#    lwu x31, 0(x3)        # x31 = zero_extend(0xDDEECCBB) -> 0x00000000DDEECCBB
#    li x2, 0xDDEECCBB     # Golden
#    li x1, 1
#    li x1, 0
#
## TEST: LD
#    la x3, test_dword     # Load address of test_dword
#    ld x31, 0(x3)         # x31 = 0x1122334455667788
#    li x2, 0x1122334455667788 # Golden
#    li x1, 1
#    li x1, 0
#
## TEST: SD / LD (Store then load back)
#    la x3, test_store     # Address to store/load from
#    li x4, 0xCAFEBABEDEADBEEF # Value to store
#    sd x4, 0(x3)          # Store value
#    ld x31, 0(x3)         # Load it back
#    li x2, 0xCAFEBABEDEADBEEF # Golden
#    li x1, 1
#    li x1, 0
#
## TEST: SB / LB (Store byte then load back)
#    la x3, test_store     # Address
#    li x4, 0xFF           # Value to store (-1 byte)
#    sb x4, 0(x3)          # Store lowest byte (0xFF)
#    lb x31, 0(x3)         # Load back, should sign extend
#    li x2, -1             # Golden
#    li x1, 1
#    li x1, 0
#
## TEST: SH / LH (Store half then load back)
#    la x3, test_store     # Address
#    li x4, 0xFFFF         # Value to store (-1 half)
#    sh x4, 0(x3)          # Store lowest half (0xFFFF)
#    lh x31, 0(x3)         # Load back, should sign extend
#    li x2, -1             # Golden
#    li x1, 1
#    li x1, 0
#
## TEST: SW / LW (Store word then load back)
#    la x3, test_store     # Address
#    li x4, 0xFFFFFFFF     # Value to store (-1 word)
#    sw x4, 0(x3)          # Store lowest word (0xFFFFFFFF)
#    lw x31, 0(x3)         # Load back, should sign extend
#    li x2, -1             # Golden
#    li x1, 1
#    li x1, 0


#--------------------------------------------
# Jump Tests (Difficult to test rd with this structure)
#--------------------------------------------

# TEST: JAL (rd = PC+4, PC-dependent!)
    # Assume this JAL is at PC = 0x200 for calculation
    # Need to adjust golden value based on actual assembled address
#jal_label_1: nop
#    # ... maybe other instructions here affecting PC ...
#jal_test_inst:
#    jal x31, jal_label_1  # x31 = PC_of_jal_test_inst + 4
#    # *** Execution jumps to jal_label_1 ***
#    # The following lines might not execute as intended after the jump
#    li x2, 0x204          # ** ADJUST GOLDEN VALUE (PC_of_jal_test_inst + 4) **
#    li x1, 1
#    li x1, 0
#    # *** Need code at jal_label_1 to maybe jump back or halt ***

# TEST: JALR (rd = PC+4, PC-dependent! Jump complicates test)
    # Assume this JALR is at PC = 0x300 for calculation
    # Need to adjust golden value based on actual assembled address
    li x30, 0x1000        # Base address for jump target
jalr_test_inst:
    jalr x31, x30, 16     # x31 = PC_of_jalr_test_inst + 4. PC jumps to (0x1000+16)&~1 = 0x1010
    # *** Execution jumps to 0x1010 ***
    # The following lines might not execute as intended after the jump
    li x2, 0x304          # ** ADJUST GOLDEN VALUE (PC_of_jalr_test_inst + 4) **
    li x1, 1
    li x1, 0
    # *** Need code at 0x1010 to maybe jump back or halt ***


#--------------------------------------------
# Branch Tests (Testing which path is taken)
#--------------------------------------------

## TEST: BEQ (Taken)
#    li x3, 100
#    li x4, 100
#    beq x3, x4, beq_taken_path_1
#    # Not taken path (error for this test)
#    li x31, 0xFFFFFFFFFFFFFFFF # -1 indicates failure path taken
#    j beq_end_1
#beq_taken_path_1:
#    li x31, 1 # 1 indicates success path taken
#beq_end_1:
#    li x2, 1  # Golden: Expect taken path code
#    li x1, 1
#    li x1, 0

## TEST: BEQ (Not Taken)
#    li x3, 100
#    li x4, 101
#    beq x3, x4, beq_taken_path_2
#    # Not taken path (success for this test)
#    li x31, 2 # 2 indicates success path taken
#    j beq_end_2
#beq_taken_path_2:
#    li x31, 0xFFFFFFFFFFFFFFFF # -1 indicates failure path taken
#beq_end_2:
#    li x2, 2  # Golden: Expect not taken path code
#    li x1, 1
#    li x1, 0

## TEST: BNE (Taken)
#    li x3, 100
#    li x4, 101
#    bne x3, x4, bne_taken_path_1
#    # Not taken path (error for this test)
#    li x31, -1
#    j bne_end_1
#bne_taken_path_1:
#    li x31, 3 # Success code
#bne_end_1:
#    li x2, 3  # Golden
#    li x1, 1
#    li x1, 0
 
## TEST: BNE (Not Taken)
#    li x3, 100
#    li x4, 100
#    bne x3, x4, bne_taken_path_2
#    # Not taken path (success for this test)
#    li x31, 4 # Success code
#    j bne_end_2
#bne_taken_path_2:
#    li x31, -1
#bne_end_2:
#    li x2, 4  # Golden
#    li x1, 1
#    li x1, 0

## TEST: BLT (Taken, signed)
#    li x3, -10
#    li x4, 10
#    blt x3, x4, blt_taken_path_1
#    # Not taken path
#    li x31, -1
#    j blt_end_1
#blt_taken_path_1:
#    li x31, 5 # Success code
#blt_end_1:
#    li x2, 5  # Golden
#    li x1, 1
#    li x1, 0
#
## TEST: BLT (Not Taken, signed)
#    li x3, 10
#    li x4, -10
#    blt x3, x4, blt_taken_path_2
#    # Not taken path
#    li x31, 6 # Success code
#    j blt_end_2
#blt_taken_path_2:
#    li x31, -1
#blt_end_2:
#    li x2, 6  # Golden
#    li x1, 1
#    li x1, 0
#
## TEST: BGE (Taken, signed)
#    li x3, 10
#    li x4, -10
#    bge x3, x4, bge_taken_path_1
#    # Not taken path
#    li x31, -1
#    j bge_end_1
#bge_taken_path_1:
#    li x31, 7 # Success code
#bge_end_1:
#    li x2, 7  # Golden
#    li x1, 1
#    li x1, 0
#
## TEST: BGE (Not Taken, signed)
#    li x3, -10
#    li x4, 10
#    bge x3, x4, bge_taken_path_2
#    # Not taken path
#    li x31, 8 # Success code
#    j bge_end_2
#bge_taken_path_2:
#    li x31, -1
#bge_end_2:
#    li x2, 8  # Golden
#    li x1, 1
#    li x1, 0
#
## TEST: BLTU (Taken, unsigned)
#    li x3, 10
#    li x4, 20
#    bltu x3, x4, bltu_taken_path_1
#    # Not taken path
#    li x31, -1
#    j bltu_end_1
#bltu_taken_path_1:
#    li x31, 9 # Success code
#bltu_end_1:
#    li x2, 9  # Golden
#    li x1, 1
#    li x1, 0
#
## TEST: BLTU (Not Taken, unsigned, -1 vs 10)
#    li x3, -1 # Max unsigned
#    li x4, 10
#    bltu x3, x4, bltu_taken_path_2
#    # Not taken path
#    li x31, 10 # Success code
#    j bltu_end_2
#bltu_taken_path_2:
#    li x31, -1
#bltu_end_2:
#    li x2, 10 # Golden
#    li x1, 1
#    li x1, 0
#
## TEST: BGEU (Taken, unsigned)
#    li x3, -1 # Max unsigned
#    li x4, 10
#    bgeu x3, x4, bgeu_taken_path_1
#    # Not taken path
#    li x31, -1
#    j bgeu_end_1
#bgeu_taken_path_1:
#    li x31, 11 # Success code
#bgeu_end_1:
#    li x2, 11 # Golden
#    li x1, 1
#    li x1, 0
#
## TEST: BGEU (Not Taken, unsigned)
#    li x3, 10
#    li x4, 20
#    bgeu x3, x4, bgeu_taken_path_2
#    # Not taken path
#    li x31, 12 # Success code
#    j bgeu_end_2
#bgeu_taken_path_2:
#    li x31, -1
#bgeu_end_2:
#    li x2, 12 # Golden
#    li x1, 1
#    li x1, 0


#--------------------------------------------
# End of Tests - Halt Processor
#--------------------------------------------
#_end_tests:
#    j _end_tests  # Infinite loop








#test: li x31, -0x100000000   #-4294967296
#test:
#addi x31, x0, -0x1
#slli x31, x31, 32
#addi x30, x31, 0
#test: li x31, 0x7ff
#test: li x31, 0x7fff
#test2: li x31, 100
#test: li x31, 0x800000001   
#test: li x31, -0x1
#test: li x31, -0x111
#test: li x31, -0x1000
#test: li x31, -0x1800
#test: li x31, -0x800000001   
#lui x31, 0x8
#addi x31, x31, -0x1
#lui x31, -1
#addi x31, x31, 0
#lui x31, -0x1
#addi x31, x0, -0x800
#lui x31, -1
#addi x31, x31, -2048
#addi x31, x0, -0x7 
# addi x31, x31, -100  not work with x31+x31 !!!!
#slli x31, x31, 32
#addi x30, x31, 0
#addi x31, x31, 0x1
#add x31, x31, x30

#lui x31, -4096
#addi x31, x31, 0
#lui x31, -8192
#addi x31, x31, -2047
#slli x30, x30, 32
#add x31, x31, x30







# Setup
#lui x10, 0x12345          # x10 = 0x12345000
#addi x31, x10, 0x678      # x10 = 0x12345678 (Using LUI, ADDI)
## 64-bit shifts
#slli x11, x10, 32         # x11 = 0x1234567800000000 (Using SLLI)
#srli x12, x11, 4          # x12 = 0x0123456780000000 (Using SRLI)
## Make a negative value for srai (-1024)
## Replacing: li x13, -1024
## -1024 fits within the 12-bit signed immediate range of ADDI.
#addi x13, x0, -1024       # x13 = -1024 (0xFFFFFFFFFFFFFC00) using ADDI with x0 (zero reg)
#srai x11, x13, 5          # x11 = -32 (0xFFFFFFFFFFFFFFE0) (Using SRAI)
## 32-bit word operations - result in x10
#addiw x10, x11, 16        # x10 = -16 (0xFFFFFFFFFFFFFFF0) (Using ADDIW)
#slliw x11, x10, 2         # x11 = -64 (0xFFFFFFFFFFFFFFC0) (Using SLLIW)
## Use a positive value for srliw (256)
## Replacing: li x12, 256
## 256 fits within the 12-bit signed immediate range of ADDI.
#addi x12, x0, 256         # x12 = 256 (0x100) using ADDI with x0
#srliw x13, x12, 4         # x13 = 16 (0x10) (Using SRLIW)
## Use the negative value for sraiw
#sraiw x10, x11, 3         # x10 = -8 (0xFFFFFFFFFFFFFFF8) (Using SRAIW)
## Final step to get -4
#addiw x31, x10, 4         # x31 = -4 (0xFFFFFFFFFFFFFFFC) (Using ADDIW)
