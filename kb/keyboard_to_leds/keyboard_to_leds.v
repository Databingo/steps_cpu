// ---------------------------------------------------------------------------
// File: keyboard_to_leds.v
// FINAL, WORKING VERSION with a robust Finite State Machine (FSM).
// ---------------------------------------------------------------------------

// The ps2 module, rewritten with a robust FSM for reliable data capture.
module ps2(
    input        clk,            // System clock (e.g., 50 MHz)
    input        ps2_clk_async,  // ASYNCHRONOUS PS/2 clock
    input        ps2_data_async, // ASYNCHRONOUS PS/2 data
    output reg [7:0] code        // Latched scan code
);

    // --- Synchronizer Stage ---
    // This part is correct and essential.
    reg ps2_clk_s1, ps2_clk_s2;
    reg ps2_data_s1, ps2_data_s2;

    always @(posedge clk) begin
        ps2_clk_s1 <= ps2_clk_async;
        ps2_clk_s2 <= ps2_clk_s1;
        ps2_data_s1 <= ps2_data_async;
        ps2_data_s2 <= ps2_data_s1;
    end
    
    wire ps2_clk  = ps2_clk_s2;
    wire ps2_data = ps2_data_s2;

    // --- Logic Stage with a Finite State Machine (FSM) ---
    reg [10:0] buffer;    // Shift register for the 11-bit frame
    reg [3:0]  bit_count; // Counts from 0 to 10
    reg        last_ps2_clk;

    // FSM state definition
    parameter IDLE    = 1'b0;
    parameter RECEIVE = 1'b1;
    reg       state;

    initial begin
        code      = 8'h00;
        state     = IDLE;
        bit_count = 0;
    end

    always @(posedge clk) begin
        last_ps2_clk <= ps2_clk;
        
        // On the falling edge of the synchronized PS/2 clock
        if (last_ps2_clk && !ps2_clk) begin
            
            case (state)
                IDLE: begin
                    // Wait for a start bit (a '0') to begin receiving
                    if (ps2_data == 1'b0) begin
                        bit_count <= 1;       // We've received the first bit (start bit)
                        buffer[0] <= ps2_data; // Store the start bit
                        state     <= RECEIVE;
                    end
                end
                
                RECEIVE: begin
                    // Shift in the next bit
                    buffer[bit_count] <= ps2_data;
                    
                    // If we have received all 11 bits...
                    if (bit_count == 10) begin
                        // Check if the frame is valid:
                        // start bit (buffer[0]) is 0, stop bit (buffer[10]) is 1, odd parity is correct
                        if (buffer[0] == 1'b0 && buffer[10] == 1'b1 && (^buffer[9:1]) == 1'b1) begin
                            code <= buffer[8:1]; // Latch the valid 8-bit scan code
                        end
                        state <= IDLE; // Go back to waiting for the next frame
                        bit_count <= 0;
                    end
                    else begin
                        bit_count <= bit_count + 1; // Continue counting bits
                    end
                end
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
    reg [7:0] led_output_reg;

    always @(posedge CLOCK_50) begin
        led_output_reg <= scan_code;
    end

    ps2 ps2_decoder (
        .clk(CLOCK_50),
        .ps2_clk_async(PS2_CLK),
        .ps2_data_async(PS2_DAT),
        .code(scan_code)
    );
    
    assign LEDG = led_output_reg;

endmodule
