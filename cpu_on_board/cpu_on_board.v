// ===========================================================================
// File: blinker.v
// The simplest "Hello, World!" for an FPGA.
// This design creates a binary counter and displays its value on the LEDs.
// ===========================================================================

module cpu_on_board (
    input wire CLOCK_50,   // 50 MHz system clock from the on-board oscillator
    input wire KEY0,       // Active-low reset button
    output reg [7:0] LEDG  // 8 green LEDs (declared as 'reg' because we assign to it in an 'always' block)
);

    // --- A large counter to slow down the 50 MHz clock ---
    // A 25-bit register is large enough to count for about 0.67 seconds.
    reg [24:0] counter;

    // This is the core logic. It runs on every rising edge of the 50 MHz clock.
    always @(posedge CLOCK_50 or negedge KEY0) begin
        
        // Asynchronous Reset: If the KEY0 button is pressed (goes low),
        // immediately reset the counter and turn off the LEDs.
        if (!KEY0) begin
            counter <= 0;
            LEDG    <= 0;
        end
        // Synchronous Logic: If we are not in reset, do this on the clock edge.
        else begin
            // Let the counter count up.
            counter <= counter + 1;
            
            // Check if the counter has reached a large number (50 million).
            // This will happen approximately once per second.
            if (counter == 50000000 - 1) begin
                // When the counter reaches its max, increment the value on the LEDs.
                LEDG    <= LEDG + 1;
                // And reset the large counter to start the 1-second delay again.
                counter <= 0;
            end
        end
    end

endmodule
