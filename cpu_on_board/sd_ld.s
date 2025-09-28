# full_extended_memory_timing_test.s (FINAL CORRECTED VERSION)
#
# A comprehensive test to diagnose SD/LD timing, checking for 0 to 6 cycles of delay.
# Writes to a safe RAM address (0x1800) generated with valid immediates.

.section .text
.globl _start

_start:
    # --- Setup ---
    # Set t0 to a safe memory address inside RAM: 0x1800
    lui t0, 0x1              # t0 = 0x1000
    addi t0, t0, 2047        # t0 = 0x1000 + 2047 = 0x17FF
    addi t0, t0, 1           # t0 = 0x17FF + 1 = 0x1800 (Correct Safe Address)

    # t1 will hold the test value to be stored.
    lui t1, 0x12345
    addi t1, t1, 0x678       # t1 = 0x12345678

    # --- Test 0: 0 NOPs ---
    sd t1, 0(t0)
    ld t2, 0(t0)
    beq t1, t2, pass_0_nops

    # --- Test 1: 1 NOP ---
    sd t1, 0(t0)
    addi x0, x0, 0
    ld t2, 0(t0)
    beq t1, t2, pass_1_nop

    # --- Test 2: 2 NOPs ---
    sd t1, 0(t0)
    addi x0, x0, 0
    addi x0, x0, 0
    ld t2, 0(t0)
    beq t1, t2, pass_2_nops

    # --- Test 3: 3 NOPs ---
    sd t1, 0(t0)
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    ld t2, 0(t0)
    beq t1, t2, pass_3_nops

    # --- Test 4: 4 NOPs ---
    sd t1, 0(t0)
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    ld t2, 0(t0)
    beq t1, t2, pass_4_nops

    # --- Test 5: 5 NOPs ---
    sd t1, 0(t0)
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    ld t2, 0(t0)
    beq t1, t2, pass_5_nops

    # --- Test 6: 6 NOPs ---
    sd t1, 0(t0)
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    ld t2, 0(t0)
    beq t1, t2, pass_6_nops

# --- Failure: All tests failed ---
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
pass_4_nops:
    addi a0, x0, 52          # ASCII for '4'
    jal x0, print_and_hang
pass_5_nops:
    addi a0, x0, 53          # ASCII for '5'
    jal x0, print_and_hang
pass_6_nops:
    addi a0, x0, 54          # ASCII for '6'
    jal x0, print_and_hang

# --- Utility Functions ---
print_and_hang:
    lui t5, 0x2
    sd  a0, 4(t5)
hang:
    jal x0, hang
