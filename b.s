_start:
    # Initialize registers (optional)
    li x5, 0
    li x6, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.
    # Current time: Sunday, April 20, 2025 at 12:22 AM PDT

##--------------------------------------------
## Conditional Branch Tests - RV64
## Using x31 as result indicator (1=Taken, 2=Not Taken)
## Using x5 as rs1, x6 as rs2
## Using x30 for Golden value
## Using x11 for Compare Signaling
##--------------------------------------------

# -- BEQ Tests (Branch if Equal) --
## TEST: BEQ_TAKEN_POS
    # Purpose: Branch if 10 == 10 (Should Take)
    li x5, 10
    li x6, 10
    beq x5, x6, L_beq_t_1      # Branch TAKEN
    li x31, 2                  # Path Not Taken Result = 2
    j L_beq_v_1
L_beq_t_1:
    li x31, 1                  # Path Taken Result = 1
L_beq_v_1:
    li x30, 1                  # Expected Result = 1
    li x11, 1
    li x11, 0

## TEST: BEQ_NOT_TAKEN_POS
    # Purpose: Branch if 10 == 11 (Should Not Take)
    li x5, 10
    li x6, 11
    beq x5, x6, L_beq_nt_1     # Branch NOT Taken
    li x31, 2                  # Path Not Taken Result = 2
    j L_beq_v_2
L_beq_nt_1:
    li x31, 1                  # Path Taken Result = 1
L_beq_v_2:
    li x30, 2                  # Expected Result = 2
    li x11, 1
    li x11, 0

## TEST: BEQ_TAKEN_NEG
    # Purpose: Branch if -5 == -5 (Should Take)
    li x5, -5
    li x6, -5
    beq x5, x6, L_beq_t_2      # Branch TAKEN
    li x31, 2
    j L_beq_v_3
L_beq_t_2:
    li x31, 1
L_beq_v_3:
    li x30, 1
    li x11, 1
    li x11, 0

# -- BNE Tests (Branch if Not Equal) --
## TEST: BNE_TAKEN_POS
    # Purpose: Branch if 10 != 11 (Should Take)
    li x5, 10
    li x6, 11
    bne x5, x6, L_bne_t_1      # Branch TAKEN
    li x31, 2                  # Path Not Taken Result = 2
    j L_bne_v_1
L_bne_t_1:
    li x31, 1                  # Path Taken Result = 1
L_bne_v_1:
    li x30, 1                  # Expected Result = 1
    li x11, 1
    li x11, 0

## TEST: BNE_NOT_TAKEN_POS
    # Purpose: Branch if 10 != 10 (Should Not Take)
    li x5, 10
    li x6, 10
    bne x5, x6, L_bne_nt_1     # Branch NOT Taken
    li x31, 2                  # Path Not Taken Result = 2
    j L_bne_v_2
L_bne_nt_1:
    li x31, 1                  # Path Taken Result = 1
L_bne_v_2:
    li x30, 2                  # Expected Result = 2
    li x11, 1
    li x11, 0

## TEST: BNE_TAKEN_MIXED
    # Purpose: Branch if 10 != -10 (Should Take)
    li x5, 10
    li x6, -10
    bne x5, x6, L_bne_t_2      # Branch TAKEN
    li x31, 2
    j L_bne_v_3
L_bne_t_2:
    li x31, 1
L_bne_v_3:
    li x30, 1
    li x11, 1
    li x11, 0

# -- BLT Tests (Branch if Less Than, Signed) --
## TEST: BLT_TAKEN_POS
    # Purpose: Branch if 5 < 10 (Signed) -> True (Should Take)
    li x5, 5
    li x6, 10
    blt x5, x6, L_blt_t_1      # Branch TAKEN
    li x31, 2
    j L_blt_v_1
L_blt_t_1:
    li x31, 1
L_blt_v_1:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BLT_NOT_TAKEN_POS
    # Purpose: Branch if 10 < 5 (Signed) -> False (Should Not Take)
    li x5, 10
    li x6, 5
    blt x5, x6, L_blt_nt_1     # Branch NOT Taken
    li x31, 2
    j L_blt_v_2
L_blt_nt_1:
    li x31, 1
L_blt_v_2:
    li x30, 2
    li x11, 1
    li x11, 0

## TEST: BLT_TAKEN_NEG_POS
    # Purpose: Branch if -5 < 10 (Signed) -> True (Should Take)
    li x5, -5
    li x6, 10
    blt x5, x6, L_blt_t_2      # Branch TAKEN
    li x31, 2
    j L_blt_v_3
L_blt_t_2:
    li x31, 1
L_blt_v_3:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BLT_NOT_TAKEN_POS_NEG
    # Purpose: Branch if 10 < -5 (Signed) -> False (Should Not Take)
    li x5, 10
    li x6, -5
    blt x5, x6, L_blt_nt_2     # Branch NOT Taken
    li x31, 2
    j L_blt_v_4
L_blt_nt_2:
    li x31, 1
L_blt_v_4:
    li x30, 2
    li x11, 1
    li x11, 0

## TEST: BLT_TAKEN_NEG_NEG
    # Purpose: Branch if -10 < -5 (Signed) -> True (Should Take)
    li x5, -10
    li x6, -5
    blt x5, x6, L_blt_t_3      # Branch TAKEN
    li x31, 2
    j L_blt_v_5
L_blt_t_3:
    li x31, 1
L_blt_v_5:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BLT_NOT_TAKEN_EQUAL
    # Purpose: Branch if 5 < 5 (Signed) -> False (Should Not Take)
    li x5, 5
    li x6, 5
    blt x5, x6, L_blt_nt_3     # Branch NOT Taken
    li x31, 2
    j L_blt_v_6
L_blt_nt_3:
    li x31, 1
L_blt_v_6:
    li x30, 2
    li x11, 1
    li x11, 0

# -- BGE Tests (Branch if Greater Than or Equal, Signed) --
## TEST: BGE_NOT_TAKEN_POS
    # Purpose: Branch if 5 >= 10 (Signed) -> False (Should Not Take)
    li x5, 5
    li x6, 10
    bge x5, x6, L_bge_nt_1     # Branch NOT Taken
    li x31, 2
    j L_bge_v_1
L_bge_nt_1:
    li x31, 1
L_bge_v_1:
    li x30, 2
    li x11, 1
    li x11, 0

## TEST: BGE_TAKEN_POS
    # Purpose: Branch if 10 >= 5 (Signed) -> True (Should Take)
    li x5, 10
    li x6, 5
    bge x5, x6, L_bge_t_1      # Branch TAKEN
    li x31, 2
    j L_bge_v_2
L_bge_t_1:
    li x31, 1
L_bge_v_2:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BGE_NOT_TAKEN_NEG_POS
    # Purpose: Branch if -5 >= 10 (Signed) -> False (Should Not Take)
    li x5, -5
    li x6, 10
    bge x5, x6, L_bge_nt_2     # Branch NOT Taken
    li x31, 2
    j L_bge_v_3
L_bge_nt_2:
    li x31, 1
L_bge_v_3:
    li x30, 2
    li x11, 1
    li x11, 0

## TEST: BGE_TAKEN_POS_NEG
    # Purpose: Branch if 10 >= -5 (Signed) -> True (Should Take)
    li x5, 10
    li x6, -5
    bge x5, x6, L_bge_t_2      # Branch TAKEN
    li x31, 2
    j L_bge_v_4
L_bge_t_2:
    li x31, 1
L_bge_v_4:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BGE_TAKEN_NEG_NEG
    # Purpose: Branch if -5 >= -10 (Signed) -> True (Should Take)
    li x5, -5
    li x6, -10
    bge x5, x6, L_bge_t_3      # Branch TAKEN
    li x31, 2
    j L_bge_v_5
L_bge_t_3:
    li x31, 1
L_bge_v_5:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BGE_TAKEN_EQUAL
    # Purpose: Branch if 5 >= 5 (Signed) -> True (Should Take)
    li x5, 5
    li x6, 5
    bge x5, x6, L_bge_t_4      # Branch TAKEN
    li x31, 2
    j L_bge_v_6
L_bge_t_4:
    li x31, 1
L_bge_v_6:
    li x30, 1
    li x11, 1
    li x11, 0

# -- BLTU Tests (Branch if Less Than, Unsigned) --
## TEST: BLTU_TAKEN_POS
    # Purpose: Branch if 5 < 10 (Unsigned) -> True (Should Take)
    li x5, 5
    li x6, 10
    bltu x5, x6, L_bltu_t_1    # Branch TAKEN
    li x31, 2
    j L_bltu_v_1
L_bltu_t_1:
    li x31, 1
L_bltu_v_1:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BLTU_NOT_TAKEN_POS
    # Purpose: Branch if 10 < 5 (Unsigned) -> False (Should Not Take)
    li x5, 10
    li x6, 5
    bltu x5, x6, L_bltu_nt_1   # Branch NOT Taken
    li x31, 2
    j L_bltu_v_2
L_bltu_nt_1:
    li x31, 1
L_bltu_v_2:
    li x30, 2
    li x11, 1
    li x11, 0

## TEST: BLTU_NOT_TAKEN_NEG_POS
    # Purpose: Branch if -5 (large unsigned) < 10 (small unsigned) -> False
    li x5, -5                  # 0xFF...FB
    li x6, 10
    bltu x5, x6, L_bltu_nt_2   # Branch NOT Taken
    li x31, 2
    j L_bltu_v_3
L_bltu_nt_2:
    li x31, 1
L_bltu_v_3:
    li x30, 2
    li x11, 1
    li x11, 0

## TEST: BLTU_TAKEN_POS_NEG
    # Purpose: Branch if 10 (small unsigned) < -5 (large unsigned) -> True
    li x5, 10
    li x6, -5                  # 0xFF...FB
    bltu x5, x6, L_bltu_t_2    # Branch TAKEN
    li x31, 2
    j L_bltu_v_4
L_bltu_t_2:
    li x31, 1
L_bltu_v_4:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BLTU_NOT_TAKEN_MAX_UNSIGNED
    # Purpose: Branch if -1 (max unsigned) < 10 -> False
    li x5, -1                  # 0xFF...FF
    li x6, 10
    bltu x5, x6, L_bltu_nt_3   # Branch NOT Taken
    li x31, 2
    j L_bltu_v_5
L_bltu_nt_3:
    li x31, 1
L_bltu_v_5:
    li x30, 2
    li x11, 1
    li x11, 0

# -- BGEU Tests (Branch if Greater Than or Equal, Unsigned) --
## TEST: BGEU_NOT_TAKEN_POS
    # Purpose: Branch if 5 >= 10 (Unsigned) -> False (Should Not Take)
    li x5, 5
    li x6, 10
    bgeu x5, x6, L_bgeu_nt_1   # Branch NOT Taken
    li x31, 2
    j L_bgeu_v_1
L_bgeu_nt_1:
    li x31, 1
L_bgeu_v_1:
    li x30, 2
    li x11, 1
    li x11, 0

## TEST: BGEU_TAKEN_POS
    # Purpose: Branch if 10 >= 5 (Unsigned) -> True (Should Take)
    li x5, 10
    li x6, 5
    bgeu x5, x6, L_bgeu_t_1    # Branch TAKEN
    li x31, 2
    j L_bgeu_v_2
L_bgeu_t_1:
    li x31, 1
L_bgeu_v_2:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BGEU_TAKEN_NEG_POS
    # Purpose: Branch if -5 (large unsigned) >= 10 (small unsigned) -> True
    li x5, -5                  # 0xFF...FB
    li x6, 10
    bgeu x5, x6, L_bgeu_t_2    # Branch TAKEN
    li x31, 2
    j L_bgeu_v_3
L_bgeu_t_2:
    li x31, 1
L_bgeu_v_3:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BGEU_NOT_TAKEN_POS_NEG
    # Purpose: Branch if 10 (small unsigned) >= -5 (large unsigned) -> False
    li x5, 10
    li x6, -5                  # 0xFF...FB
    bgeu x5, x6, L_bgeu_nt_2   # Branch NOT Taken
    li x31, 2
    j L_bgeu_v_4
L_bgeu_nt_2:
    li x31, 1
L_bgeu_v_4:
    li x30, 2
    li x11, 1
    li x11, 0

## TEST: BGEU_TAKEN_MAX_UNSIGNED
    # Purpose: Branch if -1 (max unsigned) >= 10 -> True
    li x5, -1                  # 0xFF...FF
    li x6, 10
    bgeu x5, x6, L_bgeu_t_3    # Branch TAKEN
    li x31, 2
    j L_bgeu_v_5
L_bgeu_t_3:
    li x31, 1
L_bgeu_v_5:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BGEU_TAKEN_EQUAL
    # Purpose: Branch if 5 >= 5 (Unsigned) -> True (Should Take)
    li x5, 5
    li x6, 5
    bgeu x5, x6, L_bgeu_t_4    # Branch TAKEN
    li x31, 2
    j L_bgeu_v_6
L_bgeu_t_4:
    li x31, 1
L_bgeu_v_6:
    li x30, 1
    li x11, 1
    li x11, 0
##--------------------------------------------
## Additional Branch Tests (Boundaries/Extremes) - RV64
##--------------------------------------------

# -- Signed Boundary Tests (BLT/BGE) --

## TEST: BLT_MAXPOS_VS_MINNEG
    # Purpose: Branch if MaxPos (0x7F...) < MinNeg (0x80...) -> Signed: False
    li x5, 0x7FFFFFFFFFFFFFFF
    li x6, 0x8000000000000000
    blt x5, x6, L_blt_t_4      # Branch NOT Taken (Signed: Positive is not less than Negative)
    li x31, 2                  # Path Not Taken Result = 2
    j L_blt_v_7
L_blt_t_4:
    li x31, 1                  # Path Taken Result = 1
L_blt_v_7:
    li x30, 2                  # Expected Result = 2
    li x11, 1
    li x11, 0

## TEST: BLT_MINNEG_VS_MAXPOS
    # Purpose: Branch if MinNeg (0x80...) < MaxPos (0x7F...) -> Signed: True
    li x5, 0x8000000000000000
    li x6, 0x7FFFFFFFFFFFFFFF
    blt x5, x6, L_blt_t_5      # Branch TAKEN (Signed: Negative is less than Positive)
    li x31, 2
    j L_blt_v_8
L_blt_t_5:
    li x31, 1
L_blt_v_8:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BGE_MAXPOS_VS_MINNEG
    # Purpose: Branch if MaxPos (0x7F...) >= MinNeg (0x80...) -> Signed: True
    li x5, 0x7FFFFFFFFFFFFFFF
    li x6, 0x8000000000000000
    bge x5, x6, L_bge_t_5      # Branch TAKEN (Signed: Positive is greater than Negative)
    li x31, 2
    j L_bge_v_7
L_bge_t_5:
    li x31, 1
L_bge_v_7:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BGE_MINNEG_VS_MAXPOS
    # Purpose: Branch if MinNeg (0x80...) >= MaxPos (0x7F...) -> Signed: False
    li x5, 0x8000000000000000
    li x6, 0x7FFFFFFFFFFFFFFF
    bge x5, x6, L_bge_nt_3     # Branch NOT Taken (Signed: Negative is not >= Positive)
    li x31, 2
    j L_bge_v_8
L_bge_nt_3:
    li x31, 1
L_bge_v_8:
    li x30, 2
    li x11, 1
    li x11, 0

## TEST: BLT_NEG_ONE_VS_ZERO
    # Purpose: Branch if -1 < 0 -> Signed: True
    li x5, -1
    li x6, 0
    blt x5, x6, L_blt_t_6      # Branch TAKEN
    li x31, 2
    j L_blt_v_9
L_blt_t_6:
    li x31, 1
L_blt_v_9:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BGE_NEG_ONE_VS_ZERO
    # Purpose: Branch if -1 >= 0 -> Signed: False
    li x5, -1
    li x6, 0
    bge x5, x6, L_bge_nt_4     # Branch NOT Taken
    li x31, 2
    j L_bge_v_10
L_bge_nt_4:
    li x31, 1
L_bge_v_10:
    li x30, 2
    li x11, 1
    li x11, 0

# -- Unsigned Boundary Tests (BLTU/BGEU) --

## TEST: BLTU_MAXPOS_VS_MINNEG
    # Purpose: Branch if MaxPos (0x7F...) < MinNeg (0x80...) -> Unsigned: True
    li x5, 0x7FFFFFFFFFFFFFFF
    li x6, 0x8000000000000000
    bltu x5, x6, L_bltu_t_3    # Branch TAKEN (Unsigned: 0x7F... is less than 0x80...)
    li x31, 2
    j L_bltu_v_6
L_bltu_t_3:
    li x31, 1
L_bltu_v_6:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BLTU_MINNEG_VS_MAXPOS
    # Purpose: Branch if MinNeg (0x80...) < MaxPos (0x7F...) -> Unsigned: False
    li x5, 0x8000000000000000
    li x6, 0x7FFFFFFFFFFFFFFF
    bltu x5, x6, L_bltu_nt_4   # Branch NOT Taken (Unsigned: 0x80... is not less than 0x7F...)
    li x31, 2
    j L_bltu_v_7
L_bltu_nt_4:
    li x31, 1
L_bltu_v_7:
    li x30, 2
    li x11, 1
    li x11, 0

## TEST: BGEU_MAXPOS_VS_MINNEG
    # Purpose: Branch if MaxPos (0x7F...) >= MinNeg (0x80...) -> Unsigned: False
    li x5, 0x7FFFFFFFFFFFFFFF
    li x6, 0x8000000000000000
    bgeu x5, x6, L_bgeu_nt_3   # Branch NOT Taken
    li x31, 2
    j L_bgeu_v_7
L_bgeu_nt_3:
    li x31, 1
L_bgeu_v_7:
    li x30, 2
    li x11, 1
    li x11, 0

## TEST: BGEU_MINNEG_VS_MAXPOS
    # Purpose: Branch if MinNeg (0x80...) >= MaxPos (0x7F...) -> Unsigned: True
    li x5, 0x8000000000000000
    li x6, 0x7FFFFFFFFFFFFFFF
    bgeu x5, x6, L_bgeu_t_5    # Branch TAKEN
    li x31, 2
    j L_bgeu_v_8
L_bgeu_t_5:
    li x31, 1
L_bgeu_v_8:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BLTU_NEG_ONE_VS_ZERO
    # Purpose: Branch if -1 (MaxUnsigned) < 0 -> Unsigned: False
    li x5, -1                  # 0xFF...FF
    li x6, 0
    bltu x5, x6, L_bltu_nt_5   # Branch NOT Taken
    li x31, 2
    j L_bltu_v_8
L_bltu_nt_5:
    li x31, 1
L_bltu_v_8:                 # Label typo fixed
    li x30, 2
    li x11, 1
    li x11, 0

## TEST: BGEU_NEG_ONE_VS_ZERO
    # Purpose: Branch if -1 (MaxUnsigned) >= 0 -> Unsigned: True
    li x5, -1                  # 0xFF...FF
    li x6, 0
    bgeu x5, x6, L_bgeu_t_6    # Branch TAKEN
    li x31, 2
    j L_bgeu_v_9
L_bgeu_t_6:
    li x31, 1
L_bgeu_v_9:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BLTU_MAXPOS_VS_NEG_ONE
    # Purpose: Branch if MaxPos (0x7F...) < -1 (MaxUnsigned) -> Unsigned: True
    li x5, 0x7FFFFFFFFFFFFFFF
    li x6, -1                  # 0xFF...FF
    bltu x5, x6, L_bltu_t_4    # Branch TAKEN
    li x31, 2
    j L_bltu_v_10
L_bltu_t_4:
    li x31, 1
L_bltu_v_10:
    li x30, 1
    li x11, 1
    li x11, 0

## TEST: BGEU_MAXPOS_VS_NEG_ONE
    # Purpose: Branch if MaxPos (0x7F...) >= -1 (MaxUnsigned) -> Unsigned: False
    li x5, 0x7FFFFFFFFFFFFFFF
    li x6, -1                  # 0xFF...FF
    bgeu x5, x6, L_bgeu_nt_4   # Branch NOT Taken
    li x31, 2
    j L_bgeu_v_11
L_bgeu_nt_4:
    li x31, 1
L_bgeu_v_11:
    li x30, 2
    li x11, 1
    li x11, 0

##--------------------------------------------
## End of Branch Tests
##--------------------------------------------
