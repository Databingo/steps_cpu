module cpu_on_board (
    // -- Pin --
    (* chip_pin = "PIN_L1" *)  input wire CLOCK_50, // 50 MHz clock
    (* chip_pin = "PIN_R22" *) input wire KEY0,     // Active-low reset button
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *) output wire [7:0] LEDG, // 8 green LEDs
    (* chip_pin = "R17" *) output reg LEDR9, // 1 red LEDs breath left most 
    (* chip_pin = "U18, Y18, V19, T18, Y19, U19, R19, R20" *) output wire [7:0] LEDR7_0, // 8 red LEDs right

    (* chip_pin = "H15" *)  input wire PS2_CLK, 
    (* chip_pin = "J14" *)  input wire PS2_DAT 
);

    // -- ROM -- for Boot Program
    (* ram_style = "block" *) reg [31:0] Rom [0:1023]; // 4KB Read Only Memory
    initial $readmemb("rom.mif", Rom);

    // -- RAM -- for Load Program
    (* ram_style = "block" *) reg [31:0] Ram [0:2047]; // 8KB Radom Access Memory
    initial $readmemb("ram.mif", Ram);

    // -- Clock --
    wire clock_1hz;
    clock_slower clock_ins(
        .clk_in(CLOCK_50),
        .clk_out(clock_1hz),
        .reset_n(KEY0)
    );

    wire [31:0] pc;
    wire [31:0] ir_bd; assign ir_bd = Ram[pc>>2];
    wire [31:0] ir_ld; assign ir_ld = {ir_bd[7:0], ir_bd[15:8], ir_bd[23:16], ir_bd[31:24]}; // Endianness swap

    // -- CPU --
    riscv64 cpu (
        //.clk(clock_1hz), 
        .clk(CLOCK_50), 
        .reset(KEY0),     // Active-low reset button
        .instruction(ir_ld),
        .pc(pc),
        .ir(LEDG),
        //.re(re),
        .heartbeat(LEDR9),

	.interrupt_vector(interrupt_vector),
	.interrupt_done(interrupt_done),

        .bus_address(bus_address),
        .bus_write_data(bus_write_data),
        .bus_write_enable(bus_write_enable),
        .bus_read_enable(bus_read_enable),
        .bus_read_data(bus_read_data)
    );
     
    // -- Keyboard -- 
    reg [31:0] data;
    reg [7:0] scan;
    reg key_pressed_delay;
    wire key_pressed;
    wire key_released;

    ps2_decoder ps2_decoder_inst (
        .clk(CLOCK_50),
        .ps2_clk_async(PS2_CLK),
        .ps2_data_async(PS2_DAT),
        //.scan_code(data[7:0])
        //.ascii_code(data[7:0]),
        .scan_code(scan),
        .ascii_code(data[7:0]),
        .key_pressed(key_pressed),
        .key_released(key_released)
     );
    // Drive Keyboard
    always @(posedge CLOCK_50) begin key_pressed_delay <= key_pressed; end
    wire key_pressed_edge = key_pressed && !key_pressed_delay;

    // -- Monitor -- Connected to Bus
    jtag_uart_system my_jtag_system (
        .clk_clk                             (CLOCK_50),
        .reset_reset_n                       (KEY0),
        .jtag_uart_0_avalon_jtag_slave_address   (bus_address[0:0]),
        .jtag_uart_0_avalon_jtag_slave_writedata (bus_write_data[31:0]),
        .jtag_uart_0_avalon_jtag_slave_write_n   (~uart_write_trigger_pulse),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        .jtag_uart_0_avalon_jtag_slave_read_n    (1'b1)
    );

    // -- Bus --
    wire [63:0] bus_address;
    //wire [63:0] bus_read_data;
    wire        bus_read_enable;
    wire [63:0] bus_write_data;
    wire        bus_write_enable;

    // -- Bus controller --
    localparam Rom_base = 32'h0000_0000, Rom_size = 32'h0000_1000; // 4KB ROM
    localparam Ram_base = 32'h0000_1000, Ram_size = 32'h0000_2000; // 8KB RAM
    localparam Stk_base = 32'h0000_3000, Stk_size = 32'h0000_1000; // 4KB STACK
    localparam Art_base = 32'h8000_0000, Key_base = 32'h8000_0010; 
    wire Rom_selected = (bus_address >= Rom_base && bus_address < Rom_base + Rom_size);
    wire Ram_selected = (bus_address >= Ram_base && bus_address < Ram_base + Ram_size);
    wire Stk_selected = (bus_address >= Stk_base && bus_address < Stk_base + Stk_size);
    wire Art_selected = (bus_address == Art_base);
    wire Key_selected = (bus_address == Key_base);

    wire [63:0] bus_read_data = Key_selected ? {56'd0, data[7:0]}:
	                   //Key_selected ? {56'd0, ascii}:
	                   //Art_selected ? {56'd0, ascii}:
	                   Ram_selected ? {32'd0, Ram[bus_address[11:2]]}:
			   Rom_selected ? {32'd0, Rom[bus_address[11:2]]}:
			   64'hDEADBEEF_DEADBEEF;
    wire uart_write_trigger = bus_write_enable && Art_selected;
    reg uart_write_trigger_dly;
    wire uart_write_trigger_pulse;
    always @(posedge CLOCK_50 or negedge KEY0) begin
	if (!KEY0) uart_write_trigger_dly <= 0;
	else uart_write_trigger_dly <= uart_write_trigger;
    end

    assign uart_write_trigger_pulse = uart_write_trigger  && !uart_write_trigger_dly;


    // -- interrupt controller --
    reg [3:0] interrupt_vector;
    wire interrupt_done;
    always @(posedge CLOCK_50 or negedge KEY0) begin
	if (!KEY0) begin
	    interrupt_vector <= 0;
	end else begin
            if (key_pressed_edge && data[7:0]) interrupt_vector <= 1;
            //if (key_pressed_edge) interrupt_vector <= 1;
            if (interrupt_done) interrupt_vector <= 0;
	end
    end

    // -- Timer --
    // -- CSRs --
    // -- BOIS/bootloader --
    // -- Caches --
    // -- MMU(Memory Manamgement Unit) --
    // -- DMA(Direct Memory Access) --?

endmodule



module riscv64(
    input wire clk, 
    input wire reset,     // Active-low reset button
    input wire [31:0] instruction,
    output reg [31:0] pc,
    output reg [31:0] ir,
    output reg [63:0] re [0:31],
    output wire  heartbeat,

    input wire [3:0] interrupt_vector,
    output reg interrupt_done,

    output reg [63:0] bus_address,
    output reg [63:0] bus_write_data,
    output reg        bus_write_enable,
    output reg        bus_read_enable,
    input  wire [63:0] bus_read_data


);
    // -- CSR Registers --
    reg [63:0] csr [0:4096]; // Maximal 12-bit length = 4096
    integer mstatus = 12'h300;      // 0x300 MRW Machine status reg   // 63_SD|37_MBE|36_SBE|35:34_SXL10|22_TSR|21_TW|20_TVW|17_MPRV|12:11_MPP10|7_MPIE|3_MIE|1_SIE|0_WPRI
    integer mie = 12'h304;          // 0x304 MRW Machine interrupt-enable register *
    integer mip = 12'h344;          // 0x344 MRW Machine interrupt pending *
    integer mtvec = 12'h305;        // 0x305 MRW Machine trap-handler base address *
    integer mcause = 12'h342;       // 0x342 MRW Machine trap casue *
    // -- CSR Bits --
    wire mstatus_MIE = csr[mstatus][3];
    wire mie_MEIE = csr[mie][11];
    wire mip_MEIP = csr[mie][11];
 
    
    // -- Immediate decoders (Unchanged) -- 
    wire signed [63:0] w_imm_u = {{32{ir[31]}}, ir[31:12], 12'b0};
    wire [4:0] w_rd  = ir[11:7];
    // -- Bubble signal --
    reg bubble;

    // IF ir (Unchanged)
    always @(posedge clk or negedge reset) begin
        if (!reset) begin 
            heartbeat <= 1'b0; 
            ir <= 32'h00000000; 
        end else begin
            heartbeat <= ~heartbeat; // heartbeat
            ir <= instruction;
        end
    end

    // EXE
    always @(posedge clk or negedge reset) begin
        if (!reset) begin 
	    bubble <= 1'b0;
            pc <= 0;
            // Interrupt
	    bus_read_enable <= 0;
	    bus_write_enable <= 0;
	    interrupt_done <= 0;
        end else begin
	    // PC default +4
            pc <= pc + 4;

            // Interrupt
	    bus_read_enable <= 0;
	    bus_write_enable <= 0;
	    interrupt_done <= 0;
	    if (interrupt_vector == 1) begin
	        bus_address <= 32'h8000_0010; // Key_base ;
	        bus_read_enable <= 1;
	        if (bus_read_enable) begin
	            bus_write_data <= bus_read_data;
	            bus_read_enable <= 0;

	            bus_address <= 32'h8000_0000; // Art_base ;
	            bus_write_enable <= 1;
		    interrupt_done <=1;

                    pc <= 0; // jump to ISR addr
		    bubble <= 1'b1; // bubble wrong fetche instruciton by IF
	         end
	    end else if (bubble) bubble <= 1'b0; // Flush this cycle & Clear bubble signal for the next cycle

	    // IR
	    else begin 
            casez(ir) 
		32'b???????_?????_?????_???_?????_0110111:  re[w_rd] <= w_imm_u; // Lui
		//32'b???????_?????_?????_???_?????_0110111:  begin re[w_rd] <= w_imm_u; data <= 32'h41; end
            endcase
	    end
        end
    end

endmodule
module ps2_decoder (
    input        clk,            // System clock (was clk_in)
    input        ps2_clk_async,  // Asynchronous PS/2 clock (was key_clk)
    input        ps2_data_async, // Asynchronous PS/2 data (was key_data)
    output reg [7:0] scan_code,  // The final, stable 8-bit scan code (was key_byte)
    output reg [7:0] ascii_code, // Turn into ASCII code if possible 
    output reg key_pressed,
    output reg key_released,
    output reg error,
    output wire sft_active,
    output wire alt_active,
    output wire ctr_active
);

    // --- Synchronizer Stage (from tutorial) ---
    // This is the essential double-flop synchronizer.
    reg ps2_clk_r0 = 1'b1, ps2_clk_r1 = 1'b1, ps2_clk_r2 = 1'b1;
    reg ps2_data_r0 = 1'b1, ps2_data_r1 = 1'b1, ps2_data_r2 = 1'b1;

    always @(posedge clk) begin
        ps2_clk_r0 <= ps2_clk_async;
        ps2_clk_r1 <= ps2_clk_r0;
        ps2_clk_r2 <= ps2_clk_r1;
        ps2_data_r0 <= ps2_data_async;
        ps2_data_r1 <= ps2_data_r0;
        ps2_data_r2 <= ps2_data_r1;
    end

    // *-- Robust Deployment PS/2 protocol deserilizer for 11-bit frame --*
    // time_out is drived by 50MHz for count in middle frame every bit internal OR reset to 1 by ps2_clk_falling edge
    // cnt is drived by ps2_clk OR by 50MHz reset to 0 if time_out overflow, 
    // this drop broken frame
    wire ps2_clk_falling_edge = ps2_clk_r2 & (~ps2_clk_r1);
    reg [3:0] cnt = 0;
    reg [10:0] temp_data;
    reg [16:0] time_out; // 2^17-1 = 65536*2-1: about 2.62ms at 50MHz | PS2 10kHz, 11 bits take 1.1ms, 5kHz take 2.2ms

    always @(posedge clk) begin
        if (ps2_clk_falling_edge) begin //start at frame bit 0
	    time_out <= 1;
            //if (cnt >= 10) cnt <= 0;
            if (cnt == 10) cnt <= 0;
            else cnt <= cnt + 1;
	    temp_data[cnt] <= ps2_data_r2;
        end else begin
	    if (cnt > 0) time_out <= time_out + 1; // like IF-EXE working same time but need one cycle to effect with each other
	    if (time_out == 0) cnt <= 0; // paused at cnt=0, time_out=1
        end
    end

    // -- Decode to Scan Code Set 2 --
    //reg ignore_next = 0;
    //reg shift_pressed = 0;
    reg cap_lock = 0;
    reg extended = 0;
    reg break_code = 0;

    reg alt_l = 0, alt_r = 0;
    reg ctr_l = 0, ctr_r = 0;
    reg sft_l = 0, sft_r = 0;
    reg num_lock = 0;
    reg scroll_lock = 0;
    //reg [7:0] last_key;

    always @(posedge clk) begin
	key_pressed <= 0;
	key_released <= 0;
        if (cnt == 10 && ps2_clk_falling_edge) begin
            // Verify received data frame: start bit=0, data 8-bits, parity 1-bit, stop bit=1, odd parity calculate be 1
	    if (temp_data[0] == 1'b0 && temp_data[10]==1'b1 && (^temp_data[9:1]==1'b1)) begin
		error <= 0;
                scan_code <= temp_data[8:1];
	        if (break_code) begin 
	            break_code <= 0;
		    case (temp_data[8:1]) // Modifier Keys released
			8'h12: sft_l <= 0; 
			8'h59: sft_r <= 0;
			8'h14: if (!extended) ctr_l <=0; else ctr_r <=0; // ctr_left_break:hF0_h14 ctr_right_break:hE0_hF0_h14
			8'h11: if (!extended) alt_l <=0; else alt_r <=0; // alt_left_break:hF0_h11 alt_right_break:hE0_hF0_h11
		    endcase
		    key_released <= 1;
		    if (extended) extended <= 0;
		end else begin
	            case (temp_data[8:1]) 
			8'hE0: extended <= 1; // Mark Extend Keys
	                8'hF0: break_code <= 1; // Mark Break Keys
	                8'h58: cap_lock <= ~cap_lock; // Mark Modifier Keys
	                8'h77: num_lock <= ~num_lock;
	                8'h7E: scroll_lock <= ~scroll_lock;
	                8'h12: sft_l <= 1; 
	                8'h59: sft_r <= 1; 
			8'h14: if (!extended) ctr_l <= 1; else ctr_r <=1; // ctr_left_make:h14  ctr_right_make:hE0_h14 
			8'h11: if (!extended) alt_l <= 1; else alt_r <=1; // alt_left_make:h11  alt_right_make:hE0_h11
	            endcase
	            if (temp_data[8:1] != 8'hE0 && temp_data[8:1] != 8'hF0) key_pressed <=1;
		    if (extended && temp_data[8:1] != 8'hF0) extended <= 0;
	        end
	    end else error <= 1;
        end
    end


// -- Scan Code Set 2 to ASCII --
assign sft_active = sft_l || sft_r;
assign ctr_active = ctr_l || ctr_r;
assign alt_active = alt_l || alt_r;
wire cap_active = cap_lock;    
wire shift_active = sft_active ^ cap_active;

always @(*) begin
    ascii_code = 8'h00; // Default to 0 for non-printable keys: F1-F12 etc.
    if (!break_code && !extended) begin
        case(scan_code) // with ASCII Control code support
            // Number 
            8'h16: ascii_code = sft_active ? 8'h21 : 8'h31; // ! 1
            8'h1E: ascii_code = sft_active ? 8'h40 : 8'h32; // @ 2
            8'h26: ascii_code = sft_active ? 8'h23 : 8'h33; // # 3
            8'h25: ascii_code = sft_active ? 8'h24 : 8'h34; // $ 4
            8'h2E: ascii_code = sft_active ? 8'h25 : 8'h35; // % 5
            8'h36: ascii_code = ctr_active ? 8'h1E : (shift_active ? 8'h5E : 8'h36); // ^ 6
            8'h3D: ascii_code = sft_active ? 8'h26 : 8'h37; // & 7
            8'h3E: ascii_code = sft_active ? 8'h2A : 8'h38; // * 8
            8'h46: ascii_code = sft_active ? 8'h28 : 8'h39; // ( 9
            8'h45: ascii_code = sft_active ? 8'h29 : 8'h30; // ) 0
            // Symbol 
            8'h0E: ascii_code = sft_active ? 8'h7E : 8'h60; // ~ `
            8'h4E: ascii_code = ctr_active ? 8'h1F : (shift_active ? 8'h5F : 8'h2D); // _ -
            8'h55: ascii_code = sft_active ? 8'h2B : 8'h3D; // + =
            8'h54: ascii_code = ctr_active ? 8'h1B : (shift_active ? 8'h7B : 8'h5B); // { [
            8'h5B: ascii_code = ctr_active ? 8'h1D : (shift_active ? 8'h7D : 8'h5D); // } ]
            8'h5D: ascii_code = ctr_active ? 8'h1C : (shift_active ? 8'h7C : 8'h5C); // | \
            8'h4C: ascii_code = sft_active ? 8'h3A : 8'h3B; // : ;
            8'h52: ascii_code = sft_active ? 8'h22 : 8'h27; // " '
            8'h41: ascii_code = sft_active ? 8'h3C : 8'h2C; // < ,
            8'h49: ascii_code = sft_active ? 8'h3E : 8'h2E; // > .
            8'h4A: ascii_code = ctr_active ? 8'h7F : (shift_active ? 8'h3F : 8'h2F); // ? /
            // Letter
            8'h1C: ascii_code = ctr_active ? 8'h01 : (shift_active ? 8'h41 : 8'h61); // A a 
            8'h32: ascii_code = ctr_active ? 8'h02 : (shift_active ? 8'h42 : 8'h62); // B b
            8'h21: ascii_code = ctr_active ? 8'h03 : (shift_active ? 8'h43 : 8'h63); // C c
            8'h23: ascii_code = ctr_active ? 8'h04 : (shift_active ? 8'h44 : 8'h64); // D d
            8'h24: ascii_code = ctr_active ? 8'h05 : (shift_active ? 8'h45 : 8'h65); // E e
            8'h2B: ascii_code = ctr_active ? 8'h06 : (shift_active ? 8'h46 : 8'h66); // F f
            8'h34: ascii_code = ctr_active ? 8'h07 : (shift_active ? 8'h47 : 8'h67); // G g
            8'h33: ascii_code = ctr_active ? 8'h08 : (shift_active ? 8'h48 : 8'h68); // H h
            8'h43: ascii_code = ctr_active ? 8'h09 : (shift_active ? 8'h49 : 8'h69); // I i
            8'h3B: ascii_code = ctr_active ? 8'h0A : (shift_active ? 8'h4A : 8'h6A); // J j
            8'h42: ascii_code = ctr_active ? 8'h0B : (shift_active ? 8'h4B : 8'h6B); // K k
            8'h4B: ascii_code = ctr_active ? 8'h0C : (shift_active ? 8'h4C : 8'h6C); // L l
            8'h3A: ascii_code = ctr_active ? 8'h0D : (shift_active ? 8'h4D : 8'h6D); // M m
            8'h31: ascii_code = ctr_active ? 8'h0E : (shift_active ? 8'h4E : 8'h6E); // N n
            8'h44: ascii_code = ctr_active ? 8'h0F : (shift_active ? 8'h4F : 8'h6F); // O o
            8'h4D: ascii_code = ctr_active ? 8'h10 : (shift_active ? 8'h50 : 8'h70); // P p
            8'h15: ascii_code = ctr_active ? 8'h11 : (shift_active ? 8'h51 : 8'h71); // Q q
            8'h2D: ascii_code = ctr_active ? 8'h12 : (shift_active ? 8'h52 : 8'h72); // R r
            8'h1B: ascii_code = ctr_active ? 8'h13 : (shift_active ? 8'h53 : 8'h73); // S s
            8'h2C: ascii_code = ctr_active ? 8'h14 : (shift_active ? 8'h54 : 8'h74); // T t
            8'h3C: ascii_code = ctr_active ? 8'h15 : (shift_active ? 8'h55 : 8'h75); // U u
            8'h2A: ascii_code = ctr_active ? 8'h16 : (shift_active ? 8'h56 : 8'h76); // V v
            8'h1D: ascii_code = ctr_active ? 8'h17 : (shift_active ? 8'h57 : 8'h77); // W w
            8'h22: ascii_code = ctr_active ? 8'h18 : (shift_active ? 8'h58 : 8'h78); // X x
            8'h35: ascii_code = ctr_active ? 8'h19 : (shift_active ? 8'h59 : 8'h79); // Y y
            8'h1A: ascii_code = ctr_active ? 8'h1A : (shift_active ? 8'h5A : 8'h7A); // Z z
            // Special characters
            8'h29: ascii_code = 8'h20; // Space
            8'h66: ascii_code = 8'h08; // Backspace
            8'h5A: ascii_code = 8'h0D; // Enter
            8'h76: ascii_code = 8'h1B; // Escape
            8'h0D: ascii_code = 8'h09; // Tab
            // Number pad (Num Lock)
            8'h69: ascii_code = num_lock ? 8'h31 : 8'h00; // 1
            8'h72: ascii_code = num_lock ? 8'h32 : 8'h00; // 2
            8'h7A: ascii_code = num_lock ? 8'h33 : 8'h00; // 3
            8'h6B: ascii_code = num_lock ? 8'h34 : 8'h00; // 4
            8'h73: ascii_code = num_lock ? 8'h35 : 8'h00; // 5
            8'h74: ascii_code = num_lock ? 8'h36 : 8'h00; // 6
            8'h6C: ascii_code = num_lock ? 8'h37 : 8'h00; // 7
            8'h75: ascii_code = num_lock ? 8'h38 : 8'h00; // 8
            8'h7D: ascii_code = num_lock ? 8'h39 : 8'h00; // 9
            8'h70: ascii_code = num_lock ? 8'h30 : 8'h00; // 0
            8'h7C: ascii_code = 8'h2A; // * 
            8'h7B: ascii_code = 8'h2D; // -
            8'h79: ascii_code = 8'h2B; // +
            8'h71: ascii_code = 8'h2E; // .
        endcase
    end
    if (extended) begin  // extended code LGUI RCTRL RGUI RALT APPS PRNTSCRN INSERT HOME PGUP DELETE END UARROW LARROW DARROW RARROW KP/ KPENT POWER SLEEP WAKE | window multimedia scan code
	case(scan_code)
            8'h71: ascii_code = 8'h7F; // Del
	    8'h4A: ascii_code = 8'h2F; // keypad /
	    8'h5A: ascii_code = 8'h0D; // keypad Enter
	    // hE0_h12_hE0_h7C // PrintScreen key --> 0x00 0x00 for now
	    // Optinal custom mapping for navigation
	    //8'h75: ascii_code = 8'h80; // Up Arrow
	    //8'h72: ascii_code = 8'h81; // Down
	    //8'h6B: ascii_code = 8'h82; // Left
	    //8'h74: ascii_code = 8'h83; // Right
	    //8'h6C: ascii_code = 8'h84; // Home
	    //8'h69: ascii_code = 8'h85; // End
	    //8'h70: ascii_code = 8'h86; // Insert
	endcase
    end
end
//assign key_pressed = (ascii_code != 8'h00);
endmodule

// PS2 protocol --> 11 bits frame sequences --> Scan code Set 2
// Keyboard Protocol --> Scan code to ASCII code
// 1.Make Code: Sent when a key is pressed. press A code 1C (printable)
// 2.Break Code: Sent when a key is released. release A code F0 1C
// 3.Extend Code: Special keys prefixed with 0xE0(added to IBM PC keyboard). press special key Arraw code E0 74 release  E0 F0 74
// 4.Modifier Keys: Shift, Ctrl, Alt, CapsLock, NumLock, ScrollLock -> Combination presses via track modifiers: Control code: Ctrl+A=0x01 ...
// https://tigerheli.mameworld.info/encoder/scancodesset2.htm
// fn?
