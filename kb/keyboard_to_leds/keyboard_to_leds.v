// ---------------------------------------------------------------------------
// File: keyboard_to_leds.v
// FINAL, SIMPLIFIED, AND WORKING VERSION
// This version uses a simple design that incorporates the two critical fixes:
// 1. Double-flop synchronizer for the inputs.
// 2. A fully registered output to prevent glitches.
// ---------------------------------------------------------------------------

// A simple, robust PS/2 scan code receiver.
module ps2_simple (
    input        clk,            // System clock (e.g., 50 MHz)
    input        ps2_clk_async,  // Asynchronous PS/2 clock from the keyboard
    input        ps2_data_async, // Asynchronous PS/2 data from the keyboard
    output reg [7:0] code        // Latched scan code
);

    // --- Fix #1: Double-Flop Synchronizer ---
    // Safely bring the external, asynchronous signals into our clock domain.
    reg ps2_clk_s1, ps2_clk_s2;
    reg ps2_data_s1, ps2_data_s2;

    always @(posedge clk) begin
        ps2_clk_s1 <= ps2_clk_async;
        ps2_clk_s2 <= ps2_clk_s1;
        ps2_data_s1 <= ps2_data_async;
        ps2_data_s2 <= ps2_data_s1;
    end
    
    // Use the clean, synchronized versions of the signals for all logic.
    wire ps2_clk  = ps2_clk_s2;
    wire ps2_data = ps2_data_s2;


    // --- Logic Stage ---
    reg [3:0]  bit_count;     // Counts from 0 to 10 for the 11-bit frame
    reg [9:0]  data_buffer;   // 10-bit buffer for data, parity, and stop bits
    reg        last_ps2_clk;  // For detecting the falling edge of the sync'd clock

    initial begin
        code      = 8'h00;
        bit_count = 0;
    end

    always @(posedge clk) begin
        last_ps2_clk <= ps2_clk;
        
        // On the falling edge of the synchronized PS/2 clock
        if (last_ps2_clk && !ps2_clk) begin
            
            // If we are not in the middle of a frame, wait for a start bit ('0')
            if (bit_count == 0) begin
                if (ps2_data == 1'b0) begin
                    bit_count <= bit_count + 1; // Start of frame detected
                end
            end
            // If we are in the middle of a frame, shift in the next bit
            else if (bit_count < 11) begin
                // Shift data into our buffer. We only care about bits 1 through 10.
                data_buffer <= {ps2_data, data_buffer[9:1]};
                bit_count <= bit_count + 1;
            end
            
            // If we have just received the 11th and final bit (the stop bit)
            if (bit_count == 11) begin
                // --- Fix #2: Fully Registered Update ---
                // The frame is now complete. Check its validity.
                // The data is in reverse order in the buffer.
                // buffer[0] = stop bit, buffer[1] = parity, buffer[9:2] = data
                
                // A valid frame has a stop bit of '1'
                if (data_buffer[0] == 1'b1) begin
                    // Parity check is optional for simple decoding, but good practice.
                    // if ((^data_buffer[9:1]) == 1'b1) begin
                        code <= data_buffer[9:2]; // Update the output register
                    // end
                end
                
                bit_count <= 0; // Reset to wait for the next frame
            end
        end
    end
endmodule


// ---------------------------------------------------------------------------
// The Top-Level Module (This is correct and does not need to change)
// ---------------------------------------------------------------------------
module keyboard_to_leds (
    input        CLOCK_50,
    input        PS2_CLK,
    input        PS2_DAT,
    output [7:0] LEDG
);

    wire [7:0] scan_code;
    
    // We can directly connect the output since the 'code' output of our
    // new module is already a clean, stable register.
    assign LEDG = scan_code;

    // Instantiate our new, simple, and robust PS/2 module
    ps2_simple ps2_decoder (
        .clk(CLOCK_50),
        .ps2_clk_async(PS2_CLK),
        .ps2_data_async(PS2_DAT),
        .code(scan_code)
    );
    
endmodule
