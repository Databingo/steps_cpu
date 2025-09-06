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

    (* chip_pin = "F4" *)  output wire HEX30,
    (* chip_pin = "G5" *)  output wire HEX20,
    (* chip_pin = "E1" *)  output wire HEX10,
    (* chip_pin = "J2" *)  output wire HEX00,

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
        .jtag_uart_0_avalon_jtag_slave_writedata (bus_write_data[63:0]),
        .jtag_uart_0_avalon_jtag_slave_write_n   (~uart_write_trigger_pulse),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        .jtag_uart_0_avalon_jtag_slave_read_n    (1'b1)
    );

    // -- Bus --
    wire [63:0] bus_address;
    reg [63:0] bus_read_data;
    //wire [63:0] bus_read_data;
    wire        bus_read_enable;
    wire [63:0] bus_write_data;
    wire        bus_write_enable;


    // -- Bus controller --
    wire Rom_selected = (bus_address >= `Rom_base && bus_address < `Rom_base + `Rom_size);
    wire Ram_selected = (bus_address >= `Ram_base && bus_address < `Ram_base + `Ram_size);
    ////wire Stk_selected = (bus_address >= Stk_base && bus_address < Stk_base + Stk_size);
    wire Art_selected = (bus_address == `Art_base);
    wire Key_selected = (bus_address == `Key_base);
    wire read_has_data = |bus_read_data;
    wire write_has_data = |bus_write_data;
    assign HEX30 = ~Key_selected;
    assign HEX20 = ~read_has_data;
    assign HEX10 = ~write_has_data;
    assign HEX00 = ~Art_selected;

    wire [63:0] bus_addr;
    reg [31:0] port_b_data_out;
    // Read-During-Write (read get old data in same cycle with write)
    always @(posedge CLOCK_50) begin
        // Write path
        if (bus_write_enable) Cache[bus_address/4] <= bus_write_data; 
        // Read path
        //port_b_data_out <= {32'd0, Cache[bus_address[11:2]]};
    end
    // MUX Router read
    //reg bus_read_enable_former;
    //always @(posedge CLOCK_50) begin
    //    if (!KEY0)  bus_read_enable_former <=0;
    //    else  bus_read_enable_former  <= bus_read_enable;
    //end
    //assign bus_read_enable_50 =  bus_read_enable && ! bus_read_enable_former;

    always @(posedge CLOCK_50) begin //!!
	if (bus_read_enable && Key_selected) bus_read_data  <= {32'd0, 24'd0, data[7:0]};
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
`include "header.vh"

module riscv64(
    input wire clk, 
    input wire reset,     // Active-low reset button
    input wire [31:0] instruction,
    //output reg [31:0] pc = 44,
    output reg [63:0] pc,// = 32'h1000,
    output reg [31:0] ir,
    output reg [63:0] re [0:31],
    output wire  heartbeat,

    input  reg [3:0] interrupt_vector,
    output reg  interrupt_pending,
    output reg  interrupt_ack,

    output reg [63:0] bus_addr,

    output reg [63:0] bus_address,  // 48 bit for real standard?
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
    reg lb_step;
    reg sb_step;
    reg [31:0] mepc; 



    // IF ir (Unchanged)
    always @(posedge clk or negedge reset) begin
        if (!reset) begin 
            heartbeat <= 1'b0; 
            ir <= 32'h00000001; 
        end else begin
            heartbeat <= ~heartbeat; // heartbeat
            ir <= instruction;
        end
    end

    // EXE
    always @(posedge clk or negedge reset) begin
        if (!reset) begin 
	    bubble <= 1'b0;
	    pc <= `Ram_base;
	    lb_step <= 0;
            sb_step <= 0;
	    bus_read_enable <= 0;
	    bus_write_enable <= 0;
	    bus_write_data <= 0;
	    bus_address <= `Ram_base;
            // Interrupt reset
	    interrupt_pending <= 0;
	    interrupt_ack <= 0;

        end else begin

	    // PC default +4    (1.Could be overide 2.Take effect next cycle) 
            pc <= pc + 4;
	    interrupt_ack <= 0;

            // Interrupt
	    if (interrupt_vector == 1 && interrupt_pending !=1) begin
	        mepc <= pc; // save pc
                pc <= 0; // jump to ISR addr
		bubble <= 1'b1; // bubble wrong fetche instruciton by IF
	        interrupt_pending <= 1;
		interrupt_ack <= 1;

            // Bubble
	    end else if (bubble) bubble <= 1'b0; // Flush this cycle & Clear bubble signal for the next cycle

	    // IR
	    else begin 
	        bus_read_enable <= 0;
	        bus_write_enable <= 0; 
	        bus_write_data <= 0;
	        bus_address <= `Ram_base;
                casez(ir) 
	            32'b???????_?????_?????_???_?????_0110111:  re[w_rd] <= w_imm_u; // Lui
	            32'b0000000_00000_00000_000_00000_0000000: begin // Mret 
	                pc <= mepc; 
	                bubble <= 1; 
	                interrupt_pending <= 0;
	            end 
	            32'b1111111_11111_11111_111_11111_1111111: begin // Load  3 cycles to finish re<=data
	                if (lb_step == 0) begin
	                    bus_address <= `Key_base; // cycle 1 setting read enable
	                    bus_read_enable <= 1;
	                    pc <= pc;
	                    bubble <= 1; //!! take over cycle 2, meanwhile bus read 
	                    lb_step <= 1;
	                end
	                if (lb_step == 1) begin  
	                    re[5]<= bus_read_data; // cycle 3 save to cpu's register
	                    lb_step <= 0;
	                end
	            end
	            32'b1111111_11111_11111_111_11110_1111111: begin // Store 1 cycles to finish settting data<=re (next cycle bus write to data)
	               bus_address <= `Art_base;
	               bus_write_data <= re[5];
	               bus_write_enable <= 1;
	            end
                endcase
	    end
        end
    end

endmodule
