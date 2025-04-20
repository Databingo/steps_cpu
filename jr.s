_start:
    # Initialize registers (optional)
    li x5, 0
    li x6, 0
    li x7, 0 # Used as a temp link register

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.
    # Current time: Sunday, April 20, 2025 at 8:07 AM PDT

##--------------------------------------------
## JALR (Jump and Link Register) Tests - RV64
## Using x31 as result indicator (path taken)
## Using x5 as rs1 (base address)
## Using x6 as temp, x7 as temp link reg (rd)
## Using x30 for Golden value
## Using x11 for Compare Signaling
## Relies on working AUIPC, ADDI, LI, JAL/J
##--------------------------------------------

## TEST: JALR_ZERO_OFFSET
    # Purpose: Jump to target address stored in x5 (Offset 0), discard link (rd=x0)
    # Target label follows jump sequence immediately.
    j setup_jalr_zero_offset    # Jump over target to setup
target_jalr_zero_offset:
    li x31, 1                   # Path Taken Code: Set success value
    j verify_jalr_zero_offset  # Jump to verification
setup_jalr_zero_offset:
    auipc x5, 0                 # x5 = PC of auipc (A)
    # Target is at A - 8 bytes (addi, jalr back)
    addi x5, x5, -8             # x5 = Address of target_jalr_zero_offset 
    jalr x0, x5, 0              # Jump to address in x5 (Target)运气to li.2(addi xori)
    # --- Skipped code ---
    li x31, 999                 # Error value if fall through
verify_jalr_zero_offset:
    li x30, 1                   # Expect 1 (target reached)
    li x11, 1
    li x11, 0

## TEST: JALR_POS_OFFSET
    # Purpose: Jump to target using Base + Positive Offset. rd=x0.
    # Target label follows jump sequence immediately.
    j setup_jalr_pos_offset
target_jalr_pos_offset:         # PC = T
    li x31, 2                   # Path Taken Code: Set success value
    j verify_jalr_pos_offset
setup_jalr_pos_offset:          # PC = T+8 (approx)
    # Set base x5 = Target Address - 12
    auipc x5, 0                 # x5 = PC of auipc (A = approx T+8)
    # Target is at A - 8 bytes. Base needs to be Target - 12 = A - 8 - 12 = A - 20
    addi x5, x5, -20            # x5 = A - 20
    # Jump target = Base + Offset = (A-20) + 12 = A - 8 = Target
    jalr x0, x5, 12             # Use positive offset 12
    # --- Skipped code ---
    li x31, 888                 # Error value
verify_jalr_pos_offset:
    li x30, 2                   # Expect 2 (target reached)
    li x11, 1
    li x11, 0

## TEST: JALR_NEG_OFFSET
    # Purpose: Jump back to target using Base + Negative Offset. rd=x0.
    # Target label precedes setup code.
    j setup_jalr_neg_offset     # Jump over target first
target_jalr_neg_offset:         # PC = T
    li x31, 3                   # Path Taken Code: Success indicator
    j verify_jalr_neg_offset
setup_jalr_neg_offset:          # PC = T + 8 (approx)
    # Set base x5 = Target Address + 12
    auipc x5, 0                 # x5 = PC of auipc (A = approx T+8)
    # Target is at A - 8 bytes. Base needs to be Target + 12 = (A-8) + 12 = A + 4
    addi x5, x5, 4              # x5 = A + 4
    # Jump target = Base + Offset = (A+4) + (-12) = A - 8 = Target
    jalr x0, x5, -12            # Use negative offset -12
    # --- Skipped Code ---
    li x31, 777                 # Error value
verify_jalr_neg_offset:
    li x30, 3                   # Expect 3 (target reached)
    li x11, 1
    li x11, 0

## TEST: JALR_LINK_SAVE_RET
    # Purpose: Test rd != x0 (save link) and subsequent return.
    # Setup target address
    j setup_jalr_link_ret
target_jalr_link_ret:           # PC = T
    # Code at function target
    addi x7, x7, 1              # Modify x7 just to show work
    jalr x0, ra, 0              # RETURN using link register 'ra' (x1)
    # Code below ret should not execute
    li x31, 555
setup_jalr_link_ret:
    # Calculate target address
    auipc x5, 0                 # x5 = PC of auipc (A)
    addi x5, x5, 16             # x5 = A + 16 = Address of target_jalr_link_ret
                                # (Count: addi 4, jalr 4, li 4, j 4 -> 16 bytes)
    # Call function, save return address in ra (x1)
    jalr ra, x5, 0
    # --- Code executed AFTER successful return ---
    li x31, 4                   # If return worked, we land here.
    j verify_jalr_link_ret
    # --- Code skipped if return fails ---
    li x31, 666
verify_jalr_link_ret:
    li x30, 4                   # Expect 4 if jump and return worked
    li x11, 1
    li x11, 0

## TEST: JALR_LSB_CLEARING
    # Purpose: Test that jalr clears the LSB of the calculated target address
    # Target label follows jump sequence immediately.
    j setup_jalr_lsb
target_jalr_lsb:                # PC = T (Assume Even)
    li x31, 5                   # Path Taken Code: Success indicator
    j verify_jalr_lsb
setup_jalr_lsb:
    # Set base x5 = Target Address - 1 (ODD address)
    auipc x6, 0                 # x6 = PC of auipc (A)
    addi x6, x6, 16             # x6 = A + 16 = Address of target_jalr_lsb
                                # (Count: addi 4, jalr 4, li 4, j 4 -> 16 bytes)
    addi x5, x6, -1             # x5 = Target - 1 (Odd Address)
    # Jump using x5+1. Target = (x5+1)&~1 = ((Target-1)+1)&~1 = Target&~1 = Target
    jalr x0, x5, 1              # Calculated Target = Target(Even)+1=Odd. Should jump to Target(Even).
    # --- Skipped code ---
    li x31, 333                 # Error indicator
verify_jalr_lsb:
    li x30, 5                   # Expect 5 (target reached)
    li x11, 1
    li x11, 0


##--------------------------------------------
## End of JALR Tests
##--------------------------------------------
