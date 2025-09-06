`include "header.vh"

module cpu_on_board (
    // -- Pin --
    (* chip_pin = "PIN_L1" *)  input wire CLOCK_50, // 50 MHz clock
    (* chip_pin = "PIN_R22" *) input wire KEY0,     // Active-low reset button
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *) output wire [7:0] LEDG, // 8 green LEDs
    (* chip_pin = "R17" *) output reg LEDR9, // 1 red LEDs breath left most 
    //(* chip_pin = "U18, Y18, V19, T18, Y19, U19, R19, R20" *) output wire [7:0] LEDR0_0, // 8 red LEDs right
    (* chip_pin = "R20" *) output wire LEDR0, // 
    (* chip_pin = "R19" *) output wire LEDR1, // 
    (* chip_pin = "U18, Y18, V19, T18, Y19, U19" *) output wire [5:0] LEDR_PC, // 8 red LEDs right

    (* chip_pin = "H15" *)  input wire PS2_CLK, 
    (* chip_pin = "J14" *)  input wire PS2_DAT 
);

    // -- MEM -- minic L1 cache
    //(* ram_style = "block" *) reg [31:0] Cache [0:2047]; // 2048x4=8KB L1 cache to 0x2000
    (* ram_style = "block" *) reg [31:0] Cache [0:3071]; // 2048x4=8KB L1 cache to 0x2000
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
    always @(posedge CLOCK_50) begin
	ir_bd <= Cache[pc>>2];
    end
    wire [31:0] ir_ld; assign ir_ld = {ir_bd[7:0], ir_bd[15:8], ir_bd[23:16], ir_bd[31:24]}; // Endianness swap
    assign LEDR_PC = pc/4;

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

        .bus_addr(bus_addr),

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
    //reg [63:0] bus_read_data;
    wire [63:0] bus_read_data;
    wire        bus_read_enable;
    wire [63:0] bus_write_data;
    wire        bus_write_enable;

    // -- Bus controller --
    wire Rom_selected = (bus_address >= `Rom_base && bus_address < `Rom_base + `Rom_size);
    wire Ram_selected = (bus_address >= `Ram_base && bus_address < `Ram_base + `Ram_size);
    ////wire Stk_selected = (bus_address >= Stk_base && bus_address < Stk_base + Stk_size);
    wire Art_selected = (bus_address == `Art_base);
    wire Key_selected = (bus_address == `Key_base);
    assign  LEDR1 = Key_selected;

    wire [63:0] bus_addr;
    reg [31:0] port_b_data_out;
    // Read-During-Write (read get old data in same cycle with write)
    always @(posedge CLOCK_50) begin
        if (bus_write_enable) begin
            //Cache[bus_addr[9:0]] <= bus_write_data;
            Cache[bus_address[11:2]] <= bus_write_data;
        end 
        port_b_data_out <= {32'd0, Cache[bus_address/4]};
    end
    // MUX
    //always @(posedge CLOCK_50) begin
    //    if (bus_read_enable) begin 
    //       if (Ram_selected) bus_read_data <= {32'd0, port_b_data_out}; // 
    //       else if (Key_selected) bus_read_data <= {32'd0, 24'd0, data[7:0]}; // keyboard ASCII
    //    end
    //end
    assign bus_read_data = (bus_read_enable && Ram_selected) ? {32'd0, port_b_data_out}:
                           (bus_read_enable && Rom_selected) ? {32'd0, port_b_data_out}:
                           (bus_read_enable && Key_selected) ? {32'd0, 24'd0, data[7:0]}:
			   64'h00000000;



    //always @(posedge CLOCK_50) begin
    //    if (bus_write_enable) begin
    //        Cache[bus_addr[9:0]] <= bus_write_data;
    //        //Cache[bus_addr] <= bus_write_data;
    //        //
    //    end 
    //    else if (bus_read_enable) begin 
    //        if (Key_selected) bus_read_data <= {32'd0, 24'd0, data[7:0]}; // keyboard ASCII
    //        else bus_read_data <= {32'd0, Cache[bus_addr]};
    //    end
    //end
    
    //always @(posedge CLOCK_50) begin
    //    if (bus_write_enable) begin
    //        Cache[bus_addr[9:0]] <= bus_write_data;
    //        //Cache[bus_addr] <= bus_write_data;
    //        //
    //    end 
    //end

    //always @(posedge CLOCK_50) begin
    //    if (bus_read_enable) begin 
    //        if (Key_selected) bus_read_data <= {32'd0, 24'd0, data[7:0]}; // keyboard ASCII
    //        else bus_read_data <= {32'd0, Cache[bus_addr]};
    //    end
    //end



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
	    LEDR0 <= 0;
	end else begin
            if (key_pressed_edge && data[7:0]) begin
		    interrupt_vector <= 1;
		    LEDR0 <= 1;
	    end
	    if (interrupt_vector != 0 && interrupt_ack == 1) begin
		interrupt_vector <= 0; // only sent once
		LEDR0 <= 0;
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
