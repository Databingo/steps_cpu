# RISC-V Assembly: Ultimate Minimal 'sd' Test with UART Verification
# Goal: Write the character 'P' to the UART at address 0x2004.
# Instructions used: ONLY ADDI and SD.

.section .text
.globl _start

_start:
    # --- Setup Phase (using ONLY ADDI) ---

    # 1. Construct the UART address (0x2004) in a base register (t0).
    #    We will do this by adding 2048 + 2048 + 2048 + 4 = 8196 = 0x2004
    #    The immediate in ADDI is 12 bits, so the max is 2047.
    
    addi t0, x0, 2047   # t0 = 2047
    addi t0, t0, 2047   # t0 = 4094
    addi t0, t0, 2047   # t0 = 6141
    addi t0, t0, 2047   # t0 = 8188 (0x1FFC)
    addi t0, t0, 8      # t0 = 8196 (0x2004). The address is ready.
    
    # 2. Load the data we want to write ('P') into a source register (t1).
    #    The ASCII code for 'P' is 80.
    addi t1, x0, 80     # t1 = 80
    
    # --- Action Phase: The Instruction Under Test ---

    # 3. Store the value from t1 ('P') into the memory address pointed to by t0 (0x2004).
    #    This should send the character to the UART.
    #    Instruction: sd rs2, offset(rs1)
    #    Here:        sd t1, 0(t0)
    sd t1, 0(t0)

done:
    j done              # Infinite loop to halt the processor.
