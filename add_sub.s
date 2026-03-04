_start:
    # Initialize registers used for operands (optional, assuming reset state is 0)
    li x5, 0
    li x6, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.

##--------------------------------------------
## ADD/SUB Immediate/Register Tests - RV64
## Using x31 as result (rd)
## Using x5 as rs1, x6 as rs2
## Using x30 for Golden value
## Using x11 for Compare Signaling
##--------------------------------------------

# -- ADDI Tests (Add Immediate, 64-bit) --
## TEST: ADDI_POS_POS
    li  x5, 1000
    addi x31, x5, 234          # x31 = 1000 + 234 = 1234
    li  x30, 1234
    li  x11, 1
    li  x11, 0

## TEST: ADDI_POS_NEG
    li  x5, 1000
    addi x31, x5, -234         # x31 = 1000 - 234 = 766
    li  x30, 766
    li  x11, 1
    li  x11, 0

## TEST: ADDI_NEG_POS
    li  x5, -1000
    addi x31, x5, 234          # x31 = -1000 + 234 = -766
    li  x30, -766
    li  x11, 1
    li  x11, 0

## TEST: ADDI_NEG_NEG
    li  x5, -1000
    addi x31, x5, -234         # x31 = -1000 - 234 = -1234
    li  x30, -1234
    li  x11, 1
    li  x11, 0

## TEST: ADDI_ZERO_IMM
    li  x5, 12345678
    addi x31, x5, 0            # x31 = x5 + 0 = x5
    li  x30, 12345678
    li  x11, 1
    li  x11, 0

## TEST: ADDI_ZERO_REG
    addi x31, x0, 987          # x31 = 0 + 987 = 987
    li  x30, 987
    li  x11, 1
    li  x11, 0

## TEST: ADDI_MAX_IMM
    li  x5, 10
    addi x31, x5, 2047         # x31 = 10 + 2047 = 2057
    li  x30, 2057
    li  x11, 1
    li  x11, 0

## TEST: ADDI_MIN_IMM
    li  x5, 10
    addi x31, x5, -2048        # x31 = 10 - 2048 = -2038
    li  x30, -2038
    li  x11, 1
    li  x11, 0

## TEST: ADDI_64_WRAP_POS
    li  x5, 0x7FFFFFFFFFFFFFFF # Max positive 64-bit
    addi x31, x5, 1            # x31 should wrap to min negative
    li  x30, 0x8000000000000000
    li  x11, 1
    li  x11, 0

## TEST: ADDI_64_WRAP_NEG
    li  x5, 0xFFFFFFFFFFFFFFFF # -1
    addi x31, x5, 1            # x31 should wrap to 0
    li  x30, 0
    li  x11, 1
    li  x11, 0

# -- ADDIW Tests (Add Immediate Word, 32-bit op, sign-extend result) --
## TEST: ADDIW_POS_POS
    li  x5, 1000
    addiw x31, x5, 234         # 32-bit: 1000 + 234 = 1234. Sign extend -> 1234
    li  x30, 1234
    li  x11, 1
    li  x11, 0

## TEST: ADDIW_NEG_NEG
    li  x5, -1000              # 64-bit: 0xFF...FC18, 32-bit: 0xFFFFFC18
    addiw x31, x5, -234        # 32-bit: (-1000) + (-234) = -1234 (0xFFFFF B2E). Sign extend -> -1234
    li  x30, -1234
    li  x11, 1
    li  x11, 0

## TEST: ADDIW_IGNORE_UPPER
    li  x5, 0x11111111AAAAEEEE # Upper bits should be ignored
    addiw x31, x5, 1           # 32-bit: 0xAAAAEEEE + 1 = 0xAAAAEEEF. Sign extend -> 0xFFFFF FFAAAAEEEEF
    li  x30, 0xFFFFFFFFAAAAEEEF
    li  x11, 1
    li  x11, 0

## TEST: ADDIW_32_WRAP_POS
    li  x5, 0x7FFFFFFF         # Max positive 32-bit
    addiw x31, x5, 1           # 32-bit: wraps to 0x80000000 (-2^31). Sign extend -> 0xFFFFFFFF80000000
    li  x30, 0xFFFFFFFF80000000
    li  x11, 1
    li  x11, 0

## TEST: ADDIW_32_WRAP_NEG
    li  x5, 0xFFFFFFFF         # -1 (32-bit view)
    addiw x31, x5, 1           # 32-bit: wraps to 0x00000000. Sign extend -> 0
    li  x30, 0
    li  x11, 1
    li  x11, 0

## TEST: ADDIW_SIGN_EXT_POS_RESULT
    li  x5, 0x0000000070000000 # Positive 32-bit number
    addiw x31, x5, 0x100       # 32-bit: 0x70000100. Sign extend -> 0x0000000070000100
    li  x30, 0x70000100
    li  x11, 1
    li  x11, 0

## TEST: ADDIW_SIGN_EXT_NEG_RESULT
    li  x5, 0x0000000080000000 # Negative 32-bit number (-2^31)
    addiw x31, x5, -1          # 32-bit: 0x80000000 - 1 = 0x7FFFFFFF. Sign extend -> 0x000000007FFFFFFF
    li  x30, 0x7FFFFFFF
    li  x11, 1
    li  x11, 0

# -- ADD Tests (Add Register, 64-bit) --
## TEST: ADD_POS_POS
    li  x5, 123456
    li  x6, 789
    add x31, x5, x6            # x31 = 123456 + 789 = 124245
    li  x30, 124245
    li  x11, 1
    li  x11, 0

## TEST: ADD_POS_NEG
    li  x5, 123456
    li  x6, -789
    add x31, x5, x6            # x31 = 123456 - 789 = 122667
    li  x30, 122667
    li  x11, 1
    li  x11, 0

## TEST: ADD_NEG_NEG
    li  x5, -123456
    li  x6, -789
    add x31, x5, x6            # x31 = -123456 - 789 = -124245
    li  x30, -124245
    li  x11, 1
    li  x11, 0

## TEST: ADD_ZERO_REG
    li  x5, 987654321
    add x31, x5, x0            # x31 = x5 + 0 = x5
    li  x30, 987654321
    li  x11, 1
    li  x11, 0

## TEST: ADD_LARGE
    li  x5, 0x1111111111111111
    li  x6, 0x2222222222222222
    add x31, x5, x6            # x31 = 0x3333333333333333
    li  x30, 0x3333333333333333
    li  x11, 1
    li  x11, 0

## TEST: ADD_WRAP
    li  x5, 0x7FFFFFFFFFFFFFFF
    li  x6, 0x0000000000000001
    add x31, x5, x6            # x31 wraps to 0x8000...00
    li  x30, 0x8000000000000000
    li  x11, 1
    li  x11, 0

# -- ADDW Tests (Add Word Register, 32-bit op, sign-extend result) --
## TEST: ADDW_POS_POS
    li  x5, 123456
    li  x6, 789
    addw x31, x5, x6           # 32-bit: 123456+789=124245 (0x1E555). Sign extend -> 124245
    li  x30, 124245
    li  x11, 1
    li  x11, 0

## TEST: ADDW_IGNORE_UPPER
    li  x5, 0x11111111AAAAEEEE
    li  x6, 0x22222222BBBBFFFF
    addw x31, x5, x6           # 32-bit: 0xAAAAEEEE + 0xBBBBFFFF = 0x16666EEED -> truncates to 0x6666EEED. Sign extend -> 0x000000006666EEED
    li  x30, 0x6666EEED        # <-- CORRECTED Golden Value
    li  x11, 1
    li  x11, 0

## TEST: ADDW_32_WRAP_POS
    li  x5, 0x7FFFFFFF
    li  x6, 1
    addw x31, x5, x6           # 32-bit: wraps to 0x80000000. Sign extend -> 0xFFFFFFFF80000000
    li  x30, 0xFFFFFFFF80000000
    li  x11, 1
    li  x11, 0

## TEST: ADDW_32_WRAP_NEG
    li  x5, 0xFFFFFFFF          # Represents -1 in 32 bits
    li  x6, 0xFFFFFFFF          # Represents -1 in 32 bits
    addw x31, x5, x6           # 32-bit: -1 + -1 = -2 (0xFFFFFFFE). Sign extend -> 0xFFFFFFFFFFFFFFFE
    li  x30, -2
    li  x11, 1
    li  x11, 0

# -- SUB Tests (Subtract Register, 64-bit) --
## TEST: SUB_POS_POS
    li  x5, 1000
    li  x6, 300
    sub x31, x5, x6            # x31 = 1000 - 300 = 700
    li  x30, 700
    li  x11, 1
    li  x11, 0

## TEST: SUB_POS_NEG
    li  x5, 1000
    li  x6, -300
    sub x31, x5, x6            # x31 = 1000 - (-300) = 1300
    li  x30, 1300
    li  x11, 1
    li  x11, 0

## TEST: SUB_NEG_POS
    li  x5, -1000
    li  x6, 300
    sub x31, x5, x6            # x31 = -1000 - 300 = -1300
    li  x30, -1300
    li  x11, 1
    li  x11, 0

## TEST: SUB_NEG_NEG
    li  x5, -1000
    li  x6, -300
    sub x31, x5, x6            # x31 = -1000 - (-300) = -700
    li  x30, -700
    li  x11, 1
    li  x11, 0

## TEST: SUB_ZERO_REG
    li  x5, 98765
    sub x31, x5, x0            # x31 = x5 - 0 = x5
    li  x30, 98765
    li  x11, 1
    li  x11, 0

## TEST: SUB_NEGATE
    li  x6, 12345
    sub x31, x0, x6            # x31 = 0 - x6 = -12345
    li  x30, -12345
    li  x11, 1
    li  x11, 0

## TEST: SUB_IDENTICAL
    li  x5, 12345
    sub x31, x5, x5            # x31 = x5 - x5 = 0
    li  x30, 0
    li  x11, 1
    li  x11, 0

## TEST: SUB_WRAP
    li  x5, 0x8000000000000000 # Min negative 64-bit
    li  x6, 1
    sub x31, x5, x6            # x31 wraps to 0x7FFF...FF (max positive)
    li  x30, 0x7FFFFFFFFFFFFFFF
    li  x11, 1
    li  x11, 0

# -- SUBW Tests (Subtract Word Register, 32-bit op, sign-extend result) --
## TEST: SUBW_POS_POS
    li  x5, 1000
    li  x6, 300
    subw x31, x5, x6           # 32-bit: 1000 - 300 = 700. Sign extend -> 700
    li  x30, 700
    li  x11, 1
    li  x11, 0

## TEST: SUBW_POS_NEG
    li  x5, 1000
    li  x6, 0xFFFFFFFF # -1 (32-bit view)
    subw x31, x5, x6           # 32-bit: 1000 - (-1) = 1001. Sign extend -> 1001
    li  x30, 1001
    li  x11, 1
    li  x11, 0

## TEST: SUBW_IGNORE_UPPER
    li  x5, 0xAAAAAAAA11111111
    li  x6, 0xBBBBBBBB00000001
    subw x31, x5, x6           # 32-bit: 0x11111111 - 0x00000001 = 0x11111110. Sign extend -> 0x11111110
    li  x30, 0x11111110
    li  x11, 1
    li  x11, 0

## TEST: SUBW_32_WRAP_POS
    li  x5, 0
    li  x6, 1
    subw x31, x5, x6           # 32-bit: 0 - 1 = -1 (0xFFFFFFFF). Sign extend -> 0xFFFFFFFFFFFFFFFF
    li  x30, -1
    li  x11, 1
    li  x11, 0

## TEST: SUBW_32_WRAP_NEG
    li  x5, 0x80000000         # Min negative 32-bit
    li  x6, 1
    subw x31, x5, x6           # 32-bit: wraps to 0x7FFFFFFF. Sign extend -> 0x000000007FFFFFFF
    li  x30, 0x7FFFFFFF
    li  x11, 1
    li  x11, 0

##--------------------------------------------
## Additional ADD/SUB Tests (Extreme Cases) - RV64
##--------------------------------------------

## TEST: ADD_MAX_POS_PLUS_MAX_POS
    # Purpose: Test 0x7F...F + 0x7F...F => 0xFF...FE (-2)
    li  x5, 0x7FFFFFFFFFFFFFFF
    li  x6, 0x7FFFFFFFFFFFFFFF
    add x31, x5, x6
    li  x30, -2 # Or li x30, 0xFFFFFFFFFFFFFFFE
    li  x11, 1
    li  x11, 0

## TEST: ADD_MIN_NEG_PLUS_MIN_NEG
    # Purpose: Test 0x80...0 + 0x80...0 => 0 (overflow ignored)
    li  x5, 0x8000000000000000
    li  x6, 0x8000000000000000
    add x31, x5, x6
    li  x30, 0
    li  x11, 1
    li  x11, 0

## TEST: SUB_ZERO_MINUS_ONE
    # Purpose: Test 0 - 1 => -1
    li  x5, 0
    li  x6, 1
    sub x31, x5, x6
    li  x30, -1 # Or li x30, 0xFFFFFFFFFFFFFFFF
    li  x11, 1
    li  x11, 0

## TEST: SUB_MIN_NEG_MINUS_ONE
    # Purpose: Test 0x80...0 - 1 => 0x7F...F (underflow wraps)
    li  x5, 0x8000000000000000
    li  x6, 1
    sub x31, x5, x6
    li  x30, 0x7FFFFFFFFFFFFFFF
    li  x11, 1
    li  x11, 0

## TEST: ADDW_MAX_POS_PLUS_MAX_POS
    # Purpose: Test 32-bit 0x7FFFFFFF + 0x7FFFFFFF => 0xFFFFFFFE (-2), sign extend
    li  x5, 0x7FFFFFFF
    li  x6, 0x7FFFFFFF
    addw x31, x5, x6
    li  x30, -2 # Or li x30, 0xFFFFFFFFFFFFFFFE
    li  x11, 1
    li  x11, 0

## TEST: ADDW_MIN_NEG_PLUS_MIN_NEG
    # Purpose: Test 32-bit 0x80000000 + 0x80000000 => 0x00000000, sign extend
    li  x5, 0x80000000
    li  x6, 0x80000000
    addw x31, x5, x6
    li  x30, 0
    li  x11, 1
    li  x11, 0

## TEST: SUBW_ZERO_MINUS_MIN_NEG
    # Purpose: Test 32-bit 0 - 0x80000000 => 0x80000000 (-2^31), sign extend
    li  x5, 0
    li  x6, 0x80000000
    subw x31, x5, x6
    li  x30, 0xFFFFFFFF80000000
    li  x11, 1
    li  x11, 0

## TEST: ADD_WRITE_X0
    # Purpose: Test writing to x0 using ADD (should have no effect)
    li  x5, 123
    li  x6, 456
    add x0, x5, x6             # Attempt write to x0
    addi x31, x0, 0            # Replaced 'mv x31, x0': Copy x0 to x31
    li  x30, 0                 # Golden value should still be 0
    li  x11, 1
    li  x11, 0

## TEST: ADDI_WRITE_X0
    # Purpose: Test writing to x0 using ADDI (should have no effect)
    li  x5, 123
    addi x0, x5, 456           # Attempt write to x0
    addi x31, x0, 0            # Replaced 'mv x31, x0': Copy x0 to x31
    li  x30, 0                 # Golden value should still be 0
    li  x11, 1
    li  x11, 0

## TEST: ADDW_WRITE_X0
    # Purpose: Test writing to x0 using ADDW (should have no effect)
    li  x5, 123
    li  x6, 456
    addw x0, x5, x6            # Attempt write to x0
    addi x31, x0, 0            # Replaced 'mv x31, x0': Copy x0 to x31
    li  x30, 0                 # Golden value should still be 0
    li  x11, 1
    li  x11, 0

## TEST: SUBW_WRITE_X0
    # Purpose: Test writing to x0 using SUBW (should have no effect)
    li  x5, 123
    li  x6, 456
    subw x0, x5, x6            # Attempt write to x0
    addi x31, x0, 0            # Replaced 'mv x31, x0': Copy x0 to x31
    li  x30, 0                 # Golden value should still be 0
    li  x11, 1
    li  x11, 0

##--------------------------------------------
## Data Hazard Tests - RV64
##--------------------------------------------

## TEST: HAZARD_ADD_ADDI (RAW ALU->ALU)
    li x5, 100
    li x6, 200
    add x7, x5, x6             # x7 = 300
    addi x31, x7, 50           # Use x7 immediately: x31 = 300 + 50 = 350
    li x30, 350                # Golden value for addi
    li x11, 1
    li x11, 0

## TEST: HAZARD_LW_ADD (RAW Load->ALU)
    # Assumes data_test.txt is loaded; Addr 8 has 0x12345678
    li x5, 8                   # Address for lw
    li x7, 100                 # Value for add
    lw x6, 0(x5)               # Load 0x12345678 into x6
    add x31, x6, x7            # Use x6 immediately: x31 = 0x12345678 + 100 = 0x123456DC
    li x30, 0x123456DC
    li x11, 1
    li x11, 0

## TEST: HAZARD_ADDI_LW (RAW ALU->Address)
    # Assumes data_test.txt is loaded; Addr 12 has 0x80000000
    li x5, 8                   # Base address part 1
    addi x5, x5, 4             # Calculate final address 12 in x5
    lw x31, 0(x5)              # Use x5 immediately as base address
    li x30, 0xFFFFFFFF80000000 # Golden value (lw sign extends 0x80000000)
    li x11, 1
    li x11, 0

## TEST: HAZARD_LD_SD (RAW Load->Store Data)
    # Assumes data_test.txt loaded; Addr 16 has 0x11...88
    # Store target area starts at Addr 80
    li x5, 16                  # Address for ld
    ld x6, 0(x5)               # Load 0x11...88 into x6
    sd x6, 80(x0)              # Use x6 immediately in store to Addr 80
    # Verify store
    ld x31, 80(x0)             # Load back from Addr 80
    li x30, 0x1122334455667788 # Golden value
    li x11, 1
    li x11, 0

## TEST: HAZARD_LD_SB (RAW Load->Store Address)
    # Assumes data_test.txt loaded; Addr 24 has 0x80...00
    # Store target area starts at Addr 80
    li x6, 0xAB                # Value to store
    ld x5, 24(x0)              # Load 0x80...00 into x5 (use as base address component later?)
                               # Let's make it simpler: load target address
    li x5, 88                  # Target store address 88
    ld x31, 16(x0)             # Dummy load to x31 first (using Addr 16)
    sb x6, 0(x5)               # Use x5 immediately as store address base
    # Verify store
    lb x31, 88(x0)             # Load back byte from Addr 88
    li x30, 0xFFFFFFFFFFFFFFAB # Golden value (sign extended AB)
    li x11, 1
    li x11, 0

## TEST: HAZARD_ADDW_SUBW (RAW W-Instr -> W-Instr)
    li x5, 0x7FFFFFF0
    li x6, 0x10
    addw x7, x5, x6            # x7 = 0x80000000 (32-bit), sign extended to 0xFFFFFFFF80000000
    li x8, 1
    subw x31, x7, x8           # Use x7 immediately. 32-bit: 0x80000000 - 1 = 0x7FFFFFFF. Sign extended -> 0x7FFFFFFF
    li x30, 0x7FFFFFFF
    li x11, 1
    li x11, 0

## TEST: HAZARD_LW_ADDW (RAW Load->W-Instr)
    # Assumes data_test.txt loaded; Addr 12 has 0x80000000
    li x5, 12                  # Address for lw
    lw x6, 0(x5)               # x6 = 0xFFFFFFFF80000000
    li x7, 1                   # Value for addw
    addw x31, x6, x7           # Use x6 immediately. 32-bit: x6[31:0](=0x80000000) + x7[31:0](=1) = 0x80000001. Sign extend -> 0xFFFFFFFF80000001
    li x30, 0xFFFFFFFF80000001
    li x11, 1
    li x11, 0
##--------------------------------------------
## End of ADD/SUB Tests
##--------------------------------------------
