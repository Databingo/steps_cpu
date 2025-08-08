
// ---------------------------------------------------------------------------
// File: keyboard_to_leds.v
// FINAL, WORKING VERSION with proper input signal synchronization.
// ---------------------------------------------------------------------------

// The ps2 module, now with a double-flop synchronizer to prevent metastability.
module ps2(
    input clk,          // System clock (e.g., 50 MHz)
    input ps2_clk_async,  // Asynchronous PS/2 clock from the keyboard
    input ps2_data_async, // Asynchronous PS/2 data from the keyboard
    output reg [7:0] code // Latched scan code
);

    // --- Synchronizer Stage ---
    // Double-flop synchronizers to safely bring external signals into our clock domain.
    reg ps2_clk_s1, ps2_clk_s2;
    reg ps2_data_s1, ps2_data_s2;

    always @(posedge clk) begin
        // Synchronize ps2_clk
        ps2_clk_s1 <= ps2_clk_async;
        ps2_clk_s2 <= ps2_clk_s1;
        // Synchronize ps2_data
        ps2_data_s1 <= ps2_data_async;
        ps2_data_s2 <= ps2_data_s1;
    end
    
    // Internal synchronized signals
    wire ps2_clk  = ps2_clk_s2;
    wire ps2_data = ps2_data_s2;

    // --- Logic Stage ---
    // Now we can safely use the synchronized signals in our logic.
    reg [10:0] buffer;    // Shift register for incoming data bits
    reg [3:0]  count;     // Bit counter
    reg        last_clk;  // For falling-edge detection

    // We initialize 'code' to a known value.
    initial code = 8'h00;

    always @(posedge clk) begin
        last_clk <= ps2_clk; // Use the synchronized clock
        
        // Detect the falling edge of the synchronized PS/2 clock
        if (last_clk && !ps2_clk) begin
            
            // Check for the start bit (a '0')
            if (count == 0 && ps2_data == 1'b0) begin
                count <= 1; // Start of a new frame
            end
            // Shift in the 8 data bits and the parity bit
            else if (count > 0 && count < 10) begin
                buffer[count] <= ps2_data; // Shift data bit in
                count <= count + 1;
            end
            // Check the stop bit and process the frame
            else if (count == 10) begin
                // A valid frame has:
                // 1. Start bit == 0 (which we already checked)
                // 2. Stop bit == 1 (ps2_data at this edge should be the stop bit)
                // 3. Odd parity (the XOR sum of the data bits and parity bit is 1)
                if (ps2_data == 1'b1' && (^buffer[9:1]) == 1'b1) begin
                    code <= buffer[8:1]; // Latch the valid 8-bit scan code
                end
                count <= 0; // Reset for the next frame
            end
            else begin
                 // If we're out of sync, reset the counter
                 count <= 0;
            end
        end
    end
endmodule


// ---------------------------------------------------------------------------
// The Top-Level Module
// This is the module that Quartus will see as the "main" part of the design.
// ---------------------------------------------------------------------------
module keyboard_to_leds (
    // Inputs from the board
    input        CLOCK_50,
    input        PS2_CLK,  // The physical pin from the keyboard
    input        PS2_DAT,  // The physical pin from the keyboard
    
    // Output to the board's LEDs
    output [7:0] LEDG
);

    // Create an internal wire to hold the 8-bit scan code
    wire [7:0] scan_code;

    // Create an instance of your ps2 module.
    ps2 ps2_decoder (
        .clk(CLOCK_50),            // Connect the board's 50MHz clock
        .ps2_clk_async(PS2_CLK),   // Connect the physical PS/2 clock pin
        .ps2_data_async(PS2_DAT),  // Connect the physical PS/2 data pin
        .code(scan_code)           // Connect the module's output to our wire
    );

    // This is the core logic that maps the scan code to the LEDs.
    assign LEDG = scan_code;

endmodule
