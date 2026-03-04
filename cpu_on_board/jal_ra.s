# jal_ra_direct_print_test.s
# Goal: Prove that 'jal' saves the correct return address (0x4) into 'ra'
#       by directly printing its value.
# Uses ONLY: lui, addi, sd, jal (as j)
# Expected UART Output: '4'

_start:
    # --- The Test ---
    # `jal` is at address 0x0. It will call the subroutine.
    # It must save the address of the NEXT line (which is 0x4) into `ra` (x1).
    jal ra, my_subroutine
    
    # This part of the code should never be reached if the test is designed correctly,
    # because the subroutine will end in an infinite loop. We put a loop here too
    # just in case.
    j hang_main 

# --- The Subroutine ---
my_subroutine:
    # If the jump part of `jal` worked, we are now here.
    
    # --- The Verification ---
    # The value of `ra` should be 4. Let's make it printable.
    # ASCII '0' is 48.
    addi a0, ra, 48     # a0 = 4 + 48 = 52 (which is the ASCII for '4')
    
    # --- Print the character in a0 ---
    lui  t1, 0x2        # t1 = 0x2000 (UART Base Address)
    sd   a0, 4(t1)      # memory[0x2004] = a0 (Print the character '4')
    
    # End of test. Go into an infinite loop.
hang_sub:
    j hang_sub

# --- Infinite Loops (to halt the CPU) ---
hang_main:
    j hang_main
