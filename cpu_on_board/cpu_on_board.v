// =================================================================================
// Original CPU file with minimal changes to force-send 'H' every clock cycle.
// =================================================================================

module cpu_on_board (
    (* chip_pin = "PIN_L1" *)  input wire CLOCK_50, // 50 MHz clock
    (* chip_pin = "PIN_R22" *) input wire KEY0,     // Active-low reset button
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *) output wire [7:0] LEDG, // 8 green LEDs
    (* chip_pin = "R17" *) output reg LEDR9, // 1 red LEDs breath left most 
    (* chip_pin = "U18, Y18, V19, T18, Y19, U19, R19, R20" *) output wire [7:0] LEDR7_0, // 8 red LEDs right

    (* chip_pin = "H15" *)  input wire PS2_CLK, 
    (* chip_pin = "J14" *)  input wire PS2_DAT 
);

    // --- Memory and Original CPU State (Unchanged) ---
    (* ram_style = "block" *) reg [31:0] mem [0:2999]; // Unified Memory
    initial $readmemb("mem.mif", mem);

    reg [24:0] counter; // Original, unused counter
    reg [31:0] addr_pc; // Original, unused pc
    
    reg [31:0] ir;
    wire [31:0] ir_bd; assign ir_bd = mem[pc>>2];
    wire [31:0] ir_ld; assign ir_ld = {ir_bd[7:0], ir_bd[15:8], ir_bd[23:16], ir_bd[31:24]}; // Endianness swap

    reg [31:0] pc;
    reg [63:0] re [0:31]; // General-purpose registers (x0-x31)

    wire clock_1hz;
    clock_slower clock_ins(
        .clk_in(CLOCK_50),
        .clk_out(clock_1hz),
        .reset_n(KEY0)
    );

    // --- Immediate decoders (Unchanged) --- 
    wire signed [63:0] w_imm_u = {{32{ir[31]}}, ir[31:12], 12'b0};
    wire [4:0] w_rd  = ir[11:7];

    // --- Wires for Avalon-MM Interface (Unchanged from previous JTAG version) ---
    wire [0:0]  avalon_address;
    wire        avalon_write;
    wire [31:0] avalon_writedata;

    reg [31:0] data;

    // --- Qsys System Instantiation (Unchanged from previous JTAG version) ---
    jtag_uart_system my_jtag_system (
        .clk_clk                             (CLOCK_50),
        .reset_reset_n                       (KEY0),
        .jtag_uart_0_avalon_jtag_slave_address   (avalon_address),
        .jtag_uart_0_avalon_jtag_slave_writedata (avalon_writedata),
        .jtag_uart_0_avalon_jtag_slave_write_n   (~avalon_write),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        .jtag_uart_0_avalon_jtag_slave_read_n    (1'b1)
    );

    // IF ir (Unchanged)
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin 
            LEDR9 <= 1'b0; 
            ir <= 32'h00000000; 
        end else begin
            LEDR9 <= ~LEDR9; // heartbeat
            ir <= ir_ld;
        end
    end

    // EXE pc (Unchanged, CPU runs normally)
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin 
            pc <= 0;
        end else begin
            pc <= pc + 4;
            re[31] <= 1'b0; // This was in your original code
            
	    //data <= 32'h48;
            casez(ir) 
		32'b???????_?????_?????_???_?????_0110111:  re[w_rd] <= w_imm_u; // Lui
		//32'b???????_?????_?????_???_?????_0110111:  begin re[w_rd] <= w_imm_u; data <= 32'h41; end
            endcase
        end
    end

   // LED Assignments (Unchanged)
   assign LEDG = ir[7:0];
   assign LEDR7_0 = re[31][19:12];
   
   // --- Avalon Bus Driver Logic ---
   // <<< CHANGED: This is the only part we are modifying for the test.
   // We will force a write of the character 'H' on EVERY rising edge of the 1Hz clock.
   
   reg clock_1hz_dly;
   
   // This small always block generates a single-cycle pulse on every 1Hz clock tick.
   // It's active as long as the CPU is not in reset.
   always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            clock_1hz_dly <= 1'b0;
        end else begin
            clock_1hz_dly <= clock_1hz;
        end
   end
   
   wire clock_1hz_rising_edge = clock_1hz && !clock_1hz_dly; 

   assign avalon_write     = clock_1hz_rising_edge; // Force the write signal high every cycle
   assign avalon_address   = 1'b0;            // Always write to the data register (address 0)
   //assign avalon_writedata = 32'h48;          // Force the data to be 0x48, which is the ASCII code for 'H'
   //assign avalon_writedata = {24'b0, scan_to_ascii(data)};          // Force the data to be 0x48, which is the ASCII code for 'H'
   assign avalon_writedata = {24'b0, data};          // Force the data to be 0x48, which is the ASCII code for 'H'

//wire [7:0] scan_code;
//assign LEDG = scan_code;

ps2_decoder ps2_decoder_inst (
    .clk(CLOCK_50),
    .ps2_clk_async(PS2_CLK),
    .ps2_data_async(PS2_DAT),
    //.code(scan_code)
    .scan_code(data[7:0])
);
endmodule


// clock_slower module (Unchanged)
module clock_slower(
    input wire clk_in,
    input wire reset_n,
    output reg clk_out
);
    reg [24:0] counter; 
    initial begin
        clk_out <= 0;
        counter <= 0;
    end
    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            clk_out <= 0;
            counter <= 0;
        end else begin
            if (counter == 25000000 - 1) begin
                counter <= 0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule


function [7:0] scan_to_ascii;
    input [7:0] scan;
    case (scan)
	// Main keyboard numbers
        8'h16: scan_to_ascii = "1";
        8'h1E: scan_to_ascii = "2";
        8'h26: scan_to_ascii = "3";
        8'h25: scan_to_ascii = "4";
        8'h2E: scan_to_ascii = "5";
        8'h36: scan_to_ascii = "6";
        8'h3D: scan_to_ascii = "7";
        8'h3E: scan_to_ascii = "8";
        8'h46: scan_to_ascii = "9";
        8'h45: scan_to_ascii = "0";
	// Number pad numbers (with Num Lock on)o
	8'h69: scan_to_ascii = 8'h31; // 1
        8'h72: scan_to_ascii = 8'h32; // 2
        8'h7A: scan_to_ascii = 8'h33; // 3
        8'h6B: scan_to_ascii = 8'h34; // 4
        8'h73: scan_to_ascii = 8'h35; // 5
        8'h74: scan_to_ascii = 8'h36; // 6
        8'h6C: scan_to_ascii = 8'h37; // 7
        8'h75: scan_to_ascii = 8'h38; // 8
        8'h7D: scan_to_ascii = 8'h39; // 9
        8'h70: scan_to_ascii = 8'h30; // 0


        default: scan_to_ascii = "?"; // fallback
    endcase
endfunction

