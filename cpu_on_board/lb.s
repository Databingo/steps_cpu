# RISC-V Assembly: 'lb' Test Part 1 (Positive Byte)
# Instructions used: lb (under test), lui, addi, sw.

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    # Get RAM address (0x1000).
    lui t0, 0x1
    # addi t0, t0, 0 -> Redundant, lui is enough.
    
    # Get UART address (0x2004).
    lui t3, 0x2
    addi t3, t3, 4

    # 1. Construct and store test pattern: 0x80418042
    lui t1, 0x80418
    addi t1, t1, 0x42
    sw t1, 0(t0)        # Store 0x80418042 to address 0x1000.
    
    # --- Action & Verification: Test Offset +2 ---
    
    # 2. Load the byte from address 0x1002. This is the byte with value 0x41 ('A').
    lb t2, 2(t0)
    
    # 3. Print the result. 'lb' on a positive byte (0x41) should result in
    #    0x...0041 in t2. The UART will print 'A'.
    sw t2, 0(t3)
