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
        .clk(clock_1hz), 
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
    reg key_pressed_delay;
    wire key_pressed;
    wire key_released;

    ps2_decoder ps2_decoder_inst (
        .clk(CLOCK_50),
        .ps2_clk_async(PS2_CLK),
        .ps2_data_async(PS2_DAT),
        //.scan_code(data[7:0])
        .ascii_code(data[7:0]),
        .key_pressed(key_pressed),
        .key_released(key_released)
     );
    // Drive Keyboard
    always @(posedge CLOCK_50) begin key_pressed_delay <= key_pressed; end
    wire key_pressed_edge = key_pressed && !key_pressed_delay;
    // Connected to Bus
    //assign bus_write_enable  = key_pressed_edge && Art_selected; 
    //assign bus_address   = Art_base + 64'b0;            // Always write to the data register (address 0)
    //assign bus_write_data = {24'b0, data[7:0]};    

    // -- Monitor -- Connected to Bus
    jtag_uart_system my_jtag_system (
        .clk_clk                             (CLOCK_50),
        .reset_reset_n                       (KEY0),
        .jtag_uart_0_avalon_jtag_slave_address   (bus_address[0:0]),
        .jtag_uart_0_avalon_jtag_slave_writedata (bus_write_data[31:0]),
        .jtag_uart_0_avalon_jtag_slave_write_n   (~(bus_write_enable && Art_selected)),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        .jtag_uart_0_avalon_jtag_slave_read_n    (1'b1)
    );

    // -- Bus --
    wire [63:0] bus_address;
    wire [63:0] bus_read_data;
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
    wire Stk_selected = (bus_address == Stk_base && bus_address < Stk_base + Stk_size);
    wire Art_selected = (bus_address == Art_base);
    wire Key_selected = (bus_address == Key_base);
    assign bus_read_data = Key_selected ? {56'd0, data[7:0]}:
	                   Ram_selected ? {32'd0, Ram[bus_address[11:2]]}:
			   Rom_selected ? {32'd0, Rom[bus_address[11:2]]}:
			   64'hDEADBEEF_DEADBEEF;
    wire uart_write_trigger = bus_write_enable && Art_selected;


    // -- interrupt controller --
    reg [3:0] interrupt_vector;
    wire interrupt_done;
    always @(posedge clock_1hz) begin
        if (key_pressed_edge) interrupt_vector <= 1;
        if (interrupt_done) interrupt_vector <= 0;
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
    output wire        bus_read_enable,
    input  wire [63:0] bus_read_data


);

    //reg [63:0] keyboard_data_reg;
    // -- Interrupter --
    always @(posedge clk or negedge reset) begin
	if (!reset) begin
	    bus_read_enable <= 0;
	    bus_write_enable <= 0;
	    interrupt_done <= 0;
	end else begin
	    bus_read_enable <= 0;
	    bus_write_enable <= 0;
	    interrupt_done <= 0;
	    if (interrupt_vector == 1) begin
	        bus_address <= 32'h8000_0010; // Key_base ;
	        bus_read_enable <= 1;
	    end else if (bus_read_enable) begin
                //keyboard_data_reg <= bus_read_data;
	        bus_address <= 32'h8000_0000; // Art_base ;
	        bus_write_data <= bus_read_data;
	        bus_write_enable <= 1;
		interrupt_done <=1;
	    end
	end
    end
    
    // --- Immediate decoders (Unchanged) --- 
    wire signed [63:0] w_imm_u = {{32{ir[31]}}, ir[31:12], 12'b0};
    wire [4:0] w_rd  = ir[11:7];

    // IF ir (Unchanged)
    always @(posedge clk or negedge reset) begin
        if (!reset) begin 
            heartbeat <= 1'b0; 
            ir <= 32'h00000000; 
        end else begin
            heartbeat <= ~heartbeat; // heartbeat
            //ir <= ir_ld;
            ir <= instruction;
        end
    end

    // EXE pc (Unchanged, CPU runs normally)
    always @(posedge clk or negedge reset) begin
        if (!reset) begin 
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

endmodule
