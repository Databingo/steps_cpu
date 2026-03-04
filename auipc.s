_start:
    # Initialize registers (optional)
    li x5, 0
    li x6, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.
    # Current time: Sunday, April 20, 2025 at 7:59 AM PDT

##--------------------------------------------
## AUIPC Tests - RV64
## Using x31 as result (difference)
## Using x5, x6 for intermediate results
## Using x30 for Golden value
## Using x11 for Compare Signaling
##--------------------------------------------

## TEST: AUIPC_DIFF_ZERO_IMM
    # Purpose: Test difference between two AUIPC with imm=0
    auipc x5, 0                # x5 = PC_A + 0
    nop                        # PC_A + 4
    nop                        # PC_A + 8
    nop                        # PC_A + 12
    auipc x6, 0                # x6 = PC_B + 0 = (PC_A + 16) + 0
    sub x31, x6, x5            # x31 = (PC_A + 16) - PC_A = 16
    li  x30, 16                # Expected difference
    li  x11, 1
    li  x11, 0

## TEST: AUIPC_DIFF_POS_IMM
    # Purpose: Test difference with positive immediates
    auipc x5, 1                # x5 = PC_A + (1 << 12) = PC_A + 0x1000
    nop
    nop
    nop
    auipc x6, 2                # x6 = PC_B + (2 << 12) = (PC_A + 16) + 0x2000
    sub x31, x6, x5            # x31 = (PC_A + 16 + 0x2000) - (PC_A + 0x1000)
                               # x31 = 16 + 0x1000 = 16 + 4096 = 4112
    li  x30, 4112              # Expected difference
    li  x11, 1
    li  x11, 0

## TEST: AUIPC_DIFF_NEG_IMM
    # Purpose: Test difference involving negative immediates
    # imm = 0xFFFFF -> sign_extend(imm << 12) = 0xFFFFFFFFFFFFF000 (-4096)
    # imm = 0xFFFFF = -1 in 20 bits. No, 0xFFFFF is max 20 bit value.
    # Min neg 20 bit imm = 0x80000. sign_extend(0x80000 << 12) = 0xFFFFFFFF80000000
    # Max neg 20 bit imm = 0xFFFFF. sign_extend(0xFFFFF << 12) = 0xFFFFFFFFFFFFF000
    auipc x5, 0xFFFFF          # x5 = PC_A + 0xFFFFFFFFFFFFF000 (PC_A - 4096)
    nop
    nop
    nop
    auipc x6, 0                # x6 = PC_B + 0 = (PC_A + 16) + 0
    sub x31, x6, x5            # x31 = (PC_A + 16) - (PC_A - 4096)
                               # x31 = 16 + 4096 = 4112
    li  x30, 4112              # Expected difference
    li  x11, 1
    li  x11, 0

## TEST: AUIPC_DIFF_MIXED_IMM
    # Purpose: Test difference with mixed sign immediates
    auipc x5, 0x7FFFF          # x5 = PC_A + 0x7FFFF000 (Max positive offset)
    nop
    nop
    nop
    auipc x6, 0x80000          # x6 = PC_B + 0xFFFFFFFF80000000 (Min negative offset)
                               # PC_B = PC_A + 16
                               # x6 = PC_A + 16 - 0x80000000 (effectively)
    # The offset calculation needs care: sign_extend(imm << 12)
    # imm=0x7FFFF -> offset = 0x000000007FFFF000
    # imm=0x80000 -> offset = 0xFFFFFFFF80000000
    # x5 = PC_A + 0x7FFFF000
    # x6 = PC_A + 16 + 0xFFFFFFFF80000000
    sub x31, x6, x5            # x31 = (PC_A + 16 + 0xFFFFFFFF80000000) - (PC_A + 0x7FFFF000)
                               # x31 = 16 + (-2^31 shifted) - (2^31-1 shifted) ?? No.
                               # x31 = 16 + (-0x80000000) - (0x7FFFF000) ?? Still confusing.
                               # Let's use 64-bit hex math:
                               # x31 = 16 + 0xFFFFFFFF80000000 - 0x000000007FFFF000
                               # x31 = 16 + (0xFFFFFFFF80000000 - 0x000000007FFFF000)
                               # Borrowing: 0x80000000 - 0x7FFFF000 = 0x1000
                               # Upper remains 0xFFFFFFFF
                               # Diff = 0xFFFFFFFF00001000
                               # x31 = 16 (0x10) + 0xFFFFFFFF00001000
                               # x31 = 0xFFFFFFFF00001010
    li  x30, 0xFFFFFFFF00001010 # Expected difference
    li  x11, 1
    li  x11, 0


##--------------------------------------------
## End of AUIPC Tests
##--------------------------------------------
