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
//                    if (counter == 32'd4_000_000) begin
//                        uart_data <= {24'd0, "S"}; uart_write <= 1; state <= 1;
//                    end
//                end
//                1: begin uart_data <= {24'd0, "D"}; uart_write <= 1; state <= 2; end
//                2: begin uart_data <= {24'd0, " "}; uart_write <= 1; state <= 3; end
//                3: begin
//                    // Begin SPI CMD0 send
//                    Spi_selected <= 1'b1;
//                    bus_write_enable <= 1'b1;
//                    bus_address <= 3'd0;
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
//        .spi_0_reset_reset_n(KEY0),
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

    // ================================================================
    // UART for debug
    // ================================================================
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

    // ================================================================
    // SPI signals
    // ================================================================
    wire [15:0] spi_read_data_wire;
    reg [15:0] bus_write_data;
    reg [2:0]  bus_address;
    reg        bus_write_enable, bus_read_enable, Spi_selected;

    // ================================================================
    // CMD0 sequence state machine
    // ================================================================
    // --- START MINIMAL ADDITIONS ---
    // SPI Register Offsets (consistent with standard Altera/Intel SPI IP)
    localparam SPI_RXDATA      = 3'd0;
    localparam SPI_TXDATA      = 3'd1;
    localparam SPI_STATUS      = 3'd2;
    // localparam SPI_CONTROL     = 3'd3; // Not strictly needed for this example
    localparam SPI_SLAVESELECT = 3'd4; // To control external SS_n directly

    // Status Register Bits
    localparam TRDY_BIT = 5; // Transmit Ready
    localparam RRDY_BIT = 6; // Receive Ready

    // State definitions
    localparam S_IDLE              = 4'd0; // Original state 0
    localparam S_PRINT_SD_PRE      = 4'd1; // Original state 1 "S"
    localparam S_PRINT_SD_MID      = 4'd2; // Original state 2 "D"
    localparam S_PRINT_SD_POST     = 4'd3; // Original state 3 " "
    localparam S_POWER_ON_CLK      = 4'd4; // NEW: Send 10 dummy 0xFF bytes with CS high
    localparam S_CMD0_TX           = 4'd5; // Original states 3-8, now with TRDY checks
    localparam S_CMD0_RX_POLL      = 4'd6; // Original state 9-10, now with RRDY checks & polling
    localparam S_PRINT_R1          = 4'd7; // Original state 10 printing result
    localparam S_DONE_ERROR        = 4'd8; // Original state 11 + error handling

    reg [7:0] cmd[0:5];
    reg [3:0] state;
    reg [31:0] byte_counter; // Renamed 'counter' to 'byte_counter' for clarity
    reg [7:0] sd_r1_response; // To store the R1 response
    // --- END MINIMAL ADDITIONS ---

    initial begin // CMD0
        cmd[0] = 8'h40;
        cmd[1] = 8'h00;
        cmd[2] = 8'h00;
        cmd[3] = 8'h00;
        cmd[4] = 8'h00;
        cmd[5] = 8'h95;
    end

    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            uart_data <= 0;
            uart_write <= 0;
            state <= S_IDLE; // Use named state
            Spi_selected <= 0; // CS high
            bus_write_enable <= 0;
            bus_read_enable <= 0;
            byte_counter <= 0; // Use named counter
            sd_r1_response <= 8'hFF; // Initialize
        end else begin
            uart_write <= 0;  // default off
            // byte_counter <= byte_counter + 1; // Removed from here, handled per state for specific counts

            case (state)
                S_IDLE: begin // Original state 0: Wait for a bit
                    byte_counter <= byte_counter + 1; // Use for delay
                    if (byte_counter == 32'd4_000_000) begin
                        byte_counter <= 0; // Reset for next stage
                        state <= S_PRINT_SD_PRE;
                    end
                end
                S_PRINT_SD_PRE: begin // Original state 1: "S"
                    uart_data <= {24'd0, "S"}; uart_write <= 1;
                    state <= S_PRINT_SD_MID;
                end
                S_PRINT_SD_MID: begin // Original state 2: "D"
                    uart_data <= {24'd0, "D"}; uart_write <= 1;
                    state <= S_PRINT_SD_POST;
                end
                S_PRINT_SD_POST: begin // Original state 3: " "
                    uart_data <= {24'd0, " "}; uart_write <= 1;
                    byte_counter <= 0; // Reset for S_POWER_ON_CLK
                    state <= S_POWER_ON_CLK; // NEW: Go to power-on clocking
                end

                S_POWER_ON_CLK: begin // NEW: Send 10 dummy 0xFF bytes with CS high
                    Spi_selected <= 0; // Ensure CS is HIGH
                    bus_address <= SPI_STATUS;
                    bus_read_enable <= 1'b1; // Check status for TRDY

                    if (spi_read_data_wire[TRDY_BIT]) begin // Only proceed if TX is ready
                        bus_address <= SPI_TXDATA; // Write to TX register
                        bus_write_data <= 16'hFF; // Send 0xFF dummy byte
                        bus_write_enable <= 1'b1;
                        byte_counter <= byte_counter + 1;
                        if (byte_counter == 10) begin // After 10 dummy bytes
                            byte_counter <= 0; // Reset for CMD0 byte index
                            state <= S_CMD0_TX; // Go to CMD0 transmission
                        end
                    end
                end

                S_CMD0_TX: begin // Original states 3-8, now consolidated and fixed
                    Spi_selected <= 1'b1; // Assert CS (SS_n low)
                    if (byte_counter == 0) begin // Only do this once at the start of CMD0_TX
                        bus_address <= SPI_SLAVESELECT; // Select slave 0
                        bus_write_enable <= 1'b1;
                        bus_write_data <= 16'd0; // Write 0 to assert CS
                    end

                    bus_address <= SPI_STATUS;
                    bus_read_enable <= 1'b1; // Check status for TRDY
                    if (spi_read_data_wire[TRDY_BIT]) begin // Only proceed if TX is ready
                        bus_address <= SPI_TXDATA; // Correct address for TX
                        bus_write_enable <= 1'b1;
                        bus_write_data <= {8'd0, cmd[byte_counter]};

                        byte_counter <= byte_counter + 1;
                        if (byte_counter == 6) begin // All 6 bytes of CMD0 sent
                            byte_counter <= 0; // Reset for response polling
                            state <= S_CMD0_RX_POLL; // Go to response polling
                        end
                    end
                end

                S_CMD0_RX_POLL: begin // Original state 9-10, now with RRDY checks & polling
                    Spi_selected <= 1'b1; // Keep CS asserted
                    bus_address <= SPI_STATUS;
                    bus_read_enable <= 1'b1; // Check status for RRDY

                    if (spi_read_data_wire[RRDY_BIT]) begin // If a byte has been received
                        bus_address <= SPI_RXDATA;
                        bus_read_enable <= 1'b1; // Read the received byte
                        sd_r1_response <= spi_read_data_wire[7:0]; // Store response

                        if (sd_r1_response == 8'h01) begin // Expected R1 response for CMD0
                            state <= S_PRINT_R1; // Success! Print the result.
                        end else if (byte_counter < 100 && sd_r1_response == 8'hFF) begin
                            // Keep polling: SD cards send 0xFF until response is ready
                            byte_counter <= byte_counter + 1;
                            // Stay in this state; the next clock cycle will send another dummy byte via TRDY
                        end else if (sd_r1_response != 8'hFF) begin // Unexpected R1
                            uart_data <= {24'd0, 8'h45}; // Print 'E' for Error
                            uart_write <= 1;
                            state <= S_DONE_ERROR;
                        end else begin // Timeout after 100 attempts without 0x01
                            uart_data <= {24'd0, 8'h54}; // Print 'T' for Timeout
                            uart_write <= 1;
                            state <= S_DONE_ERROR;
                        end
                    end else if (spi_read_data_wire[TRDY_BIT]) begin
                        // If no data received, but TX is ready, send a dummy byte to clock MISO
                        bus_address <= SPI_TXDATA;
                        bus_write_enable <= 1'b1;
                        bus_write_data <= 16'hFF;
                    end
                end

                S_PRINT_R1: begin // Original state 10 printing result
                    uart_data <= {24'd0, sd_r1_response + 8'h30}; // Convert 0x01 to ASCII '1'
                    uart_write <= 1;
                    state <= S_DONE_ERROR;
                end

                S_DONE_ERROR: begin // Original state 11: Halt
                    Spi_selected <= 0; // De-assert CS
                    state <= S_DONE_ERROR;
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
        .spi_0_reset_reset_n(KEY0),
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

    // LEDR0 is high if not in DONE or ERROR state
    assign LEDR0 = (state != S_DONE_ERROR);

endmodule
