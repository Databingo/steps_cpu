import intel_jtag_uart
import sys
import time
try:
    ju = intel_jtag_uart.intel_jtag_uart()
    print("Connected to USB-Blaster")
    while True:
        data = ju.read()
        if data:
            sys.stdout.write(data.decode('ascii', errors='ignore'))
            sys.stdout.flush()
        time.sleep(0.1)  #// Poll every 100ms
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
