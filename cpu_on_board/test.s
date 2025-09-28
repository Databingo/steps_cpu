# core_test.s (Minimal Version - CORRECTED)
#
# A minimal, sequential test for the core instruction set using only
# basic assembler syntax.
# If a test fails, it prints the test number (1-8). If all pass, it prints 'P'.

.section .text
.globl _start

_start:
    # --- Test 1: ADDI (Add Immediate) ---
    # Setup values. Verification happens in Test 3.
    addi t0, x0, 15      # t0 = 15
    addi t1, t0, -5      # t1 should be 10
    addi t2, x0, 10      # t2 = 10 (expected value for t1)

    # --- Test 2: SLT (Set on Less Than) ---
    # Setup values. Verification happens in Test 3.
    addi t0, x0, -1      # t0 = -1
    addi t1, x0, 1       # t1 = 1
    slt  t2, t0, t1      # t2 should be 1, because -1 < 1
    addi t3, x0, 1       # t3 = 1 (expected value for t2)

    # --- Test 3: BEQ (Branch if Equal) ---
    # Test 3.1: Verify ADDI from Test 1. (10 == 10)
    addi a0, x0, 1          # Load fail code '1' for ADDI
    beq  t1, t2, skip_fail_1 # If equal (pass), skip the fail jump.
    jal  x0, fail_handler    # If not equal (fail), jump to handler.
skip_fail_1:

    # Test 3.2: Verify SLT from Test 2. (1 == 1)
    addi a0, x0, 2          # Load fail code '2' for SLT
    beq  t2, t3, skip_fail_2 # If equal (pass), skip the fail jump.
    jal  x0, fail_handler    # If not equal (fail), jump to handler.
skip_fail_2:

    # Test 3.3: A BEQ that should NOT be taken. (5 == 10)
    addi t0, x0, 5
    addi t1, x0, 10
    addi a0, x0, 3          # Load fail code '3' for BEQ
    beq  t0, t1, fail_handler # This should NOT branch. If it does, BEQ failed.

    # --- Test 4: LUI (Load Upper Immediate) ---
    lui  t0, 0xABCDE         # t0 = 0xABCDE000
    lui  t1, 0xABCDD
    addi t1, t1, 0x1000      # t1 = 0xABCDD000 + 0x1000 = 0xABCDE000
    addi a0, x0, 4           # Load fail code '4'
    beq  t0, t1, skip_fail_4  # If equal (pass), skip the fail jump.
    jal  x0, fail_handler     # If not equal (fail), jump to handler.
skip_fail_4:

    # --- Test 5: JAL (Jump and Link) ---
    # Jump to `jal_target`. `ra` will store the address of the next line.
    jal  ra, jal_target
    # This code is skipped if JAL works. If it runs, the test fails.
    addi a0, x0, 5
    jal  x0, fail_handler
jal_target:
    # JAL successfully jumped here. The next test will use `ra` to return.

    # --- Test 6: JALR (Jump and Link Register) ---
    # Return from the JAL call. This tests `jalr rd, 0(rs1)`.
    # It jumps to the address stored in `ra`. We land right after the `jal ra, jal_target` line.
    jalr x0, 0(ra)
    # This code should never be reached.
    addi a0, x0, 6
    jal  x0, fail_handler

    # --- Test 7: AUIPC (Add Upper Immediate to PC) ---
auipc_test:
    auipc t0, 0          # t0 = address of this `auipc` instruction
    # Jump forward 16 bytes (4 instructions) from the `auipc`'s address.
    # This will skip the next 3 instructions and land at the label.
    jalr  x0, 16(t0)
    # The next 3 lines must be skipped.
    addi a0, x0, 7
    jal  x0, fail_handler
auipc_land_here:
    # Success if we land here.

    # --- Test 8: SD and LD (Store and Load Doubleword) ---
    # Use hardcoded address 0x1000 for storage.
    lui   t0, 0x1             # t0 = 0x1000
    lui   t1, 0xCAFFE         # Create a test value: 0xCAFFE000...
    addi  t1, t1, 0xBABE      # ...now it's 0xCAFFEBABE
    sd    t1, 0(t0)           # Store the value to memory address 0x1000
    ld    t2, 0(t0)           # Load it back from memory
    addi  a0, x0, 8
    beq   t1, t2, skip_fail_8 # If equal (pass), skip the fail jump.
    jal   x0, fail_handler    # If not equal (fail), jump to handler.
skip_fail_8:

# --- All Tests Passed ---
# If execution reaches here, all tests were successful.
pass:
    addi a0, x0, 80      # Load ASCII for 'P'
    jal  x0, print_and_hang

# --- Failure Handling ---
fail_handler:
    # The failing test number is already in register a0.
    # Convert number to printable ASCII char (1 -> '1', 2 -> '2', etc.)
    addi a0, a0, 48

print_and_hang:
    lui t5, 0x2          # t5 = 0x2000
    sd  a0, 4(t5)        # Store character in a0 to UART at 0x2004

hang:
    jal x0, hang

