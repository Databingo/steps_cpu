// ---------------------------------------------------------------------------
// File: keyboard_to_leds.v
// FINAL, WORKING VERSION. This adapts the known-good tutorial code directly.
// It keeps the core, proven logic and simplifies it for our specific task.
// ---------------------------------------------------------------------------

// This module is a direct, simplified adaptation of the working tutorial code.
module ps2_decoder (
    input        clk,            // System clock (was clk_in)
    input        ps2_clk_async,  // Asynchronous PS/2 clock (was key_clk)
    input        ps2_data_async, // Asynchronous PS/2 data (was key_data)
    output reg [7:0] code        // The final, stable 8-bit scan code (was key_byte)
);

    // --- Synchronizer Stage (from tutorial) ---
    // This is the essential double-flop synchronizer.
    reg ps2_clk_r0 = 1'b1, ps2_clk_r1 = 1'b1;
    reg ps2_data_r0 = 1'b1, ps2_data_r1 = 1'b1;

    always @(posedge clk) begin
        ps2_clk_r0 <= ps2_clk_async;
        ps2_clk_r1 <= ps2_clk_r0;
        ps2_data_r0 <= ps2_data_async;
        ps2_data_r1 <= ps2_data_r0;
    end

    // Falling edge detector for the synchronized clock (from tutorial)
    wire ps2_clk_falling_edge = ps2_clk_r1 & (~ps2_clk_r0);

    // --- Data Capture Logic (from tutorial) ---
    reg [3:0] cnt;
    reg [7:0] temp_data;

    // This is the core state machine for capturing the 11-bit frame.
    always @(posedge clk) begin
        if (ps2_clk_falling_edge) begin
            if (cnt >= 10) begin
                cnt <= 0;
            end else begin
                cnt <= cnt + 1;
            end

            case (cnt)
                // We only care about bits 1-8 (the data bits)
                1: temp_data[0] <= ps2_data_r1;
                2: temp_data[1] <= ps2_data_r1;
                3: temp_data[2] <= ps2_data_r1;
                4: temp_data[3] <= ps2_data_r1;
                5: temp_data[4] <= ps2_data_r1;
                6: temp_data[5] <= ps2_data_r1;
                7: temp_data[6] <= ps2_data_r1;
                8: temp_data[7] <= ps2_data_r1;
                default: ;
            endcase
        end
    end

    // --- Output Latching Logic (simplified from tutorial) ---
    // This `always` block ensures the `code` output is clean and registered.
    always @(posedge clk) begin
        // When the 10th bit (stop bit) has just been received on the last falling edge...
        if (cnt == 10 && ps2_clk_falling_edge) begin
            // ...and the received data is not a key-release code...
            if (temp_data != 8'hF0) begin
                code <= temp_data; // Latch the captured scan code to the output.
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

    // Instantiate our new, tutorial-based PS/2 module
    ps2_decoder ps2_decoder_inst (
        .clk(CLOCK_50),
        .ps2_clk_async(PS2_CLK),
        .ps2_data_async(PS2_DAT),
        .code(scan_code)
    );
    
endmodule
