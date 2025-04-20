_start:
    # Initialize registers (optional, assuming reset state is 0)
    li x5, 0
    li x6, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.
    # Current time: Saturday, April 19, 2025 at 8:12 PM PDT

##--------------------------------------------
## Logical AND/OR/XOR Tests - RV64
## Using x31 as result (rd)
## Using x5 as rs1, x6 as rs2
## Using x30 for Golden value
## Using x11 for Compare Signaling
##--------------------------------------------

# -- AND Tests (Bitwise AND) --
## TEST: AND_ZERO_RIGHT
    # Purpose: x & 0 = 0
    li  x5, 0x123456789ABCDEF0
    li  x6, 0
    and x31, x5, x6
    li  x30, 0                  # Expected: 0
    li  x11, 1
    li  x11, 0

## TEST: AND_ZERO_LEFT
    # Purpose: 0 & x = 0
    li  x5, 0
    li  x6, 0x123456789ABCDEF0
    and x31, x5, x6
    li  x30, 0                  # Expected: 0
    li  x11, 1
    li  x11, 0

## TEST: AND_IDENTICAL
    # Purpose: x & x = x
    li  x5, 0xAABBCCDDEEFF0011
    li  x6, 0xAABBCCDDEEFF0011
    and x31, x5, x6
    li  x30, 0xAABBCCDDEEFF0011 # Expected: x
    li  x11, 1
    li  x11, 0

## TEST: AND_ALL_ONES
    # Purpose: x & -1 = x
    li  x5, 0x1234ABCD4321EF01
    li  x6, -1                 # x6 = 0xFF...FF
    and x31, x5, x6
    li  x30, 0x1234ABCD4321EF01 # Expected: x
    li  x11, 1
    li  x11, 0

## TEST: AND_PATTERNS_1
    # Purpose: Test specific patterns
    li  x5, 0xF0F0F0F0F0F0F0F0
    li  x6, 0x0FF00FF00FF00FF0
    and x31, x5, x6
    li  x30, 0x00F000F000F000F0  # Expected: overlapping bits
    li  x11, 1
    li  x11, 0

## TEST: AND_PATTERNS_2
    # Purpose: Test alternating patterns
    li  x5, 0xAAAAAAAAAAAAAAAA
    li  x6, 0x5555555555555555
    and x31, x5, x6
    li  x30, 0                  # Expected: 0 (no common bits)
    li  x11, 1
    li  x11, 0

## TEST: AND_MASK_BYTE
    # Purpose: Masking lower byte (value & 0xFF)
    li  x5, 0x123456789ABCDEF0
    li  x6, 0xFF
    and x31, x5, x6
    li  x30, 0xF0               # Expected: lower byte
    li  x11, 1
    li  x11, 0

# -- OR Tests (Bitwise OR) --
## TEST: OR_ZERO_RIGHT
    # Purpose: x | 0 = x
    li  x5, 0x123456789ABCDEF0
    li  x6, 0
    or  x31, x5, x6
    li  x30, 0x123456789ABCDEF0 # Expected: x
    li  x11, 1
    li  x11, 0

## TEST: OR_ZERO_LEFT
    # Purpose: 0 | x = x
    li  x5, 0
    li  x6, 0x123456789ABCDEF0
    or  x31, x5, x6
    li  x30, 0x123456789ABCDEF0 # Expected: x
    li  x11, 1
    li  x11, 0

## TEST: OR_IDENTICAL
    # Purpose: x | x = x
    li  x5, 0xAABBCCDDEEFF0011
    li  x6, 0xAABBCCDDEEFF0011
    or  x31, x5, x6
    li  x30, 0xAABBCCDDEEFF0011 # Expected: x
    li  x11, 1
    li  x11, 0

## TEST: OR_ALL_ONES
    # Purpose: x | -1 = -1
    li  x5, 0x1234ABCD4321EF01
    li  x6, -1                 # x6 = 0xFF...FF
    or  x31, x5, x6
    li  x30, -1                # Expected: -1 (0xFF...FF)
    li  x11, 1
    li  x11, 0

## TEST: OR_PATTERNS_1
    # Purpose: Test specific patterns
    li  x5, 0xF0F0F0F0F0F0F0F0
    li  x6, 0x0FF00FF00FF00FF0
    or  x31, x5, x6
    li  x30, 0xFFF0FFF0FFF0FFF0  # <-- CORRECTED Golden Value (was 17 digits)
    li  x11, 1
    li  x11, 0

## TEST: OR_PATTERNS_2
    # Purpose: Test alternating patterns
    li  x5, 0xAAAAAAAAAAAAAAAA
    li  x6, 0x5555555555555555
    or  x31, x5, x6
    li  x30, 0xFFFFFFFFFFFFFFFF # Expected: -1 (all bits set)
    li  x11, 1
    li  x11, 0

## TEST: OR_SET_BITS
    # Purpose: Setting lower bits (value | 0xFF)
    li  x5, 0x123456789ABCDE00
    li  x6, 0xFF
    or  x31, x5, x6
    li  x30, 0x123456789ABCDEFF # Expected: lower byte set
    li  x11, 1
    li  x11, 0

# -- XOR Tests (Bitwise XOR) --
## TEST: XOR_ZERO_RIGHT
    # Purpose: x ^ 0 = x
    li  x5, 0x123456789ABCDEF0
    li  x6, 0
    xor x31, x5, x6
    li  x30, 0x123456789ABCDEF0 # Expected: x
    li  x11, 1
    li  x11, 0

## TEST: XOR_ZERO_LEFT
    # Purpose: 0 ^ x = x
    li  x5, 0
    li  x6, 0x123456789ABCDEF0
    xor x31, x5, x6
    li  x30, 0x123456789ABCDEF0 # Expected: x
    li  x11, 1
    li  x11, 0

## TEST: XOR_IDENTICAL
    # Purpose: x ^ x = 0
    li  x5, 0xAABBCCDDEEFF0011
    li  x6, 0xAABBCCDDEEFF0011
    xor x31, x5, x6
    li  x30, 0                  # Expected: 0
    li  x11, 1
    li  x11, 0

## TEST: XOR_ALL_ONES (NOT)
    # Purpose: x ^ -1 = ~x (Bitwise NOT)
    li  x5, 0x123456789ABCDEF0
    li  x6, -1                 # x6 = 0xFF...FF
    xor x31, x5, x6
    li  x30, 0xEDCBA9876543210F # Expected: ~x
    li  x11, 1
    li  x11, 0

## TEST: XOR_PATTERNS_1
    # Purpose: Test specific patterns
    li  x5,  0xF0F0F0F0F0F0F0F0
    li  x6,  0x0FF00FF00FF00FF0
    xor x31, x5, x6
    li  x30, 0xFF00FF00FF00FF00 # Expected: bits where inputs differ
    li  x11, 1
    li  x11, 0

## TEST: XOR_PATTERNS_2
    # Purpose: Test alternating patterns
    li  x5, 0xAAAAAAAAAAAAAAAA
    li  x6, 0x5555555555555555
    xor x31, x5, x6
    li  x30, 0xFFFFFFFFFFFFFFFF # Expected: -1 (all bits differ)
    li  x11, 1
    li  x11, 0

## TEST: XOR_FLIP_BITS
    # Purpose: Flipping lower bits (value ^ 0xFF)
    li  x5, 0x123456789ABCDEF0
    li  x6, 0xFF
    xor x31, x5, x6
    li  x30, 0x123456789ABCDE0F # Expected: lower byte flipped
    li  x11, 1
    li  x11, 0
##--------------------------------------------
## Additional Logical Tests (Extreme Values/x0) - RV64
## Using x31 as result (rd)
## Using x5 as rs1, x6 as rs2
## Using x30 for Golden value
## Using x11 for Compare Signaling
##--------------------------------------------

## TEST: AND_MAXPOS_MINNEG
    # Purpose: Max Positive & Min Negative -> 0
    li  x5, 0x7FFFFFFFFFFFFFFF
    li  x6, 0x8000000000000000
    and x31, x5, x6
    li  x30, 0                 # Golden: 0111... & 1000... = 0
    li  x11, 1
    li  x11, 0

## TEST: AND_MINNEG_MINNEG
    # Purpose: Min Negative & Min Negative -> Min Negative
    li  x5, 0x8000000000000000
    li  x6, 0x8000000000000000
    and x31, x5, x6
    li  x30, 0x8000000000000000 # Golden: 1000... & 1000... = 1000...
    li  x11, 1
    li  x11, 0

## TEST: OR_MAXPOS_MINNEG
    # Purpose: Max Positive | Min Negative -> -1
    li  x5, 0x7FFFFFFFFFFFFFFF
    li  x6, 0x8000000000000000
    or  x31, x5, x6
    li  x30, -1                # Golden: 0111... | 1000... = 1111... (-1)
    li  x11, 1
    li  x11, 0

## TEST: OR_PATTERN_MINNEG
    # Purpose: Pattern | Min Negative
    li  x5, 0xAAAAAAAAAAAAAAAA # 1010...
    li  x6, 0x8000000000000000 # 1000...
    or  x31, x5, x6             # 1010... | 1000... -> 1010... = 0xA...A
    li  x30, 0xAAAAAAAAAAAAAAAA
    li  x11, 1
    li  x11, 0

## TEST: XOR_MAXPOS_MINNEG
    # Purpose: Max Positive ^ Min Negative -> -1
    li  x5, 0x7FFFFFFFFFFFFFFF
    li  x6, 0x8000000000000000
    xor x31, x5, x6
    li  x30, -1                # Golden: 0111... ^ 1000... = 1111... (-1)
    li  x11, 1
    li  x11, 0

## TEST: XOR_PATTERN_MAXPOS
    # Purpose: Pattern ^ Max Positive
    li  x5, 0xAAAAAAAAAAAAAAAA # 10101010...
    li  x6, 0x7FFFFFFFFFFFFFFF # 01111111...
    xor x31, x5, x6             # 1010^0111=1101(D), 0101^1111=1010(A) -> DADADADA...
    li  x30, 0xD555555555555555
    li  x11, 1
    li  x11, 0

## TEST: XOR_PATTERN_MINNEG
    # Purpose: Pattern ^ Min Negative
    li  x5, 0xAAAAAAAAAAAAAAAA # 10100101...
    li  x6, 0x8000000000000000 # 10000000...
    xor x31, x5, x6             # 1010^1000=0010(2), 0101^0000=0101(5) -> 25252525...
    li  x30, 0x2AAAAAAAAAAAAAAA
    li  x11, 1
    li  x11, 0

## TEST: AND_WRITE_X0
    # Purpose: Test writing to x0 using AND (should have no effect)
    li  x5, 0xAAAAAAAAAAAAAAA A
    li  x6, 0x5555555555555555
    and x0, x5, x6             # Attempt write to x0 (result would be 0 anyway)
    addi x31, x0, 0            # Copy x0 to x31 (using addi instead of mv)
    li  x30, 0                 # Golden value should still be 0
    li  x11, 1
    li  x11, 0

## TEST: OR_WRITE_X0
    # Purpose: Test writing to x0 using OR (should have no effect)
    li  x5, 0xAAAAAAAAAAAAAAA A
    li  x6, 0x5555555555555555
    or  x0, x5, x6             # Attempt write to x0 (result would be -1)
    addi x31, x0, 0            # Copy x0 to x31
    li  x30, 0                 # Golden value should still be 0
    li  x11, 1
    li  x11, 0

## TEST: XOR_WRITE_X0
    # Purpose: Test writing to x0 using XOR (should have no effect)
    li  x5, 0x123456789ABCDEF0
    li  x6, 0x123456789ABCDEF0
    xor x0, x5, x6             # Attempt write to x0 (result is 0 anyway)
    addi x31, x0, 0            # Copy x0 to x31
    li  x30, 0                 # Golden value should still be 0
    li  x11, 1
    li  x11, 0

##--------------------------------------------
## End of Logical Tests
##--------------------------------------------
