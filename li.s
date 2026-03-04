##--------------------------------------------
## li (Load Immediate) Tests - RV64
## Using x31 as result/test value
## Using x30 to load Golden value
## Using x11 for Compare Signaling
##--------------------------------------------

## TEST: LI_ZERO
    # Purpose: Test loading zero.
    li x31, 0               # Value under test -> x31
    li x30, 0               # Golden value -> x30
    li x11, 1               # Signal Compare (External harness should check x31 == x30)
    li x11, 0               # Clear Signal

## TEST: LI_SMALL_POS_1 (Fits in ADDI imm)
    # Purpose: Test loading a small positive value.
    li x31, 1               # Value under test -> x31
    li x30, 1               # Golden value -> x30
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal

## TEST: LI_SMALL_POS_1000 (Fits in ADDI imm)
    # Purpose: Test loading a larger small positive value.
    li x31, 1000            # Value under test -> x31
    li x30, 1000            # Golden value -> x30
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal

## TEST: LI_SMALL_POS_ADDI_MAX (Upper limit of ADDI imm)
    # Purpose: Test the positive boundary of ADDI immediate field.
    li x31, 2047            # Value under test (0x7FF) -> x31
    li x30, 0x7FF           # Golden value -> x30
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal

## TEST: LI_SMALL_NEG_ADDI (Fits in ADDI imm)
    # Purpose: Test loading a small negative value (decimal).
    li x31, -1000           # Value under test -> x31
    li x30, -1000           # Golden value (assembler handles negative decimal) -> x30
    # Golden hex: 0xFFFFFFFFFFFFFС18
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal

## TEST: LI_SMALL_NEG_ADDI_MIN (Lower limit of ADDI imm)
    # Purpose: Test the negative boundary of ADDI immediate field.
    li x31, -2048           # Value under test (bit pattern 0xFF...FFF800) -> x31
    li x30, -2048           # Golden value -> x30
    # Golden hex: 0xFFFFFFFFFFFFF800
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal

## TEST: LI_MEDIUM_POS_LUI_ADDI (Requires LUI/ADDI)
    # Purpose: Test value just outside ADDI range, requiring LUI.
    li x31, 2048            # Value under test (0x800) -> x31
    li x30, 0x800           # Golden value -> x30
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal

## TEST: LI_MEDIUM_POS_LUI_ADDI_2
    # Purpose: Test another value requiring LUI/ADDI.
    li x31, 100000          # Value under test (0x186A0) -> x31
    li x30, 100000          # Golden value -> x30
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal

## TEST: LI_CONST_POS_32BIT_MAX_SIGNED (0x7FFFFFFF)
    # Purpose: Test loading max positive 32-bit signed integer value.
    li x31, 0x7FFFFFFF      # Value under test (Hex) -> x31
    li x30, 0x7FFFFFFF      # Golden value -> x30
    # Expected in RV64 reg: 0x000000007FFFFFFF
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal

## TEST: LI_CONST_POS_32BIT_0xFFFFFFFF
    # Purpose: Test loading 0xFFFFFFFF (often -1 in 32-bit signed).
    # On RV64, li typically zero-extends positive hex values if <= 32 bits.
    li x31, 0xFFFFFFFF      # Value under test (Hex) -> x31
    li x30, 0x00000000FFFFFFFF # Golden value (zero-extended 32-bit pattern) -> x30
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal

## TEST: LI_MEDIUM_NEG_LUI_ADDI (Requires LUI/ADDI)
    # Purpose: Test negative value just outside ADDI range.
    li x31, -2049           # Value under test (bit pattern 0xFF...FFF7FF) -> x31
    li x30, -2049           # Golden value -> x30
    # Golden hex: 0xFFFFFFFFFFFFF7FF
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal

## TEST: LI_CONST_NEG_32BIT_MIN_SIGNED (Decimal)
    # Purpose: Test loading min negative 32-bit signed value (-2^31).
    # On RV64, li sign-extends negative decimal values.
    li x31, -2147483648     # Value under test (Decimal) -> x31
    li x30, -2147483648     # Golden value -> x30
    # Golden hex: 0xFFFFFFFF80000000 (sign-extended from 32-bit 0x80000000)
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal

## TEST: LI_CONST_HEX_32BIT_0x80000000
    # Purpose: Test loading the pattern 0x80000000 via hex.
    # On RV64, li typically zero-extends positive hex values.
    li x31, 0x80000000      # Value under test (Hex) -> x31
    li x30, 0x0000000080000000 # Golden value (zero-extended pattern) -> x30
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal

## TEST: LI_LARGE_POS_64BIT (Requires multi-instruction sequence)
    # Purpose: Test loading a large positive 64-bit value.
    li x31, 0x123456789ABCDEF0 # Value under test -> x31
    li x30, 0x123456789ABCDEF0 # Golden value -> x30
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal

## TEST: LI_LARGE_POS_64BIT_MAX_SIGNED (0x7FFFFFFFFFFFFFFF)
    # Purpose: Test loading the maximum positive signed 64-bit value.
    li x31, 0x7FFFFFFFFFFFFFFF # Value under test -> x31
    li x30, 0x7FFFFFFFFFFFFFFF # Golden value -> x30
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal

## TEST: LI_LARGE_CONST_NEG_ONE (0xFFFFFFFFFFFFFFFF)
    # Purpose: Test loading the pattern for -1 (signed) or max uint64 (unsigned).
    li x31, 0xFFFFFFFFFFFFFFFF # Value under test (Hex) -> x31
    li x30, 0xFFFFFFFFFFFFFFFF # Golden value -> x30
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal

## TEST: LI_NEG_ONE_DECIMAL
    # Purpose: Test loading -1 using decimal literal.
    li x31, -1                # Value under test (Decimal) -> x31
    li x30, -1                # Golden value (should also be 0xFF...FF) -> x30
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal

## TEST: LI_LARGE_CONST_MIN_SIGNED (0x8000000000000000)
    # Purpose: Test loading the pattern for minimum signed 64-bit value (-2^63).
    li x31, 0x8000000000000000 # Value under test (Hex is safest) -> x31
    li x30, 0x8000000000000000 # Golden value -> x30
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal
    # Note: Loading -9223372036854775808 via decimal might fail in some
    # assembler parsers due to internal limits, hex is preferred here.

## TEST: LI_LARGE_NEG_OTHER
    # Purpose: Test loading another large negative 64-bit value.
    li x31, 0xC000000000000000 # Value under test -> x31
    li x30, 0xC000000000000000 # Golden value -> x30
    li x11, 1               # Signal Compare
    li x11, 0               # Clear Signal
##--------------------------------------------
## Additional li Tests (Pattern Stress) - RV64
## Using x31 as result/test value
## Using x30 to load Golden value
## Using x11 for Compare Signaling
##--------------------------------------------

## TEST: LI_PATTERN_ALT_10
    # Purpose: Test alternating 10 pattern (64-bit)
    li x31, 0xAAAAAAAAAAAAAAAA # Value under test
    li x30, 0xAAAAAAAAAAAAAAAA # Golden value
    li x11, 1                  # Signal Compare (External harness should check x31 == x30)
    li x11, 0                  # Clear Signal

## TEST: LI_PATTERN_ALT_01
    # Purpose: Test alternating 01 pattern (64-bit)
    li x31, 0x5555555555555555 # Value under test
    li x30, 0x5555555555555555 # Golden value
    li x11, 1                  # Signal Compare
    li x11, 0                  # Clear Signal

## TEST: LI_PATTERN_32_ALT_10
    # Purpose: Test alternating 10 pattern (32-bit), check zero extension on RV64
    li x31, 0xAAAAAAAA         # Value under test
    li x30, 0x00000000AAAAAAAA # Golden value (assuming zero-extend for positive hex < 2^31)
    li x11, 1                  # Signal Compare
    li x11, 0                  # Clear Signal

## TEST: LI_PATTERN_32_ALT_01
    # Purpose: Test alternating 01 pattern (32-bit), check zero extension on RV64
    li x31, 0x55555555         # Value under test
    li x30, 0x0000000055555555 # Golden value
    li x11, 1                  # Signal Compare
    li x11, 0                  # Clear Signal
##--------------------------------------------
## Additional li Tests (LUI/ADDI Stress) - RV64
##--------------------------------------------

## TEST: LI_STRESS_LUI_ADDI_NEG_LO_1
    # Purpose: Test LUI/ADDI combination with negative lower 12 bits (-2048 = 0x800)
    # Example: target 0xABC800 = lui(0xABD) + addi(-2048)
    li x31, 0xABC800           # Value under test
    li x30, 0x00000000ABC800   # Golden value (assuming zero-extend overall)
    li x11, 1                  # Signal Compare
    li x11, 0                  # Clear Signal

## TEST: LI_STRESS_LUI_ADDI_NEG_LO_2
    # Purpose: Test LUI/ADDI near 32-bit wrap with negative lower 12 bits (-1 = 0xFFF)
    # Example: target 0x123FFF = lui(0x124) + addi(-1)
    li x31, 0x123FFF           # Value under test
    li x30, 0x00000000123FFF   # Golden value (assuming zero-extend overall)
    li x11, 1                  # Signal Compare
    li x11, 0                  # Clear Signal

## TEST: LI_STRESS_LUI_ADDI_NEG_LO_3
    # Purpose: Test LUI/ADDI that constructs 0xFFFFFxxx pattern using negative lower bits
    # Example: target 0xFFFFE800 = lui(0xFFFFF) + addi(-2048)? No, that's FFFFE800. Need lui(0x100000)+addi(-2048)? No, wrong sign ext.
    # How about lui(0xFFFFE) + addi(0x800)? -> 0xFFFFE800. Let's use this.
    li x31, 0xFFFFE800         # Value under test
    li x30, 0x00000000FFFFE800 # Golden value (assuming zero-extend overall)
    li x11, 1                  # Signal Compare
    li x11, 0                  # Clear Signal
##--------------------------------------------
## Additional li Tests (32/64 Boundary) - RV64
##--------------------------------------------

## TEST: LI_NEAR_32_BOUNDARY_POS
    # Purpose: Test value just above 32-bit boundary
    li x31, 0x100000000        # Value under test (2^32)
    li x30, 0x0000000100000000 # Golden value
    li x11, 1                  # Signal Compare
    li x11, 0                  # Clear Signal

## TEST: LI_NEAR_32_BOUNDARY_NEG
    # Purpose: Test pattern with high 32 bits set, low clear
    li x31, 0xFFFFFFFF00000000 # Value under test
    li x30, 0xFFFFFFFF00000000 # Golden value
    li x11, 1                  # Signal Compare
    li x11, 0                  # Clear Signal
##--------------------------------------------
## Additional li Tests (Complex Pattern) - RV64
##--------------------------------------------

## TEST: LI_COMPLEX_PATTERN_1
    # Purpose: Test a general complex bit pattern
    li x31, 0xFEDCBA9876543210 # Value under test
    li x30, 0xFEDCBA9876543210 # Golden value
    li x11, 1                  # Signal Compare
    li x11, 0                  # Clear Signal

## TEST: LI_COMPLEX_PATTERN_2
    # Purpose: Test another complex bit pattern
    li x31, 0x1234ABCD4321EF01 # Value under test
    li x30, 0x1234ABCD4321EF01 # Golden value
    li x11, 1                  # Signal Compare
    li x11, 0                  # Clear Signal
