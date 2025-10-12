// 74 cycles 0xFF to MOSI
// CMD0
// Assume the register offsets within the SPI core are:
// 0x0: rxdata (Read-Only)
// 0x4: txdata (Write-Only)
// 0x8: status (Read-Only)
// 0xC: control (Read/Write)
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

// SD card CMD0 test — minimal working sequence (by ChatGPT-5)
// Sends 80 dummy clocks, enters SPI mode, sends CMD0, prints response

module cpu_on_board (
    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
    (* chip_pin = "R20"     *) output wire LEDR0,

    (* chip_pin = "V20" *) output wire SPI_SCLK,  // SD_CLK
    (* chip_pin = "Y20" *) output wire SPI_MOSI,  // SD_CMD
    (* chip_pin = "W20" *) input  wire SPI_MISO,  // SD_DAT0
    (* chip_pin = "U20" *) output wire SPI_SS_n   // SD_DAT3 / CS
);

    // UART
    reg [31:0] uart_data;
    reg        uart_write;

    jtag_uart_system uart0 (
        .clk_clk(CLOCK_50),
        .reset_reset_n(KEY0),
        .jtag_uart_0_avalon_jtag_slave_address(1'b0),
        .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
        .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
    );

    // SPI interface wires
    wire [15:0] spi_read_data_wire;
    reg  [15:0] bus_write_data;
    reg  [2:0]  bus_address;
    reg         bus_write_enable, bus_read_enable, Spi_selected;

    // CMD0 contents
    reg [7:0] cmd[0:5];
    reg [3:0] state;
    reg [31:0] counter;
    reg [7:0] response;
    reg [6:0] dummy_count;

    initial begin
        cmd[0] = 8'h40;  // CMD0
        cmd[1] = 8'h00;
        cmd[2] = 8'h00;
        cmd[3] = 8'h00;
        cmd[4] = 8'h00;
        cmd[5] = 8'h95;  // CRC
    end

    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            state <= 0;
            uart_write <= 0;
            Spi_selected <= 0;
            bus_write_enable <= 0;
            bus_read_enable <= 0;
            counter <= 0;
            dummy_count <= 0;
            response <= 8'hFF;
        end else begin
            uart_write <= 0;
            bus_write_enable <= 0;
            bus_read_enable <= 0;
            Spi_selected <= 1'b1;  // Always select bus

            case (state)
                // Wait some time after power-up
                0: begin
                    if (counter == 32'd2_000_000) begin
                        uart_data <= {24'd0, "S"}; uart_write <= 1;
                        counter <= 0; state <= 1;
                    end else counter <= counter + 1;
                end

                // Send 80 dummy clocks (10 bytes of 0xFF with CS high)
                1: begin
                    Spi_selected <= 1'b0; // CS high
                    if (dummy_count < 10) begin
                        bus_write_enable <= 1'b1;
                        bus_address <= 3'd1;  // TXDATA
                        bus_write_data <= 16'hFF;
                        dummy_count <= dummy_count + 1;
                    end else begin
                        dummy_count <= 0;
                        state <= 2;
                    end
                end

                // Assert CS low and start CMD0
                2: begin
                    Spi_selected <= 1'b1; // CS low (active)
                    counter <= 0;
                    state <= 3;
                end

                // Send all 6 bytes of CMD0
                3: begin
                    if (counter < 6) begin
                        bus_write_enable <= 1'b1;
                        bus_address <= 3'd1;
                        bus_write_data <= {8'd0, cmd[counter]};
                        counter <= counter + 1;
                    end else begin
                        counter <= 0;
                        state <= 4;
                    end
                end

                // Send dummy bytes until response != 0xFF or timeout
                4: begin
                    if (counter < 255) begin
                        bus_write_enable <= 1'b1;
                        bus_address <= 3'd1;
                        bus_write_data <= 16'hFF;
                        bus_read_enable <= 1'b1;
                        bus_address <= 3'd0;
                        response <= spi_read_data_wire[7:0];
                        counter <= counter + 1;
                        if (response != 8'hFF) state <= 5;
                    end else state <= 5;
                end

                // Print result
                5: begin
                    uart_data <= {24'd0, "D"}; uart_write <= 1;
                    state <= 6;
                end
                6: begin
                    uart_data <= {24'd0, " "}; uart_write <= 1;
                    state <= 7;
                end
                7: begin
                    uart_data <= {24'd0, response[3:0] + 8'h30};
                    uart_write <= 1;
                    state <= 8;
                end
                default: state <= 8;
            endcase
        end
    end

    // SPI IP
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

    assign LEDR0 = Spi_selected;

endmodule
