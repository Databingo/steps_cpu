// ---------------------------------------------------------------------------
// File: keyboard_to_leds.v
// FINAL, WORKING VERSION. This enhances the tutorial's proven logic
// with an explicit and robust IDLE/RECEIVE Finite State Machine.
// ---------------------------------------------------------------------------

// This module is the "best of both worlds": tutorial's capture logic + FSM's robustness.
module ps2_decoder_final (
    input        clk,            // System clock
    input        ps2_clk_async,  // Asynchronous PS/2 clock
    input        ps2_data_async, // Asynchronous PS/2 data
    output reg [7:0] code        // The final, stable 8-bit scan code
);

    // --- Synchronizer Stage (Essential) ---
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

    // --- FSM and Data Capture Logic ---
    reg [3:0] bit_count;
    reg [7:0] data_buffer;
    reg       last_ps2_clk;
    
    // Define the states for our FSM
    parameter IDLE    = 1'b0;
    parameter RECEIVE = 1'b1;
    reg       state;

    wire ps2_clk_falling_edge = last_ps2_clk & ~ps2_clk;

    initial begin
        code      = 8'h00;
        bit_count = 4'd0;
        state     = IDLE;
    end

    always @(posedge clk) begin
        last_ps2_clk <= ps2_clk;
        
        if (ps2_clk_falling_edge) begin
            
            case (state)
                IDLE: begin
                    // In the IDLE state, we only do one thing:
                    // wait for a start bit (ps2_data == 0).
                    if (ps2_data == 1'b0) begin
                        state <= RECEIVE; // A frame has started, move to RECEIVE state
                        bit_count <= 1;   // We have received 1 bit (the start bit)
                    end
                end
                
                RECEIVE: begin
                    // In the RECEIVE state, we capture the data bits.
                    // This is the tutorial's robust case-based sampling logic.
                    case (bit_count)
                        1: data_buffer[0] <= ps2_data; // Sample data bit 0
                        2: data_buffer[1] <= ps2_data; // Sample data bit 1
                        3: data_buffer[2] <= ps2_data; // Sample data bit 2
                        4: data_buffer[3] <= ps2_data; // Sample data bit 3
                        5: data_buffer[4] <= ps2_data; // Sample data bit 4
                        6: data_buffer[5] <= ps2_data; // Sample data bit 5
                        7: data_buffer[6] <= ps2_data; // Sample data bit 6
                        8: data_buffer[7] <= ps2_data; // Sample data bit 7
                        // bit 9 is parity, bit 10 is stop. We can ignore them for sampling.
                        default: ;
                    endcase
                    
                    // After the 10th bit (stop bit) has been sampled...
                    if (bit_count == 10) begin
                        // Parity and stop bit checks could be added here for more robustness,
                        // but for now, we will just latch the data.
                        code <= data_buffer; // Latch the complete scan code
                        state <= IDLE;       // Go back to the IDLE state
                        bit_count <= 0;
                    end
                    else begin
                        bit_count <= bit_count + 1; // Continue to the next bit
                    end
                end
            endcase
            
        end
    end
endmodule


// ---------------------------------------------------------------------------
// The Top-Level Module (This now instantiates the final decoder)
// ---------------------------------------------------------------------------
module keyboard_to_leds (
    input        CLOCK_50,
    input        PS2_CLK,
    input        PS2_DAT,
    output [7:0] LEDG
);

    wire [7:0] scan_code;
    
    // We can still directly connect the output since the 'code' output
    // of our new FSM is clean and fully registered.
    assign LEDG = scan_code;

    // Instantiate our new, final, and robust PS/2 module
    ps2_decoder_final ps2_decoder_inst (
        .clk(CLOCK_50),
        .ps2_clk_async(PS2_CLK),
        .ps2_data_async(PS2_DAT),
        .code(scan_code)
    );
    
endmodule
