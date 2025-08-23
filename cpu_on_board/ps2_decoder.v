module ps2_decoder (
    input        clk,            // System clock (was clk_in)
    input        ps2_clk_async,  // Asynchronous PS/2 clock (was key_clk)
    input        ps2_data_async, // Asynchronous PS/2 data (was key_data)
    output reg [7:0] code,        // The final, stable 8-bit scan code (was key_byte)
    output reg code_valid
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

    // --- Data Capture Logic ---
    reg [3:0] cnt = 0;
    reg [10:0] temp_data;
    reg ignore_next = 0;
    reg shift_pressed = 0;
    reg caps_lock = 0;

    // This is the core state machine for capturing the 11-bit frame.
    always @(posedge clk) begin
        if (ps2_clk_falling_edge) begin
            if (cnt >= 10) begin
                cnt <= 0;
            end else begin
                cnt <= cnt + 1;
            end
	    temp_data[cnt] <= ps2_data_r1;

            //case (cnt)
            //    // We only care about bits 1-8 (the data bits)
            //    0: temp_data[0] <= ps2_data_r1; // Start bit:0
            //    1: temp_data[1] <= ps2_data_r1;
            //    2: temp_data[2] <= ps2_data_r1;
            //    3: temp_data[3] <= ps2_data_r1;
            //    4: temp_data[4] <= ps2_data_r1;
            //    5: temp_data[5] <= ps2_data_r1;
            //    6: temp_data[6] <= ps2_data_r1;
            //    7: temp_data[7] <= ps2_data_r1;
            //    8: temp_data[8] <= ps2_data_r1;
            //    9: temp_data[9] <= ps2_data_r1; // Parity bit
            //   10: temp_data[10] <= ps2_data_r1; // Stop bit:1
            //    default: ;
            //endcase
        end
    end

    // --- Output Latching Logic (simplified from tutorial) ---
    // This `always` block ensures the `code` output is clean and registered.
    always @(posedge clk) begin
        //// When the 10th bit (stop bit) has just been received on the last falling edge...
        //if (cnt == 10 && ps2_clk_falling_edge) begin
        //    // ...and the received data is not a key-release code...and parity is 1
        //    if (temp_data[8:1] != 8'hF0 && temp_data[0] == 1'b0 && temp_data[10]==1'b1 && (^temp_data[9:1]==1'b1)) begin
        //        code <= temp_data[8:1]; // Latch the captured scan code to the output.
        //    end
        //end
   
	// Output latching logci with shift/caps tracking
        if (cnt == 10 && ps2_clk_falling_edge) begin
	    if (temp_data[0] == 1'b0 && temp_data[10]==1'b1 && (^temp_data[9:1]==1'b1)) begin
	        if (ignore_next) begin ignore_next <= 1'b0; end
	        else begin
	            case (temp_data[8:1]) 
	                8'h12, 8'h59: shift_pressed <= 1'b1; // Left or Right Shift
	                8'hF0: ignore_next <= 1'b0; // Break code
	                8'h59: caps_lock <= 1'b1; 
	                default: code <= temp_data[8:1];
	            endcase
	        end
	    end
        end

	// Handle shift key releases (need to track break codes 8'hF0 for shift)
        if (cnt == 10 && ps2_clk_falling_edge && ignore_next) begin
	    if (temp_data[0] == 1'b0 && temp_data[10]==1'b1 && (^temp_data[9:1]==1'b1)) begin
	        if (temp_data[8:1] == 8'h12 || temp_data[8:1] == 8'h59) shift_pressed <= 1'b0;
	        ignore_next <= 1'b0;
	    end
        end
    end

endmodule


// ---------------------------------------------------------------------------
// The Top-Level Module (This is correct and does not need to change)
// ---------------------------------------------------------------------------
//module keyboard_to_leds (
//    input        CLOCK_50,
//    input        PS2_CLK,
//    input        PS2_DAT,
//    output [7:0] LEDG
//);
//
//    wire [7:0] scan_code;
//
//    // We can directly connect the output since the 'code' output of our
//    // new module is already a clean, stable register.
//    assign LEDG = scan_code;
//
//    // Instantiate our new, tutorial-based PS/2 module
//    ps2_decoder ps2_decoder_inst (
//        .clk(CLOCK_50),
//        .ps2_clk_async(PS2_CLK),
//        .ps2_data_async(PS2_DAT),
//        .code(scan_code)
//    );
//    
//endmodule
