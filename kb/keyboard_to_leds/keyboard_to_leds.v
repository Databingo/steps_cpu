// ---------------------------------------------------------------------------
// File: keyboard_to_leds.v
// Your original ps2 module remains unchanged.
// ---------------------------------------------------------------------------
module ps2(clk, ps2_clk, ps2_data,code);
    input clk, ps2_clk, ps2_data;
    output reg [7:0] code;
    reg [10:0] buffer;
    reg [3:0] count;
    reg last_clk;

    always @(posedge clk) begin
        last_clk <= ps2_clk;
        if (last_clk && !ps2_clk)begin
            buffer <= {ps2_data, buffer[10:1]};
            count <= count + 1;
            if (count == 10) begin
                if (!buffer[0] && buffer[10] && (^buffer[9:1]))
                    code <= buffer[8:1];
                count <= 0;
            end
        end
    end
endmodule


// ---------------------------------------------------------------------------
// The Top-Level Module -- WITH THE FIX
// ---------------------------------------------------------------------------
module keyboard_to_leds (
    // Inputs from the board
    input        CLOCK_50,
    input        PS2_CLK,
    input        PS2_DAT,
    
    // Output to the board's LEDs
    output [7:0] LEDG
);

    // This wire still receives the potentially glitchy scan code from the ps2 module
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

    
    // Your ps2 module instantiation is unchanged
    ps2 ps2_decoder (
        .clk(CLOCK_50),
        .ps2_clk(PS2_CLK),
        .ps2_data(PS2_DAT),
        .code(scan_code)
    );
    
    // Now, the LEDs are driven by our clean, stable register, not the raw wire.
    assign LEDG = led_output_reg;

endmodule
