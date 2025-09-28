# memory_timing_test.s
#
# A dedicated test to diagnose the timing of SD (store) and LD (load) instructions.
# It determines the number of delay cycles (NOPs) needed between a store
# and a load to the same address.
#
# The program will print one of the following characters to UART (0x2004):
# '0' -> Success with 0 NOPs (immediate read-after-write works).
# '1' -> Success with 1 NOP. (This is the most common expected result).
# '2' -> Success with 2 NOPs.
# '3' -> Success with 3 NOPs.
# 'F' -> The test failed even with 3 NOPs, indicating a non-timing-related bug.

.section .text
.globl _start

_start:
    # --- Setup ---
    # t0 will hold the memory address.
    lui t0, 0x1              # t0 = 0x1000

    # t1 will hold the test value to be stored.
    # We construct 0x12345678.
    lui t1, 0x12345          # t1 = 0x12345000
    addi t1, t1, 0x678       # t1 = 0x12345678 (0x678 is a valid 12-bit immediate)

    # t2 will be used to load the value back.

    # --- Test 0: 0 NOPs ---
    # The failing case from the previous test.
    sd t1, 0(t0)             # Store the value
    ld t2, 0(t0)             # Load it back immediately
    beq t1, t2, pass_0_nops  # If it matches, we are done.

    # --- Test 1: 1 NOP ---
    # Store, wait one cycle, then load.
    sd t1, 0(t0)             # Store the value
    addi x0, x0, 0           # NOP (1 cycle delay)
    ld t2, 0(t0)             # Load it back
    beq t1, t2, pass_1_nop   # If it matches, we are done.

    # --- Test 2: 2 NOPs ---
    # Store, wait two cycles, then load.
    sd t1, 0(t0)             # Store the value
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP (2 cycles delay)
    ld t2, 0(t0)             # Load it back
    beq t1, t2, pass_2_nops  # If it matches, we are done.

    # --- Test 3: 3 NOPs ---
    # Store, wait three cycles, then load.
    sd t1, 0(t0)             # Store the value
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP (3 cycles delay)
    ld t2, 0(t0)             # Load it back
    beq t1, t2, pass_3_nops  # If it matches, we are done.

# --- Failure: All tests failed ---
# If execution falls through to here, none of the tests worked.
fail_all:
    addi a0, x0, 70          # ASCII for 'F'
    jal x0, print_and_hang

# --- Success Handlers ---
pass_0_nops:
    addi a0, x0, 48          # ASCII for '0'
    jal x0, print_and_hang

pass_1_nop:
    addi a0, x0, 49          # ASCII for '1'
    jal x0, print_and_hang

pass_2_nops:
    addi a0, x0, 50          # ASCII for '2'
    jal x0, print_and_hang

pass_3_nops:
    addi a0, x0, 51          # ASCII for '3'
    jal x0, print_and_hang


# --- Utility Functions ---
print_and_hang:
    lui t5, 0x2              # t5 = 0x2000
    sd  a0, 4(t5)            # Store result character to UART at 0x2004

hang:
    jal x0, hang             # Infinite loop
