# Sh  test

.section .text
.globl _start

_start:
    # --- Setup Phase ---
    # Get the UART address (0x2004) into t3.
    lui t0, 0x2
    addi t0, t0, 4      # t0 = 8196 (0x2004)

    # --- Action Phase ---
    # Construct the test value 0x50417353 ('P' 'A' 's' 'S') in register t1. 'P' = 0x50, 'A' = 0x41, 'S' = 0x53.
    lui t1, 0x50417
    addi t1, t1, 0x353  # t1 = 0x50417353.

    sh t1, -16(t0)   # save t1 low 2 bytes value to ram -16(t0) 2 aligned 
    srli t1, t1, 16  # put t1 high 2 byte in low 2 bytes
    sh t1, -14(t0)   # save t1 value to ram -14(t0) 2 aligned
   #sh t1, -13(t0)   # save t1 value to ram -14(t0) not 2 aligned  trigger assembler rvas.go alert

    addi t1, x0, 0   # clean t1 to 0
    lw t1, -16(t0)    # loab back the saved value from -16(t0) to t1


    # -- Print 'P' --
    srli t2, t1, 24     # Isolate 'P' (0x50)
    sb t2, 0(t0)        # Print 'P'
    
    # -- Print 'A' --
    srli t3, t1, 16     # Isolate 'A' (0x41)
    sb t3, 0(t0)        # Print 'A'
    
    # -- Print 'S' --
    srli t4, t1, 8      # Isolate 's' (0x73)
    sb t4, 0(t0)        # Print 's'
    
    # -- Print final 'S' --
    sb t1, 0(t0)        # Print the lowest byte 'S'

    addi t2, x0, 0x0A
    sb t2, 0(t0)      


