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
