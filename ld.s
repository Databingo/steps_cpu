_start:
    # Initialize base address register x5 to 0.
    # Assumes the data from 'data_test.txt' is loaded into memory starting at address 0.
    li x5, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.

##--------------------------------------------
## LD (Load Doubleword) Tests - RV64
## Using x31 as result/test value
## Using x30 to load Golden value
## Using x11 for Compare Signaling
## Using x5 as base address register (rs1), assumes base address = 0
## REQUIRES data memory pre-loaded from 'data_test.txt' at address 0.
## --- Ensure Verilog 'ld' implementation correctly sign-extends the offset ---
##--------------------------------------------

# -- LD Tests (No extension needed for RV64) --
## TEST: LD_POS
    # Purpose: Load positive doubleword (at Addr 16 = 0x10)
    # Data @010: 88 77 66 55, @014: 44 33 22 11 -> 0x1122334455667788
    ld  x31, 16(x5)           # Load double: x31 = MEM[0 + 16]
    li  x30, 0x1122334455667788 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LD_PATTERN
    # Purpose: Load pattern doubleword (at Addr 24 = 0x18)
    # Data @018: 11 00 FF EE, @01C: DD CC BB AA -> 0xAABBCCDDEEFF0011
    ld  x31, 24(x5)           # Load double: x31 = MEM[0 + 24]
    li  x30, 0xAABBCCDDEEFF0011 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LD_NEG_ONE
    # Purpose: Load negative one doubleword (at Addr 32 = 0x20)
    # Data @020: FF FF FF FF, @024: FF FF FF FF -> 0xFFFFFFFFFFFFFFFF
    ld  x31, 32(x5)           # Load double: x31 = MEM[0 + 32]
    li  x30, 0xFFFFFFFFFFFFFFFF # Golden value (-1)
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LD_MAX_POS
    # Purpose: Load max positive doubleword (at Addr 40 = 0x28)
    # Data @028: FF FF FF FF, @02C: FF FF FF 7F -> 0x7FFFFFFFFFFFFFFF
    ld  x31, 40(x5)           # Load double: x31 = MEM[0 + 40]
    li  x30, 0x7FFFFFFFFFFFFFFF # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LD_MIN_NEG
    # Purpose: Load min negative doubleword (at Addr 48 = 0x30)
    # Data @030: 00 00 00 00, @034: 00 00 00 80 -> 0x8000000000000000
    ld  x31, 48(x5)           # Load double: x31 = MEM[0 + 48]
    li  x30, 0x8000000000000000 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LD_ZERO
    # Purpose: Load zero doubleword (at Addr 56 = 0x38)
    # Data @038: 00 00 00 00, @03C: 00 00 00 00 -> 0x0000000000000000
    ld  x31, 56(x5)           # Load double: x31 = MEM[0 + 56]
    li  x30, 0x0000000000000000 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

# -- Offset Test --
## TEST: LD_NEGATIVE_OFFSET
    # Purpose: Load double 0x11...88 (Addr 16) using base x5=24 and offset -8.
    # THIS TEST REQUIRES VERILOG 'ld' TO SIGN-EXTEND THE OFFSET -8 CORRECTLY
    li  x5, 24                # Set base register temporarily
    ld  x31, -8(x5)           # Load double: x31 = MEM[24 + (-8)] = MEM[16]
    li  x30, 0x1122334455667788 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal
    li  x5, 0                 # Restore base register x5 to 0


##--------------------------------------------
## End of LD Tests
##--------------------------------------------
