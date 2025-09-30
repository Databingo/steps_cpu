# RISC-V Assembly Example: Basic Function Call with Stack Usage

.section .text
.globl _start

_start:
    # --- Setup Phase (in the 'main' function) ---
    # 1. Initialize the stack pointer.
    #    Let's put the stack at the top of a small RAM region, e.g., 0x1800.
    li sp, 0x1800

    # 2. Set up the argument for our function call.
    #    We want to calculate add_five(5).
    li a0, 5        # Put the argument (5) into the first argument register, a0.

    # 3. Call the function.
    #    'jal ra, add_five' does two things:
    #       a) Puts the address of the NEXT instruction (the 'add a0, a0, x0' line) into 'ra'.
    #       b) Jumps to the 'add_five' label.
    jal ra, add_five

    # 5. We are now back from the function call.
    #    The result is in a0. We'll just hold it here.
    #    (In a real program, we would use it or store it somewhere).
    nop             # The return value is now in a0. a0 should be 10.

done:
    j done          # Infinite loop to end the program.


# --------------------------------------------------------------------------
# Function: add_five
#   - Takes one argument in a0.
#   - Adds 5 to it.
#   - Returns the result in a0.
# --------------------------------------------------------------------------
add_five:
    # --- Function Prologue: Setting up the stack frame ---
    # Reserve space on the stack for 1 item (the return address).
    # Since we are using 64-bit registers, one item is 8 bytes.
    # The stack grows downwards, so we subtract from sp.
    addi sp, sp, -8     # sp now points to 0x17F8. We have a frame of 8 bytes.

    # Save the return address ('ra') to our stack frame.
    # 'ra' currently holds the address of the 'nop' instruction in _start.
    # We must save it so we don't lose our way back.
    sd ra, 0(sp)        # Store the value of 'ra' at the address pointed to by sp.

    # --- Function Body: The actual work ---
    addi a0, a0, 5      # a0 = a0 + 5. (5 + 5 = 10). The result is now in a0.

    # --- Function Epilogue: Tearing down the stack frame ---
    # Restore the original return address from our stack frame back into 'ra'.
    ld ra, 0(sp)        # Load the value from address sp back into the 'ra' register.

    # Deallocate our stack frame by moving the stack pointer back up.
    addi sp, sp, 8      # sp is now back at 0x1800.

    # Return to the caller.
    # 'ret' is a pseudo-instruction for 'jalr x0, ra, 0'.
    # It jumps to the address we just restored into 'ra'.
    ret
