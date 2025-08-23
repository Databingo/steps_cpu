module ps2_decoder (
    input        clk,            // System clock (was clk_in)
    input        ps2_clk_async,  // Asynchronous PS/2 clock (was key_clk)
    input        ps2_data_async, // Asynchronous PS/2 data (was key_data)
    output reg [7:0] scan_code,  // The final, stable 8-bit scan code (was key_byte)
    output reg [7:0] ascii_code, // Turn into ASCII code if possible 
    output reg key_pressed,
    output reg key_released
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
    reg extended = 0;
    reg break_code = 0;

    // This is the core state machine for capturing the 11-bit frame.
    always @(posedge clk) begin
        if (ps2_clk_falling_edge) begin
            if (cnt >= 10) begin
                cnt <= 0;
            end else begin
                cnt <= cnt + 1;
            end
	    temp_data[cnt] <= ps2_data_r1;

        end
    end

    // --- Output Latching Logic (simplified from tutorial) ---
    always @(posedge clk) begin
	key_pressed <= 0;
	key_released <= 0;
	// Output latching logci with shift/caps tracking
        if (cnt == 0) extended <= 1'b0; // Reset extended flag after processing
        if (cnt == 10 && ps2_clk_falling_edge) begin
            // the received data parity is 1
	    if (temp_data[0] == 1'b0 && temp_data[10]==1'b1 && (^temp_data[9:1]==1'b1)) begin
	        if (ignore_next) begin 
		    ignore_next <= 1'b0; 
	            break_code <= 1'b1;
	            scan_code <= temp_data[8:1];
		    // Handle key release
		    if (temp_data[8:1] != 8'hE0 && temp_data[8:1] != 8'hF0) begin key_released <= 1'b1; end
		    // Handle shife key release
		    if (temp_data[8:1] == 8'h12 || temp_data[8:1] == 8'h59) begin shift_pressed <= 1'b0; end
		end
	        else begin
		    break_code <= 1'b0;
	            scan_code <= temp_data[8:1];
	            case (temp_data[8:1]) 
			8'hE0: begin extended <= 1'b1; ignore_next <= 1'b1; end // Extended code
	                8'hF0: ignore_next <= 1'b0; // Break code
	                8'h12, 8'h59: shift_pressed <= 1'b1; // Left or Right Shift
	                8'h59: caps_lock <= ~caps_lock; // Caps Lock
	                default: key_pressed <= 1'b1;
	            endcase
	        end
	    end
        end
    end

wire shift_active = shift_pressed ^ caps_lock;    

always @(*) begin
    ascii_code = scan_code; // Default to scan code if no ASCII mapping
    case(scan_code)
	// Number (top row)
	8'h16: ascii_code = shift_active ? 8'h21 : 8'h31; // ! 1
	8'h1E: ascii_code = shift_active ? 8'h40 : 8'h32; // @ 2
	8'h26: ascii_code = shift_active ? 8'h23 : 8'h33; // # 3
	8'h25: ascii_code = shift_active ? 8'h24 : 8'h34; // $ 4
	8'h2E: ascii_code = shift_active ? 8'h25 : 8'h35; // % 5
	8'h36: ascii_code = shift_active ? 8'h5E : 8'h36; // ^ 6
	8'h3D: ascii_code = shift_active ? 8'h26 : 8'h37; // & 7
	8'h3E: ascii_code = shift_active ? 8'h2A : 8'h38; // * 8
	8'h46: ascii_code = shift_active ? 8'h28 : 8'h39; // ( 9
	8'h45: ascii_code = shift_active ? 8'h29 : 8'h30; // ) 0
	// Letters (a-z)
	8'h1C: ascii_code = shift_active ? 8'h41 : 8'h61; // a A 
	8'h32: ascii_code = shift_active ? 8'h42 : 8'h62; // b B
	8'h21: ascii_code = shift_active ? 8'h43 : 8'h63; // c C
	8'h23: ascii_code = shift_active ? 8'h44 : 8'h64; // d D
	8'h24: ascii_code = shift_active ? 8'h45 : 8'h65; // e E
	8'h2B: ascii_code = shift_active ? 8'h46 : 8'h66; // f F
	8'h34: ascii_code = shift_active ? 8'h47 : 8'h67; // g G
	8'h33: ascii_code = shift_active ? 8'h48 : 8'h68; // h H
	8'h43: ascii_code = shift_active ? 8'h49 : 8'h69; // i I
	8'h3B: ascii_code = shift_active ? 8'h4A : 8'h6A; // j J
	8'h42: ascii_code = shift_active ? 8'h4B : 8'h6B; // k K
	8'h4B: ascii_code = shift_active ? 8'h4C : 8'h6C; // l L
	8'h3A: ascii_code = shift_active ? 8'h4D : 8'h6D; // m M
	8'h31: ascii_code = shift_active ? 8'h4E : 8'h6E; // n N
	8'h44: ascii_code = shift_active ? 8'h4F : 8'h6F; // o O
	8'h4D: ascii_code = shift_active ? 8'h50 : 8'h70; // p P
	8'h15: ascii_code = shift_active ? 8'h51 : 8'h71; // q Q
	8'h2D: ascii_code = shift_active ? 8'h52 : 8'h72; // r R
	8'h1B: ascii_code = shift_active ? 8'h53 : 8'h73; // s S
	8'h2C: ascii_code = shift_active ? 8'h54 : 8'h74; // t T
	8'h3C: ascii_code = shift_active ? 8'h55 : 8'h75; // u U
	8'h2A: ascii_code = shift_active ? 8'h56 : 8'h76; // v V
	8'h1D: ascii_code = shift_active ? 8'h57 : 8'h77; // w W
	8'h22: ascii_code = shift_active ? 8'h58 : 8'h78; // x X
	8'h35: ascii_code = shift_active ? 8'h59 : 8'h79; // y Y
	8'h1A: ascii_code = shift_active ? 8'h5A : 8'h7A; // z Z
	// Special characters
	8'h29: ascii_code = 8'h20; // Space
	8'h66: ascii_code = 8'h08; // Backspcae
	8'h5A: ascii_code = 8'h0D; // Enter
	8'h76: ascii_code = 8'h1B; // Escape
	// Symboles (keep as scan code if extended)
	8'h0E: if (!extended) ascii_code = shift_active ? 8'h7E : 8'h60; // ` ~
	8'h4E: if (!extended) ascii_code = shift_active ? 8'h5F : 8'h2D; // - _
	8'h55: if (!extended) ascii_code = shift_active ? 8'h2B : 8'h3D; // = +
	8'h54: if (!extended) ascii_code = shift_active ? 8'h7B : 8'h5B; // [ {
	8'h5B: if (!extended) ascii_code = shift_active ? 8'h7D : 8'h5D; // ] }
	8'h5D: if (!extended) ascii_code = shift_active ? 8'h7C : 8'h5C; // \ |
	8'h4C: if (!extended) ascii_code = shift_active ? 8'h3A : 8'h3B; // ; :
	8'h52: if (!extended) ascii_code = shift_active ? 8'h22 : 8'h27; // ' "
	8'h41: if (!extended) ascii_code = shift_active ? 8'h3C : 8'h2C; // , <
	8'h49: if (!extended) ascii_code = shift_active ? 8'h3E : 8'h2E; // . >
	8'h4A: if (!extended) ascii_code = shift_active ? 8'h3F : 8'h2F; // / ?
    endcase
end
 

endmodule

	//// Main keyboard numbers
        //8'h16: scan_to_ascii = "1";
        //8'h1E: scan_to_ascii = "2";
        //8'h26: scan_to_ascii = "3";
        //8'h25: scan_to_ascii = "4";
        //8'h2E: scan_to_ascii = "5";
        //8'h36: scan_to_ascii = "6";
        //8'h3D: scan_to_ascii = "7";
        //8'h3E: scan_to_ascii = "8";
        //8'h46: scan_to_ascii = "9";
        //8'h45: scan_to_ascii = "0";
	//// Number pad numbers (with Num Lock on)o
	//8'h69: scan_to_ascii = 8'h31; // 1
        //8'h72: scan_to_ascii = 8'h32; // 2
        //8'h7A: scan_to_ascii = 8'h33; // 3
        //8'h6B: scan_to_ascii = 8'h34; // 4
        //8'h73: scan_to_ascii = 8'h35; // 5
        //8'h74: scan_to_ascii = 8'h36; // 6
        //8'h6C: scan_to_ascii = 8'h37; // 7
        //8'h75: scan_to_ascii = 8'h38; // 8
        //8'h7D: scan_to_ascii = 8'h39; // 9
        //8'h70: scan_to_ascii = 8'h30; // 0
