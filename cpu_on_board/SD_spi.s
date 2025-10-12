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
#lui t6, 0x2
#addi t6, t6, 4      # t0 = 0x2004
#
#li t0, 0x2008 # t0 holds the SPI base address (0x2008)
#li t1, 0xFF # t1 holds the byte to send (e.g., a dummy 0xFF for a read)
#
## Write 0 to the control register (offset +12) to ensure it's in a known state.
#sw x0, 12(t0)
#
## --- Step 1: Wait until the transmitter is ready ---
#wait_tx_ready:
#    lw t3, 8(t0)       # Read the status register into t3
#    andi t3, t3, 0x20   # Isolate the TRDY bit (bit 5)
#    beq t3, x0, wait_tx_ready # If TRDY is 0, loop and wait.
#    
## --- Step 2: Write the byte to the transmit register ---
#sw t1, 4(t0)        # Write the byte from t1 to the txdata register.
#                    # This starts the 8-clock-pulse SPI transfer.
#
## --- Step 3: Wait until the receiver has valid data ---
#wait_rx_ready:
#    lw t3, 8(t0)       # Read the status register
#    andi t3, t3, 0x40   # Isolate the RRDY bit (bit 6)
#    beq t3, x0, wait_rx_ready # If RRDY is 0, loop and wait.
#
## --- Step 4: Read and Print ---
#    lw t2, 0(t0)       # Read the received byte from rxdata into t2.
#    sw t2, 0(t6) # print 



# RISC-V Assembly: SPI Core Loopback Test
# Goal: Verify the CPU can write to and read from the SPI IP core.

#.section .text
#.globl _start
#
#_start:
#    # --- Setup Phase ---
#    li t6, 0x2004       # UART Address
#    li t0, 0x2008       # SPI Base Address
#    
#    # Define register offsets
#    li t4, 0            # rxdata offset = 0
#    li t5, 4            # txdata offset = 4
#    li t6, 8            # status offset = 8
#    li a7, 12           # control offset = 12
#
#    # --- Step 1: Configure the SPI Core for Loopback ---
#    # We need to write '2' (0b0010) to the control register to enable loopback.
#    li t1, 2
#    add t2, t0, a7      # t2 = SPI_BASE + control_offset
#    sw t1, 0(t2)        # Write '2' to the control register
#
#    # --- Step 2: Write a Magic Byte ---
#    # Prepare the magic byte 'X' (ASCII 88).
#    li t1, 88
#
#    # Wait for the transmitter to be ready.
#wait_tx_ready:
#    lw t3, 8(t0)
#    andi t3, t3, 0x20   # Check TRDY bit
#    beq t3, x0, wait_tx_ready
#
#    # Send the magic byte 'X'.
#    sw t1, 4(t0)
#
#    # --- Step 3: Wait for the Receiver ---
#wait_rx_ready:
#    lw t3, 8(t0)
#    andi t3, t3, 0x40   # Check RRDY bit
#    beq t3, x0, wait_rx_ready
#
#    # --- Step 4: Read the received byte ---
#    lw t2, 0(t0)       # Read from rxdata. t2 should now hold 'X' (88).
#
#    # --- Step 5: Verify ---
#    # Compare the received byte (t2) with the original magic byte (t1).
#    beq t1, t2, pass
#
#fail:
#    # If the bytes don't match, print 'F'.
#    li t1, 70
#    sw t1, 0(t6)
#fail_loop:
#    beq x0, x0, fail_loop
#    
#pass:
#    # If the bytes match, print 'P'.
#    li t1, 80
#    sw t1, 0(t6)
#pass_loop:
#    beq x0, x0, pass_loop
#
#


# RISC-V Assembly: Minimal SD Card Communication Test (CMD0)
# Goal: Send the GO_IDLE_STATE command and print the card's response.
# Expected Output: 'Q' (if the card responds with 0x01)

.section .text
.globl _start

# Function to send one byte and receive one byte
# a0: byte to send
# a0: byte received
send_spi_byte:
    # t5 holds SPI base address (0x2008)
    # Wait for transmitter to be ready
    wait_tx:
        lw t6, 8(t5)
        andi t6, t6, 0x20 # Check TRDY (bit 5)
        beq t6, x0, wait_tx
    
    # Send the byte
    sw a0, 4(t5)
    
    # Wait for receiver to be ready
    wait_rx:
        lw t6, 8(t5)
        andi t6, t6, 0x40 # Check RRDY (bit 6)
        beq t6, x0, wait_rx
        
    # Read the received byte
    lw a0, 0(t5)
    ret

# Function to send a 6-byte SD command
# a0-a5: The 6 bytes of the command
send_spi_cmd:
    # Save ra and other registers we will use
    addi sp, sp, -24
    sw ra, 0(sp)
    sw s0, 8(sp)
    sw s1, 16(sp)
    
    mv s0, a0 # Save command bytes
    mv s1, a1

    # Send the 6 bytes
    mv a0, s0 
    call send_spi_byte
    mv a0, s1
    call send_spi_byte
    mv a0, a2
    call send_spi_byte
    mv a0, a3
    call send_spi_byte
    mv a0, a4
    call send_spi_byte
    mv a0, a5
    call send_spi_byte
    
    # Restore registers
    lw ra, 0(sp)
    lw s0, 8(sp)
    lw s1, 16(sp)
    addi sp, sp, 24
    ret

_start:
    # --- Setup ---
    li sp, 0x1800       # Init stack pointer
    li t4, 0x2004       # UART Address
    li t5, 0x2008       # SPI Base Address

    # 1. SPI/SD Power-on sequence.
    #    Send at least 74 clock cycles with SS_n HIGH (de-asserted).
    #    We do this by writing 10 dummy bytes (0xFF).
    #    First, ensure SS_n is high by writing 0 to the slave select register.
    sw x0, 16(t5)       # Write 0 to slaveselect register to de-assert all SS lines.
    
    li t6, 10           # Counter for 10 bytes
    li a0, 0xFF         # Dummy byte
power_on_loop:
    call send_spi_byte
    addi t6, t6, -1
    bne t6, x0, power_on_loop

    # 2. Assert Slave Select (SS_n LOW).
    #    Write '1' to the slave select register to select the first (and only) slave.
    li t6, 1
    sw t6, 16(t5)
    
    # 3. Send CMD0 (GO_IDLE_STATE).
    #    Command is: 0x40, 0x00, 0x00, 0x00, 0x00, 0x95
    li a0, 0x40
    li a1, 0x00
    li a2, 0x00
    li a3, 0x00
    li a4, 0x00
    li a5, 0x95
    call send_spi_cmd

    # 4. Wait for the response from the card.
    #    The card can take a few cycles to respond. We poll by sending dummy bytes
    #    until we receive something other than 0xFF.
    li a0, 0xFF         # Dummy byte
    li t6, 8            # Max attempts before giving up
wait_response_loop:
    call send_spi_byte  # Send 0xFF, receive response in a0
    li t1, 0xFF
    beq a0, t1, check_timeout # If we got 0xFF, it's not a real response yet.
    j response_received # We got a real response!

check_timeout:
    addi t6, t6, -1
    bne t6, x0, wait_response_loop
    # If we get here, we timed out. Just hang.
    j done 

response_received:
    # 'a0' now holds the response byte from the SD card.
    # A correct response for CMD0 is 0x01.
    
    # --- Verification ---
    # To make it a printable character, add 80.
    # If response was 0x01, a0 will become 81 ('Q').
    addi a0, a0, 80
    
    # Print the resulting character to the UART.
    sw a0, 0(t4)
    
done:
    beq x0, x0, done



