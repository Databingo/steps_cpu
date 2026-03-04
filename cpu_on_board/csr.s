# RISC-V Assembly: CSR Instruction Test

.section .text
.globl _start

_start:
    li t0, 0x2004       # UART address
    

    # --- Test 1: CSRRW ---
    li t1, 0x12345678
    csrrw x0, mscratch, t1  # Write t1 to mscratch, discard old value.
    csrrw t2, mscratch, x0  # Read mscratch into t2, write 0 back.
    li t6, 49          # 1
    sd t6, 0(t0)
    bne t1, t2, fail        # Check if what we read back is correct.
    
    # --- Test 2: CSRRS with non-zero rs1 ---
    # Set some bits in mscratch.
    li t1, 0x0000000F      # The bits we want to set.
    li t2, 0x12345670      # The initial value in the CSR.
    csrrw x0, mscratch, t2
    
    csrrs t3, mscratch, t1  # Atomically read old (t3) and set bits.
    
    # Verify the read part. t3 should be the old value.
    li t6, 50          # 1
    sd t6, 0(t0)
    bne t3, t2, fail
    
    # Verify the write part. Read mscratch again. It should be the new value.
    csrrw t4, mscratch, x0  # Read into t4, clear mscratch.
    li t5, 0x1234567F      # Expected new value (0x...70 | 0x...0F)
    li t6, 51          # 1
    sd t6, 0(t0)
    bne t4, t5, fail
    
    # --- Test 3: CSRRS with x0 (Read-Only) ---
    # Write a value to mscratch.
    li t1, 0xABC
    csrrw x0, mscratch, t1
    
    # This should ONLY read. It should NOT change mscratch.
    csrrs t2, mscratch, x0
    
    # Check that t2 has the correct read value.
    li t6, 52          # 1
    sd t6, 0(t0)
    bne t2, t1, fail
    
    # Now, read mscratch again to prove it was not changed.
    csrrw t3, mscratch, x0
    li t6, 53          # 1
    sd t6, 0(t0)
    bne t3, t1, fail
    
    # If all tests passed...
pass:
    li t6, 80           # ASCII 'P'
    sd t6, 0(t0)
pass_loop:
    beq x0, x0, pass_loop

fail:
    li t6, 70           # ASCII 'P'
    sd t6, 0(t0)
    beq x0, x0, fail
