import socket
import sys
import time

# --- Configuration ---
# jtagd usually runs on localhost, port 1309
JTAGD_HOST = '127.0.0.1'
JTAGD_PORT = 1309

# From your 'jtagconfig' output: "1) USB-Blaster [2-1]"
# We need to specify the cable and the device index on that cable.
CABLE_NAME = "USB-Blaster [2-1]"
DEVICE_INDEX = 1

# From your Verilog: IR is 10 bits long, USER1 instruction is '1'
IR_LENGTH = 10
IR_USER1 = 1

# From your Verilog: DR is 8 bits long
DR_LENGTH = 8

def jtag_talk(sock, command):
    """Sends a command to jtagd and returns the response."""
    # jtagd commands are null-terminated strings
    sock.sendall(command.encode('ascii') + b'\x00')
    
    # Responses are also null-terminated
    response = b''
    while True:
        data = sock.recv(1)
        if data == b'\x00':
            break
        response += data
    return response.decode('ascii')

# --- Main Program ---
sock = None
try:
    # --- Step 1: Connect to the jtagd server ---
    print(f"Connecting to jtagd on {JTAGD_HOST}:{JTAGD_PORT}...")
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((JTAGD_HOST, JTAGD_PORT))
    print("Connected.")

    # --- Step 2: Lock the device for our exclusive use ---
    # The command is "Lock Chain <cable> <device_index>"
    lock_cmd = f"Lock Chain \"{CABLE_NAME}\" {DEVICE_INDEX}"
    response = jtag_talk(sock, lock_cmd)
    if "OK" not in response:
        raise Exception(f"Failed to lock JTAG chain: {response}")
    print(f"Successfully locked device {DEVICE_INDEX} on {CABLE_NAME}")
    
    # --- Step 3: Shift in our USER1 instruction ---
    # The command is "IR Shift <ir_length> <ir_value>"
    ir_cmd = f"IR Shift {IR_LENGTH} {IR_USER1}"
    jtag_talk(sock, ir_cmd) # No interesting response, just do it

    print("------------------------------------")
    print("Listening for characters from the custom UART...")
    print("Press Ctrl+C in this terminal to stop.")
    print("------------------------------------")
    
    # --- Step 4: Loop forever, reading data ---
    while True:
        # The command is "DR Shift <dr_length> <dr_value_to_shift_in> <flags>"
        # Flags: 1=read_tdo, 2=capture_dr
        # Flag 3 (1|2) means capture and then read.
        dr_cmd = f"DR Shift {DR_LENGTH} 0 3" 
        response = jtag_talk(sock, dr_cmd)

        # The response is a hex string, e.g., "0x41" for 'A'
        if response:
            try:
                data_val = int(response, 16)
                if data_val != 0:
                    sys.stdout.write(chr(data_val))
                    sys.stdout.flush()
            except ValueError:
                # Ignore non-hex responses
                pass
        
        time.sleep(0.01) # Poll every 10ms

except Exception as e:
    print(f"\nError: {e}")
    sys.exit(1)

finally:
    # --- Step 5: Clean up by unlocking the device ---
    if sock:
        print("\nUnlocking JTAG chain...")
        jtag_talk(sock, "Unlock")
        sock.close()
        print("Done.")
