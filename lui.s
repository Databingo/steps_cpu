##--------------------------------------------
## LUI (Load Upper Immediate) Tests - RV64
## Using x31 as result/test value
## Using x30 to load Golden value
## Using x11 for Compare Signaling
##--------------------------------------------

## TEST: LUI_ZERO
    # Purpose: Test LUI with zero immediate. imm=0
    # Loads 0x0 into bits 31:12, zero extends, clears lower 12 bits.
    lui x31, 0                  # Instruction under test: x31 = 0x0000000000000000
    li  x30, 0x0000000000000000  # Golden value
    li  x11, 1                  # Signal Compare (External harness should check x31 == x30)
    li  x11, 0                  # Clear Signal

## TEST: LUI_SMALL_POS
    # Purpose: Test LUI with small positive immediate. imm=1
    # Loads 0x1 into bits 31:12, zero extends, clears lower 12 bits.
    lui x31, 0x1                # Instruction under test: x31 = 0x0000000000001000
    li  x30, 0x0000000000001000  # Golden value
    li  x11, 1                  # Signal Compare
    li  x11, 0                  # Clear Signal

## TEST: LUI_PATTERN_POS
    # Purpose: Test LUI with a positive pattern. imm=0x12345
    # Loads 0x12345 into bits 31:12, zero extends, clears lower 12 bits.
    lui x31, 0x12345            # Instruction under test: x31 = 0x0000000012345000
    li  x30, 0x0000000012345000  # Golden value
    li  x11, 1                  # Signal Compare
    li  x11, 0                  # Clear Signal

## TEST: LUI_MAX_POS
    # Purpose: Test LUI with max positive immediate (bit 19 = 0). imm=0x7FFFF
    # Loads 0x7FFFF into bits 31:12, zero extends, clears lower 12 bits.
    lui x31, 0x7FFFF            # Instruction under test: x31 = 0x000000007FFFF000
    li  x30, 0x000000007FFFF000  # Golden value
    li  x11, 1                  # Signal Compare
    li  x11, 0                  # Clear Signal

## TEST: LUI_MIN_NEG
    # Purpose: Test LUI with min immediate where sign bit is set (bit 19 = 1). imm=0x80000
    # Loads 0x80000 into bits 31:12, SIGN extends, clears lower 12 bits.
    lui x31, 0x80000            # Instruction under test: x31 = 0xFFFFFFFF80000000
    li  x30, 0xFFFFFFFF80000000  # Golden value
    li  x11, 1                  # Signal Compare
    li  x11, 0                  # Clear Signal

## TEST: LUI_PATTERN_NEG_1
    # Purpose: Test LUI with a negative pattern. imm=0xABCDE
    # Loads 0xABCDE into bits 31:12, SIGN extends, clears lower 12 bits.
    lui x31, 0xABCDE            # Instruction under test: x31 = 0xFFFFFFFFABCDE000
    li  x30, 0xFFFFFFFFABCDE000  # Golden value
    li  x11, 1                  # Signal Compare
    li  x11, 0                  # Clear Signal

## TEST: LUI_PATTERN_NEG_2
    # Purpose: Test LUI with another negative pattern. imm=0xC0001
    # Loads 0xC0001 into bits 31:12, SIGN extends, clears lower 12 bits.
    lui x31, 0xC0001            # Instruction under test: x31 = 0xFFFFFFFFC0001000
    li  x30, 0xFFFFFFFFC0001000  # Golden value
    li  x11, 1                  # Signal Compare
    li  x11, 0                  # Clear Signal

## TEST: LUI_MAX_IMM
    # Purpose: Test LUI with max immediate (all 1s). imm=0xFFFFF
    # Loads 0xFFFFF into bits 31:12, SIGN extends, clears lower 12 bits.
    lui x31, 0xFFFFF            # Instruction under test: x31 = 0xFFFFFFFFFFFFF000
    li  x30, 0xFFFFFFFFFFFFF000  # Golden value
    li  x11, 1                  # Signal Compare
    li  x11, 0                  # Clear Signal


##--------------------------------------------
## End of LUI Tests
##--------------------------------------------
