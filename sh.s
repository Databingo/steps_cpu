_start:
    # Initialize registers (optional, assuming reset state is 0)
    li x5, 0
    li x6, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.
    # Current time: Saturday, April 19, 2025 at 8:53 PM PDT

##--------------------------------------------
## Register Shift Instructions Tests - RV64
## (sll, srl, sra, sllw, srlw, sraw)
## Using x31 as result (rd)
## Using x5 as rs1 (value), x6 as rs2 (shift amount)
## Using x30 for Golden value
## Using x11 for Compare Signaling
##--------------------------------------------

# -- SLL Tests (Shift Left Logical Register) --
## TEST: SLL_SMALL_AMT
    li  x5, 0x1111
    li  x6, 8                  # Shift amount in x6[5:0] = 8
    sll x31, x5, x6
    li  x30, 0x111100
    li  x11, 1
    li  x11, 0

## TEST: SLL_LARGE_AMT
    li  x5, 0x1234
    li  x6, 48                 # Shift amount in x6[5:0] = 48
    sll x31, x5, x6
    li  x30, 0x1234000000000000
    li  x11, 1
    li  x11, 0

## TEST: SLL_MAX_AMT
    li  x5, 0x1                 # Value is 1
    li  x6, 63                 # Shift amount in x6[5:0] = 63
    sll x31, x5, x6
    li  x30, 0x8000000000000000 # Expected: Only MSB set
    li  x11, 1
    li  x11, 0

## TEST: SLL_AMT_MASKING
    # Purpose: Test shift amount > 63 (uses only lower 6 bits of rs2)
    li  x5, 0xABCD
    li  x6, 68                 # Shift amount 68. x6[5:0] = 4.
    sll x31, x5, x6            # Should be same as shift by 4
    li  x30, 0xABCD0
    li  x11, 1
    li  x11, 0

# -- SRL Tests (Shift Right Logical Register) --
## TEST: SRL_SMALL_AMT
    li  x5, 0xFF00FF00FF00FF00
    li  x6, 8                  # Shift amount = 8
    srl x31, x5, x6
    li  x30, 0x00FF00FF00FF00FF # Zero fill MSB
    li  x11, 1
    li  x11, 0

## TEST: SRL_LARGE_AMT
    li  x5, 0x1111111122222222
    li  x6, 32                 # Shift amount = 32
    srl x31, x5, x6
    li  x30, 0x0000000011111111 # Upper half shifted down, zero fill
    li  x11, 1
    li  x11, 0

## TEST: SRL_MAX_AMT
    li  x5, 0x8000000000000000 # Min negative (only MSB set)
    li  x6, 63                 # Shift amount = 63
    srl x31, x5, x6
    li  x30, 0x0000000000000001 # Expected: Only LSB set
    li  x11, 1
    li  x11, 0

## TEST: SRL_AMT_MASKING
    # Purpose: Test shift amount > 63 (uses only lower 6 bits of rs2)
    li  x5, 0xFF00FF00FF00FF00
    li  x6, 72                 # Shift amount 72. x6[5:0] = 8.
    srl x31, x5, x6            # Should be same as shift by 8
    li  x30, 0x00FF00FF00FF00FF # Zero fill MSB
    li  x11, 1
    li  x11, 0

# -- SRA Tests (Shift Right Arithmetic Register) --
## TEST: SRA_SMALL_AMT_NEG
    li  x5, 0xFF00FF00FF00FF00 # Negative number (MSB=1)
    li  x6, 8                  # Shift amount = 8
    sra x31, x5, x6
    li  x30, 0xFFFF00FF00FF00FF # Sign bit (1) shifted in
    li  x11, 1
    li  x11, 0

## TEST: SRA_SMALL_AMT_POS
    li  x5, 0x7F00FF00FF00FF00 # Positive number (MSB=0)
    li  x6, 8                  # Shift amount = 8
    sra x31, x5, x6
    li  x30, 0x007F00FF00FF00FF # Sign bit (0) shifted in
    li  x11, 1
    li  x11, 0

## TEST: SRA_LARGE_AMT_NEG
    li  x5, 0x8000000000000000 # Min negative number
    li  x6, 32                 # Shift amount = 32
    sra x31, x5, x6
    li  x30, 0xFFFFFFFF80000000 # Sign bit (1) shifted in
    li  x11, 1
    li  x11, 0

## TEST: SRA_MAX_AMT_NEG
    li  x5, 0x8000000000000000 # Min negative number
    li  x6, 63                 # Shift amount = 63
    sra x31, x5, x6
    li  x30, 0xFFFFFFFFFFFFFFFF # Expected: -1 (all sign bits)
    li  x11, 1
    li  x11, 0

## TEST: SRA_AMT_MASKING
    # Purpose: Test shift amount > 63 (uses only lower 6 bits of rs2)
    li  x5, 0xFF00FF00FF00FF00 # Negative number
    li  x6, 72                 # Shift amount 72. x6[5:0] = 8.
    sra x31, x5, x6            # Should be same as shift by 8
    li  x30, 0xFFFF00FF00FF00FF # Sign bit (1) shifted in
    li  x11, 1
    li  x11, 0

# -- SLLW Tests (Shift Left Logical Word Register) --
## TEST: SLLW_SMALL_AMT
    li  x5, 0x111111110000FFFF # Value to shift (lower 32: 0x0000FFFF)
    li  x6, 8                  # Shift amount = 8 (rs2[4:0]=8)
    sllw x31, x5, x6           # 32-bit op: 0x0000FFFF << 8 = 0x00FFFF00. Sign extend -> 0x00FFFF00
    li  x30, 0x0000000000FFFF00
    li  x11, 1
    li  x11, 0

## TEST: SLLW_MAX_AMT
    li  x5, 0x1                 # Value 1
    li  x6, 31                 # Shift amount = 31 (rs2[4:0]=31)
    sllw x31, x5, x6           # 32-bit op: 1 << 31 = 0x80000000. Sign extend -> 0xFFFFFFFF80000000
    li  x30, 0xFFFFFFFF80000000
    li  x11, 1
    li  x11, 0

## TEST: SLLW_AMT_MASKING
    # Purpose: Test shift amount > 31 (uses only lower 5 bits of rs2)
    li  x5, 0xABCD             # Value 0xABCD
    li  x6, 36                 # Shift amount 36. x6[4:0] = 4.
    sllw x31, x5, x6           # Should be same as 32-bit shift by 4. 0xABCD << 4 = 0xABCD0. Sign extend -> 0xABCD0
    li  x30, 0x00000000000ABCD0
    li  x11, 1
    li  x11, 0

## TEST: SLLW_SIGN_EXT_FROM_POS
    li  x5, 0x00007FFF          # Value 0x7FFF
    li  x6, 16                 # Shift amount 16
    sllw x31, x5, x6           # 32-bit op: 0x7FFF << 16 = 0x7FFF0000. Sign extend -> 0x7FFF0000
    li  x30, 0x000000007FFF0000
    li  x11, 1
    li  x11, 0

## TEST: SLLW_SIGN_EXT_FROM_NEG
    li  x5, 0x00008000          # Value 0x8000
    li  x6, 16                 # Shift amount 16
    sllw x31, x5, x6           # 32-bit op: 0x8000 << 16 = 0x80000000. Sign extend -> 0xFFFFFFFF80000000
    li  x30, 0xFFFFFFFF80000000
    li  x11, 1
    li  x11, 0

# -- SRLW Tests (Shift Right Logical Word Register) --
## TEST: SRLW_SMALL_AMT
    li  x5, 0xAAAAAAAA87654321 # Lower 32: 0x87654321
    li  x6, 4                  # Shift amount = 4 (rs2[4:0]=4)
    srlw x31, x5, x6           # 32-bit op: 0x87654321 >> 4 = 0x08765432. Sign extend -> 0x08765432
    li  x30, 0x0000000008765432
    li  x11, 1
    li  x11, 0

## TEST: SRLW_MAX_AMT
    li  x5, 0xFFFFFFFF         # Lower 32: 0xFFFFFFFF
    li  x6, 31                 # Shift amount = 31
    srlw x31, x5, x6           # 32-bit op: 0xFFFFFFFF >> 31 = 0x1. Sign extend -> 1
    li  x30, 1
    li  x11, 1
    li  x11, 0

## TEST: SRLW_AMT_MASKING
    # Purpose: Test shift amount > 31 (uses only lower 5 bits of rs2)
    li  x5, 0xAAAAAAAA87654321 # Lower 32: 0x87654321
    li  x6, 36                 # Shift amount 36. x6[4:0] = 4.
    srlw x31, x5, x6           # Should be same as 32-bit shift by 4. Result 0x08765432. Sign extend -> 0x08765432
    li  x30, 0x0000000008765432
    li  x11, 1
    li  x11, 0

# -- SRAW Tests (Shift Right Arithmetic Word Register) --
## TEST: SRAW_SMALL_AMT_NEG
    li  x5, 0xAAAAAAAA87654321 # Lower 32: 0x87654321 (MSB=1)
    li  x6, 4                  # Shift amount = 4
    sraw x31, x5, x6           # 32-bit op: 0x87654321 >>> 4 = 0xF8765432. Sign extend -> 0xFFFFFFFFF8765432
    li  x30, 0xFFFFFFFFF8765432
    li  x11, 1
    li  x11, 0

## TEST: SRAW_SMALL_AMT_POS
    li  x5, 0xBBBBBBBB7FEDCBA9 # Lower 32: 0x7FEDCBA9 (MSB=0)
    li  x6, 4                  # Shift amount = 4
    sraw x31, x5, x6           # 32-bit op: 0x7FEDCBA9 >>> 4 = 0x07FEDCBA. Sign extend -> 0x07FEDCBA
    li  x30, 0x0000000007FEDCBA
    li  x11, 1
    li  x11, 0

## TEST: SRAW_MAX_AMT_NEG
    li  x5, 0x80000000         # Lower 32: 0x80000000 (Min neg 32-bit)
    li  x6, 31                 # Shift amount = 31
    sraw x31, x5, x6           # 32-bit op: 0x80000000 >>> 31 = 0xFFFFFFFF (-1). Sign extend -> -1
    li  x30, -1
    li  x11, 1
    li  x11, 0

## TEST: SRAW_AMT_MASKING
    # Purpose: Test shift amount > 31 (uses only lower 5 bits of rs2)
    li  x5, 0xAAAAAAAA87654321 # Lower 32: 0x87654321
    li  x6, 36                 # Shift amount 36. x6[4:0] = 4.
    sraw x31, x5, x6           # Should be same as 32-bit arithmetic shift by 4. Result 0xF8765432. Sign extend -> 0xFF...F8765432
    li  x30, 0xFFFFFFFFF8765432
    li  x11, 1
    li  x11, 0
##--------------------------------------------
## Additional Shift Reg Tests (Extremes/Boundaries) - RV64
## Using x31 as result (rd)
## Using x5 as rs1 (value), x6 as rs2 (shift amount)
## Using x30 for Golden value
## Using x11 for Compare Signaling
##--------------------------------------------

## TEST: SLLW_AMT_31
    # Purpose: Test sllw with max valid shift amount (31)
    li  x5, 0x1                 # Low 32 bits = 1
    li  x6, 31
    sllw x31, x5, x6           # 32b op: 1 << 31 = 0x80000000. Sign extend -> 0xFFFFFFFF80000000
    li  x30, 0xFFFFFFFF80000000
    li  x11, 1
    li  x11, 0

## TEST: SLLW_AMT_32_MASKED
    # Purpose: Test sllw with shift amount 32 (should now use rs2[4:0]=0)
    li  x5, 0x12345678         # Low 32 bits = 0x12345678
    li  x6, 32                 # x6[4:0] = 0
    sllw x31, x5, x6           # 32b op: 0x12345678 << 0 = 0x12345678. Sign extend -> 0x12345678
    li  x30, 0x12345678
    li  x11, 1
    li  x11, 0

## TEST: SRLW_AMT_31
    # Purpose: Test srlw with max valid shift amount (31)
    li  x5, 0xFFFFFFFF         # Lower 32 bits = -1
    li  x6, 31
    srlw x31, x5, x6           # 32b op: 0xFFFFFFFF >> 31 = 0x1. Sign extend -> 1
    li  x30, 1
    li  x11, 1
    li  x11, 0

## TEST: SRLW_AMT_32_MASKED
    # Purpose: Test srlw with shift amount 32 (should now use rs2[4:0]=0)
    li  x5, 0xAAAAAAAA87654321 # Lower 32 bits = 0x87654321
    li  x6, 32                 # x6[4:0] = 0
    srlw x31, x5, x6           # 32b op: 0x87654321 >> 0 = 0x87654321. Sign extend -> 0xFFFFFFFF87654321
    li  x30, 0xFFFFFFFF87654321
    li  x11, 1
    li  x11, 0

## TEST: SRAW_AMT_31
    # Purpose: Test sraw with max valid shift amount (31)
    li  x5, 0x80000000         # Lower 32 bits = -2^31
    li  x6, 31
    sraw x31, x5, x6           # 32b op: 0x80000000 >>> 31 = 0xFFFFFFFF (-1). Sign extend -> -1
    li  x30, -1
    li  x11, 1
    li  x11, 0

## TEST: SRAW_AMT_32_MASKED
    # Purpose: Test sraw with shift amount 32 (should now use rs2[4:0]=0)
    li  x5, 0xAAAAAAAA87654321 # Lower 32 bits = 0x87654321
    li  x6, 32                 # x6[4:0] = 0
    sraw x31, x5, x6           # 32b op: 0x87654321 >>> 0 = 0x87654321. Sign extend -> 0xFFFFFFFF87654321
    li  x30, 0xFFFFFFFF87654321
    li  x11, 1
    li  x11, 0

## TEST: SLL_PATTERN_A
    # Purpose: Shift alternating 10 pattern left
    li  x5, 0xAAAAAAAAAAAAAAAA
    li  x6, 4
    sll x31, x5, x6
    li  x30, 0xAAAAAAAAAAAAAAA0 # Expected: A...A0
    li  x11, 1
    li  x11, 0

## TEST: SRL_PATTERN_A
    # Purpose: Shift alternating 10 pattern right logical
    li  x5, 0xAAAAAAAAAAAAAAAA
    li  x6, 4
    srl x31, x5, x6
    li  x30, 0x0AAAAAAAAAAAAAAA # Expected: 0A...A
    li  x11, 1
    li  x11, 0

## TEST: SRA_PATTERN_A
    # Purpose: Shift alternating 10 pattern right arithmetic
    li  x5, 0xAAAAAAAAAAAAAAAA # Negative
    li  x6, 4
    sra x31, x5, x6
    li  x30, 0xFAAAAAAAAAAAAAAA # Expected: FA...A
    li  x11, 1
    li  x11, 0

## TEST: SLL_SHIFT_BY_64_MASKED
    # Purpose: Test shift by 64 (should use rs2[5:0]=0, be no-op)
    li  x5, 0x123456789ABCDEF0
    li  x6, 64                 # x6[5:0] = 0
    sll x31, x5, x6
    li  x30, 0x123456789ABCDEF0
    li  x11, 1
    li  x11, 0

## TEST: SRL_SHIFT_BY_64_MASKED
    # Purpose: Test shift by 64 (should use rs2[5:0]=0, be no-op)
    li  x5, 0x123456789ABCDEF0
    li  x6, 64                 # x6[5:0] = 0
    srl x31, x5, x6
    li  x30, 0x123456789ABCDEF0
    li  x11, 1
    li  x11, 0

## TEST: SRA_SHIFT_BY_64_MASKED
    # Purpose: Test shift by 64 (should use rs2[5:0]=0, be no-op)
    li  x5, 0x8765432112345678 # Negative
    li  x6, 64                 # x6[5:0] = 0
    sra x31, x5, x6
    li  x30, 0x8765432112345678
    li  x11, 1
    li  x11, 0

## TEST: SLLW_SHIFT_INTO_SIGN
    # Purpose: Test sllw shifting 1 into bit 31, check sign extension
    li  x5, 0x40000000         # Lower 32 bits
    li  x6, 1                  # Shift amount 1
    sllw x31, x5, x6           # 32b result: 0x80000000. Sign extend -> 0xFFFFFFFF80000000
    li  x30, 0xFFFFFFFF80000000
    li  x11, 1
    li  x11, 0

## TEST: SRLW_SHIFT_OUT_SIGN
    # Purpose: Test srlw shifting out sign bit, check sign extension of result
    li  x5, 0x87654321         # Lower 32 bits (MSB=1)
    li  x6, 1                  # Shift amount 1
    srlw x31, x5, x6           # 32b result: 0x43B2A320. Sign extend -> 0x43B2A320
    li  x30, 0x0000000043B2A190
    li  x11, 1
    li  x11, 0

## TEST: SRAW_SHIFT_OUT_SIGN
    # Purpose: Test sraw shifting out sign bit (but replicating it), check sign extension
    li  x5, 0x87654321         # Lower 32 bits (MSB=1)
    li  x6, 1                  # Shift amount 1
    sraw x31, x5, x6           # 32b result: 0xC3B2A320. Sign extend -> 0xFFFFFFFFC3B2A320
    li  x30, 0xFFFFFFFFC3B2A190
    li  x11, 1
    li  x11, 0

## TEST: SLL_ZERO_OPERAND
    # Purpose: Test shifting zero
    li  x5, 0
    li  x6, 15
    sll x31, x5, x6
    li  x30, 0
    li  x11, 1
    li  x11, 0

## TEST: SRAW_ZERO_OPERAND
    # Purpose: Test shifting zero
    li  x5, 0
    li  x6, 15
    sraw x31, x5, x6
    li  x30, 0
    li  x11, 1
    li  x11, 0

## TEST: SRLW_ZERO_OPERAND
    # Purpose: Test shifting zero
    li  x5, 0
    li  x6, 15
    srlw x31, x5, x6
    li  x30, 0
    li  x11, 1
    li  x11, 0
##--------------------------------------------
## Additional Shift Reg Tests (Extreme Amt Source/Self) - RV64
## Using x31 as result (rd)
## Using x5 as rs1 (value), x6 as rs2 (shift amount)
## Using x30 for Golden value
## Using x11 for Compare Signaling
##--------------------------------------------

## TEST: SLL_AMT_X0
    # Purpose: Test shift amount from x0 (should be shift by 0)
    li  x5, 0x1234ABCDFFFF4321
    sll x31, x5, x0            # Shift Amount = x0[5:0] = 0
    li  x30, 0x1234ABCDFFFF4321 # Golden: Unchanged
    li  x11, 1
    li  x11, 0

## TEST: SRL_AMT_X0
    # Purpose: Test shift amount from x0 (should be shift by 0)
    li  x5, 0x87654321FEDCBA98
    srl x31, x5, x0            # Shift Amount = x0[5:0] = 0
    li  x30, 0x87654321FEDCBA98 # Golden: Unchanged
    li  x11, 1
    li  x11, 0

## TEST: SRA_AMT_X0
    # Purpose: Test shift amount from x0 (should be shift by 0)
    li  x5, 0x98BADCFE13579BDF
    sra x31, x5, x0            # Shift Amount = x0[5:0] = 0
    li  x30, 0x98BADCFE13579BDF # Golden: Unchanged
    li  x11, 1
    li  x11, 0

## TEST: SLLW_AMT_X0
    # Purpose: Test word shift amount from x0 (should be shift by 0)
    li  x5, 0x1111111187654321 # Lower 32 = 0x87654321
    sllw x31, x5, x0           # Shift Amount = x0[4:0] = 0
                               # 32b op: 0x87654321 << 0 = 0x87654321. Sign extend -> 0xFF...87654321
    li  x30, 0xFFFFFFFF87654321
    li  x11, 1
    li  x11, 0

## TEST: SRLW_AMT_X0
    # Purpose: Test word shift amount from x0 (should be shift by 0)
    li  x5, 0x1111111187654321 # Lower 32 = 0x87654321
    srlw x31, x5, x0           # Shift Amount = x0[4:0] = 0
                               # 32b op: 0x87654321 >> 0 = 0x87654321. Sign extend -> 0xFF...87654321
    li  x30, 0xFFFFFFFF87654321
    li  x11, 1
    li  x11, 0

## TEST: SRAW_AMT_X0
    # Purpose: Test word shift amount from x0 (should be shift by 0)
    li  x5, 0x1111111176543210 # Lower 32 = 0x76543210
    sraw x31, x5, x0           # Shift Amount = x0[4:0] = 0
                               # 32b op: 0x76543210 >>> 0 = 0x76543210. Sign extend -> 0x76543210
    li  x30, 0x76543210
    li  x11, 1
    li  x11, 0

## TEST: SLL_AMT_NEG_ONE
    # Purpose: Test shift amount from register holding -1 (shift by 63)
    li  x5, 0x3                 # Value = 3
    li  x6, -1                 # x6 = 0xFF...FF, so x6[5:0] = 63 (0x3F)
    sll x31, x5, x6
    li  x30, 0x8000000000000000 # Golden: 3 << 63
    li  x11, 1
    li  x11, 0

## TEST: SRA_AMT_NEG_ONE
    # Purpose: Test shift amount from register holding -1 (shift by 63)
    li  x5, 0x8000000000000002 # Value = -2^63 + 2
    li  x6, -1                 # x6[5:0] = 63 (0x3F)
    sra x31, x5, x6
    li  x30, -1                # Golden: (Negative number) >>> 63 = -1
    li  x11, 1
    li  x11, 0

## TEST: SLLW_AMT_NEG_ONE
    # Purpose: Test word shift amount from register holding -1 (shift by 31)
    li  x5, 0x3                # Lower 32 bits = 3
    li  x6, -1                 # x6 = 0xFF...FF, so x6[4:0] = 31 (0x1F)
    sllw x31, x5, x6           # 32b op: 3 << 31 = 0x80000000. Sign extend -> 0xFFFFFFFF80000000
    li  x30, 0xFFFFFFFF80000000
    li  x11, 1
    li  x11, 0

## TEST: SRAW_AMT_NEG_ONE
    # Purpose: Test word shift amount from register holding -1 (shift by 31)
    li  x5, 0x00000002         # Lower 32 bits = 2
    li  x6, -1                 # x6[4:0] = 31 (0x1F)
    sraw x31, x5, x6           # 32b op: 2 >>> 31 = 0. Sign extend -> 0.
    li  x30, 0
    li  x11, 1
    li  x11, 0

## TEST: SLL_SELF_SHIFT
    # Purpose: Test shift left using rs1 as amount source (x5=4)
    li  x5, 4                  # Value=4, Shift Amount=4 (x5[5:0]=4)
    sll x31, x5, x5            # x31 = 4 << 4 = 64
    li  x30, 64
    li  x11, 1
    li  x11, 0

## TEST: SRA_SELF_SHIFT
    # Purpose: Test shift right arithmetic using rs1 as amount source (x5=-8)
    li  x5, 0xFFFFFFFFFFFFFFF8 # Value = -8, Shift Amount = -8 & 0x3F = 56
    sra x31, x5, x5            # x31 = -8 >>> 56 = -1
    li  x30, -1
    li  x11, 1
    li  x11, 0

## TEST: SRLW_SELF_SHIFT
    # Purpose: Test shift right logical word using rs1 as amount source (x5=10)
    li  x5, 0x0000000A         # Value[31:0] = 10, Shift Amount[4:0] = 10
    srlw x31, x5, x5           # 32b op: 10 >> 10 = 0. Sign extend -> 0
    li  x30, 0
    li  x11, 1
    li  x11, 0

##--------------------------------------------
## End of Register Shift Tests
##--------------------------------------------
