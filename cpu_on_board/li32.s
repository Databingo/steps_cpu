# RISC-V Assembly: 'li' Pseudo-Instruction Test
# Goal: Verify the assembler correctly expands 'li' for a 32-bit value.
# Instructions used: li (under test), sd, ld (trusted helpers).

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    # Get RAM address (0x1000) into t0.
    # We can use 'li' for this now, as it's part of the test.
    li t0, 0x1000
    
    # Get UART address (0x2004) into t3.
    # We can use 'li' for this now too.
    li t3, 0x2004
    
    # --- Action Phase: The Pseudo-Instruction Under Test (li) ---

    # 1. Use 'li' to load a 32-bit constant. The assembler should expand
    #    this into a 'lui' and an 'addi' instruction.
    #    The value is 0x1A2B3C4D. The lower 8 bits are 0x4D (ASCII 'M').
    li t1, 0x1A2B3C4D
    
    # --- Verification Phase ---
    
    # 2. Store the generated value from t1 to RAM.
    sd t1, 0(t0)        # Store 0x1A2B3C4D to address 0x1000.
    
    # 3. Clear a register and load the value back from RAM.
    li t2, 0            # Clear t2
    ld t2, 0(t0)        # Load from 0x1000 into t2. If everything works,
                        # t2 should now hold 0x..._1A2B3C4D.

    # 4. Print the loaded value to the UART.
    #    The 32-bit UART will receive the lower 32 bits of the store (0x1A2B3C4D).
    #    The UART peripheral will transmit the lowest 8 bits, which is 0x4D ('M').
    sd t2, 0(t3)
