#`define Spi_base  32'h0000_2008
#`define Spi_size  32'h0000_0020

## Conceptual code for sending an SPI command
#li   t0, 0x2000      # Base address of SPI core
#li   t1, CMD0        # The command byte to send
#sw   t1, 0(t0)       # Write the command to the SPI data register
## ... loop and check the SPI status register until transmission is complete ...
#
#
## Assume t0 holds the base address of your RAM buffer (e.g., 0x1000)
#    # Assume t1 holds the address of the SPI data register (e.g., 0x2000)
#    # Assume t2 holds the address of the SPI status register (e.g., 0x2004)
#    # Assume t3 is our loop counter, initialized to 512.
#    
#read_loop:
#    # 1. Check if the SPI core has received a new byte.
#    #    This is a "polling" loop. The CPU will spin here for thousands of cycles.
#    lw t4, 0(t2)        # Read the status register
#    andi t4, t4, 0x80   # Check the "Receive Ready" bit (e.g., bit 7)
#    beq t4, x0, read_loop # If not ready, loop and check again.
#    
#    # 2. A new byte has arrived! Read it from the SPI data register.
#    lw t4, 0(t1)        # Load the 32-bit word from the data register.
#                        # The byte we want is in the lower 8 bits.
#    
#    # 3. Store this new byte into our RAM buffer.
#    #    The 'sb' instruction will take its 3 cycles. This is perfectly fine.
#    #    The SPI controller is already busy fetching the *next* bit in the background.
#    sb t4, 0(t0)
#    
#    # 4. Update pointers and counters.
#    addi t0, t0, 1      # Increment the RAM buffer address.
#    addi t3, t3, -1     # Decrement the loop counter.
#    bne t3, x0, read_loop # If not done, go back to wait for the next byte.
#
## Corrected assembly for 8-bit SPI core
## Assume t0 holds the base address of your RAM buffer (e.g., 0x1000)
#    # Assume t1 holds the address of the SPI data register (e.g., 0x2000)
#    # Assume t2 holds the address of the SPI status register (e.g., 0x2004)
#    # Assume t3 is our loop counter, initialized to 512.
#
##`define Spi_base  32'h0000_2008
##`define Spi_size  32'h0000_0020
#.globl _start
#_start:
#    # --- Setup Phase ---
#    # Get the base address of the SPI controller (e.g., 0x2000) into t0
#    li t0, 0x2000 
#    
#    # Assume the register offsets within the SPI core are:
#    # 0x0: rxdata (Read-Only)
#    # 0x4: txdata (Write-Only)
#    # 0x8: status (Read-Only)
#    # 0xC: control (Read/Write)
#    
#    # --- Example: Sending a command byte (e.g., CMD0) ---
#    li t1, CMD0_VALUE   # Load the command byte into a register
#    
#    # Use STORE BYTE to write the command to the transmit data register
#    sb t1, 4(t0)        # Write the byte in t1 to address 0x2004
#
#_wait_for_tx_complete:
#    # Use LOAD BYTE UNSIGNED to read the 8-bit status register
#    lbu t2, 8(t0)       # Read status from address 0x2008
#    # ... check the busy bit in t2 ...
#    # beq ..., ..., _wait_for_tx_complete
#
#    # --- Example: Reading a data byte ---
#    
#    # First, write a dummy byte to start the clock
#    li t1, 0xFF
#    sb t1, 4(t0)
#
#_wait_for_rx_complete:
#    # Poll the status register until the "Receive Ready" bit is set
#    lbu t2, 8(t0)
#    # ... check the ready bit ...
#    # beq ..., ..., _wait_for_rx_complete
#
#    # Now read the received byte from the receive data register
#    lbu t3, 0(t0)       # Load the 8-bit result from 0x2000 into t3
#                        # lbu correctly zero-extends it to 64 bits.
# #    # Now t3 holds the byte you received from the SD card.



#`define Spi_base  32'h0000_2008
#`define Spi_size  32'h0000_0020
.globl _start
_start:
    # Assume the register offsets within the SPI core are:
    # 0x0: rxdata (Read-Only)
    # 0x4: txdata (Write-Only)
    # 0x8: status (Read-Only)
    # 0xC: control (Read/Write)
    # 0x10: slaveselect (Write-Only) 0x01 for only one
# status
# Bit 5 TRDY Transmit Ready, empty for receive a new byte
# Bit 6 RRDY Receive Ready, ready for be read

# Bit 7 Error
# Bit 4 Empty
# Bit 3 Rx Overrun
# Bit 2 Tx Overrun


# Goal: Send the byte in 't1', and put the received byte into 't2'.
# --- Setup Phase ---
# Get UART address (0x2004) into t0.
lui t6, 0x2
addi t6, t6, 4      # t0 = 0x2004
# Get the base address of the SPI controller (e.g., 0x2008) into t0
li t0, 0x2008 # t0 holds the SPI base address (0x2008)
li t1, 0xFF # t1 holds the byte to send (e.g., a dummy 0xFF for a read)

# --- Step 1: Wait until the transmitter is ready ---
wait_tx_ready:
    lw t3, 8(t0)       # Read the status register into t3
    andi t3, t3, 0x20   # Isolate the TRDY bit (bit 5)
    beq t3, x0, wait_tx_ready # If TRDY is 0, loop and wait.
    
# --- Step 2: Write the byte to the transmit register ---
sb t1, 4(t0)        # Write the byte from t1 to the txdata register.
                    # This starts the 8-clock-pulse SPI transfer.

# --- Step 3: Wait until the receiver has valid data ---
wait_rx_ready:
    lw t3, 8(t0)       # Read the status register
    andi t3, t3, 0x40   # Isolate the RRDY bit (bit 6)
    beq t3, x0, wait_rx_ready # If RRDY is 0, loop and wait.

lw t2, 0(t0)       # Read the received byte from rxdata into t2.
sb t2, 0(t6) # print 

