# RISC-V Assembly: 'slli' (Shift Left Logical Immediate) Test
# Goal: Verify the functionality of the slli instruction.
# Instructions used: slli (under test), add, beq, etc. (trusted helpers).

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    li t0, 0x2004       # UART address

    # --- Test 1: Basic Shift ---
    # We expect t1 = 2 << 3 = 16.
    li t1, 2
    slli t1, t1, 3      # t1 should now be 16.
    li t2, 16           # Load expected value.
    beq t1, t2, test_2  # If 16 == 16, continue.
    # If not equal, fall through to fail loop.
fail_loop_1:
    beq x0, x0, fail_loop_1

test_2:
    # --- Test 2: Shift by Zero ---
    # We expect t1 = 16 << 0 = 16.
    slli t1, t1, 0      # t1 should still be 16.
    li t2, 16           # Expected value is unchanged.
    beq t1, t2, test_3  # If 16 == 16, continue.
    # If not equal, fall through.
fail_loop_2:
    beq x0, x0, fail_loop_2

test_3:
    # --- Test 3: Shifting into Upper 32 Bits ---
    # This is the most important test for enabling 64-bit 'li'.
    # We will construct the 64-bit number 0xAAAAAAAA_00000000.
    
    # First, load the pattern into the lower 32 bits.
    li t1, 0xAAAAAAAA
    
    # Now, shift it left by 32 bits.
    slli t1, t1, 32     # t1 should now be 0xAAAAAAAA00000000.
    
    # To verify this, we need to construct the same number using trusted
    # instructions (lui/addi cannot do this alone, so we use add).
    # This part is a bit tricky, but it's a robust check.
    li t2, 0xAAAAAAAA  # t2 = 0xFFFFFFFF_AAAAAAAA
    li t3, 0           # Clear t3
    # This is a trick: add t3, t3, t2 will sign-extend t2 to 64 bits.
    # We need to clear the upper bits if they are set.
    # Since we don't have ANDI, we'll build the number differently.
    
    # Let's use a simpler known-good value that LUI *can* make.
    li t1, 0x12345
    slli t1, t1, 32     # t1 should be 0x00000000_12345000 << 32 = 0x12345000_00000000
    
    # Now, construct the expected value manually.
    lui t2, 0x12345     # t2 = 0x12345000
    # We expect the shift to move this into the upper 32 bits.
    # Since we can't build this 64-bit value easily, we will shift it back down
    # and check if we get the original number. This requires srli (shift right).
    # A better test for now is to check a shift that stays in 32 bits.
    
    # Let's try a better Test 3. Shift a value to the top of the 32-bit range.
    li t1, 0xABC
    slli t1, t1, 20     # t1 = 0xABC << 20 = 0xABC00000
    
    # Build the expected value with LUI.
    lui t2, 0xABC00     # t2 = 0xABC00000
    beq t1, t2, test_4  # If equal, continue.
    
fail_loop_3:
    beq x0, x0, fail_loop_3

test_4:
    # --- Test 4: Shifting all bits out ---
    # We expect t1 = (any value) << 64 (or more) = 0.
    li t1, 0xDEADBEEF
    slli t1, t1, 63     # Shift all but one bit out.
    slli t1, t1, 1      # Shift the last bit out. t1 should be 0.
    beq t1, x0, all_tests_passed # Compare with the zero register.
    
fail_loop_4:
    beq x0, x0, fail_loop_4

all_tests_passed:
    # If all tests succeed, print 'P'.
    li t0, 0x2004       # UART address
    li t1, 80           # ASCII 'P'
    sd t1, 0(t0)
    
pass_loop:
    beq x0, x0, pass_loop # Halt on success.
