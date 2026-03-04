_start:
    # Initialize base address register x5 to 0.
    # Assumes the data from 'data_test.txt' is loaded into memory starting at address 0.
    li x5, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.

##--------------------------------------------
## Store Instructions Tests - RV64
## Using x6 as source value (rs2)
## Using x31 as load-back result value (rd)
## Using x30 to load Golden value
## Using x11 for Compare Signaling
## Using x5 as base address register (rs1), assumes base address = 0
## Stores target memory area starting at offset 80 (0x50)
## REQUIRES data memory pre-loaded from 'data_test.txt' at address 0.
##--------------------------------------------

# -- SB Tests --
## TEST: SB_ZERO
    # Purpose: Store zero byte, load back signed/unsigned.
    li  x6, 0                 # Value to store (0x00)
    sb  x6, 80(x5)            # Store byte to Addr 80 (0x50)
    lb  x31, 80(x5)           # Load back signed
    li  x30, 0                 # Expected result
    li  x11, 1                 # Signal Compare 1
    li  x11, 0                 # Clear Signal
    lbu x31, 80(x5)           # Load back unsigned
    li  x30, 0                 # Expected result
    li  x11, 1                 # Signal Compare 2
    li  x11, 0                 # Clear Signal

## TEST: SB_POSITIVE
    # Purpose: Store positive byte (0x5A), load back signed/unsigned.
    li  x6, 0x5A              # Value to store
    sb  x6, 81(x5)            # Store byte to Addr 81 (0x51)
    lb  x31, 81(x5)           # Load back signed
    li  x30, 0x5A              # Expected result (sign extended = zero extended)
    li  x11, 1                 # Signal Compare 1
    li  x11, 0                 # Clear Signal
    lbu x31, 81(x5)           # Load back unsigned
    li  x30, 0x5A              # Expected result
    li  x11, 1                 # Signal Compare 2
    li  x11, 0                 # Clear Signal

## TEST: SB_NEGATIVE
    # Purpose: Store negative byte pattern (0xC3), load back signed/unsigned.
    li  x6, 0xFFFFFFFFFFFFC3 # Load -61 (ends in C3)
    sb  x6, 82(x5)            # Store byte (0xC3) to Addr 82 (0x52)
    lb  x31, 82(x5)           # Load back signed
    li  x30, 0xFFFFFFFFFFFFFFC3 # Expected result (sign extended)
    li  x11, 1                 # Signal Compare 1
    li  x11, 0                 # Clear Signal
    lbu x31, 82(x5)           # Load back unsigned
    li  x30, 0xC3              # Expected result (zero extended)
    li  x11, 1                 # Signal Compare 2
    li  x11, 0                 # Clear Signal

## TEST: SB_NEG_ONE
    # Purpose: Store -1 byte (0xFF), load back signed/unsigned.
    li  x6, -1                # Value to store (0xFF..FF)
    sb  x6, 83(x5)            # Store byte (0xFF) to Addr 83 (0x53)
    lb  x31, 83(x5)           # Load back signed
    li  x30, -1                # Expected result (sign extended)
    li  x11, 1                 # Signal Compare 1
    li  x11, 0                 # Clear Signal
    lbu x31, 83(x5)           # Load back unsigned
    li  x30, 0xFF              # Expected result (zero extended)
    li  x11, 1                 # Signal Compare 2
    li  x11, 0                 # Clear Signal

# -- SH Tests --
## TEST: SH_ZERO
    # Purpose: Store zero halfword, load back signed/unsigned.
    li  x6, 0
    sh  x6, 84(x5)            # Store half to Addr 84 (0x54)
    lh  x31, 84(x5)           # Load back signed
    li  x30, 0
    li  x11, 1                 # Signal Compare 1
    li  x11, 0
    lhu x31, 84(x5)           # Load back unsigned
    li  x30, 0
    li  x11, 1                 # Signal Compare 2
    li  x11, 0

## TEST: SH_POSITIVE
    # Purpose: Store positive halfword (0x1234), load back signed/unsigned.
    li  x6, 0x1234
    sh  x6, 86(x5)            # Store half to Addr 86 (0x56)
    lh  x31, 86(x5)           # Load back signed
    li  x30, 0x1234
    li  x11, 1                 # Signal Compare 1
    li  x11, 0
    lhu x31, 86(x5)           # Load back unsigned
    li  x30, 0x1234
    li  x11, 1                 # Signal Compare 2
    li  x11, 0

## TEST: SH_NEGATIVE
    # Purpose: Store negative halfword pattern (0xABCD), load back signed/unsigned.
    li  x6, 0xFFFFFFFFFFFFABCD # Load value ending in ABCD
    sh  x6, 88(x5)            # Store half (0xABCD) to Addr 88 (0x58)
    lh  x31, 88(x5)           # Load back signed
    li  x30, 0xFFFFFFFFFFFFABCD # Expected result (sign extended)
    li  x11, 1                 # Signal Compare 1
    li  x11, 0
    lhu x31, 88(x5)           # Load back unsigned
    li  x30, 0xABCD            # Expected result (zero extended)
    li  x11, 1                 # Signal Compare 2
    li  x11, 0

## TEST: SH_NEG_ONE
    # Purpose: Store -1 halfword (0xFFFF), load back signed/unsigned.
    li  x6, -1
    sh  x6, 90(x5)            # Store half (0xFFFF) to Addr 90 (0x5A)
    lh  x31, 90(x5)           # Load back signed
    li  x30, -1
    li  x11, 1                 # Signal Compare 1
    li  x11, 0
    lhu x31, 90(x5)           # Load back unsigned
    li  x30, 0xFFFF
    li  x11, 1                 # Signal Compare 2
    li  x11, 0

# -- SW Tests --
## TEST: SW_ZERO
    # Purpose: Store zero word, load back signed/unsigned.
    li  x6, 0
    sw  x6, 92(x5)            # Store word to Addr 92 (0x5C)
    lw  x31, 92(x5)           # Load back signed
    li  x30, 0
    li  x11, 1                 # Signal Compare 1
    li  x11, 0
    lwu x31, 92(x5)           # Load back unsigned
    li  x30, 0
    li  x11, 1                 # Signal Compare 2
    li  x11, 0

## TEST: SW_POSITIVE
    # Purpose: Store positive word (0x12345678), load back signed/unsigned.
    li  x6, 0x12345678
    sw  x6, 96(x5)            # Store word to Addr 96 (0x60)
    lw  x31, 96(x5)           # Load back signed
    li  x30, 0x12345678
    li  x11, 1                 # Signal Compare 1
    li  x11, 0
    lwu x31, 96(x5)           # Load back unsigned
    li  x30, 0x12345678
    li  x11, 1                 # Signal Compare 2
    li  x11, 0

## TEST: SW_NEGATIVE
    # Purpose: Store negative word pattern (0xDEADBEEF), load back signed/unsigned.
    li  x6, 0xFFFFFFFFDEADBEEF # Load value ending in DEADBEEF
    sw  x6, 100(x5)           # Store word (0xDEADBEEF) to Addr 100 (0x64)
    lw  x31, 100(x5)          # Load back signed
    li  x30, 0xFFFFFFFFDEADBEEF # Expected result (sign extended)
    li  x11, 1                 # Signal Compare 1
    li  x11, 0
    lwu x31, 100(x5)          # Load back unsigned
    li  x30, 0xDEADBEEF        # Expected result (zero extended)
    li  x11, 1                 # Signal Compare 2
    li  x11, 0

## TEST: SW_NEG_ONE
    # Purpose: Store -1 word (0xFFFFFFFF), load back signed/unsigned.
    li  x6, -1
    sw  x6, 104(x5)           # Store word (0xFFFFFFFF) to Addr 104 (0x68)
    lw  x31, 104(x5)          # Load back signed
    li  x30, -1
    li  x11, 1                 # Signal Compare 1
    li  x11, 0
    lwu x31, 104(x5)          # Load back unsigned
    li  x30, 0xFFFFFFFF
    li  x11, 1                 # Signal Compare 2
    li  x11, 0

# -- SD Tests --
## TEST: SD_ZERO
    # Purpose: Store zero doubleword, load back.
    li  x6, 0
    sd  x6, 108(x5)           # Store double to Addr 108 (0x6C)
    ld  x31, 108(x5)          # Load back
    li  x30, 0
    li  x11, 1                 # Signal Compare
    li  x11, 0

## TEST: SD_POSITIVE
    # Purpose: Store positive doubleword (0x1122...7788), load back.
    li  x6, 0x1122334455667788
    sd  x6, 80(x5)            # Store double to Addr 80 (0x50) - Overwrite start of store area
    ld  x31, 80(x5)           # Load back
    li  x30, 0x1122334455667788
    li  x11, 1                 # Signal Compare
    li  x11, 0

## TEST: SD_NEGATIVE
    # Purpose: Store negative doubleword (0xAABB...0011), load back.
    li  x6, 0xAABBCCDDEEFF0011
    sd  x6, 88(x5)            # Store double to Addr 88 (0x58) - Overwrite more
    ld  x31, 88(x5)           # Load back
    li  x30, 0xAABBCCDDEEFF0011
    li  x11, 1                 # Signal Compare
    li  x11, 0

## TEST: SD_NEG_ONE
    # Purpose: Store -1 doubleword (0xFFFF..FF), load back.
    li  x6, -1
    sd  x6, 96(x5)            # Store double to Addr 96 (0x60) - Overwrite more
    ld  x31, 96(x5)           # Load back
    li  x30, -1
    li  x11, 1                 # Signal Compare
    li  x11, 0

# -- Offset Test --
## TEST: SW_NEGATIVE_OFFSET
    # Purpose: Store word 0xCAFEBABE using base=100, offset=-4 (Addr 96)
    li  x6, 0xCAFEBABE
    li  x5, 100               # Temp base
    sw  x6, -4(x5)            # Store word to MEM[100 - 4] = MEM[96]
    li  x5, 0                 # Restore base
    lwu x31, 96(x5)           # Load back verification (unsigned)
    li  x30, 0xCAFEBABE        # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0

##--------------------------------------------
## End of Store Tests
##--------------------------------------------
