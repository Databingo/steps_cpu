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

    // -- ROM -- for Boot Program
    //(* ram_style = "block" *) reg [31:0] Rom [0:1023]; // 4KB Read Only Memory
    //initial $readmemb("rom.mif", Rom);

    // -- RAM -- for Load Program
      
      
           
    // -- MEM -- for all
    (* ram_style = "block" *) reg [31:0] Ram [0:4096]; // 8KB Radom Access Memory
    initial $readmemb("mem.mif", Ram);

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
        ir_bd = Ram[pc>>2];
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
    //wire [63:0] bus_read_data;
    wire        bus_read_enable;
    wire [63:0] bus_write_data;
    wire        bus_write_enable;

    // -- Bus controller --
    localparam Ram_base = 32'h0000_0000, Ram_size = 32'h0000_1000; // 4KB RAM
    localparam Rom_base = 32'h0000_1000, Rom_size = 32'h0000_2000; // 8KB ROM
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
			   Rom_selected ? {32'd0, Ram[bus_address[11:2]]}:
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



module riscv64(
    input wire clk, 
    input wire reset,     // Active-low reset button
    input wire [31:0] instruction,
    output reg [31:0] pc = 44,
    output reg [31:0] ir,
    output reg [63:0] re [0:31],
    output wire  heartbeat,

    input  reg [3:0] interrupt_vector,
    output reg  interrupt_pending,
    output reg  interrupt_ack,

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
            pc <= 44; //
	    lb_step <= 0;
            sb_step <= 0;
            // Interrupt reset
	    interrupt_pending <= 0;
	    interrupt_ack <= 0;
	    //interrupt_done <= 0;
	    bus_read_enable <= 0;
	    bus_write_enable <= 0;
        end else begin
	    // PC default +4 (1.Could be overide 2.Take effect next cycle) 
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
            casez(ir) 
		// Lui
		32'b???????_?????_?????_???_?????_0110111:  re[w_rd] <= w_imm_u;
		// Mret 
		32'b0000000_00000_00000_000_00000_0000000: begin 
		    pc <= mepc; 
		    bubble <= 1; 
	            interrupt_pending <= 0;
		end 
                // Load
	        32'b1111111_11111_11111_111_11111_1111111: begin
		    if (lb_step == 0) begin
	            bus_address <= 32'h8000_0010; // Keyboard_base ;
	            bus_read_enable <= 1;
		    pc <= pc;
		    bubble <= 1;
		    lb_step <= 1;
		    end
		    if (lb_step == 1) begin
	            //bus_address <= 32'h8000_0000; // Art_base ;
	            //bus_write_data <= bus_read_data; //32'h41;
	            re[5]<= bus_read_data; //32'h41;
	            //bus_write_enable <= 1;
		    lb_step <= 0;
		    end
	        end
                // Store
	        32'b1111111_11111_11111_111_11110_1111111: begin
		    if (sb_step == 0) begin
	            bus_address <= 32'h8000_0000; // Art_base ;
	            bus_write_data <= re[5];
	            bus_write_enable <= 1;
		    //pc <= pc;
		    //bubble <= 1;
		    //sb_step <= 1;
		    //end
		    //if (lb_step == 1) begin
	            //bus_address <= 32'h8000_0000; // Art_base ;
	            //bus_write_data <= bus_read_data; //32'h41;
	            //bus_write_enable <= 1;
		    //lb_step <= 0;
		    end
	        end
            endcase
	    end
        end
    end

endmodule
