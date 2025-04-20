_start:
    # Initialize registers (optional)
    li x5, 0

    # Test sequence starts here.
    # Assumes an external harness monitors x11 and compares x31 vs x30 when x11 becomes 1.
    # Current time: Sunday, April 20, 2025 at 5:51 AM PDT

##--------------------------------------------
## JAL / JALR Tests - RV64
## Using x31 as result indicator (path taken)
## Using x5 as rs1 for JALR base address
## Using x30 for Golden value
## Using x11 for Compare Signaling
##--------------------------------------------

# -- JAL Tests (PC-Relative Jump) --

## TEST: JAL_FORWARD
    # Purpose: Test jumping forward to a label, discarding return address (rd=x0)
    jal x0, L_jal_fwd_target   # Jump forward
    # --- Code that should be skipped ---
    li x31, 999                # Error indicator if jump fails
    j L_jal_fwd_verify         # Skip target code if this runs
L_jal_fwd_target:
    # --- Target Code ---
    li x31, 1                  # Success indicator for reaching target
L_jal_fwd_verify:
    # --- Verification ---
    li x30, 1                  # Expect 1 (target reached)
    li x11, 1
    li x11, 0

## TEST: JAL_BACKWARD
    # Purpose: Test jumping backward to a label, discarding return address (rd=x0)
    j L_jal_back_setup         # Jump forward to setup first
L_jal_back_target:
    # --- Target Code ---
    li x31, 2                  # Success indicator
    j L_jal_back_verify        # Jump to verification
L_jal_back_setup:
    # --- Setup and Jump ---
    jal x0, L_jal_back_target  # Jump backward
    # --- Code that should be skipped ---
    li x31, 888                # Error indicator
    # Fall through to verification is okay here, but x31 should be 2
L_jal_back_verify:
    # --- Verification ---
    li x30, 2                  # Expect 2 (target reached)
    li x11, 1
    li x11, 0

## TEST: JAL_LINK_SAVE
    # Purpose: Test jumping forward, saving return address (PC+4) in x7
    # We primarily verify the jump target here.
    jal x7, L_jal_link_target  # Jump forward, save PC+4 to x7
    # --- Code that is jumped over (would be returned to if using x7 later) ---
    li x31, 777
    j L_jal_link_verify
L_jal_link_target:
    # --- Target Code ---
    li x31, 3                  # Success indicator for reaching target
L_jal_link_verify:
    # --- Verification ---
    li x30, 3                  # Expect 3 (target reached)
    li x11, 1
    li x11, 0

# -- JALR Tests (Register-Indirect Jump) --

## TEST: JALR_ZERO_OFFSET
    # Purpose: Jump to address in x5 + 0 offset. rd=x0.
    # Setup target address in x5 using AUIPC/ADDI for label L_jalr_target_1
    auipc x5, 0                # x5 = PC of auipc
    addi x5, x5, 20            # x5 = PC + 20 = Address of L_jalr_target_1 (jalr=4, li=4, j=4, li=4 -> total 16 to skip)
    jalr x0, x5, 0             # Jump to address in x5
    # --- Code that should be skipped ---
    li x31, 666
    j L_jalr_zero_verify
L_jalr_target_1:
    li x31, 4                  # Success indicator
L_jalr_zero_verify:
    li x30, 4
    li x11, 1
    li x11, 0

## TEST: JALR_POS_OFFSET
    # Purpose: Jump to address in x5 + positive offset. rd=x0.
    # Setup target address base = PC+8, Target = PC+24, Offset = +16
    auipc x5, 0                # x5 = PC of auipc (A)
    addi x5, x5, 8             # x5 = A + 8 (Base address for jump)
                               # Target label L_jalr_target_2 is at A + 24
    jalr x0, x5, 16            # Jump to x5 + 16 = (A+8)+16 = A+24 (target)
    # --- Code that should be skipped ---
    li x31, 555
    j L_jalr_pos_verify
L_jalr_target_2:               # Label expected at A + 24
    li x31, 5                  # Success indicator
L_jalr_pos_verify:
    li x30, 5
    li x11, 1
    li x11, 0

## TEST: JALR_NEG_OFFSET
    # Purpose: Jump to address in x5 + negative offset. rd=x0.
    # Target label defined first, then code jumps back to it.
    j L_jalr_neg_setup_2       # Jump forward to the setup code first

L_jalr_neg_target_2:           # Target Label: Execution should land here. PC = T
    li x31, 6                  # Success indicator code at target
    j L_jalr_neg_verify_2      # Jump to verification

L_jalr_neg_setup_2:
    # Setup base register x5 to point PAST the target label.
    # We know L_jalr_neg_target_2 is a few instructions behind the current PC.
    # Let's set x5 to PC + 8 (address of the 'j' instruction after jalr)
    auipc x5, 0                # x5 = PC of auipc (A)
    addi x5, x5, 12            # x5 = A + 12 (Points 4 bytes past the jalr instruction)
                               # Target L_jalr_neg_target_2 is at A - 8 (roughly, counting back 2 instructions)
                               # So we need offset = (A-8) - (A+12) = -20
    jalr x0, x5, -20           # Jump target = (A+12) - 20 = A - 8 (Should hit the label)
    # --- Code Skipped if jump is successful ---
    li x31, 444                # Error indicator if fall-through
L_jalr_neg_verify_2:
    # --- Verification ---
    li x30, 6                  # Expect 6 from target path
    li x11, 1
    li x11, 0
## TEST: JALR_RET_PSEUDO
    # Purpose: Test function call and return using jal and ret (jalr x0, ra, 0)
    jal ra, sub_function       # Call sub_function, ra = PC + 4 (address of next li x31)
    li x31, 7                  # Should execute AFTER return, x31 indicates successful return
    j L_jalr_ret_verify        # Go to verification
sub_function:
    # --- Function Code ---
    addi x7, x0, 123           # Dummy work
    ret                        # Pseudo-instruction for jalr x0, ra, 0
    # --- Code that should be skipped ---
    li x31, 333                # Error indicator
L_jalr_ret_verify:
    li x30, 7                  # Expect 7 if return worked
    li x11, 1
    li x11, 0

## TEST: JALR_LSB_CLEARING
    # Purpose: Test that jalr clears the LSB of the target address
    # Get address of target label into x6
    auipc x6, 0                # x6 = PC of auipc (A)
    addi x6, x6, 24            # x6 = A + 24 = Approx address of L_jalr_lsb_target_GOOD
                               # Verify offset: addi(4)+jalr(4)+li(4)+j(4)+li(4)=20 bytes to label
                               # Need offset of 20
    addi x6, x6, -4            # Correct offset: x6 = A + 20 = Address of L_jalr_lsb_target_GOOD
    # Set base register x5 to target address MINUS 1 (an odd number)
    addi x5, x6, -1            # x5 = Target - 1 (Odd Address)
    # Jump using x5+1. Target = (Target-1)+1 = Target. LSB clear ensures jump to Target (even).
    jalr x0, x5, 1
    # --- Code skipped if jump successful ---
    li x31, 99                 # Error indicator
    j L_jalr_lsb_verify_2
L_jalr_lsb_target_GOOD:        # Expected Target (Address = A + 20)
    # --- Target Code ---
    li x31, 8                  # Success indicator
L_jalr_lsb_verify_2:
    li x30, 8                  # Expected Result = 8
    li x11, 1
    li x11, 0
    # REMOVED .align 3


##--------------------------------------------
## End of JAL/JALR Tests
##--------------------------------------------
