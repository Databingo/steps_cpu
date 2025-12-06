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

//// -- sdram end--
//sdram sdram_instance (
//        .clk_clk                                 (CLOCK_50),  
//        .reset_reset_n                           (KEY0),                //                       reset.reset_n
//	// to bus
//        .new_sdram_controller_0_s1_address       (sdram_address),       //   new_sdram_controller_0_s1.address
//        .new_sdram_controller_0_s1_byteenable_n  (sdram_byteenable_n),  //                            .byteenable_n
//        .new_sdram_controller_0_s1_chipselect    (sdram_chipselect),    //                            .chipselect
//        .new_sdram_controller_0_s1_writedata     (sdram_writedata),     //                            .writedata
//        .new_sdram_controller_0_s1_read_n        (sdram_read_n),        //                            .read_n
//        .new_sdram_controller_0_s1_write_n       (sdram_write_n),       //                            .write_n
//        .new_sdram_controller_0_s1_readdata      (sdram_readdata),      //                            .readdata
//        .new_sdram_controller_0_s1_readdatavalid (sdram_readdatavalid), //                            .readdatavalid
//        .new_sdram_controller_0_s1_waitrequest   (sdram_waitrequest),   //                            .waitrequest
//        // to pin
//        .new_sdram_controller_0_wire_addr        (DRAM_ADDR),        // new_sdram_controller_0_wire.addr
//        .new_sdram_controller_0_wire_ba          (DRAM_BA),          //                            .ba
//        .new_sdram_controller_0_wire_cas_n       (DRAM_CAS_N),       //                            .cas_n
//        .new_sdram_controller_0_wire_cke         (DRAM_CKE),         //                            .cke
//        .new_sdram_controller_0_wire_cs_n        (DRAM_CS_N),        //                            .cs_n
//        .new_sdram_controller_0_wire_dq          (DRAM_DQ),          //                            .dq
//        .new_sdram_controller_0_wire_dqm         (DRAM_DQM),         //                            .dqm
//        .new_sdram_controller_0_wire_ras_n       (DRAM_RAS_N),       //                            .ras_n
//        .new_sdram_controller_0_wire_we_n        (DRAM_WE_N)         //                            .we_n
//    );
//wire [21:0] sdram_address = bus_address - `Sdram_min;
//wire sdram_chipselect = Sdram_selected && (bus_read_enable || bus_write_enable || !bus_read_done || !bus_write_done);
//wire sdram_read_n  = ~(Sdram_selected && bus_read_enable); 
//wire sdram_write_n = ~(Sdram_selected && bus_write_enable);   
//wire [15:0] sdram_writedata = bus_write_data[15:0]; 
//wire [1:0] sdram_byteenable_n = 2'b00; // Enable all bytes (active low)
//wire [15:0] sdram_readdata;   
//wire sdram_readdatavalid;
//wire sdram_waitrequest;
//
//wire sys_clk;
//wire sdram_clk;
//
//    //// -- sdram pll --
//    //sdram_pll sdrampll (
//    //    .clk_clk                        (CLOCK_50),               //                     clk.clk
//    //    .reset_reset_n                  (KEY0),                   //                   reset.reset_n
//    //    .altpll_0_c0_clk                (sys_clk),                //             altpll_0_c0.clk
//    //    .altpll_0_c1_clk                (sdram_clk),              //             altpll_0_c1.clk
//    //    .altpll_0_areset_conduit_export (), // altpll_0_areset_conduit.export
//    //    .altpll_0_locked_conduit_export ()  // altpll_0_locked_conduit.export
//    //);
//
//
//  // -- up pll --
//    upclk u0 (
//        .clk_clk                   (CLOCK_50),                   //                   clk.clk
//        .reset_reset_n             (KEY0),             //                 reset.reset_n
//        .up_clocks_0_sdram_clk_clk (sdram_clk), // up_clocks_0_sdram_clk.clk
//        .up_clocks_0_CLOCK_50_clk   (sys_clk)    //   up_clocks_0_CLOCK_50.clk
//    );
//
//
//assign DRAM_CLK=sdram_clk;
 

//// Bus to SDRAM
////wire [21:0] sdram_addr = bus_address - `Sdram_min;
//wire [21:0] sdram_addr = bus_address[21:0];
//wire [15:0] sdram_wrdata= bus_write_data[15:0];
//wire [1:0]  sdram_byte_en = 2'b11; // Enable all bytes (active low);
//// Control
//wire        sdram_write_en = (Sdram_selected && bus_write_enable);
//wire        sdram_read_en = (Sdram_selected && bus_read_enable);

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
    .BA(DRAM_BA),          //                            .ba
    .CASn(DRAM_CAS_N),       //                            .cas_n
    .CSn(DRAM_CS_N),        //                            .cs_n
    .DQ(DRAM_DQ),          //                            .dq
    .DQM(DRAM_DQM),         //                            .dqm
    .RASn(DRAM_RAS_N),       //                            .ras_n
    .WEn(DRAM_WE_N)         //                            .we_n
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
    reg uart_read_pulse;
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
        .jtag_uart_0_avalon_jtag_slave_read_n    (~(bus_read_done==0 && Art_selected)),
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
    //reg [31:0] Plic_claim [0:1];  // 0x200004 4B per hart
//say hart0 M mode UART id 1 give an interrupt, then what happen accordingly?
//1.base+4*1 set to be 7( suppose higher priority of id 1 interrupt) (address mapping to array of reg)
//2.pending base+0x1000's bit 1 (not 0) to be 1 means id 1 is pending (address mapping to 32bits regs)
//3.enable base +0x2000's bit 1 to be 1 means it is enabled (address mapping to 32bits regs)
//4.threshold base +0x200000 4 bytes to be set  (address mapping to 32bits regs, one reg for one context?)
//5.when PLIC find it worth then trigger to cpu (set SEIP MEIP .etc)
//6.CPU check claim for id, PLIC checkout pending value to CPU, then PLIC clean pending
//7. then cpu handler to finish then set claim register to be 1, PLIC know cpu finished.


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
    // Plic mapping
    wire Plic_priority_selected = (bus_address >= `Plic_base && bus_address < `Plic_pending);
    wire Plic_pending_selected = (bus_address == `Plic_pending);
    wire Plic_enable_ctx0_selected = (bus_address == `Plic_enable);
    wire Plic_enable_ctx1_selected = (bus_address == `Plic_enable + 32'h80);
    wire Plic_threshold_ctx0_selected = (bus_address == `Plic_threshold);
    wire Plic_threshold_ctx1_selected = (bus_address == `Plic_threshold + 32'h1000);
    wire Plic_claim_ctx0_selected = (bus_address == `Plic_claim );
    wire Plic_claim_ctx1_selected = (bus_address == `Plic_claim + 32'h1000);
    //wire Plic_claim_ctx0_selected = (bus_address >= `Plic_claim && bus_address < `Plic_claim+1024*0x1000+4);
    reg [31:0] claim_id_calc [0:1]; // 0 for hart0M 1 for hart0S
    //reg [2:0] current_max_prio;
    //integer c, ctx;
    //always @(*) begin
    //    for (ctx=0;ctx<2;ctx=ctx+1) begin
    //        claim_id_calc[ctx]=0;
    //        current_max_prio = Plic_threshold[ctx];
    //        for (c=1;c<6;c=c+1) begin
    //    	if (Plic_pending[c] && Plic_enable[ctx][c]) begin  
    //    	    if (Plic_priority[c] > current_max_prio) begin
    //    	        current_max_prio = Plic_priority[c];
    //    	        claim_id_calc[ctx] = c; 
    //    	    end
    //            end
    //        end
    //    end
    //end
    always @(*) begin
        claim_id_calc[0] = 0; 
        claim_id_calc[1] = 0; 
        if (Plic_pending[1] && Plic_enable[0][1]) claim_id_calc[0] = 1; 
        if (Plic_pending[1] && Plic_enable[1][1]) claim_id_calc[1] = 1; 
    end



    wire meip_interrupt;
    wire msip_interrupt;
    assign meip_interrupt = (claim_id_calc[0] != 0);
    assign msip_interrupt = (claim_id_calc[1] != 0);
    wire uart_irq;
    wire [31:0] uart_readdata;


    // Read & Write BRAM Port B 
    reg [63:0] bus_address_reg;
    reg [63:0] bus_address_reg_full;
    reg [63:0] data;
    reg ld = 0;
    reg sd = 0;
    reg [2:0] step = 0;
    reg bus_read_done = 1;
    reg bus_write_done = 1;
    reg [63:0] next_addr;

    //reg bus_read_start = 0;
    //reg bus_write_start = 0;
    reg [4:0] plic_id;



    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            bus_read_done <= 1;
            bus_write_done <= 1;
	    bus_address_reg <= 0;
	    bus_address_reg_full <= 0;
	    next_addr <= 0;
	    ld <= 0;
	    sd <= 0;
	    step <= 0;
	    bus_read_data <= 0;
	    uart_write_pulse <= 0;
	    uart_read_pulse <= 0;
	    mtimecmp <=  32'h80000000;
	end else begin
        bus_address_reg <= bus_address>>2;
        bus_address_reg_full <= bus_address;
        sd_rd_start <= 0;
        uart_write_pulse <= 0;
	uart_read_pulse <= 0;
	// Plic
	plic_id <= (bus_address - `Plic_base) >> 2; // id = offset /4
	if (uart_irq) Plic_pending[1] <= 1;
	//if (key_pressed_edge) Plic_pending[1] <= 1;

        if (bus_read_enable) begin bus_read_done <= 0; cid <= (bus_address-`Sdc_base); end 
        if (bus_write_enable) begin bus_write_done <= 0; end

        // Read
        if (!bus_read_enable && bus_read_done==0) begin 
            if (Key_selected) begin bus_read_data <= {32'd0, 24'd0, ascii}; bus_read_done <= 1; end
	    if (Ram_selected) begin 
	        casez(bus_ls_type)
	            3'b011: begin // 011Ld
		        case(ld)
			    0: begin bus_read_data[31:0]  <= Cache[bus_address_reg]; bus_address_reg <= bus_address_reg +1; ld <= 1; end
		            1: begin bus_read_data[63:32] <= Cache[bus_address_reg]; ld <= 0; bus_read_done <= 1; end
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

	    if (Art_selected) begin uart_read_pulse <= 1; bus_read_data <= uart_readdata; bus_read_done <=1; end

	    //if (Sdram_selected && bus_read_done == 0) begin
	    //    if (sdram_req_wait==0) begin bus_read_data <= {48'b0, sdram_rddata}; bus_read_done <= 1; end
	    //end
	    
	     
	    if (Sdram_selected && bus_read_done == 0) begin
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
                // 000Lb 001Lh 010Lw  011Ld
		// 100Lbu 101Lhu 110Lwu
	    end
            // Plic read
	    if (Plic_priority_selected) begin bus_read_data <= Plic_priority[plic_id]; bus_read_done <= 1; end
	    else if (Plic_pending_selected) begin bus_read_data <= Plic_pending; bus_read_done <= 1; end
	    // context 0 M-mode
	    else if (Plic_enable_ctx0_selected) begin bus_read_data <= Plic_enable[0]; bus_read_done <= 1; end
	    else if (Plic_threshold_ctx0_selected) begin bus_read_data <= Plic_threshold[0]; bus_read_done <= 1; end
	    //else if (Plic_claim_ctx0_selected) begin bus_read_data <= Plic_claim[0]; end
	    else if (Plic_claim_ctx0_selected) begin bus_read_data <= claim_id_calc[0]; Plic_pending[claim_id_calc[0]]<=0; bus_read_done <= 1; end
	    // context 1 S-mode
	    else if (Plic_enable_ctx1_selected) begin bus_read_data <= Plic_enable[1]; bus_read_done <= 1; end
	    else if (Plic_threshold_ctx1_selected) begin bus_read_data <= Plic_threshold[1]; bus_read_done <= 1; end
	    else if (Plic_claim_ctx1_selected) begin bus_read_data <= claim_id_calc[1]; Plic_pending[claim_id_calc[1]]<=0; bus_read_done <= 1; end


        end

        // Write
        //if (bus_write_enable || sd!=0 ) begin 
        if (!bus_write_enable && bus_write_done == 0) begin 
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
		        case(sd)
		            0: begin Cache[bus_address[63:2]] <= bus_write_data[31:0]; sd <= 1; next_addr <= bus_address[63:2]+1; bus_write_done <= 0; end
			    1: begin Cache[next_addr] <= bus_write_data[63:32]; sd <= 0; end
			endcase
			end
	        endcase
	    end

	    if (Sdc_addr_selected) begin sd_addr <= bus_write_data[31:0]; bus_write_done <= 1; end
	    if (Sdc_read_selected) begin sd_rd_start <= 1; bus_write_done <= 1; end

	    if (Art_selected) begin uart_write_pulse <= 1; bus_write_done <=1; end

	    if (Mtimecmp_selected) begin mtimecmp <= bus_write_data; bus_write_done <= 1; end
	    //if (Sdram_selected) begin if (sdram_req_wait==0) bus_write_done <= 1; end
	    
            // Plic write
	    if (Plic_priority_selected) begin Plic_priority[plic_id] <= bus_write_data; bus_write_done <= 1; end
	    // context 0
	    else if (Plic_enable_ctx0_selected) begin Plic_enable[0] <= bus_write_data; bus_write_done <= 1; end
	    else if (Plic_threshold_ctx0_selected) begin Plic_threshold[0] <= bus_write_data; bus_write_done <= 1; end
	    //else if (Plic_claim_ctx0_selected) begin bus_write_done <= 1; end // set to 0 when read already
	    else if (Plic_claim_ctx0_selected) begin Plic_pending[bus_write_data] <= 0; bus_write_done <= 1; end
	    // context 1
	    else if (Plic_enable_ctx1_selected) begin Plic_enable[1] <= bus_write_data; bus_write_done <= 1; end
	    else if (Plic_threshold_ctx1_selected) begin Plic_threshold[1] <= bus_write_data; bus_write_done <= 1; end
	    //else if (Plic_claim_ctx1_selected) begin bus_write_done <= 1; end // set to 0 when read already
	    else if (Plic_claim_ctx1_selected) begin Plic_pending[bus_write_data] <= 0; bus_write_done <= 1; end
	    
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


    //// UART Writer Trigger
    //wire uart_write_trigger = bus_write_enable && Art_selected;
    //reg uart_write_trigger_dly;
    //always @(posedge CLOCK_50 or negedge KEY0) begin
    //    if (!KEY0) uart_write_trigger_dly <= 0;
    //    else uart_write_trigger_dly <= uart_write_trigger;
    //end
    //assign uart_write_trigger_pulse = uart_write_trigger  && !uart_write_trigger_dly;

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
    assign HEX05 = ~key_pressed;
    assign HEX06 = ~meip_interrupt;

endmodule
