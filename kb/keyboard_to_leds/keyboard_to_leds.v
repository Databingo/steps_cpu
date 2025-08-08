// ---------------------------------------------------------------------------
// File: keyboard_to_leds.v
// FINAL, WORKING, AND SIMPLIFIED VERSION
// Combines the essential input synchronizer with the robust, case-based
// data capture logic inspired by the tutorial.
// ---------------------------------------------------------------------------

// A simple and robust PS/2 scan code receiver.
module ps2_decoder (
    input        clk,            // System clock (e.g., 50 MHz)
    input        ps2_clk_async,  // ASYNCHRONOUS PS/2 clock from the keyboard
    input        ps2_data_async, // ASYNCHRONOUS PS/2 data from the keyboard
    output reg [7:0] code        // The final, stable 8-bit scan code
);

    // --- Fix #1: Double-Flop Synchronizer (Essential) ---
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

    // --- Fix #2: Robust Case-Based Data Capture Logic ---
    reg [3:0]  bit_count;     // Counts from 0 to 10 for the 11-bit frame
    reg [7:0]  data_buffer;   // 8-bit buffer for the data payload
    reg        last_ps2_clk;  // For detecting the falling edge

    // A signal to detect the falling edge of the SYNCHRONIZED ps2_clk
    wire ps2_clk_falling_edge = last_ps2_clk & ~ps2_clk;

    initial begin
        code      = 8'h00;
        bit_count = 4'd0;
    end

    always @(posedge clk) begin
        last_ps2_clk <= ps2_clk;
        
        if (ps2_clk_falling_edge) begin
            // If the counter is at 10 (stop bit), reset it. Otherwise, increment.
            // This also handles the initial state where we wait for a start bit.
            if (bit_count >= 10) begin
                bit_count <= 0;
            end else begin
                bit_count <= bit_count + 1;
            end

            // Use the counter to decide which bit to sample.
            // This is a robust state machine.
            case (bit_count)
                // bit 0 is the start bit, we don't need to store it.
                1: data_buffer[0] <= ps2_data; // Sample data bit 0
                2: data_buffer[1] <= ps2_data; // Sample data bit 1
                3: data_buffer[2] <= ps2_data; // Sample data bit 2
                4: data_buffer[3] <= ps2_data; // Sample data bit 3
                5: data_buffer[4] <= ps2_data; // Sample data bit 4
                6: data_buffer[5] <= ps2_data; // Sample data bit 5
                7: data_buffer[6] <= ps2_data; // Sample data bit 6
                8: data_buffer[7] <= ps2_data; // Sample data bit 7
                // bit 9 is the parity bit, we can ignore it for this simple decoder.
                10: code <= data_buffer; // On the stop bit edge, latch the complete data buffer to the output.
                default: ;
            endcase
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
    // new module is already a clean, stable register updated on a clean clock edge.
    assign LEDG = scan_code;

    // Instantiate our new, simple, and robust PS/2 module
    ps2_decoder ps2_decoder_inst (
        .clk(CLOCK_50),
        .ps2_clk_async(PS2_CLK),
        .ps2_data_async(PS2_DAT),
        .code(scan_code)
    );
    
endmodule
