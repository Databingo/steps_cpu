#// t0,t1,t2(x5,x6,x7) was used in li
_start:
    # Initialize base address register x8 to 0.
    # Assumes the data from 'data_lb.txt' is loaded into memory starting at address 0.
    li x8, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.

## TEST: LB_NEG_ALT
    # Purpose: Load negative byte (0xFF at Addr 2 = -1), check sign extension
    lb  x31, 2(x8)            # Load byte: x31 = MEM[0 + 2] sign-extended
    li  x30, 0xFFFFFFFFFFFFFFFF # Golden value (-1)
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

##--------------------------------------------
## LB (Load Byte) Only Tests - RV64
## Using x31 as result/test value
## Using x30 to load Golden value
## Using x11 for Compare Signaling
## Using x8 as base address register (rs1), assumes base address = 0
## REQUIRES data memory pre-loaded from 'data_lb.txt' at address 0.
##--------------------------------------------

## TEST: LB_POS
    # Purpose: Load positive byte (0x7F at Addr 0), check sign extension (should be 0x7F)
    lb  x31, 0(x8)            # Load byte: x31 = MEM[0 + 0] sign-extended
    li  x30, 0x000000000000007F # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LB_NEG
    # Purpose: Load negative byte (0x80 at Addr 1 = -128), check sign extension
    lb  x31, 1(x8)            # Load byte: x31 = MEM[0 + 1] sign-extended
    li  x30, 0xFFFFFFFFFFFFFF80 # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LB_NEG_ALT
    # Purpose: Load negative byte (0xFF at Addr 2 = -1), check sign extension
    lb  x31, 2(x8)            # Load byte: x31 = MEM[0 + 2] sign-extended
    li  x30, 0xFFFFFFFFFFFFFFFF # Golden value (-1)
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LB_ZERO
    # Purpose: Load zero byte (0x00 at Addr 3)
    lb  x31, 3(x8)            # Load byte: x31 = MEM[0 + 3] sign-extended
    li  x30, 0x0000000000000000 # Golden value (0)
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

## TEST: LB_OFFSET_POS
    # Purpose: Load byte 0xBB from Addr 33 (offset 33)
    lb  x31, 33(x8)           # x31 = MEM[0 + 33] = 0xBB (sign extends to 0xFF..FFBB)
    li  x30, 0xFFFFFFFFFFFFFFBB # Golden value
    li  x11, 1                 # Signal Compare
    li  x11, 0                 # Clear Signal

##--------------------------------------------
## End of LB Tests
##--------------------------------------------
