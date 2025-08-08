// ---------------------------------------------------------------------------
// File: keyboard_to_leds.v
// FINAL, WORKING VERSION with proper input signal synchronization AND a clean, registered output.
// ---------------------------------------------------------------------------

// The ps2 module, now with a double-flop synchronizer to safely handle asynchronous inputs.
module ps2(
    input        clk,          // System clock (e.g., 50 MHz)
    input        ps2_clk_async,  // ASYNCHRONOUS PS/2 clock from the keyboard
    input        ps2_data_async, // ASYNCHRONOUS PS/2 data from the keyboard
    output reg [7:0] code        // Latched scan code
);

    // --- CRITICAL FIX: Synchronizer Stage ---
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
    
    // Create internal, synchronized versions of the signals
    wire ps2_clk  = ps2_clk_s2;
    wire ps2_data = ps2_data_s2;

    // --- Logic Stage ---
    // Now we can safely use the synchronized signals in our logic.
    reg [10:0] buffer;    // Shift register for incoming data bits
    reg [3:0]  count;     // Bit counter
    reg        last_clk;  // For falling-edge detection of the SYNCHRONIZED clock

    initial code = 8'h00; // Initialize code to a known state

    always @(posedge clk) begin
        last_clk <= ps2_clk; // Use the synchronized clock
        
        // Detect the falling edge of the SYNCHRONIZED PS/2 clock
        if (last_clk && !ps2_clk) begin
            
            // This is a simple but effective state machine for capturing the 11-bit frame
            if (count < 11) begin
                buffer <= {ps2_data, buffer[10:1]}; // Shift in the current bit
                count <= count + 1;
            end
            
            // Once 11 bits are received, check the frame and update the code
            if (count == 11) begin
                // A valid frame has:
                // 1. Start bit == 0 (this is the first bit shifted in, now at buffer[0])
                // 2. Stop bit == 1 (this is the last bit shifted in, now at buffer[10])
                // 3. Odd parity on the data bits + parity bit (buffer[9:1])
                if (buffer[0] == 1'b0 && buffer[10] == 1'b1 && (^buffer[9:1]) == 1'b1) begin
                    code <= buffer[8:1]; // Latch the valid 8-bit scan code
                end
                count <= 0; // Reset for the next frame
            end
        end
    end
endmodule


// ---------------------------------------------------------------------------
// The Top-Level Module
// This now correctly wires the asynchronous physical pins to the synchronizer inputs.
// ---------------------------------------------------------------------------
module keyboard_to_leds (
    // Inputs from the board (physical pins)
    input        CLOCK_50,
    input        PS2_CLK,
    input        PS2_DAT,
    
    // Output to the board's LEDs
    output [7:0] LEDG
);

    // This wire receives the clean, stable scan code from the ps2 module
    wire [7:0] scan_code;
    
    // This register holds the value for the LEDs to prevent flickering
    reg [7:0] led_output_reg;

    always @(posedge CLOCK_50) begin
        led_output_reg <= scan_code;
    end

    // Instantiate the ps2 module
    ps2 ps2_decoder (
        .clk(CLOCK_50),            // Connect the board's 50MHz system clock
        .ps2_clk_async(PS2_CLK),   // Connect the physical PS/2 clock pin
        .ps2_data_async(PS2_DAT),  // Connect the physical PS/2 data pin
        .code(scan_code)           // Get the decoded scan code
    );
    
    // Drive the LEDs from the clean, registered output
    assign LEDG = led_output_reg;

endmodule
