# jalr_test.s
# Goal: Prove a full subroutine call and return cycle using only
#       base instructions.
# This version uses NO pseudo-instructions for control flow.
# Uses: lui, addi, sd, jal, jalr
# Expected UART Output: "OK"

_start:
    # --- The Test ---
    # Manually perform a "call" using the JAL instruction.
    # This instruction is at address 0x0. It will jump to `my_subroutine`.
    # It MUST save the address of the NEXT line (0x4) into `ra` (x1).
    jal ra, my_subroutine

after_call:
    # --- Verification ---
    # The `jalr` in the subroutine should have jumped back here.
    
    # Print 'K' to signify a successful return.
    addi a0, x0, 75  # ASCII for 'K'
    lui  t1, 0x2
    sd   a0, 4(t1)
    
    # Use 'j' (jal x0, ...) for the final hang, which is fine.
    j hang

# --- The Subroutine ---
my_subroutine:
    # If the `jal` worked, we are now here.
    
    # Print 'O' to signify we entered the subroutine.
    addi a0, x0, 79  # ASCII for 'O'
    lui  t1, 0x2
    sd   a0, 4(t1)
    
    # --- Manually Return from Subroutine ---
    # This is the real instruction for `ret`.
    # It tells the CPU: "Jump to the address stored in register `ra` with an offset of 0.
    # Do not save a link, because the destination is `x0`."
    jalr x0, 0(ra)

# --- Infinite Loop ---
hang:
    j hang
