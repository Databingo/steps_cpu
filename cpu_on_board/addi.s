# Test ADDI: Calculates 2 + 3 = 5, prints '5' (ASCII 0x35)

# --- Test Logic ---
addi t0, x0, 2      # t0 = 2
addi t0, t0, 3      # t0 = t0 + 3 = 5

# --- Convert result to printable ASCII ---
# ASCII for '0' is 48 (0x30). We add this to our result.
addi a0, t0, 48     # a0 = 5 + 48 = 53 (ASCII for '5')

# --- Print the character in a0 to the UART ---
# Load the UART base address (0x2000) into t1
lui  t1, 0x2
# Store the character from a0 to the UART data register at address 0x2004
sd   a0, 4(t1)

# --- End of program ---
# Infinite loop to halt the CPU after the test is done.
hang:
    j hang
