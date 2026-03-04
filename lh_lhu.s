_start:
    # Initialize base address register x5 to 0.
    # Assumes the data from 'data_test.txt' is loaded into memory starting at address 0.
    li x5, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.

##--------------------------------------------
## LH/LHU (Load Halfword / Unsigned) Tests - RV64
## Using x31 as result/test value
## Using x30 to load Golden value
## Using x11 for Compare Signaling
## Using x5 as base address register (rs1), assumes base address = 0
## REQUIRES data memory pre-loaded from 'data_test.txt' at address 0.
##--------------------------------------------

# -- LH Tests (Sign Extended) --
## TEST: LH_POS
    # Purpose: Load positive halfword (0x1234 at Decimal Addr 4), check sign extension.
    # Data @004 (hex): 34 12 00 80
    lh  x31, 4(x5)            # Load half: x31 = MEM[0 + 4] sign-extended
    li  x30, 0x0000000000001234 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LH_NEG
    # Purpose: Load negative halfword (0x8000 at Decimal Addr 6 = -32768), check sign extension.
    # Data @004 (hex): 34 12 00 80
    lh  x31, 6(x5)            # Load half: x31 = MEM[0 + 6] sign-extended
    li  x30, 0xFFFFFFFFFFFF8000 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LH_NEG_ONE
    # Purpose: Load negative one halfword (0xFFFF at Decimal Addr 72 = 0x48), check sign extension.
    # Data @048 (hex): FF FF FF 7F
    lh  x31, 72(x5)           # Load half: x31 = MEM[0 + 72] sign-extended <-- CORRECTED OFFSET
    li  x30, 0xFFFFFFFFFFFFFFFF # Golden value (-1)
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LH_MAX_POS
    # Purpose: Load max positive halfword (0x7FFF at Decimal Addr 74 = 0x4A), check sign extension.
    # Data @048 (hex): FF FF FF 7F  (Bytes at 74,75 are FF 7F -> 0x7FFF Little Endian)
    lh  x31, 74(x5)           # Load half: x31 = MEM[0 + 74] sign-extended <-- CORRECTED OFFSET
    li  x30, 0x0000000000007FFF # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

# -- LHU Tests (Zero Extended) --
## TEST: LHU_POS
    # Purpose: Load positive halfword (0x1234 at Decimal Addr 4), check zero extension.
    # Data @004 (hex): 34 12 00 80
    lhu x31, 4(x5)            # Load half: x31 = MEM[0 + 4] zero-extended
    li  x30, 0x0000000000001234 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LHU_NEG_PATTERN
    # Purpose: Load halfword with MSB set (0x8000 at Decimal Addr 6), check zero extension.
    # Data @004 (hex): 34 12 00 80
    lhu x31, 6(x5)            # Load half: x31 = MEM[0 + 6] zero-extended
    li  x30, 0x0000000000008000 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LHU_NEG_ONE_PATTERN
    # Purpose: Load halfword pattern 0xFFFF at Decimal Addr 72 = 0x48, check zero extension.
    # Data @048 (hex): FF FF FF 7F
    lhu x31, 72(x5)           # Load half: x31 = MEM[0 + 72] zero-extended <-- CORRECTED OFFSET
    li  x30, 0x000000000000FFFF # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LHU_MAX_POS
    # Purpose: Load max positive halfword (0x7FFF at Decimal Addr 74 = 0x4A), check zero extension.
    # Data @048 (hex): FF FF FF 7F (Bytes at 74,75 are FF 7F -> 0x7FFF Little Endian)
    lhu x31, 74(x5)           # Load half: x31 = MEM[0 + 74] zero-extended <-- CORRECTED OFFSET
    li  x30, 0x0000000000007FFF # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

# -- Offset Test --
## TEST: LH_NEGATIVE_OFFSET
    # Purpose: Load half 0x1234 (Decimal Addr 4) using base x5=6 and offset -2. Check sign extension.
    li  x5, 6                 # Set base register temporarily
    lh  x31, -2(x5)           # Load half: x31 = MEM[6 + (-2)] = MEM[4]
    li  x30, 0x0000000000001234 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal
    li  x5, 0                 # Restore base register x5 to 0


##--------------------------------------------
## End of LH/LHU Tests
##--------------------------------------------
