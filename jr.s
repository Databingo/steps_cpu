_start:
    # Initialize registers (optional)
    li x5, 0
    li x6, 0
    li x7, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.
    # Current time: Sunday, April 20, 2025 at 7:57:11 AM PDT

##--------------------------------------------
## JALR (Jump and Link Register) Tests - RV64
## Using x31 as result indicator (path taken)
## Using x5 as rs1 (base address)
## Using x6, x7 as temps/link register
## Using x30 for Golden value
## Using x11 for Compare Signaling
##--------------------------------------------

## TEST: JALR_ZERO_OFFSET_SIMPLE
    # Purpose: Jump to target label address stored in x5 (Offset 0)
    # Target is label immediately following jump sequence
    j setup_jalr_zero_offset
target_jalr_zero_offset:
    li x31, 1                  # Set success value
    j verify_jalr_zero_offset
setup_jalr_zero_offset:
    auipc x5, 0                # x5 = PC of auipc (A)
    addi x5, x5, 12            # x5 = A + 12 = Address of target_jalr_zero_offset
                               # (Count: addi 4, jalr 4, li 4 -> 12 bytes)
    jalr x0, x5, 0             # Jump to address in x5 (Target)
    # --- Skipped code ---
    li x31, 999                # Error value
verify_jalr_zero_offset:
    li x30, 1                  # Expect 1 (target reached)
    li x11, 1
    li x11, 0

## TEST: JALR_POS_OFFSET_SHORT
    # Purpose: Jump to target using Base + Positive Offset. rd=x0.
    # Target is label immediately following jump sequence.
    j setup_jalr_pos_offset
target_jalr_pos_offset:        # PC = T
    li x31, 2                  # Set success value
    j verify_jalr_pos_offset
setup_jalr_pos_offset:
    # Set base x5 = Target Address - 8
    auipc x5, 0                # x5 = PC of auipc (A)
    addi x5, x5, 4             # x5 = A + 4 = Target - 8
                               # (Count: addi 4, jalr 4, li 4, j 4 -> 16 bytes to target)
    jalr x0, x5, 8             # Jump to x5 + 8 = (Target-8)+8 = Target
    # --- Skipped code ---
    li x31, 888                # Error value
verify_jalr_pos_offset:
    li x30, 2                  # Expect 2 (target reached)
    li x11, 1
    li x11, 0

## TEST: JALR_NEG_OFFSET_SHORT
    # Purpose: Jump back to target using Base + Negative Offset. rd=x0.
    # Target label precedes setup code.
    j setup_jalr_neg_offset    # Jump over target first
target_jalr_neg_offset:        # PC = T
    li x31, 3                  # Success indicator
    j verify_jalr_neg_offset
setup_jalr_neg_offset:         # PC = T + 8 (approx)
    # Set base x5 = Target Address + 12
    auipc x5, 0                # x5 = PC of auipc (A = approx T+8)
    # Target is 2 instructions (8 bytes) before auipc. Target = A - 8.
    # Base needs to be T + 12 = (A-8) + 12 = A + 4
    addi x5, x5, 4             # x5 = A + 4
    # Jump target = Base + Offset = (A+4) + (-12) = A - 8 = Target
    jalr x0, x5, -12           # Jump back to Target
    # --- Skipped code ---
    li x31, 777                # Error value
verify_jalr_neg_offset:
    li x30, 3                  # Expect 3 (target reached)
    li x11, 1
    li x11, 0

## TEST: JALR_LINK_SAVE_SIMPLE
    # Purpose: Test saving link register (rd=x7). Verify target reached.
    # Target is label immediately following jump sequence.
    j setup_jalr_link
target_jalr_link:              # PC = T
    li x31, 4                  # Set success value
    # Now attempt return using saved link register x7
    # Note: Value in x7 will be address of the 'li x31, 666' line
    jalr x0, x7, 0             # Return jump using x7
    # --- Code skipped if ret works ---
    li x31, 555
setup_jalr_link:
    auipc x6, 0                # x6 = PC of auipc (A)
    addi x6, x6, 16            # x6 = A + 16 = Address of target_jalr_link
                               # (Count: addi 4, jalr 4, li 4, j 4 -> 16 bytes)
    jalr x7, x6, 0             # Jump to Target, SAVE PC+4 in x7
    # --- Code jumped over, but execution returns here after target runs 'ret' ---
    li x31, 44                 # Set value *after* return. Overwrites the 4 set at target.
    j verify_jalr_link
    # --- Code skipped if ret fails to return here ---
    li x31, 666
verify_jalr_link:
    li x30, 44                 # Expect 44 if target reached AND return worked
    li x11, 1
    li x11, 0

## TEST: JALR_LSB_CLEARING_SIMPLE
    # Purpose: Test LSB clearing. Jump target = Base + 1 (Odd), should land at Base (Even).
    # Target label follows immediately.
    j setup_jalr_lsb
target_jalr_lsb:               # PC = T (Assume Even)
    li x31, 5                  # Success indicator
    j verify_jalr_lsb
setup_jalr_lsb:
    # Set base x5 = Target address - 1 (ODD address)
    auipc x5, 0                # x5 = PC of auipc (A)
    addi x5, x5, 11            # x5 = A + 11 = Target - 1 (Odd)
                               # (Count: addi 4, jalr 4, li 4 = 12 bytes to Target)
    jalr x0, x5, 1             # Jump target = (x5+1)&~1 = ((T-1)+1)&~1 = T&~1 = T
    # --- Skipped code ---
    li x31, 333                # Error indicator
verify_jalr_lsb:
    li x30, 5                  # Expect 5 (target reached)
    li x11, 1
    li x11, 0


##--------------------------------------------
## End of JALR Tests
##--------------------------------------------
