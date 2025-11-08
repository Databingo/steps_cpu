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
    // Port A BRAM
    always @(posedge CLOCK_50) begin
	ir_bd <= Cache[pc>>2];
    end
    wire [31:0] ir_ld; assign ir_ld = {ir_bd[7:0], ir_bd[15:8], ir_bd[23:16], ir_bd[31:24]}; // Endianness swap
    assign LEDR_PC = pc/4;

    // -- CPU --
    riscv64 cpu (
        .clk(clock_1hz), 
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
    reg   bus_read_done;

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

    // Port B read & write BRAM
    reg [63:0] bus_address_reg;
    always @(posedge CLOCK_50) begin
        bus_address_reg <= bus_address>>2;
        sd_rd_start <= 0;

        // Read
        if (bus_read_enable) begin 
            if (Key_selected) begin bus_read_data <= {32'd0, 24'd0, ascii}; bus_read_done <= 1; end
            if (Ram_selected) begin bus_read_data <= {32'd0, Cache[bus_address_reg]}; bus_read_done <= 1; end
            if (Sdc_ready_selected) begin bus_read_data <= {63'd0, sd_ready}; bus_read_done <= 1; end
            //if (Sdc_cache_selected) begin bus_read_data <= {56'd0, sd_dout}; bus_read_done <= 1; end
            //if (Sdc_avail_selected) begin bus_read_data <= {63'd0, sd_byte_available}; bus_read_done <= 1; end
            if (Sdc_cache_selected) begin bus_read_data <= {56'd0, sd_cache[cid]}; bus_read_done <= 1; end 
            if (Sdc_avail_selected) begin bus_read_data <= {63'd0, sd_cache_available}; bus_read_done <= 1; end 
        end

        // Write
        if (bus_write_enable) begin 
            if (Ram_selected) Cache[bus_address[63:2]] <= bus_write_data[31:0];
            if (Sdc_addr_selected) sd_addr <= bus_write_data[31:0];
            if (Sdc_read_selected) sd_rd_start <= 1;
        end
    end

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
    output reg [63:0] bus_address,     // 39 bit for real standard? 64 bit now
    output reg [63:0] bus_write_data,
    output reg        bus_write_enable,
    output reg        bus_read_enable,
    input  reg        bus_read_done,
    input  wire [63:0] bus_read_data   // from outside
);

    // -- Immediate decoders  -- 
    wire signed [63:0] w_imm_u = {{32{ir[31]}}, ir[31:12], 12'b0};  // U-type immediate Lui Auipc
    wire signed [63:0] w_imm_i = {{52{ir[31]}}, ir[31:20]};   // I-type immediate Lb Lh Lw Lbu Lhu Lwu Ld Jalr Addi Slti Sltiu Xori Ori Andi Addiw 
    wire signed [63:0] w_imm_s = {{52{ir[31]}}, ir[31:25], ir[11:7]};  // S-type immediate Sb Sh Sw Sd
    wire signed [63:0] w_imm_j = {{43{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0}; // UJ-type immediate Jal  // read immediate & padding last 0, total 20 + 1 = 21 bits
    wire signed [63:0] w_imm_b = {{51{ir[31]}}, ir[7],  ir[30:25], ir[11:8], 1'b0}; // B-type immediate Beq Bne Blt Bge Bltu Bgeu // read immediate & padding last 0, total 12 + 1 = 13 bits
    wire        [63:0] w_imm_z = {59'b0, ir[19:15]};  // CSR zimm zero-extending unsigned
    wire [5:0] w_shamt = ir[25:20]; // If 6 bits the highest is always 0??
    // -- Instruction Decoding --
    wire [4:0] w_rd  = ir[11:7];
    wire [4:0] w_rs1 = ir[19:15];
    wire [4:0] w_rs2 = ir[24:20];

    wire [11:0] w_csr = ir[31:20];   // CSR address
    //wire [11:0] w_f12 = ir[31:20];   // ecall 0, ebreak 1
    // --Machine CSR --
    reg [63:0] csr_mstatus; localparam mstatus = 12'h300;  // 0x300 MRW Machine status reg   // 63_SD|37_MBE|36_SBE|35:34_SXL10|22_TSR|21_TW|20_TVW|17_MPRV|12:11_MPP10|7_MPIE|3_MIE|1_SIE|0_WPRI
    reg [63:0] csr_mtvec = 64'd0; integer mtvec = 12'h305; // 0x305 MRW Machine trap-handler base address *
    reg [63:0] csr_mscratch; localparam mscratch = 12'h340; // 
    reg [63:0] csr_mepc; localparam mepc = 12'h341;   
    reg [63:0] csr_mcause; localparam mcause = 12'h342;    // 0x342 MRW Machine trap casue *
    reg [63:0] csr_mie; localparam mie = 12'h304;    //
    reg [63:0] csr_mip; localparam mip = 12'h344;    //
    reg [63:0] csr_medeleg ; localparam medeleg = 12'h302;    //
    reg [63:0] csr_mideleg ; localparam mideleg = 12'h303;    //
    // Supervisor CSR
    reg [63:0] csr_sstatus; localparam sstatus =  12'h100; 
    reg [63:0] csr_sie ; localparam sie = 12'h104;   // Supervisor interrupt-enable register
    reg [63:0] csr_stvec ; localparam stvec =12'h105;
    reg [63:0] csr_satp; localparam satp = 12'h180; // Supervisor address translation and protection satp[63:60].MODE=0:off|8:SV39 satp[59:44].asid vpn2:9 vpn1:9 vpn0:9 satp[43:0]:rootpage physical addr
    reg [63:0] csr_sscratch ; localparam sscratch =12'h140;
    reg [63:0] csr_sepc ; localparam sepc =12'h141; //
    reg [63:0] csr_scause ; localparam scause = 12'h142;// 
    reg [63:0] csr_stval ; localparam stval = 12'h143;//
    reg [63:0] csr_sip ; localparam sip = 12'h144; // Supervisor interrupt pending
    //integer sedeleg = 12'h102;
    //integer sideleg = 12'h103;
    //integer scounteren = 12'h106;
    //integer scontext = 12'h5a8; 
    // -- CSR Bits --
    localparam MIE  = 3; // mstatus.MIE
    localparam MPIE  = 7; // mstatus.MPIE
    //wire mie_MEIE = csr[mie][11];
    //wire mip_MEIP = csr[mie][11];
    wire mstatus_MIE = csr_mstatus[MIE];
    // -- CSR Other Registers -- use BRAM in FPGA then SRAM in ASIC port?
    //reg [63:0] other_csr [0:4096]; // Maximal 12-bit length = 4096 
    // -- CSR Reader -- 
    function [63:0] csr_read;
	input [11:0] csr_index;
	begin
	    case (csr_index)
            12'h300: csr_read = csr_mstatus;
            12'h305: csr_read = csr_mtvec;
            12'h340: csr_read = csr_mscratch;
            12'h341: csr_read = csr_mepc;
            12'h342: csr_read = csr_mcause;

            default: csr_read = 64'd0;
	    endcase
	end
    endfunction
    // -- CSR Writer -- 
    task csr_write;
	input [11:0] csr_index;
	input [63:0] csr_wdata;
	begin
	    case (csr_index)
            12'h300: csr_mstatus  = csr_wdata;
            12'h305: csr_mtvec    = csr_wdata;
            12'h340: csr_mscratch = csr_wdata;
            12'h341: csr_mepc     = csr_wdata;
            12'h342: csr_mcause   = csr_wdata;

            default: ;
	    endcase
	end
    endtask
    // -- Innerl signal --
    reg bubble;
    reg [1:0] load_step;
    reg [1:0] store_step;

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
	    load_step <= 0;
	    store_step <= 0;
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

		csr_mcause <= 64'h800000000000000B; // MSB 1 for interrupts 0 for exceptions, Cause 11 for Machine External Interrupt
		csr_mstatus[MPIE] <= csr_mstatus[MIE];
		csr_mstatus[MIE] <= 0;

		pc <= csr_mtvec; // jump to mtvec addrss (default 0, need C or Assembly code of handler)
		bubble <= 1'b1; // bubble wrong fetched instruciton by IF
	        csr_mstatus[MIE] <= 0;
		interrupt_ack <= 1; // reply to outside

            // Bubble
	    end else if (bubble) begin bubble <= 1'b0; bus_write_enable <=0; end // Flush this cycle & Clear bubble signal for the next cycle

	    // IR
	    else begin 
	        bus_read_enable <= 0;
	        bus_write_enable <= 0; 
	        //bus_write_data <= 0;
	        bus_address <= `Ram_base;
                casez(ir) // Pseudo: li j jr ret call // I: addi sb sh sw sd lb lw ld lbu lhu lwu lui jal jalr auipc beq slt mret 
	            // U-type
	            32'b???????_?????_?????_???_?????_0110111: re[w_rd] <= w_imm_u; // Lui
	            32'b???????_?????_?????_???_?????_0010111: re[w_rd] <= w_imm_u + (pc - 4); // Auipc
		//    32'b???????_?????_?????_000_?????_0000011: begin  // Lb  3 cycles
		//        if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
	        //        if (load_step == 1) begin case ((re[w_rs1] + w_imm_i) & 2'b11)
		//	        0: re[w_rd]<= $signed(bus_read_data[7:0]);   1: re[w_rd]<= $signed(bus_read_data[15:8]); 
		//	        2: re[w_rd]<= $signed(bus_read_data[23:16]); 3: re[w_rd]<= $signed(bus_read_data[31:24]); 
		//	        endcase load_step <= 0; end end
		//    32'b???????_?????_?????_001_?????_0000011: begin  // Lh 3 cycles
		//        if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
	        //        if (load_step == 1) begin case ((re[w_rs1] + w_imm_i) & 2'b11)
		//	        0: re[w_rd]<= $signed(bus_read_data[15:0]); 2: re[w_rd]<= $signed(bus_read_data[31:16]); 1,3:; 
		//	        endcase load_step <= 0; end end
		    //32'b???????_?????_?????_010_?????_0000011: begin  // Lw 3 cycles
		    //    if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
		    //    if (load_step == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0; end end
		    32'b???????_?????_?????_010_?????_0000011: begin  // Lw_mmu 3 cycles
		        if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		        if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0; end end // bus ok and execute
		    //32'b???????_?????_?????_011_?????_0000011: begin   // Ld 5 cycles
		    //    if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; 
		    //    end if (load_step == 1) begin re[w_rd]<= bus_read_data; bus_address <= re[w_rs1] + w_imm_i + 4;  bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 2; 
		    //    end if (load_step == 2) begin re[w_rd]<= {bus_read_data[31:0], re[w_rd][31:0]}; load_step <= 0; end end
		    //32'b???????_?????_?????_100_?????_0000011: begin   // Lbu 3 cycles
		    //    if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
	            //    if (load_step == 1) begin case ((re[w_rs1] + w_imm_i) & 2'b11)
		    //            0: re[w_rd]<= bus_read_data[7:0];   1: re[w_rd]<= bus_read_data[15:8]; 
		    //            2: re[w_rd]<= bus_read_data[23:16]; 3: re[w_rd]<= bus_read_data[31:24]; 
		    //            endcase load_step <= 0; end end
		    //32'b???????_?????_?????_101_?????_0000011: begin   // Lhu 3 cycles
		    //    if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
	            //    if (load_step == 1) begin case ((re[w_rs1] + w_imm_i) & 2'b11)
		    //            0: re[w_rd]<= bus_read_data[15:0]; 2: re[w_rd]<= bus_read_data[31:16]; 1,3: ;
		    //            endcase load_step <= 0; end end
		    //32'b???????_?????_?????_110_?????_0000011: begin   // Lwu 3 cycles
		    //    if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
		    //    if (load_step == 1) begin re[w_rd]<= bus_read_data[31:0]; load_step <= 0; end end
	            //32'b???????_?????_?????_000_?????_0100011: begin  // Sb 3 cycles
		    //    if (store_step == 0) begin bus_address <= re[w_rs1] + w_imm_s; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; store_step <= 1; end
                    //    if (store_step == 1) begin bus_address <= re[w_rs1] + w_imm_s; case ((re[w_rs1] + w_imm_s) & 2'b11)
		    //            0: bus_write_data <= {bus_read_data[31:8], re[w_rs2][7:0]}; 1: bus_write_data <= {bus_read_data[31:16], re[w_rs2][7:0], bus_read_data[7:0]};
		    //            2: bus_write_data <= {bus_read_data[31:24], re[w_rs2][7:0], bus_read_data[15:0]}; 3: bus_write_data <= {re[w_rs2][7:0], bus_read_data[23:0]};
		    //            endcase bus_write_enable <= 1; store_step <= 0;  end end
	            //32'b???????_?????_?????_001_?????_0100011: begin  // Sh 3 cycles
		    //    if (store_step == 0) begin bus_address <= re[w_rs1] + w_imm_s; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; store_step <= 1; end
                    //    if (store_step == 1) begin bus_address <= re[w_rs1] + w_imm_s; case ((re[w_rs1] + w_imm_s) & 2'b11)
		    //            0: bus_write_data <= {bus_read_data[31:16], re[w_rs2][15:0]}; 2: bus_write_data <= {re[w_rs2][15:0], bus_read_data[15:0]}; 1,3:;
		    //            endcase bus_write_enable <= 1; store_step <= 0;  end end
		    //// Sw 1 cycle
	            32'b???????_?????_?????_010_?????_0100011: begin bus_address <= re[w_rs1] + w_imm_s; bus_write_data <= re[w_rs2][31:0]; bus_write_enable <= 1; pc <= pc; bubble <= 1; end
	            //32'b???????_?????_?????_011_?????_0100011: begin  // Sd 3 cycles
		    //    if (store_step == 0) begin; bus_address <= re[w_rs1] + w_imm_s; bus_write_data <= re[w_rs2][31:0]; bus_write_enable <= 1; pc <= pc - 4; bubble <= 1; store_step <= 1; end 
		    //    if (store_step == 1) begin; bus_address <= re[w_rs1] + w_imm_s + 4; bus_write_data <= re[w_rs2][63:32]; bus_write_enable <= 1; store_step <= 0; end end
                    //// Math-I
	            32'b???????_?????_?????_000_?????_0010011: re[w_rd] <= re[w_rs1] + w_imm_i;  // Addi
	            32'b???????_?????_?????_100_?????_0010011: re[w_rd] <= re[w_rs1] ^ w_imm_i ; // Xori
	            32'b???????_?????_?????_111_?????_0010011: re[w_rd] <= re[w_rs1] & w_imm_i ; // Andi
	            32'b???????_?????_?????_110_?????_0010011: re[w_rd] <= re[w_rs1] | w_imm_i ; // Ori
	            32'b???????_?????_?????_001_?????_0010011: re[w_rd] <= re[w_rs1] << w_shamt; // Slli
	            32'b000000?_?????_?????_101_?????_0010011: re[w_rd] <= re[w_rs1] >> w_shamt; // Srli // func7->6 // rv64 shame take w_f7[0]
	            32'b010000?_?????_?????_101_?????_0010011: re[w_rd] <= $signed(re[w_rs1]) >>> w_shamt; // Srai
	            32'b???????_?????_?????_010_?????_0010011: re[w_rd] <= $signed(re[w_rs1]) < w_imm_i ? 1:0; // Slti
	            32'b???????_?????_?????_011_?????_0010011: re[w_rd] <= (re[w_rs1] < w_imm_i) ?  1:0; // Sltiu
                    // Math-I (Word)
	            32'b???????_?????_?????_000_?????_0011011: re[w_rd] <= $signed(re[w_rs1][31:0] + w_imm_i[31:0]); // Addiw
	            32'b???????_?????_?????_001_?????_0011011: re[w_rd] <= $signed(re[w_rs1][31:0] << w_shamt[4:0]); // Slliw
	            32'b0000000_?????_?????_101_?????_0011011: re[w_rd] <= $signed(re[w_rs1][31:0] >> w_shamt[4:0]); // Srliw
	            32'b0100000_?????_?????_101_?????_0011011: re[w_rd] <= $signed(re[w_rs1][31:0]) >>> w_shamt[4:0]; // Sraiw
                    //// Math-R
	            32'b0000000_?????_?????_000_?????_0110011: re[w_rd] <= re[w_rs1] + re[w_rs2];  // Add
	            32'b0100000_?????_?????_000_?????_0110011: re[w_rd] <= re[w_rs1] - re[w_rs2];  // Sub;
	            32'b???????_?????_?????_100_?????_0110011: re[w_rd] <= re[w_rs1] ^ re[w_rs2]; // Xor
	            32'b???????_?????_?????_111_?????_0110011: re[w_rd] <= re[w_rs1] & re[w_rs2]; // And
	            32'b???????_?????_?????_110_?????_0110011: re[w_rd] <= re[w_rs1] | re[w_rs2]; // Or
	            32'b???????_?????_?????_001_?????_0110011: re[w_rd] <= re[w_rs1] << re[w_rs2][5:0]; // Sll 6 length
                    32'b0000000_?????_?????_101_?????_0110011: re[w_rd] <= re[w_rs1] >> re[w_rs2][5:0]; // Srl 6 length
	            32'b0100000_?????_?????_101_?????_0110011: re[w_rd] <= $signed(re[w_rs1]) >>> re[w_rs2][5:0]; // Sra 6 length
	            32'b???????_?????_?????_010_?????_0110011: re[w_rd] <= ($signed(re[w_rs1]) < $signed(re[w_rs2])) ? 1: 0;  // Slt
	            32'b???????_?????_?????_011_?????_0110011: re[w_rd] <= re[w_rs1] < re[w_rs2] ? 1:0; // Sltu

                    //// Math-R (Word)
	            32'b0000000_?????_?????_000_?????_0111011: re[w_rd] <= $signed(re[w_rs1][31:0] + re[w_rs2][31:0]);  // Addw
	            32'b0100000_?????_?????_000_?????_0111011: re[w_rd] <= $signed(re[w_rs1][31:0] - re[w_rs2][31:0]);  // Subw
	            32'b???????_?????_?????_001_?????_0111011: re[w_rd] <= $signed(re[w_rs1][31:0] << re[w_rs2][4:0]);  // Sllw 5 length
                    32'b0000000_?????_?????_101_?????_0111011: re[w_rd] <= $signed(re[w_rs1][31:0] >> re[w_rs2][4:0]);  // Srlw 5 length
	            32'b0100000_?????_?????_101_?????_0111011: re[w_rd] <= $signed(re[w_rs1][31:0]) >>> re[w_rs2][4:0]; // Sraw 5 length
                    // Jump
	            32'b???????_?????_?????_???_?????_1101111: begin pc <= pc - 4 + w_imm_j; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1'b1; end // Jal
	            32'b???????_?????_?????_???_?????_1100111: begin pc <= (re[w_rs1] + w_imm_i) & 64'hFFFFFFFFFFFFFFFE; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1; end // Jalr
                    // Branch 
		    32'b???????_?????_?????_000_?????_1100011: begin if (re[w_rs1] == re[w_rs2]) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Beq
		    32'b???????_?????_?????_001_?????_1100011: begin if (re[w_rs1] != re[w_rs2]) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bne
		    32'b???????_?????_?????_100_?????_1100011: begin if ($signed(re[w_rs1]) < $signed(re[w_rs2])) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Blt
		    32'b???????_?????_?????_101_?????_1100011: begin if ($signed(re[w_rs1]) >= $signed(re[w_rs2])) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bge
		    32'b???????_?????_?????_110_?????_1100011: begin if (re[w_rs1] < re[w_rs2]) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bltu
		    32'b???????_?????_?????_111_?????_1100011: begin if (re[w_rs1] >= re[w_rs2]) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bgeu
                    // M extension
		    32'b0000001_?????_?????_000_?????_0110011: re[w_rd] <= $signed(re[w_rs1]) * $signed(re[w_rs2]);  // Mul
                    32'b0000001_?????_?????_001_?????_0110011: re[w_rd] <= ($signed(re[w_rs1]) * $signed(re[w_rs2]))>>>64;//[127:64];  // Mulh 
                    //32'b0000001_?????_?????_100_?????_0110011: re[w_rd] <= (re[w_rs2]==0||(re[w_rs1]==64'h8000_0000_0000_0000 && re[w_rs2] == -1)) ? -1 : $signed(re[w_rs1]) / $signed(re[w_rs2]);  // Div
                    32'b0000001_?????_?????_101_?????_0110011: re[w_rd] <= (re[w_rs2]==0) ? -1 : $unsigned(re[w_rs1]) / $unsigned(re[w_rs2]);  // Divu

		    // System-CSR 
	            32'b???????_?????_?????_001_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); csr_write(w_csr,  re[w_rs1]); end // Csrrw
	            32'b???????_?????_?????_010_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_rs1 != 0 )  csr_write(w_csr, csr_read(w_csr) |  re[w_rs1]); end // Csrrs
	            32'b???????_?????_?????_011_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_rs1 != 0 )  csr_write(w_csr, csr_read(w_csr) & ~re[w_rs1]); end // Csrrc
	            32'b???????_?????_?????_101_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); csr_write(w_csr,  w_imm_z); end // Csrrwi
	            32'b???????_?????_?????_110_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_imm_z != 0) csr_write(w_csr, csr_read(w_csr) |  w_imm_z); end // csrrsi
	            32'b???????_?????_?????_111_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_imm_z != 0) csr_write(w_csr, csr_read(w_csr) & ~w_imm_z); end // Csrrci
                    // System-Machine
	            32'b0011000_00010_?????_000_?????_1110011: begin pc <= csr_read(mepc); bubble <= 1; csr_mstatus[MIE] <= csr_mstatus[MPIE]; csr_mstatus[MPIE] <= 1; end  // Mret
                    //// Mret
	            //32'b0011000_00010_?????_000_?????_1110011: begin  
	            //   			       csre[mstatus][3] <= csre[mstatus][7]; // set back interrupt enable(MIE) by MPIE 
	            //   			       csre[mstatus][7] <= 1; // set previous interrupt enable(MIE) to be 1 (enable)
	            //   			       if (csre[mstatus][12:11] < M_mode) csre[mstatus][17] <= 0; // set mprv to 0
	            //   			       current_privilege_mode  <= csre[mstatus][12:11]; // set back previous mode
	            //   			       csre[mstatus][12:11] <= 2'b00; // set previous privilege mode(MPP) to be 00 (U-mode)
	            //   			       pc <=  csre[mepc]; // mepc was +4 by the software handler and written back to sepc
		    //      		       bubble <= 1'b1;
	            //   			       end
		        // Ecall
                    //// Ecall
	            //32'b0000000_00000_?????_000_?????_1110011: begin  // func12 
                    //                                    // Trap into S-mode
	            //                                    if (current_privilege_mode == U_mode && medeleg[8] == 1)
	            //     			       begin
	            //     			           csre[scause][63] <= 0; //63_type 0exception 1interrupt|value
	            //     			           csre[scause][62:0] <= 8; // 8 indicate Ecall from U-mode; 9 call from S-mode; 11 call from M-mode
	            //     			           csre[sepc] <= pc;
	            //     			           csre[sstatus][8] <= 0; // save previous privilege mode(user0 super1) to SPP 
	            //     			           csre[sstatus][5] <= csre[sstatus][1]; // save interrupt enable(SIE) to SPIE 
	            //     			           csre[sstatus][1] <= 0; // clear SIE
	            //     			           //if ((csre[scause][63]==1'b1) && (csre[stvec][1:0]== 2'b01)) pc <= (csre[stvec][63:2] << 2) + (csre[scause][62:0] << 2);
	            //     			           pc <= (csre[stvec][63:2] << 2);
	            //     				   current_privilege_mode <= S_mode;
		    //				   bubble <= 1'b1;
	            //     			       end
	            //     			       // Trap into M-mode
	            //     			       else 
	            //     			       begin
	            //     			           csre[mcause][63] <= 0; //63_type 0exception 1interrupt|value
	            //     			           csre[mepc] <= pc;
	            //     			           csre[mstatus][7] <= csre[mstatus][3]; // save interrupt enable(MIE) to MPIE 
	            //     			           csre[mstatus][3] <= 0; // clear MIE (not enabled)
	            //     			           pc <= (csre[mtvec][63:2] << 2);
	            //                                        if (current_privilege_mode == U_mode && medeleg[8] == 0) csre[mcause][62:0] <= 8; // save cause 
	            //                                        if (current_privilege_mode == S_mode) csre[mcause][62:0] <= 9; 
	            //     			           if (current_privilege_mode == M_mode) csre[mcause][62:0] <= 11; 
	            //     				   csre[mstatus][12:11] <= current_privilege_mode; // save privilege mode to MPP 
	            //     				   current_privilege_mode <= M_mode;  // set current privilege mode
		    //				   bubble <= 1'b1;
	            //     			       end
	            //     			       end
                    //// Ebreak
	            //32'b0000000_00001_?????_000_?????_1110011: begin  end
	            //// Sret
	            //32'b0001000_00010_?????_000_?????_1110011: begin      
	            //     			       if (csre[sstatus][8] == 0) current_privilege_mode <= U_mode;
	            //     			       if (csre[sstatus][8] == 1) current_privilege_mode <= S_mode;
	            //     			       csre[sstatus][1] <= csre[sstatus][5]; // set back interrupt enable(SIE) by SPIE 
	            //     			       csre[sstatus][5] <= 1; // set previous interrupt enable(SIE) to be 1 (enable)
	            //     			       csre[sstatus][8] <= 0; // set previous privilege mode(SPP) to be 0 (U-mode)
	            //     			       pc <=  csre[sepc]; // sepc was +4 by the software handler and written back to sepc
		    //			       bubble <= 1'b1;
	            //     			       end
		     // Ebreak
		     // Fence
		     // Fence.i
		     // RV64IMAFD(G)C  RVA23U64
		     // M mul mulh mulhsu mulhu div divu rem remu mulw divw divuw remuw
		     // A lr.w sc.w lr.d sc.d
		     // amoswap amoadd amoxor amoand amoor
		     // amomin amomax amominu amomaxu
		     // F (reg f0-f31)
		     // flw fsw fadd.s fsub.s fmul.s fdiv.s fsqrt.s fmadd.s
		     // fmsub.s fnmsub.s fcvt.w.s fcvt.wu.s fcvt.s.w fcvt.s.wu
		     // fmv.x.w fclass.s feq.s flt.s fle.s fsgnj.s fsgnjn.s
		     // fsgnjx.s fmin.s fmax.s
		     // D fld fsd fadd.d fsub.d fdiv.d fsqrt.d fmadd.s fcvt.d.s fcvt.s.d
		     // C
		     default: $display("unknow instruction %h, %b", ir, ir);
                endcase
	    end
        end
    end

endmodule

//PLIC
//CLINT
  
  
//interrupt
//N+0 see interrupt and set isr pc
//N+1 bubble branch take over
//Lb
//N+2 execute load:step_0 setting read bubble1 load_step1
//N+3 bubble branch take over (BUT bus read data into bus_read_data)
//N+4 execute load:step_1 save bus_read_data into re
//Sb
//N+5 save re to bus_write_data
//mret
//N+6 mret (BUT URAT get data for print).   //
// -- 
//in cycle N0, IF fetching sb, EXE ir is lb, bubble is setting 1, pc is re-setting to pc, load_step is setting to 1;
//in N1, IF fetching lb, Bubble flushed ir sb, bubble <=0, Default pc is setting to lb+4(sb);
//in N2, IF fetching sb, EXE ir is lb, load_step is 1, bus_read_data is saving to re, load_step is setting to 0;
//in N3, IF fethcing mret, EXE ir is sb, re is saving to bus_write_data, bus_write_enable is setting to 1;
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
            //if (counter == 25000000 - 1) begin // 1hz
            if (counter == 2500000 - 1) begin // 10hz
                counter <= 0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule

//#`define Sdc_base  32'h0000_3000 (3000-31ff 512 bytes index) sd_cache 
//#`define Sdc_addr  32'h0000_3200
//#`define Sdc_read  32'h0000_3204
//#`define Sdc_write 32'h0000_3208
//#`define Sdc_ready 32'h0000_3220
//#`define Sdc_dirty 32'h0000_3224
//#`define Sdc_avail 32'h0000_3228
//# UART 0x2004
//
//.globl _start
//_start:
//
//# UART base (for print_char)
//lui t0, 0x2
//addi t0, t0, 4      # t0 = 0x2004
//
//# SD controller base
//lui a1, 0x3         # a1 = 0x3000 base
//
//# -- Wait SD ready
//sd_ready:
//lw a2, 0x220(a1)    # a2 0x3220 ready
//beq a2, x0, sd_ready
//
//# -- Read Boot Sector 0 -- 
//li a2, 0
//jal sd_read_sector
//
//li t1, 65        # A
//sw t1, 0(t0)     # print
//
//#jal print_sector
//
//# -- Parse BPB -- little-endian
//
//# bytes_per_sector offset 0x0b-0x0c 2 bytes
//addi t1, a1, 0x0B 
//lw t2, 0(t1)
//andi t2, t2, 0xff
//
//addi t1, a1, 0x0C  
//lw t3, 0(t1)
//andi t3, t3, 0xff
//
//slli t3, t3, 8
//or t2, t2, t3
//mv s0, t2    # s0 = bytes_per_sector offset 0x0b-0x0c 2 bytes
// 
//# sectors_per_cluster offset 0x0d 1 byte
//addi t1, a1, 0x0D
//lw t2, 0(t1)
//andi t2, t2, 0xff
//mv s1, t2    # s1 = sectors per cluster offset 0x0d 1 byte
//
//# reserved_sectors offset 0x0e-0x0f 2 bytes (including root sector 0)
//addi t1, a1, 0x0E
//lw t2, 0(t1)
//andi t2, t2, 0xff
//
//addi t1, a1, 0x0F 
//lw t3, 0(t1)
//andi t3, t3, 0xff
//
//slli t3, t3, 8
//or t2, t2, t3
//mv s2, t2    # s2 = reserved_sectors offset 0x0e-0x0f 2 bytes (including root sector 0)
//
//# num_fats offset 0x10 1 bytes
//addi t1, a1, 0x10
//lw t2, 0(t1)
//andi t2, t2, 0xff
//mv s3, t2  # s3 = num_fats offset 0x10 1 bytes
//
//# root_entries offset 0x11-0x12 2 bytes
//addi t1, a1, 0x11
//lw t2, 0(t1)
//andi t2, t2, 0xff
//
//addi t1, a1, 0x12
//lw t3, 0(t1)
//andi t3, t3, 0xff
//
//slli t3, t3, 8
//or t2, t2, t3
//mv s4, t2    # s4 = root_entries offset 0x11-0x12 2 bytes
//
//# sectors_per_fat16 high offset 0x16-0x17 2 bytes
//addi t1, a1, 0x16
//lw t2, 0(t1)
//andi t2, t2, 0xff
//
//addi t1, a1, 0x17
//lw t3, 0(t1)
//andi t3, t3, 0xff
//
//slli t3, t3, 8
//or t2, t2, t3
//mv s5, t2    # s5 = sectors_per_fat16 high offset 0x16-0x17 2 bytes
//
//# root_dir_sector_start = reserved_sectors + (num_fats * sectors_per_fat16)
//mul t4, s3, s5
//add t4, t4, s2
//mv s6, t4     # s6 = root_dir_sector_start
//
//# -- Read Root Dir first sector --
//mv a2, s6
//jal sd_read_sector
//
//li t1, 66 # B
//sw t1, 0(t0)     # print
//#jal print_sector
//
//# -- Scan Entries --
//# entries_per_sector = bytes_per_sector / 32 -> srli 5
//srli s7, s0, 5 # s7 = entries_per_sector (512/32=16)
//li s8, 0       # s8 = entry_index
//
//entry_loop:
//bge s8, s7, done_entries
//
//# entry_addr = a1 + (entry_index * 32)
//li t1, 32
//mul t2, s8, t1 # t2 = offset
//add t3, a1, t2 # t3 = address of entry
//
//# first byte of entry
//lw t4, 0(t3)
//beq t4, x0, done_entries # 0x00 no more entries in dir
//li t1, 0xE5
//beq t4, t1, next_entry # 0xE5 deleted entry, skip
//
//# attribute at 0x0B(11)
//lw t5, 11(t3)
//li t1, 0x0F
//beq t5, t1, next_entry # 0x0F LFN entry, skip
//
//andi t6, t5, 0x08
//bne t6, x0, next_entry # Bit 3 set Volume lable, skip 
//
//# first cluster at 0x1A-0x1B 2 bytes
//# file size at 0x1C-0x1D-0x1E-0x1F 4 bytes
//
//# print 8.3 name
//li a3, 0 # a3 = name char index
//li a6, 8 # a6 = exit char index
//li a7, 0 # name_chars
//li a2, 0x4D55534943202020  # MUSIC___
//
//print_name_loop:
//add a4, t3, a3 # a4 = name char address
//lw a5, 0(a4)   # a5 = name char
//sw a5, 0(t0)
//
//slli a7, a7, 8
//or a7, a7, a5
//addi a3, a3, 1
//blt a3, a6, print_name_loop
//beq a7, a2, find_file_entry
//
//next_entry:
//addi s8, s8, 1
//j entry_loop
//
//done_entries:
//li t1, 90  # Z
//sw t1, 0(t0)
//j done_entries
//
//find_file_entry:
//li t1, 89  # Y
//sw t1, 0(t0)
//#j find_file
//
//# file size at 0x1C-0x1D-0x1E-0x1F 4 bytes
//addi t1, t3, 0x1C
//lw t2, 0(t1)
//andi t2, t2, 0xff
//
//addi t1, t3, 0x1D
//lw t4, 0(t1)
//andi t4, t4, 0xff
//slli t4, t4, 8
//or t2, t2, t4
//
//addi t1, t3, 0x1E
//lw t4, 0(t1)
//andi t4, t4, 0xff
//slli t4, t4, 16
//or t2, t2, t4
//
//addi t1, t3, 0x1F
//lw t4, 0(t1)
//andi t4, t4, 0xff
//slli t4, t4, 24
//or t2, t2, t4
//mv s9, t2   # s9 = file_size_bytes  
//
//
//# first cluster at 0x1A-0x1B 2 bytes
//addi t1, t3, 0x1A
//lw t2, 0(t1)
//andi t2, t2, 0xff
//
//addi t1, t3, 0x1B
//lw t4, 0(t1)
//andi t4, t4, 0xff
//slli t4, t4, 8
//or t2, t2, t4
//mv s10, t2   # s10 = file_cluster_start_number
//
//# print file_cluster_start_number
//li t1, 123  # {
//sw t1, 0(t0) # print
//srli t2, s10, 8
//jal print_hex_b
//mv t2, s10
//jal print_hex_b
//li t1, 125  # }
//sw t1, 0(t0) # print
//
//# s0 = bytes_per_sector
//# s1 = sectors_per_cluster
//# s2 = reserved_sectors
//# s3 = num_fats
//# s4 = root_entries
//# s5 = sectors_per_fat16
//# s6 = root_dir_sector_start
//# s7 = entries_per_sector (512/32=16)
//# s8 = entry_index
//# s9 = file_size_bytes  
//# s10 = file_cluster_start_number
//# s11 = root_dir_sectors
//
//# print bytes_per_sector
//li t1, 91  # [
//sw t1, 0(t0) # print
//srli t2, s0, 8
//jal print_hex_b
//mv t2, s0
//jal print_hex_b
//li t1, 93  # ]
//sw t1, 0(t0) # print
//
//# print  sectors_per_cluster
//li t1, 91  # [
//sw t1, 0(t0) # print
//mv t2, s1
//jal print_hex_b
//li t1, 93  # ]
//sw t1, 0(t0) # print
//
//# print root_entries
//li t1, 91  # [
//sw t1, 0(t0) # print
//srli t2, s4, 8
//jal print_hex_b
//mv t2, s4
//jal print_hex_b
//li t1, 93  # ]
//sw t1, 0(t0) # print
//
//# root_dir_sector_start = reserved_sectors + (num_FATs * sectors_per_FAT)
//# root_dir_sectors = (RootEntryCount * 32 + BytesPerSector -1 )/ BytesPerSector
//# FirstDataSector = root_dir_sector_start + root_dir_sectors 
//# FirstSectorOfCluster(N)=FirstDataSector + (N - 2) * SectorsPerCluster
//
//#(.4000)(41FF)()
//# ------
//# print RootEntryCount * 32
//li t1, 32
//mul t6, s4, t1
//
//li t1, 40  # (
//sw t1, 0(t0) # print
//li t1, 46  # .
//sw t1, 0(t0) # print
//srli t2, t6, 8
//jal print_hex_b
//mv t2, t6
//jal print_hex_b
//li t1, 41  # )
//sw t1, 0(t0) # print
//
//# ------ (41ff 16895)
//# print  t6 + 512 - 1
//add t6, t6, s0
//addi t6, t6, -1
//
//li t1, 40  # (
//sw t1, 0(t0) # print
//srli t2, t6, 8
//jal print_hex_b
//mv t2, t6
//jal print_hex_b
//li t1, 41  # )
//sw t1, 0(t0) # print
//
//
//# calculate root_dir_sectors 
//li t1, 32
//mul t4, s4, t1
//addi t3, s0, -1
//add t4, t4, t3
//divu t3, t4, s0
//mv s11, t3 # s11 = root_dir_sectors
//
//
//
//# file_cluster_start_number
//# bytes_per_sector
//# sectors_per_cluster
//# root_entries
//# root_dir_sectors
//# file_first_sector
//# {00BD}[0200][40][0200][41FF](30E1) 
//# s10     s0   s1  s4    s11
//
//
//# print root_dir_sectors 0x0020
//li t1, 91  # [
//sw t1, 0(t0) # print
//srli t2, s11, 8
//jal print_hex_b
//mv t2, s11
//jal print_hex_b
//li t1, 93  # ]
//sw t1, 0(t0) # print
//
//# calculate first data sector
//add t1, s6, s11
//
//# calculate file_first_sector
//addi t2, s10, -2
//mul t3, t2, s1
//add t6, t1, t3 # t6 = file's first sector
//
//# print file_first_sector 0x30E1)
//li t1, 40  # (
//sw t1, 0(t0) # print
//srli t2, t6, 8
//jal print_hex_b
//mv t2, t6
//jal print_hex_b
//li t1, 41  # )
//sw t1, 0(t0) # print
//
//# read & print file_first_sector 
//mv a2, t6
//jal sd_read_sector
//jal print_sector
//
//
//
//# ---  sd_read_sector ---
//sd_read_sector:
//sw a2, 0x200(a1) # Write Sector index value to address 0x3200
//li t1, 1
//sw t1, 0x204(a1) # Trigger read at 0x3204
//wait_ready:
//lw t2, 0x220(a1)    # t2 0x3220 ready
//beq t2, x0, wait_ready
//wait_cache:
//lw t2, 0x228(a1)    # t2 0x3228 cache_avaible
//beq t2, x0, wait_cache
//ret
//
//
//# BPB
//#Field,Value
//#Jump Instruction,EB3C90
//#OEM Name,BSD  4.4
//#Bytes per Sector,512
//#Sectors per Cluster,64
//#Reserved Sectors,1
//#Number of FATs,2
//#Root Directory Entries,512
//#Total Sectors (small),0
//#Media Descriptor,0xF0
//#Sectors per FAT,256
//#Sectors per Track,32
//#Number of Heads,255
//#Hidden Sectors,0
//#Total Sectors (large),4194144
//#Drive Number,0
//#Reserved,0
//#Extended Boot Signature,0x29
//#Volume ID,0x31761C09
//#Volume Label,NO NAME
//#File System Type,FAT16
//#Error Message,\r\nNon-system disk\r\nPress any key to reboot\r\n
//#Boot Signature,55AA
//
//
//#| Entry | Type    | Short Name          | Attribute | Notes                                             |
//#| :---: | :------ | :------------------ | :-------: | :------------------------------------------------ |
//#|   0   | Invalid | –                   |    0x0F   | garbage / deleted LFN                             |
//#|   1   | LFN     | (part of SPOTLIGHT) |    0x0F   | Unicode chars `.Spotlight-`                       |
//#|   2   | Short   | `SPOTLI~1`          |    0x12   | Short name for `.Spotlight-`                      |
//#|   3   | LFN     | (part of FSEVEN)    |    0x0F   | Unicode chars `fsseven`                           |
//#|   4   | Short   | `FSEVEN~1`          |    0x12   | short name for that                               |
//#|   5   | Short   | `MUSIC   WAV`       |    0x20   | ✅ file MUSIC.WAV, cluster 5B62, size 32 146 bytes |
//#|   6   | LFN     | (part of _MUSIC...) |    0x0F   | Unicode sequence `_music.wav`                     |
//#|   7   | Short   | `_MUSIC~1.WAV`      |    0x22   | Hidden/Archive                                    |
//#|   8   | LFN     | (part of TRASHE)    |    0x0F   | Unicode “Trashes”                                 |
//#|   9   | Short   | `TRASHE~1`          |    0x12   | Hidden+archive (macOS trash)                      |
//#|  10+  | Empty   | —                   |    0x00   | end of directory                                  |
//
//
//# FAT16 Raw Construction
//# ReservedSectors(including root sector 0)|FAT|rootDirectorySectors(entry32bytes*cnt/512=sectores)|Clusters(First cluster is 2)
//# sector0 = initial information
//# root_dir_sector = reserved_sectors + (num_FATs * sectors_per_FAT)
//# RootDirEntry0x1A-0x1B = file's firstClusterNumber(N)
//# DataRegionStart(FirstDataSector) = root_dir_start_sector + root_dir_sectors
//# FirstSectorOfCluster(N)=FirstDataSector + (N - 2) * SectorsPerCluster
//
//
//# FAT16 Raw Data Layout
//#| Region                     | Description                                                    | Formula / Range                                                     |
//#| :------------------------- | :------------------------------------------------------------- | :------------------------------------------------------------------ |
//#| **Boot Sector (BPB)**      | Sector 0 — contains BIOS Parameter Block (filesystem metadata) | Sector 0                                                            |
//#| **Reserved Sectors**       | Includes boot sector + any reserved sectors                    | 0 → (ReservedSectors − 1)                                           |
//#| **FAT Region**             | Contains cluster chain tables                                  | `ReservedSectors → ReservedSectors + (NumFATs * SectorsPerFAT) − 1` |
//#| **Root Directory Region**  | Contains fixed 32-byte directory entries                       | `RootDirStartSector = ReservedSectors + (NumFATs * SectorsPerFAT)`  |
//#| **Data Region (Clusters)** | File and directory data stored here                            | `DataRegionStart = RootDirStartSector + RootDirSectors`             |
//
//#RootDirSectors = RootEntries * 32 /BytesPerSector
//
//# Sector 0 Layout # BPB (BIOS Parameter Block) in sector 0
//#| Offset | Size | Field                           | Meaning                        | Example (FAT16) |
//#| :----- | :--- | :------------------------------ | :----------------------------- | :-------------- |
//#| `0x00` | 3    | Jump Instruction                | JMP to boot code               | EB 3C 90        |
//#| `0x03` | 8    | OEM Name                        | Text label                     | "MSDOS5.0"      |
//#| `0x0B` | 2    | **Bytes per sector**            | Usually 512                    | 0x0200          |
//#| `0x0D` | 1    | **Sectors per cluster**         | Cluster size (e.g. 1,2,4,8,16) | 1               |
//#| `0x0E` | 2    | **Reserved sectors**            | Includes boot sector           | 1               |
//#| `0x10` | 1    | **Number of FATs**              | Typically 2                    | 2               |
//#| `0x11` | 2    | **Root entries**                | Count of directory entries     | 512             |
//#| `0x13` | 2    | **Total sectors (16-bit)**      | If zero, use 0x20–0x23         | 2880            |
//#| `0x15` | 1    | **Media descriptor**            | 0xF8 (fixed disk)              | F8              |
//#| `0x16` | 2    | **Sectors per FAT**             | FAT size                       | 9               |
//#| `0x18` | 2    | **Sectors per track**           | BIOS info                      | 18              |
//#| `0x1A` | 2    | **Number of heads**             | BIOS info                      | 2               |
//#| `0x1C` | 4    | **Hidden sectors**              | Partition offset               | 0               |
//#| `0x20` | 4    | **Total sectors (32-bit)**      | Large volumes                  | 0               |
//#| `0x24` | —    | (More fields in FAT32 only)     | —                              | —               |
//#| `0x36` | 11   | Volume Label / File System Type | "NO NAME    " / "FAT16   "     | —               |
//
//# BPB (BIOS Parameter Block) in sector 0
//# offset size FAT16 FAT32 filed 
//# 0x0b 2    512   512   bytes per secter
//# 0x0d 2                sectors per cluster 
//# 0x0e 2    1     32    reserverd sectors
//# 0x10 1    2     2     numbers of FATs
//# 0x11 2    512   0     root entries
//# 0x16 2    9     0     sectors per FAT
//# 0x24 4    0     0x9f0 sectors per FAT (fat32 only)
//# 0x2c                  root cluster (fat32 only)
//# 0x36 8    FAT16 FAT32 FAT label string 
//
//
//# Entry Layout(in Root Directory)
//#| Offset | Size | Field                             | Description                  | Example      |
//#| :----- | :--- | :-------------------------------- | :--------------------------- | :----------- |
//#| `0x00` | 8    | **Filename**                      | 8 chars (space padded)       | `"MUSIC   "` | FAT16 8.3 format for name.extension
//#| `0x08` | 3    | **Extension**                     | 3 chars (space padded)       | `"WAV"`      |
//#| `0x0B` | 1    | **Attributes**                    | Bit flags (see below)        | 0x20         |
//#| `0x0C` | 1    | Reserved                          | For Windows NT               | 0            |
//#| `0x0D` | 1    | Creation time (tenths)            | Optional                     | —            |
//#| `0x0E` | 2    | Creation time                     | —                            | —            |
//#| `0x10` | 2    | Creation date                     | —                            | —            |
//#| `0x12` | 2    | Last access date                  | —                            | —            |
//#| `0x14` | 2    | High word of cluster (FAT32 only) | —                            | —            |
//#| `0x16` | 2    | Last modified time                | —                            | —            |
//#| `0x18` | 2    | Last modified date                | —                            | —            |
//#| `0x1A` | 2    | **First cluster (low word)**      | Cluster number (starts at 2) | 0x0002       |
//#| `0x1C` | 4    | **File size (bytes)**             | File length                  | 4096         |
//
//# Attribute at 0x0B(11)
//#| Attribute | Meaning               | Example entry        |
//#| :-------: | :-------------------- | :------------------- |
//#|   `0x0F`  | Long file name (LFN)  | `xx xx xx xx ... 0F` |
//#|   `0x20`  | Archive (normal file) | `"MUSIC   WAV"`      |
//#|   `0x10`  | Directory             | `"FOLDER  "`         |
//#|   `0x08`  | Volume label          | `"NO NAME "`         |
//#|   `0x00`  | Unused entry          | empty/deleted        |
//
//# Attribute Type Bits(0x0B)
//#| Bit | Mask | Meaning               |
//#| :-- | :--- | :-------------------- |
//#| 0   | 0x01 | Read-only             |
//#| 1   | 0x02 | Hidden                |
//#| 2   | 0x04 | System                |
//#| 3   | 0x08 | Volume label          |
//#| 4   | 0x10 | Subdirectory          |
//#| 5   | 0x20 | Archive (normal file) |
//#| 6   | 0x40 | Device (unused)       |
//#| 7   | 0x80 | Unused                |
//
//# FAT Table(Cluster->NextCluster Map) Each entry (2 bytes) in FAT corresponds to one cluster in the data area.
//#|No| Next Cluster      | Meaning of FAT entry (16-bit value) |
//#|- | :---------------- | :---------------------------------- |
//#|0 | `0x0000`          | Reserved Media description          |
//#|1 | `0x0000`          | Reserved                            |
//#|x | `0x0002`          | First uasble cluster                |
//#|2 | `0x0003`          | Second uasble cluster               |
//#|4.| `0x0004`–`0xFFEF` | Next cluster number in chain        |
//#|x | `0xFFF0`–`0xFFF6` | Reserved values                     |
//#|x | `0xFFF7`          | Bad cluster                         |
//#|x | `0xFFF8`–`0xFFFF` | End of file (EOF marker)            |
//
//# FATEntryOffset = N * 2
//# Which sector contained this FAT entry:
//# FATSector = ReservedSectors + (FATEntryOffset / BytesPerSector)
//# OffsetInSector = FATEntryOffset % BytesPerSector
//
//# root_dir_sector_start = reserved_sectors + (num_FATs * sectors_per_FAT)
//# root_dir_sectors = RootEntryCount * 32 + BytesPerSector -1 )/ BytesPerSector
//# FirstDataSector = root_dir_sector_start + root_dir_sectors 
//# FirstSectorOfCluster(N)=FirstDataSector + (N - 2) * SectorsPerCluster
//
//
//
//
//
//
//
//# print sector 0 512 bytes
//print_sector:
//li t1, 0   # byte index
//li t6, 511 # max byte index
//print_loop:
//#li a3, 32     # space 
//#sw a3, 0(t0)  # print start space per byte
//add a4, a1, t1 
//addi t1, t1, 1
//lw t2, 0(a4)           # load byte at 0x3000 a1+t1
//andi t2, t2, 0xFF   # Isolate byte value
//srli t3, t2, 4      # get high nibble
//slti t5, t3, 10     # if < 10 number
//beq t5, x0, letter_h
//addi t3, t3, 48     # 0 is "0" ascii 48
//j print_h_hex
//letter_h:
//addi t3, t3, 55     # 10 is "A" ascii 65 ..
//print_h_hex:
//sw t3, 0(t0)
//andi t4, t2, 0x0F      # get low nibble
//slti t5, t4, 10     # if < 10 number
//beq t5, x0, letter_l
//addi t4, t4, 48     # 0 is "0" ascii 48
//j print_l_hex
//letter_l:
//addi t4, t4, 55        # 10 is "A" ascii 65 ..
//print_l_hex:
//sw t4, 0(t0)
//bge t6, t1, print_loop
//ret
//# -- end print_sector --
//
//
//# funciton print_bin(a0) print 8 bits of a0 at t0 UART
//print_bin_f:
//li t1, 8 # number of bits
//print_binf_loop:
//addi t1, t1, -1
//srl t2, a0, t1
//andi t2, t2, 1
//addi t2, t2, 48  # 0 to "0"
//sw t2, 0(t0)     # print
//bne t1, x0, print_binf_loop
//# clean middle re
//addi t1, x0, 0
//addi t2, x0, 0
//ret
//
//
//
//# print_hex_b(t2)
//print_hex_b:
//andi t2, t2, 0xFF   # Isolate byte value
//
//srli t3, t2, 4      # get high nibble
//slti t5, t3, 10     # if < 10 number
//beq t5, x0, letterh
//addi t3, t3, 48     # 0 is "0" ascii 48
//j print_hhex
//letterh:
//addi t3, t3, 55     # 10 is "A" ascii 65 ..
//print_hhex:
//sw t3, 0(t0)
//
//andi t4, t2, 0x0F      # get low nibble
//slti t5, t4, 10     # if < 10 number
//beq t5, x0, letterl
//addi t4, t4, 48     # 0 is "0" ascii 48
//j print_lhex
//letterl:
//addi t4, t4, 55        # 10 is "A" ascii 65 ..
//print_lhex:
//sw t4, 0(t0)
//
//# clean middle re
//addi t3, x0, 0
//addi t4, x0, 0
//addi t5, x0, 0
//ret
//
//
//# sector 0:
//# EB3C904253442020342E3400024001000200020000F000012000FF000000000060FF3F00000029091C76314E4F204E414D45202020204641543136202020FA31C08ED0BC007CFB8ED8E800005E83C619BB0700FCAC84C07406B40ECD10EBF530E4CD16CD190D0A4E6F6E2D73797374656D206469736B0D0A507265737320616E79206B657920746F207265626F6F740D0A000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055AA
//
//# raw root_dir_sector_start:
//#42300030000000FFFFFFFF0F0021FFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF012E00530070006F0074000F00216C0069006700680074002D0000005600310053504F544C497E312020201200591AA44E5B4E5B00001AA44E5B020000000000412E0066007300650076000F00DA65006E0074007300640000000000FFFFFFFF46534556454E7E3120202012009B7AA6625B625B00007AA6625B0400000000004D555349432020205741562018277D924E5B625B00007D924E5BBD00C4E10F00412E005F006D00750073000F004C690063002E0077006100760000000000FFFF5F4D5553497E31205741562200280CB24F5B625B00000CB24F5BBC0000100000412E0054007200610073000F00256800650073000000FFFFFFFF0000FFFFFFFF5452415348457E312020201200BBE1B14F5B4F5B0000E1B14F5B1B0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000B00�
//#| Offset | Bytes                     | Meaning                                              |
//#| ------ | ------------------------- | ---------------------------------------------------- |
//#| 00–07  | `4D 55 53 49 43 20 20 20` | “MUSIC   ”                                           |
//#| 08–0A  | `57 41 56`                | “WAV”                                                |
//#| 0B     | `20`                      | Attribute 0x20 → normal file                         |
//#| 0C–0D  | `18 27`                   | creation time/date (not relevant now)                |
//#| 1A–1B  | `BD 00`                   | **First cluster = 0x00BD = 189 = 10111101 **         |
//#| 1C–1F  | `C4 E1 0F 00`             | **File size = 0x000FE1C4 = 651,076 bytes (~636 KB)** |
//
//
//
//# file_cluster_start_number
//# bytes_per_sector
//# sectors_per_cluster
//# root_entries
//# root_dir_sectors
//# file first sector
//# {00BD}[0200][40][0200][43FF](7434) 
//
//
//#sudo dd if=/dev/disk2 bs=512 skip=12513 count=1 |hexdump -C
//#512 bytes transferred in 0.001376 secs (372116 bytes/sec)
//#00000000  52 49 46 46 bc e1 0f 00  57 41 56 45 66 6d 74 20  |RIFF....WAVEfmt |
//#00000010  10 00 00 00 01 00 02 00  44 ac 00 00 10 b1 02 00  |........D.......|
//#00000020  04 00 10 00 64 61 74 61  98 e1 0f 00 3d f7 fb f6  |....data....=...|
//#00000030  f7 f7 3e f7 b7 f8 83 f7  7b f9 cc f7 3e fa 1c f8  |..>.....{...>...|
//#00000040  fd fa 74 f8 b5 fb d5 f8  62 fc 45 f9 ff fc c6 f9  |..t.....b.E.....|
//#00000050  8a fd 5a fa 05 fe fb fa  71 fe a2 fb d0 fe 49 fc  |..Z.....q.....I.|
//#00000060  25 ff e8 fc 76 ff 78 fd  cc ff f3 fd 2d 00 58 fe  |%...v.x.....-.X.|
//#00000070  9c 00 a9 fe 19 01 e8 fe  a6 01 18 ff 44 02 42 ff  |............D.B.|
//#00000080  f0 02 6d ff a1 03 a2 ff  53 04 e5 ff 04 05 38 00  |..m.....S.....8.|
//#00000090  ad 05 9b 00 49 06 0b 01  d5 06 85 01 51 07 01 02  |....I.......Q...|
//#000000a0  c1 07 7d 02 24 08 f9 02  7a 08 74 03 c3 08 ec 03  |..}.$...z.t.....|
//#000000b0  ff 08 64 04 2c 09 e0 04  49 09 60 05 59 09 e2 05  |..d.,...I.`.Y...|
//#000000c0  60 09 63 06 5e 09 e1 06  53 09 58 07 41 09 c2 07  |`.c.^...S.X.A...|
//#000000d0  2b 09 1a 08 14 09 5d 08  f9 08 8c 08 da 08 aa 08  |+.....].........|
//#000000e0  b8 08 b7 08 94 08 b5 08  6b 08 a7 08 3d 08 95 08  |........k...=...|
//#000000f0  0a 08 82 08 d3 07 71 08  97 07 64 08 56 07 5d 08  |......q...d.V.].|
//#00000100  12 07 5f 08 cb 06 6a 08  7d 06 7c 08 26 06 95 08  |.._...j.}.|.&...|
//#00000110  c7 05 b5 08 5f 05 d9 08  e9 04 f8 08 5f 04 0b 09  |...._......._...|
//#00000120  bf 03 0d 09 0a 03 fb 08  3c 02 ce 08 55 01 80 08  |........<...U...|
//#00000130  56 00 08 08 49 ff 64 07  36 fe 93 06 26 fd 92 05  |V...I.d.6...&...|
//#00000140  1f fc 62 04 2a fb 06 03  52 fa 84 01 9b f9 e6 ff  |..b.*...R.......|
//#00000150  08 f9 3a fe 97 f8 8e fc  47 f8 f0 fa 12 f8 6b f9  |..:.....G.....k.|
//#00000160  ef f7 0a f8 d6 f7 d4 f6  bc f7 ce f5 98 f7 f9 f4  |................|
//#00000170  68 f7 51 f4 29 f7 d1 f3  da f6 73 f3 80 f6 2f f3  |h.Q.).....s.../.|
//#00000180  22 f6 01 f3 ca f5 e5 f2  7e f5 db f2 41 f5 e5 f2  |".......~...A...|
//#00000190  16 f5 ff f2 05 f5 2c f3  10 f5 6d f3 37 f5 c2 f3  |......,...m.7...|
//#000001a0  76 f5 26 f4 c9 f5 94 f4  30 f6 08 f5 ac f6 81 f5  |v.&.....0.......|
//#000001b0  37 f7 f9 f5 ce f7 6b f6  69 f8 d5 f6 08 f9 37 f7  |7.....k.i.....7.|
//#000001c0  a6 f9 96 f7 3e fa f6 f7  cb fa 5d f8 4a fb d2 f8  |....>.....].J...|
//#000001d0  b9 fb 58 f9 19 fc ef f9  67 fc 97 fa a0 fc 49 fb  |..X.....g.....I.|
//#000001e0  c5 fc 01 fc db fc b8 fc  e8 fc 67 fd f5 fc 09 fe  |..........g.....|
//#000001f0  07 fd 9c fe 27 fd 21 ff  58 fd 9b ff 9d fd 0c 00  |....'.!.X.......|
