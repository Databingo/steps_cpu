`include "header.vh"

module cpu_on_board (
    // -- Pin --
    (* chip_pin = "PIN_L1" *)  input wire CLOCK_50, // 50 MHz clock
    (* chip_pin = "PIN_R22" *) input wire KEY0,     // Active-low reset button
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *) output wire [7:0] LEDG, // 8 green LEDs
    (* chip_pin = "R17" *) output reg LEDR9, // 1 red LEDs breath left most 
    (* chip_pin = "R20" *) output wire LEDR0, // 
    (* chip_pin = "R19" *) output wire LEDR1, // 
    (* chip_pin = "U18, Y18, V19, T18, Y19, U19" *) output wire [5:0] LEDR_PC, // 8 red LEDs right
    (* chip_pin = "F4" *)  output wire HEX30,
    (* chip_pin = "G5" *)  output wire HEX20,
    (* chip_pin = "G6" *)  output wire HEX21,
    (* chip_pin = "E1" *)  output wire HEX10,
    (* chip_pin = "H6" *)  output wire HEX11,
    (* chip_pin = "J2" *)  output wire HEX00,
    (* chip_pin = "J1" *)  output wire HEX01,
    (* chip_pin = "H2" *)  output wire HEX02,
    (* chip_pin = "H1" *)  output wire HEX03,
    (* chip_pin = "H15" *)  input wire PS2_CLK, 
    (* chip_pin = "J14" *)  input wire PS2_DAT,
    (* chip_pin = "V20" *)  output wire SD_CLK, //SD_CLK
    (* chip_pin = "Y20" *)  inout wire SD_CMD, // SD_CMD (MOSI)
    (* chip_pin = "W20" *)  inout wire SD_DAT0, // SD_DAT (MISO)
    (* chip_pin = "U20" *)  output wire SD_DAT3 // SD_DAT3
);

    // -- MEM -- minic L1 cache
    (* ram_style = "block" *) reg [31:0] Cache [0:3071];
    integer i;
    initial begin
        $readmemb("rom.mif", Cache, `Rom_base>>2);
        $readmemb("ram.mif", Cache, `Ram_base>>2);
    end

    // -- Clock --
    wire clock_1hz;
    clock_slower clock_ins(
        .clk_in(CLOCK_50),
        .clk_out(clock_1hz),
        .reset_n(KEY0)
    );

    wire [63:0] pc;
    reg [31:0] ir_bd;
    // IR_LD BRAM Port A read
    always @(posedge CLOCK_50) begin ir_bd <= Cache[pc>>2]; end
    wire [31:0] ir_ld; assign ir_ld = {ir_bd[7:0], ir_bd[15:8], ir_bd[23:16], ir_bd[31:24]}; // Endianness swap
    assign LEDR_PC = pc/4;

    // -- CPU --
    riscv64 cpu (
        .clk(clock_1hz), 
        //.clk(CLOCK_50), 
        .reset(KEY0),     
        .instruction(ir_ld),
        .pc(pc),
        .ir(LEDG),
        .heartbeat(LEDR9),

        .interrupt_vector(interrupt_vector),
        .interrupt_ack(interrupt_ack),

        .bus_address(bus_address),
        .bus_write_data(bus_write_data),
        .bus_write_enable(bus_write_enable),
        .bus_read_enable(bus_read_enable),

        .bus_read_type(bus_read_type), // lb lh lw ld lbu lhu lwu 
        .bus_write_type(bus_write_type), // sb sh sw sd 
        .bus_read_done(bus_read_done),
        .bus_read_data(bus_read_data)
    );

    // -- Keyboard -- 
    reg [7:0] ascii;
    reg [7:0] scan;
    reg key_pressed_delay;
    wire key_pressed;
    wire key_released;

    ps2_decoder ps2_decoder_inst (
        .clk(CLOCK_50),
        .ps2_clk_async(PS2_CLK),
        .ps2_data_async(PS2_DAT),
        .scan_code(scan),
        .ascii_code(ascii),
        .key_pressed(key_pressed),
        .key_released(key_released)
     );
    always @(posedge CLOCK_50) begin key_pressed_delay <= key_pressed; end
    wire key_pressed_edge = key_pressed && !key_pressed_delay;

    // -- Monitor -- Connected to Bus
    jtag_uart_system my_jtag_system (
        .clk_clk                                 (CLOCK_50),
        .reset_reset_n                           (KEY0),
        .jtag_uart_0_avalon_jtag_slave_address   (bus_address[0:0]),
        .jtag_uart_0_avalon_jtag_slave_writedata (bus_write_data[31:0]),
        .jtag_uart_0_avalon_jtag_slave_write_n   (~uart_write_trigger_pulse),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        .jtag_uart_0_avalon_jtag_slave_read_n    (1'b1)
    );

    // -- Bus --
    reg  [63:0] bus_read_data;
    wire [63:0] bus_address;
    wire        bus_read_enable;
    wire [63:0] bus_write_data;
    wire        bus_write_enable;
    wire [2:0]  bus_read_type; // lb lbu...
    wire [2:0]  bus_write_type; // sbhwd...

    // Address Decoding --
    wire Rom_selected = (bus_address >= `Rom_base && bus_address < `Rom_base + `Rom_size);
    wire Ram_selected = (bus_address >= `Ram_base && bus_address < `Ram_base + `Ram_size);
    wire Key_selected = (bus_address == `Key_base);
    wire Art_selected = (bus_address == `Art_base);
    wire Sdc_addr_selected = (bus_address == `Sdc_addr);
    wire Sdc_read_selected = (bus_address == `Sdc_read);
    wire Sdc_write_selected = (bus_address == `Sdc_write);
    wire Sdc_ready_selected = (bus_address == `Sdc_ready);
    wire Sdc_cache_selected = (bus_address >= `Sdc_base && bus_address < (`Sdc_base + 512));
    wire Sdc_avail_selected = (bus_address == `Sdc_avail);

    // Read & Write BRAM Port B 
    reg [63:0] bus_address_reg;
    reg [63:0] bus_address_reg_full;
    reg [63:0] data;
    reg ld = 0;
    reg sd = 0;
    reg bus_read_done = 1;
    //reg bus_write_done = 1;
    reg [63:0] next_addr;

    always @(posedge CLOCK_50) begin
        bus_address_reg <= bus_address>>2;
        bus_address_reg_full <= bus_address;
        sd_rd_start <= 0;

        if (bus_read_enable) begin bus_read_done <= 0; end
        //if (bus_write_enable) begin bus_write_done <= 0; end

        // Read
        if (bus_read_done==0) begin 
            if (Key_selected) begin bus_read_data <= {32'd0, 24'd0, ascii}; bus_read_done <= 1; end
	    if (Ram_selected) begin 
	        casez(bus_read_type)
	            3'b011: begin // 011Ld
		        case(ld)
			    0: begin bus_read_data[31:0]  <= Cache[bus_address_reg]; bus_address_reg <= bus_address_reg +1; ld <= 1; end
		            1: begin bus_read_data[63:32] <= Cache[bus_address_reg]; ld <= 0; bus_read_done <= 1; end
			endcase
		    end 
		    default: begin bus_read_data <= Cache[bus_address_reg] >> (8*bus_address_reg_full[1:0]); bus_read_done <= 1; end // 000Lb 100Lbu 001Lh 101Lhu 010Lw 110Lwu
		endcase
	    end

            if (Sdc_ready_selected) begin bus_read_data <= {63'd0, sd_ready}; bus_read_done <= 1; end
	    if (Sdc_cache_selected) begin bus_read_data <= {56'd0, sd_cache[cid]}; bus_read_done <= 1; end // one byte for all load
	   //if(Sdc_cache_selected)begin bus_read_data<={sd_cache[cid+7],sd_cache[cid+6],sd_cache[cid+5],sd_cache[cid+4],sd_cache[cid+3],sd_cache[cid+2],sd_cache[cid+1],sd_cache[cid]};bus_read_done<=1;end
            //if (Sdc_cache_selected && cid < 512) begin   // resource only 18752.                                              
	    //    casez(bus_read_type)
	    //        3'b000: bus_read_data <= {{56{sd_cache[cid][7]}}, sd_cache[cid]};  // lb
	    //        3'b100: bus_read_data <= {56'b0, sd_cache[cid]};           // lbu
	    //        3'b001: bus_read_data <= {{48{sd_cache[cid+1][7]}}, sd_cache[cid+1], sd_cache[cid]};  // lh
	    //        3'b101: bus_read_data <= {48'b0, sd_cache[cid+1], sd_cache[cid]};           // lhu
	    //        3'b010: bus_read_data <= {{32{sd_cache[cid+3][7]}}, sd_cache[cid+3], sd_cache[cid+2], sd_cache[cid+1], sd_cache[cid]};  // lw
	    //        3'b110: bus_read_data <= {32'b0, sd_cache[cid+3], sd_cache[cid+2], sd_cache[cid+1], sd_cache[cid]};  // lwu
	    //        3'b011: bus_read_data <= {sd_cache[cid+7], sd_cache[cid+6], sd_cache[cid+5], sd_cache[cid+4], sd_cache[cid+3], sd_cache[cid+2], sd_cache[cid+1], sd_cache[cid]};  // ld
	    //        default:;// 3'b111 bus_read_data <= 64'hxxxxxxxx_xxxxxxxx for debuging
	    //    endcase
	    //    bus_read_done <= 1; 
	    //end 
            if (Sdc_avail_selected) begin bus_read_data <= {63'd0, sd_cache_available}; bus_read_done <= 1; end 
        end

        // Write
        if (bus_write_enable || sd!=0 ) begin 
	    if (Ram_selected) begin 
		casez(bus_write_type) // 000sb 001sh 010sw 011sd
		    3'b000: begin //sb
			if (bus_address[1:0] == 0) Cache[bus_address[63:2]][7:0] <= bus_write_data[7:0];
			if (bus_address[1:0] == 1) Cache[bus_address[63:2]][15:8] <= bus_write_data[7:0];
			if (bus_address[1:0] == 2) Cache[bus_address[63:2]][23:16] <= bus_write_data[7:0];
			if (bus_address[1:0] == 3) Cache[bus_address[63:2]][31:24] <= bus_write_data[7:0];
			end
		    3'b001: begin //sh
			if (bus_address[1:0] == 0) Cache[bus_address[63:2]][15:0] <= bus_write_data[15:0];
			if (bus_address[1:0] == 2) Cache[bus_address[63:2]][31:16] <= bus_write_data[15:0];
			end
		    3'b010: begin Cache[bus_address[63:2]] <= bus_write_data[31:0]; end
		    3'b011: begin //sd
		        case(sd)
		            0: begin Cache[bus_address[63:2]] <= bus_write_data[31:0]; sd <= 1; next_addr <= bus_address[63:2]+1; end
			    1: begin Cache[next_addr] <= bus_write_data[63:32]; sd <= 0; end
			endcase
			end
	        endcase
	    end

	    if (Sdc_addr_selected) sd_addr <= bus_write_data[31:0];
            if (Sdc_read_selected) sd_rd_start <= 1;
        end
    end

    // -- SD Card --
    wire [11:0] cid = (bus_address-`Sdc_base);
    reg [7:0] sd_cache [0:511];
    reg [9:0] byte_index = 0;
    reg sd_cache_available = 0;
    reg sd_byte_available_d = 0;
    reg do_read = 0;
    wire [4:0] sd_status;
    always @(posedge CLOCK_50 or negedge KEY0) begin
	if (!KEY0) begin
	    //sd_rd_start <= 0;
	    byte_index <= 0;
	    do_read <=0;
	    sd_cache_available <= 0;
	    //sd_byte_available <= 0;
	    sd_byte_available_d <= 0;
	end
	else begin
	    //sd_cache_available <= 0;
            sd_byte_available_d  <= sd_byte_available;
            if (sd_byte_available && !sd_byte_available_d) begin
	        sd_cache[byte_index] <= sd_dout;
	        byte_index <= byte_index + 1;
	        do_read <=1;
	    end
	    if (byte_index == 10) sd_cache_available <= 0;
	    //if (do_read && sd_status !=6) begin 
	    if (byte_index == 512) begin 
	        //sd_rd_start <= 0;
	        byte_index <= 0;
	        do_read <=0;
	        sd_cache_available <= 1;
	    end
        end
    end

    // Slow pulse clock for SD init (~100 kHz)
    reg [8:0] clkdiv = 0;
    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) clkdiv <= 0;
        else clkdiv <= clkdiv + 1;
    end
    wire clk_pulse_slow = (clkdiv == 0);

    // SD Controller Bridge
    reg [31:0] sd_addr = 0;           // Sector address
    reg sd_rd_start;                  // Trigger rd

    wire [7:0] sd_dout;
    wire sd_ready;
    wire sd_byte_available;

    // SD Controller Instantiation
    sd_controller sdctrl (
        .cs(SD_DAT3),
        .mosi(SD_CMD),
        .miso(SD_DAT0),
        .sclk(SD_CLK),

        .rd(sd_rd_start),
        .wr(1'b0),
        .dout(sd_dout),
        .byte_available(sd_byte_available),

        .din(8'd0),
        .ready_for_next_byte(),
        .reset(~KEY0),
        .ready(sd_ready),
        .address(sd_addr),
        .clk(CLOCK_50),
        .clk_pulse_slow(clk_pulse_slow),
        .status(sd_status),
        .recv_data()
    );


    // UART Writer Trigger
    wire uart_write_trigger = bus_write_enable && Art_selected;
    reg uart_write_trigger_dly;
    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) uart_write_trigger_dly <= 0;
        else uart_write_trigger_dly <= uart_write_trigger;
    end
    assign uart_write_trigger_pulse = uart_write_trigger  && !uart_write_trigger_dly;

    // Interrupt controller
    wire [3:0] interrupt_vector;
    wire interrupt_ack;
    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            interrupt_vector <= 0;
            LEDR0 <= 0;
        end else begin
            if (key_pressed && ascii) begin
                interrupt_vector <= 1;
                LEDR0 <= 1;
            end
            if (interrupt_vector != 0 && interrupt_ack == 1) begin
                interrupt_vector <= 0;
                LEDR0 <= 0;
            end
        end
    end

    // Debug LEDs
    assign HEX30 = ~Key_selected;
    assign HEX20 = ~|bus_read_data;
    assign HEX21 = ~bus_read_enable;
    assign HEX10 = ~|bus_write_data;
    assign HEX11 = ~bus_write_enable;
    assign HEX00 = ~Art_selected;
    assign HEX01 = ~Ram_selected;
    assign HEX02 = ~Rom_selected;
    //assign HEX03 = ~Sdc_selected;
endmodule
