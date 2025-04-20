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
    li  x30, 0x0000000080000000 # Expected: Only MSB set
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
    li  x30, 0x0000000100000000 # Expected: Only LSB set
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
    li  x30, 0xFFFFFFFF00000000 # Expected: -1 (all sign bits)
    li  x11, 1
    li  x11, 0

## TEST: SRAI_MAX_AMT_IMM_POS
    # Purpose: Shift right arithmetic by 31 (max imm) on max positive
    li  x5, 0x7FFFFFFFFFFFFFFF
    srai x31, x5, 31
    li  x30, 0x00000000FFFFFFFF # Expected: 0
    li  x11, 1
    li  x11, 0

## TEST: SRAI_SHIFT_OUT_IMM
    # Purpose: Shift right arithmetic causing all original bits to be lost
    li  x5, 0x7FFFFFFFFFFFFFFF
    srai x31, x5, 63 
    li  x30, 0x0000000000000000 # Expected: Zero
    li  x11, 1
    li  x11, 0

_start:
    # Initialize register (optional, assuming reset state is 0)
    li x5, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.
    # Current time: Saturday, April 19, 2025 at 11:54 PM PDT

##--------------------------------------------
## Immediate Word Shift Instructions Tests - RV64
## (slliw, srliw, sraiw)
## Using x31 as result (rd)
## Using x5 as rs1 (value)
## Using x30 for Golden value
## Using x11 for Compare Signaling
## Immediate shift amount (shamt) is 5 bits (0-31)
## Result is SIGN-EXTENDED from 32 bits to 64 bits
##--------------------------------------------

# -- SLLIW Tests (Shift Left Logical Immediate Word) --
## TEST: SLLIW_ZERO_AMT
    # Purpose: Shift left word by 0
    li  x5, 0x1111111187654321 # Lower 32 = 0x87654321
    slliw x31, x5, 0           # 32b op: 0x87654321 << 0 = 0x87654321. Sign extend -> 0xFF...87654321
    li  x30, 0xFFFFFFFF87654321
    li  x11, 1
    li  x11, 0

## TEST: SLLIW_SMALL_AMT
    # Purpose: Shift left word by 4
    li  x5, 0x0000000012345678 # Lower 32 = 0x12345678
    slliw x31, x5, 4           # 32b op: 0x12345678 << 4 = 0x23456780. Sign extend -> 0x23456780
    li  x30, 0x23456780
    li  x11, 1
    li  x11, 0

## TEST: SLLIW_MAX_AMT
    # Purpose: Shift left word by 31 (max shamt)
    li  x5, 0x1                 # Lower 32 = 1
    slliw x31, x5, 31          # 32b op: 1 << 31 = 0x80000000. Sign extend -> 0xFF...F80000000
    li  x30, 0xFFFFFFFF80000000
    li  x11, 1
    li  x11, 0

## TEST: SLLIW_INTO_SIGN
    # Purpose: Shift left word, resulting in negative 32b value
    li  x5, 0x40000000         # Lower 32 = 0x40000000
    slliw x31, x5, 1           # 32b op: 0x40000000 << 1 = 0x80000000. Sign extend -> 0xFF...F80000000
    li  x30, 0xFFFFFFFF80000000
    li  x11, 1
    li  x11, 0

## TEST: SLLW_WRAP_32
    # Purpose: Shift left word causing 32b wrap, result positive
    li  x5, 0x87654321         # Lower 32 = 0x87654321
    slliw x31, x5, 4           # 32b op: 0x87654321 << 4 = 0x76543210. Sign extend -> 0x76543210
    li  x30, 0x76543210
    li  x11, 1
    li  x11, 0

# -- SRLIW Tests (Shift Right Logical Immediate Word) --
## TEST: SRLIW_ZERO_AMT
    # Purpose: Shift right logical word by 0
    li  x5, 0xAAAAAAAA87654321 # Lower 32 = 0x87654321
    srliw x31, x5, 0           # 32b op: 0x87654321 >> 0 = 0x87654321. Sign extend -> 0xFF...87654321
    li  x30, 0xFFFFFFFF87654321
    li  x11, 1
    li  x11, 0

## TEST: SRLIW_SMALL_AMT
    # Purpose: Shift right logical word by 4
    li  x5, 0xAAAAAAAA87654321 # Lower 32 = 0x87654321
    srliw x31, x5, 4           # 32b op: 0x87654321 >> 4 = 0x08765432. Sign extend -> 0x08765432
    li  x30, 0x08765432
    li  x11, 1
    li  x11, 0

## TEST: SRLIW_MAX_AMT
    # Purpose: Shift right logical word by 31 (max shamt)
    li  x5, 0xFFFFFFFF         # Lower 32 = -1
    srliw x31, x5, 31          # 32b op: 0xFFFFFFFF >> 31 = 0x1. Sign extend -> 1
    li  x30, 1
    li  x11, 1
    li  x11, 0

## TEST: SRLIW_IGNORES_UPPER
    # Purpose: Ensure upper bits of rs1 are ignored
    li  x5, 0x1111111180000000 # Lower 32 = 0x80000000
    srliw x31, x5, 1           # 32b op: 0x80000000 >> 1 = 0x40000000. Sign extend -> 0x40000000
    li  x30, 0x40000000
    li  x11, 1
    li  x11, 0

# -- SRAIW Tests (Shift Right Arithmetic Immediate Word) --
## TEST: SRAIW_ZERO_AMT
    # Purpose: Shift right arithmetic word by 0
    li  x5, 0xAAAAAAAA87654321 # Lower 32 = 0x87654321
    sraiw x31, x5, 0           # 32b op: 0x87654321 >>> 0 = 0x87654321. Sign extend -> 0xFF...87654321
    li  x30, 0xFFFFFFFF87654321
    li  x11, 1
    li  x11, 0

## TEST: SRAIW_SMALL_AMT_NEG
    # Purpose: Shift right arithmetic word by 4 (negative input)
    li  x5, 0xAAAAAAAA87654321 # Lower 32 = 0x87654321 (MSB=1)
    sraiw x31, x5, 4           # 32b op: 0x87654321 >>> 4 = 0xF8765432. Sign extend -> 0xFF...FF8765432
    li  x30, 0xFFFFFFFFF8765432
    li  x11, 1
    li  x11, 0

## TEST: SRAIW_SMALL_AMT_POS
    # Purpose: Shift right arithmetic word by 4 (positive input)
    li  x5, 0xBBBBBBBB7FEDCBA9 # Lower 32 = 0x7FEDCBA9 (MSB=0)
    sraiw x31, x5, 4           # 32b op: 0x7FEDCBA9 >>> 4 = 0x07FEDCBA. Sign extend -> 0x07FEDCBA
    li  x30, 0x07FEDCBA
    li  x11, 1
    li  x11, 0

## TEST: SRAIW_MAX_AMT_NEG
    # Purpose: Shift right arithmetic word by 31 (max shamt) on negative input
    li  x5, 0x80000000         # Lower 32 = 0x80000000 (-2^31)
    sraiw x31, x5, 31          # 32b op: 0x80000000 >>> 31 = 0xFFFFFFFF (-1). Sign extend -> -1
    li  x30, -1
    li  x11, 1
    li  x11, 0

## TEST: SRAIW_MAX_AMT_POS
    # Purpose: Shift right arithmetic word by 31 (max shamt) on positive input
    li  x5, 0x7FFFFFFF         # Lower 32 = Max positive 32-bit
    sraiw x31, x5, 31          # 32b op: 0x7FFFFFFF >>> 31 = 0x0. Sign extend -> 0
    li  x30, 0
    li  x11, 1
    li  x11, 0
##--------------------------------------------
## Yet More Immediate Word Shift Tests (Extreme Patterns/Operands) - RV64
## Using x31 as result (rd)
## Using x5 as rs1 (value)
## Using x30 for Golden value
## Using x11 for Compare Signaling
##--------------------------------------------

## TEST: SLLIW_PATTERN_A
    # Purpose: Shift left word on alternating 10 pattern
    li  x5, 0xAAAAAAAAAAAAAAAA # Lower 32: 0xAAAAAAAA
    slliw x31, x5, 1           # 32b op: 0xAAAAAAAA << 1 = 0x55555554. Sign extend -> 0x55555554
    li  x30, 0x55555554
    li  x11, 1
    li  x11, 0

## TEST: SRLIW_PATTERN_A
    # Purpose: Shift right logical word on alternating 10 pattern
    li  x5, 0xAAAAAAAAAAAAAAAA # Lower 32: 0xAAAAAAAA
    srliw x31, x5, 1           # 32b op: 0xAAAAAAAA >> 1 = 0x55555555. Sign extend -> 0x55555555
    li  x30, 0x55555555
    li  x11, 1
    li  x11, 0

## TEST: SRAIW_PATTERN_A
    # Purpose: Shift right arithmetic word on alternating 10 pattern
    li  x5, 0xAAAAAAAAAAAAAAAA # Lower 32: 0xAAAAAAAA (Negative 32b)
    sraiw x31, x5, 1           # 32b op: 0xAAAAAAAA >>> 1 = 0xD5555555. Sign extend -> 0xFFFFFFFED5555555
    li  x30, 0xffffffffd5555555
    li  x11, 1
    li  x11, 0

## TEST: SLLIW_PATTERN_5
    # Purpose: Shift left word on alternating 01 pattern
    li  x5, 0x5555555555555555 # Lower 32: 0x55555555
    slliw x31, x5, 1           # 32b op: 0x55555555 << 1 = 0xAAAAAAAA. Sign extend -> 0xFFFFFFFFAAAAAAAA
    li  x30, 0xFFFFFFFFAAAAAAAA
    li  x11, 1
    li  x11, 0

## TEST: SRLIW_PATTERN_5
    # Purpose: Shift right logical word on alternating 01 pattern
    li  x5, 0x5555555555555555 # Lower 32: 0x55555555
    srliw x31, x5, 1           # 32b op: 0x55555555 >> 1 = 0x2AAAAAAA. Sign extend -> 0x2AAAAAAA
    li  x30, 0x2AAAAAAA
    li  x11, 1
    li  x11, 0

## TEST: SRAIW_PATTERN_5
    # Purpose: Shift right arithmetic word on alternating 01 pattern
    li  x5, 0x5555555555555555 # Lower 32: 0x55555555 (Positive 32b)
    sraiw x31, x5, 1           # 32b op: 0x55555555 >>> 1 = 0x2AAAAAAA. Sign extend -> 0x2AAAAAAA
    li  x30, 0x2AAAAAAA
    li  x11, 1
    li  x11, 0

## TEST: SLLIW_ZERO_OPERAND
    # Purpose: Test slliw with zero operand
    li  x5, 0                  # Zero operand
    slliw x31, x5, 15          # Shift amount 15
    li  x30, 0                 # Result should be 0
    li  x11, 1
    li  x11, 0

## TEST: SRLIW_ZERO_OPERAND
    # Purpose: Test srliw with zero operand
    li  x5, 0                  # Zero operand
    srliw x31, x5, 15          # Shift amount 15
    li  x30, 0                 # Result should be 0
    li  x11, 1
    li  x11, 0

## TEST: SRAIW_ZERO_OPERAND
    # Purpose: Test sraiw with zero operand
    li  x5, 0                  # Zero operand
    sraiw x31, x5, 15          # Shift amount 15
    li  x30, 0                 # Result should be 0
    li  x11, 1
    li  x11, 0

## TEST: SLLIW_NEG_ONE_OPERAND
    # Purpose: Test slliw with -1 operand
    li  x5, -1                 # Lower 32: 0xFFFFFFFF
    slliw x31, x5, 1           # 32b op: 0xFFFFFFFF << 1 = 0xFFFFFFFE (-2). Sign extend -> -2
    li  x30, -2
    li  x11, 1
    li  x11, 0

## TEST: SRLIW_NEG_ONE_OPERAND
    # Purpose: Test srliw with -1 operand
    li  x5, -1                 # Lower 32: 0xFFFFFFFF
    srliw x31, x5, 1           # 32b op: 0xFFFFFFFF >> 1 = 0x7FFFFFFF (max pos). Sign extend -> 0x7FFFFFFF
    li  x30, 0x7FFFFFFF
    li  x11, 1
    li  x11, 0

## TEST: SRAIW_NEG_ONE_OPERAND
    # Purpose: Test sraiw with -1 operand
    li  x5, -1                 # Lower 32: 0xFFFFFFFF
    sraiw x31, x5, 1           # 32b op: 0xFFFFFFFF >>> 1 = 0xFFFFFFFF (-1). Sign extend -> -1
    li  x30, -1
    li  x11, 1
    li  x11, 0

##--------------------------------------------
## End of Immediate Word Shift Tests
##--------------------------------------------
