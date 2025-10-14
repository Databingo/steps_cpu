// 74 cycles 0xFF to MOSI
// CMD0
// Assume the register offsets within the SPI core are:
// 0x0: rxdata (Read-Only)
// 0x4: txdata (Write-Only)
// 0x8: status (Read-Only)
// 0xC: control (Read/Write)
// 0x10: slaveselect (Write-Only) 0x01 for only one
// status
// Bit 5 TRDY Transmit Ready, empty for receive a new byte
// Bit 6 RRDY Receive Ready, ready for be read
// Bit 7 Error
// Bit 4 Empty
// Bit 3 Rx Overrun
// Bit 2 Tx Overrun
//
//
//
// print D 0 by chatgpt5
//module cpu_on_board (
//    // -- Pins --
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    (* chip_pin = "V20" *) output wire SPI_SCLK,  // SD_CLK
//    (* chip_pin = "Y20" *) output wire SPI_MOSI,  // SD_CMD
//    (* chip_pin = "W20" *) input  wire SPI_MISO,  // SD_DAT0
//    (* chip_pin = "U20" *) output wire SPI_SS_n   // SD_DAT3 / CS
//);
//
//    // ================================================================
//    // UART for debug
//    // ================================================================
//    reg  [31:0] uart_data;
//    reg         uart_write;
//
//    jtag_uart_system uart0 (
//        .clk_clk(CLOCK_50),
//        .reset_reset_n(KEY0),
//        .jtag_uart_0_avalon_jtag_slave_address(1'b0),
//        .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
//        .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
//        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
//        .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
//    );
//
//    // ================================================================
//    // SPI signals
//    // ================================================================
//    wire [15:0] spi_read_data_wire;
//    reg [15:0] bus_write_data;
//    reg [2:0]  bus_address;
//    reg        bus_write_enable, bus_read_enable, Spi_selected;
//
//    // ================================================================
//    // CMD0 sequence state machine
//    // ================================================================
//    reg [7:0] cmd[0:5];
//    reg [3:0] state;
//    reg [31:0] counter;
//
//    initial begin // CMD0
//        cmd[0] = 8'h40; 
//	cmd[1] = 8'h00; 
//	cmd[2] = 8'h00; 
//	cmd[3] = 8'h00; 
//	cmd[4] = 8'h00; 
//	cmd[5] = 8'h95;
//    end
//
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0) begin
//            uart_data <= 0;
//            uart_write <= 0;
//            state <= 0;
//            Spi_selected <= 0;
//            bus_write_enable <= 0;
//            bus_read_enable <= 0;
//            counter <= 0;
//        end else begin
//            uart_write <= 0;  // default off
//            counter <= counter + 1;
//
//            case (state)
//                0: begin
//                    // Wait a bit before printing
//                    if (counter == 32'd100_000_000) begin
//                        uart_data <= {24'd0, "S"}; uart_write <= 1; state <= 1;
//                    end
//                end
//                1: begin uart_data <= {24'd0, "D"}; uart_write <= 1; state <= 2; end
//                2: begin uart_data <= {24'd0, " "}; uart_write <= 1; state <= 3; end
//                3: begin
//                    // Begin SPI CMD0 send
//                    Spi_selected <= 1'b1;
//                    bus_write_enable <= 1'b1;
//                    bus_address <= 3'd1; // TXDATA register
//                    bus_write_data <= {8'd0, cmd[0]};
//                    state <= 4;
//                end
//                4: begin bus_write_data <= {8'd0, cmd[1]}; state <= 5; end
//                5: begin bus_write_data <= {8'd0, cmd[2]}; state <= 6; end
//                6: begin bus_write_data <= {8'd0, cmd[3]}; state <= 7; end
//                7: begin bus_write_data <= {8'd0, cmd[4]}; state <= 8; end
//                8: begin bus_write_data <= {8'd0, cmd[5]}; state <= 9; end
//                9: begin
//                    // Now read back response
//                    bus_write_enable <= 0;
//                    bus_read_enable <= 1;
//                    state <= 10;
//                end
//                10: begin
//                    // Print response in hex
//                    uart_data <= {24'd0, spi_read_data_wire[7:0] + 8'h30};
//                    uart_write <= 1;
//                    Spi_selected <= 0;
//                    bus_read_enable <= 0;
//                    state <= 11;
//                end
//		//11: begin uart_write <= 0; state <= 2; end
//                default: state <= 11;
//            endcase
//        end
//    end
//
//    // ================================================================
//    // SPI IP instantiation
//    // ================================================================
//    spi my_spi_system (
//        .clk_clk(CLOCK_50),
//        .reset_reset_n(KEY0),
//        //.spi_0_reset_reset_n(KEY0),
//        .spi_0_spi_control_port_chipselect (Spi_selected),
//        .spi_0_spi_control_port_address    (bus_address),
//        .spi_0_spi_control_port_read_n     (~(bus_read_enable && Spi_selected)),
//        .spi_0_spi_control_port_readdata   (spi_read_data_wire),
//        .spi_0_spi_control_port_write_n    (~(bus_write_enable && Spi_selected)),
//        .spi_0_spi_control_port_writedata  (bus_write_data),
//        .spi_0_external_MISO(SPI_MISO),
//        .spi_0_external_MOSI(SPI_MOSI),
//        .spi_0_external_SCLK(SPI_SCLK),
//        .spi_0_external_SS_n(SPI_SS_n)
//    );
//
//    assign LEDR0 = Spi_selected;
//
//endmodule
//
//
////                    bus_write_data<=16'hFF;
////                    if(counter>0) counter<=counter-1;
//

// SD card CMD0 test — fixed version by ChatGPT-5
// Prints "S D <response>" over JTAG UART

//module cpu_on_board (
//    // -- Pins --
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    (* chip_pin = "V20" *) output wire SPI_SCLK,  // SD_CLK
//    (* chip_pin = "Y20" *) output wire SPI_MOSI,  // SD_CMD
//    (* chip_pin = "W20" *) input  wire SPI_MISO,  // SD_DAT0
//    (* chip_pin = "U20" *) output wire SPI_SS_n   // SD_DAT3 / CS
//);
//
//    // ================================================================
//    // UART for debug
//    // ================================================================
//    reg  [31:0] uart_data;
//    reg         uart_write;
//
//    jtag_uart_system uart0 (
//        .clk_clk(CLOCK_50),
//        .reset_reset_n(KEY0),
//        .jtag_uart_0_avalon_jtag_slave_address(1'b0),
//        .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
//        .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
//        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
//        .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
//    );
//
//    // ================================================================
//    // SPI signals
//    // ================================================================
//    wire [15:0] spi_read_data_wire;
//    reg [15:0] bus_write_data;
//    reg [2:0]  bus_address;
//    reg        bus_write_enable, bus_read_enable, Spi_selected;
//
//    // ================================================================
//    // CMD0 sequence state machine
//    // ================================================================
//    reg [7:0] cmd[0:5];
//    reg [3:0] state;
//    reg [31:0] counter;
//
//    // --- CMD0 ---
//    initial begin
//        cmd[0] = 8'h40;
//        cmd[1] = 8'h00;
//        cmd[2] = 8'h00;
//        cmd[3] = 8'h00;
//        cmd[4] = 8'h00;
//        cmd[5] = 8'h95;
//    end
//
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0) begin
//            uart_data <= 0;
//            uart_write <= 0;
//            state <= 0;
//            Spi_selected <= 0;
//            bus_write_enable <= 0;
//            bus_read_enable <= 0;
//            counter <= 0;
//        end else begin
//            uart_write <= 0;  // default off
//            counter <= counter + 1;
//
//            case (state)
//                // -----------------------------------------------------
//                // Wait a bit before start (2 seconds)
//                // -----------------------------------------------------
//                0: begin
//                    if (counter == 32'd100_000_000) begin
//                        uart_data <= {24'd0, "S"};
//                        uart_write <= 1;
//                        counter <= 0;
//                        state <= 1;
//                    end
//                end
//
//                // -----------------------------------------------------
//                // Print D (indicates sending CMD0)
//                // -----------------------------------------------------
//                1: begin
//                    uart_data <= {24'd0, "D"};
//                    uart_write <= 1;
//                    counter <= 0;
//                    state <= 2;
//                end
//
//                // -----------------------------------------------------
//                // Send space for formatting
//                // -----------------------------------------------------
//                2: begin
//                    uart_data <= {24'd0, " "};
//                    uart_write <= 1;
//                    counter <= 0;
//                    state <= 3;
//                end
//
//                // -----------------------------------------------------
//                // Send CMD0 bytes to SPI (TXDATA = address 1)
//                // -----------------------------------------------------
//                3: begin
//                    Spi_selected <= 1'b1;
//                    bus_write_enable <= 1'b1;
//                    bus_address <= 3'd1;  // TXDATA
//                    bus_write_data <= {8'd0, cmd[0]};
//                    state <= 4;
//                end
//                4: begin bus_write_data <= {8'd0, cmd[1]}; state <= 5; end
//                5: begin bus_write_data <= {8'd0, cmd[2]}; state <= 6; end
//                6: begin bus_write_data <= {8'd0, cmd[3]}; state <= 7; end
//                7: begin bus_write_data <= {8'd0, cmd[4]}; state <= 8; end
//                8: begin bus_write_data <= {8'd0, cmd[5]}; state <= 9; counter <= 0; end
//
//                // -----------------------------------------------------
//                // Wait some time for SPI transfer to finish
//                // -----------------------------------------------------
//                9: begin
//                    if (counter > 32'd1000) begin
//                        bus_write_enable <= 0;
//                        bus_read_enable <= 1;
//                        bus_address <= 3'd0; // RXDATA
//                        state <= 10;
//                    end
//                end
//
//                // -----------------------------------------------------
//                // Print SPI read result
//                // -----------------------------------------------------
//                10: begin
//                    uart_data <= {24'd0, spi_read_data_wire[7:0] + 8'h30};
//                    uart_write <= 1;
//                    Spi_selected <= 0;
//                    bus_read_enable <= 0;
//                    state <= 11;
//                end
//
//                // -----------------------------------------------------
//                // Stop state
//                // -----------------------------------------------------
//                default: state <= 11;
//            endcase
//        end
//    end
//
//    // ================================================================
//    // SPI IP instantiation
//    // ================================================================
//    spi my_spi_system (
//        .clk_clk(CLOCK_50),
//        .reset_reset_n(KEY0),
//        .spi_0_spi_control_port_chipselect (Spi_selected),
//        .spi_0_spi_control_port_address    (bus_address),
//        .spi_0_spi_control_port_read_n     (~(bus_read_enable && Spi_selected)),
//        .spi_0_spi_control_port_readdata   (spi_read_data_wire),
//        .spi_0_spi_control_port_write_n    (~(bus_write_enable && Spi_selected)),
//        .spi_0_spi_control_port_writedata  (bus_write_data),
//        .spi_0_external_MISO(SPI_MISO),
//        .spi_0_external_MOSI(SPI_MOSI),
//        .spi_0_external_SCLK(SPI_SCLK),
//        .spi_0_external_SS_n(SPI_SS_n)
//    );
//
//    assign LEDR0 = Spi_selected;
//
//en




//
//module cpu_on_board (
//    // -- Pins --
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    (* chip_pin = "V20" *) output wire SPI_SCLK,  // SD_CLK
//    (* chip_pin = "Y20" *) output wire SPI_MOSI,  // SD_CMD
//    (* chip_pin = "W20" *) input  wire SPI_MISO,  // SD_DAT0
//    (* chip_pin = "U20" *) output wire SPI_SS_n   // SD_DAT3 / CS
//);
//
//    // ================================================================
//    // UART for debug
//    // ================================================================
//    reg  [31:0] uart_data;
//    reg         uart_write;
//
//    jtag_uart_system uart0 (
//        .clk_clk(CLOCK_50),
//        .reset_reset_n(KEY0),
//        .jtag_uart_0_avalon_jtag_slave_address(1'b0),
//        .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
//        .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
//        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
//        .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
//    );
//
//    // ================================================================
//    // SPI control
//    // ================================================================
//    wire [15:0] spi_read_data_wire;
//    reg  [15:0] bus_write_data;
//    reg  [2:0]  bus_address;
//    reg         bus_write_enable, bus_read_enable, Spi_selected;
//
//    // ================================================================
//    // CMD0 sequence
//    // ================================================================
//    reg [7:0] cmd[0:5];
//    reg [4:0] state;
//    reg [7:0] i;
//    reg [31:0] delay_counter;
//    reg [7:0] response;
//
//    localparam SPI_TXDATA  = 3'd1;
//    localparam SPI_RXDATA  = 3'd0;
//    localparam SPI_STATUS  = 3'd2;
//    localparam SPI_SSREG   = 3'd4;
//    localparam TRDY_BIT    = 5;
//    localparam RRDY_BIT    = 6;
//
//    initial begin
//        cmd[0] = 8'h40; 
//        cmd[1] = 8'h00; 
//        cmd[2] = 8'h00; 
//        cmd[3] = 8'h00; 
//        cmd[4] = 8'h00; 
//        cmd[5] = 8'h95; 
//    end
//
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0) begin
//            uart_data <= 0;
//            uart_write <= 0;
//            Spi_selected <= 0;
//            bus_write_enable <= 0;
//            bus_read_enable <= 0;
//            state <= 0;
//            i <= 0;
//            delay_counter <= 0;
//            response <= 8'hFF;
//        end else begin
//            // defaults
//            uart_write <= 0;
//            bus_write_enable <= 0;
//            bus_read_enable <= 0;
//            Spi_selected <= 0;
//
//            case (state)
//                // Wait some time and print 'S'
//                0: begin
//                    delay_counter <= delay_counter + 1;
//                    if (delay_counter == 32'd50_000_000) begin // 1s delay
//                        uart_data <= {24'd0, "S"};
//                        uart_write <= 1;
//                        delay_counter <= 0;
//                        state <= 1;
//                    end
//                end
//
//                // Send 80 dummy clocks (10 bytes of 0xFF)
//                1: begin
//                    Spi_selected <= 1'b1;
//                    bus_write_enable <= 1'b1;
//                    bus_address <= SPI_SSREG;
//                    bus_write_data <= 16'd0; // deassert CS (SS_n high)
//                    i <= 0;
//                    state <= 2;
//                end
//
//                2: begin
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1;
//                    bus_address <= SPI_STATUS;
//                    if (spi_read_data_wire[TRDY_BIT]) begin
//                        Spi_selected <= 1'b1;
//                        bus_write_enable <= 1'b1;
//                        bus_address <= SPI_TXDATA;
//                        bus_write_data <= 16'hFF;
//                        i <= i + 1;
//                        if (i == 10) state <= 3;
//                    end
//                end
//
//                // Assert CS low and send CMD0
//                3: begin
//                    Spi_selected <= 1'b1;
//                    bus_write_enable <= 1'b1;
//                    bus_address <= SPI_SSREG;
//                    bus_write_data <= 16'd1; // select slave 0 -> CS low
//                    i <= 0;
//                    state <= 4;
//                end
//
//                // Wait TRDY, send 6 CMD0 bytes
//                4: begin
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1;
//                    bus_address <= SPI_STATUS;
//                    if (spi_read_data_wire[TRDY_BIT]) begin
//                        Spi_selected <= 1'b1;
//                        bus_write_enable <= 1'b1;
//                        bus_address <= SPI_TXDATA;
//                        bus_write_data <= {8'd0, cmd[i]};
//                        if (i == 5) begin
//                            i <= 0;
//                            state <= 5;
//                        end else i <= i + 1;
//                    end
//                end
//
//                // Poll for response (expect 0x01)
//                5: begin
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1;
//                    bus_address <= SPI_STATUS;
//                    if (spi_read_data_wire[TRDY_BIT]) begin
//                        Spi_selected <= 1'b1;
//                        bus_write_enable <= 1'b1;
//                        bus_address <= SPI_TXDATA;
//                        bus_write_data <= 16'hFF; // send dummy
//                        state <= 6;
//                    end
//                end
//
//                6: begin
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1;
//                    bus_address <= SPI_STATUS;
//                    if (spi_read_data_wire[RRDY_BIT]) begin
//                        Spi_selected <= 1'b1;
//                        bus_read_enable <= 1'b1;
//                        bus_address <= SPI_RXDATA;
//                        response <= spi_read_data_wire[7:0];
//                        state <= 7;
//                    end
//                end
//
//                // Print response
//                7: begin
//                    uart_data <= {24'd0, " "};
//                    uart_write <= 1;
//                    state <= 8;
//                end
//
//                8: begin
//                    uart_data <= {24'd0, response + 8'd48}; // ASCII number
//                    uart_write <= 1;
//                    state <= 9;
//                end
//
//                9: begin
//                    Spi_selected <= 1'b1;
//                    bus_write_enable <= 1'b1;
//                    bus_address <= SPI_SSREG;
//                    bus_write_data <= 16'd0; // CS high
//                    state <= 9; // done
//                end
//            endcase
//        end
//    end
//
//    // ================================================================
//    // SPI core
//    // ================================================================
//    spi my_spi_system (
//        .clk_clk(CLOCK_50),
//        .reset_reset_n(KEY0),
//        .spi_0_spi_control_port_chipselect (Spi_selected),
//        .spi_0_spi_control_port_address    (bus_address),
//        .spi_0_spi_control_port_read_n     (~(bus_read_enable && Spi_selected)),
//        .spi_0_spi_control_port_readdata   (spi_read_data_wire),
//        .spi_0_spi_control_port_write_n    (~(bus_write_enable && Spi_selected)),
//        .spi_0_spi_control_port_writedata  (bus_write_data),
//        .spi_0_external_MISO(SPI_MISO),
//        .spi_0_external_MOSI(SPI_MOSI),
//        .spi_0_external_SCLK(SPI_SCLK),
//        .spi_0_external_SS_n(SPI_SS_n)
//    );
//
//    assign LEDR0 = Spi_selected;
//
//endmodule



//module cpu_on_board (
//    // -- Pins --
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    (* chip_pin = "V20" *) output wire SPI_SCLK,  // SD_CLK
//    (* chip_pin = "Y20" *) output wire SPI_MOSI,  // SD_CMD
//    (* chip_pin = "W20" *) input  wire SPI_MISO,  // SD_DAT0
//    (* chip_pin = "U20" *) output wire SPI_SS_n   // SD_DAT3 / CS
//);
//
//    // ================================================================
//    // UART for debug
//    // ================================================================
//    reg  [31:0] uart_data;
//    reg         uart_write;
//
//    jtag_uart_system uart0 (
//        .clk_clk(CLOCK_50),
//        .reset_reset_n(KEY0),
//        .jtag_uart_0_avalon_jtag_slave_address(1'b0),
//        .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
//        .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
//        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
//        .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
//    );
//
//    // ================================================================
//    // SPI control
//    // ================================================================
//    wire [15:0] spi_read_data_wire;
//    reg  [15:0] bus_write_data;
//    reg  [2:0]  bus_address;
//    reg         bus_write_enable, bus_read_enable, Spi_selected;
//
//    // ================================================================
//    // CMD0 sequence
//    // ================================================================
//    reg [7:0] cmd[0:5];
//    reg [4:0] state;
//    reg [7:0] i;
//    reg [31:0] delay_counter;
//    reg [7:0] response;
//
//    localparam SPI_TXDATA  = 3'd1;
//    localparam SPI_RXDATA  = 3'd0;
//    localparam SPI_STATUS  = 3'd2;
//    localparam SPI_SSREG   = 3'd4;
//    localparam TRDY_BIT    = 5;
//    localparam RRDY_BIT    = 6;
//
//    // --- Start Minimal Changes ---
//    // Assuming a standard Altera/Intel SPI IP:
//    // This is a common address for the baud rate divisor register.
//    // YOU MUST CONFIRM THIS ADDRESS AND THE WIDTH OF THE VALUE (16'd128)
//    // from the documentation of your `spi` core (`my_spi_system`).
//    localparam SPI_BAUD_REG = 3'd6; // **CHANGE THIS IF YOUR SPI CORE HAS A DIFFERENT BAUD_REG ADDRESS**
//    // --- End Minimal Changes ---
//
//    initial begin
//        cmd[0] = 8'h40; 
//        cmd[1] = 8'h00; 
//        cmd[2] = 8'h00; 
//        cmd[3] = 8'h00; 
//        cmd[4] = 8'h00; 
//        cmd[5] = 8'h95; 
//    end
//
//    // --- Start Minimal Changes ---
//    // Renamed state constants for better readability and to match new states
//    localparam STATE_INIT_DELAY         = 0;
//    localparam STATE_SET_SPI_BAUD_RATE  = 1; // NEW STATE
//    localparam STATE_CS_HIGH_DUMMY_CLKS = 2;
//    localparam STATE_SEND_DUMMY_FF      = 3; // Renamed from '2'
//    localparam STATE_ASSERT_CS_CMD0     = 4; // Renamed from '3'
//    localparam STATE_SEND_CMD0_BYTES    = 5; // Renamed from '4'
//    localparam STATE_WAIT_R1_RESPONSE   = 6; // NEW STATE, was '5' but re-purposed
//    localparam STATE_READ_R1_RESPONSE   = 7; // NEW STATE, was '6' but re-purposed
//    localparam STATE_PRINT_SPACE        = 8; // Renamed from '7'
//    localparam STATE_PRINT_RESPONSE     = 9; // Renamed from '8'
//    localparam STATE_DEASSERT_CS_DONE   = 10; // Renamed from '9'
//    // --- End Minimal Changes ---
//
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0) begin
//            uart_data <= 0;
//            uart_write <= 0;
//            Spi_selected <= 0;
//            bus_write_enable <= 0;
//            bus_read_enable <= 0;
//            // --- Start Minimal Changes ---
//            state <= STATE_INIT_DELAY; // Reset to the initial state
//            // --- End Minimal Changes ---
//            i <= 0;
//            delay_counter <= 0;
//            response <= 8'hFF;
//        end else begin
//            // defaults
//            uart_write <= 0;
//            bus_write_enable <= 0;
//            bus_read_enable <= 0;
//            Spi_selected <= 0;
//
//            case (state)
//                // Wait some time and print 'S'
//                STATE_INIT_DELAY: begin
//                    delay_counter <= delay_counter + 1;
//                    if (delay_counter == 32'd50_000_000) begin // 1s delay
//                        uart_data <= {24'd0, "S"};
//                        uart_write <= 1;
//                        delay_counter <= 0;
//                        // --- Start Minimal Changes ---
//                        state <= STATE_SET_SPI_BAUD_RATE; // Move to new state to set baud rate
//                        // --- End Minimal Changes ---
//                    end
//                end
//
//                // --- Start Minimal Changes ---
//                // NEW STATE: Set SPI Baud Rate for initialization (<= 400kHz)
//                STATE_SET_SPI_BAUD_RATE: begin
//                    Spi_selected <= 1'b1; // Engage SPI controller
//                    bus_write_enable <= 1'b1;
//                    bus_address <= SPI_BAUD_REG;
//                    bus_write_data <= 16'd128; // Divisor: 50MHz / 128 = 390.625kHz (good for init)
//                                              // **ADJUST THIS DIVISOR IF 16'd128 IS NOT APPROPRIATE**
//                                              // **(e.g., if your clock is not 50MHz or core needs different value)**
//                    state <= STATE_CS_HIGH_DUMMY_CLKS; // Move to sending dummy clocks
//                end
//                // --- End Minimal Changes ---
//
//
//                // Send 80 dummy clocks (10 bytes of 0xFF) with CS high
//                STATE_CS_HIGH_DUMMY_CLKS: begin // Renamed from '1'
//                    Spi_selected <= 1'b1;
//                    bus_write_enable <= 1'b1;
//                    bus_address <= SPI_SSREG;
//                    bus_write_data <= 16'd0; // deassert CS (SS_n high)
//                    i <= 0;
//                    state <= STATE_SEND_DUMMY_FF; // Renamed from '2'
//                end
//
//                STATE_SEND_DUMMY_FF: begin // Renamed from '2'
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1;
//                    bus_address <= SPI_STATUS;
//                    if (spi_read_data_wire[TRDY_BIT]) begin
//                        Spi_selected <= 1'b1;
//                        bus_write_enable <= 1'b1;
//                        bus_address <= SPI_TXDATA;
//                        bus_write_data <= 16'hFF;
//                        i <= i + 1;
//                        if (i == 10) state <= STATE_ASSERT_CS_CMD0; // Renamed from '3'
//                    end
//                end
//
//                // Assert CS low and send CMD0
//                STATE_ASSERT_CS_CMD0: begin // Renamed from '3'
//                    Spi_selected <= 1'b1;
//                    bus_write_enable <= 1'b1;
//                    bus_address <= SPI_SSREG;
//                    bus_write_data <= 16'd1; // select slave 0 -> CS low (assuming slave 0 is your SD card)
//                    i <= 0;
//                    state <= STATE_SEND_CMD0_BYTES; // Renamed from '4'
//                end
//
//                // Wait TRDY, send 6 CMD0 bytes
//                STATE_SEND_CMD0_BYTES: begin // Renamed from '4'
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1;
//                    bus_address <= SPI_STATUS;
//                    if (spi_read_data_wire[TRDY_BIT]) begin
//                        Spi_selected <= 1'b1;
//                        bus_write_enable <= 1'b1;
//                        bus_address <= SPI_TXDATA;
//                        bus_write_data <= {8'd0, cmd[i]};
//                        if (i == 5) begin
//                            i <= 0; // Reset i for next use (e.g., polling for response)
//                            // --- Start Minimal Changes ---
//                            state <= STATE_WAIT_R1_RESPONSE; // Go to new polling state
//                            // --- End Minimal Changes ---
//                        end else i <= i + 1;
//                    end
//                end
//
//                // --- Start Minimal Changes ---
//                // NEW STATE: Poll for R1 response after CMD0, sending dummy 0xFF
//                STATE_WAIT_R1_RESPONSE: begin
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1; // Keep read_enable high to potentially catch RRDY
//                    bus_address <= SPI_STATUS; // Check status first
//
//                    if (spi_read_data_wire[TRDY_BIT]) begin // If ready to send dummy
//                        bus_write_enable <= 1'b1;
//                        bus_address <= SPI_TXDATA;
//                        bus_write_data <= 16'hFF; // Send dummy byte to clock in response
//
//                        // After sending dummy, check if RX buffer has data
//                        bus_address <= SPI_STATUS; // Re-read status to check RRDY_BIT after potential TX
//                        if (spi_read_data_wire[RRDY_BIT]) begin // If RX data is ready
//                            state <= STATE_READ_R1_RESPONSE;
//                        end else if (i == 100) begin // Timeout after X dummy bytes (e.g., 100 bytes = 800 clocks)
//                            response <= 8'hFF; // Indicate timeout with FF
//                            state <= STATE_PRINT_SPACE; // Move to printing
//                        end else begin
//                            i <= i + 1; // Increment counter for timeout
//                        end
//                    end
//                end
//
//                // NEW STATE: Read the R1 response
//                STATE_READ_R1_RESPONSE: begin
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1;
//                    bus_address <= SPI_RXDATA;
//                    response <= spi_read_data_wire[7:0]; // Read the actual response
//                    state <= STATE_PRINT_SPACE;
//                end
//                // --- End Minimal Changes ---
//
//
//                // Print response
//                STATE_PRINT_SPACE: begin // Renamed from '7'
//                    uart_data <= {24'd0, " "};
//                    uart_write <= 1;
//                    state <= STATE_PRINT_RESPONSE; // Renamed from '8'
//                end
//
//                STATE_PRINT_RESPONSE: begin // Renamed from '8'
//                    // --- Start Minimal Changes ---
//                    // Improved response printing for better debugging
//                    if (response == 8'h01) begin
//                        uart_data <= {24'd0, "1"}; // Print '1' if R1 is 0x01
//                    end else if (response == 8'hFF) begin
//                        uart_data <= {24'd0, "F"}; // Print 'F' if R1 is 0xFF (timeout or no response)
//                    end else begin
//                        uart_data <= {24'd0, "X"}; // Print 'X' for any other response
//                    end
//                    // --- End Minimal Changes ---
//                    uart_write <= 1;
//                    state <= STATE_DEASSERT_CS_DONE; // Renamed from '9'
//                end
//
//                STATE_DEASSERT_CS_DONE: begin // Renamed from '9'
//                    Spi_selected <= 1'b1;
//                    bus_write_enable <= 1'b1;
//                    bus_address <= SPI_SSREG;
//                    bus_write_data <= 16'd0; // CS high
//                    state <= STATE_DEASSERT_CS_DONE; // Stay in this state (done)
//                end
//            endcase
//        end
//    end
//
//    // ================================================================
//    // SPI core
//    // ================================================================
//    spi my_spi_system (
//        .clk_clk(CLOCK_50),
//        .reset_reset_n(KEY0),
//        .spi_0_spi_control_port_chipselect (Spi_selected),
//        .spi_0_spi_control_port_address    (bus_address),
//        .spi_0_spi_control_port_read_n     (~(bus_read_enable && Spi_selected)),
//        .spi_0_spi_control_port_readdata   (spi_read_data_wire),
//        .spi_0_spi_control_port_write_n    (~(bus_write_enable && Spi_selected)),
//        .spi_0_spi_control_port_writedata  (bus_write_data),
//        .spi_0_external_MISO(SPI_MISO),
//        .spi_0_external_MOSI(SPI_MOSI),
//        .spi_0_external_SCLK(SPI_SCLK),
//        .spi_0_external_SS_n(SPI_SS_n)
//    );
//
//    assign LEDR0 = Spi_selected;
//
//endmodule






//===========================================================
// Minimal DE1 SD Card SPI-like test (Cyclone II Starter)
//===========================================================
//module cpu_on_board (
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    // --- SD card pins ---
//    (* chip_pin = "V20" *) output wire SD_CLK,   // SD_CLK
//    (* chip_pin = "Y20" *) inout  wire SD_CMD,   // SD_CMD
//    (* chip_pin = "W20" *) inout  wire SD_DAT0,  // SD_DAT0
//    (* chip_pin = "U20" *) output wire SD_DAT3   // optional CS line
//);
//
//    //=======================================================
//    // Internal reset and LED blink
//    //=======================================================
//    wire reset_n = KEY0;
//    reg [23:0] blink_counter;
//
//    always @(posedge CLOCK_50 or negedge reset_n)
//        if (!reset_n)
//            blink_counter <= 0;
//        else
//            blink_counter <= blink_counter + 1'b1;
//
//    assign LEDR0 = blink_counter[23];
//
//    //=======================================================
//    // UART for debug output
//    //=======================================================
//    reg  [31:0] uart_data;
//    reg         uart_write;
//
//    jtag_uart_system uart0 (
//        .clk_clk(CLOCK_50),
//        .reset_reset_n(reset_n),
//        .jtag_uart_0_avalon_jtag_slave_address(1'b0),
//        .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
//        .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
//        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
//        .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
//    );
//
//    //=======================================================
//    // Simple SD controller wiring (mimic SOPC signals)
//    //=======================================================
//    reg [1:0]  sd_address;
//    reg        sd_chipselect;
//    reg        sd_write_n;
//    reg [15:0] sd_writedata;
//    wire [15:0] sd_readdata_cmd;
//    wire [15:0] sd_readdata_dat;
//    wire        sd_out_clk;
//
//    // --- SD_CLK ---
//    SD_CLK sd_clk_inst (
//        .address(sd_address),
//        .chipselect(sd_chipselect),
//        .clk(CLOCK_50),
//        .reset_n(reset_n),
//        .write_n(sd_write_n),
//        .writedata(sd_writedata),
//        .out_port(sd_out_clk)
//    );
//    assign SD_CLK = sd_out_clk;
//
//    // --- SD_CMD ---
//    SD_CMD sd_cmd_inst (
//        .address(sd_address),
//        .chipselect(sd_chipselect),
//        .clk(CLOCK_50),
//        .reset_n(reset_n),
//        .write_n(sd_write_n),
//        .writedata(sd_writedata),
//        .bidir_port(SD_CMD),
//        .readdata(sd_readdata_cmd)
//    );
//
//    // --- SD_DAT0 ---
//    SD_DAT sd_dat_inst (
//        .address(sd_address),
//        .chipselect(sd_chipselect),
//        .clk(CLOCK_50),
//        .reset_n(reset_n),
//        .write_n(sd_write_n),
//        .writedata(sd_writedata),
//        .bidir_port(SD_DAT0),
//        .readdata(sd_readdata_dat)
//    );
//
//    //=======================================================
//    // Simple test sequence
//    //=======================================================
//    reg [3:0]  state;
//    reg [31:0] counter;
//
//    always @(posedge CLOCK_50 or negedge reset_n) begin
//        if (!reset_n) begin
//            state <= 0;
//            counter <= 0;
//            uart_write <= 0;
//            sd_chipselect <= 0;
//            sd_write_n <= 1;
//            sd_writedata <= 16'd0;
//            sd_address <= 2'd0;
//        end else begin
//            uart_write <= 0;
//            counter <= counter + 1;
//
//            case (state)
//                0: begin
//                    if (counter == 32'd50_000_000) begin // 1 sec
//                        uart_data <= {24'd0, "S"};
//                        uart_write <= 1;
//                        counter <= 0;
//                        state <= 1;
//                    end
//                end
//                1: begin
//                    uart_data <= {24'd0, "/"};
//                    uart_write <= 1;
//                    sd_chipselect <= 1'b1;
//                    sd_write_n <= 1'b0;
//                    sd_writedata <= 16'hFF; // drive clock pulses
//                    sd_address <= 2'd0;
//                    state <= 2;
//                end
//                2: begin
//                    sd_chipselect <= 1'b0;
//                    sd_write_n <= 1'b1;
//                    uart_data <= {24'd0, "0"};
//                    uart_write <= 1;
//                    state <= 3;
//                end
//                3: begin
//                    // stop
//                    state <= 3;
//                end
//            endcase
//        end
//    end
//
//endmodule


////===========================================================
//// Minimal DE1 SD Card SPI-like test (Cyclone II Starter)
////===========================================================
//
//module cpu_on_board (
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    // --- SD card pins ---
//    (* chip_pin = "V20" *) output wire SD_CLK,   // SD_CLK
//    (* chip_pin = "Y20" *) inout  wire SD_CMD,   // SD_CMD
//    (* chip_pin = "W20" *) inout  wire SD_DAT0,  // SD_DAT0
//    (* chip_pin = "U20" *) output wire SD_DAT3   // optional CS line
//);
//
//    //=======================================================
//    // Internal reset and LED blink
//    //=======================================================
//    wire reset_n = KEY0;
//    reg [23:0] blink_counter;
//
//    always @(posedge CLOCK_50 or negedge reset_n)
//        if (!reset_n)
//            blink_counter <= 0;
//        else
//            blink_counter <= blink_counter + 1'b1;
//
//    assign LEDR0 = blink_counter[23];
//
//    //=======================================================
//    // UART for debug output
//    //=======================================================
//    reg  [31:0] uart_data;
//    reg         uart_write;
//
//    jtag_uart_system uart0 (
//        .clk_clk(CLOCK_50),
//        .reset_reset_n(reset_n),
//        .jtag_uart_0_avalon_jtag_slave_address(1'b0),
//        .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
//        .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
//        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
//        .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
//    );
//
//    //=======================================================
//    // Simple SD controller wiring (mimic SOPC signals)
//    //=======================================================
//    reg [1:0]  sd_address;
//    reg        sd_chipselect;
//    reg        sd_write_n;
//    reg [15:0] sd_writedata;
//    wire [15:0] sd_readdata_cmd;
//    wire [15:0] sd_readdata_dat;
//    wire        sd_out_clk;
//
//    // --- SD_CLK ---
//    SD_CLK sd_clk_inst (
//        .address(sd_address),
//        .chipselect(sd_chipselect),
//        .clk(CLOCK_50),
//        .reset_n(reset_n),
//        .write_n(sd_write_n),
//        .writedata(sd_writedata),
//        .out_port(sd_out_clk)
//    );
//    assign SD_CLK = sd_out_clk;
//
//    // --- SD_CMD ---
//    SD_CMD sd_cmd_inst (
//        .address(sd_address),
//        .chipselect(sd_chipselect),
//        .clk(CLOCK_50),
//        .reset_n(reset_n),
//        .write_n(sd_write_n),
//        .writedata(sd_writedata),
//        .bidir_port(SD_CMD),
//        .readdata(sd_readdata_cmd)
//    );
//
//    // --- SD_DAT0 ---
//    SD_DAT sd_dat_inst (
//        .address(sd_address),
//        .chipselect(sd_chipselect),
//        .clk(CLOCK_50),
//        .reset_n(reset_n),
//        .write_n(sd_write_n),
//        .writedata(sd_writedata),
//        .bidir_port(SD_DAT0),
//        .readdata(sd_readdata_dat)
//    );
//
//    //=======================================================
//    // Simple test sequence
//    //=======================================================
//    reg [3:0]  state;
//    reg [31:0] counter;
//
//    always @(posedge CLOCK_50 or negedge reset_n) begin
//        if (!reset_n) begin
//            state <= 0;
//            counter <= 0;
//            uart_write <= 0;
//            sd_chipselect <= 0;
//            sd_write_n <= 1;
//            sd_writedata <= 16'd0;
//            sd_address <= 2'd0;
//        end else begin
//            uart_write <= 0;
//            counter <= counter + 1;
//
//            case (state)
//                0: begin
//                    if (counter == 32'd50_000_000) begin // 1 sec
//                        uart_data <= {24'd0, "S"};
//                        uart_write <= 1;
//                        counter <= 0;
//                        state <= 1;
//                    end
//                end
//                1: begin
//                    uart_data <= {24'd0, "/"};
//                    uart_write <= 1;
//                    sd_chipselect <= 1'b1;
//                    sd_write_n <= 1'b0;
//                    sd_writedata <= 16'hFF; // drive clock pulses
//                    sd_address <= 2'd0;
//                    state <= 2;
//                end
//                2: begin
//                    sd_chipselect <= 1'b0;
//                    sd_write_n <= 1'b1;
//                    uart_data <= {24'd0, "0"};
//                    uart_write <= 1;
//                    state <= 3;
//                end
//                3: begin
//                    // stop
//                    state <= 3;
//                end
//            endcase
//        end
//    end
//
//endmodule
//



////===========================================================
//// DE1 SD Card SPI-like test with CMD0 initialization
////===========================================================
//module cpu_on_board (
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    // --- SD card pins ---
//    (* chip_pin = "V20" *) output wire SD_CLK,
//    (* chip_pin = "Y20" *) inout  wire SD_CMD,
//    (* chip_pin = "W20" *) inout  wire SD_DAT0,
//    (* chip_pin = "U20" *) output wire SD_DAT3
//);
//
////=======================================================
//// Internal reset and LED blink
////=======================================================
//wire reset_n = KEY0;
//reg [23:0] blink_counter;
//
//always @(posedge CLOCK_50 or negedge reset_n)
//    if (!reset_n)
//        blink_counter <= 0;
//    else
//        blink_counter <= blink_counter + 1'b1;
//
//assign LEDR0 = blink_counter[23];
//
////=======================================================
//// UART for debug output
////=======================================================
//reg  [31:0] uart_data;
//reg         uart_write;
//
//jtag_uart_system uart0 (
//    .clk_clk(CLOCK_50),
//    .reset_reset_n(reset_n),
//    .jtag_uart_0_avalon_jtag_slave_address(1'b0),
//    .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
//    .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
//    .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
//    .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
//);
//
////=======================================================
//// SD card SPI signals (simplified)
////=======================================================
//reg [1:0]  sd_address;
//reg        sd_chipselect;
//reg        sd_write_n;
//reg [15:0] sd_writedata;
//wire [15:0] sd_readdata_cmd;
//wire [15:0] sd_readdata_dat;
//wire        sd_out_clk;
//
//SD_CLK sd_clk_inst (
//    .address(sd_address),
//    .chipselect(sd_chipselect),
//    .clk(CLOCK_50),
//    .reset_n(reset_n),
//    .write_n(sd_write_n),
//    .writedata(sd_writedata),
//    .out_port(sd_out_clk)
//);
//assign SD_CLK = sd_out_clk;
//
//SD_CMD sd_cmd_inst (
//    .address(sd_address),
//    .chipselect(sd_chipselect),
//    .clk(CLOCK_50),
//    .reset_n(reset_n),
//    .write_n(sd_write_n),
//    .writedata(sd_writedata),
//    .bidir_port(SD_CMD),
//    .readdata(sd_readdata_cmd)
//);
//
//SD_DAT sd_dat_inst (
//    .address(sd_address),
//    .chipselect(sd_chipselect),
//    .clk(CLOCK_50),
//    .reset_n(reset_n),
//    .write_n(sd_write_n),
//    .writedata(sd_writedata),
//    .bidir_port(SD_DAT0),
//    .readdata(sd_readdata_dat)
//);
//
////=======================================================
//// SD card test state machine
////=======================================================
//reg [3:0]  state;
//reg [31:0] counter;
//
//always @(posedge CLOCK_50 or negedge reset_n) begin
//    if (!reset_n) begin
//        state <= 0;
//        counter <= 0;
//        uart_write <= 0;
//        sd_chipselect <= 0;
//        sd_write_n <= 1;
//        sd_writedata <= 16'd0;
//        sd_address <= 2'd0;
//    end else begin
//        uart_write <= 0;
//        counter <= counter + 1;
//
//        case (state)
//            0: begin
//                // Wait 1 second before starting
//                if (counter == 32'd50_000_000) begin
//                    uart_data <= {24'd0, "S"}; uart_write <= 1;
//                    counter <= 0;
//                    state <= 1;
//                end
//            end
//            1: begin
//                // Send SD CMD0 (GO_IDLE_STATE) to reset card
//                uart_data <= {24'd0, "C"}; uart_write <= 1;
//                sd_chipselect <= 1;
//                sd_write_n <= 0;
//                sd_writedata <= 16'h4000; // Example: SPI-like CMD0
//                sd_address <= 2'd0;
//                counter <= 0;
//                state <= 2;
//            end
//            2: begin
//                // Release SD chip select
//                sd_chipselect <= 0;
//                sd_write_n <= 1;
//                uart_data <= {24'd0, "0"}; uart_write <= 1;
//                state <= 3;
//            end
//            3: begin
//                // Idle
//                state <= 3;
//            end
//        endcase
//    end
//end
//
//endmodule




////===========================================================
//// DE1 SD Card SPI-like test with read of first 512 bytes
////===========================================================
//module cpu_on_board (
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    (* chip_pin = "V20" *) output wire SD_CLK,
//    (* chip_pin = "Y20" *) inout  wire SD_CMD,
//    (* chip_pin = "W20" *) inout  wire SD_DAT0,
//    (* chip_pin = "U20" *) output wire SD_DAT3
//);
//
//wire reset_n = KEY0;
//reg [23:0] blink_counter;
//
//always @(posedge CLOCK_50 or negedge reset_n)
//    if (!reset_n)
//        blink_counter <= 0;
//    else
//        blink_counter <= blink_counter + 1'b1;
//
//assign LEDR0 = blink_counter[23];
//
//reg  [31:0] uart_data;
//reg         uart_write;
//
//jtag_uart_system uart0 (
//    .clk_clk(CLOCK_50),
//    .reset_reset_n(reset_n),
//    .jtag_uart_0_avalon_jtag_slave_address(1'b0),
//    .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
//    .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
//    .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
//    .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
//);
//
//reg [1:0]  sd_address;
//reg        sd_chipselect;
//reg        sd_write_n;
//reg [15:0] sd_writedata;
//wire [15:0] sd_readdata_cmd;
//wire [15:0] sd_readdata_dat;
//wire        sd_out_clk;
//
//SD_CLK sd_clk_inst (
//    .address(sd_address),
//    .chipselect(sd_chipselect),
//    .clk(CLOCK_50),
//    .reset_n(reset_n),
//    .write_n(sd_write_n),
//    .writedata(sd_writedata),
//    .out_port(sd_out_clk)
//);
//assign SD_CLK = sd_out_clk;
//
//SD_CMD sd_cmd_inst (
//    .address(sd_address),
//    .chipselect(sd_chipselect),
//    .clk(CLOCK_50),
//    .reset_n(reset_n),
//    .write_n(sd_write_n),
//    .writedata(sd_writedata),
//    .bidir_port(SD_CMD),
//    .readdata(sd_readdata_cmd)
//);
//
//SD_DAT sd_dat_inst (
//    .address(sd_address),
//    .chipselect(sd_chipselect),
//    .clk(CLOCK_50),
//    .reset_n(reset_n),
//    .write_n(sd_write_n),
//    .writedata(sd_writedata),
//    .bidir_port(SD_DAT0),
//    .readdata(sd_readdata_dat)
//);
//
////=======================================================
//// SD card read test
////=======================================================
//reg [3:0] state;
//reg [31:0] counter;
//reg [8:0] byte_index; // 0-511
//
//always @(posedge CLOCK_50 or negedge reset_n) begin
//    if (!reset_n) begin
//        state <= 0;
//        counter <= 0;
//        uart_write <= 0;
//        sd_chipselect <= 0;
//        sd_write_n <= 1;
//        sd_writedata <= 16'd0;
//        sd_address <= 2'd0;
//        byte_index <= 0;
//    end else begin
//        uart_write <= 0;
//        counter <= counter + 1;
//
//        case (state)
//            0: begin
//                if (counter == 32'd50_000_000) begin
//                    uart_data <= {24'd0, "S"}; uart_write <= 1;
//                    counter <= 0;
//                    state <= 1;
//                end
//            end
//            1: begin
//                // CMD0: reset card
//                uart_data <= {24'd0, "C"}; uart_write <= 1;
//                sd_chipselect <= 1;
//                sd_write_n <= 0;
//                sd_writedata <= 16'h4000; // simplified SPI CMD0
//                sd_address <= 2'd0;
//                counter <= 0;
//                state <= 2;
//            end
//            2: begin
//                sd_chipselect <= 0;
//                sd_write_n <= 1;
//                uart_data <= {24'd0, "0"}; uart_write <= 1;
//                counter <= 0;
//                state <= 3;
//            end
//            3: begin
//                // CMD17: read single block (block 0)
//                uart_data <= {24'd0, "R"}; uart_write <= 1;
//                sd_chipselect <= 1;
//                sd_write_n <= 0;
//                sd_writedata <= 16'h5117; // simplified SPI-like CMD17
//                sd_address <= 2'd0;
//                counter <= 0;
//                byte_index <= 0;
//                state <= 4;
//            end
//            4: begin
//                sd_chipselect <= 0;
//                sd_write_n <= 1;
//                // Read 512 bytes (simplified)
//                if (byte_index < 512) begin
//                    uart_data <= {24'd0, sd_readdata_dat[7:0]}; // read low byte
//                    uart_write <= 1;
//                    byte_index <= byte_index + 1;
//                end else begin
//                    uart_data <= {24'd0, "D"}; uart_write <= 1; // Done
//                    state <= 5;
//                end
//            end
//            5: begin
//                state <= 5; // idle
//            end
//        endcase
//    end
//end
//
//endmodule


//===========================================================
// DE1 SD Card SPI-like test: read first 512-byte block
//===========================================================
module cpu_on_board (
    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
    (* chip_pin = "R20"     *) output wire LEDR0,

    (* chip_pin = "V20" *) output wire SD_CLK,
    (* chip_pin = "Y20" *) inout  wire SD_CMD,
    (* chip_pin = "W20" *) inout  wire SD_DAT0,
    (* chip_pin = "U20" *) output wire SD_DAT3
);

wire reset_n = KEY0;
reg [23:0] blink_counter;

always @(posedge CLOCK_50 or negedge reset_n)
    if (!reset_n)
        blink_counter <= 0;
    else
        blink_counter <= blink_counter + 1'b1;

assign LEDR0 = blink_counter[23];

reg  [31:0] uart_data;
reg         uart_write;

jtag_uart_system uart0 (
    .clk_clk(CLOCK_50),
    .reset_reset_n(reset_n),
    .jtag_uart_0_avalon_jtag_slave_address(1'b0),
    .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
    .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
    .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
    .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
);

//=======================================================
// SD card SPI signals
//=======================================================
reg [1:0]  sd_address;
reg        sd_chipselect;
reg        sd_write_n;
reg [15:0] sd_writedata;
wire [15:0] sd_readdata_cmd;
wire [15:0] sd_readdata_dat;
wire        sd_out_clk;

SD_CLK sd_clk_inst (
    .address(sd_address),
    .chipselect(sd_chipselect),
    .clk(CLOCK_50),
    .reset_n(reset_n),
    .write_n(sd_write_n),
    .writedata(sd_writedata),
    .out_port(sd_out_clk)
);
assign SD_CLK = sd_out_clk;

SD_CMD sd_cmd_inst (
    .address(sd_address),
    .chipselect(sd_chipselect),
    .clk(CLOCK_50),
    .reset_n(reset_n),
    .write_n(sd_write_n),
    .writedata(sd_writedata),
    .bidir_port(SD_CMD),
    .readdata(sd_readdata_cmd)
);

SD_DAT sd_dat_inst (
    .address(sd_address),
    .chipselect(sd_chipselect),
    .clk(CLOCK_50),
    .reset_n(reset_n),
    .write_n(sd_write_n),
    .writedata(sd_writedata),
    .bidir_port(SD_DAT0),
    .readdata(sd_readdata_dat)
);

//=======================================================
// SD card read state machine
//=======================================================
reg [3:0] state;
reg [31:0] counter;
reg [8:0] byte_index;
reg [7:0] sd_byte;

always @(posedge CLOCK_50 or negedge reset_n) begin
    if (!reset_n) begin
        state <= 0;
        counter <= 0;
        uart_write <= 0;
        sd_chipselect <= 0;
        sd_write_n <= 1;
        sd_writedata <= 16'd0;
        sd_address <= 2'd0;
        byte_index <= 0;
        sd_byte <= 0;
    end else begin
        uart_write <= 0;
        counter <= counter + 1;

        case (state)
            0: begin
                // wait 1 second before starting
                if (counter == 32'd50_000_000) begin
                    uart_data <= {24'd0, "S"}; uart_write <= 1;
                    counter <= 0;
                    state <= 1;
                end
            end
            1: begin
                // CMD0: reset card
                uart_data <= {24'd0, "C"}; uart_write <= 1;
                sd_chipselect <= 1;
                sd_write_n <= 0;
                sd_writedata <= 16'h4000; // simplified SPI CMD0
                sd_address <= 2'd0;
                state <= 2;
            end
            2: begin
                // release chip select, CMD0 response
                sd_chipselect <= 0;
                sd_write_n <= 1;
                uart_data <= {24'd0, "0"}; uart_write <= 1;
                counter <= 0;
                state <= 3;
            end
            3: begin
                // CMD17: read block 0
                uart_data <= {24'd0, "R"}; uart_write <= 1;
                sd_chipselect <= 1;
                sd_write_n <= 0;
                sd_writedata <= 16'h5117; // simplified SPI CMD17
                sd_address <= 2'd0;
                byte_index <= 0;
                state <= 4;
            end
            4: begin
                // wait for start token 0xFE
                if (sd_readdata_dat[7:0] == 8'hFE) begin
                    byte_index <= 0;
                    state <= 5;
                end
            end
            5: begin
                // read 512 bytes
                if (byte_index < 512) begin
                    sd_byte <= sd_readdata_dat[7:0];
                    uart_data <= {24'd0, sd_byte};
                    uart_write <= 1;
                    byte_index <= byte_index + 1;
                end else begin
                    state <= 6; // done
                end
            end
            6: begin
                // done reading
                uart_data <= {24'd0, "D"}; uart_write <= 1;
                state <= 6; // idle
            end
        endcase
    end
end

endmodule
