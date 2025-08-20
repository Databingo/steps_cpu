#!/usr/bin/env python3

from pyftdi.jtag import JtagEngine
import time

# Initialize JTAG engine
jtag = JtagEngine()
jtag.configure('ftdi://ftdi:2232/1')  # Adjust for your USB-Blaster

# Your custom IR length and value
ir_length = 10
user1_ir = 0x001  # Your USER1 instruction

try:
    print("Listening for JTAG UART messages...")
    print("Press Ctrl+C to stop")
    
    while True:
        # Shift in the USER1 instruction
        jtag.write_ir(user1_ir, ir_length)
        
        # Shift out 8 bits of data
        data = jtag.read_dr(8)
        
        # Only print non-zero values
        if data != 0:
            print(chr(data), end='', flush=True)
        
        # Small delay
        time.sleep(0.01)

except KeyboardInterrupt:
    print("\nStopping...")
finally:
    jtag.close()
