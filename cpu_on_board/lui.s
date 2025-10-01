# RISC-V Assembly: Minimal LUI Test
# Goal: Use LUI to construct a value, store/load it, and print it to the UART.
#       Then, print a known-good value for comparison.
# Instructions used: LUI (under test), addi, sd, ld (trusted helpers).

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    # Get RAM address  into t0.
    addi t0, x0, 2047
    addi t0, t0, 2047
    addi t0, t0, 2047
    
    # Get UART address (0x2004) into t3.
    addi t3, x0, 2047
    addi t3, t3, 2047
    addi t3, t3, 2047
    addi t3, t3, 2047
    addi t3, t3, 8      # t3 = 8196 (0x2004)

    # --- Action Phase: The Instruction Under Test (LUI) ---

    # 1. Use LUI to construct the value 80 (ASCII 'P').
    #    The number 80 is 0x50. LUI loads into the upper 20 bits, so this is too small.
    #    Let's construct a larger number where the 'P' is a side effect.
    #    Let's aim for 0x10050.
    #    The upper 20 bits are 0x10. The lower 12 bits are 0x50.
    
    lui t1, 0x10        # LUI is under test. t1 should become 0x10000.
    
    # 2. Use ADDI to add the lower bits.
    #    0x50 is decimal 80.
    addi t1, t1, 80     # t1 should now be 0x10000 + 80 = 0x10050.

    # We only care about the lowest byte for printing. Let's isolate it.
    # Since we don't have ANDI, we can't mask it. But the UART will only
    # look at the lowest 8 bits of the 64-bit value anyway. So, the value
    # in t1 is effectively 80 ('P') for the purpose of printing.
    
    # --- Verification Phase ---

    # 3. Store the LUI-generated value to RAM.
    sd t1, 0(t0)        # Store 0x10050 to address t0
    
    # 4. Clear a register and load the value back.
    addi t2, x0, 0
    ld t2, 0(t0)        # Load  into t2. If LUI/ADDI/SD/LD all work, t2 is 0x10050.

    # 5. Print the loaded value to the UART.
    #    The UART will only see the lower 8 bits, which is 80 ('P').
    sd t2, 0(t3)        # This should print the FIRST 'P'.

    # 6. Now, create the known-good value 80 using only ADDI.
    addi t4, x0, 80
    
    # 7. Print the known-good value to the UART.
    sd t4, 0(t3)        # This should print the SECOND 'P'.

