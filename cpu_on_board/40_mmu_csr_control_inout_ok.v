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

        .bus_ls_type(bus_ls_type), // lb lh lw ld lbu lhu lwu sb sh sw sd 

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
    jtag_uart_system my_jtag_system (
        .clk_clk                                 (CLOCK_50),
        .reset_reset_n                           (KEY0),
        .jtag_uart_0_avalon_jtag_slave_address   (bus_address[0:0]),
        .jtag_uart_0_avalon_jtag_slave_writedata (bus_write_data[31:0]),
        //.jtag_uart_0_avalon_jtag_slave_write_n   (~uart_write_trigger_pulse),
        .jtag_uart_0_avalon_jtag_slave_write_n   (~uart_write_pulse),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        .jtag_uart_0_avalon_jtag_slave_read_n    (1'b1)
    );

    // -- Bus --
    reg  [63:0] bus_read_data;
    wire [63:0] bus_address;
    wire        bus_read_enable;
    wire [63:0] bus_write_data;
    wire        bus_write_enable;
    wire [2:0]  bus_ls_type; // lb lbu...sbhwd...

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
    wire Sdram_selected = (bus_address >= `Sdram_min && bus_address < `Sdram_max);

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
	end else begin
        bus_address_reg <= bus_address>>2;
        bus_address_reg_full <= bus_address;
        sd_rd_start <= 0;
        uart_write_pulse <= 0;

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

	    //if (Sdram_selected) begin if (sdram_req_wait==0) bus_write_done <= 1; end
	    
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


endmodule
`include "header.vh"

module riscv64(
    input wire clk, 
    input wire reset,     // Active-low reset button
    input wire [31:0] instruction,
    //output reg [63:0] pc,
    output reg [39:0] pc,
    output reg [31:0] ir,
    //output reg [63:0] re [0:31], // General Registers 32s
    output wire  heartbeat,
    input  reg [3:0] interrupt_vector, // notice from outside
    output reg  interrupt_ack,         // reply to outside
    //output reg [63:0] bus_address,     // 39 bit for real standard? 64 bit now
    output reg [38:0] bus_address,     // 39 bit for real Sv39 standard?
    output reg [63:0] bus_write_data,
    output reg        bus_write_enable,
    output reg        bus_read_enable,
    output reg [2:0]  bus_ls_type, // lb lh lw ld lbu lhu lwu // sb sh sw sd sbu shu swu 
    //output reg [2:0]  bus_ls_type, // sb sh sw sd sbu shu swu 
    input  reg        bus_read_done,
    input  reg        bus_write_done,
    input  wire [63:0] bus_read_data   // from outside
);

// -- new --
    reg [63:0] re [0:31]; // General Registers 32s
    reg [63:0] sre [0:31]; // Shadow Registers 32s
    reg shadowing=0;
    reg [63:0] saved_user_pc;
    reg [63:0] pa;
    reg [63:0] va;
    reg init_enter=1;
    integer i; 

    function [31:0] get_shadow_ir; // 0-5 mmu 
        input [63:0] spc;
        begin
    	case(spc)
    	    0: get_shadow_ir  = 32'b00000000000000000010001010110111; // lui t0, 0x2
    	    4: get_shadow_ir  = 32'b00000000010000101000001010010011; // addi t0, t0, 0x4
    	    8: get_shadow_ir  = 32'b00000101111000000000001100010011; // addi t1, x0, 0x5e
    	    12: get_shadow_ir = 32'b00000000011000101011000000100011; //sd t1, 0(t0) print ^
    	    16: get_shadow_ir = 32'b00110000001000000000000001110011; //mret
    	    default: get_shadow_ir = 32'h00000013; //NOP:addi x0, x0, 0
    	endcase
        end
    endfunction

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
    wire [6:0] w_func7   = ir[31:25]; 
    wire [11:0] w_func12 = ir[31:20]; 
    // -- rs1 rs2 value --
    wire [63:0] rs1 = re[w_rs1];
    wire [63:0] rs2 = re[w_rs2];



    reg [63:0] Csrs [0:20]; // 20 csr for now
    wire [11:0] w_csr = ir[31:20];   // CSR official address
//    wire [5:0] w_csr_id = (w_csr == 12'h180) ? 1 : // satp
//	                  (w_csr == 12'h300) ? 2 : // mstatus
//	                  (w_csr == 12'h305) ? 3 : // mtvec
//	                  (w_csr == 12'h340) ? 4 : // mscratch
//			   0;
    reg [5:0] w_csr_id;
    always @(*) begin
	case(w_csr)
            satp:w_csr_id = 1; 
            mstatus:w_csr_id = 2; 
            mtvec:w_csr_id = 3; 
            mscratch:w_csr_id = 4; 
	    default:w_csr_id = 0; 
	endcase
    end

    wire [63:0] csr_satp = Csrs[1];
    wire [3:0]  satp_mode = csr_satp[63:60]; // 0:bare, 8:sv39, 9:sv48  satp.MODE!=0, privilegae is not M-mode, mstatus.MPRN is not set or in MPP's mode?
    wire [15:0] satp_asid = csr_satp[59:44]; // Address Space ID for TLB
    wire [43:0] satp_ppn  = csr_satp[43:0];  // Root Page Table PPN physical page number
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
    //reg [63:0] csr_satp; 
    localparam satp = 12'h180; // Supervisor address translation and protection satp[63:60].MODE=0:off|8:SV39 satp[59:44].asid vpn2:9 vpn1:9 vpn0:9 satp[43:0]:rootpage physical addr
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
    //function [63:0] csr_read;
    //    input [11:0] csr_index;
    //    begin
    //        case (csr_index)
    //        12'h300: csr_read = csr_mstatus;
    //        12'h305: csr_read = csr_mtvec;
    //        12'h340: csr_read = csr_mscratch;
    //        12'h341: csr_read = csr_mepc;
    //        12'h342: csr_read = csr_mcause;

    //        12'h180: csr_read = csr_satp;

    //        default: csr_read = 64'd0;
    //        endcase
    //    end
    //endfunction
    //// -- CSR Writer -- 
    //task csr_write;
    //    input [11:0] csr_index;
    //    input [63:0] csr_wdata;
    //    begin
    //        case (csr_index)
    //        12'h300: csr_mstatus  = csr_wdata;
    //        12'h305: csr_mtvec    = csr_wdata;
    //        12'h340: csr_mscratch = csr_wdata;
    //        12'h341: csr_mepc     = csr_wdata;
    //        12'h342: csr_mcause   = csr_wdata;

    //        12'h180: csr_satp     = csr_wdata;

    //        default: ;
    //        endcase
    //    end
    //endtask
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
            //ir <= instruction;
	    if (shadowing) ir <= get_shadow_ir(pc);
            else ir <= instruction;
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
	    shadowing <= 0;
	    init_enter <= 1;
	    for (i=0;i<=31;i=i+1) begin sre[i]<= 64'b0; end
	    for (i=0;i<=20;i=i+1) begin Csrs[i]<= 64'b0; end

        end else begin
	    // Default PC+4    (1.Could be overide 2.Take effect next cycle) 
            pc <= pc + 4;
	    interrupt_ack <= 0;
	    bus_read_enable <= 0;
	    bus_write_enable <= 0; 

            // Shadowing
	    if (shadowing && init_enter) begin 
	        saved_user_pc <= pc; // save pc
		pc <= 0; // simplest default to mmu //if (mmu_working) pc <= 0; // mmu handle from 0
	 	bubble <= 1'b1; // bubble wrong fetched instruciton by IF
		init_enter <= 0;
		for (i=0;i<=31;i=i+1) begin sre[i]<= re[i]; end // save usr re
		re[31]<= va; // pass va to x31
		// then inner assembly for mmu wroking to calculate pa via va load and bus, put pa to x31
	    end else if (shadowing && ir == 32'h30200073) begin // hiject mret
		pc <= saved_user_pc; // recover from shadow when see Mret
		pa <= re[31]; // save inner assembly calculated physical address to pa
		shadowing <= 0; // end shadowing
		bubble <= 1; // bubble pre-fetched shadow ir
		for (i=0;i<=31;i=i+1) begin re[i]<= sre[i]; end // recover usr re
		
            // Interrupt
	    //if (interrupt_vector == 1 && mstatus_MIE == 1) begin //mstatus[3] MIE
	    end else if (interrupt_vector == 1 && mstatus_MIE == 1) begin //mstatus[3] MIE
	        csr_mepc <= pc; // save pc

		csr_mcause <= 64'h800000000000000B; // MSB 1 for interrupts 0 for exceptions, Cause 11 for Machine External Interrupt
		csr_mstatus[MPIE] <= csr_mstatus[MIE];
		csr_mstatus[MIE] <= 0;

		pc <= csr_mtvec; // jump to mtvec addrss (default 0, need C or Assembly code of handler)
		bubble <= 1'b1; // bubble wrong fetched instruciton by IF
	        csr_mstatus[MIE] <= 0;
		interrupt_ack <= 1; // reply to outside

            // Bubble
	    end else if (bubble) begin bubble <= 1'b0; end //  bus_write_enable <=0; bus_read_enable <= 0; end // Flush this cycle & Clear bubble signal for the next cycle

	    // IR
	    else begin 
	        //bus_read_enable <= 0;
	        //bus_write_enable <= 0; 
	        //bus_write_data <= 0;
	        //bus_address <= `Ram_base;
                casez(ir) // Pseudo: li j jr ret call // I: addi sb sh sw sd lb lw ld lbu lhu lwu lui jal jalr auipc beq slt mret 
	            // U-type
	            32'b???????_?????_?????_???_?????_0110111: re[w_rd] <= w_imm_u; // Lui
	            32'b???????_?????_?????_???_?????_0010111: re[w_rd] <= w_imm_u + (pc - 4); // Auipc

		    //32'b???????_?????_?????_000_?????_0000011: begin  // Lb  3 cycles but wait to 5
		    //    if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		    //    if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		    //    if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[7:0]); load_step <= 0; end end //bus_read_enable <= 0; end end // bus ok and execute
		    32'b???????_?????_?????_000_?????_0000011: begin  // Lb  3 cycles but wait to 5
			if (satp_mode && init_enter==1) begin shadowing<=1; va <= rs1 + w_imm_i; pc <= pc -4; end // for enter | hiject Lb, pass lb pc, bus_address to mmu va
			else begin 

		        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		        if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[7:0]); load_step <= 0; end //end //bus_read_enable <= 0; end end // bus ok and execute

			if (satp_mode && !shadowing && !init_enter) begin bus_address <= pa; end // for start pa_ed lb | overwrite bus_address by pa
			if (satp_mode && !shadowing && bus_read_done) begin init_enter<=1;end // for finish
		        end
		    end
		    32'b???????_?????_?????_100_?????_0000011: begin  // Lbu  3 cycles
		        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[7:0]); load_step <= 0; end end //bus_read_enable <= 0; end end // bus ok and execute
		    32'b???????_?????_?????_001_?????_0000011: begin  // Lh 3 cycles
		        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[15:0]); load_step <= 0; end end //bus_read_enable <= 0; end end // bus ok and execute
		    32'b???????_?????_?????_101_?????_0000011: begin   // Lhu 3 cycles
		        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[15:0]); load_step <= 0; end end //bus_read_enable <= 0; end end // bus ok and execute
		    32'b???????_?????_?????_010_?????_0000011: begin  // Lw_mmu 3 cycles
		        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0; end end //bus_read_enable <= 0; end end // bus ok and execute
		    32'b???????_?????_?????_110_?????_0000011: begin  // Lwu_mmu 3 cycles
		        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[31:0]); load_step <= 0; end end //bus_read_enable <= 0; end end // bus ok and execute
		    32'b???????_?????_?????_011_?????_0000011: begin   // Ld 5 cycles
		        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0; end end //bus_read_enable <= 0; end end // bus ok and execute
                    // Store
	            //32'b???????_?????_?????_000_?????_0100011: begin bus_address <= rs1 + w_imm_s;bus_write_data<=rs2[7:0]; bus_write_enable<=1;bus_ls_type<=w_func3;end//Sb bus1 cycles
	            //32'b???????_?????_?????_001_?????_0100011: begin bus_address <= rs1 + w_imm_s;bus_write_data<=rs2[15:0];bus_write_enable<=1;bus_ls_type<=w_func3;end//Sh bus1
	            //32'b???????_?????_?????_010_?????_0100011: begin bus_address <= rs1 + w_imm_s;bus_write_data<=rs2[31:0];bus_write_enable<=1;bus_ls_type<=w_func3;end//Sw bus1
	            //32'b???????_?????_?????_011_?????_0100011: begin bus_address <= rs1 + w_imm_s;bus_write_data<=rs2;bus_write_enable<=1;pc<=pc;bubble<=1;bus_ls_type<=w_func3;end//Sdbus2
	            32'b???????_?????_?????_000_?????_0100011: begin 
		        if (store_step == 0) begin bus_address <= rs1 + w_imm_s; bus_write_data<=rs2[7:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		        if (store_step == 1 && bus_write_done == 1) store_step <= 0;
		        end //Sb bus1 cycles
	            32'b???????_?????_?????_001_?????_0100011: begin
		        if (store_step == 0) begin bus_address <= rs1 + w_imm_s; bus_write_data<=rs2[15:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		        if (store_step == 1 && bus_write_done == 1) store_step <= 0;
		        end //Sh
	            32'b???????_?????_?????_010_?????_0100011: begin
		        if (store_step == 0) begin bus_address <= rs1 + w_imm_s; bus_write_data<=rs2[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		        if (store_step == 1 && bus_write_done == 1) store_step <= 0;
		        end //Sw
	            32'b???????_?????_?????_011_?????_0100011: begin 
		        if (store_step == 0) begin bus_address <= rs1 + w_imm_s; bus_write_data<=rs2;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		        if (store_step == 1 && bus_write_done == 1) store_step <= 0;
		        end //Sd
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
	            32'b???????_?????_?????_???_?????_1100111: begin pc <= (rs1 + w_imm_i) & 64'hFFFFFFFFFFFFFFFE; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1; end // Jalr
                    // Branch 
		    32'b???????_?????_?????_000_?????_1100011: begin if (rs1 == rs2) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Beq
		    32'b???????_?????_?????_001_?????_1100011: begin if (rs1 != rs2) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bne
		    32'b???????_?????_?????_100_?????_1100011: begin if ($signed(rs1) < $signed(rs2)) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Blt
		    32'b???????_?????_?????_101_?????_1100011: begin if ($signed(rs1) >= $signed(rs2)) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bge
		    32'b???????_?????_?????_110_?????_1100011: begin if (rs1 < rs2) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bltu
		    32'b???????_?????_?????_111_?????_1100011: begin if (rs1 >= rs2) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bgeu
                    // M extension
		    //32'b0000001_?????_?????_000_?????_0110011: re[w_rd] <= $signed(rs1) * $signed(rs2);  // Mul
                    //32'b0000001_?????_?????_001_?????_0110011: re[w_rd] <= ($signed(rs1) * $signed(rs2))>>>64;//[127:64];  // Mulh 
                    ////32'b0000001_?????_?????_100_?????_0110011: re[w_rd] <= (rs2==0||(rs1==64'h8000_0000_0000_0000 && rs2 == -1)) ? -1 : $signed(rs1) / $signed(rs2);  // Div
                    //32'b0000001_?????_?????_101_?????_0110011: re[w_rd] <= (rs2==0) ? -1 : $unsigned(rs1) / $unsigned(rs2);  // Divu

		    // System-CSR 
	            //32'b???????_?????_?????_001_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); csr_write(w_csr,  rs1); end // Csrrw
	            //32'b???????_?????_?????_010_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_rs1 != 0 )  csr_write(w_csr, csr_read(w_csr) |  rs1); end // Csrrs
	            //32'b???????_?????_?????_011_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_rs1 != 0 )  csr_write(w_csr, csr_read(w_csr) & ~rs1); end // Csrrc
	            //32'b???????_?????_?????_101_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); csr_write(w_csr,  w_imm_z); end // Csrrwi
	            //32'b???????_?????_?????_110_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_imm_z != 0) csr_write(w_csr, csr_read(w_csr) |  w_imm_z); end // csrrsi
	            //32'b???????_?????_?????_111_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_imm_z != 0) csr_write(w_csr, csr_read(w_csr) & ~w_imm_z); end // Csrrci

	            32'b???????_?????_?????_001_?????_1110011: begin if (w_rd != 0) re[w_rd] <= Csrs[w_csr_id]; Csrs[w_csr_id] <= rs1; end // Csrrw  bram read first old data

	            //32'b???????_?????_?????_010_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_rs1 != 0 )  csr_write(w_csr, csr_read(w_csr) |  rs1); end // Csrrs
	            //32'b???????_?????_?????_011_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_rs1 != 0 )  csr_write(w_csr, csr_read(w_csr) & ~rs1); end // Csrrc
	            //32'b???????_?????_?????_101_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); csr_write(w_csr,  w_imm_z); end // Csrrwi
	            //32'b???????_?????_?????_110_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_imm_z != 0) csr_write(w_csr, csr_read(w_csr) |  w_imm_z); end // csrrsi
	            //32'b???????_?????_?????_111_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_imm_z != 0) csr_write(w_csr, csr_read(w_csr) & ~w_imm_z); end // Csrrci
                    // System-Machine
	            //32'b0011000_00010_?????_000_?????_1110011: begin pc <= csr_read(mepc); bubble <= 1; csr_mstatus[MIE] <= csr_mstatus[MPIE]; csr_mstatus[MPIE] <= 1; end  // Mret
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
	re[0]<=0; 
	sre[0]<=0;
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
//    # Write one byte
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
//    # MMU enabled
//    li a1, 8              
//    slli a1, a1, 60          # mmu mode sv39 #li a1, 0x8000000000000000 # mmu mode sv39
//    csrrw a3, 0x180, a1      # set satp csr index 0x180
//
//
//    lb a0, 1(s0)         # test sdram ld+1
//    sb a0, 0(t0)         # Should print 'B'
//
//done:
//    j done
