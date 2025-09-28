# extended_memory_timing_test.s
#
# An extended test to diagnose the timing of SD/LD instructions.
# It checks for delays of 0 to 6 cycles.
#
# The program will print one of the following characters to UART (0x2004):
# '0'-'6' -> The number of NOPs required for success.
# 'F'     -> The test failed even with 6 NOPs, indicating a functional bug.

.section .text
.globl _start

_start:
    # --- Setup ---
    lui t0, 0x1              # t0 = 0x1000 (Memory Address)
    lui t1, 0x12345          # t1 = 0x12345000
    addi t1, t1, 0x678       # t1 = 0x12345678 (Test Value)

    # --- Test 0: 0 NOPs ---
    sd t1, 0(t0)
    ld t2, 0(t0)
    beq t1, t2, pass_0_nops

    # --- Test 1: 1 NOP ---
    sd t1, 0(t0)
    addi x0, x0, 0           # NOP
    ld t2, 0(t0)
    beq t1, t2, pass_1_nop

    # --- Test 2: 2 NOPs ---
    sd t1, 0(t0)
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP
    ld t2, 0(t0)
    beq t1, t2, pass_2_nops

    # --- Test 3: 3 NOPs ---
    sd t1, 0(t0)
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP
    ld t2, 0(t0)
    beq t1, t2, pass_3_nops

    # --- Test 4: 4 NOPs ---
    sd t1, 0(t0)
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP
    ld t2, 0(t0)
    beq t1, t2, pass_4_nops

    # --- Test 5: 5 NOPs ---
    sd t1, 0(t0)
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP
    ld t2, 0(t0)
    beq t1, t2, pass_5_nops

    # --- Test 6: 6 NOPs ---
    sd t1, 0(t0)
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP
    addi x0, x0, 0           # NOP
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
