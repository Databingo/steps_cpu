# jal_test.s
# Goal: Print "OK"

jal ra, test_passed  # Jump to the label, saving return address in ra

# This code should be SKIPPED. Print 'F' for Fail if it runs.
addi a0, x0, 70  # ASCII for 'F'
lui t1, 0x2
sd a0, 4(t1)
j hang

test_passed:
    # If the jump was successful, we land here.
    addi a0, x0, 79  # ASCII for 'O'
    lui t1, 0x2
    sd a0, 4(t1)

    addi a0, x0, 75  # ASCII for 'K'
    sd a0, 4(t1) # UART address is still in t1
hang:
    j hang
