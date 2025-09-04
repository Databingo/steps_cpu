`include "header.vh"

module cpu_on_board (
    // -- Pin --
    (* chip_pin = "PIN_L1" *)  input wire CLOCK_50, // 50 MHz clock
    (* chip_pin = "PIN_R22" *) input wire KEY0,     // Active-low reset button
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *) output wire [7:0] LEDG, // 8 green LEDs
    (* chip_pin = "R17" *) output reg LEDR9, // 1 red LEDs breath left most 
    //(* chip_pin = "U18, Y18, V19, T18, Y19, U19, R19, R20" *) output wire [7:0] LEDR7_0, // 8 red LEDs right
    (* chip_pin = "R20" *) output wire LEDR7, // 

    (* chip_pin = "H15" *)  input wire PS2_CLK, 
    (* chip_pin = "J14" *)  input wire PS2_DAT 
);

    //// -- ROM -- for Boot Program
    //(* ram_style = "block" *) reg [31:0] Rom [0:1023]; // 4KB Read Only Memory
    //initial $readmemb("rom.mif", Rom);

    //// -- RAM -- for Load Program
    //(* ram_style = "block" *) reg [31:0] Ram [0:2047]; // 8KB Radom Access Memory
    //initial $readmemb("ram.mif", Ram);

    // -- MEM -- minic L1 cache
    (* ram_style = "block" *) reg [31:0] Cache [0:2047]; // 2048x4=8KB L1 cache to 0x2000
    initial $readmemb("rom.mif", Cache, 0); // 1024x4=4KB ROM untill 0x1000
    initial $readmemb("ram.mif", Cache, 1024); // RAM to 0x2000

    // -- Clock --
    wire clock_1hz;
    clock_slower clock_ins(
        .clk_in(CLOCK_50),
        .clk_out(clock_1hz),
        .reset_n(KEY0)
    );

    wire [31:0] pc;
    //wire [31:0] ir_bd; assign ir_bd = Ram[pc>>2];
    reg [31:0] ir_bd;
    always @(posedge CLOCK_50) begin
	//if (pc >= Rom_base && pc < Rom_base + Rom_size) 
	//    ir_bd = Rom[pc>>2]; else 
	//ir_bd = Ram[pc>>2];
	ir_bd = Cache[pc>>2];
    end
    wire [31:0] ir_ld; assign ir_ld = {ir_bd[7:0], ir_bd[15:8], ir_bd[23:16], ir_bd[31:24]}; // Endianness swap

    // -- CPU --
    riscv64 cpu (
        .clk(clock_1hz), 
        //.clk(CLOCK_50), 
        .reset(KEY0),     // Active-low reset button
        .instruction(ir_ld),
        .pc(pc),
        .ir(LEDG),
        //.re(re),
        .heartbeat(LEDR9),

	.interrupt_vector(interrupt_vector),
	.interrupt_ack(interrupt_ack),

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
    reg [63:0] bus_read_data;
    wire        bus_read_enable;
    wire [63:0] bus_write_data;
    wire        bus_write_enable;

    // -- Bus controller --
    //localparam Rom_base = 32'h0000_0000, Rom_size = 32'h0000_1000; // 4KB ROM
    //localparam Ram_base = 32'h0000_1000, Ram_size = 32'h0000_2000; // 4KB RAM
    //localparam Art_base = 32'h0000_ffff; 
    //localparam Key_base = 32'h0000_fffe; 
    //localparam Stk_base = 32'h0000_3000, Stk_size = 32'h0000_1000; // 4KB STACK
    wire Rom_selected = (bus_address >= `Rom_base && bus_address < `Rom_base + `Rom_size);
    wire Ram_selected = (bus_address >= `Ram_base && bus_address < `Ram_base + `Ram_size);
    ////wire Stk_selected = (bus_address >= Stk_base && bus_address < Stk_base + Stk_size);
    wire Art_selected = (bus_address == `Art_base);
    wire Key_selected = (bus_address == `Key_base);

//    wire [63:0] bus_read_data = Key_selected ? {56'd0, data[7:0]}:
//	                   //Key_selected ? {56'd0, ascii}:
//	                   //Art_selected ? {56'd0, ascii}:
//	                   Ram_selected ? {32'd0, Ram[bus_address[11:2]]}:
//			   Rom_selected ? {32'd0, Rom[bus_address[11:2]]}:
//			   64'hDEADBEEF_DEADBEEF;
//
//  // Bus read
    //always @(posedge CLOCK_50) begin
    //    if (bus_read_enable) begin
    //             if (bus_address == `Key_base) bus_read_data <= {56'd0, data[7:0]};
    //        else if (bus_address >= `Rom_base && bus_address < `Rom_base + `Rom_size) bus_read_data <= {32'd0, Cache[bus_address[11:2]]};
    //        //else if (Rom_selected) bus_read_data <= {32'd0, Cache[bus_address[11:2]]};
    //        else if (bus_address >= `Ram_base && bus_address < `Ram_base + `Ram_size) bus_read_data <= {32'd0, Cache[bus_address[11:2]]};
    //    end
    //    else if (bus_write_enable) begin
    //             if (bus_address >= `Ram_base && bus_address < `Ram_base + `Ram_size) Cache[bus_address[11:2]] <= bus_write_data;
    //        else if (bus_address == `Art_base) uart_write_trigger <= 1; 
    //    end
    //end
    //reg [63:0] cache_read;
    //reg [9:0] addr_reg;
    //reg reading;
    always @(posedge CLOCK_50) begin
        if (bus_write_enable) begin
            //Cache[bus_address[11:2]] <= bus_write_data;
            Cache[bus_address] <= bus_write_data;
        end 
	//if (bus_read_enable) begin 
        //    addr_reg <= bus_address[11:2];
	//    reading <= 1;
	//end
	//if (reading) begin
        //    bus_read_data <= {32'd0, Cache[addr_reg]};
	//    reading <= 0;
	//end
	if (bus_read_enable) begin 
            bus_read_data <= {32'd0, Cache[bus_address]};
	end
    end
    



    wire uart_write_trigger = bus_write_enable && Art_selected;
    //reg uart_write_trigger;
    reg uart_write_trigger_dly;
    wire uart_write_trigger_pulse;
    always @(posedge CLOCK_50 or negedge KEY0) begin
	if (!KEY0) uart_write_trigger_dly <= 0;
	else uart_write_trigger_dly <= uart_write_trigger;
    end

    assign uart_write_trigger_pulse = uart_write_trigger  && !uart_write_trigger_dly;


    // -- interrupt controller --
    wire [3:0] interrupt_vector;
    wire interrupt_ack;
    wire interrupt_pending;
    always @(posedge CLOCK_50 or negedge KEY0) begin
	if (!KEY0) begin
	    interrupt_vector <= 0;
	    LEDR7 <= 0;
	end else begin
            if (key_pressed_edge && data[7:0]) begin
		    interrupt_vector <= 1;
		    LEDR7 <= 1;
	    end
	    if (interrupt_vector != 0 && interrupt_ack == 1) begin
		interrupt_vector <= 0; // only sent once
		LEDR7 <= 0;
		end
		
	end
    end

    // -- Timer --
    // -- CSRs --
    // -- BOIS/bootloader --
    // -- Caches --
    // -- MMU(Memory Manamgement Unit) --
    // -- DMA(Direct Memory Access) --?

endmodule
