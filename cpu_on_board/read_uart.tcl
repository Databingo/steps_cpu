# read_uart.tcl
proc read_uart {} {
    # Set IR to your USER1 instruction (0x001)
    irscan custom_jtag.tap 0x001
    
    # Shift 8 bits through the DR
    set data [drscan custom_jtag.tap 8 0x00]
    
    # Only print non-zero values (your FIFO sends 0 when empty)
    if {$data != 0} {
        puts -nonewline [format %c $data]
        flush stdout
    }
    
    # Small delay
    after 10
}

puts "Starting to listen for custom JTAG UART messages..."
puts "Press Ctrl+C to stop"

# Continuously read from UART
while {1} {
    read_uart
}
