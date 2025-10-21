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
    (* chip_pin = "G6" *)  output wire HEX21,

    (* chip_pin = "E1" *)  output wire HEX10,
    (* chip_pin = "H6" *)  output wire HEX11,

    (* chip_pin = "J2" *)  output wire HEX00,
    (* chip_pin = "J1" *)  output wire HEX01,
    (* chip_pin = "H2" *)  output wire HEX02,
    (* chip_pin = "H1" *)  output wire HEX03,

    (* chip_pin = "H15" *)  input wire PS2_CLK, 
    (* chip_pin = "J14" *)  input wire PS2_DAT,


    //(* chip_pin = "V20" *)  output wire SPI_SCLK, //SD_CLK
    //(* chip_pin = "Y20" *)  output wire SPI_MOSI, // SD_CMD
    //(* chip_pin = "W20" *)  input wire SPI_MISO,// SD_DAT
    (* chip_pin = "V20" *)  output wire SD_CLK, //SD_CLK
    (* chip_pin = "Y20" *)  output wire SD_CMD, // SD_CMD
    (* chip_pin = "W20" *)  input wire SD_DAT0, // SD_DAT
    (* chip_pin = "U20" *)  output wire SD_DAT3 // SD_DAT3


    

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
    // Port A BRAM
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
    // Keyboard signal
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

    //// -- mmu_d --
    //wire tlb_hit;
    //wire [63:0] physical_address;
    //wire [63:0] satp;
    //mmu_d mmud (
    //.clk (CLOCK_50),
    //.reset (KEY0),
    //.va (bus_address),
    //.pa (physical_address),
    //.satp (satp),
    //.tlb_hit (tlb_hit)
    //);
    // --  ---

    // -- Bus --
    reg  [63:0] bus_read_data;
    wire [63:0] bus_address;
    wire        bus_read_enable;
    wire [63:0] bus_write_data;
    wire        bus_write_enable;
    reg   bus_read_done;

    // == Bus controller ==
    // 1.-- Address Decoding --
    wire Rom_selected = (bus_address >= `Rom_base && bus_address < `Rom_base + `Rom_size);
    wire Ram_selected = (bus_address >= `Ram_base && bus_address < `Ram_base + `Ram_size);
    ////wire Stk_selected = (bus_address >= Stk_base && bus_address < Stk_base + Stk_size);
    wire Key_selected = (bus_address == `Key_base);
    wire Art_selected = (bus_address == `Art_base);
    wire Spi_selected = (bus_address >= `Spi_base && bus_address < `Spi_base + `Spi_size);
    reg Spi_selected_reg;
    always @(posedge CLOCK_50) begin
        Spi_selected_reg <= Spi_selected;
    end


    // 3. Port B read & write BRAM
    reg [63:0] bus_address_reg;
    always @(posedge CLOCK_50) begin
        bus_address_reg <= bus_address>>2; // BRAM read need this reg address if has condition in circle
        if (bus_read_enable) begin // Read
	    if (Key_selected) begin bus_read_data <= {32'd0, 24'd0, ascii}; bus_read_done <= 1; end
	    if (Ram_selected) begin bus_read_data <= {32'd0, Cache[bus_address_reg]}; bus_read_done <= 1; end
	    //if (Spi_selected_reg) begin bus_read_data <= {48'd0, spi_read_data_wire}; bus_read_done <= 1; end
        end
	if (bus_write_enable) begin // Write
	    if (Ram_selected) Cache[bus_address[63:2]] <= bus_write_data[31:0];  // cut fit 32 bit ram //work
        end
    end
      
      
     //  4.-- UART Writer Trigger --
      wire uart_write_trigger = bus_write_enable && Art_selected;
      reg uart_write_trigger_dly;
      always @(posedge CLOCK_50 or negedge KEY0) begin
  	if (!KEY0) uart_write_trigger_dly <= 0;
  	else uart_write_trigger_dly <= uart_write_trigger;
      end
      assign uart_write_trigger_pulse = uart_write_trigger  && !uart_write_trigger_dly;


//wire uart_write_trigger = bus_write_enable && Art_selected;
//reg uart_write_trigger_dly;
//reg uart_write_pending;
//always @(posedge CLOCK_50 or negedge KEY0) begin
//  if (!KEY0) begin
//    uart_write_pending <= 0;
//    uart_write_trigger_dly <= 0;
//  end else begin
//    if (uart_write_trigger && !uart_write_pending) begin
//       uart_write_pending <= 1;         // start pending
//    end else if (uart_write_pending) begin
//       uart_write_pending <= 0;         // complete next cycle
//    end
//    uart_write_trigger_dly <= uart_write_trigger;
//  end
//end
//wire uart_write_trigger_pulse = uart_write_pending;





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
    assign HEX21 = ~bus_read_enable;

    assign HEX10 = ~|bus_write_data;
    assign HEX11 = ~bus_write_enable;

    assign HEX00 = ~Art_selected;
    assign HEX01 = ~Ram_selected;
    assign HEX02 = ~Rom_selected;
    assign HEX03 = ~Spi_selected;


   // // 6. -- SPI --
   //wire [15:0] spi_read_data_wire;
   //spi my_spi_system (
   //    .clk_clk                       (CLOCK_50),
   //    .reset_reset_n                 (KEY0),
   //    //.spi_0_reset_reset_n           (KEY0),
   //    .spi_0_spi_control_port_chipselect (Spi_selected), // Connection
   //    .spi_0_spi_control_port_address    (bus_address[3:1]), // IP is 16 bytes wide data so address align by bytes
   //    .spi_0_spi_control_port_read_n     (~(bus_read_enable && Spi_selected)), // Read
   //    .spi_0_spi_control_port_readdata   (spi_read_data_wire),
   //    .spi_0_spi_control_port_write_n    (~(bus_write_enable && Spi_selected)), // Write
   //    .spi_0_spi_control_port_writedata  (bus_write_data[15:0]),  // 16-bytes wide
   //    .spi_0_external_MISO           (SPI_MISO), // Map to Physical pins
   //    .spi_0_external_MOSI           (SPI_MOSI),
   //    .spi_0_external_SCLK           (SPI_SCLK),
   //    .spi_0_external_SS_n           (SPI_SS_n),
   //); 
   // 7. -- SD Card --
    wire [31:0] spo;
    reg [15:0] mem_a = 32'h0000_3010;
    reg [31:0] mem_d = 0;
    reg mem_we = 0;
    wire sd_ncd = 0;
    wire sd_wp = 0;
    wire irq;
    wire sd_dat1;
    wire sd_dat2;

    sdcard sd0 (
	.clk(CLOCK_50),
	.rst(KEY0), // ?
	.sd_dat0(SD_DAT0), // MISO
	.sd_ncd(sd_ncd), 
	.sd_wp(sd_wp), 
	.sd_dat1(sd_dat1), 
	.sd_dat2(sd_dat2), 
	.sd_dat3(SD_DAT3),  // chip select
	.sd_cmd(SD_CMD),  // MOSI
	.sd_sck(SD_CLK),  // SPI Clock
	// memory map
	.a(mem_a),
	            // 0x4000-0x41fc 0x0000-0x01fc:128x32=518BytesSectorCache 
                    // 0x3000 0x1000getSetAddress512Aligned 
                    // 0x3004 0x1004Read  mem_d:1-sd_rd
                    // 0x3008 0x1008Write mem_d:1-sd_wr
                    // 0x3012 0x2000Sd_ncd
                    // 0x3016 0x2004Sd_wp
                    // 0x3020 0x2010readyforpoll 
                    // 0x3024 0x2014dirty
	.d(mem_d),
	.we(mem_we),
	.spo(spo),
	.irq(irq)
    );
      

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
