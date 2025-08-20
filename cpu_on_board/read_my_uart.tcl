# =========================================================================
# File: read_my_uart.tcl (v7 - Definitive API for Quartus 13.0)
# This version uses the correct 3-argument claim_service command.
# =========================================================================

# Get a handle to the first available JTAG master service
set master_path [lindex [get_service_paths master] 0]

# Take exclusive control of the JTAG master service.
# For Quartus 13.0, this command requires THREE arguments:
# 1. The service path ($master_path)
# 2. A client name for this script ("My Script")
# 3. The name of the command library to load (com.altera.systemconsole.services.jtag)
claim_service $master_path "My Script" com.altera.systemconsole.services.jtag

puts "Successfully claimed JTAG master service and loaded JTAG commands."
puts "------------------------------------"
puts "Listening for characters from the custom UART..."
puts "Press Ctrl+C in this terminal to stop."
puts "------------------------------------"

# --- Configure the JTAG chain for our custom USER1 instruction ---
# Now that the library is loaded, we can call commands on the handle.
$master_path ir_shift -ir_value 1 -ir_length 10

# Now, continuously poll the Data Register (DR)
while {1} {
    # Call the dr_shift command on the handle.
    set data [$master_path dr_shift -length 8 -capture -shift -tdo]

    # Your Verilog sends 0x00 when the FIFO is empty.
    # Only print characters if they are not NULL.
    if {$data != 0} {
        # Convert the integer data to an ASCII character and print it
        puts -nonewline [format %c $data]
        # Flush the output buffer to make sure the character appears immediately
        flush stdout
    }
    
    # Wait a little bit to avoid hammering the JTAG bus at 100% CPU
    after 10
}

# This part is unreachable, but it's good practice to show how to release the service
unclaim_service $master_path
