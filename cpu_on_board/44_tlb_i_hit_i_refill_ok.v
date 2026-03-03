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
    (* chip_pin = "J2" *)  output wire HEX00,
    (* chip_pin = "J1" *)  output wire HEX01,
    (* chip_pin = "H2" *)  output wire HEX02,
    (* chip_pin = "H1" *)  output wire HEX03,
    (* chip_pin = "F2" *)  output wire HEX04,
    (* chip_pin = "F1" *)  output wire HEX05,
    (* chip_pin = "E2" *)  output wire HEX06,
    (* chip_pin = "E1" *)  output wire HEX10,
    (* chip_pin = "H6" *)  output wire HEX11,
    (* chip_pin = "H5" *)  output wire HEX12,
    (* chip_pin = "H4" *)  output wire HEX13,
    (* chip_pin = "G5" *)  output wire HEX20,
    (* chip_pin = "G6" *)  output wire HEX21,
    (* chip_pin = "C2" *)  output wire HEX22,
    (* chip_pin = "C1" *)  output wire HEX23,
    (* chip_pin = "F4" *)  output wire HEX30,
    (* chip_pin = "D5" *)  output wire HEX31,
    (* chip_pin = "D6" *)  output wire HEX32,
    (* chip_pin = "J4" *)  output wire HEX33,
    (* chip_pin = "L8" *)  output wire HEX34,
    (* chip_pin = "F3" *)  output wire HEX35,
    (* chip_pin = "D4" *)  output wire HEX36,
    (* chip_pin = "H15" *)  input wire PS2_CLK, 
    (* chip_pin = "J14" *)  input wire PS2_DAT,
    (* chip_pin = "V20" *)  output wire SD_CLK, //SD_CLK
    (* chip_pin = "Y20" *)  inout wire SD_CMD, // SD_CMD (MOSI)
    (* chip_pin = "W20" *)  inout wire SD_DAT0, // SD_DAT (MISO)
    (* chip_pin = "U20" *)  output wire SD_DAT3, // SD_DAT3
//);

    // -- SDRAM pins -- 
    (* chip_pin = "N6, W3, N4, P3, P5, P6, R5, R6, Y4, Y3, W5, W4" *)  output wire [11:0] DRAM_ADDR,
    (* chip_pin = "T2, T1, R2, R1, P2, P1, N2, N1, Y2, Y1, W2, W1, V2, V1, U2, U1" *)  inout wire [15:0] DRAM_DQ,
    (* chip_pin = "V4, U3" *)  output wire [1:0] DRAM_BA, // Bank address
    (* chip_pin = "T3" *)  output wire DRAM_CAS_N, // Column address strobe
    (* chip_pin = "T5" *)  output wire DRAM_RAS_N, // Row address strobe
    (* chip_pin = "U4" *)  output wire DRAM_CLK, 
    (* chip_pin = "N3" *)  output wire DRAM_CKE,  // Clock enable
    (* chip_pin = "R8" *)  output wire DRAM_WE_N, // write enable
    (* chip_pin = "T6" *)  output wire DRAM_CS_N,  // chip selected
    (* chip_pin = "M5, R7" *)  output wire [1:0] DRAM_DQM   // High-low byte data mask
);

reg [21:0] sdram_addr;
reg [15:0] sdram_wrdata;
reg [1:0]  sdram_byte_en; // Enable all bytes (active low);
// Control
reg sdram_write_en;
reg sdram_read_en;

wire [15:0] sdram_rddata;   
wire        sdram_req_wait;

sdram_controller sdram_ctrl (
    .sys_clk(CLOCK_50),
    .rstn(KEY0),
    // to bus (software)
    .avl_addr(sdram_addr),
    .avl_byte_en(sdram_byte_en),
    .avl_WRITEen(sdram_write_en),
    .avl_READen(sdram_read_en),
    .avl_WRDATA(sdram_wrdata),
    .avl_RDDATA(sdram_rddata),
    .avl_req_wait(sdram_req_wait),
    // to pin (hardware)
    .addr(DRAM_ADDR),        // new_sdram_controller_0_wire.addr
    .BA(DRAM_BA),            //                            .ba
    .CASn(DRAM_CAS_N),       //                            .cas_n
    .CSn(DRAM_CS_N),         //                            .cs_n
    .DQ(DRAM_DQ),            //                            .dq
    .DQM(DRAM_DQM),          //                            .dqm
    .RASn(DRAM_RAS_N),       //                            .ras_n
    .WEn(DRAM_WE_N)          //                            .we_n
);
assign DRAM_CLK = CLOCK_50;
assign DRAM_CKE = 1; // always enable

    // -- MEM -- minic L1 cache
    (* ram_style = "block" *) reg [31:0] Cache [0:2000];
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

    wire [63:0] ppc;
    reg [31:0] ir_bd;
    //wire bubble;
    // IR_LD BRAM Port A read
    always @(posedge CLOCK_50) begin ir_bd <= Cache[ppc>>2]; end
    wire [31:0] ir_ld; assign ir_ld = {ir_bd[7:0], ir_bd[15:8], ir_bd[23:16], ir_bd[31:24]}; // Endianness swap
    assign LEDR_PC = ppc/4;
    assign LEDG = ir_ld;

    // -- CPU --
    riscv64 cpu (
        //.clk(clock_1hz), 
        .clk(CLOCK_50), 
        .reset(KEY0),     
        .instruction(ir_ld),
        //.pc(pc),
        .ppc(ppc),
        //.bubble(bubble),
        //.ir(LEDG),
        .heartbeat(LEDR9),

        .bus_address(bus_address),
        .bus_write_data(bus_write_data),
        .bus_write_enable(bus_write_enable),
        .bus_read_enable(bus_read_enable),

        .bus_ls_type(bus_ls_type), // lb lh lw ld lbu lhu lwu sb sh sw sd 
	.mtime(mtime),
	.mtimecmp(mtimecmp),
	.meip_interrupt(meip_interrupt),
	.msip_interrupt(msip_interrupt),

        .bus_read_data(bus_read_data),
        .bus_read_done(bus_read_done),
        .bus_write_done(bus_write_done)
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
    reg uart_write_pulse;
    reg uart_write_step;
    reg uart_read_pulse;
    reg uart_read_step;
    wire uart_waitrequest;
    jtag_uart_system my_jtag_system (
        .clk_clk                                 (CLOCK_50),
        .reset_reset_n                           (KEY0),
        //.jtag_uart_0_avalon_jtag_slave_address   (bus_address[0:0]),
        .jtag_uart_0_avalon_jtag_slave_address   (~bus_address[2]), // 0x00 for Data, 0x04 for Control
        .jtag_uart_0_avalon_jtag_slave_writedata (bus_write_data[31:0]),
        //.jtag_uart_0_avalon_jtag_slave_write_n   (~uart_write_trigger_pulse),
        .jtag_uart_0_avalon_jtag_slave_write_n   (~uart_write_pulse),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        //.jtag_uart_0_avalon_jtag_slave_read_n    (~(bus_read_done==0 && Art_selected)),
        .jtag_uart_0_avalon_jtag_slave_read_n    (~uart_read_pulse),
	
        .jtag_uart_0_avalon_jtag_slave_readdata    (uart_readdata),
        .jtag_uart_0_avalon_jtag_slave_waitrequest (uart_waitrequest),
	.jtag_uart_0_irq_irq(uart_irq)                        
    );

    // -- Bus --
    reg  [63:0] bus_read_data;
    wire [63:0] bus_address;
    wire        bus_read_enable;
    wire [63:0] bus_write_data;
    wire        bus_write_enable;
    wire [2:0]  bus_ls_type; // lb lbu...sbhwd...
    wire [63:0] mtime;
    reg  [63:0] mtimecmp;


    // -- PLIC --
    reg [2:0]  Plic_priority [0:5];  // 0x000 + 4 per id
    reg [31:0] Plic_pending; // 0x1000 Global pending Bitmap 
    reg [31:0] Plic_enable [0:1];  // 0x2000 per context +0x80
    reg [2:0]  Plic_threshold [0:1]; // 0x200000 4B per hart
    //# PER PRIORITY(id) = base + 4 * id (000-fff) array
    //# base + 0x1000 id 1-32 ... bitmap
    //# base + 0x2000 + ContextID*0x80 0hart0M 1hart0S... bitmap
    //# base + 0x200000 + ContextID*0x1000 0hart0M 1hart0S...4B 
    //# base + 0x200004 + ContextID*0x1000 0hart0M 1hart0S...4B
    //
    // Address Decoding --
    wire Rom_selected = (bus_address >= `Rom_base && bus_address < `Rom_base + `Rom_size);
    wire Ram_selected = (bus_address >= `Ram_base && bus_address < `Ram_base + `Ram_size);
    wire Key_selected = (bus_address == `Key_base);
    wire Art_selected = (bus_address == `Art_base || bus_address == `ArtC_base);
    wire Sdc_addr_selected = (bus_address == `Sdc_addr);
    wire Sdc_read_selected = (bus_address == `Sdc_read);
    wire Sdc_write_selected = (bus_address == `Sdc_write);
    wire Sdc_ready_selected = (bus_address == `Sdc_ready);
    wire Sdc_cache_selected = (bus_address >= `Sdc_base && bus_address < (`Sdc_base + 512));
    wire Sdc_avail_selected = (bus_address == `Sdc_avail);
    wire Sdram_selected = (bus_address >= `Sdram_min && bus_address < `Sdram_max);
    wire Mtime_selected = (bus_address == `Mtime);
    wire Mtimecmp_selected = (bus_address == `Mtimecmp);
    wire CacheI_selected = (bus_address == `CacheI);
    wire Tlb_selected = (bus_address == `Tlb);

    // Plic mapping
    wire Plic_priority_selected = (bus_address >= `Plic_base && bus_address < `Plic_pending);
    wire Plic_pending_selected = (bus_address == `Plic_pending);
    wire Plic_enable_ctx0_selected = (bus_address == `Plic_enable);
    wire Plic_enable_ctx1_selected = (bus_address == `Plic_enable + 64'h80);
    wire Plic_threshold_ctx0_selected = (bus_address == `Plic_threshold);
    wire Plic_threshold_ctx1_selected = (bus_address == `Plic_threshold + 64'h1000);
    wire Plic_claim_ctx0_selected = (bus_address == `Plic_claim );
    wire Plic_claim_ctx1_selected = (bus_address == `Plic_claim + 64'h1000);
    //wire Plic_claim_ctx0_selected = (bus_address >= `Plic_claim && bus_address < `Plic_claim+1024*0x1000+4);
    reg [31:0] claim_interrupt_id_ctx [0:1]; // 0 for hart0M 1 for hart0S

    always @(*) begin
        claim_interrupt_id_ctx[0] = 0; 
        claim_interrupt_id_ctx[1] = 0; 
        if (Plic_pending[1] && Plic_enable[0][1]) claim_interrupt_id_ctx[0] = 1; 
        if (Plic_pending[1] && Plic_enable[1][1]) claim_interrupt_id_ctx[1] = 1; 
    end

    wire meip_interrupt = (claim_interrupt_id_ctx[0] != 0);
    wire msip_interrupt = (claim_interrupt_id_ctx[1] != 0);
    wire uart_irq;
    reg uart_irq_pre;
    wire [31:0] uart_readdata;


    // Read & Write BRAM Port B 
    reg [63:0] bus_address_reg;
    reg [63:0] bus_address_reg_full;
    reg [2:0] step = 0;
    reg bus_read_done = 1;
    reg bus_write_done = 1;
    reg [63:0] next_addr;
    wire [4:0] plic_id = (bus_address - `Plic_base) >> 2; // id = offset /4

    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            bus_read_done <= 1;
            bus_write_done <= 1;
	    bus_address_reg <= 0;
	    bus_address_reg_full <= 0;
	    next_addr <= 0;
	    step <= 0;
	    bus_read_data <= 0;
	    uart_write_pulse <= 0;
	    uart_read_pulse <= 0;
	    uart_read_step <= 0;
	    mtimecmp <=  64'h80000000;
	    uart_irq_pre <= 0;
	end else begin
        bus_address_reg <= bus_address>>2;
        bus_address_reg_full <= bus_address;
        sd_rd_start <= 0;
        uart_write_pulse <= 0;
	uart_read_pulse <= 0;
	uart_irq_pre <= uart_irq;
	if (uart_irq && !uart_irq_pre) Plic_pending[1] <= 1;
	//if (key_pressed_edge) Plic_pending[1] <= 1;

        if (bus_read_enable) begin bus_read_done <= 0; cid <= (bus_address-`Sdc_base); end 
        if (bus_write_enable) begin bus_write_done <= 0; end

        // Read
        //if (!bus_read_enable && bus_read_done==0) begin 
        if (bus_read_done==0) begin 
            if (Key_selected) begin bus_read_data <= {32'd0, 24'd0, ascii}; bus_read_done <= 1; end
	    if (Ram_selected) begin 
	        casez(bus_ls_type)
	            3'b011: begin // 011Ld
		        case(step)
			    0: begin bus_read_data[31:0]  <= Cache[bus_address_reg]; bus_address_reg <= bus_address_reg +1; step <= 1; end
		            1: begin bus_read_data[63:32] <= Cache[bus_address_reg]; step <= 0; bus_read_done <= 1; end
			endcase
		    end 
		    default: begin bus_read_data <= Cache[bus_address_reg] >> (8*bus_address_reg_full[1:0]); bus_read_done <= 1; end // 000Lb 001Lh 010Lw 101Lhu 100Lbu 110Lwu
		endcase
	    end

            if (Sdc_ready_selected) begin bus_read_data <= {63'd0, sd_ready}; bus_read_done <= 1; end
	    if (Sdc_cache_selected) begin bus_read_data <= {56'd0, sd_cache[cid]}; bus_read_done <= 1; end // one byte for all load
            if (Sdc_avail_selected) begin bus_read_data <= {63'd0, sd_cache_available}; bus_read_done <= 1; end 

            if (Mtime_selected) begin bus_read_data <= mtime; bus_read_done <= 1; end 
            if (Mtimecmp_selected) begin bus_read_data <= mtimecmp; bus_read_done <= 1; end 

	    if (Art_selected) begin 
	        if (uart_read_step ==0) begin uart_read_pulse <= 1; uart_read_step <= 1; end
	        if (uart_read_step ==1 && !uart_waitrequest) begin bus_read_data <= uart_readdata; uart_read_step <= 0; bus_read_done <=1; end
	    end

	    if (Sdram_selected) begin
		case(bus_ls_type)
	            3'b000: begin //lb
			   sdram_addr <= bus_address[22:1]; sdram_byte_en <= bus_address[0] ? 2'b10 : 2'b01; sdram_read_en <= 1; 
			   if (sdram_req_wait==0) begin 
			       case(bus_address[0])
				   0: begin bus_read_data <= {{56{sdram_rddata[7]}}, sdram_rddata[7:0]}; end  // byte 0
			           1: begin bus_read_data <= {{56{sdram_rddata[15]}}, sdram_rddata[15:8]}; end // byte 1
			       endcase
			       sdram_read_en <= 0; bus_read_done <= 1;
			   end
		    end
	            3'b100: begin //lbu
			   sdram_addr <= bus_address[22:1]; sdram_byte_en <= bus_address[0] ? 2'b10 : 2'b01; sdram_read_en <= 1; 
			   if (sdram_req_wait==0) begin 
			       case(bus_address[0])
				   0: begin bus_read_data <= {56'b0, sdram_rddata[7:0]}; end  // byte 0
			           1: begin bus_read_data <= {56'b0, sdram_rddata[15:8]}; end // byte 1
			       endcase
			       sdram_read_en <= 0; bus_read_done <= 1;
			   end
		    end
	            3'b001: begin // lh
			   sdram_addr <= bus_address[22:1]; sdram_byte_en <= 2'b11; sdram_read_en <= 1; 
			   if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data <= {{48{sdram_rddata[15]}}, sdram_rddata[15:0]}; bus_read_done <= 1; end
		    end
	            3'b101: begin // lhu 
			   sdram_addr <= bus_address[22:1]; sdram_byte_en <= 2'b11; sdram_read_en <= 1; 
			   if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data <= {48'b0, sdram_rddata[15:0]}; bus_read_done <= 1; end
		    end
	            3'b010: begin // lw
		        case(step)
		            0: begin sdram_addr <= bus_address[22:1]; sdram_byte_en <= 2'b11; sdram_read_en <= 1; 
			       if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data<= {48'b0, sdram_rddata[15:0]};bus_read_done <= 0; step <=1; end end
		            1: begin sdram_addr <= bus_address[22:1]+1; sdram_byte_en <= 2'b11; sdram_read_en <= 1; 
			       if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data[63:16] <= {{32{sdram_rddata[15]}}, sdram_rddata[15:0]}; bus_read_done <= 1; step <=0; end end
			endcase
		    end
	            3'b110: begin // lwu 
		        case(step)
		            0: begin sdram_addr <= bus_address[22:1]; sdram_byte_en <= 2'b11; sdram_read_en <= 1; 
			       if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data<= {48'b0, sdram_rddata[15:0]};bus_read_done <= 0; step <=1; end end
		            1: begin sdram_addr <= bus_address[22:1]+1; sdram_byte_en <= 2'b11; sdram_read_en <= 1; 
			       if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data[31:16] <= sdram_rddata[15:0]; bus_read_done <= 1; step <=0; end end
			endcase
		    end
	            3'b011: begin // ld 
		        case(step)
		            0: begin sdram_addr <= bus_address[22:1]; sdram_byte_en <= 2'b11; sdram_read_en <= 1; 
			       if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data<= {48'b0, sdram_rddata[15:0]};bus_read_done <= 0; step <=1; end end
		            1: begin sdram_addr <= bus_address[22:1]+1; sdram_byte_en <= 2'b11; sdram_read_en <= 1; 
			       if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data[31:16] <= sdram_rddata[15:0]; bus_read_done <= 0; step <=2; end end
		            2: begin sdram_addr <= bus_address[22:1]+2; sdram_byte_en <= 2'b11; sdram_read_en <= 1; 
			       if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data[47:32] <= sdram_rddata[15:0]; bus_read_done <= 0; step <=3; end end
		            3: begin sdram_addr <= bus_address[22:1]+3; sdram_byte_en <= 2'b11; sdram_read_en <= 1; 
			       if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data[63:48] <= sdram_rddata[15:0]; bus_read_done <= 1; step <=0; end end
			endcase
		    end
		endcase
                // 000Lb 001Lh 010Lw  011Ld // 100Lbu 101Lhu 110Lwu
	    end
            // Plic read
	    if (Plic_priority_selected) begin bus_read_data <= Plic_priority[plic_id]; bus_read_done <= 1; end
	    else if (Plic_pending_selected) begin bus_read_data <= Plic_pending; bus_read_done <= 1; end
	    // context 0 M-mode
	    else if (Plic_enable_ctx0_selected) begin bus_read_data <= Plic_enable[0]; bus_read_done <= 1; end
	    else if (Plic_threshold_ctx0_selected) begin bus_read_data <= Plic_threshold[0]; bus_read_done <= 1; end
	    else if (Plic_claim_ctx0_selected) begin bus_read_data <= claim_interrupt_id_ctx[0]; Plic_pending[claim_interrupt_id_ctx[0]]<=0; bus_read_done <= 1; end
	    // context 1 S-mode
	    else if (Plic_enable_ctx1_selected) begin bus_read_data <= Plic_enable[1]; bus_read_done <= 1; end
	    else if (Plic_threshold_ctx1_selected) begin bus_read_data <= Plic_threshold[1]; bus_read_done <= 1; end
	    else if (Plic_claim_ctx1_selected) begin bus_read_data <= claim_interrupt_id_ctx[1]; Plic_pending[claim_interrupt_id_ctx[1]]<=0; bus_read_done <= 1; end


        end

        // Write
        //if (bus_write_enable || sd!=0 ) begin 
        //if (!bus_write_enable && bus_write_done == 0) begin 
        if (bus_write_done == 0) begin 
	    if (Ram_selected) begin 
		bus_write_done <= 1;
		casez(bus_ls_type) // 000sb 001sh 010sw 011sd
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
		        case(step)
		            0: begin Cache[bus_address[63:2]] <= bus_write_data[31:0]; step <= 1; next_addr <= bus_address[63:2]+1; bus_write_done <= 0; end
			    1: begin Cache[next_addr] <= bus_write_data[63:32]; step <= 0; end
			endcase
			end
	        endcase
	    end

	    if (Sdc_addr_selected) begin sd_addr <= bus_write_data[31:0]; bus_write_done <= 1; end
	    if (Sdc_read_selected) begin sd_rd_start <= 1; bus_write_done <= 1; end

	    //if (Art_selected) begin uart_write_pulse <= 1; bus_write_done <=1; end
	    if (Art_selected) begin 
	        if (uart_write_step ==0) begin uart_write_pulse <= 1; uart_write_step <= 1; end
	        if (uart_write_step ==1 && !uart_waitrequest) begin uart_write_step <= 0; bus_write_done <=1; end
	    end

	    if (Mtimecmp_selected) begin mtimecmp <= bus_write_data; bus_write_done <= 1; end
	    //if (Sdram_selected) begin if (sdram_req_wait==0) bus_write_done <= 1; end

            if (Tlb_selected) bus_write_done <= 1; 
	    if (CacheI_selected) bus_write_done <= 1; 
	    
            // Plic write
	    if (Plic_priority_selected) begin Plic_priority[plic_id] <= bus_write_data; bus_write_done <= 1; end
	    // context 0
	    else if (Plic_enable_ctx0_selected) begin Plic_enable[0] <= bus_write_data; bus_write_done <= 1; end
	    else if (Plic_threshold_ctx0_selected) begin Plic_threshold[0] <= bus_write_data; bus_write_done <= 1; end
	    else if (Plic_claim_ctx0_selected) begin bus_write_done <= 1; end // set to 0 when read already
	    //else if (Plic_claim_ctx0_selected) begin Plic_pending[bus_write_data] <= 0; bus_write_done <= 1; end
	    // context 1
	    else if (Plic_enable_ctx1_selected) begin Plic_enable[1] <= bus_write_data; bus_write_done <= 1; end
	    else if (Plic_threshold_ctx1_selected) begin Plic_threshold[1] <= bus_write_data; bus_write_done <= 1; end
	    else if (Plic_claim_ctx1_selected) begin bus_write_done <= 1; end // set to 0 when read already
	    //else if (Plic_claim_ctx1_selected) begin Plic_pending[bus_write_data] <= 0; bus_write_done <= 1; end
	    
        end

	    if (Sdram_selected && bus_write_done==0) begin 
		case(bus_ls_type)
	            3'b000: begin //sb
		        sdram_addr<=bus_address[22:1];
		        sdram_wrdata<={bus_write_data[7:0],bus_write_data[7:0]};
		        sdram_write_en<=1;
		        sdram_byte_en <= bus_address[0] ? 2'b10 : 2'b01; 
		        if (sdram_req_wait==0) begin sdram_write_en <= 0; bus_write_done <= 1; end 
		    end
		    3'b001: begin //sh
		        sdram_addr <= bus_address[22:1]; sdram_wrdata <= bus_write_data[15:0]; sdram_write_en <= 1; sdram_byte_en <= 2'b11;
			if (sdram_req_wait==0) begin sdram_write_en <= 0; bus_write_done <= 1; end
		    end
		    3'b010: begin //sw
		        case(step)
		            0: begin sdram_addr <= bus_address[22:1]; sdram_wrdata <= bus_write_data[15:0]; sdram_write_en <= 1; sdram_byte_en <= 2'b11;
			       if (sdram_req_wait==0) begin sdram_write_en <= 0; bus_write_done <= 0; step <= 1; end end
		            1: begin sdram_addr <= bus_address[22:1]+1; sdram_wrdata <= bus_write_data[31:16]; sdram_write_en <= 1; sdram_byte_en <= 2'b11;
			       if (sdram_req_wait==0) begin sdram_write_en <= 0; bus_write_done <= 1; step <= 0; end end
			endcase
		    end
		    3'b011: begin //sd
		        case(step)
		            0: begin sdram_addr <= bus_address[22:1]; sdram_wrdata <= bus_write_data[15:0]; sdram_write_en <= 1; sdram_byte_en <= 2'b11;
			       if (sdram_req_wait==0) begin sdram_write_en <= 0; bus_write_done <= 0; step <= 1; end end
		            1: begin sdram_addr <= bus_address[22:1]+1; sdram_wrdata <= bus_write_data[31:16]; sdram_write_en <= 1; sdram_byte_en <= 2'b11;
			       if (sdram_req_wait==0) begin sdram_write_en <= 0; bus_write_done <= 0; step <= 2; end end
		            2: begin sdram_addr <= bus_address[22:1]+2; sdram_wrdata <= bus_write_data[47:32]; sdram_write_en <= 1; sdram_byte_en <= 2'b11;
			       if (sdram_req_wait==0) begin sdram_write_en <= 0; bus_write_done <= 0; step <= 3; end end
		            3: begin sdram_addr <= bus_address[22:1]+3; sdram_wrdata <= bus_write_data[63:48]; sdram_write_en <= 1; sdram_byte_en <= 2'b11;
			       if (sdram_req_wait==0) begin sdram_write_en <= 0; bus_write_done <= 1; step <= 0; end end
			endcase
		    end
		 //000sb 001sh 010sw 011sd
	        endcase
	    end



    end
end

    // -- SD Card --
    //wire [11:0] cid = (bus_address-`Sdc_base);
    reg [11:0] cid;
    //reg [7:0] sd_cache [0:511];
    (* ram_style = "block" *) reg [7:0] sd_cache [0:511];
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

    // Debug LEDs
    assign HEX30 = ~Key_selected;
    assign HEX20 = ~|bus_read_data;
    assign HEX21 = ~bus_read_enable;
    assign HEX10 = ~|bus_write_data;
    assign HEX11 = ~bus_write_enable;
    assign HEX00 = ~Art_selected;
    assign HEX01 = ~Ram_selected;
    assign HEX02 = ~Rom_selected;
    //assign HEX03 = ~Sdram_selected ;
    assign HEX03 = (bus_address >= `Sdram_min && bus_address < `Sdram_max);

    assign HEX31 = ~Sdram_selected;
    //assign HEX32 = ~sdram_readdatavalid;
    //assign HEX33 = sdram_read_n;
    assign HEX33 = ~sdram_read_en;
    //assign HEX34 = sdram_write_n;
    assign HEX34 = ~sdram_write_en;
    //assign HEX35 = ~sdram_waitrequest;
    assign HEX35 = ~sdram_req_wait;
    //assign HEX36 = ~|sdram_readdata;
    assign HEX36 = ~|sdram_rddata;
    assign HEX04 = ~uart_irq;
    assign HEX05 = ~Plic_priority_selected;
    assign HEX06 = ~meip_interrupt;

endmodule
`include "header.vh"

module riscv64(
    input wire clk, 
    input wire reset,     // Active-low reset button
    input wire [31:0] instruction,
    output wire [63:0] ppc,
    output wire  heartbeat,
    output reg [63:0] bus_address,     // 39 bit for real Sv39 standard?
    output reg [63:0] bus_write_data,
    output reg        bus_write_enable,
    output reg        bus_read_enable,
    output reg [2:0]  bus_ls_type, // lb lh lw ld lbu lhu lwu // sb sh sw sd sbu shu swu 
      
    output reg [63:0] mtime,    // map to 0x0200_bff8 
    inout wire [63:0] mtimecmp, // map to 0x0200_4000 + 8byte*hartid

    input wire meip_interrupt, // from PLIC
    input wire msip_interrupt, // from Software
      
    input  reg        bus_read_done,
    input  reg        bus_write_done,
    input  wire [63:0] bus_read_data   // from outside
);

    (* keep = 1 *) reg [63:0] pc;
    wire [31:0] ir;
// -- new --
    reg [63:0] re [0:31]; // General Registers 32s
    reg [63:0] sre [0:9]; // Shadow Registers 10s
    reg mmu_da=0;
    reg mmu_pc = 0;
    reg mmu_cache_refill=0;
    reg [63:0] saved_user_pc;
    integer i; 

    //// MMU
    //function [31:0] get_shadow_ir; // 0-5 mmu 
    //    input [63:0] spc;
    //    begin
    //	case(spc) /// only x0-x9 could use, x9 is the value passer
    //        // I-TLB Handler
    //	    0: get_shadow_ir = 32'b00000000000000000010000010110111; // lui x1, 0x2     
    //	    4: get_shadow_ir = 32'b00000000010000001000000010010011; // addi x1, x1, 0x4 
    //	    8: get_shadow_ir = 32'b00000010101000000000000100010011; // addi x2, x0, 0x2a
    //	    12: get_shadow_ir = 32'b00000000001000001011000000100011; // sd x2, 0(x1)      print *
    //        16: get_shadow_ir = 32'b00100000000000000000010000110111; // 20000437 lui x8, 0x20000
    //        20: get_shadow_ir = 32'b00000000100101000010000000100011; // 00942023 sw x9, 0(x8)   
    //        24: get_shadow_ir = 32'b00110000001000000000000001110011; // 30200073 mret           
    //        // D-TLB Handler
    //	    100: get_shadow_ir = 32'b00000000000000000010000010110111; // lui x1, 0x2     
    //	    104: get_shadow_ir = 32'b00000000010000001000000010010011; // addi x1, x1, 0x4 
    //        108: get_shadow_ir = 32'b00000101111000000000000100010011; // addi x2, x0, 0x5e
    //        112: get_shadow_ir = 32'b00000000001000001011000000100011; // sd x2, 0(x1)      print ^
    //        116: get_shadow_ir = 32'b00100000000000000000010000110111; // 20000437 lui x8, 0x20000
    //        120: get_shadow_ir = 32'b00000000100101000010000000100011; // 00942023 sw x9, 0(x8)   
    //        124: get_shadow_ir = 32'b00110000001000000000000001110011; // 30200073 mret           
    //        //// I-CacheI Handler
    //	    //200: get_shadow_ir = 32'b00000000000000000010000010110111; // lui x1, 0x2     
    //	    //204: get_shadow_ir = 32'b00000000010000001000000010010011; // addi x1, x1, 0x4 
    //        //208: get_shadow_ir = 32'b00000111110000000000000100010011; // addi x2, x0, 0x7c
    //        //212: get_shadow_ir = 32'b00000000001000001011000000100011; // sd x2, 0(x1)      print |
    //        //216: get_shadow_ir = 32'b00100000000000000001010000110111; // 20001437 lui x8, 0x20001
    //        //220: get_shadow_ir = 32'b00000000000001001010001110000011; // 0004a383 lw x7, 0(x9)   
    //        //224: get_shadow_ir = 32'b00000000011101000010000000100011; // 00742023 sw x7, 0(x8)   
    //        //228: get_shadow_ir = 32'b00110000001000000000000001110011; // 30200073 mret           

    //	    default: get_shadow_ir = 32'h00000013; // NOP:addi x0, x0, 0
    //	endcase
    //    end
    //endfunction


    // --- Privilege Modes ---
    localparam M_mode = 2'b11;
    localparam S_mode = 2'b01;
    localparam U_mode = 2'b00;
    reg [1:0] current_privilege_mode;
    // -- newend --

    // -- Immediate decoders  -- 
    wire signed [63:0] w_imm_u = {{32{ir[31]}}, ir[31:12], 12'b0};  // U-type immediate Lui Auipc
    wire signed [63:0] w_imm_i = {{52{ir[31]}}, ir[31:20]};   // I-type immediate Lb Lh Lw Lbu Lhu Lwu Ld Jalr Addi Slti Sltiu Xori Ori Andi Addiw 
    wire signed [63:0] w_imm_s = {{52{ir[31]}}, ir[31:25], ir[11:7]};  // S-type immediate Sb Sh Sw Sd
    wire signed [63:0] w_imm_j = {{43{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0}; // UJ-type immediate Jal  // read immediate & padding last 0, total 20 + 1 = 21 bits
    wire signed [63:0] w_imm_b = {{51{ir[31]}}, ir[7],  ir[30:25], ir[11:8], 1'b0}; // B-type immediate Beq Bne Blt Bge Bltu Bgeu // read immediate & padding last 0, total 12 + 1 = 13 bits
    wire        [63:0] w_imm_z = {59'b0, ir[19:15]};  // CSR zimm zero-extending unsigned
    wire [5:0] w_shamt = ir[25:20]; // If 6 bits the highest is always 0??
    // -- Register decoder --
    wire [4:0] w_rd  = ir[11:7];
    wire [4:0] w_rs1 = ir[19:15];
    wire [4:0] w_rs2 = ir[24:20];
    // -- Func decoder --
    wire [2:0] w_func3   = ir[14:12];
    wire [4:0] w_func5   = ir[31:27];
    wire [6:0] w_func7   = ir[31:25]; 
    wire [11:0] w_func12 = ir[31:20]; 
    // -- rs1 rs2 value --
    wire [63:0] rs1 = re[w_rs1];
    wire [63:0] rs2 = re[w_rs2];
    // -- op --
    wire [6:0] op = ir[6:0];
    //wire [11:0] w_f12 = ir[31:20];   // ecall 0, ebreak 1
    //-- csr --
    wire [11:0] w_csr = ir[31:20];   // CSR official address

    // --Machine CSR --
   localparam mstatus    = 0 ; localparam MPRV=17,MPP=11,SPP=8,MPIE=7,SPIE=5,MIE=3,SIE=1,UIE=0;//63_SD|37_MBE|36_SBE|35:34_SXL10|22_TSR|21_TW|20_TVW|17_MPRV|12:11_MPP|8_SPP|7_MPIE|5_SPIE|3_MIE|1_SIE|0_UIE
   localparam mtvec      = 1 ; localparam BASE=2,MODE=0; // 63:2BASE|1:0MDOE  // 0x305 MRW Machine trap-handler base address * 0 direct 1vec
   localparam mscratch   = 2 ;  // 
   localparam mepc       = 3 ;  
   localparam mcause     = 4 ; localparam INTERRUPT=63,CAUSE=0; // 0x342 MRW Machine trap casue *  63InterruptAsync/ErrorSync|62:0CauseCode
   localparam mie        = 5 ; localparam SGEIE=12,MEIE=11,VSEIE=10,SEIE=9,MTIE=7,VSTIE=6,STIE=5,MSIE=3,VSSIE=2,SSIE=1; // Machine Interrupt Enable from OS software set enable
   localparam mip        = 6 ; localparam SGEIP=12,MEIP=11,VSEIP=10,SEIP=9,MTIP=7,VSTIP=6,STIP=5,MSIP=3,VSSIP=2,SSIP=1; // Machine Interrupt Pending from HardWare timer,uart,PLIC..11Exter 7Time 3Software
   localparam medeleg    = 7 ; localparam MECALL=11,SECALL=9,UECALL=8,BREAK=3; // bit_index=mcause_value 8UECALL|9SECALL
   localparam mideleg    = 8 ;  //
   localparam sstatus    = 9 ; localparam SD=63,UXL=32,MXR=19,SUM=18,XS=15,FS=13,VS=9,UBE=6; //SPP=8,SPIE=5,SIE=1,//63SD|33:32UXL|19MXR|18SUM|16:15XS|14:13FS|10:9VS|8SPP|6UBE|5SPIE|1SIE
   localparam sedeleg    = 10;  
   localparam sideleg    = 11;  
   localparam sie        = 12;  // Supervisor interrupt-enable register
   localparam stvec      = 13; //localparam ; //BASE=2,MODE=0 63:2BASE|1:0MDOE Supervisor trap handler base address
   localparam scounteren = 14;  
   localparam sscratch   = 15;  
   localparam sepc       = 16;  
   localparam scause     = 17; //localparam ; //INTERRUPT=63,CAUSE=0 *  63InterruptAsync/ErrorSync|62:0CauseCode// 
   localparam stval      = 18;  
   localparam sip        = 19;  // Supervisor interrupt pending
   localparam satp       = 20;  // Supervisor address translation and protection satp[63:60].MODE=0:off|8:SV39 satp[59:44].asid vpn2:9 vpn1:9 vpn0:9 satp[43:0]:rootpage physical addr
   localparam mtval      = 21;  // Machine Trap Value Register (bad address or instruction)
    //integer scontext = 12'h5a8; 
   reg [62:0] CAUSE_CODE;
   reg  [5:0] w_csr_id;             // CSR id (32)
    always @(*) begin
	case(w_csr)
            12'h300 : w_csr_id = mstatus    ;    
            12'h305 : w_csr_id = mtvec      ;    
            12'h340 : w_csr_id = mscratch   ;    
            12'h341 : w_csr_id = mepc       ;    
            12'h342 : w_csr_id = mcause     ;    
            12'h343 : w_csr_id = mtval      ;    
            12'h304 : w_csr_id = mie        ;    
            12'h344 : w_csr_id = mip        ;    
            12'h302 : w_csr_id = medeleg    ;    
            12'h303 : w_csr_id = mideleg    ;    
            12'h100 : w_csr_id = sstatus    ;    
            12'h102 : w_csr_id = sedeleg    ;   
            12'h103 : w_csr_id = sideleg    ;   
            12'h104 : w_csr_id = sie        ;   
            12'h105 : w_csr_id = stvec      ;   
            12'h106 : w_csr_id = scounteren ;   
            12'h140 : w_csr_id = sscratch   ;   
            12'h141 : w_csr_id = sepc       ;   
            12'h142 : w_csr_id = scause     ;   
            12'h143 : w_csr_id = stval      ;   
            12'h144 : w_csr_id = sip        ;   
            12'h180 : w_csr_id = satp       ;   
	    default : w_csr_id = 64; 
	endcase
    end

    reg [63:0] Csrs [0:31]; // 32 CSRs for now
    wire [3:0]  satp_mmu  = Csrs[satp][63:60]; // 0:bare, 8:sv39, 9:sv48  satp.MODE!=0, privilegae is not M-mode, mstatus.MPRN is not set or in MPP's mode?
    wire [15:0] satp_asid = Csrs[satp][59:44]; // Address Space ID for TLB
    wire [43:0] satp_ppn  = Csrs[satp][43:0];  // Root Page Table PPN physical page number

    // -- Timer --
    always @(posedge clk or negedge reset) begin 
	if (!reset) mtime <= 0;
	else mtime <= mtime + 1; end
    wire time_interrupt = (mtime >= mtimecmp);
      
    // -- Innerl signal --
    reg bubble;
    reg [1:0] load_step;
    reg [1:0] store_step;

    // -- Atomic & Sync state --
    reg [63:0] reserve_addr;
    reg        reserve_valid;

    // -- TLB -- 8 pages
    reg [26:0] tlb_vpn [0:7]; // vpn number VA[38:12]  Sv39
    reg [43:0] tlb_ppn [0:7]; // ppn number PA[55:12]
    reg tlb_vld [0:7];

    // i hit
    wire [26:0] pc_vpn = pc[38:12];
    reg [43:0] pc_ppn;
    reg tlb_i_hit;
    always @(*) begin
        tlb_i_hit = 0;
        pc_ppn = 0;
        if      (tlb_vld[0] && tlb_vpn[0] == pc_vpn) begin tlb_i_hit = 1; pc_ppn = tlb_ppn[0]; end
        else if (tlb_vld[1] && tlb_vpn[1] == pc_vpn) begin tlb_i_hit = 1; pc_ppn = tlb_ppn[1]; end
        else if (tlb_vld[2] && tlb_vpn[2] == pc_vpn) begin tlb_i_hit = 1; pc_ppn = tlb_ppn[2]; end
        else if (tlb_vld[3] && tlb_vpn[3] == pc_vpn) begin tlb_i_hit = 1; pc_ppn = tlb_ppn[3]; end
        else if (tlb_vld[4] && tlb_vpn[4] == pc_vpn) begin tlb_i_hit = 1; pc_ppn = tlb_ppn[4]; end
        else if (tlb_vld[5] && tlb_vpn[5] == pc_vpn) begin tlb_i_hit = 1; pc_ppn = tlb_ppn[5]; end
        else if (tlb_vld[6] && tlb_vpn[6] == pc_vpn) begin tlb_i_hit = 1; pc_ppn = tlb_ppn[6]; end
        else if (tlb_vld[7] && tlb_vpn[7] == pc_vpn) begin tlb_i_hit = 1; pc_ppn = tlb_ppn[7]; end
    end

    // d hit
    // -- directly 1:1 --
    //wire [63:0] ls_va = (op == 7'b0000011) ? (rs1 + w_imm_i) : (op == 7'b0100011) ? (rs1 + w_imm_s) : (op == 7'b0101111) ? rs1 : 0; // load/jalr/store/atom
    //wire [63:0] pda = ls_va;

    wire [63:0] ls_va = (op == 7'b0000011) ? (rs1 + w_imm_i) : (op == 7'b0100011) ? (rs1 + w_imm_s) : (op == 7'b0101111) ? rs1 : 64'h0; // load/jalr/store/atom
    wire [63:0] pda;

    //wire [26:0] data_vpn = ls_va[38:12];
    //reg [43:0] data_ppn;
    //reg tlb_d_hit;
    //always @(*) begin
    //     tlb_d_hit = 0;
    //     data_ppn = 0;
    //     if      (tlb_vld[0] && tlb_vpn[0] == data_vpn) begin tlb_d_hit = 1; data_ppn=tlb_ppn[0]; end
    //     else if (tlb_vld[1] && tlb_vpn[1] == data_vpn) begin tlb_d_hit = 1; data_ppn=tlb_ppn[1]; end
    //     else if (tlb_vld[2] && tlb_vpn[2] == data_vpn) begin tlb_d_hit = 1; data_ppn=tlb_ppn[2]; end
    //     else if (tlb_vld[3] && tlb_vpn[3] == data_vpn) begin tlb_d_hit = 1; data_ppn=tlb_ppn[3]; end
    //     else if (tlb_vld[4] && tlb_vpn[4] == data_vpn) begin tlb_d_hit = 1; data_ppn=tlb_ppn[4]; end
    //     else if (tlb_vld[5] && tlb_vpn[5] == data_vpn) begin tlb_d_hit = 1; data_ppn=tlb_ppn[5]; end
    //     else if (tlb_vld[6] && tlb_vpn[6] == data_vpn) begin tlb_d_hit = 1; data_ppn=tlb_ppn[6]; end
    //     else if (tlb_vld[7] && tlb_vpn[7] == data_vpn) begin tlb_d_hit = 1; data_ppn=tlb_ppn[7]; end
    // end
     // concat physical address
     wire need_trans = satp_mmu   && !mmu_pc && !mmu_da && !mmu_cache_refill;
     assign ppc = need_trans ? {8'h0, pc_ppn, pc[11:0]} : pc;
    //assign pda = need_trans ? {data_ppn, ls_va[11:0]} : ls_va;
       
     assign pda = need_trans ?  ls_va : ls_va;
     
    // TLB Refill
    reg [2:0] tlb_ptr = 0; // 8 entries TLB
    always @(posedge clk or negedge reset) begin
        if (!reset) tlb_ptr <= 0; // hit->trap(save va to x9)->refill assembly(fetch pa to x9)-> sd x9, `Tlb -> here to refill tlb
        else if ((mmu_pc || mmu_da) && bus_write_enable && bus_address == `Tlb) begin // for the last fill: sd ppa, Tlb
            tlb_vpn[tlb_ptr] <= re[9][38:12]; // VA from x9 saved by trapp mmu_pc/mmu_da
            tlb_ppn[tlb_ptr] <= {17'h0, re[9][38:12]}; // mimic copy now | real need walking assembly
            tlb_vld[tlb_ptr] <= 1;
            tlb_ptr <= tlb_ptr + 1; 
        end
    end

   // // IF Instruction (Only drive IR)
   // always @(posedge clk or negedge reset) begin
   //     if (!reset) begin 
   //         heartbeat <= 1'b0; 
   //         ir <= 32'h00000001; 
   //     end else begin
   //         heartbeat <= ~heartbeat; // heartbeat
   //         if (mmu_pc || mmu_da || mmu_cache_refill) ir <= get_shadow_ir(pc);  // Runing shadow code
   //         else ir <= instruction; // 
   //         //else if (cache_hit) ir <= cache_data; // Cache hit
   //         ////else ir <= instruction; // 
   //         //else ir <= 32'h00000013; // TLB miss or Cache miss: Nop(stall)
   //     end
   // end
    assign ir = instruction;
    //always @(*) begin
    //    if (!reset) begin 
    //        heartbeat = 1'b0; 
    //        ir = 32'h00000001; 
    //    end else begin
    //        ir = instruction;
    //    end
    //end

    // EXE Instruction 
    always @(posedge clk or negedge reset) begin
        if (!reset) begin 
	    current_privilege_mode <= M_mode;
	    bubble <= 1'b0;
	    pc <= `Ram_base;
	    load_step <= 0;
	    store_step <= 0;
	    bus_read_enable <= 0;
	    bus_write_enable <= 0;
	    bus_write_data <= 0;
	    bus_address <= `Ram_base;
            // Interrupt re-enable
	    Csrs[mstatus][MIE] <= 0;
	    //interrupt_ack <= 0;
	    mmu_da <= 0;
	    for (i=0;i<10;i=i+1) begin sre[i]<= 64'b0; end
	    for (i=0;i<32;i=i+1) begin Csrs[i]<= 64'b0; end
	    Csrs[medeleg] <= 64'hb1af; // delegate to S-mode 1011000110101111 // see VII 3.1.15 mcasue exceptions
	    Csrs[mideleg] <= 64'h0222; // delegate to S-mode 0000001000100010 see VII 3.1.15 mcasue interrupt 1/5/9 SSIP(supervisor software interrupt) STIP(time) SEIP(external)
	    mmu_pc <= 0;
            reserve_addr <= 0;
            reserve_valid <= 0;


        end else begin
            pc <= pc + 4; // Default PC+4    (1.Could be overide 2.Take effect next cycle) 
	    //interrupt_ack <= 0;
	    bus_read_enable <= 0;
	    bus_write_enable <= 0; 

            // Bubble
	    if (bubble) begin bubble <= 1'b0; // Flush this cycle & Clear bubble signal for the next cycle

	    //  mmu_pc  I-TLB miss Trap
	    end else if (satp_mmu && !mmu_pc && !mmu_da && !tlb_i_hit) begin //OPEN 
       		mmu_pc <= 1; // MMU_PC ON 
       	        pc <= 0; // I-TLB refill Handler
       	 	bubble <= 1'b1; // bubble 
	        saved_user_pc <= pc - 4; // !!! save pc (EXE was flushed so record-redo it, previous pc)
		for (i=0;i<=9;i=i+1) begin sre[i]<= re[i]; end // save re
		re[9] <= pc;// - 4; // save this vpc to x1 //!!!! We also need to refill pc - 4' ppc for re-executeing pc-4, with hit(if satp in for very next sfence.vma) 
		Csrs[mstatus][MPIE] <= Csrs[mstatus][MIE]; // disable interrupt during shadow mmu walking
		Csrs[mstatus][MIE] <= 0;
	    end else if (mmu_pc && ir == 32'b00110000001000000000000001110011) begin // end hiject mret & recover from shadow when see Mret
		pc <= saved_user_pc; // recover from shadow when see Mret
	 	bubble <= 1'b1; // bubble
		for (i=0;i<10;i=i+1) begin re[i]<= sre[i]; end // recover usr re
		mmu_pc <= 0; // MMU_PC OFF
		Csrs[mstatus][MIE] <= Csrs[mstatus][MPIE]; // set back interrupt status

        //    //  mmu_da  D-TLB miss Trap // load/store/atom
	//    end else if (satp_mmu && !mmu_pc && !mmu_da && tlb_i_hit && !tlb_d_hit && (op == 7'b0000011 || op == 7'b0100011 || op == 7'b0101111) ) begin  
	//	mmu_da <= 1; // MMU_DA ON
	//	pc <= 28; // D-TLB refill Handler
	// 	bubble <= 1'b1; // bubble
	//        saved_user_pc <= pc - 4; // save pc EXE l/s/a
	//	for (i=0;i<10;i=i+1) begin sre[i]<= re[i]; end // save re
	//	//re[9] <= ls_va; //save va to x1
	//	if (op == 7'b0000011) re[9] <= rs1 + w_imm_i;
	//	if (op == 7'b0100011) re[9] <= rs1 + w_imm_s;
	//	if (op == 7'b0101111) re[9] <= rs1;
	//	Csrs[mstatus][MPIE] <= Csrs[mstatus][MIE]; // disable interrupt during shadow mmu walking
	//	Csrs[mstatus][MIE] <= 0;
	//    end else if (mmu_da && ir == 32'b00110000001000000000000001110011) begin // hiject mret 
	//	pc <= saved_user_pc; // recover from shadow when see Mret
	//	bubble <= 1; // bubble
	//	for (i=0;i<10;i=i+1) begin re[i]<= sre[i]; end // recover usr re
	//	mmu_da <= 0; // MMU_DA OFF
	//	Csrs[mstatus][MIE] <= Csrs[mstatus][MPIE]; // set back interrupt status
		
            // Interrupt PLIC full (Platform-Level-Interrupt-Control)  MMIO
	    end else if ((meip_interrupt || msip_interrupt) && Csrs[mstatus][MIE]==1) begin //mstatus[3] MIE
                Csrs[mip][MTIP] <= time_interrupt; // MTIP linux will see then jump to its handler
                Csrs[mip][MEIP] <= meip_interrupt; // MEIP
                Csrs[mip][MSIP] <= msip_interrupt; // MSIP

		Csrs[mcause][INTERRUPT] <= 1; // MSB 1 for interrupts 0 for exceptions
                if (msip_interrupt) Csrs[mcause][CAUSE+62:CAUSE] <= 3; // Cause 3 for Sofeware Interrupt
                if (time_interrupt) Csrs[mcause][CAUSE+62:CAUSE] <= 7; // Cause 7 for Timer Interrupt
                if (meip_interrupt) Csrs[mcause][CAUSE+62:CAUSE] <= 11; // Cause 11 for External Interrupt

	        //Csrs[mepc] <= pc; // save next pc (interrupt asynchronize)
	        Csrs[mepc] <= pc-4; // save interruptec pc (interrupt asynchronize) ?? M-mode 3.1.15
		Csrs[mstatus][MPIE] <= Csrs[mstatus][MIE];
		Csrs[mstatus][MIE] <= 0;
		Csrs[mstatus][MPP+1:MPP] <= current_privilege_mode; // MPP = old mode
		if (Csrs[mtvec][MODE+1:MODE] == 1) begin // vec-mode 1
                    if (msip_interrupt) pc <= (Csrs[mtvec][BASE+61:BASE] << 2) + (MSIP << 2); // vectorily BASE & CAUSE_CODE are 4 bytes aligned already number need << 2
                    if (time_interrupt) pc <= (Csrs[mtvec][BASE+61:BASE] << 2) + (MTIP << 2);
                    if (meip_interrupt) pc <= (Csrs[mtvec][BASE+61:BASE] << 2) + (MEIP << 2); 
		end else pc <= (Csrs[mtvec][BASE+61:BASE] << 2);// jump to mtvec addrss (directly mode 0, need C or Assembly code of handlers deciding) 
		bubble <= 1'b1; // bubble wrong fetched instruciton by IF
		reserve_valid <= 0;// Interrupt clear lr.w/lr.d

	    // IR
	    end else begin 
                casez(ir)
	            // U-type
	            32'b???????_?????_?????_???_?????_0110111: re[w_rd] <= w_imm_u; // Lui
	            32'b???????_?????_?????_???_?????_0010111: re[w_rd] <= w_imm_u + (pc - 4); // Auipc
                    // Load after TLB
		    32'b???????_?????_?????_000_?????_0000011: begin  // Lb  3 cycles but wait to 5
			if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		        if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[7:0]); load_step <= 0; end end
		    32'b???????_?????_?????_100_?????_0000011: begin  // Lbu  3 cycles
		        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[7:0]); load_step <= 0; end end 
		    32'b???????_?????_?????_001_?????_0000011: begin  // Lh 3 cycles
		        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[15:0]); load_step <= 0; end end
		    32'b???????_?????_?????_101_?????_0000011: begin   // Lhu 3 cycles
		        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[15:0]); load_step <= 0; end end
		    32'b???????_?????_?????_010_?????_0000011: begin  // Lw_mmu 3 cycles
		        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0; end end
		    32'b???????_?????_?????_110_?????_0000011: begin  // Lwu_mmu 3 cycles
		        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[31:0]); load_step <= 0; end end
		    32'b???????_?????_?????_011_?????_0000011: begin   // Ld 5 cycles
		        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0; end end
		    // Store after TLB
	            32'b???????_?????_?????_000_?????_0100011: begin 
		        if (store_step == 0) begin bus_address <= pda; bus_write_data<=rs2[7:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
			if (store_step == 1 && bus_write_done == 1) store_step <= 0; end // Sb
	            32'b???????_?????_?????_001_?????_0100011: begin
		        if (store_step == 0) begin bus_address <= pda; bus_write_data<=rs2[15:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
			if (store_step == 1 && bus_write_done == 1) store_step <= 0; end //Sh
	            32'b???????_?????_?????_010_?????_0100011: begin
		        if (store_step == 0) begin bus_address <= pda; bus_write_data<=rs2[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
			if (store_step == 1 && bus_write_done == 1) store_step <= 0; end //Sw
	            32'b???????_?????_?????_011_?????_0100011: begin 
		        if (store_step == 0) begin bus_address <= pda; bus_write_data<=rs2;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
			if (store_step == 1 && bus_write_done == 1) store_step <= 0; end //Sd
                    // Math-I
	            32'b???????_?????_?????_000_?????_0010011: re[w_rd] <= rs1 + w_imm_i;  // Addi
	            32'b???????_?????_?????_100_?????_0010011: re[w_rd] <= rs1 ^ w_imm_i ; // Xori
	            32'b???????_?????_?????_111_?????_0010011: re[w_rd] <= rs1 & w_imm_i ; // Andi
	            32'b???????_?????_?????_110_?????_0010011: re[w_rd] <= rs1 | w_imm_i ; // Ori
	            32'b???????_?????_?????_001_?????_0010011: re[w_rd] <= rs1 << w_shamt; // Slli
	            32'b000000?_?????_?????_101_?????_0010011: re[w_rd] <= rs1 >> w_shamt; // Srli // func7->6 // rv64 shame take w_f7[0]
	            32'b010000?_?????_?????_101_?????_0010011: re[w_rd] <= $signed(rs1) >>> w_shamt; // Srai
	            32'b???????_?????_?????_010_?????_0010011: re[w_rd] <= $signed(rs1) < w_imm_i ? 1:0; // Slti
	            32'b???????_?????_?????_011_?????_0010011: re[w_rd] <= (rs1 < w_imm_i) ?  1:0; // Sltiu
                    // Math-I (Word)
	            32'b???????_?????_?????_000_?????_0011011: re[w_rd] <= $signed(rs1[31:0] + w_imm_i[31:0]); // Addiw
	            32'b???????_?????_?????_001_?????_0011011: re[w_rd] <= $signed(rs1[31:0] << w_shamt[4:0]); // Slliw
	            32'b0000000_?????_?????_101_?????_0011011: re[w_rd] <= $signed(rs1[31:0] >> w_shamt[4:0]); // Srliw
	            32'b0100000_?????_?????_101_?????_0011011: re[w_rd] <= $signed(rs1[31:0]) >>> w_shamt[4:0]; // Sraiw
                    //// Math-R
	            32'b0000000_?????_?????_000_?????_0110011: re[w_rd] <= rs1 + rs2;  // Add
	            32'b0100000_?????_?????_000_?????_0110011: re[w_rd] <= rs1 - rs2;  // Sub;
	            32'b???????_?????_?????_100_?????_0110011: re[w_rd] <= rs1 ^ rs2; // Xor
	            32'b???????_?????_?????_111_?????_0110011: re[w_rd] <= rs1 & rs2; // And
	            32'b???????_?????_?????_110_?????_0110011: re[w_rd] <= rs1 | rs2; // Or
	            32'b???????_?????_?????_001_?????_0110011: re[w_rd] <= rs1 << rs2[5:0]; // Sll 6 length
                    32'b0000000_?????_?????_101_?????_0110011: re[w_rd] <= rs1 >> rs2[5:0]; // Srl 6 length
	            32'b0100000_?????_?????_101_?????_0110011: re[w_rd] <= $signed(rs1) >>> rs2[5:0]; // Sra 6 length
	            32'b???????_?????_?????_010_?????_0110011: re[w_rd] <= ($signed(rs1) < $signed(rs2)) ? 1: 0;  // Slt
	            32'b???????_?????_?????_011_?????_0110011: re[w_rd] <= rs1 < rs2 ? 1:0; // Sltu
                    //// Math-R (Word)
	            32'b0000000_?????_?????_000_?????_0111011: re[w_rd] <= $signed(rs1[31:0] + rs2[31:0]);  // Addw
	            32'b0100000_?????_?????_000_?????_0111011: re[w_rd] <= $signed(rs1[31:0] - rs2[31:0]);  // Subw
	            32'b???????_?????_?????_001_?????_0111011: re[w_rd] <= $signed(rs1[31:0] << rs2[4:0]);  // Sllw 5 length
                    32'b0000000_?????_?????_101_?????_0111011: re[w_rd] <= $signed(rs1[31:0] >> rs2[4:0]);  // Srlw 5 length
	            32'b0100000_?????_?????_101_?????_0111011: re[w_rd] <= $signed(rs1[31:0]) >>> rs2[4:0]; // Sraw 5 length
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
		    // System-CSR 
	            32'b???????_?????_?????_001_?????_1110011: begin if (w_rd != 0) re[w_rd] <= Csrs[w_csr_id]; Csrs[w_csr_id] <= rs1; end // Csrrw  bram read first old data
	            32'b???????_?????_?????_010_?????_1110011: begin if (w_rd != 0) re[w_rd] <= Csrs[w_csr_id]; if (w_rs1 != 0) Csrs[w_csr_id] <= (Csrs[w_csr_id] |  rs1); end // Csrrs
	            32'b???????_?????_?????_011_?????_1110011: begin if (w_rd != 0) re[w_rd] <= Csrs[w_csr_id]; if (w_rs1 != 0) Csrs[w_csr_id] <= (Csrs[w_csr_id] & ~rs1); end // Csrrc
	            32'b???????_?????_?????_101_?????_1110011: begin if (w_rd != 0) re[w_rd] <= Csrs[w_csr_id]; Csrs[w_csr_id] <= w_imm_z; end // Csrrwi
	            32'b???????_?????_?????_110_?????_1110011: begin if (w_rd != 0) re[w_rd] <= Csrs[w_csr_id]; if (w_imm_z != 0) Csrs[w_csr_id] <= (Csrs[w_csr_id] |  w_imm_z); end // csrrsi
	            32'b???????_?????_?????_111_?????_1110011: begin if (w_rd != 0) re[w_rd] <= Csrs[w_csr_id]; if (w_imm_z != 0) Csrs[w_csr_id] <= (Csrs[w_csr_id] & ~w_imm_z); end // Csrrci
                    // Ecall
	            32'b0000000_00000_?????_000_?????_1110011: begin 
	                                                if      (current_privilege_mode == U_mode) CAUSE_CODE = UECALL; // 8 indicate Ecall from U-mode; 9 call from S-mode; 11 call from M-mode
	                                                else if (current_privilege_mode == S_mode) CAUSE_CODE = SECALL; // block assign attaintion!
	                                                else if (current_privilege_mode == M_mode) CAUSE_CODE = MECALL;
						        if (Csrs[medeleg][CAUSE_CODE] == 1) // UECALL8 SECALL9 MECALL11 delegate to S-mode
	                 			        begin // Trap into S-mode
	                 			           Csrs[scause][INTERRUPT] <= 0; //63_type 0exception 1interrupt|value
	                 			           Csrs[scause][CAUSE+62:CAUSE] <= CAUSE_CODE; // 8 indicate Ecall from U-mode; 9 call from S-mode; 11 call from M-mode
	                 			           Csrs[sepc] <= pc - 4;  // Ecall is sycronized, back and repeat pc
							   Csrs[stval] <= 0; // mandatory
	                 			           Csrs[sstatus][SPP] <= (current_privilege_mode == U_mode ? 0 : 1); // save previous privilege mode(user0 super1) to SPP 
	                 			           Csrs[sstatus][SPIE] <= Csrs[sstatus][SIE]; // save interrupt enable(SIE) to SPIE 
	                 			           Csrs[sstatus][SIE] <= 0; // clear SIE
							   if (Csrs[stvec][MODE+1:MODE] == 0) pc <= (Csrs[stvec][BASE+61:BASE] << 2); // directly  
							   else  pc <= (Csrs[stvec][BASE+61:BASE] << 2) + (CAUSE_CODE << 2); // vectorily BASE & CAUSE_CODE are 4 bytes aligned already number need << 2
	                 				   current_privilege_mode <= S_mode;
		    				           bubble <= 1'b1;
	                 			       end
	                 			       else begin // Trap into M-mode
	                 			           Csrs[mcause][INTERRUPT] <= 0; //63_type 0exception 1interrupt|value
	                 			           Csrs[mcause][CAUSE+62:CAUSE] <= CAUSE_CODE; // 8 indicate Ecall from U-mode; 9 call from S-mode; 11 call from M-mode
	                 			           Csrs[mepc] <= pc - 4; 
							   Csrs[mtval] <= 0;
	                 			           Csrs[mstatus][MPIE] <= Csrs[mstatus][MIE]; // save interrupt enable(MIE) to MPIE 
	                 			           Csrs[mstatus][MIE] <= 0; // clear MIE (not enabled, blocked when trap)
							   if (Csrs[mtvec][MODE+1:MODE] == 0) pc <= (Csrs[mtvec][BASE+61:BASE] << 2); // directly
							   else  pc <= (Csrs[mtvec][BASE+61:BASE] << 2) + (CAUSE_CODE << 2); // vectorily
	                 				   Csrs[mstatus][MPP+1:MPP] <= current_privilege_mode; // save privilege mode to MPP 
	                 				   current_privilege_mode <= M_mode;  // set current privilege mode
		    				           bubble <= 1'b1;
	                 			       end
	                 			   end
                    // Ebreak
	            32'b0000000_00001_?????_000_?????_1110011: begin 
	                                                //CAUSE_CODE <= 3; // Breakpoint is 3
						        if (Csrs[medeleg][BREAK] == 1) // BREAK3 UECALL8 SECALL9 MECALL11 delegate to S-mode
	                 			        begin // Trap into S-mode
	                 			           Csrs[scause][INTERRUPT] <= 0; //63_type 0exception 1interrupt|value
	                 			           Csrs[scause][CAUSE+62:CAUSE] <= BREAK; // 8 indicate Ecall from U-mode; 9 call from S-mode; 11 call from M-mode
	                 			           Csrs[sepc] <= pc - 4;  // Ecall is sycronized, back and repeat pc
							   Csrs[stval] <= 0; // mandatory
	                 			           Csrs[sstatus][SPP] <= (current_privilege_mode == U_mode ? 0 : 1); // save previous privilege mode(user0 super1) to SPP 
	                 			           Csrs[sstatus][SPIE] <= Csrs[sstatus][SIE]; // save interrupt enable(SIE) to SPIE 
	                 			           Csrs[sstatus][SIE] <= 0; // clear SIE
							   if (Csrs[stvec][MODE+1:MODE] == 0) pc <= (Csrs[stvec][BASE+61:BASE] << 2); // directly  
							   else  pc <= (Csrs[stvec][BASE+61:BASE] << 2) + (BREAK << 2); // vectorily BASE & CAUSE_CODE are 4 bytes aligned already number need << 2
	                 				   current_privilege_mode <= S_mode;
		    				           bubble <= 1'b1;
	                 			       end
	                 			       else begin // Trap into M-mode
	                 			           Csrs[mcause][INTERRUPT] <= 0; //63_type 0exception 1interrupt|value
	                 			           Csrs[mcause][CAUSE+62:CAUSE] <= BREAK; // 8 indicate Ecall from U-mode; 9 call from S-mode; 11 call from M-mode
	                 			           Csrs[mepc] <= pc - 4; 
							   Csrs[mtval] <= 0;
	                 			           Csrs[mstatus][MPIE] <= Csrs[mstatus][MIE]; // save interrupt enable(MIE) to MPIE 
	                 			           Csrs[mstatus][MIE] <= 0; // clear MIE (not enabled, blocked when trap)
							   if (Csrs[mtvec][MODE+1:MODE] == 0) pc <= (Csrs[mtvec][BASE+61:BASE] << 2); // directly
							   else  pc <= (Csrs[mtvec][BASE+61:BASE] << 2) + (BREAK << 2); // vectorily
	                 				   Csrs[mstatus][MPP+1:MPP] <= current_privilege_mode; // save privilege mode to MPP 
	                 				   current_privilege_mode <= M_mode;  // set current privilege mode
		    				           bubble <= 1'b1;
	                 			       end
	                 			   end
                    // Mret
	            32'b0011000_00010_?????_000_?????_1110011: begin  
	               			       Csrs[mstatus][MIE] <= Csrs[mstatus][MPIE]; // set back interrupt enable(MIE) by MPIE 
	               			       Csrs[mstatus][MPIE] <= 1; // set previous interrupt enable(MIE) to be 1 (enable)
	               			       if (Csrs[mstatus][MPP+1:MPP] < M_mode) Csrs[mstatus][MPRV] <= 0; // set mprv to 0, modified privilege, 1 using in MPP not current
	               			       current_privilege_mode  <= Csrs[mstatus][MPP+1:MPP]; // set back previous mode
	               			       Csrs[mstatus][MPP+1:MPP] <= 2'b00; // set previous privilege mode(MPP) to be 00 (U-mode)
	               			       pc <=  Csrs[mepc]; // mepc was +4 by the software handler and written back to sepc
		          		       bubble <= 1'b1;
	               			       end
                    // Sret
	            32'b0001000_00010_?????_000_?????_1110011: begin      
	               			       Csrs[sstatus][SIE] <= Csrs[sstatus][SPIE]; // restore interrupt enable(SIE) by SPIE 
	               			       Csrs[sstatus][SPIE] <= 1; // next trap will have SPIE=1
	               			       if (Csrs[sstatus][SPP] == 0) current_privilege_mode <= U_mode;
					       else current_privilege_mode  <= S_mode;
	               			       Csrs[sstatus][SPP] <= 0; // set previous privilege mode(SPP) to be 0 (U-mode)
	               			       pc <=  Csrs[sepc]; // sepc was +4 by the software handler and written back to sepc
		          		       bubble <= 1'b1;
	               			       end 
		//    // Wfi
		//    32'b00010000010100000000000001110011: begin end
		//    // Fence
		//    32'b?????????????????_000_?????_0001111: begin end
		//    // Fence.i
		//    32'b?????????????????_001_?????_0001111: begin end
		//    // Sfence.vma
		//    32'b0001001??????????_000_?????_1110011: begin end
		//    // RV64IMAFD(G)C  RVA23U64
		//    // Atomic after TLB // -- ATOMIC instructions (A-extension) opcode: 0101111
		//    // lr.w
		//    32'b00010_??_?????_?????_010_?????_0101111: begin  // Lr.w_mmu 3 cycles
		//        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; reserve_addr <= pda; reserve_valid <= 1; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0; end end
		//    // sc.w 
	        //    32'b00011_??_?????_?????_010_?????_0101111: begin
		//        if (store_step == 0) begin 
		//	    if (!reserve_valid || reserve_addr != pda) begin re[w_rd] <= 1; reserve_valid <= 0; end // finish failed 1 in rd cycle without bubble & clear reserve
		//	    else begin bus_address <= pda; bus_write_data<=rs2[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3;reserve_valid<=0;end end//consumed
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; re[w_rd] <= 0; end end // sc.w successed return 0 in rd
		//    // amoswap.w
	        //    32'b00001_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=rs2[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amoadd.w
	        //    32'b00000_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=$signed(bus_read_data[31:0])+$signed(rs2[31:0]);bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amoxor.w
	        //    32'b00100_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data[31:0]^rs2[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amoand.w
	        //    32'b01100_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data[31:0]&rs2[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amoor.w
	        //    32'b01000_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data[31:0]|rs2[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amomin.w
	        //    32'b10000_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //start store
		//	    if ($signed(rs2[31:0]) < $signed(bus_read_data[31:0])) bus_write_data <= rs2[31:0]; end
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amomax.w
	        //    32'b10100_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //start store
		//	    if ($signed(rs2[31:0]) > $signed(bus_read_data[31:0])) bus_write_data <= rs2[31:0]; end
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amominu.w
	        //    32'b11000_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data[31:0]; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //start store
		//	    if (rs2[31:0] < bus_read_data[31:0]) bus_write_data <= rs2[31:0]; end
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amomaxu.w
	        //    32'b11100_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data[31:0]; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //start store
		//	    if (rs2[31:0] > bus_read_data[31:0]) bus_write_data <= rs2[31:0]; end
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //

		//    // lr.d
		//    32'b00010_??_?????_?????_011_?????_0101111: begin  // Lr.w_mmu 3 cycles
		//        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; reserve_addr <= pda; reserve_valid <= 1; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0; end end
		//    // sc.d 
	        //    32'b00011_??_?????_?????_011_?????_0101111: begin
		//        if (store_step == 0) begin 
		//	    if (!reserve_valid || reserve_addr != pda) begin re[w_rd] <= 1; reserve_valid <= 0; end // finish failed 1 in rd cycle without bubble & clear reserve
		//	    else begin bus_address <= pda; bus_write_data<=rs2;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3;reserve_valid<=0;end end//consumed
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; re[w_rd] <= 0; end end // sc.w successed return 0 in rd
		//    // amoswap.d
	        //    32'b00001_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<=bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=rs2;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amoadd.d
	        //    32'b00000_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data+rs2;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amoxor.d
	        //    32'b00100_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data^rs2;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amoand.d
	        //    32'b01100_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<=bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data&rs2;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amoor.d
	        //    32'b01000_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<=bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data|rs2;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amomin.d
	        //    32'b10000_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //start store
		//	    if ($signed(rs2) < $signed(bus_read_data)) bus_write_data <= rs2; end
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amomax.d
	        //    32'b10100_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //start store
		//	    if ($signed(rs2) > $signed(bus_read_data)) bus_write_data <= rs2; end
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amominu.d
	        //    32'b11000_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //start store
		//	    if (rs2 < bus_read_data) bus_write_data <= rs2; end
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amomaxu.d
	        //    32'b11100_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //start store
		//	    if (rs2 > bus_read_data) bus_write_data <= rs2; end
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		     // -- ATOMIC end --
                     // M extension // M mul mulh mulhsu mulhu div divu rem remu mulw divw divuw remuw
		     // 32'b0000001_?????_?????_000_?????_0110011: re[w_rd] <= $signed(rs1) * $signed(rs2);  // Mul
                     // 32'b0000001_?????_?????_001_?????_0110011: re[w_rd] <= ($signed(rs1) * $signed(rs2))>>>64;//[127:64];  // Mulh 
                     // 32'b0000001_?????_?????_100_?????_0110011: re[w_rd] <= (rs2==0||(rs1==64'h8000_0000_0000_0000 && rs2 == -1)) ? -1 : $signed(rs1) / $signed(rs2);  // Div
                     // 32'b0000001_?????_?????_101_?????_0110011: re[w_rd] <= (rs2==0) ? -1 : $unsigned(rs1) / $unsigned(rs2);  // Divu
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
	re[0]<=0; 
	sre[0]<=0;
    end

endmodule

// Linux needs:
// Privilege RV
// mret/sret/ecall/ebreak
//PLIC
//CLINT timer
//UART 16550
//Map DRAM 0x80000000/0x40000000
//OpenSBI at 0x80000000 ?
//lr.w|d/sc.w|d Atom amo...
//sfence.vma TLE flush could be NOP
//sv39 mmu ! Accessed/Direct bit in PTE(Page Table Entry)
//exception handler: page faults/illegal ir/misaligned ls/timer interrutp/external interrupt/breakpoint/ecallUSM
//SBI interface: OpenSBI run first
//fence fence.i
//cache !  // SDRAM to cache(BRAM)
// Device Tree
  
`define Rom_base   64'h0000_0000
`define Rom_size   64'h0000_1000
`define Ram_base   64'h0000_1000
`define Ram_size   64'h0000_1000
`define Key_base   64'h0000_2000
`define Art_base   64'h0000_2004
`define ArtC_base  64'h0000_2008

`define Sdc_base   64'h0000_3000
`define Sdc_addr   64'h0000_3200
`define Sdc_read   64'h0000_3204
`define Sdc_write  64'h0000_3208
`define Sdc_ncd    64'h0000_3212
`define Sdc_wp     64'h0000_3216
`define Sdc_ready  64'h0000_3220
`define Sdc_dirty  64'h0000_3224
`define Sdc_avail  64'h0000_3228

`define Sdram_min  64'h1000_0000
`define Sdram_max  64'h1080_0000

`define Mtime      64'h0200_bff8
`define Mtimecmp   64'h0200_4000

`define Plic_base         64'h0C00_0000  
`define Plic_pending      64'h0C00_1000  
`define Plic_enable       64'h0C00_2000  
`define Plic_threshold    64'h0C20_0000  
`define Plic_claim        64'h0C20_0004  
`define HARTS 1

`define Tlb    64'h2000_0000
`define CacheI 64'h2000_1000



//# Minimal SDRAM test
//.section .text
//.globl _start
//
//_start:
//    lui t0, 0x2
//    addi t0, t0, 4       # UART = 0x2004
//    
//    lui s0, 0x10000      # SDRAM = 0x10000000
//    
//    # Write one byte
//    li t1, 0x58          # 'X'
//    sb t1, 0(s0)         # test sdram sb/sh
//    
//    # Read it back
//    lbu t2, 0(s0)         # test sdram lbu
//    
//    # Print it
//    sb t2, 0(t0)         # Should print 'X'
//    sb t2, 0(t0)         # Should print 'X'
//    sh t2, 0(t0)         # Should print 'X'
//    
//    # Write 4 byte
//    li t1, 0x44434241    # 'DCBA'
//    sw t1, 0(s0)         # test sdram sw
//    
//    # Read it back
//    lhu t3, 0(s0) # A    # test sdram lhu lwu
//    lbu t4, 1(s0) # B
//    lwu t5, 2(s0) # C
//    lbu t6, 3(s0) # D
//    
//    # Print it
//    sb t3, 0(t0)         # Should print 'A'
//    sb t4, 0(t0)         # Should print 'B'
//    sb t5, 0(t0)         # Should print 'C'
//    sb t6, 0(t0)         # Should print 'D'
//    sb t2, 0(t0)         # Should print 'X'
//
//    # MMU enabled
//    li a1, 8              
//    slli a1, a1, 60          # mmu mode sv39 #li a1, 0x8000000000000000 # mmu mode sv39
//    csrrw a3, satp, a1      # set satp csr index 0x180
//
//
//    # Write 8 byte
//    li t1, 0x4847464544434241         # 'HGFEDCBA'
//    sd t1, 0(s0)         # test sdram sd
//
//    # Read it back
//    lbu a0, 0(s0) # A
//    lbu a1, 1(s0) # B
//    lbu a2, 2(s0) # C
//    lbu a3, 3(s0) # D
//    lbu a4, 4(s0) # E
//    lbu a5, 5(s0) # F
//    lbu a6, 6(s0) # G
//    lbu a7, 7(s0) # H
//
//    # Print it
//    sb a0, 0(t0)         # Should print 'A'
//    sb a1, 0(t0)         # Should print 'B'
//    sb a2, 0(t0)         # Should print 'C'
//    sb a3, 0(t0)         # Should print 'D'
//    sb a4, 0(t0)         # Should print 'E'
//    sb a5, 0(t0)         # Should print 'F'
//    sb a6, 0(t0)         # Should print 'G'
//    sb a7, 0(t0)         # Should print 'H'
//    sb t2, 0(t0)         # Should print 'X'
//
//#wait_loop:
//#    j wait_loop
//#
//
//    # Write 8 byte
//    li t1, 0x4847464544434241         # 'HGFEDCBA'
//    sd t1, 0(s0)         
//
//    # Read it back       # test sdram ld
//    ld a0, 0(s0)
//
//
//    sb a0, 0(t0)         # Should print 'A'
//    srli a0, a0, 8
//    sb a0, 0(t0)         # Should print 'B'
//    srli a0, a0, 8
//    sb a0, 0(t0)         # Should print 'C'
//    srli a0, a0, 8
//    sb a0, 0(t0)         # Should print 'D'
//    srli a0, a0, 8
//    sb a0, 0(t0)         # Should print 'E'
//    srli a0, a0, 8
//    sb a0, 0(t0)         # Should print 'F'
//    srli a0, a0, 8
//    sb a0, 0(t0)         # Should print 'G'
//    srli a0, a0, 8
//    sb a0, 0(t0)         # Should print 'H'
//    sb t2, 0(t0)         # Should print 'X'
//
//    # Write one byte
//    li t1, 0x41          # 'A'
//    sb t1, 0(s0)         # test sdarm sb
//    li t1, 0x42          # 'B'
//    sb t1, 1(s0)         # test sdarm sb+1
//
//    # Read it back       
//    lb a0, 0(s0)         # test sdram ld
//    sb a0, 0(t0)         # Should print 'A'
//
//
//    ## MMU enabled
//    #li a1, 8              
//    #slli a1, a1, 60          # mmu mode sv39 #li a1, 0x8000000000000000 # mmu mode sv39
//    #csrrw a3, satp, a1      # set satp csr index 0x180
//
//
//    lb a0, 1(s0)         # test sdram ld+1
//    sb a0, 0(t0)         # Should print 'B'
//    
//    ## MMU un-enabled
//    #li a1, 0              
//    #slli a1, a1, 60          # mmu mode sv39 #li a1, 0x8000000000000000 # mmu mode sv39
//    #csrrw a3, satp, a1      # set satp csr index 0x180
//
//    li t3, 124 # |
//    sb t3, 0(t0) # to plic
//
//    # -----PLIC TEST---
//    li t0, 0x2004 # UART data
//
//    # Enable UART read from terminal as irq
//    li t1, 1
//    sw t1, 4(t0) # write 1 to 0x2008 UART control means readable
//
//    li t3, 48 # 0
//    sb t3, 0(t0)
//
//    # Set handler
//    la t2, irq_handler
//    csrw mtvec, t2
//
//    li t3, 49 # 1
//    sb t3, 0(t0)
//
//    # PLIC setting
//    # Set priority[1] = 1 # [1] is UART
//    li t2, 0x0C000004 # `define Plic_base 32'h0C00_0000  # PRIORITY(id) = base + 4 * id
//    li t3, 1
//    sw t3, 0(t2)
//   
//    li t3, 50 # 2
//    sb t3, 0(t0)
//
//    # Set enable bits = irq_id, so enable bit = (1 << id) ctx 0
//    li t2, 0x0C002000
//    li t1, 2 #( 1<<1 = 2)
//    sw t1, 0(t2)
//
//    li t3, 51 # 3
//    sb t3, 0(t0)
//
//    ## Set enable bits = irq_id, so enable bit = (1 << id) ctx 1
//    #li t2, 0x0C002080
//    #li t1, 2 #( 1<<1 = 2)
//    #sw t1, 0(t2)
//
//    #li t3, 51 # 3
//    #sb t3, 0(t0)
//
//    # Set shreshold 0
//    li t2, 0x0C200000  # base +0x200000+hard_id<<12
//    li t1, 0 
//    sw t1, 0(t2)
//
//    li t3, 52 # 4
//    sb t3, 0(t0)
//  
//    # Set shreshold 1
//    li t2, 0x0C201000  # base +0x200000+hard_id<<12
//    li t1, 0 
//    sw t1, 0(t2)
//
//    li t3, 53 # 5
//    sb t3, 0(t0)
//
//    # Enable MEIE (mie.MEIE enternal interrupt)
//    li t2, 0x800 # bit 11=MEIE
//    csrs mie, t2
//
//    li t3, 54 # 6
//    sb t3, 0(t0)
//
//    # Enalbe MIE
//    li t2, 8  # (bit 3 mstatus.MIE)
//    csrs mstatus, t2
//
//    li t3, 55 # 7
//    sb t3, 0(t0) # to plic
//
//wait_loop:
//    j wait_loop
//
//irq_handler:
//   li t0, 0x2004 # UART data for print/read
//   li t2, 0x0C200004  # PLIC Claim context 0 register
//
//   li t3, 124 # |
//   sb t3, 0(t0) # print |
//
//   # Read claim
//   lw t1, 0(t2)
//   mv t5, t1
//
//   beqz t1, exit_irq
//
//   addi t4, t1, 48 
//   sb t4, 0(t0) # show interrupt id
//   li t3, 46 # .
//   sb t3, 0(t0) 
//
//   # Handle
//   lw t3, 0(t0) # read from UART FIFO
//   sw t3, 0(t0) # print key value
//
//   sw t5, 0(t2) # write id back to ctx0claim to clear pending id
//   li t3, 47 # /
//   sb t3, 0(t0) #  finished
//
//exit_irq:
//   li t3, 69 # E
//   sb t3, 0(t0) #  Exit irq
//   mret 
