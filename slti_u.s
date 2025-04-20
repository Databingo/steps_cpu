_start:
    # Initialize registers (optional, assuming reset state is 0)
    li x5, 0
    li x6, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.

##--------------------------------------------
## SLTI / SLTIU Tests - RV64
## Using x31 as result (rd)
## Using x5 as rs1, x6 as rs2
## Using x30 for Golden value (0 or 1)
## Using x11 for Compare Signaling
##--------------------------------------------
# -- SLTI Tests (Set Less Than, Signed, Immediate) --
## TEST: SLTI_POS_LESS
    # Purpose: 5 < 10 (signed imm) -> True (1)
    li  x5, 5
    slti x31, x5, 10
    li  x30, 1                 # Expected result: 1
    li  x11, 1
    li  x11, 0

## TEST: SLTI_POS_GREATER
    # Purpose: 10 < 5 (signed imm) -> False (0)
    li  x5, 10
    slti x31, x5, 5
    li  x30, 0                 # Expected result: 0
    li  x11, 1
    li  x11, 0

## TEST: SLTI_NEG_LESS_POS
    # Purpose: -5 < 10 (signed imm) -> True (1)
    li  x5, -5
    slti x31, x5, 10
    li  x30, 1                 # Expected result: 1
    li  x11, 1
    li  x11, 0

## TEST: SLTI_POS_LESS_NEG
    # Purpose: 10 < -5 (signed imm) -> False (0)
    li  x5, 10
    slti x31, x5, -5
    li  x30, 0                 # Expected result: 0
    li  x11, 1
    li  x11, 0

## TEST: SLTI_NEG_LESS_NEG
    # Purpose: -10 < -5 (signed imm) -> True (1)
    li  x5, -10
    slti x31, x5, -5
    li  x30, 1                 # Expected result: 1
    li  x11, 1
    li  x11, 0

## TEST: SLTI_EQUAL
    # Purpose: 5 < 5 (signed imm) -> False (0)
    li  x5, 5
    slti x31, x5, 5
    li  x30, 0                 # Expected result: 0
    li  x11, 1
    li  x11, 0

## TEST: SLTI_MAX_IMM
    # Purpose: 2046 < 2047 (signed max imm) -> True (1)
    li  x5, 2046
    slti x31, x5, 2047
    li  x30, 1                 # Expected result: 1
    li  x11, 1
    li  x11, 0

## TEST: SLTI_MIN_IMM
    # Purpose: -2049 < -2048 (signed min imm) -> True (1)
    li  x5, -2049
    slti x31, x5, -2048
    li  x30, 1                 # Expected result: 1
    li  x11, 1
    li  x11, 0

# -- SLTIU Tests (Set Less Than, Unsigned, Immediate) --
# Remember: Immediate is sign-extended first, THEN compared unsigned.
## TEST: SLTIU_POS_LESS
    # Purpose: 5 < 10 (unsigned imm) -> True (1)
    li  x5, 5
    sltiu x31, x5, 10          # Compare 5 < sign_extend(10)=10 (unsigned)
    li  x30, 1                 # Expected result: 1
    li  x11, 1
    li  x11, 0

## TEST: SLTIU_POS_GREATER
    # Purpose: 10 < 5 (unsigned imm) -> False (0)
    li  x5, 10
    sltiu x31, x5, 5           # Compare 10 < sign_extend(5)=5 (unsigned)
    li  x30, 0                 # Expected result: 0
    li  x11, 1
    li  x11, 0

## TEST: SLTIU_NEG_VS_POS
    # Purpose: -5 (huge unsigned) < 10 (small unsigned imm) -> False (0)
    li  x5, -5                 # x5 = 0xFF...FB (large unsigned)
    sltiu x31, x5, 10          # Compare large_unsigned < sign_extend(10)=10 (unsigned)
    li  x30, 0                 # Expected result: 0
    li  x11, 1
    li  x11, 0

## TEST: SLTIU_POS_VS_NEG
    # Purpose: 10 (small unsigned) < -5 (large unsigned imm) -> True (1)
    li  x5, 10
    sltiu x31, x5, -5          # Compare 10 < sign_extend(-5)=0xFF...FB (large unsigned)
    li  x30, 1                 # Expected result: 1
    li  x11, 1
    li  x11, 0

## TEST: SLTIU_NEG_VS_NEG
    # Purpose: -10 (0xFF...F6) < -5 (0xFF...FB) (unsigned imm) -> True (1)
    li  x5, -10
    sltiu x31, x5, -5          # Compare 0xFF...F6 < 0xFF...FB (unsigned)
    li  x30, 1                 # Expected result: 1
    li  x11, 1
    li  x11, 0

## TEST: SLTIU_EQUAL
    # Purpose: 5 < 5 (unsigned imm) -> False (0)
    li  x5, 5
    sltiu x31, x5, 5           # Compare 5 < sign_extend(5)=5 (unsigned)
    li  x30, 0                 # Expected result: 0
    li  x11, 1
    li  x11, 0

## TEST: SLTIU_MAX_IMM
    # Purpose: 2046 < 2047 (unsigned max imm) -> True (1)
    li  x5, 2046
    sltiu x31, x5, 2047        # Compare 2046 < sign_extend(2047)=2047 (unsigned)
    li  x30, 1                 # Expected result: 1
    li  x11, 1
    li  x11, 0

## TEST: SLTIU_MIN_IMM
    # Purpose: -2049 (large unsigned) < -2048 (large unsigned imm) -> True (1)
    li  x5, -2049              # 0xFF...F7FF
    sltiu x31, x5, -2048       # Compare 0xFF...F7FF < sign_extend(-2048)=0xFF...F800 (unsigned)
    li  x30, 1                 # Expected result: 1
    li  x11, 1
    li  x11, 0

## TEST: SLTIU_SEQZ_TRUE  (Set if Equal Zero pseudo-op)
    # Purpose: Test sltiu rd, rs1, 1 when rs1 is zero -> True (1)
    li  x5, 0
    sltiu x31, x5, 1           # Compare 0 < sign_extend(1)=1 (unsigned)
    li  x30, 1                 # Expected result: 1
    li  x11, 1
    li  x11, 0

## TEST: SLTIU_SEQZ_FALSE (Set if Equal Zero pseudo-op)
    # Purpose: Test sltiu rd, rs1, 1 when rs1 is non-zero -> False (0)
    li  x5, 55
    sltiu x31, x5, 1           # Compare 55 < sign_extend(1)=1 (unsigned)
    li  x30, 0                 # Expected result: 0
    li  x11, 1
    li  x11, 0


##--------------------------------------------
## End of SLT Tests
##--------------------------------------------
