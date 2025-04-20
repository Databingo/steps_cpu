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
## End of Logical Tests
##--------------------------------------------
