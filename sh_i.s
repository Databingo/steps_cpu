##--------------------------------------------
## Immediate Shift Instructions Tests - RV64
## Using x31 as result (rd)
## Using x5 as rs1 (value), immediate as shift amount
## Using x30 for Golden value
## Using x11 for Compare Signaling
##--------------------------------------------

# -- SLLI Tests (Shift Left Logical Immediate) --
## TEST: SLLI_ZERO_AMT_IMM
    # Purpose: Shift left by 0
    li  x5, 0x123456789ABCDEF0
    slli x31, x5, 0
    li  x30, 0x123456789ABCDEF0 # Expected: Unchanged
    li  x11, 1
    li  x11, 0

## TEST: SLLI_SMALL_AMT_IMM
    # Purpose: Shift left by 4
    li  x5, 0x000000000000000F
    slli x31, x5, 4
    li  x30, 0x00000000000000F0 # Expected: F shifted left
    li  x11, 1
    li  x11, 0

## TEST: SLLI_LARGE_AMT_IMM
    # Purpose: Shift left by 32
    li  x5, 0x00000000FFFFFFFF
    slli x31, x5, 32
    li  x30, 0xFFFFFFFF00000000 # Expected: Shifted into upper half
    li  x11, 1
    li  x11, 0

## TEST: SLLI_MAX_AMT_IMM
    # Purpose: Shift left by 31 (max valid immediate shift)
    li  x5, 0x1
    slli x31, x5, 31
    li  x30, 0x8000000000000000 # Expected: Only MSB set
    li  x11, 1
    li  x11, 0

# -- SRLI Tests (Shift Right Logical Immediate) --
## TEST: SRLI_ZERO_AMT_IMM
    # Purpose: Shift right logical by 0
    li  x5, 0xFEDCBA9876543210
    srli x31, x5, 0
    li  x30, 0xFEDCBA9876543210 # Expected: Unchanged
    li  x11, 1
    li  x11, 0

## TEST: SRLI_SMALL_AMT_IMM
    # Purpose: Shift right logical by 4 (zero fill)
    li  x5, 0xFEDCBA9876543210
    srli x31, x5, 4
    li  x30, 0x0FEDCBA987654321 # Expected: Shifted right, zero fill MSB
    li  x11, 1
    li  x11, 0

## TEST: SRLI_LARGE_AMT_IMM
    # Purpose: Shift right logical by 32
    li  x5, 0x1111111122222222
    srli x31, x5, 32
    li  x30, 0x0000000011111111 # Expected: Upper half shifted down, zero fill
    li  x11, 1
    li  x11, 0

## TEST: SRLI_MAX_AMT_IMM
    # Purpose: Shift right logical by 31 (max valid immediate shift)
    li  x5, 0x8000000000000000 # Min negative (only MSB set)
    srli x31, x5, 31
    li  x30, 0x0000000000000001 # Expected: Only LSB set
    li  x11, 1
    li  x11, 0

# -- SRAI Tests (Shift Right Arithmetic Immediate) --
## TEST: SRAI_ZERO_AMT_IMM
    # Purpose: Shift right arithmetic by 0
    li  x5, 0xFEDCBA9876543210 # Negative number
    srai x31, x5, 0
    li  x30, 0xFEDCBA9876543210 # Expected: Unchanged
    li  x11, 1
    li  x11, 0

## TEST: SRAI_SMALL_AMT_NEG_IMM
    # Purpose: Shift right arithmetic by 4 (sign fill) on negative number
    li  x5, 0xFEDCBA9876543210 # MSB is 1
    srai x31, x5, 4
    li  x30, 0xFFEDCBA987654321 # Expected: Shifted right, sign (1) fill MSBs
    li  x11, 1
    li  x11, 0

## TEST: SRAI_SMALL_AMT_POS_IMM
    # Purpose: Shift right arithmetic by 4 (sign fill) on positive number
    li  x5, 0x7EDCBA9876543210 # MSB is 0
    srai x31, x5, 4
    li  x30, 0x07EDCBA987654321 # Expected: Shifted right, sign (0) fill MSBs
    li  x11, 1
    li  x11, 0

## TEST: SRAI_LARGE_AMT_IMM
    # Purpose: Shift right arithmetic by 32 on negative number
    li  x5, 0xFFFFFFFF11111111 # Negative number
    srai x31, x5, 32
    li  x30, 0xFFFFFFFFFFFFFFFF # Expected: Sign bits propagate
    li  x11, 1
    li  x11, 0

## TEST: SRAI_MAX_AMT_IMM_NEG
    # Purpose: Shift right arithmetic by 31 (max imm) on min negative
    li  x5, 0x8000000000000000
    srai x31, x5, 31
    li  x30, 0xFFFFFFFFFFFFFFFF # Expected: -1 (all sign bits)
    li  x11, 1
    li  x11, 0

## TEST: SRAI_MAX_AMT_IMM_POS
    # Purpose: Shift right arithmetic by 31 (max imm) on max positive
    li  x5, 0x7FFFFFFFFFFFFFFF
    srai x31, x5, 31
    li  x30, 0x0000000000000000 # Expected: 0
    li  x11, 1
    li  x11, 0

## TEST: SRAI_SHIFT_OUT_IMM
    # Purpose: Shift right arithmetic causing all original bits to be lost
    li  x5, 0x7FFFFFFFFFFFFFFF
    srai x31, x5, 31
    li  x30, 0x0000000000000000 # Expected: Zero
    li  x11, 1
    li  x11, 0


##--------------------------------------------
## End of Immediate Shift Tests
##--------------------------------------------
