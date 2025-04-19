
_start:
    # Initialize base address register x5 to 0.
    # Assumes the data from 'data_test.txt' is loaded into memory starting at address 0.
    li x5, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.

##--------------------------------------------
## LW/LWU (Load Word / Unsigned) Tests - RV64
## Using x31 as result/test value
## Using x30 to load Golden value
## Using x11 for Compare Signaling
## Using x5 as base address register (rs1), assumes base address = 0
## REQUIRES data memory pre-loaded from 'data_test.txt' at address 0.
##--------------------------------------------

# -- LW Tests (Sign Extended) --
## TEST: LW_POS
    # Purpose: Load positive word (0x12345678 at Addr 8), check sign extension.
    # Data @008: 78 56 34 12
    lw  x31, 8(x5)            # Load word: x31 = MEM[0 + 8] sign-extended
    li  x30, 0x0000000012345678 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LW_NEG
    # Purpose: Load negative word (0x80000000 at Addr 12 = -2^31), check sign extension.
    # Data @00C: 00 00 00 80
    lw  x31, 12(x5)           # Load word: x31 = MEM[0 + 12] sign-extended
    li  x30, 0xFFFFFFFF80000000 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LW_NEG_ONE
    # Purpose: Load negative one word (0xFFFFFFFF at Addr 0x28 = 40), check sign extension.
    # Data @040: FF FF FF FF
    lw  x31, 40(x5)           # Load word: x31 = MEM[0 + 40] sign-extended
    li  x30, 0xFFFFFFFFFFFFFFFF # Golden value (-1)
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LW_MAX_POS
    # Purpose: Load max positive word (0x7FFFFFFF at Addr 0x2C = 44), check sign extension.
    # Data @044: FF FF FF 7F
    lw  x31, 44(x5)           # Load word: x31 = MEM[0 + 44] sign-extended
    li  x30, 0x000000007FFFFFFF # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

# -- LWU Tests (Zero Extended) --
## TEST: LWU_POS
    # Purpose: Load positive word (0x12345678 at Addr 8), check zero extension.
    # Data @008: 78 56 34 12
    lwu x31, 8(x5)            # Load word: x31 = MEM[0 + 8] zero-extended
    li  x30, 0x0000000012345678 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LWU_NEG_PATTERN
    # Purpose: Load word with MSB set (0x80000000 at Addr 12), check zero extension.
    # Data @00C: 00 00 00 80
    lwu x31, 12(x5)           # Load word: x31 = MEM[0 + 12] zero-extended
    li  x30, 0x0000000080000000 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LWU_NEG_ONE_PATTERN
    # Purpose: Load word pattern 0xFFFFFFFF at Addr 0x28 (40), check zero extension.
    # Data @040: FF FF FF FF
    lwu x31, 40(x5)           # Load word: x31 = MEM[0 + 40] zero-extended
    li  x30, 0x00000000FFFFFFFF # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LWU_MAX_POS
    # Purpose: Load max positive word (0x7FFFFFFF at Addr 0x2C = 44), check zero extension.
    # Data @044: FF FF FF 7F
    lwu x31, 44(x5)           # Load word: x31 = MEM[0 + 44] zero-extended
    li  x30, 0x000000007FFFFFFF # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

# -- Offset Test --
## TEST: LW_NEGATIVE_OFFSET
    # Purpose: Load word 0x12345678 (Addr 8) using base x5=12 and offset -4. Check sign extension.
    li  x5, 12                # Set base register temporarily
    lw  x31, -4(x5)           # Load word: x31 = MEM[12 + (-4)] = MEM[8]
    li  x30, 0x0000000012345678 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal
    li  x5, 0                 # Restore base register x5 to 0


