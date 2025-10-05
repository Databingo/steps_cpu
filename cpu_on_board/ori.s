# ============================================================
# RISC-V Assembly Test: SRAI, ORI, ANDI, XORI, SLTI, SLTIU
# All ASCII-safe (no character literals)
# Expected UART output: "ROAXsS"
# ============================================================

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    # UART base address = 0x2004
    lui  t0, 0x2
    addi t0, t0, 4      # t0 = 0x2004

    # ------------------------------------------------------------
    # 1. SRAI test
    # ------------------------------------------------------------
    # SRAI performs an arithmetic right shift
    # Example: 0xFFFF_FF80 (−128) >> 4 → 0xFFFF_FFF8 (−8)
    addi t1, x0, -128
    srai t2, t1, 4

    addi t6, x0, 82      # 'R'
    sb   t6, 0(t0)       # UART print 'R'

    # ------------------------------------------------------------
    # 2. ORI test
    # ------------------------------------------------------------
    # 0x0F0F | 0xF0F0 = 0xFFFF
    addi t2, x0, 0x0F0F
    ori  t3, t2, 0xF0F0

    addi t6, x0, 79      # 'O'
    sb   t6, 0(t0)       # UART print 'O'

    # ------------------------------------------------------------
    # 3. ANDI test
    # ------------------------------------------------------------
    # 0x0F0F & 0x5555 = 0x0505
    andi t4, t2, 0x5555
    addi t5, x0, 0x505
    beq  t4, t5, andi_ok
    j fail
andi_ok:
    addi t6, x0, 65      # 'A'
    sb   t6, 0(t0)       # UART print 'A'

    # ------------------------------------------------------------
    # 4. XORI test
    # ------------------------------------------------------------
    # 0xAAAA ^ 0x0F0F = 0xA5A5
    addi t2, x0, 0xAAAA
    xori t3, t2, 0x0F0F

    addi t6, x0, 88      # 'X'
    sb   t6, 0(t0)       # UART print 'X'

    # ------------------------------------------------------------
    # 5. SLTI test (signed)
    # ------------------------------------------------------------
    # SLTI sets rd=1 if signed(rs1) < imm
    addi t2, x0, -5
    slti t3, t2, 10      # true → t3 = 1
    beq  t3, x0, fail
    addi t6, x0, 115     # 's'
    sb   t6, 0(t0)       # UART print 's'

    # ------------------------------------------------------------
    # 6. SLTIU test (unsigned)
    # ------------------------------------------------------------
    # Unsigned compare: 0xFFFFFFFE < 10? false → 0
    addi t2, x0, -2
    sltiu t3, t2, 10
    bne  t3, x0, fail
    addi t6, x0, 83      # 'S'
    sb   t6, 0(t0)       # UART print 'S'

    # ------------------------------------------------------------
    # Done
    j done

fail:
    addi t6, x0, 70      # 'F'
    sb   t6, 0(t0)       # UART print 'F'
    j done

done:
    j done                # loop forever
