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


////===========================================================
//// DE1 SD Card SPI-like test: read first 512-byte block
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
////=======================================================
//// SD card SPI signals
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
//// SD card read state machine
////=======================================================
//reg [3:0] state;
//reg [31:0] counter;
//reg [8:0] byte_index;
//reg [7:0] sd_byte;
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
//        sd_byte <= 0;
//    end else begin
//        uart_write <= 0;
//        counter <= counter + 1;
//
//        case (state)
//            0: begin
//                // wait 1 second before starting
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
//                state <= 2;
//            end
//            2: begin
//                // release chip select, CMD0 response
//                sd_chipselect <= 0;
//                sd_write_n <= 1;
//                uart_data <= {24'd0, "0"}; uart_write <= 1;
//                counter <= 0;
//                state <= 3;
//            end
//            3: begin
//                // CMD17: read block 0
//                uart_data <= {24'd0, "R"}; uart_write <= 1;
//                sd_chipselect <= 1;
//                sd_write_n <= 0;
//                sd_writedata <= 16'h5117; // simplified SPI CMD17
//                sd_address <= 2'd0;
//                byte_index <= 0;
//                state <= 4;
//            end
//            4: begin
//                // wait for start token 0xFE
//                if (sd_readdata_dat[7:0] == 8'hFE) begin
//                    byte_index <= 0;
//                    state <= 5;
//                end
//            end
//            5: begin
//                // read 512 bytes
//                if (byte_index < 512) begin
//                    sd_byte <= sd_readdata_dat[7:0];
//                    uart_data <= {24'd0, sd_byte};
//                    uart_write <= 1;
//                    byte_index <= byte_index + 1;
//                end else begin
//                    state <= 6; // done
//                end
//            end
//            6: begin
//                // done reading
//                uart_data <= {24'd0, "D"}; uart_write <= 1;
//                state <= 6; // idle
//            end
//        endcase
//    end
//end
//
//endmodule



////===========================================================
//// DE1 SD Card SPI Bit-banged Reader: Read 1st 512-byte block
////===========================================================
//module cpu_on_board (
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    (* chip_pin = "V20" *) output reg SD_CLK,
//    (* chip_pin = "Y20" *) inout  wire SD_CMD,
//    (* chip_pin = "W20" *) inout  wire SD_DAT0,
//    (* chip_pin = "U20" *) output wire SD_DAT3
//);
//
////=======================================================
//// LED blink
////=======================================================
//wire reset_n = KEY0;
//reg [23:0] blink_counter;
//always @(posedge CLOCK_50 or negedge reset_n)
//    if (!reset_n)
//        blink_counter <= 0;
//    else
//        blink_counter <= blink_counter + 1'b1;
//
//assign LEDR0 = blink_counter[23];
//
////=======================================================
//// UART
////=======================================================
//reg  [31:0] uart_data;
//reg         uart_write;
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
//// SPI signals
////=======================================================
//reg sd_cmd_out;
//reg sd_cmd_oe;
//assign SD_CMD = sd_cmd_oe ? sd_cmd_out : 1'bz;
//wire sd_cmd_in = SD_CMD;
//
//wire sd_data_in = SD_DAT0; // read data from SD
//
//assign SD_DAT3 = 1'b1; // deselect chip (always high)
//
////=======================================================
//// SPI / SD state machine
////=======================================================
//reg [5:0] state;
//reg [31:0] counter;
//reg [8:0] bit_index;
//reg [8:0] byte_index;
//reg [47:0] shift_reg;
//reg [7:0] read_byte;
//reg [8:0] byte_count;
//reg [7:0] response;
//reg start_token_received;
//
//always @(posedge CLOCK_50 or negedge reset_n) begin
//    if (!reset_n) begin
//        SD_CLK <= 0;
//        sd_cmd_out <= 1;
//        sd_cmd_oe <= 1;
//        state <= 0;
//        counter <= 0;
//        bit_index <= 0;
//        byte_index <= 0;
//        byte_count <= 0;
//        uart_write <= 0;
//        response <= 8'hFF;
//        start_token_received <= 0;
//    end else begin
//        uart_write <= 0;
//        counter <= counter + 1;
//
//        case(state)
//            0: begin
//                // wait some time and then start CMD0
//                if(counter > 32'd5_000_000) begin
//                    uart_data <= {24'd0,"S"}; uart_write <= 1;
//                    counter <= 0;
//                    // CMD0: GO_IDLE_STATE
//                    // CMD format: 0x40 | cmd_index, 32-bit arg, 8-bit CRC
//                    // We'll just use fixed 48-bit CMD0: 0x40_00_00_00_00_95
//                    shift_reg <= 48'h400000000095;
//                    bit_index <= 47;
//                    SD_CLK <= 0;
//                    sd_cmd_oe <= 1;
//                    state <= 1;
//                end
//            end
//            1: begin
//                // Shift out CMD0
//                SD_CLK <= ~SD_CLK;
//                if(SD_CLK) begin
//                    sd_cmd_out <= shift_reg[bit_index];
//                    if(bit_index == 0) begin
//                        state <= 2;
//                        bit_index <= 0;
//                    end else begin
//                        bit_index <= bit_index - 1;
//                    end
//                end
//            end
//            2: begin
//                // Release CMD line and wait for response
//                sd_cmd_oe <= 0;
//                SD_CLK <= ~SD_CLK;
//                // wait for response (0x01) from SD card
//                if(sd_data_in == 0) begin
//                    response <= 8'h01;
//                    uart_data <= {24'd0,"C"}; uart_write <= 1;
//                    // prepare CMD17 to read block 0
//                    shift_reg <= 48'h5117000000FF; // CMD17 + addr 0 + CRC
//                    bit_index <= 47;
//                    SD_CLK <= 0;
//                    sd_cmd_oe <= 1;
//                    state <= 3;
//                end
//            end
//            3: begin
//                // Shift out CMD17
//                SD_CLK <= ~SD_CLK;
//                if(SD_CLK) begin
//                    sd_cmd_out <= shift_reg[bit_index];
//                    if(bit_index == 0) begin
//                        state <= 4;
//                        sd_cmd_oe <= 0;
//                        byte_count <= 0;
//                        start_token_received <= 0;
//                    end else begin
//                        bit_index <= bit_index - 1;
//                    end
//                end
//            end
//            4: begin
//                // Wait for start token 0xFE
//                SD_CLK <= ~SD_CLK;
//                if(SD_CLK) begin
//                    read_byte <= {read_byte[6:0], sd_data_in};
//                    bit_index <= bit_index + 1;
//                    if(bit_index == 7) begin
//                        if(read_byte == 8'hFE) start_token_received <= 1;
//                        bit_index <= 0;
//                    end
//                    if(start_token_received) begin
//                        byte_index <= 0;
//                        state <= 5;
//                    end
//                end
//            end
//            5: begin
//                // Read 512 bytes
//                SD_CLK <= ~SD_CLK;
//                if(SD_CLK) begin
//                    read_byte <= {read_byte[6:0], sd_data_in};
//                    bit_index <= bit_index + 1;
//                    if(bit_index == 7) begin
//                        uart_data <= {24'd0, read_byte};
//                        uart_write <= 1;
//                        byte_index <= byte_index + 1;
//                        bit_index <= 0;
//                        if(byte_index == 511) state <= 6;
//                    end
//                end
//            end
//            6: begin
//                // Done
//                uart_data <= {24'd0,"D"}; uart_write <= 1;
//                state <= 6;
//            end
//        endcase
//    end
//end
//
//endmodule




////===========================================================
//// DE1 SD Card SPI Reader (with proper 400 kHz SPI clock)
////===========================================================
//module cpu_on_board (
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    (* chip_pin = "V20" *) output reg SD_CLK,
//    (* chip_pin = "Y20" *) inout  wire SD_CMD,
//    (* chip_pin = "W20" *) inout  wire SD_DAT0,
//    (* chip_pin = "U20" *) output wire SD_DAT3
//);
//
////=======================================================
//// LED blink
////=======================================================
//wire reset_n = KEY0;
//reg [23:0] blink_counter;
//always @(posedge CLOCK_50 or negedge reset_n)
//    if (!reset_n) blink_counter <= 0;
//    else blink_counter <= blink_counter + 1'b1;
//assign LEDR0 = blink_counter[23];
//
////=======================================================
//// UART
////=======================================================
//reg  [31:0] uart_data;
//reg         uart_write;
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
//// SPI signals
////=======================================================
//reg sd_cmd_out;
//reg sd_cmd_oe;
//assign SD_CMD = sd_cmd_oe ? sd_cmd_out : 1'bz;
//wire sd_cmd_in = SD_CMD;
//wire sd_data_in = SD_DAT0;
//assign SD_DAT3 = 1'b1; // deselect chip
//
////=======================================================
//// SPI clock divider (~400 kHz)
////=======================================================
//reg [6:0] clk_div;
//reg spi_clk_en;
//always @(posedge CLOCK_50 or negedge reset_n) begin
//    if(!reset_n) begin
//        clk_div <= 0;
//        spi_clk_en <= 0;
//    end else begin
//        if(clk_div == 62) begin  // 50MHz / 125 -> 400kHz
//            clk_div <= 0;
//            spi_clk_en <= 1;
//        end else begin
//            clk_div <= clk_div + 1;
//            spi_clk_en <= 0;
//        end
//    end
//end
//
////=======================================================
//// SD bit-banged SPI state machine
////=======================================================
//reg [5:0] state;
//reg [5:0] bit_index;
//reg [8:0] byte_index;
//reg [47:0] shift_reg;
//reg [7:0] read_byte;
//reg [8:0] byte_count;
//reg [7:0] response;
//reg start_token_received;
//
//always @(posedge CLOCK_50 or negedge reset_n) begin
//    if(!reset_n) begin
//        SD_CLK <= 0;
//        sd_cmd_out <= 1;
//        sd_cmd_oe <= 1;
//        state <= 0;
//        bit_index <= 0;
//        byte_index <= 0;
//        byte_count <= 0;
//        uart_write <= 0;
//        response <= 8'hFF;
//        start_token_received <= 0;
//    end else if(spi_clk_en) begin
//        uart_write <= 0;
//
//        case(state)
//            0: begin
//                // CMD0 setup
//                uart_data <= {24'd0,"S"}; uart_write <= 1;
//                shift_reg <= 48'h400000000095; // CMD0 frame
//                bit_index <= 47;
//                SD_CLK <= 0;
//                sd_cmd_oe <= 1;
//                state <= 1;
//            end
//            1: begin
//                // Shift out CMD0
//                SD_CLK <= ~SD_CLK;
//                if(SD_CLK) begin
//                    sd_cmd_out <= shift_reg[bit_index];
//                    if(bit_index==0) state <= 2;
//                    else bit_index <= bit_index - 1;
//                end
//            end
//            2: begin
//                // Release CMD line & wait for response 0x01
//                sd_cmd_oe <= 0;
//                SD_CLK <= ~SD_CLK;
//                if(sd_data_in == 0) begin
//                    uart_data <= {24'd0,"C"}; uart_write <= 1;
//                    shift_reg <= 48'h5117000000FF; // CMD17 frame
//                    bit_index <= 47;
//                    SD_CLK <= 0;
//                    sd_cmd_oe <= 1;
//                    state <= 3;
//                end
//            end
//            3: begin
//                // Shift out CMD17
//                SD_CLK <= ~SD_CLK;
//                if(SD_CLK) begin
//                    sd_cmd_out <= shift_reg[bit_index];
//                    if(bit_index==0) begin
//                        sd_cmd_oe <= 0;
//                        start_token_received <= 0;
//                        byte_index <= 0;
//                        bit_index <= 0;
//                        state <= 4;
//                    end else bit_index <= bit_index - 1;
//                end
//            end
//            4: begin
//                // Wait for start token 0xFE
//                SD_CLK <= ~SD_CLK;
//                if(SD_CLK) begin
//                    read_byte <= {read_byte[6:0], sd_data_in};
//                    bit_index <= bit_index + 1;
//                    if(bit_index==7) begin
//                        if(read_byte==8'hFE) start_token_received <= 1;
//                        bit_index <= 0;
//                        if(start_token_received) begin
//                            byte_index <= 0;
//                            state <= 5;
//                        end
//                    end
//                end
//            end
//            5: begin
//                // Read 512 bytes
//                SD_CLK <= ~SD_CLK;
//                if(SD_CLK) begin
//                    read_byte <= {read_byte[6:0], sd_data_in};
//                    bit_index <= bit_index + 1;
//                    if(bit_index==7) begin
//                        uart_data <= {24'd0, read_byte};
//                        uart_write <= 1;
//                        byte_index <= byte_index + 1;
//                        bit_index <= 0;
//                        if(byte_index==511) state <= 6;
//                    end
//                end
//            end
//            6: begin
//                // Done
//                uart_data <= {24'd0,"D"}; uart_write <= 1;
//                state <= 6;
//            end
//        endcase
//    end
//end
//
//endmodule








////===========================================================
//// DE1 SD Card SPI Reader (with dummy clocks after CMD0)
////===========================================================
//module cpu_on_board (
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    (* chip_pin = "V20" *) output reg SD_CLK,
//    (* chip_pin = "Y20" *) inout  wire SD_CMD,
//    (* chip_pin = "W20" *) inout  wire SD_DAT0,
//    (* chip_pin = "U20" *) output wire SD_DAT3
//);
//
////=======================================================
//// LED blink
////=======================================================
//wire reset_n = KEY0;
//reg [23:0] blink_counter;
//always @(posedge CLOCK_50 or negedge reset_n)
//    if (!reset_n) blink_counter <= 0;
//    else blink_counter <= blink_counter + 1'b1;
//assign LEDR0 = blink_counter[23];
//
////=======================================================
//// UART
////=======================================================
//reg  [31:0] uart_data;
//reg         uart_write;
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
//// SPI signals
////=======================================================
//reg sd_cmd_out;
//reg sd_cmd_oe;
//assign SD_CMD = sd_cmd_oe ? sd_cmd_out : 1'bz;
//wire sd_cmd_in = SD_CMD;
//wire sd_data_in = SD_DAT0;
//assign SD_DAT3 = 1'b1; // deselect chip
//
////=======================================================
//// SPI clock divider (~400 kHz)
////=======================================================
//reg [6:0] clk_div;
//reg spi_clk_en;
//always @(posedge CLOCK_50 or negedge reset_n) begin
//    if(!reset_n) begin
//        clk_div <= 0;
//        spi_clk_en <= 0;
//    end else begin
//        if(clk_div == 62) begin  // 50MHz / 125 -> 400kHz
//            clk_div <= 0;
//            spi_clk_en <= 1;
//        end else begin
//            clk_div <= clk_div + 1;
//            spi_clk_en <= 0;
//        end
//    end
//end
//
////=======================================================
//// SD SPI state machine
////=======================================================
//reg [5:0] state;
//reg [5:0] bit_index;
//reg [8:0] byte_index;
//reg [47:0] shift_reg;
//reg [7:0] read_byte;
//reg start_token_received;
//
//always @(posedge CLOCK_50 or negedge reset_n) begin
//    if(!reset_n) begin
//        SD_CLK <= 0;
//        sd_cmd_out <= 1;
//        sd_cmd_oe <= 1;
//        state <= 0;
//        bit_index <= 0;
//        byte_index <= 0;
//        uart_write <= 0;
//        read_byte <= 0;
//        start_token_received <= 0;
//        shift_reg <= 0;
//    end else if(spi_clk_en) begin
//        uart_write <= 0;
//        SD_CLK <= ~SD_CLK;
//
//        case(state)
//            0: begin
//                // CMD0 setup
//                uart_data <= {24'd0,"S"}; uart_write <= 1;
//                shift_reg <= 48'h400000000095; // CMD0 frame
//                bit_index <= 47;
//                sd_cmd_oe <= 1;
//                state <= 1;
//            end
//            1: begin
//                // Shift out CMD0
//                if(SD_CLK) begin
//                    sd_cmd_out <= shift_reg[bit_index];
//                    if(bit_index==0) begin
//                        sd_cmd_oe <= 0;
//                        bit_index <= 0;
//                        state <= 2;
//                    end else bit_index <= bit_index - 1;
//                end
//            end
//            2: begin
//                // Send dummy clocks (0xFF) until card responds
//                read_byte <= {read_byte[6:0], sd_cmd_in};
//                bit_index <= bit_index + 1;
//                if(bit_index==7) begin
//                    bit_index <= 0;
//                    if(read_byte != 8'hFF) begin
//                        // response received
//                        uart_data <= {24'd0,"C"}; uart_write <= 1;
//                        // CMD17 frame (read block 0)
//                        shift_reg <= 48'h5117000000FF;
//                        bit_index <= 47;
//                        sd_cmd_oe <= 1;
//                        state <= 3;
//                    end
//                end
//            end
//            3: begin
//                // Shift out CMD17
//                if(SD_CLK) begin
//                    sd_cmd_out <= shift_reg[bit_index];
//                    if(bit_index==0) begin
//                        sd_cmd_oe <= 0;
//                        bit_index <= 0;
//                        start_token_received <= 0;
//                        byte_index <= 0;
//                        state <= 4;
//                    end else bit_index <= bit_index - 1;
//                end
//            end
//            4: begin
//                // Wait for start token 0xFE
//                read_byte <= {read_byte[6:0], sd_data_in};
//                bit_index <= bit_index + 1;
//                if(bit_index==7) begin
//                    bit_index <= 0;
//                    if(read_byte==8'hFE) begin
//                        start_token_received <= 1;
//                        byte_index <= 0;
//                        state <= 5;
//                    end
//                end
//            end
//            5: begin
//                // Read 512 bytes
//                read_byte <= {read_byte[6:0], sd_data_in};
//                bit_index <= bit_index + 1;
//                if(bit_index==7) begin
//                    bit_index <= 0;
//                    uart_data <= {24'd0, read_byte};
//                    uart_write <= 1;
//                    byte_index <= byte_index + 1;
//                    if(byte_index==511) state <= 6;
//                end
//            end
//            6: begin
//                // Done
//                uart_data <= {24'd0,"D"}; uart_write <= 1;
//                state <= 6;
//            end
//        endcase
//    end
//end
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
//    (* chip_pin = "U20" *) output wire SD_DAT3   // SD_CS (optional, often used as CS)
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
//    assign LEDR0 = blink_counter[23]; // Blinks every ~1.6 seconds
//
//    //=======================================================
//    // UART for debug output
//    //=======================================================
//    reg  [31:0] uart_tx_data;
//    reg         uart_tx_valid; // Assert high to send a byte
//    reg         uart_tx_ready; // Indicates UART is ready to accept data
//
//    // Example of a basic JTAG UART sender. In a real system,
//    // you'd typically have a small FIFO or a more robust driver.
//    jtag_uart_system uart0 (
//        .clk_clk(CLOCK_50),
//        .reset_reset_n(reset_n),
//        .jtag_uart_0_avalon_jtag_slave_address(1'b0), // Assuming control register
//        .jtag_uart_0_avalon_jtag_slave_writedata(uart_tx_data),
//        .jtag_uart_0_avalon_jtag_slave_write_n(~uart_tx_valid), // Active low write
//        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
//        .jtag_uart_0_avalon_jtag_slave_read_n(1'b1) // Not reading for this example
//        // Need to check specific JTAG UART component for ready signal,
//        // often available from the status register. For simplicity,
//        // we'll assume it's always ready in this example or poll the status bit.
//    );
//
//    // A simple UART sender for string literals
//    reg [7:0]   uart_string_data;
//    reg         uart_string_valid;
//    reg [3:0]   uart_string_idx;
//    reg [31:0]  uart_string_current_addr;
//
//    localparam UART_BUFFER_SIZE = 32;
//    reg [7:0]   uart_buffer [0:UART_BUFFER_SIZE-1];
//
//    always @(posedge CLOCK_50 or negedge reset_n) begin
//        if (!reset_n) begin
//            uart_tx_valid <= 0;
//        end else begin
//            // Drive the JTAG UART with current byte
//            uart_tx_valid <= uart_string_valid;
//            uart_tx_data <= {24'h00, uart_string_data};
//        end
//    end
//
//    // Helper for sending a null-terminated string via UART
//    // Call with uart_send_string = 1, and string_ptr pointing to data
//    reg         uart_send_string;
//    reg [31:0]  uart_string_ptr; // Base address for string data (simulated)
//
//    always @(posedge CLOCK_50 or negedge reset_n) begin
//        if (!reset_n) begin
//            uart_string_idx <= 0;
//            uart_string_valid <= 0;
//            uart_string_data <= 0;
//            uart_send_string <= 0; // Clear on reset
//        end else if (uart_send_string) begin
//            // This is a simplified model. In reality, you'd have actual memory
//            // and an address pointer to fetch bytes. Here, we'll just queue a few hardcoded strings.
//            uart_string_valid <= 1; // Always try to send when active
//
//            // Simplified: if JTAG UART is ready, move to next char
//            // For this example, assuming JTAG UART is always ready for simplicity
//            // or we'd need to poll its status register.
//            if (uart_string_valid == 1) begin // This implies a byte was sent
//                case (uart_string_idx)
//                    0:  uart_string_data <= uart_buffer[0];
//                    1:  uart_string_data <= uart_buffer[1];
//                    2:  uart_string_data <= uart_buffer[2];
//                    3:  uart_string_data <= uart_buffer[3];
//                    4:  uart_string_data <= uart_buffer[4];
//                    5:  uart_string_data <= uart_buffer[5];
//                    6:  uart_string_data <= uart_buffer[6];
//                    7:  uart_string_data <= uart_buffer[7];
//                    8:  uart_string_data <= uart_buffer[8];
//                    9:  uart_string_data <= uart_buffer[9];
//                    10: uart_string_data <= uart_buffer[10];
//                    11: uart_string_data <= uart_buffer[11];
//                    12: uart_string_data <= uart_buffer[12];
//                    13: uart_string_data <= uart_buffer[13];
//                    14: uart_string_data <= uart_buffer[14];
//                    15: uart_string_data <= uart_buffer[15];
//                    // Add more if your messages are longer
//                    default: begin
//                        uart_string_valid <= 0; // End of string
//                        uart_string_idx <= 0;
//                        uart_send_string <= 0; // Done sending
//                    end
//                endcase
//                // Only increment if a valid character was sent and not null
//                if (uart_string_data != 8'h00 && uart_string_idx < UART_BUFFER_SIZE) begin
//                    uart_string_idx <= uart_string_idx + 1;
//                end else begin
//                    uart_string_valid <= 0;
//                    uart_string_idx <= 0;
//                    uart_send_string <= 0; // Stop sending
//                end
//            end
//        end else begin
//            uart_string_valid <= 0; // Default off
//            uart_string_idx <= 0;
//        end
//    end
//
//    // --- Utility function to copy string to buffer and initiate send ---
//    task send_uart_string;
//        input [8*UART_BUFFER_SIZE-1:0] str; // Maximum string length (e.g., 32 chars)
//        integer i;
//    begin
//        for (i = 0; i < UART_BUFFER_SIZE; i = i + 1) begin
//            uart_buffer[i] = str[i*8 +: 8];
//            if (str[i*8 +: 8] == 8'h00) break; // Stop at null terminator
//        end
//        for (i = i; i < UART_BUFFER_SIZE; i = i + 1) begin // Clear remaining buffer
//            uart_buffer[i] = 8'h00;
//        end
//        uart_string_idx <= 0;
//        uart_send_string <= 1;
//    end
//    endtask
//
//    //=======================================================
//    // Simple SD controller wiring (mimic SOPC signals)
//    // IMPORTANT: Replace these with actual SD controller logic!
//    // These are placeholders for illustration.
//    //=======================================================
//    reg [1:0]  sd_address;
//    reg        sd_chipselect;
//    reg        sd_write_n;
//    reg [15:0] sd_writedata;
//    wire [15:0] sd_readdata_cmd; // Data read from SD_CMD
//    wire [15:0] sd_readdata_dat; // Data read from SD_DAT0
//    wire        sd_out_clk;
//
//    // --- SD_CLK ---
//    // Placeholder module. In a real system, this would be part of your
//    // SD controller and include clock generation/division logic.
//    // For this example, we'll just toggle SD_CLK directly in the state machine
//    // to simulate an SPI clock.
//    reg sd_clk_reg;
//    assign SD_CLK = sd_clk_reg;
//
//    // --- SD_CMD --- (MOSI for commands, MISO for responses in SPI mode)
//    // Assume SD_CMD is configured as an output when sending commands (MOSI)
//    // and an input when reading responses (MISO).
//    // In SPI mode, SD_CMD is MOSI, SD_DAT0 is MISO.
//    reg sd_cmd_output_enable;
//    reg sd_cmd_out;
//    wire sd_cmd_in;
//
//    assign SD_CMD = sd_cmd_output_enable ? sd_cmd_out : 1'bz;
//    assign sd_cmd_in = SD_CMD; // Read actual pin value
//
//    // --- SD_DAT0 --- (MISO in SPI mode)
//    // SD_DAT0 is typically MISO in SPI mode, so it's usually an input.
//    // However, the card can sometimes drive it for busy signals.
//    reg sd_dat0_output_enable; // Keep it as an option, but usually 0 for MISO
//    reg sd_dat0_out;
//    wire sd_dat0_in;
//
//    assign SD_DAT0 = sd_dat0_output_enable ? sd_dat0_out : 1'bz;
//    assign sd_dat0_in = SD_DAT0; // Read actual pin value
//
//    // SD_DAT3 is often used as the Chip Select (CS) line for SPI mode.
//    assign SD_DAT3 = sd_chipselect; // Active low CS, so invert if active high needed
//
//    //=======================================================
//    // SD Card SPI specific registers/signals
//    //=======================================================
//    reg [7:0] spi_data_out;
//    reg [7:0] spi_data_in;
//    reg [2:0] spi_bit_count;
//    reg       spi_transfer_in_progress;
//    reg       sd_cmd_response_expected; // Flag to indicate a response is awaited
//    reg [7:0] sd_response_byte;
//
//    // SD Card State Machine
//    parameter S_IDLE                = 4'h0,
//              S_POWER_UP_DELAY      = 4'h1,
//              S_SEND_CMD0_GO_IDLE   = 4'h2,
//              S_WAIT_R1_CMD0        = 4'h3,
//              S_SEND_CMD8_IF_V2     = 4'h4,
//              S_WAIT_R7_CMD8        = 4'h5,
//              S_SEND_CMD55          = 4'h6,
//              S_WAIT_R1_CMD55       = 4'h7,
//              S_SEND_ACMD41_INIT    = 4'h8,
//              S_WAIT_R1_ACMD41      = 4'h9,
//              S_SEND_CMD58_READ_OCR = 4'hA,
//              S_WAIT_R3_CMD58       = 4'hB,
//              S_INITIALIZED         = 4'hC,
//              S_SEND_CMD17_READ_BLOCK = 4'hD,
//              S_WAIT_R1_CMD17       = 4'hE,
//              S_READ_DATA_TOKEN_WAIT = 4'hF,
//              S_READ_DATA_BLOCK     = 4'h10,
//              S_READ_CRC            = 4'h11,
//              S_TEST_DONE           = 4'h12;
//
//    reg [4:0]  state;
//    reg [31:0] main_counter;
//    reg [31:0] delay_counter;
//    reg [7:0]  sd_rxb_buffer; // Buffer for incoming SD data
//    reg [7:0]  sd_last_response; // Store the last received R1 response
//    reg [31:0] sd_ocr_reg;       // OCR register from CMD58
//    reg [7:0]  sd_read_byte_counter;
//    reg [7:0]  sd_read_data_byte;
//    reg [11:0] sd_read_block_byte_index;
//    reg [7:0]  sd_read_data_block [0:511]; // 512-byte block buffer
//
//    // --- SPI Clock Divider ---
//    // SD card initialization needs a slow clock, max 400kHz.
//    // 50MHz / 400kHz = 125. So, divide by 125, or 62.5 for rising/falling edge
//    // A divisor of 250 would make 200kHz.
//    // Let's use a 12-bit counter for flexibility.
//    reg [11:0] spi_clk_divider_counter;
//    reg        spi_clk_enable; // Controls actual SPI clock generation
//    reg        spi_clk_slow_mode; // Flag to use slow clock for init
//
//    localparam SPI_DIV_SLOW = 12'd124; // 50MHz / (2 * (124+1)) = 200kHz (approx)
//    localparam SPI_DIV_FAST = 12'd1;  // 50MHz / (2 * (1+1)) = 12.5MHz (example, higher possible)
//
//    always @(posedge CLOCK_50 or negedge reset_n) begin
//        if (!reset_n) begin
//            spi_clk_divider_counter <= 0;
//            sd_clk_reg <= 0;
//        end else if (spi_clk_enable) begin
//            if (spi_clk_divider_counter == (spi_clk_slow_mode ? SPI_DIV_SLOW : SPI_DIV_FAST)) begin
//                spi_clk_divider_counter <= 0;
//                sd_clk_reg <= ~sd_clk_reg; // Toggle clock
//            end else begin
//                spi_clk_divider_counter <= spi_clk_divider_counter + 1;
//            end
//        end else begin
//            sd_clk_reg <= 0; // Keep clock low when disabled
//        end
//    end
//
//    // --- SPI Transfer Logic ---
//    // Assumes SD_CMD is MOSI and SD_DAT0 is MISO
//    always @(posedge CLOCK_50 or negedge reset_n) begin
//        if (!reset_n) begin
//            spi_data_in <= 0;
//            spi_data_out <= 0;
//            spi_bit_count <= 0;
//            spi_transfer_in_progress <= 0;
//            sd_cmd_output_enable <= 0; // SD_CMD as input by default
//            sd_cmd_out <= 0;
//        end else begin
//            if (spi_transfer_in_progress) begin
//                if (sd_clk_reg == 1'b0) begin // On falling edge of SD_CLK (or rising, depending on SPI mode)
//                    // Drive MOSI (SD_CMD) on falling edge, prepare for next bit
//                    sd_cmd_out <= spi_data_out[7 - spi_bit_count];
//                    sd_cmd_output_enable <= 1; // Enable output
//                end else begin // On rising edge of SD_CLK
//                    // Read MISO (SD_DAT0) on rising edge
//                    spi_data_in[7 - spi_bit_count] <= sd_dat0_in;
//
//                    if (spi_bit_count == 7) begin // Last bit
//                        spi_bit_count <= 0;
//                        spi_transfer_in_progress <= 0;
//                        sd_cmd_output_enable <= 0; // Disable MOSI output, make SD_CMD input again
//                    end else begin
//                        spi_bit_count <= spi_bit_count + 1;
//                    end
//                end
//            end else begin
//                sd_cmd_output_enable <= 0; // Ensure SD_CMD is input when not transmitting
//            end
//        end
//    end
//
//    // Function to start an SPI byte transfer
//    task spi_send_byte;
//        input [7:0] tx_data;
//    begin
//        spi_data_out <= tx_data;
//        spi_bit_count <= 0;
//        spi_transfer_in_progress <= 1;
//    end
//    endtask
//
//    // Main state machine
//    always @(posedge CLOCK_50 or negedge reset_n) begin
//        if (!reset_n) begin
//            state <= S_IDLE;
//            main_counter <= 0;
//            delay_counter <= 0;
//            sd_chipselect <= 1'b1; // CS high (inactive)
//            spi_clk_enable <= 0;
//            spi_clk_slow_mode <= 1; // Start with slow clock
//            sd_last_response <= 8'hFF;
//            sd_ocr_reg <= 0;
//            sd_read_block_byte_index <= 0;
//        end else begin
//            main_counter <= main_counter + 1; // General purpose counter
//
//            // --- UART Debug Output Trigger ---
//            // Simplified triggering for UART messages
//            if (uart_send_string == 0) begin // Only if not already sending
//                case (state)
//                    S_IDLE: begin
//                        if (main_counter == 50_000_000) begin // 1 second delay
//                            send_uart_string({"Starting SD Init\n", 8'h00});
//                            state <= S_POWER_UP_DELAY;
//                            main_counter <= 0;
//                            delay_counter <= 0;
//                        end
//                    end
//                    S_POWER_UP_DELAY: begin
//                        if (delay_counter == 500_000_000) begin // ~10 seconds power-up delay (adjust as needed)
//                            send_uart_string({"Power-up delay done\n", 8'h00});
//                            state <= S_SEND_CMD0_GO_IDLE;
//                            delay_counter <= 0;
//                        end else begin
//                            delay_counter <= delay_counter + 1;
//                        end
//                    end
//                    S_SEND_CMD0_GO_IDLE: begin
//                        // Trigger sending CMD0
//                        send_uart_string({"CMD0...\n", 8'h00});
//                        state <= S_WAIT_R1_CMD0;
//                        // More explicit SPI handling for SD commands
//                        // First, hold CS high for 74+ clocks (done during power-up delay)
//                        // Then, pull CS low.
//                        sd_chipselect <= 1'b0; // Active low CS
//                        spi_clk_enable <= 1;   // Start SPI clock
//                        spi_clk_slow_mode <= 1; // Ensure slow clock for init
//
//                        // Send CMD0 (0x40), Arg (0x00000000), CRC (0x95)
//                        spi_send_byte(8'h40); // Command byte
//                        state <= S_WAIT_R1_CMD0; // Transition to wait for response
//                        delay_counter <= 0; // Use delay_counter for SPI bit timing if needed, or separate counter
//                    end
//                    S_WAIT_R1_CMD0: begin
//                        if (!spi_transfer_in_progress) begin // CMD0 byte sent
//                            // Now send argument bytes and CRC
//                            spi_send_byte(8'h00); // Arg byte 0
//                            state <= S_WAIT_R1_CMD0; // Keep state
//                            delay_counter <= delay_counter + 1; // Use this as byte sent counter
//                            if (delay_counter == 0) begin // After 1st byte (CMD0)
//                                spi_send_byte(8'h00);
//                            end else if (delay_counter == 1) begin // After 2nd byte
//                                spi_send_byte(8'h00);
//                            end else if (delay_counter == 2) begin // After 3rd byte
//                                spi_send_byte(8'h00);
//                            end else if (delay_counter == 3) begin // After 4th byte
//                                spi_send_byte(8'h95); // CRC byte
//                                delay_counter <= 0;
//                                state <= S_WAIT_R1_CMD0_RESPONSE; // Now wait for actual R1 response
//                            end
//                        end
//                    end
//                    S_WAIT_R1_CMD0_RESPONSE: begin
//                        // Read response (R1) byte from SD_DAT0 (MISO)
//                        // This requires continuous clocking until response is received.
//                        // A proper SPI controller would handle this, but here we manually clock and sample.
//                        if (delay_counter < 800) begin // Max 8 bytes / 8 bits per byte = 64 clocks. Plus extra. Max 80 clock cycles.
//                            if (!spi_transfer_in_progress) begin // One byte has been read
//                                spi_send_byte(8'hFF); // Send dummy byte to clock in response
//                                if (spi_data_in[7] == 1'b0) begin // Response bit 7 is 0, indicates valid R1 response
//                                    sd_last_response <= spi_data_in;
//                                    send_uart_string({"R1 from CMD0: ", spi_data_in, "\n", 8'h00});
//                                    if (spi_data_in == 8'h01) begin // Should be 0x01 (Idle state)
//                                        state <= S_SEND_CMD8_IF_V2;
//                                        delay_counter <= 0;
//                                        sd_chipselect <= 1'b1; // De-assert CS after command sequence
//                                        spi_clk_enable <= 0; // Stop clock
//                                    end else begin
//                                        send_uart_string({"CMD0 failed (not 0x01): ", spi_data_in, "\n", 8'h00});
//                                        state <= S_IDLE; // Reset if failed
//                                        sd_chipselect <= 1'b1;
//                                        spi_clk_enable <= 0;
//                                    end
//                                end
//                            end
//                            delay_counter <= delay_counter + 1;
//                        end else begin
//                            send_uart_string({"CMD0 Timeout\n", 8'h00});
//                            state <= S_IDLE; // Timeout
//                            sd_chipselect <= 1'b1;
//                            spi_clk_enable <= 0;
//                        end
//                    end
//
//                    S_SEND_CMD8_IF_V2: begin
//                        if (uart_send_string == 0 && delay_counter == 0) begin // Ensure UART is done and not transitioning instantly
//                            send_uart_string({"CMD8...\n", 8'h00});
//                            sd_chipselect <= 1'b0;
//                            spi_clk_enable <= 1;
//                            spi_send_byte(8'h48); // CMD8 (0x48)
//                            state <= S_WAIT_R7_CMD8;
//                            delay_counter <= 1; // Counter for arg/crc bytes
//                        end
//                    end
//                    S_WAIT_R7_CMD8: begin
//                        if (!spi_transfer_in_progress) begin
//                            if (delay_counter == 1) begin // Send Arg1 (VHS, 0x01)
//                                spi_send_byte(8'h00); // Reserved
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 2) begin // Send Arg2 (VHS, 0x01)
//                                spi_send_byte(8'h00); // Reserved
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 3) begin // Send Arg3 (VHS, 0x01)
//                                spi_send_byte(8'h01); // 2.7-3.6V (VHS)
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 4) begin // Send Arg4 (Check Pattern, 0xAA)
//                                spi_send_byte(8'hAA); // Check Pattern
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 5) begin // Send CRC (0x87)
//                                spi_send_byte(8'h87); // CRC for CMD8
//                                delay_counter <= 0;
//                                state <= S_WAIT_R7_CMD8_RESPONSE;
//                            end
//                        end
//                    end
//                    S_WAIT_R7_CMD8_RESPONSE: begin
//                        if (delay_counter < 800) begin
//                            if (!spi_transfer_in_progress) begin
//                                spi_send_byte(8'hFF); // Dummy byte to clock in response
//                                if (spi_data_in[7] == 1'b0) begin // R1 part of R7 response
//                                    sd_last_response <= spi_data_in;
//                                    send_uart_string({"R1 from CMD8: ", spi_data_in, "\n", 8'h00});
//                                    if (spi_data_in == 8'h01) begin // Should be 0x01 (Idle state) or 0x05 (Illegal command if not V2 card)
//                                        // Read remaining 4 bytes of R7 (32-bit response)
//                                        state <= S_READ_R7_BYTES;
//                                        delay_counter <= 0; // Use for R7 byte count
//                                    end else if (spi_data_in == 8'h05) begin
//                                        send_uart_string({"CMD8 rejected, V1 card?\n", 8'h00});
//                                        state <= S_SEND_CMD55; // Proceed as V1 card (skip ACMD41 with HCS)
//                                        sd_chipselect <= 1'b1;
//                                        spi_clk_enable <= 0;
//                                    end else begin
//                                        send_uart_string({"CMD8 failed (R1 != 0x01/0x05): ", spi_data_in, "\n", 8'h00});
//                                        state <= S_IDLE; // Reset if failed
//                                        sd_chipselect <= 1'b1;
//                                        spi_clk_enable <= 0;
//                                    end
//                                end
//                            end
//                            delay_counter <= delay_counter + 1;
//                        end else begin
//                            send_uart_string({"CMD8 Timeout\n", 8'h00});
//                            state <= S_IDLE;
//                            sd_chipselect <= 1'b1;
//                            spi_clk_enable <= 0;
//                        end
//                    end
//                    S_READ_R7_BYTES: begin
//                        // Read the 4 additional bytes of R7 (OCR and Check Pattern)
//                        if (delay_counter < 4) begin
//                            if (!spi_transfer_in_progress) begin
//                                spi_send_byte(8'hFF); // Dummy to clock in next byte
//                                sd_ocr_reg[(3-delay_counter)*8 +: 8] <= spi_data_in; // Store R7 bytes
//                                delay_counter <= delay_counter + 1;
//                            end
//                        end else begin
//                            send_uart_string({"R7 response received\n", 8'h00});
//                            send_uart_string({"Check Pattern: ", sd_ocr_reg[7:0], "\n", 8'h00});
//                            send_uart_string({"Voltage Range: ", sd_ocr_reg[19:16], "\n", 8'h00});
//                            state <= S_SEND_CMD55; // Next, send CMD55 for ACMD41
//                            sd_chipselect <= 1'b1;
//                            spi_clk_enable <= 0;
//                        end
//                    end
//
//                    S_SEND_CMD55: begin
//                        if (uart_send_string == 0 && delay_counter == 0) begin
//                            send_uart_string({"CMD55...\n", 8'h00});
//                            sd_chipselect <= 1'b0;
//                            spi_clk_enable <= 1;
//                            spi_send_byte(8'h77); // CMD55 (0x77)
//                            state <= S_WAIT_R1_CMD55;
//                            delay_counter <= 1;
//                        end
//                    end
//                    S_WAIT_R1_CMD55: begin
//                        if (!spi_transfer_in_progress) begin
//                            if (delay_counter == 1) begin // Arg (0x00000000)
//                                spi_send_byte(8'h00);
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 2) begin
//                                spi_send_byte(8'h00);
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 3) begin
//                                spi_send_byte(8'h00);
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 4) begin
//                                spi_send_byte(8'h00);
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 5) begin // CRC (0x65 for dummy, not really checked)
//                                spi_send_byte(8'h01); // Dummy CRC or 0x65
//                                delay_counter <= 0;
//                                state <= S_WAIT_R1_CMD55_RESPONSE;
//                            end
//                        end
//                    end
//                    S_WAIT_R1_CMD55_RESPONSE: begin
//                        if (delay_counter < 800) begin
//                            if (!spi_transfer_in_progress) begin
//                                spi_send_byte(8'hFF);
//                                if (spi_data_in[7] == 1'b0) begin
//                                    sd_last_response <= spi_data_in;
//                                    send_uart_string({"R1 from CMD55: ", spi_data_in, "\n", 8'h00});
//                                    if (spi_data_in == 8'h01) begin // Should be 0x01 (Idle state)
//                                        state <= S_SEND_ACMD41_INIT;
//                                        delay_counter <= 0;
//                                        sd_chipselect <= 1'b1;
//                                        spi_clk_enable <= 0;
//                                    end else begin
//                                        send_uart_string({"CMD55 failed (not 0x01): ", spi_data_in, "\n", 8'h00});
//                                        state <= S_IDLE;
//                                        sd_chipselect <= 1'b1;
//                                        spi_clk_enable <= 0;
//                                    end
//                                end
//                            end
//                            delay_counter <= delay_counter + 1;
//                        end else begin
//                            send_uart_string({"CMD55 Timeout\n", 8'h00});
//                            state <= S_IDLE;
//                            sd_chipselect <= 1'b1;
//                            spi_clk_enable <= 0;
//                        end
//                    end
//
//                    S_SEND_ACMD41_INIT: begin
//                        if (uart_send_string == 0 && delay_counter == 0) begin
//                            send_uart_string({"ACMD41...\n", 8'h00});
//                            sd_chipselect <= 1'b0;
//                            spi_clk_enable <= 1;
//                            spi_send_byte(8'h69); // ACMD41 (0x69)
//                            state <= S_WAIT_R1_ACMD41;
//                            delay_counter <= 1;
//                        end
//                    end
//                    S_WAIT_R1_ACMD41: begin
//                        if (!spi_transfer_in_progress) begin
//                            if (delay_counter == 1) begin // Arg (0x40000000 for HCS, or 0x00000000 for standard capacity)
//                                spi_send_byte(8'h40); // HCS (Host Capacity Support)
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 2) begin
//                                spi_send_byte(8'h00);
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 3) begin
//                                spi_send_byte(8'h00);
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 4) begin
//                                spi_send_byte(8'h00);
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 5) begin // CRC (dummy)
//                                spi_send_byte(8'h01); // Dummy CRC or 0x77
//                                delay_counter <= 0;
//                                state <= S_WAIT_R1_ACMD41_RESPONSE;
//                            end
//                        end
//                    end
//                    S_WAIT_R1_ACMD41_RESPONSE: begin
//                        if (delay_counter < 800) begin // Max 800 clock cycles for response (CMD0 timeout)
//                            if (!spi_transfer_in_progress) begin
//                                spi_send_byte(8'hFF);
//                                if (spi_data_in == 8'h00) begin // Should be 0x00 (card initialized and ready)
//                                    sd_last_response <= spi_data_in;
//                                    send_uart_string({"R1 from ACMD41: ", spi_data_in, "\n", 8'h00});
//                                    // Initialization successful
//                                    send_uart_string({"SD Card Initialized!\n", 8'h00});
//                                    state <= S_SEND_CMD58_READ_OCR;
//                                    delay_counter <= 0;
//                                    sd_chipselect <= 1'b1;
//                                    spi_clk_enable <= 0;
//                                    spi_clk_slow_mode <= 0; // Switch to fast clock after init
//                                end else if (spi_data_in == 8'h01) begin // Still in idle state, keep polling
//                                    state <= S_SEND_CMD55; // Loop back to CMD55 -> ACMD41
//                                    delay_counter <= 0;
//                                    sd_chipselect <= 1'b1;
//                                    spi_clk_enable <= 0;
//                                end else begin
//                                    send_uart_string({"ACMD41 failed (not 0x00/0x01): ", spi_data_in, "\n", 8'h00});
//                                    state <= S_IDLE;
//                                    sd_chipselect <= 1'b1;
//                                    spi_clk_enable <= 0;
//                                end
//                            end
//                            delay_counter <= delay_counter + 1;
//                        end else begin
//                            send_uart_string({"ACMD41 Timeout\n", 8'h00});
//                            state <= S_IDLE;
//                            sd_chipselect <= 1'b1;
//                            spi_clk_enable <= 0;
//                        end
//                    end
//
//                    S_SEND_CMD58_READ_OCR: begin
//                        if (uart_send_string == 0 && delay_counter == 0) begin
//                            send_uart_string({"CMD58 (Read OCR)...\n", 8'h00});
//                            sd_chipselect <= 1'b0;
//                            spi_clk_enable <= 1;
//                            spi_send_byte(8'h7A); // CMD58 (0x7A)
//                            state <= S_WAIT_R3_CMD58;
//                            delay_counter <= 1;
//                        end
//                    end
//                    S_WAIT_R3_CMD58: begin
//                        if (!spi_transfer_in_progress) begin
//                            if (delay_counter == 1) begin // Arg (0x00000000)
//                                spi_send_byte(8'h00);
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 2) begin
//                                spi_send_byte(8'h00);
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 3) begin
//                                spi_send_byte(8'h00);
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 4) begin
//                                spi_send_byte(8'h00);
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 5) begin // CRC (dummy)
//                                spi_send_byte(8'h01);
//                                delay_counter <= 0;
//                                state <= S_WAIT_R3_CMD58_RESPONSE;
//                            end
//                        end
//                    end
//                    S_WAIT_R3_CMD58_RESPONSE: begin
//                        if (delay_counter < 800) begin
//                            if (!spi_transfer_in_progress) begin
//                                spi_send_byte(8'hFF); // Dummy byte for R1
//                                if (spi_data_in[7] == 1'b0) begin
//                                    sd_last_response <= spi_data_in;
//                                    send_uart_string({"R1 from CMD58: ", spi_data_in, "\n", 8'h00});
//                                    if (spi_data_in == 8'h00) begin // Should be 0x00
//                                        state <= S_READ_OCR_BYTES; // Read the 4 OCR bytes
//                                        delay_counter <= 0;
//                                    end else begin
//                                        send_uart_string({"CMD58 failed (not 0x00): ", spi_data_in, "\n", 8'h00});
//                                        state <= S_IDLE;
//                                        sd_chipselect <= 1'b1;
//                                        spi_clk_enable <= 0;
//                                    end
//                                end
//                            end
//                            delay_counter <= delay_counter + 1;
//                        end else begin
//                            send_uart_string({"CMD58 Timeout\n", 8'h00});
//                            state <= S_IDLE;
//                            sd_chipselect <= 1'b1;
//                            spi_clk_enable <= 0;
//                        end
//                    end
//                    S_READ_OCR_BYTES: begin
//                        if (delay_counter < 4) begin
//                            if (!spi_transfer_in_progress) begin
//                                spi_send_byte(8'hFF);
//                                sd_ocr_reg[(3-delay_counter)*8 +: 8] <= spi_data_in; // Store OCR bytes
//                                delay_counter <= delay_counter + 1;
//                            end
//                        end else begin
//                            send_uart_string({"OCR Value: ", sd_ocr_reg, "\n", 8'h00});
//                            if (sd_ocr_reg[30] == 1) begin
//                                send_uart_string({"Card is SDHC/SDXC\n", 8'h00});
//                            end else begin
//                                send_uart_string({"Card is Standard Capacity\n", 8'h00});
//                            end
//                            state <= S_INITIALIZED;
//                            sd_chipselect <= 1'b1;
//                            spi_clk_enable <= 0;
//                            delay_counter <= 0;
//                        end
//                    end
//
//                    S_INITIALIZED: begin
//                        if (uart_send_string == 0 && delay_counter == 0) begin
//                            send_uart_string({"SD Card Ready! Reading Block 0...\n", 8'h00});
//                            delay_counter <= 50_000_000; // Delay a bit before reading
//                            state <= S_SEND_CMD17_READ_BLOCK;
//                        end else if (uart_send_string == 0 && delay_counter > 0) begin
//                             delay_counter <= delay_counter - 1;
//                        end
//                    end
//
//                    S_SEND_CMD17_READ_BLOCK: begin
//                        if (uart_send_string == 0 && delay_counter == 0) begin
//                            send_uart_string({"CMD17 (Read Single Block)...\n", 8'h00});
//                            sd_chipselect <= 1'b0;
//                            spi_clk_enable <= 1;
//                            spi_clk_slow_mode <= 0; // Use fast clock now
//                            spi_send_byte(8'h51); // CMD17 (0x51)
//                            state <= S_WAIT_R1_CMD17;
//                            delay_counter <= 1;
//                        end
//                    end
//                    S_WAIT_R1_CMD17: begin
//                        if (!spi_transfer_in_progress) begin
//                            if (delay_counter == 1) begin // Arg (Block Address: 0x00000000 for block 0)
//                                spi_send_byte(8'h00);
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 2) begin
//                                spi_send_byte(8'h00);
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 3) begin
//                                spi_send_byte(8'h00);
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 4) begin
//                                spi_send_byte(8'h00);
//                                delay_counter <= delay_counter + 1;
//                            end else if (delay_counter == 5) begin // CRC (dummy)
//                                spi_send_byte(8'h01); // Dummy CRC or 0xFF
//                                delay_counter <= 0;
//                                state <= S_WAIT_R1_CMD17_RESPONSE;
//                            end
//                        end
//                    end
//                    S_WAIT_R1_CMD17_RESPONSE: begin
//                        if (delay_counter < 800) begin
//                            if (!spi_transfer_in_progress) begin
//                                spi_send_byte(8'hFF);
//                                if (spi_data_in == 8'h00) begin
//                                    sd_last_response <= spi_data_in;
//                                    send_uart_string({"R1 from CMD17: ", spi_data_in, "\n", 8'h00});
//                                    send_uart_string({"Waiting for data token...\n", 8'h00});
//                                    state <= S_READ_DATA_TOKEN_WAIT;
//                                    delay_counter <= 0;
//                                end else begin
//                                    send_uart_string({"CMD17 failed (not 0x00): ", spi_data_in, "\n", 8'h00});
//                                    state <= S_INITIALIZED; // Go back to initialized state for retry/further commands
//                                    sd_chipselect <= 1'b1;
//                                    spi_clk_enable <= 0;
//                                end
//                            end
//                            delay_counter <= delay_counter + 1;
//                        end else begin
//                            send_uart_string({"CMD17 Timeout\n", 8'h00});
//                            state <= S_INITIALIZED;
//                            sd_chipselect <= 1'b1;
//                            spi_clk_enable <= 0;
//                        end
//                    end
//                    S_READ_DATA_TOKEN_WAIT: begin
//                        if (delay_counter < 50_000_000) begin // Max 100ms for data token
//                            if (!spi_transfer_in_progress) begin
//                                spi_send_byte(8'hFF); // Clock in dummy byte to read MISO
//                                if (spi_data_in == 8'hFE) begin // Start block token
//                                    send_uart_string({"Data token received!\n", 8'h00});
//                                    state <= S_READ_DATA_BLOCK;
//                                    sd_read_block_byte_index <= 0;
//                                    delay_counter <= 0;
//                                end else if (spi_data_in != 8'hFF) begin
//                                    // Error token or busy signal
//                                    send_uart_string({"Error/Busy Token: ", spi_data_in, "\n", 8'h00});
//                                    state <= S_INITIALIZED;
//                                    sd_chipselect <= 1'b1;
//                                    spi_clk_enable <= 0;
//                                end
//                            end
//                            delay_counter <= delay_counter + 1;
//                        end else begin
//                            send_uart_string({"Data Token Timeout\n", 8'h00});
//                            state <= S_INITIALIZED;
//                            sd_chipselect <= 1'b1;
//                            spi_clk_enable <= 0;
//                        end
//                    end
//                    S_READ_DATA_BLOCK: begin
//                        if (sd_read_block_byte_index < 512) begin
//                            if (!spi_transfer_in_progress) begin
//                                spi_send_byte(8'hFF); // Clock in dummy byte to read MISO
//                                sd_read_data_block[sd_read_block_byte_index] <= spi_data_in;
//                                sd_read_block_byte_index <= sd_read_block_byte_index + 1;
//                            end
//                        end else begin
//                            send_uart_string({"Block data read complete.\n", 8'h00});
//                            state <= S_READ_CRC;
//                            delay_counter <= 0;
//                        end
//                    end
//                    S_READ_CRC: begin
//                        if (delay_counter < 2) begin // Read 2 CRC bytes
//                             if (!spi_transfer_in_progress) begin
//                                spi_send_byte(8'hFF); // Clock in dummy byte to read MISO
//                                delay_counter <= delay_counter + 1;
//                             end
//                        end else begin
//                            send_uart_string({"CRC bytes read.\n", 8'h00});
//                            send_uart_string({"First 16 bytes of Block 0:\n", 8'h00});
//                            // Print first 16 bytes for verification
//                            // This would be done by sending individual characters or by loading an array.
//                            // For simplicity, let's just print a placeholder.
//                            // send_uart_string({sd_read_data_block[0], sd_read_data_block[1], ...}); (Need a way to print hex)
//                            send_uart_string({"[Block 0 Data Sample...]\n", 8'h00});
//                            state <= S_TEST_DONE;
//                            sd_chipselect <= 1'b1;
//                            spi_clk_enable <= 0;
//                        end
//                    end
//
//                    S_TEST_DONE: begin
//                        if (main_counter == 50_000_000) begin
//                            send_uart_string({"SD Test Done. Looping...\n", 8'h00});
//                            main_counter <= 0;
//                            state <= S_IDLE; // Loop back to start (or S_INITIALIZED for more commands)
//                        end
//                    end
//                endcase
//            end
//        end
//    end
//
//endmodule
//
//// --- Placeholder for jtag_uart_system ---
//// You will replace this with your actual Quartus JTAG UART IP.
//// This is a minimal definition to allow compilation.
//module jtag_uart_system (
//    input clk_clk,
//    input reset_reset_n,
//    input jtag_uart_0_avalon_jtag_slave_address,
//    input [31:0] jtag_uart_0_avalon_jtag_slave_writedata,
//    input jtag_uart_0_avalon_jtag_slave_write_n,
//    input jtag_uart_0_avalon_jtag_slave_chipselect,
//    input jtag_uart_0_avalon_jtag_slave_read_n
//);
//    // In a real system, this connects to the JTAG UART IP core
//    // and would have internal logic to handle data.
//    // For this example, it's just a dummy.
//endmodule
//
//// --- Placeholder for SD_CLK, SD_CMD, SD_DAT modules ---
//// These are currently not used in the expanded design,
//// as the SPI logic is implemented directly in cpu_on_board.
//// You should remove these if you implement the full controller.
//// If your existing project uses these for IO buffering, ensure they
//// are tristate buffers properly configured.
//module SD_CLK (
//    input [1:0] address,
//    input chipselect,
//    input clk,
//    input reset_n,
//    input write_n,
//    input [15:0] writedata,
//    output out_port
//);
//    assign out_port = 1'b0; // Dummy
//endmodule
//
//module SD_CMD (
//    input [1:0] address,
//    input chipselect,
//    input clk,
//    input reset_n,
//    input write_n,
//    input [15:0] writedata,
//    inout bidir_port,
//    output [15:0] readdata
//);
//    assign bidir_port = 1'bz; // Dummy
//    assign readdata = 16'hFFFF; // Dummy
//endmodule
//
//module SD_DAT (
//    input [1:0] address,
//    input chipselect,
//    input clk,
//    input reset_n,
//    input write_n,
//    input [15:0] writedata,
//    inout bidir_port,
//    output [15:0] readdata
//);
//    assign bidir_port = 1'bz; // Dummy
//    assign readdata = 16'hFFFF; // Dummy
//endmodule



// sd_spi_reader.v
// IP-free SD SPI reader for DE1: reads block 0 and prints bytes via JTAG UART.
// - Safe init SPI ~400 kHz (50MHz / 125)
// - Sends CMD0, waits by clocking 0xFF until response != 0xFF
// - Sends CMD17, waits for 0xFE start token, reads 512 bytes
// - Streams bytes to jtag UART (single-byte writes)
// Notes: this is a simple demonstrator. Real card init (SDHC vs SDSC) and ACMD41
// handling is not implemented; many SD cards will accept CMD0 + CMD17 for simple tests.

//module cpu_on_board (
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    // SD pins for DE1
//    (* chip_pin = "V20" *) output reg SD_CLK,   // SD clock
//    (* chip_pin = "Y20" *) inout  wire SD_CMD,   // SD command (MOSI when driving)
//    (* chip_pin = "W20" *) inout  wire SD_DAT,   // SD data0 (MISO)
//    (* chip_pin = "U20" *) output wire SD_DAT3   // tie high or unused
//);
//
//// ---------- basics ----------
//wire reset_n = KEY0;
//reg [23:0] blink_counter;
//always @(posedge CLOCK_50 or negedge reset_n) begin
//    if (!reset_n) blink_counter <= 0;
//    else blink_counter <= blink_counter + 1'b1;
//end
//assign LEDR0 = blink_counter[23];
//
//// ---------- JTAG UART (same interface as your project) ----------
//reg  [31:0] uart_data;
//reg         uart_write;
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
//// ---------- SD IO control (tri-state for MOSI) ----------
//reg sd_mosi_o;
//reg sd_mosi_oe;            // when 1 drive SD_CMD with sd_mosi_o
//assign SD_CMD = sd_mosi_oe ? sd_mosi_o : 1'bz;
//wire sd_miso = SD_DAT;     // DAT0 is MISO
//assign SD_DAT3 = 1'b1;     // keep DAT3 high (card detect or cs), or Z if unused
//
//// ---------- SPI clock divider (~400 kHz) ----------
//reg [6:0] clk_div;         // divides 50MHz by 125 -> 400kHz
//reg spi_edge;              // pulses when we should sample/drive at each half-cycle
//always @(posedge CLOCK_50 or negedge reset_n) begin
//    if(!reset_n) begin
//        clk_div <= 0; spi_edge <= 0;
//    end else begin
//        if(clk_div == 62) begin
//            clk_div <= 0;
//            spi_edge <= 1;
//        end else begin
//            clk_div <= clk_div + 1;
//            spi_edge <= 0;
//        end
//    end
//end
//
//// ---------- state machine and variables ----------
//localparam IDLE = 0, SEND_CMD = 1, WAIT_RESP = 2, SEND_CMD17 = 3,
//           WAIT_TOKEN = 4, READ_BYTES = 5, DONE = 6, ERROR = 7;
//
//reg [3:0] state;
//reg [5:0] bitpos;          // 0..47, or 0..7 for byte
//reg [47:0] shift48;
//reg [7:0] shift8;
//reg [8:0] byte_count;
//reg [15:0] timeout;        // small timeout counters for safety
//
//// helper: write single byte to UART (blocking one-cycle request)
//task uart_put_byte (input [7:0] b);
//begin
//    uart_data <= {24'd0, b};
//    uart_write <= 1;
//    @(posedge CLOCK_50); // allow handshake pulse to be seen next cycle
//    uart_write <= 0;
//end
//endtask
//
//// initialization: a small startup wait, then send CMD0
//always @(posedge CLOCK_50 or negedge reset_n) begin
//    if(!reset_n) begin
//        SD_CLK <= 0;
//        sd_mosi_o <= 1'b1;
//        sd_mosi_oe <= 1'b1;
//        state <= IDLE;
//        bitpos <= 0;
//        shift48 <= 0;
//        shift8 <= 0;
//        byte_count <= 0;
//        timeout <= 0;
//        uart_write <= 0;
//    end else begin
//        // only proceed SPI actions on spi_edge (slowed clock)
//        if(spi_edge) begin
//            case(state)
//                IDLE: begin
//                    // small startup delay to let card power-up (many cycles)
//                    if(timeout < 16'h7FFF) timeout <= timeout + 1;
//                    else begin
//                        // print "S" then prepare CMD0: 0x40 00 00 00 00 95
//                        uart_data <= {24'd0, "S"};
//                        uart_write <= 1;
//                        // load CMD0 into shift48 (MSB first)
//                        shift48 <= 48'h40_00_00_00_00_95;
//                        bitpos <= 47;
//                        sd_mosi_oe <= 1;
//                        SD_CLK <= 0;
//                        timeout <= 0;
//                        state <= SEND_CMD;
//                    end
//                end
//
//                SEND_CMD: begin
//                    // toggle SD_CLK and shift bits on MOSI on the rising half
//                    SD_CLK <= ~SD_CLK;
//                    if(SD_CLK) begin
//                        // on rising edge sample MOSI out bit
//                        sd_mosi_o <= shift48[bitpos];
//                        if(bitpos == 0) begin
//                            // finished sending 48 bits
//                            sd_mosi_oe <= 0; // release line, card drives responses
//                            bitpos <= 0;
//                            shift8 <= 8'hFF;
//                            timeout <= 0;
//                            state <= WAIT_RESP;
//                            // print marker once
//                            uart_data <= {24'd0, "C"};
//                            uart_write <= 1;
//                        end else bitpos <= bitpos - 1;
//                    end
//                end
//
//                WAIT_RESP: begin
//                    // Keep toggling SD_CLK and shift in bits from MISO,
//                    // assembling bytes; wait until a byte != 0xFF (response).
//                    SD_CLK <= ~SD_CLK;
//                    if(SD_CLK) begin
//                        // shift in one bit (MSB first)
//                        shift8 <= {shift8[6:0], sd_miso};
//                        if(bitpos < 7) bitpos <= bitpos + 1;
//                        else begin
//                            // one byte received
//                            bitpos <= 0;
//                            if(shift8 != 8'hFF) begin
//                                // got response (likely 0x01 for CMD0)
//                                // prepare CMD17 frame: 0x51 + addr(0) + CRC 0xFF
//                                shift48 <= 48'h51_00_00_00_00_FF; // 0x51 = 0x40|0x11 (CMD17)
//                                bitpos <= 47;
//                                sd_mosi_oe <= 1;
//                                SD_CLK <= 0;
//                                timeout <= 0;
//                                state <= SEND_CMD17;
//                                // mark that response was seen
//                                uart_data <= {24'd0, "R"};
//                                uart_write <= 1;
//                            end else begin
//                                // still 0xFF; keep waiting
//                                timeout <= timeout + 1;
//                                if(timeout == 16'hFFFF) begin
//                                    // timeout -> error
//                                    state <= ERROR;
//                                end
//                            end
//                        end
//                    end
//                end
//
//                SEND_CMD17: begin
//                    // Shift out CMD17 48 bits similarly to SEND_CMD
//                    SD_CLK <= ~SD_CLK;
//                    if(SD_CLK) begin
//                        sd_mosi_o <= shift48[bitpos];
//                        if(bitpos == 0) begin
//                            sd_mosi_oe <= 0; // release MOSI for response/data
//                            bitpos <= 0;
//                            shift8 <= 8'hFF;
//                            timeout <= 0;
//                            state <= WAIT_TOKEN;
//                        end else bitpos <= bitpos - 1;
//                    end
//                end
//
//                WAIT_TOKEN: begin
//                    // After CMD17, the card may send some 0xFF bytes, then 0xFE token.
//                    SD_CLK <= ~SD_CLK;
//                    if(SD_CLK) begin
//                        shift8 <= {shift8[6:0], sd_miso};
//                        if(bitpos < 7) bitpos <= bitpos + 1;
//                        else begin
//                            bitpos <= 0;
//                            if(shift8 == 8'hFE) begin
//                                // token received: start reading 512 bytes
//                                byte_count <= 0;
//                                bitpos <= 0;
//                                timeout <= 0;
//                                state <= READ_BYTES;
//                                // optional marker
//                                uart_data <= {24'd0, "T"}; // token
//                                uart_write <= 1;
//                            end else begin
//                                timeout <= timeout + 1;
//                                if(timeout == 16'hFFFF) state <= ERROR;
//                            end
//                        end
//                    end
//                end
//
//                READ_BYTES: begin
//                    // Read 512 bytes; shift bits from sd_miso
//                    SD_CLK <= ~SD_CLK;
//                    if(SD_CLK) begin
//                        shift8 <= {shift8[6:0], sd_miso};
//                        if(bitpos < 7) bitpos <= bitpos + 1;
//                        else begin
//                            // one full byte ready
//                            bitpos <= 0;
//                            // stream to UART (non-blocking write request)
//                            uart_data <= {24'd0, shift8};
//                            uart_write <= 1;
//                            byte_count <= byte_count + 1;
//                            if(byte_count == 9'd511) begin
//                                state <= DONE;
//                                timeout <= 0;
//                            end
//                        end
//                    end
//                end
//
//                DONE: begin
//                    // finished reading 512 bytes; signal done
//                    uart_data <= {24'd0, "D"};
//                    uart_write <= 1;
//                    // hold here
//                    SD_CLK <= 0;
//                    sd_mosi_oe <= 0;
//                    // state stays DONE
//                end
//
//                ERROR: begin
//                    uart_data <= {24'd0, "E"}; uart_write <= 1;
//                    SD_CLK <= 0;
//                    sd_mosi_oe <= 0;
//                end
//
//                default: state <= ERROR;
//            endcase
//        end else begin
//            // not spi edge: clear uart_write pulse to 0 (we pulse it one clock)
//            uart_write <= 0;
//        end
//    end
//end
//
//endmodule





//module cpu_on_board (
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    (* chip_pin = "V20" *) output wire SD_CLK,  // SD_CLK
//    (* chip_pin = "Y20" *) inout  wire SD_CMD,  // SD_CMD
//    (* chip_pin = "W20" *) inout  wire SD_DAT0, // SD_DAT0
//    (* chip_pin = "U20" *) output wire SD_DAT3  // SD_DAT3 / CS
//
//
//);
//
////=======================================================
//// Reset and LED blink
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
//// UART debug (JTAG UART)
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
//// Instantiate SD card interface (from your code)
////=======================================================
//wire [2:0]  sd_addr;
//wire        sd_read, sd_write, sd_begin;
//wire [31:0] sd_wdata;
//wire [31:0] sd_rdata;
//
//SdCardSlave sd0 (
//    .clk(CLOCK_50),
//    .reset(~reset_n),
//    .address(sd_addr),
//    .read(sd_read),
//    .write(sd_write),
//    .writedata(sd_wdata),
//    .readdata(sd_rdata),
//    .begintransfer(sd_begin),
//    .SD_CLK(SD_CLK),
//    .SD_CMD(SD_CMD),
//    .SD_DAT(SD_DAT0),
//    .SD_DAT3(SD_DAT3)
//);
//
////=======================================================
//// Minimal test FSM
////=======================================================
//reg [3:0] state;
//reg [31:0] counter;
//
//assign sd_begin = 1'b1;
//
//reg [2:0]  addr_r;
//reg        read_r, write_r;
//reg [31:0] wdata_r;
//
//assign sd_addr  = addr_r;
//assign sd_read  = read_r;
//assign sd_write = write_r;
//assign sd_wdata = wdata_r;
//
//always @(posedge CLOCK_50 or negedge reset_n) begin
//    if (!reset_n) begin
//        state <= 0;
//        uart_write <= 0;
//        counter <= 0;
//        addr_r <= 0;
//        read_r <= 0;
//        write_r <= 0;
//        wdata_r <= 0;
//    end else begin
//        uart_write <= 0;
//        read_r <= 0;
//        write_r <= 0;
//        counter <= counter + 1;
//
//        case (state)
//            0: begin
//                uart_data <= {24'd0, "R"}; uart_write <= 1;
//                state <= 1;
//            end
//
//            // Write CMD0 (reset command)
//            1: begin
//                addr_r <= 1; wdata_r <= 32'h00000000; write_r <= 1; // command low
//                state <= 2;
//            end
//            2: begin
//                addr_r <= 2; wdata_r <= 32'h00000000; write_r <= 1; // command high
//                state <= 3;
//            end
//            3: begin
//                addr_r <= 0; wdata_r <= 32'h1; write_r <= 1; // start command
//                state <= 4;
//            end
//            // Wait for completion flag
//            4: begin
//                addr_r <= 0; read_r <= 1;
//                if (sd_rdata[1]) begin // CMD finished
//                    uart_data <= {24'd0, "C"}; uart_write <= 1;
//                    state <= 5;
//                end
//            end
//
//            5: begin
//                uart_data <= {24'd0, "D"}; uart_write <= 1;
//                state <= 6; // new: move to idle
//            end
//
//            6: begin
//                // done, hold idle
//                state <= 6;
//            end
//
//        endcase
//    end
//end
//
//endmodule



//module cpu_on_board (
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    (* chip_pin = "V20" *) output wire SD_CLK,  // SD_CLK
//    (* chip_pin = "Y20" *) inout  wire SD_CMD,  // SD_CMD
//    (* chip_pin = "W20" *) inout  wire SD_DAT0, // SD_DAT0
//    (* chip_pin = "U20" *) output wire SD_DAT3  // SD_DAT3 / CS
//);
//
////=======================================================
//// Reset and LED blink
////=======================================================
//wire reset_n = KEY0;
//reg [23:0] blink_counter;
//always @(posedge CLOCK_50 or negedge reset_n)
//    if (!reset_n)
//        blink_counter <= 0;
//    else
//        blink_counter <= blink_counter + 1'b1;
//assign LEDR0 = blink_counter[23];
//
////=======================================================
//// UART debug (JTAG UART)
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
//// Instantiate SD card interface
////=======================================================
//wire [2:0]  sd_addr;
//wire        sd_read, sd_write, sd_begin;
//wire [31:0] sd_wdata;
//wire [31:0] sd_rdata;
//
//SdCardSlave sd0 (
//    .clk(CLOCK_50),
//    .reset(~reset_n),
//    .address(sd_addr),
//    .read(sd_read),
//    .write(sd_write),
//    .writedata(sd_wdata),
//    .readdata(sd_rdata),
//    .begintransfer(sd_begin),
//    .SD_CLK(SD_CLK),
//    .SD_CMD(SD_CMD),
//    .SD_DAT(SD_DAT0),
//    .SD_DAT3(SD_DAT3)
//);
//
////=======================================================
//// SD card command FSM
////=======================================================
//reg [4:0]  state;
//reg [31:0] counter;
//reg [2:0]  addr_r;
//reg        read_r, write_r;
//reg [31:0] wdata_r;
//
//assign sd_begin  = 1'b1;
//assign sd_addr   = addr_r;
//assign sd_read   = read_r;
//assign sd_write  = write_r;
//assign sd_wdata  = wdata_r;
//
//always @(posedge CLOCK_50 or negedge reset_n) begin
//    if (!reset_n) begin
//        state <= 0;
//        uart_write <= 0;
//        counter <= 0;
//        addr_r <= 0;
//        read_r <= 0;
//        write_r <= 0;
//        wdata_r <= 0;
//    end else begin
//        uart_write <= 0;
//        read_r <= 0;
//        write_r <= 0;
//
//        case (state)
//            0: begin
//                uart_data <= {24'd0, "R"}; uart_write <= 1;
//                state <= 1;
//            end
//
//            // CMD0 (reset)
//            1: begin
//                addr_r <= 1; wdata_r <= 32'h00000000; write_r <= 1; state <= 2;
//            end
//            2: begin
//                addr_r <= 2; wdata_r <= 32'h00000000; write_r <= 1; state <= 3;
//            end
//            3: begin
//                addr_r <= 0; wdata_r <= 32'h40 | 0; write_r <= 1; state <= 4; // CMD0
//            end
//            4: begin
//                addr_r <= 0; read_r <= 1;
//                uart_data <= {8'h00, 8'h00, 8'h30, sd_rdata[3:0] + 8'h30}; // print low bits as ASCII
//                uart_write <= 1;
//                if (sd_rdata[3]) begin
//                    uart_data <= {24'd0, "0"}; uart_write <= 1;
//                    state <= 5;
//                end
//            end
//
//            // CMD55 (APP_CMD)
//            5: begin
//                addr_r <= 1; wdata_r <= 32'h00000000; write_r <= 1; state <= 6;
//            end
//            6: begin
//                addr_r <= 2; wdata_r <= 32'h00000000; write_r <= 1; state <= 7;
//            end
//            7: begin
//                addr_r <= 0; wdata_r <= 32'h40 | 55; write_r <= 1; state <= 8;
//            end
//            8: begin
//                addr_r <= 0; read_r <= 1;
//                if (sd_rdata[3]) begin
//                    uart_data <= {24'd0, "5"}; uart_write <= 1;
//                    state <= 9;
//                end
//            end
//
//            // ACMD41 (init)
//            9: begin
//                addr_r <= 1; wdata_r <= 32'h40300000; write_r <= 1; state <= 10;
//            end
//            10: begin
//                addr_r <= 2; wdata_r <= 32'h00000000; write_r <= 1; state <= 11;
//            end
//            11: begin
//                addr_r <= 0; wdata_r <= 32'h40 | 41; write_r <= 1; state <= 12;
//            end
//            12: begin
//                addr_r <= 0; read_r <= 1;
//                if (sd_rdata[3]) begin
//                    uart_data <= {24'd0, "A"}; uart_write <= 1;
//                    state <= 13;
//                end
//            end
//
//            13: begin
//                uart_data <= {24'd0, "O"}; uart_write <= 1;
//                state <= 14;
//            end
//
//            14: begin
//                uart_data <= {24'd0, "D"}; uart_write <= 1;
//                state <= 15; // stop
//            end
//
//            15: state <= 15; // done
//        endcase
//    end
//end
//
//endmodule


module cpu_on_board (
    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
    (* chip_pin = "R20"     *) output wire LEDR0,

    (* chip_pin = "V20" *) output wire SD_CLK,  // SD_CLK
    (* chip_pin = "Y20" *) inout  wire SD_CMD,  // SD_CMD
    (* chip_pin = "W20" *) inout  wire SD_DAT0, // SD_DAT0
    (* chip_pin = "U20" *) output wire SD_DAT3  // SD_DAT3 / CS
);

//=======================================================
// Heartbeat LED
//=======================================================
wire reset_n = KEY0;
reg [23:0] blink_counter;

always @(posedge CLOCK_50 or negedge reset_n)
    if (!reset_n)
        blink_counter <= 0;
    else
        blink_counter <= blink_counter + 1'b1;

assign LEDR0 = blink_counter[23];

//=======================================================
// JTAG UART
//=======================================================
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
// SD card interface (minimal)
//=======================================================
wire [2:0]  sd_addr;
wire        sd_read, sd_write, sd_begin;
wire [31:0] sd_wdata;
wire [31:0] sd_rdata;

SdCardSlave sd0 (
    .clk(CLOCK_50),
    .reset(~reset_n),
    .address(sd_addr),
    .read(sd_read),
    .write(sd_write),
    .writedata(sd_wdata),
    .readdata(sd_rdata),
    .begintransfer(sd_begin),
    .SD_CLK(SD_CLK),
    .SD_CMD(SD_CMD),
    .SD_DAT(SD_DAT0),
    .SD_DAT3(SD_DAT3)
);

//=======================================================
// SD card command FSM (prints "0", "5", "A", "O", "D")
//=======================================================
reg [4:0]  state;
reg [2:0]  addr_r;
reg        read_r, write_r;
reg [31:0] wdata_r;

assign sd_begin  = 1'b1;
assign sd_addr   = addr_r;
assign sd_read   = read_r;
assign sd_write  = write_r;
assign sd_wdata  = wdata_r;

always @(posedge CLOCK_50 or negedge reset_n) begin
    if (!reset_n) begin
        state <= 0;
        uart_write <= 0;
        addr_r <= 0;
        read_r <= 0;
        write_r <= 0;
        wdata_r <= 0;
    end else begin
        uart_write <= 0;
        read_r <= 0;
        write_r <= 0;

        case (state)
            0: begin
                uart_data <= {24'd0, "R"}; uart_write <= 1;
                state <= 1;
            end

            // CMD0
            1: begin addr_r <= 1; wdata_r <= 32'h00000000; write_r <= 1; state <= 2; end
            2: begin addr_r <= 2; wdata_r <= 32'h00000000; write_r <= 1; state <= 3; end
            3: begin addr_r <= 0; wdata_r <= 32'h40; write_r <= 1; state <= 4; end
            4: begin
                addr_r <= 0; read_r <= 1;
                if (sd_rdata[3]) begin
                    uart_data <= {24'd0, "0"}; uart_write <= 1;
                    state <= 5;
                end
            end

            // CMD55
            5: begin addr_r <= 1; wdata_r <= 32'h00000000; write_r <= 1; state <= 6; end
            6: begin addr_r <= 2; wdata_r <= 32'h00000000; write_r <= 1; state <= 7; end
            7: begin addr_r <= 0; wdata_r <= 32'h40 | 55; write_r <= 1; state <= 8; end
            8: begin
                addr_r <= 0; read_r <= 1;
                if (sd_rdata[3]) begin
                    uart_data <= {24'd0, "5"}; uart_write <= 1;
                    state <= 9;
                end
            end

            // ACMD41
            9: begin addr_r <= 1; wdata_r <= 32'h40300000; write_r <= 1; state <= 10; end
            10: begin addr_r <= 2; wdata_r <= 32'h00000000; write_r <= 1; state <= 11; end
            11: begin addr_r <= 0; wdata_r <= 32'h40 | 41; write_r <= 1; state <= 12; end
            12: begin
                addr_r <= 0; read_r <= 1;
                if (sd_rdata[3]) begin
                    uart_data <= {24'd0, "A"}; uart_write <= 1;
                    state <= 13;
                end
            end

            13: begin uart_data <= {24'd0, "O"}; uart_write <= 1; state <= 14; end
            14: begin uart_data <= {24'd0, "D"}; uart_write <= 1; state <= 15; end
            15: state <= 15; // stop
        endcase
    end
end

endmodule
