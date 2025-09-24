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
    // Keyboard signal
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
    reg  [63:0] bus_read_data;
    wire [63:0] bus_address;
    wire        bus_read_enable;
    wire [63:0] bus_write_data;
    wire        bus_write_enable;

    // == Bus controller ==
    // 1.-- Address Decoding --
    wire Rom_selected = (bus_address >= `Rom_base && bus_address < `Rom_base + `Rom_size);
    wire Ram_selected = (bus_address >= `Ram_base && bus_address < `Ram_base + `Ram_size);
    ////wire Stk_selected = (bus_address >= Stk_base && bus_address < Stk_base + Stk_size);
    wire Art_selected = (bus_address == `Art_base);
    wire Key_selected = (bus_address == `Key_base);

    // 2.-- Port B of the On-Chip Memeory (Cache L1) --
    reg [31:0] port_b_data_out;
    always @(posedge CLOCK_50) begin // Read-During-Write (read get old data in same cycle with write)
        if (bus_write_enable && (Ram_selected || Art_selected)) Cache[bus_address/4] <= bus_write_data; 
        port_b_data_out <= {32'd0, Cache[bus_address[11:2]]}; // Read path (Unconditional)
    end

    // 3.-- Synchronous Read Data Multiplexer --
    always @(posedge CLOCK_50) begin
	if (bus_read_enable) begin
	   if (Key_selected) bus_read_data  <= {32'd0, 24'd0, ascii};
	   else if (bus_read_enable && (Rom_selected || Ram_selected)) bus_read_data <= {32'd0, port_b_data_out};
	   //else bus_read_data <= 64'h00000000; // at 50MHz will override 
        end
        else bus_read_data <= 0; // clean
    end

    // 4.-- UART Writer Trigger --
    wire uart_write_trigger = bus_write_enable && Art_selected;
    reg uart_write_trigger_dly;
    always @(posedge CLOCK_50 or negedge KEY0) begin
	if (!KEY0) uart_write_trigger_dly <= 0;
	else uart_write_trigger_dly <= uart_write_trigger;
    end
    assign uart_write_trigger_pulse = uart_write_trigger  && !uart_write_trigger_dly;

    // -- interrupt controller --
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
		interrupt_vector <= 0; // only sent once
		LEDR0 <= 0;
	    end
	end
    end

    // 5. -- Debug LEDs --
    assign HEX30 = ~Key_selected;
    assign HEX20 = ~|bus_read_data;
    assign HEX10 = ~|bus_write_data;
    assign HEX00 = ~Art_selected;

    // -- Timer --
    // -- CSRs --
    // -- BOIS/bootloader --
    // -- Caches --
    // -- MMU(Memory Manamgement Unit) --
    // -- DMA(Direct Memory Access) --?

    // isr table
    // IMA set
    // M/S/U mode
    // MMU (Sv39 standard) satp
    // CLINT mtime mtimecmp
    // PLIC meip seip mip
    // openSBI/u-boot/berkeleyBootLoader
    // linux kernel S mode
    // 16550A UART
    // AXI-lite BUS
    //
    // Cyclone II FPGA Starter Board Resource
    // BRAM 30KB for Cache L1
    // SRAM 512KB for Booting(load from FLASH)
    // FLASH 4MB for Rom(opensbi_50KB/u-boot_100-200KB)
    // SDRAM 8MB for Ram
    // SD for Linux Kernel busybox (SRAM use SPI(IP) read kernel_initramfs from SD(IP) to SDRAM within 3s)
    // zImage .dtb initramfs.gz Buildroot:no network/deviceDrivers/FileSystem/kernekHacking
    // build and qemu test first
    // 
    // simplify:
    // BRAM for bootloader(tested in qemu)
    // FLASH for Linux kernel(tested in qemu)
    // SDRAM for ram
    //
    // Run naked neural network on riscv64
endmodule
`include "header.vh"

module riscv64(
    input wire clk, 
    input wire reset,     // Active-low reset button
    input wire [31:0] instruction,
    output reg [63:0] pc,
    output reg [31:0] ir,
    output reg [63:0] re [0:31], // General Registers 32s
    output wire  heartbeat,

    input  reg [3:0] interrupt_vector, // notice from outside
    output reg  interrupt_ack,         // reply to outside

    output reg [63:0] bus_address,     // 39 bit for real standard?
    output reg [63:0] bus_write_data,
    output reg        bus_write_enable,
    output reg        bus_read_enable,

    input  wire [63:0] bus_read_data   // from outside
);
    // -- CSR Index--
    localparam mstatus = 12'h300;   // 0x300 MRW Machine status reg   // 63_SD|37_MBE|36_SBE|35:34_SXL10|22_TSR|21_TW|20_TVW|17_MPRV|12:11_MPP10|7_MPIE|3_MIE|1_SIE|0_WPRI
    integer mie = 12'h304;          // 0x304 MRW Machine interrupt-enable register *
    integer mip = 12'h344;          // 0x344 MRW Machine interrupt pending *
    integer mtvec = 12'h305;        // 0x305 MRW Machine trap-handler base address *
    localparam mcause = 12'h342;    // 0x342 MRW Machine trap casue *
    localparam mepc = 12'h341;   
    // -- CSR Bits --
    localparam MIE  = 3; // mstatus.MIE
    localparam MPIE  = 7; // mstatus.MPIE
    //wire mie_MEIE = csr[mie][11];
    //wire mip_MEIP = csr[mie][11];
    wire mstatus_MIE = csr_mstatus[MIE];

    // -- Immediate decoders  -- 
    wire signed [63:0] w_imm_u = {{32{ir[31]}}, ir[31:12], 12'b0};  // U-type immediate Lui Auipc
    wire signed [63:0] w_imm_i = {{52{ir[31]}}, ir[31:20]};   // I-type immediate Lb Lh Lw Lbu Lhu Lwu Ld Jalr Addi Slti Sltiu Xori Ori Andi Addiw
    wire signed [63:0] w_imm_s = {{52{ir[31]}}, ir[31:25], ir[11:7]};  // S-type immediate Sb Sh Sw Sd
    // -- Instruction Decoding --
    wire [4:0] w_rd  = ir[11:7];
    wire [4:0] w_rs1 = ir[19:15];
    wire [4:0] w_rs2 = ir[24:20];
	

    // -- CSR Registers --
    reg [63:0] csr_mepc;
    reg [63:0] csr_mstatus;
    reg [63:0] csr_mcasue;
    reg [63:0] csr_mtvec = 64'd0;
    // -- CSR Other Registers -- use BRAM in FPGA then SRAM in ASIC
    //reg [63:0] other_csr [0:4096]; // Maximal 12-bit length = 4096 
    // -- CSR Reader -- 
    function [63:0] csr_read;
	input [11:0] csr_index;
	begin
	    case (csr_index)
            12'h341: csr_read = csr_mepc;
            12'h300: csr_read = csr_mstatus;
            default: csr_read = 64'd0;
	    endcase
	end
    endfunction
    // -- CSR Bit-- 
    function csr_bit;
	input [11:0] csr_index;
	input integer bit_position;
        reg [63:0] csr_value;
	begin
	    csr_value = csr_read(csr_index);
	    csr_bit = csr_value[bit_position];
	end
    endfunction
    // -- CSR Writer -- 
    function csr_write;
	input [11:0] csr_index;
	input [63:0] csr_wdata;
	begin
	    case (csr_index)
            12'h341: csr_mepc = csr_wdata;
            12'h300: csr_mstatus = csr_wdata;
            default: ;
	    endcase
	end
    endfunction

    // -- Innerl signal --
    reg bubble;
    reg lb_step;
    reg sb_step;

    // IF ir (Only drive IR)
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
            // Interrupt re-enable
	    csr_mstatus[MIE] <= 1;
	    interrupt_ack <= 0;

        end else begin
	    // Default PC+4    (1.Could be overide 2.Take effect next cycle) 
            pc <= pc + 4;
	    interrupt_ack <= 0;

            // Interrupt
	    if (interrupt_vector == 1 && mstatus_MIE == 1) begin //mstatus[3] MIE
	        csr_mepc <= pc; // save pc

		csr_mcasue <= 64'h800000000000000B; // MSB 1 for interrupts 0 for exceptions, Cause 11 for Machine External Interrupt
		csr_mstatus[MPIE] <= csr_mstatus[MIE];
		csr_mstatus[MIE] <= 0;

		pc <= csr_mtvec; // jump to mtvec addrss (default 0, need C or Assembly code of handler)
		bubble <= 1'b1; // bubble wrong fetched instruciton by IF
	        csr_mstatus[MIE] <= 0;
		interrupt_ack <= 1; // reply to outside

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
	            32'b0011000_00010_?????_000_?????_1110011: begin   // Mret
	                pc <= csr_read(mepc); 
			bubble <= 1; 
		        csr_mstatus[MIE] <= csr_mstatus[MPIE];
		        csr_mstatus[MPIE] <= 1;
		    end 
		    32'b???????_?????_?????_011_?????_0000011: begin  // Ld
	                if (lb_step == 0) begin
	                    bus_address <= re[w_rs1] + w_imm_i ;
	                    bus_read_enable <= 1;
	                    pc <= pc - 4; // Key of pipeline
	                    bubble <= 1; //!! take over cycle 2, meanwhile bus read 
	                    lb_step <= 1;
	                end
	                if (lb_step == 1) begin  
	                    re[w_rd]<= bus_read_data; // cycle 3 save to cpu's register
	                    lb_step <= 0;
	                end
		    end 
	            32'b???????_?????_?????_011_?????_0100011: begin // Sd
		        if (sb_step == 0) begin 
		            //bus_address <= `Art_base;
	                    bus_address <= re[w_rs1] + w_imm_s ;
	                    bus_write_data <= re[w_rs2];
	                    bus_write_enable <= 1;
			end
	            end
	            32'b???????_?????_?????_000_?????_0010011: re[w_rd] <= re[w_rs1] + w_imm_i;  // Addi
                endcase
	    end
        end
    end

endmodule

    //lui t1, 0x2
    //ld t0, 0(t1)
    //addi t1, t1, 0x4
    //sd t0, 0(t1)
    //mret
