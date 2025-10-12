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
//endmodule
//
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








//// ============================================================
//// Minimal SD-card init test
//// Prints:  "S" then "D1" if CMD0 OK, "D/" if timeout
//// ============================================================
module cpu_on_board (
    // -- Pins --
    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
    (* chip_pin = "R20"     *) output wire LEDR0,

    (* chip_pin = "V20" *) output wire SPI_SCLK,  // SD_CLK
    (* chip_pin = "Y20" *) output wire SPI_MOSI,  // SD_CMD
    (* chip_pin = "W20" *) input  wire SPI_MISO,  // SD_DAT0
    (* chip_pin = "U20" *) output wire SPI_SS_n   // SD_DAT3 / CS
);

    // ----------------------------
    // UART (JTAG UART simple)
    // ----------------------------
    reg  [31:0] uart_data;
    reg         uart_write;
    jtag_uart_system uart0 (
        .clk_clk(CLOCK_50),
        .reset_reset_n(KEY0),
        .jtag_uart_0_avalon_jtag_slave_address(1'b0),
        .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
        .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
    );

    // ----------------------------
    // SPI bus control signals
    // ----------------------------
    wire [15:0] spi_read_data_wire;
    reg  [15:0] bus_write_data;
    reg  [2:0]  bus_address;
    reg         bus_write_enable, bus_read_enable, Spi_selected;

    // SPI register offsets (Altera core)
    localparam SPI_RXDATA      = 3'd0;
    localparam SPI_TXDATA      = 3'd1;
    localparam SPI_STATUS      = 3'd2;
    localparam SPI_SLAVESELECT = 3'd4;

    localparam TRDY_BIT = 5;
    localparam RRDY_BIT = 6;

    // ----------------------------
    // State machine
    // ----------------------------
    localparam S_IDLE         = 0;
    localparam S_PRINT_S      = 1;
    localparam S_DUMMY_INIT   = 2;
    localparam S_WAIT_TRDY    = 3;
    localparam S_SEND_DUMMY   = 4;
    localparam S_ASSERT_CS    = 5;
    localparam S_SEND_CMD     = 6;
    localparam S_WAIT_RRDY    = 7;
    localparam S_READ_RESP    = 8;
    localparam S_CHECK_RESP   = 9;
    localparam S_PRINT_RESULT = 10;
    localparam S_DONE         = 11;

    reg [3:0]  state;
    reg [7:0]  cmd[0:5];
    reg [7:0]  response;
    reg [7:0]  dummy_count;
    reg [7:0]  cmd_index;
    reg [7:0]  poll_count;
    reg [31:0] delay_count;

    initial begin
        cmd[0] = 8'h40; // CMD0
        cmd[1] = 8'h00;
        cmd[2] = 8'h00;
        cmd[3] = 8'h00;
        cmd[4] = 8'h00;
        cmd[5] = 8'h95; // CRC for CMD0
    end

    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            uart_data <= 0;
            uart_write <= 0;
            state <= S_IDLE;
            Spi_selected <= 0;
            bus_write_enable <= 0;
            bus_read_enable  <= 0;
            delay_count <= 0;
            dummy_count <= 0;
            cmd_index <= 0;
            poll_count <= 0;
            response <= 8'hFF;
        end else begin
            // defaults
            uart_write <= 0;
            bus_write_enable <= 0;
            bus_read_enable  <= 0;
            Spi_selected <= 0;

            case (state)
                // ------------------------------------------------------
                S_IDLE: begin
                    if (delay_count < 32'd2_000_000)
                        delay_count <= delay_count + 1;
                    else begin
                        uart_data <= {24'd0, "S"};
                        uart_write <= 1;
                        delay_count <= 0;
                        state <= S_DUMMY_INIT;
                        dummy_count <= 10; // 10 bytes * 8 = 80 clocks
                    end
                end

                // ------------------------------------------------------
                S_DUMMY_INIT: begin
                    Spi_selected <= 1'b1;
                    bus_read_enable <= 1'b1;
                    bus_address <= SPI_STATUS;
                    if (spi_read_data_wire[TRDY_BIT]) begin
                        bus_write_enable <= 1'b1;
                        bus_address <= SPI_TXDATA;
                        bus_write_data <= 16'hFF;
                        dummy_count <= dummy_count - 1;
                        if (dummy_count == 1)
                            state <= S_ASSERT_CS;
                    end
                end

                // ------------------------------------------------------
                S_ASSERT_CS: begin
                    // Assert chip select (slave 0)
                    Spi_selected <= 1'b1;
                    bus_write_enable <= 1'b1;
                    bus_address <= SPI_SLAVESELECT;
                    bus_write_data <= 16'd1;
                    cmd_index <= 0;
                    state <= S_SEND_CMD;
                end

                // ------------------------------------------------------
                S_SEND_CMD: begin
                    Spi_selected <= 1'b1;
                    bus_read_enable <= 1'b1;
                    bus_address <= SPI_STATUS;
                    if (spi_read_data_wire[TRDY_BIT]) begin
                        bus_write_enable <= 1'b1;
                        bus_address <= SPI_TXDATA;
                        bus_write_data <= {8'd0, cmd[cmd_index]};
                        if (cmd_index == 5) begin
                            poll_count <= 100;
                            state <= S_WAIT_RRDY;
                        end else
                            cmd_index <= cmd_index + 1;
                    end
                end

                // ------------------------------------------------------
                S_WAIT_RRDY: begin
                    Spi_selected <= 1'b1;
                    bus_read_enable <= 1'b1;
                    bus_address <= SPI_STATUS;
                    if (spi_read_data_wire[RRDY_BIT]) begin
                        state <= S_READ_RESP;
                    end else if (poll_count == 0)
                        state <= S_PRINT_RESULT;
                    else begin
                        poll_count <= poll_count - 1;
                        // send dummy 0xFF to keep clocking
                        if (spi_read_data_wire[TRDY_BIT]) begin
                            bus_write_enable <= 1'b1;
                            bus_address <= SPI_TXDATA;
                            bus_write_data <= 16'hFF;
                        end
                    end
                end

                // ------------------------------------------------------
                S_READ_RESP: begin
                    Spi_selected <= 1'b1;
                    bus_read_enable <= 1'b1;
                    bus_address <= SPI_RXDATA;
                    response <= spi_read_data_wire[7:0];
                    state <= S_CHECK_RESP;
                end

                // ------------------------------------------------------
                S_CHECK_RESP: begin
                    if (response != 8'hFF)
                        state <= S_PRINT_RESULT;
                    else if (poll_count > 0)
                        state <= S_WAIT_RRDY;
                    else
                        state <= S_PRINT_RESULT;
                end

                // ------------------------------------------------------
                S_PRINT_RESULT: begin
                    uart_data <= {24'd0, (response == 8'h01) ? "1" :
                                           (response == 8'hFF) ? "/" : "0"};
                    uart_write <= 1;
                    state <= S_DONE;
                end

                // ------------------------------------------------------
                S_DONE: begin
                    // idle forever
                    Spi_selected <= 1'b0;
                end
            endcase
        end
    end

    // ================================================================
    // SPI IP instantiation
    // ================================================================
    spi my_spi_system (
        .clk_clk(CLOCK_50),
        .reset_reset_n(KEY0),
        .spi_0_spi_control_port_chipselect (Spi_selected),
        .spi_0_spi_control_port_address    (bus_address),
        .spi_0_spi_control_port_read_n     (~(bus_read_enable && Spi_selected)),
        .spi_0_spi_control_port_readdata   (spi_read_data_wire),
        .spi_0_spi_control_port_write_n    (~(bus_write_enable && Spi_selected)),
        .spi_0_spi_control_port_writedata  (bus_write_data),
        .spi_0_external_MISO(SPI_MISO),
        .spi_0_external_MOSI(SPI_MOSI),
        .spi_0_external_SCLK(SPI_SCLK),
        .spi_0_external_SS_n(SPI_SS_n)
    );

    assign LEDR0 = ~state[0]; // activity indicator

endmodule






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
//    // ----------------------------
//    // UART (JTAG UART simple)
//    // ----------------------------
//    reg  [31:0] uart_data;
//    reg         uart_write;
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
//    // ----------------------------
//    // SPI control signals
//    // ----------------------------
//    wire [15:0] spi_read_data_wire;
//    reg  [15:0] bus_write_data;
//    reg  [2:0]  bus_address;
//    reg         bus_write_enable, bus_read_enable, Spi_selected;
//
//    // SPI register offsets
//    localparam SPI_RXDATA      = 3'd0;
//    localparam SPI_TXDATA      = 3'd1;
//    localparam SPI_STATUS      = 3'd2;
//    localparam SPI_CONTROL     = 3'd3;
//    localparam SPI_SLAVESELECT = 3'd4;
//
//    localparam TRDY_BIT = 5;
//    localparam RRDY_BIT = 6;
//
//    // ----------------------------
//    // State machine
//    // ----------------------------
//    localparam S_IDLE        = 0;
//    localparam S_INIT_CTRL   = 1;
//    localparam S_PRINT_S     = 2;
//    localparam S_SEND_DUMMY  = 3;
//    localparam S_ASSERT_CS   = 4;
//    localparam S_SEND_CMD    = 5;
//    localparam S_WAIT_RESP   = 6;
//    localparam S_READ_RESP   = 7;
//    localparam S_PRINT_D     = 8;
//    localparam S_DONE        = 9;
//
//    reg [3:0]  state;
//    reg [7:0]  cmd[0:5];
//    reg [7:0]  response;
//    reg [7:0]  dummy_count;
//    reg [7:0]  cmd_index;
//    reg [31:0] delay_count;
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
//            state <= S_IDLE;
//            Spi_selected <= 0;
//            bus_write_enable <= 0;
//            bus_read_enable <= 0;
//            response <= 8'hFF;
//            delay_count <= 0;
//            dummy_count <= 0;
//            cmd_index <= 0;
//        end else begin
//            uart_write <= 0;
//            bus_write_enable <= 0;
//            bus_read_enable  <= 0;
//            Spi_selected <= 0;
//
//            case (state)
//                // ------------------------------------------------------
//                S_IDLE: begin
//                    // configure SPI control register
//                    Spi_selected <= 1'b1;
//                    bus_write_enable <= 1'b1;
//                    bus_address <= SPI_CONTROL;
//                    bus_write_data <= 16'h0100; // enable master mode
//                    state <= S_PRINT_S;
//                end
//
//                // ------------------------------------------------------
//                S_PRINT_S: begin
//                    uart_data <= {24'd0, "S"};
//                    uart_write <= 1;
//                    dummy_count <= 10;
//                    state <= S_SEND_DUMMY;
//                end
//
//                // ------------------------------------------------------
//                S_SEND_DUMMY: begin
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1;
//                    bus_address <= SPI_STATUS;
//                    if (spi_read_data_wire[TRDY_BIT]) begin
//                        bus_write_enable <= 1'b1;
//                        bus_address <= SPI_TXDATA;
//                        bus_write_data <= 16'hFF;
//                        dummy_count <= dummy_count - 1;
//                        if (dummy_count == 1)
//                            state <= S_ASSERT_CS;
//                    end
//                end
//
//                // ------------------------------------------------------
//                S_ASSERT_CS: begin
//                    Spi_selected <= 1'b1;
//                    bus_write_enable <= 1'b1;
//                    bus_address <= SPI_SLAVESELECT;
//                    bus_write_data <= 16'd1; // select SD card
//                    cmd_index <= 0;
//                    state <= S_SEND_CMD;
//                end
//
//                // ------------------------------------------------------
//                S_SEND_CMD: begin
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1;
//                    bus_address <= SPI_STATUS;
//                    if (spi_read_data_wire[TRDY_BIT]) begin
//                        bus_write_enable <= 1'b1;
//                        bus_address <= SPI_TXDATA;
//                        bus_write_data <= {8'd0, cmd[cmd_index]};
//                        if (cmd_index == 5) begin
//                            state <= S_WAIT_RESP;
//                        end else begin
//                            cmd_index <= cmd_index + 1;
//                        end
//                    end
//                end
//
//                // ------------------------------------------------------
//                S_WAIT_RESP: begin
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1;
//                    bus_address <= SPI_STATUS;
//                    if (spi_read_data_wire[TRDY_BIT]) begin
//                        bus_write_enable <= 1'b1;
//                        bus_address <= SPI_TXDATA;
//                        bus_write_data <= 16'hFF; // dummy read
//                        state <= S_READ_RESP;
//                    end
//                end
//
//                // ------------------------------------------------------
//                S_READ_RESP: begin
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1;
//                    bus_address <= SPI_RXDATA;
//                    response <= spi_read_data_wire[7:0];
//                    state <= S_PRINT_D;
//                end
//
//                // ------------------------------------------------------
//                S_PRINT_D: begin
//                    uart_data <= {24'd0, (response == 8'h01) ? "1" :
//                                           (response == 8'hFF) ? "/" : "0"};
//                    uart_write <= 1;
//                    state <= S_DONE;
//                end
//
//                // ------------------------------------------------------
//                S_DONE: begin
//                    Spi_selected <= 0;
//                end
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
//    assign LEDR0 = ~state[0];
//
//endmodule
//
//
//
//
//
