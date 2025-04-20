_start:
    # Initialize registers (optional, assuming reset state is 0)
    li x5, 0
    li x6, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.

##--------------------------------------------
## SLT / SLTU / SLTI / SLTIU Tests - RV64
## Using x31 as result (rd)
## Using x5 as rs1, x6 as rs2
## Using x30 for Golden value (0 or 1)
## Using x11 for Compare Signaling
##--------------------------------------------

# -- SLT Tests (Set Less Than, Signed, Register) --
## TEST: SLT_POS_LESS
    # Purpose: 5 < 10 (signed) -> True (1)
    li  x5, 5
    li  x6, 10
    slt x31, x5, x6
    li  x30, 1                 # Expected result: 1
    li  x11, 1
    li  x11, 0

## TEST: SLT_POS_GREATER
    # Purpose: 10 < 5 (signed) -> False (0)
    li  x5, 10
    li  x6, 5
    slt x31, x5, x6
    li  x30, 0                 # Expected result: 0
    li  x11, 1
    li  x11, 0

## TEST: SLT_NEG_LESS_POS
    # Purpose: -5 < 10 (signed) -> True (1)
    li  x5, -5
    li  x6, 10
    slt x31, x5, x6
    li  x30, 1                 # Expected result: 1
    li  x11, 1
    li  x11, 0

## TEST: SLT_POS_LESS_NEG
    # Purpose: 10 < -5 (signed) -> False (0)
    li  x5, 10
    li  x6, -5
    slt x31, x5, x6
    li  x30, 0                 # Expected result: 0
    li  x11, 1
    li  x11, 0

## TEST: SLT_NEG_LESS_NEG
    # Purpose: -10 < -5 (signed) -> True (1)
    li  x5, -10
    li  x6, -5
    slt x31, x5, x6
    li  x30, 1                 # Expected result: 1
    li  x11, 1
    li  x11, 0

## TEST: SLT_NEG_GREATER_NEG
    # Purpose: -5 < -10 (signed) -> False (0)
    li  x5, -5
    li  x6, -10
    slt x31, x5, x6
    li  x30, 0                 # Expected result: 0
    li  x11, 1
    li  x11, 0

## TEST: SLT_EQUAL
    # Purpose: 5 < 5 (signed) -> False (0)
    li  x5, 5
    li  x6, 5
    slt x31, x5, x6
    li  x30, 0                 # Expected result: 0
    li  x11, 1
    li  x11, 0

# -- SLTU Tests (Set Less Than, Unsigned, Register) --
## TEST: SLTU_POS_LESS
    # Purpose: 5 < 10 (unsigned) -> True (1)
    li  x5, 5
    li  x6, 10
    sltu x31, x5, x6
    li  x30, 1                 # Expected result: 1
    li  x11, 1
    li  x11, 0

## TEST: SLTU_POS_GREATER
    # Purpose: 10 < 5 (unsigned) -> False (0)
    li  x5, 10
    li  x6, 5
    sltu x31, x5, x6
    li  x30, 0                 # Expected result: 0
    li  x11, 1
    li  x11, 0

## TEST: SLTU_NEG_VS_POS
    # Purpose: -5 (huge unsigned) < 10 (small unsigned) -> False (0)
    li  x5, -5                 # 0xFF...FB (very large unsigned)
    li  x6, 10
    sltu x31, x5, x6
    li  x30, 0                 # Expected result: 0
    li  x11, 1
    li  x11, 0

## TEST: SLTU_POS_VS_NEG
    # Purpose: 10 (small unsigned) < -5 (huge unsigned) -> True (1)
    li  x5, 10
    li  x6, -5                 # 0xFF...FB (very large unsigned)
    sltu x31, x5, x6
    li  x30, 1                 # Expected result: 1
    li  x11, 1
    li  x11, 0

## TEST: SLTU_NEG_VS_NEG
    # Purpose: -10 (0xFF...F6) < -5 (0xFF...FB) (unsigned) -> True (1)
    li  x5, -10
    li  x6, -5
    sltu x31, x5, x6
    li  x30, 1                 # Expected result: 1
    li  x11, 1
    li  x11, 0

## TEST: SLTU_EQUAL
    # Purpose: 5 < 5 (unsigned) -> False (0)
    li  x5, 5
    li  x6, 5
    sltu x31, x5, x6
    li  x30, 0                 # Expected result: 0
    li  x11, 1
    li  x11, 0
