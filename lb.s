_start:
    # Initialize base address register x5 to 0.
    # Assumes the data from 'data_test.txt' is loaded into memory starting at address 0.
    li x5, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.

##--------------------------------------------
## LB (Load Byte) Specific Tests - RV64
## Using x31 as result/test value
## Using x30 to load Golden value
## Using x11 for Compare Signaling
## Using x5 as base address register (rs1), assumes base address = 0
## REQUIRES data memory pre-loaded from 'data_test.txt' at address 0.
##--------------------------------------------

## TEST: LB_MAX_POS_BYTE
    # Purpose: Load max positive byte (0x7F at Addr 0), check sign extension.
    # Data @000: 7F ...
    lb  x31, 0(x5)            # Load byte: x31 = MEM[0 + 0] sign-extended
    li  x30, 0x000000000000007F # Golden value (0x7F sign-extended is still 0x7F)
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LB_MIN_NEG_BYTE
    # Purpose: Load min negative byte (0x80 at Addr 1 = -128), check sign extension.
    # Data @000: 7F 80 ...
    lb  x31, 1(x5)            # Load byte: x31 = MEM[0 + 1] sign-extended
    li  x30, 0xFFFFFFFFFFFFFF80 # Golden value (0x80 sign-extended)
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LB_NEG_ONE_BYTE
    # Purpose: Load negative one byte (0xFF at Addr 2 = -1), check sign extension.
    # Data @000: 7F 80 FF ...
    lb  x31, 2(x5)            # Load byte: x31 = MEM[0 + 2] sign-extended
    li  x30, 0xFFFFFFFFFFFFFFFF # Golden value (-1)
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LB_ZERO_BYTE
    # Purpose: Load zero byte (0x00 at Addr 3).
    # Data @000: 7F 80 FF 00
    lb  x31, 3(x5)            # Load byte: x31 = MEM[0 + 3] sign-extended
    li  x30, 0x0000000000000000 # Golden value (0)
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LB_PATTERN_55
    # Purpose: Load pattern byte 0x55 from Addr 0x4C (76). Check sign extension.
    # Data @04C: 55 AA 00 00
    lb  x31, 76(x5)           # Load byte: x31 = MEM[0 + 76] sign-extended
    li  x30, 0x0000000000000055 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LB_PATTERN_AA
    # Purpose: Load pattern byte 0xAA from Addr 0x4D (77). Check sign extension.
    # Data @04C: 55 AA 00 00
    lb  x31, 77(x5)           # Load byte: x31 = MEM[0 + 77] sign-extended
    li  x30, 0xFFFFFFFFFFFFFFAA # Golden value (0xAA sign-extended)
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LB_FROM_HALFWORD_LSB
    # Purpose: Load LSB (0x34) from halfword 0x1234 at Addr 4. Check sign extension.
    # Data @004: 34 12 00 80
    lb  x31, 4(x5)            # Load byte: x31 = MEM[0 + 4] sign-extended
    li  x30, 0x0000000000000034 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LB_FROM_HALFWORD_MSB
    # Purpose: Load MSB (0x12) from halfword 0x1234 at Addr 5. Check sign extension.
    # Data @004: 34 12 00 80
    lb  x31, 5(x5)            # Load byte: x31 = MEM[0 + 5] sign-extended
    li  x30, 0x0000000000000012 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LB_FROM_WORD_LSB
    # Purpose: Load LSB (0x78) from word 0x12345678 at Addr 8. Check sign extension.
    # Data @008: 78 56 34 12
    lb  x31, 8(x5)            # Load byte: x31 = MEM[0 + 8] sign-extended
    li  x30, 0x0000000000000078 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LB_FROM_WORD_BYTE2
    # Purpose: Load byte 2 (0x56) from word 0x12345678 at Addr 9. Check sign extension.
    # Data @008: 78 56 34 12
    lb  x31, 9(x5)            # Load byte: x31 = MEM[0 + 9] sign-extended
    li  x30, 0x0000000000000056 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LB_FROM_DOUBLE_LSB
    # Purpose: Load LSB (0x88) from double 0x11...88 at Addr 16 (0x10). Check sign extension.
    # Data @010: 88 77 66 55
    lb  x31, 16(x5)           # Load byte: x31 = MEM[0 + 16] sign-extended
    li  x30, 0xFFFFFFFFFFFFFF88 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LB_FROM_DOUBLE_MSB
    # Purpose: Load MSB (0x11) from double 0x11...88 at Addr 23 (0x17). Check sign extension.
    # Data @014: 44 33 22 11
    lb  x31, 23(x5)           # Load byte: x31 = MEM[0 + 23] sign-extended
    li  x30, 0x0000000000000011 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LB_NEGATIVE_OFFSET
    # Purpose: Load byte 0xFF (Addr 2) using base x5=3 and offset -1. Check sign extension.
    li  x5, 3                 # Set base register to 3 Temporarily
    lb  x31, -1(x5)           # Load byte: x31 = MEM[3 + (-1)] = MEM[2]
    li  x30, 0xFFFFFFFFFFFFFFFF # Golden value (-1)
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal
    li  x5, 0                 # Restore base register x5 to 0


##--------------------------------------------
## End of LB Tests
##--------------------------------------------

