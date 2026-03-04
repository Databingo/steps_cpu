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
#
## TEST: ADDI (Zero)
#    li x3, 1000
#    addi x31, x3, 0     # x31 = 1000 + 0 = 1000
#    li x2, 1000         # Golden
#    li x1, 1            # Signal Compare
#    li x1, 0            # Clear Signal
#
## TEST: SLTI (Less Than - True)
#    li x3, -50
#    slti x31, x3, 100   # x31 = (signed(-50) < signed(100)) ? 1 : 0 -> 1
#    li x2, 1            # Golden
#    li x1, 1            # Signal Compare
#    li x1, 0            # Clear Signal
#
## TEST: SLTI (Less Than - False)
#    li x3, 150
#    slti x31, x3, 100   # x31 = (signed(150) < signed(100)) ? 1 : 0 -> 0
#    li x2, 0            # Golden
#    li x1, 1            # Signal Compare
#    li x1, 0            # Clear Signal
#
## TEST: SLTI (Equal - False)
#    li x3, 100
#    slti x31, x3, 100   # x31 = (signed(100) < signed(100)) ? 1 : 0 -> 0
#    li x2, 0            # Golden
#    li x1, 1            # Signal Compare
#    li x1, 0            # Clear Signal
#
## TEST: SLTIU (Less Than Unsigned - True)
#    li x3, 50
#    sltiu x31, x3, 100  # x31 = (unsigned(50) < unsigned(100)) ? 1 : 0 -> 1
#    li x2, 1            # Golden
#    li x1, 1            # Signal Compare
#    li x1, 0            # Clear Signal
#
## TEST: SLTIU (Less Than Unsigned - False, comparing with -1 = max_unsigned)
#    li x3, 50
#    sltiu x31, x3, -1   # x31 = (unsigned(50) < unsigned(-1)) ? 1 : 0 -> 1 (since -1 is max uint)
#    li x2, 1            # Golden
#    li x1, 1            # Signal Compare
#    li x1, 0            # Clear Signal
#
## TEST: SLTIU (Immediate 1 -> True)
#    li x3, 0
#    sltiu x31, x3, 1    # x31 = (unsigned(0) < unsigned(1)) ? 1 : 0 -> 1
#    li x2, 1            # Golden
#    li x1, 1            # Signal Compare
#    li x1, 0            # Clear Signal
#
## TEST: ANDI
#   li x3, 0x0F0F0F0F
#   # andi x31, x3, 0xFF  # x31 = 0x0F0F0F0F & 0x...00FF = 0x0F
#   # li x2, 0x0F
#   # li x1, 1
#   # li x1, 0
#
### TEST: ORI
##    li x3, 0x0F0F0F0F
##    ori x31, x3, 0xF0   # x31 = 0x0F0F0F0F | 0x...00F0 = 0x0F0F0FFF
##    li x2, 0x0F0F0FFF
##    li x1, 1
##    li x1, 0
##
### TEST: XORI
##    li x3, 0xAAAA5555
##    xori x31, x3, 0xFFF # x31 = 0xAAAA5555 ^ 0x...0FFF = 0xAAAA5AAA
##    li x2, 0xAAAA5AAA
##    li x1, 1
##    li x1, 0
#
###--------------------------------------------
### Immediate Shift Tests
###--------------------------------------------
##
### TEST: SLLI (64-bit)
##    li x3, 0x1111222233334444
##    slli x31, x3, 4     # x31 = 0x1112222333344440
##    li x2, 0x1112222333344440
##    li x1, 1
##    li x1, 0
##
### TEST: SRLI (64-bit)
##    li x3, 0xF111222233334444
##    srli x31, x3, 4     # x31 = 0x0F11122223333444 (logical shift, zero fill)
##    li x2, 0x0F11122223333444
##    li x1, 1
##    li x1, 0
##
### TEST: SRAI (64-bit, Positive)
##    li x3, 0x0111222233334444
##    srai x31, x3, 4     # x31 = 0x0011122223333444 (arithmetic shift, sign bit 0)
##    li x2, 0x0011122223333444
##    li x1, 1
##    li x1, 0
##
### TEST: SRAI (64-bit, Negative)
##    li x3, 0xF111222233334444 # Sign bit is 1
##    srai x31, x3, 4     # x31 = 0xFF11122223333444 (arithmetic shift, sign bit 1 replicated)
##    li x2, 0xFF11122223333444
##    li x1, 1
##    li x1, 0
##
###--------------------------------------------
### Upper Immediate Tests
###--------------------------------------------
##
### TEST: LUI
##    lui x31, 0xBADF0     # x31 = 0xBADF0000. Sign extend? No. = 0x00000000BADF0000
##    li x2, 0xBADF0000
##    li x1, 1
##    li x1, 0
##
### TEST: AUIPC (Result depends on PC!)
##    # Assume this instruction is at PC = 0x100 for calculation
##    # Need to adjust golden value based on actual assembled address
##    auipc x31, 0xBEEF   # x31 = PC + (0xBEEF << 12) = 0x100 + 0xBEEF0000 = 0x00000000BEEF0100
##    li x2, 0xBEEF0100   # ** ADJUST GOLDEN VALUE BASED ON ACTUAL PC **
##    li x1, 1
##    li x1, 0
##
###--------------------------------------------
### Register Arithmetic Tests
###--------------------------------------------
##
### TEST: ADD
##    li x3, 0x1000
##    li x4, 0x2345
##    add x31, x3, x4     # x31 = 0x1000 + 0x2345 = 0x3345
##    li x2, 0x3345
##    li x1, 1
##    li x1, 0
##
### TEST: SUB
##    li x3, 0x3000
##    li x4, 0x1111
##    sub x31, x3, x4     # x31 = 0x3000 - 0x1111 = 0x1EEE
##    li x2, 0x1EEE
##    li x1, 1
##    li x1, 0
##
### TEST: SLT (Signed Less Than - True)
##    li x3, -10
##    li x4, 10
##    slt x31, x3, x4     # x31 = (signed(-10) < signed(10)) ? 1 : 0 -> 1
##    li x2, 1
##    li x1, 1
##    li x1, 0
##
### TEST: SLT (Signed Less Than - False)
##    li x3, 10
##    li x4, -10
##    slt x31, x3, x4     # x31 = (signed(10) < signed(-10)) ? 1 : 0 -> 0
##    li x2, 0
##    li x1, 1
##    li x1, 0
##
### TEST: SLTU (Unsigned Less Than - True)
##    li x3, 10
##    li x4, 20
##    sltu x31, x3, x4    # x31 = (unsigned(10) < unsigned(20)) ? 1 : 0 -> 1
##    li x2, 1
##    li x1, 1
##    li x1, 0
##
### TEST: SLTU (Unsigned Less Than - False, comparing -1)
##    li x3, -1           # Max unsigned value
##    li x4, 10
##    sltu x31, x3, x4    # x31 = (unsigned(-1) < unsigned(10)) ? 1 : 0 -> 0
##    li x2, 0
##    li x1, 1
##    li x1, 0
##
### TEST: AND
##    li x3, 0xF0F0F0F0
##    li x4, 0x00FF00FF
##    and x31, x3, x4     # x31 = 0x00F000F0
##    li x2, 0x00F000F0
##    li x1, 1
##    li x1, 0
##
### TEST: OR
##    li x3, 0xF0F0F0F0
##    li x4, 0x00FF00FF
##    or x31, x3, x4      # x31 = 0xF0FFF0FF
##    li x2, 0xF0FFF0FF
##    li x1, 1
##    li x1, 0
##
### TEST: XOR
##    li x3, 0xF0F0F0F0
##    li x4, 0x00FF00FF
##    xor x31, x3, x4     # x31 = 0xF00FF00F
##    li x2, 0xF00FF00F
##    li x1, 1
##    li x1, 0
##
###--------------------------------------------
### Register Shift Tests
###--------------------------------------------
##
### TEST: SLL (Shift amount < 64)
##    li x3, 0x1111222233334444
##    li x4, 4
##    sll x31, x3, x4     # x31 = 0x1112222333344440
##    li x2, 0x1112222333344440
##    li x1, 1
##    li x1, 0
##
### TEST: SRL (Shift amount < 64)
##    li x3, 0xF111222233334444
##    li x4, 4
##    srl x31, x3, x4     # x31 = 0x0F11122223333444
##    li x2, 0x0F11122223333444
##    li x1, 1
##    li x1, 0
##
### TEST: SRA (Shift amount < 64, Negative)
##    li x3, 0xF111222233334444
##    li x4, 4
##    sra x31, x3, x4     # x31 = 0xFF11122223333444
##    li x2, 0xFF11122223333444
##    li x1, 1
##    li x1, 0
##
###--------------------------------------------
### Immediate Word Arithmetic Tests (RV64I)
###--------------------------------------------
##
### TEST: ADDIW (Positive 32b result)
##    li x3, 0x7FFFFFF0    # Positive 32-bit value
##    addiw x31, x3, 5     # x31 = sign_extend(0x7FFFFFF0 + 5) = sign_extend(0x7FFFFFF5) -> 0x7FFFFFF5
##    li x2, 0x7FFFFFF5
##    li x1, 1
##    li x1, 0
##
### TEST: ADDIW (Negative 32b result)
##    li x3, 5
##    addiw x31, x3, -10   # x31 = sign_extend(5 - 10) = sign_extend(-5 = 0xFFFFFFFB) -> 0xFFFFFFFFFFFFFFFB
##    li x2, -5
##    li x1, 1
##    li x1, 0
##
### TEST: ADDIW (Overflow 32b positive -> negative)
##    li x3, 0x7FFFFFFF
##    addiw x31, x3, 1     # x31 = sign_extend(0x7FFFFFFF + 1) = sign_extend(0x80000000 = -2147483648) -> 0xFFFFFFFF80000000
##    li x2, 0xFFFFFFFF80000000
##    li x1, 1
##    li x1, 0
##
###--------------------------------------------
### Immediate Word Shift Tests (RV64I)
###--------------------------------------------
##
### TEST: SLLIW
##    li x3, 0xFFFFFFFFABCD1234 # Lower 32 bits are ABCD1234
##    slliw x31, x3, 4     # x31 = sign_extend( (ABCD1234 << 4) & 0xFFFFFFFF ) = sign_extend(BCDA2340) -> 0xFFFFFFFFBCDA2340 (sign bit 1)
##    li x2, 0xFFFFFFFFBCDA2340
##    li x1, 1
##    li x1, 0
##
### TEST: SRLIW
##    li x3, 0xFFFFFFFFABCD1234 # Lower 32 bits are ABCD1234
##    srliw x31, x3, 4     # x31 = sign_extend( (ABCD1234 >> 4) & 0xFFFFFFFF ) = sign_extend(0ABCD123) -> 0x000000000ABCD123 (sign bit 0)
##    li x2, 0x0ABCD123
##    li x1, 1
##    li x1, 0
##
### TEST: SRAIW (Positive 32-bit)
##    li x3, 0x000000007BCD1234 # Lower 32 bits positive
##    sraiw x31, x3, 4     # x31 = sign_extend( signed(7BCD1234) >>> 4 ) = sign_extend(07BCD123) -> 0x07BCD123
##    li x2, 0x07BCD123
##    li x1, 1
##    li x1, 0
##
### TEST: SRAIW (Negative 32-bit)
##    li x3, 0xFFFFFFFFABCD1234 # Lower 32 bits negative
##    sraiw x31, x3, 4     # x31 = sign_extend( signed(ABCD1234) >>> 4 ) = sign_extend(FABCD123) -> 0xFFFFFFFFFABCD123
##    li x2, 0xFFFFFFFFFABCD123
##    li x1, 1
##    li x1, 0
##
###--------------------------------------------
### Register Word Arithmetic Tests (RV64I)
###--------------------------------------------
##
### TEST: ADDW
##    li x3, 0x10000000A       # Lower 32-bit is 0xA
##    li x4, 0x200000005       # Lower 32-bit is 0x5
##    addw x31, x3, x4    # x31 = sign_extend(0xA + 0x5) = sign_extend(0xF) -> 0xF
##    li x2, 0xF
##    li x1, 1
##    li x1, 0
##
### TEST: SUBW
##    li x3, 0xFFFFFFFF8000000A # Lower 32-bit is neg (-ve large + 10)
##    li x4, 0x0000000000000005 # Lower 32-bit is 5
##    subw x31, x3, x4    # x31 = sign_extend(0x8000000A - 5) = sign_extend(0x80000005) -> 0xFFFFFFFF80000005
##    li x2, 0xFFFFFFFF80000005
##    li x1, 1
##    li x1, 0
##
###--------------------------------------------
### Register Word Shift Tests (RV64I)
###--------------------------------------------
##
### TEST: SLLW
##    li x3, 0xFFFFFFFFABCD1234
##    li x4, 4
##    sllw x31, x3, x4    # x31 = sign_extend( (ABCD1234 << 4) & 0xFFFFFFFF ) -> 0xFFFFFFFFBCDA2340
##    li x2, 0xFFFFFFFFBCDA2340
##    li x1, 1
##    li x1, 0
##
### TEST: SRLW
##    li x3, 0xFFFFFFFFABCD1234
##    li x4, 4
##    srlw x31, x3, x4    # x31 = sign_extend( (ABCD1234 >> 4) & 0xFFFFFFFF ) -> 0x000000000ABCD123
##    li x2, 0x0ABCD123
##    li x1, 1
##    li x1, 0
##
### TEST: SRAW (Negative 32-bit)
##    li x3, 0xFFFFFFFFABCD1234
##    li x4, 4
##    sraw x31, x3, x4    # x31 = sign_extend( signed(ABCD1234) >>> 4 ) -> 0xFFFFFFFFFABCD123
##    li x2, 0xFFFFFFFFFABCD123
##    li x1, 1
##    li x1, 0
##
###--------------------------------------------
### Load/Store Tests (Require Memory Setup)
###--------------------------------------------
###.section .data
###.align 3 # Ensure 8-byte alignment for LD/SD
###test_byte:   .byte 0xAA
###test_half:   .half 0xBBCC
###test_word:   .word 0xDDEECCBB
###test_dword:  .dword 0x1122334455667788
###test_store:  .dword 0 # Location to test stores
###
###.section .text
#### TEST: LB (Negative byte value)
###    la x3, test_byte      # Load address of test_byte (value 0xAA = -86)
###    lb x31, 0(x3)         # x31 = sign_extend(0xAA) -> 0xFFFFFFFFFFFFFFAA
###    li x2, -86            # Golden (0xFFFFFFFFFFFFFFAA)
###    li x1, 1
###    li x1, 0
###
#### TEST: LBU (Positive byte value)
###    la x3, test_byte      # Load address of test_byte (value 0xAA = 170)
###    lbu x31, 0(x3)        # x31 = zero_extend(0xAA) -> 0x00000000000000AA
###    li x2, 170            # Golden (0xAA)
###    li x1, 1
###    li x1, 0
###
#### TEST: LH (Negative half value)
###    la x3, test_half      # Load address of test_half (value 0xBBCC = -17204)
###    lh x31, 0(x3)         # x31 = sign_extend(0xBBCC) -> 0xFFFFFFFFFFFFBBCC
###    li x2, -17204         # Golden
###    li x1, 1
###    li x1, 0
###
#### TEST: LHU (Positive half value)
###    la x3, test_half      # Load address of test_half (value 0xBBCC = 48076)
###    lhu x31, 0(x3)        # x31 = zero_extend(0xBBCC) -> 0x000000000000BBCC
###    li x2, 48076          # Golden
###    li x1, 1
###    li x1, 0
###
#### TEST: LW (Negative word value)
###    la x3, test_word      # Load address of test_word (value 0xDDEECCBB = neg)
###    lw x31, 0(x3)         # x31 = sign_extend(0xDDEECCBB) -> 0xFFFFFFFFDDEECCBB
###    li x2, 0xFFFFFFFFDDEECCBB # Golden
###    li x1, 1
###    li x1, 0
###
#### TEST: LWU (Positive word value)
###    la x3, test_word      # Load address of test_word (value 0xDDEECCBB = pos)
###    lwu x31, 0(x3)        # x31 = zero_extend(0xDDEECCBB) -> 0x00000000DDEECCBB
###    li x2, 0xDDEECCBB     # Golden
###    li x1, 1
###    li x1, 0
###
#### TEST: LD
###    la x3, test_dword     # Load address of test_dword
###    ld x31, 0(x3)         # x31 = 0x1122334455667788
###    li x2, 0x1122334455667788 # Golden
###    li x1, 1
###    li x1, 0
###
#### TEST: SD / LD (Store then load back)
###    la x3, test_store     # Address to store/load from
###    li x4, 0xCAFEBABEDEADBEEF # Value to store
###    sd x4, 0(x3)          # Store value
###    ld x31, 0(x3)         # Load it back
###    li x2, 0xCAFEBABEDEADBEEF # Golden
###    li x1, 1
###    li x1, 0
###
#### TEST: SB / LB (Store byte then load back)
###    la x3, test_store     # Address
###    li x4, 0xFF           # Value to store (-1 byte)
###    sb x4, 0(x3)          # Store lowest byte (0xFF)
###    lb x31, 0(x3)         # Load back, should sign extend
###    li x2, -1             # Golden
###    li x1, 1
###    li x1, 0
###
#### TEST: SH / LH (Store half then load back)
###    la x3, test_store     # Address
###    li x4, 0xFFFF         # Value to store (-1 half)
###    sh x4, 0(x3)          # Store lowest half (0xFFFF)
###    lh x31, 0(x3)         # Load back, should sign extend
###    li x2, -1             # Golden
###    li x1, 1
###    li x1, 0
###
#### TEST: SW / LW (Store word then load back)
###    la x3, test_store     # Address
###    li x4, 0xFFFFFFFF     # Value to store (-1 word)
###    sw x4, 0(x3)          # Store lowest word (0xFFFFFFFF)
###    lw x31, 0(x3)         # Load back, should sign extend
###    li x2, -1             # Golden
###    li x1, 1
###    li x1, 0
##
##
###--------------------------------------------
### Jump Tests (Difficult to test rd with this structure)
###--------------------------------------------
##
### TEST: JAL (rd = PC+4, PC-dependent!)
##    # Assume this JAL is at PC = 0x200 for calculation
##    # Need to adjust golden value based on actual assembled address
###jal_label_1: nop
###    # ... maybe other instructions here affecting PC ...
###jal_test_inst:
###    jal x31, jal_label_1  # x31 = PC_of_jal_test_inst + 4
###    # *** Execution jumps to jal_label_1 ***
###    # The following lines might not execute as intended after the jump
###    li x2, 0x204          # ** ADJUST GOLDEN VALUE (PC_of_jal_test_inst + 4) **
###    li x1, 1
###    li x1, 0
###    # *** Need code at jal_label_1 to maybe jump back or halt ***
##
### TEST: JALR (rd = PC+4, PC-dependent! Jump complicates test)
##    # Assume this JALR is at PC = 0x300 for calculation
##    # Need to adjust golden value based on actual assembled address
##    li x30, 0x1000        # Base address for jump target
##jalr_test_inst:
##    jalr x31, x30, 16     # x31 = PC_of_jalr_test_inst + 4. PC jumps to (0x1000+16)&~1 = 0x1010
##    # *** Execution jumps to 0x1010 ***
##    # The following lines might not execute as intended after the jump
##    li x2, 0x304          # ** ADJUST GOLDEN VALUE (PC_of_jalr_test_inst + 4) **
##    li x1, 1
##    li x1, 0
##    # *** Need code at 0x1010 to maybe jump back or halt ***
##
##
###--------------------------------------------
### Branch Tests (Testing which path is taken)
###--------------------------------------------
