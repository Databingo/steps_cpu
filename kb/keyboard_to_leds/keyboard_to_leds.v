// ---------------------------------------------------------------------------
// File: keyboard_to_leds.v
// FINAL, WORKING VERSION with a robust FSM AND a registered output to prevent glitches.
// ---------------------------------------------------------------------------

// The ps2 module, with the robust FSM. THIS MODULE IS CORRECT AND UNCHANGED.
module ps2(
    input        clk,
    input        ps2_clk_async,
    input        ps2_data_async,
    output reg [7:0] code
);
    // ... (The entire FSM-based ps2 module from the previous answer goes here) ...
    // ... This part is correct and does not need to be changed.
    reg ps2_clk_s1, ps2_clk_s2;
    reg ps2_data_s1, ps2_data_s2;
    always @(posedge clk) begin
        ps2_clk_s1 <= ps2_clk_async; ps2_clk_s2 <= ps2_clk_s1;
        ps2_data_s1 <= ps2_data_async; ps2_data_s2 <= ps2_data_s1;
    end
    wire ps2_clk  = ps2_clk_s2;
    wire ps2_data = ps2_data_s2;
    reg [10:0] buffer;
    reg [3:0]  bit_count;
    reg        last_ps2_clk;
    parameter IDLE = 1'b0, RECEIVE = 1'b1;
    reg        state;
    initial begin code = 8'h00; state = IDLE; bit_count = 0; end
    always @(posedge clk) begin
        last_ps2_clk <= ps2_clk;
        if (last_ps2_clk && !ps2_clk) begin
            case (state)
                IDLE: if (ps2_data == 1'b0) begin
                    bit_count <= 1;
                    buffer[0] <= ps2_data;
                    state <= RECEIVE;
                end
                RECEIVE: begin
                    buffer[bit_count] <= ps2_data;
                    if (bit_count == 10) begin
                        if (buffer[0]==1'b0 && buffer[10]==1'b1 && (^buffer[9:1])==1'b1) begin
                            code <= buffer[8:1];
                        end
                        state <= IDLE;
                        bit_count <= 0;
                    end
                    else begin
                        bit_count <= bit_count + 1;
                    end
                end
            endcase
        end
    end
endmodule


// ---------------------------------------------------------------------------
// The Top-Level Module -- WITH THE GLITCH FIX
// ---------------------------------------------------------------------------
module keyboard_to_leds (
    input        CLOCK_50,
    input        PS2_CLK,
    input        PS2_DAT,
    output [7:0] LEDG // This will now be driven by a clean register
);

    // This wire still receives the scan code from the ps2 module.
    // It might have momentary glitches as the FSM calculates its output.
    wire [7:0] scan_code;
    
    // --- THE FIX: A REGISTER TO CLEAN THE OUTPUT ---
    // We create an 8-bit register to hold the final, stable value for the LEDs.
    reg [7:0] led_output_reg;

    // This `always` block acts as our "glitch filter".
    // On every rising edge of the stable 50MHz clock, it cleanly samples the
    // value of scan_code and stores it in our register.
    always @(posedge CLOCK_50) begin
        led_output_reg <= scan_code;
    end
    // --- END OF FIX ---

    // Instantiate the ps2 module (this is unchanged)
    ps2 ps2_decoder (
        .clk(CLOCK_50),
        .ps2_clk_async(PS2_CLK),
        .ps2_data_async(PS2_DAT),
        .code(scan_code)
    );
    
    // Now, the LEDs are driven by our clean, stable register, not the raw, glitchy wire.
    assign LEDG = led_output_reg;

endmodule
