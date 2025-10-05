# Unaligned SW Test with LB

.section .text
.globl _start

_start:
    # --- Setup Phase: UART base ---
    addi t0, x0, 2047
    addi t0, t0, 2047
    addi t0, t0, 2047
    addi t0, t0, 2047
    addi t0, t0, 8      # t0 = 0x2004 (UART / memory base)

    # --- Construct word 0x53734150 = 'SsAP' ---
    lui t1, 0x53734
    addi t1, t1, 0x150  # t1 = 0x53734150 

    # --- Store word at unaligned offset: e.g., addr-1 ---
    sw t1, -15(t0)      # intentionally unaligned (addr % 4 = 1)

    # --- Load bytes individually to test LB ---
    lb t2, -15(t0)      # byte 0 (lowest addr) P
    sb t2, 0(t0)        # 
    lb t3, -14(t0)      # byte 1 A
    sb t3, 0(t0)        #
    lb t4, -13(t0)      # byte 2 s
    sb t4, 0(t0)        # 
    lb t5, -12(t0)      # byte 3 S
    sb t5, 0(t0)        # 
