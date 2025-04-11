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
#addiw x31, x0, 1 
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
li x30, 0x1
sltiu x31, x30, -0x1

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
