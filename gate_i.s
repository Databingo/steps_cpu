_start:
    # Initialize register (optional, assuming reset state is 0)
    li x5, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.
    # Current time: Saturday, April 19, 2025 at 8:25 PM PDT

##--------------------------------------------
## Logical Immediate ANDI/ORI/XORI Tests - RV64
## Using x31 as result (rd)
## Using x5 as rs1
## Using x30 for Golden value
## Using x11 for Compare Signaling
## Immediate is Sign-Extended from 12 bits before operation
##--------------------------------------------

# -- ANDI Tests (rd = rs1 & sign_extend(imm12)) --
## TEST: ANDI_ZERO_IMM
    # Purpose: x & 0 = 0
    li  x5, 0x123456789ABCDEF0
    andi x31, x5, 0            # Immediate 0 sign extends to 0
    li  x30, 0
    li  x11, 1
    li  x11, 0

## TEST: ANDI_ZERO_REG
    # Purpose: 0 & imm = 0
    li  x5, 0
    andi x31, x5, 0x5A5        # Immediate 0x5A5 sign extends to 0x5A5
    li  x30, 0
    li  x11, 1
    li  x11, 0

## TEST: ANDI_ALL_ONES_IMM
    # Purpose: x & -1 = x
    li  x5, 0x1234ABCD4321EF01
    andi x31, x5, -1           # Immediate -1 (0xFFF) sign extends to 0xFF...FF
    li  x30, 0x1234ABCD4321EF01 # Expected: x
    li  x11, 1
    li  x11, 0

## TEST: ANDI_MASK_POSITIVE
    # Purpose: Masking with a positive immediate
    li  x5, 0xFFFFFFFFFFFFFFAA
    andi x31, x5, 0x0FF        # Immediate 0x0FF sign extends to 0x0FF
    li  x30, 0xAA              # Expected: x5 & 0x0FF
    li  x11, 1
    li  x11, 0

## TEST: ANDI_MASK_NEGATIVE
    # Purpose: Masking with a negative immediate (min neg imm)
    li  x5,  0x123456789ABCDEF0
    andi x31, x5, -2048        # Immediate -2048 (0x800) sign extends to 0xFF...F800
    li  x30, 0x123456789ABCD800 # Expected: x5 & 0xFF...F800
    li  x11, 1
    li  x11, 0

## TEST: ANDI_MAX_IMM
    # Purpose: x & 2047
    li  x5, 0xFFFFFFFFFFFFFFFF
    andi x31, x5, 2047         # Immediate 2047 (0x7FF) sign extends to 0x7FF
    li  x30, 0x7FF             # Expected: -1 & 0x7FF
    li  x11, 1
    li  x11, 0

# -- ORI Tests (rd = rs1 | sign_extend(imm12)) --
## TEST: ORI_ZERO_IMM
    # Purpose: x | 0 = x
    li  x5, 0x123456789ABCDEF0
    ori x31, x5, 0             # Immediate 0 sign extends to 0
    li  x30, 0x123456789ABCDEF0 # Expected: x
    li  x11, 1
    li  x11, 0

## TEST: ORI_ZERO_REG
    # Purpose: 0 | imm = sign_extend(imm)
    li  x5, 0
    ori x31, x5, 0x5A5         # Immediate 0x5A5 sign extends to 0x5A5
    li  x30, 0x5A5             # Expected: 0 | 0x5A5
    li  x11, 1
    li  x11, 0

## TEST: ORI_ALL_ONES_IMM
    # Purpose: x | -1 = -1
    li  x5, 0x1234ABCD4321EF01
    ori x31, x5, -1            # Immediate -1 (0xFFF) sign extends to 0xFF...FF
    li  x30, -1                # Expected: x | -1 = -1
    li  x11, 1
    li  x11, 0

## TEST: ORI_SET_BITS_POSITIVE
    # Purpose: Setting bits with a positive immediate
    li  x5, 0xF0F0F0F0F0F0F000
    ori x31, x5, 0x0F0         # Immediate 0x0F0 sign extends to 0x0F0
    li  x30, 0xF0F0F0F0F0F0F0F0 # Expected: LSBs unchanged, next nibble set
    li  x11, 1
    li  x11, 0

## TEST: ORI_SET_BITS_NEGATIVE
    # Purpose: Setting bits with a negative immediate
    li  x5, 0x00000000000000AA
    ori x31, x5, -2048         # Immediate -2048 (0x800) sign extends to 0xFF...F800
    li  x30, 0xFFFFFFFFFFFFF8AA # Expected: 0xAA | 0xFF...F800
    li  x11, 1
    li  x11, 0

## TEST: ORI_MAX_IMM
    # Purpose: x | 2047
    li  x5, 0xF0F0F0F0F0F0F0F0
    ori x31, x5, 2047          # Immediate 2047 (0x7FF) sign extends to 0x7FF
    li  x30, 0xF0F0F0F0F0F0F7FF # Expected: x | 0x7FF
    li  x11, 1
    li  x11, 0

# -- XORI Tests (rd = rs1 ^ sign_extend(imm12)) --
## TEST: XORI_ZERO_IMM
    # Purpose: x ^ 0 = x
    li  x5, 0x123456789ABCDEF0
    xori x31, x5, 0            # Immediate 0 sign extends to 0
    li  x30, 0x123456789ABCDEF0 # Expected: x
    li  x11, 1
    li  x11, 0

## TEST: XORI_ZERO_REG
    # Purpose: 0 ^ imm = sign_extend(imm)
    li  x5, 0
    xori x31, x5, 0x5A5        # Immediate 0x5A5 sign extends to 0x5A5
    li  x30, 0x5A5             # Expected: 0 ^ 0x5A5
    li  x11, 1
    li  x11, 0

## TEST: XORI_ALL_ONES_IMM (NOT)
    # Purpose: x ^ -1 = ~x
    li  x5, 0x123456789ABCDEF0
    xori x31, x5, -1           # Immediate -1 (0xFFF) sign extends to 0xFF...FF
    li  x30, 0xEDCBA9876543210F # Expected: ~x
    li  x11, 1
    li  x11, 0

## TEST: XORI_IDENTICAL
    # Purpose: Test x ^ sign_extend(x_low12) (where x_low12 has sign bit 0)
    li  x5, 0xABCDEF0123456789
    xori x31, x5, 0x789        # Immediate 0x789 sign extends to 0x789
    li  x30, 0xABCDEF0123456000 # Expected: lower 12 bits cleared
    li  x11, 1
    li  x11, 0

## TEST: XORI_FLIP_BITS_POSITIVE
    # Purpose: Flipping bits with a positive immediate mask
    li  x5, 0xF0F0F0F0F0F0F0F0
    xori x31, x5, 0x0F0        # Immediate 0x0F0 sign extends to 0x0F0
    li  x30, 0xF0F0F0F0F0F0F000 # Expected: low bits flipped
    li  x11, 1
    li  x11, 0

## TEST: XORI_FLIP_BITS_NEGATIVE
    # Purpose: Flipping bits with a negative immediate mask
    li  x5, 0x00000000000000AA
    xori x31, x5, -1           # Immediate -1 (0xFFF) sign extends to 0xFF...FF
    li  x30, 0xFFFFFFFFFFFFFF55 # Expected: ~0xAA
    li  x11, 1
    li  x11, 0

## TEST: XORI_MIN_IMM
    # Purpose: x ^ -2048
    li  x5, 0xAAAAAAAAAAAAAAAA
    xori x31, x5, -2048        # Immediate -2048 (0x800) sign extends to 0xFF...F800
    li  x30, 0x55555555555552AA # Expected: x ^ 0xFF...F800
    li  x11, 1
    li  x11, 0

##--------------------------------------------
## End of Logical Immediate Tests
##--------------------------------------------
