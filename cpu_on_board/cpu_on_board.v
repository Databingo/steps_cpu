//module cpu_on_board (
//    // -- Pin mapping --
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    (* chip_pin = "V20" *) output wire SPI_SCLK,  // SD_CLK
//    (* chip_pin = "Y20" *) output wire SPI_MOSI,  // SD_CMD
//    (* chip_pin = "W20" *) input  wire SPI_MISO,  // SD_DAT0
//    (* chip_pin = "U20" *) output wire SPI_SS_n   // SD_CS
//);
//
//    // ================================================================
//    // 1. UART Test: print "A" periodically through JTAG UART IP
//    // ================================================================
//    reg [31:0] uart_data;
//    reg uart_write;
//    reg [23:0] counter;
//
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0) begin
//            counter <= 0;
//            uart_data <= 32'h41;   // ASCII "A"
//            uart_write <= 0;
//        end else begin
//            counter <= counter + 1;
//            if (counter == 24'd12_000_000) begin  // roughly every 0.24 sec at 50MHz
//                uart_write <= 1;
//            end else if (counter == 24'd12_000_010) begin
//                uart_write <= 0;
//                counter <= 0;
//            end
//        end
//    end
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
//    // 2. SPI Test: basic toggle of SPI lines via IP core
//    // ================================================================
//    wire [15:0] spi_read_data_wire;
//    reg [15:0] bus_write_data;
//    reg [2:0]  bus_address;
//    reg        bus_write_enable, bus_read_enable, Spi_selected;
//
//    // Dummy activity to verify SPI toggling
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0) begin
//            bus_write_data   <= 16'hA5A5;
//            bus_write_enable <= 1'b0;
//            bus_read_enable  <= 1'b0;
//            Spi_selected     <= 1'b0;
//            bus_address      <= 3'b000;
//        end else begin
//            bus_write_enable <= ~bus_write_enable; // toggle to make SPI clock visible
//            Spi_selected     <= 1'b1;
//        end
//    end
//
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
//    // LED blinks as SPI toggles
//    assign LEDR0 = Spi_selected;
//
//endmodule
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
//    initial begin
//        cmd[0] = 8'h40; cmd[1] = 8'h00; cmd[2] = 8'h00; cmd[3] = 8'h00; cmd[4] = 8'h00; cmd[5] = 8'h95;
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
//                    if (counter == 32'd2_000_000) begin
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
//
// progress by gemini2.5
// A top-level module to test the Altera SPI Core with a hardware state machine.
// It sends CMD0 to an SD card and prints the response to the JTAG UART.

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
//    // JTAG UART for debug output
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
//    // Bus signals to control peripherals
//    // ================================================================
//    wire [15:0] spi_read_data_wire;
//    reg  [15:0] bus_write_data;
//    reg  [2:0]  bus_address;
//    reg         bus_write_enable, bus_read_enable, Spi_selected;
//
//    // ================================================================
//    // Test state machine
//    // ================================================================
//
//    // --- NEW: Define constants for clarity ---
//    // State definitions
//    localparam S_START           = 5'd0;
//    localparam S_POWER_ON_DELAY  = 5'd1;
//    localparam S_POWER_ON_WRITE  = 5'd2;
//    localparam S_POWER_ON_WAIT   = 5'd3;
//    localparam S_ASSERT_SS       = 5'd4;
//    localparam S_CMD_WAIT_TRDY   = 5'd5;
//    localparam S_CMD_WRITE       = 5'd6;
//    localparam S_POLL_RESPONSE   = 5'd7;
//    localparam S_POLL_WAIT_TRDY  = 5'd8;
//    localparam S_POLL_WRITE_DUMMY= 5'd9;
//    localparam S_POLL_WAIT_RRDY  = 5'd10;
//    localparam S_POLL_READ_RX    = 5'd11;
//    localparam S_PRINT_RESULT    = 5'd12;
//    localparam S_DONE            = 5'd13;
//
//    // SPI Register Offsets (assuming 16-bit interface, so addr increments by 1)
//    localparam SPI_RXDATA      = 3'd0;
//    localparam SPI_TXDATA      = 3'd1;
//    localparam SPI_STATUS      = 3'd2;
//    localparam SPI_CONTROL     = 3'd3;
//    localparam SPI_SLAVESELECT = 3'd4;
//
//    // Status Register Bits
//    localparam TRDY_BIT = 5;
//    localparam RRDY_BIT = 6;
//    // --- End of new constants ---
//
//    reg [7:0] cmd[0:5];
//    reg [4:0] state; // Increased state register size
//    reg [6:0] counter; // A smaller counter for bytes
//    
//    initial begin
//        cmd[0] = 8'h40; cmd[1] = 8'h00; cmd[2] = 8'h00; cmd[3] = 8'h00; cmd[4] = 8'h00; cmd[5] = 8'h95;
//    end
//
//    // --- MODIFIED: The state machine is now much more robust ---
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0) begin
//            uart_write <= 0;
//            state <= S_START;
//            Spi_selected <= 0;
//            bus_write_enable <= 0;
//            bus_read_enable <= 0;
//            counter <= 0;
//        end else begin
//            // Default assignments for signals
//            uart_write <= 0;
//            Spi_selected <= 0;
//            bus_write_enable <= 0;
//            bus_read_enable <= 0;
//
//            case (state)
//                S_START: begin
//                    // De-assert slave select to start
//                    Spi_selected <= 1'b1;
//                    bus_write_enable <= 1'b1;
//                    bus_address <= SPI_SLAVESELECT;
//                    bus_write_data <= 16'd0; // Write 0 for SS_n high
//                    counter <= 10; // We will send 10 dummy bytes
//                    state <= S_POWER_ON_DELAY;
//                end
//
//                S_POWER_ON_DELAY: begin // Wait one cycle after setting SS_n
//                    state <= S_POWER_ON_WRITE;
//                end
//                
//                S_POWER_ON_WRITE: begin // Send a dummy 0xFF byte
//                    Spi_selected <= 1'b1;
//                    bus_write_enable <= 1'b1;
//                    bus_address <= SPI_TXDATA;
//                    bus_write_data <= 16'hFF;
//                    state <= S_POWER_ON_WAIT;
//                end
//
//                S_POWER_ON_WAIT: begin // Wait for the byte to be sent
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1;
//                    bus_address <= SPI_STATUS;
//                    if (spi_read_data_wire[RRDY_BIT]) begin // Check if a byte was also received
//                        if (counter > 0) begin
//                            counter <= counter - 1;
//                            state <= S_POWER_ON_WRITE; // Send next dummy byte
//                        end else begin
//                            state <= S_ASSERT_SS; // Done with power-on, now assert SS_n
//                        end
//                    end
//                end
//
//                S_ASSERT_SS: begin
//                    // Assert SS_n LOW by selecting slave 0
//                    Spi_selected <= 1'b1;
//                    bus_write_enable <= 1'b1;
//                    bus_address <= SPI_SLAVESELECT;
//                    bus_write_data <= 16'd1;
//                    counter <= 0; // Reset counter for command bytes
//                    state <= S_CMD_WAIT_TRDY;
//                end
//
//                S_CMD_WAIT_TRDY: begin
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1;
//                    bus_address <= SPI_STATUS;
//                    if (spi_read_data_wire[TRDY_BIT]) begin
//                        state <= S_CMD_WRITE;
//                    end
//                end
//                
//                S_CMD_WRITE: begin
//                    Spi_selected <= 1'b1;
//                    bus_write_enable <= 1'b1;
//                    bus_address <= SPI_TXDATA;
//                    bus_write_data <= {8'd0, cmd[counter]};
//                    
//                    if (counter == 5) begin
//                        counter <= 8; // Max 8 attempts to get a response
//                        state <= S_POLL_RESPONSE;
//                    end else begin
//                        counter <= counter + 1;
//                        state <= S_CMD_WAIT_TRDY;
//                    end
//                end
//
//                S_POLL_RESPONSE: begin // Wait for RRDY from the last command byte
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1;
//                    bus_address <= SPI_STATUS;
//                    if (spi_read_data_wire[RRDY_BIT]) begin
//                        state <= S_POLL_WAIT_TRDY;
//                    end
//                end
//
//                S_POLL_WAIT_TRDY: begin // Wait for TX to be ready to send a dummy byte
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1;
//                    bus_address <= SPI_STATUS;
//                    if (spi_read_data_wire[TRDY_BIT]) begin
//                        state <= S_POLL_WRITE_DUMMY;
//                    end
//                end
//
//                S_POLL_WRITE_DUMMY: begin // Send 0xFF to poll for the response
//                    Spi_selected <= 1'b1;
//                    bus_write_enable <= 1'b1;
//                    bus_address <= SPI_TXDATA;
//                    bus_write_data <= 16'hFF;
//                    state <= S_POLL_WAIT_RRDY;
//                end
//
//                S_POLL_WAIT_RRDY: begin // Wait for the response byte to be received
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1;
//                    bus_address <= SPI_STATUS;
//                    if (spi_read_data_wire[RRDY_BIT]) begin
//                        state <= S_POLL_READ_RX;
//                    end
//                end
//
//                S_POLL_READ_RX: begin
//                    Spi_selected <= 1'b1;
//                    bus_read_enable <= 1'b1;
//                    bus_address <= SPI_RXDATA;
//                    
//                    if (spi_read_data_wire[7:0] != 8'hFF && counter > 0) begin
//                        state <= S_PRINT_RESULT;
//                    end else if (counter > 0) begin 
//                        counter <= counter - 1;
//                        state <= S_POLL_WAIT_TRDY;
//                    end else state <= S_DONE;
//                end
//
//                S_PRINT_RESULT: begin
//                    // 'spi_read_data_wire' from the previous cycle holds the response
//                    // If response was 0x01, data is 1+81='Q'
//                    uart_data <= {24'd0, spi_read_data_wire[7:0] + 8'd80};
//                    uart_write <= 1;
//                    state <= S_DONE;
//                end
//
//                S_DONE: begin
//                    // Halt
//                    state <= S_DONE;
//                end
//            endcase
//        end
//    end
//    // --- End of modified state machine ---
//
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
//    assign LEDR0 = ~state[0]; // Use an LED to see the state machine changing
//
//endmodule



module cpu_on_board (
    input  wire CLOCK_50,
    input  wire KEY0,        // Active-low reset
    output wire LEDR0,
    output wire SPI_SCLK,  
    output wire SPI_MOSI,  
    input  wire SPI_MISO,  
    output wire SPI_SS_n
);

    // -----------------------------
    // UART
    // -----------------------------
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

    // -----------------------------
    // SPI
    // -----------------------------
    wire [15:0] spi_read_data_wire;
    reg  [15:0] bus_write_data;
    reg  [2:0]  bus_address;
    reg         bus_write_enable, bus_read_enable, Spi_selected;

    // -----------------------------
    // CMD0 state machine
    // -----------------------------
    reg [2:0] state;
    reg [2:0] byte_cnt;
    reg [7:0] cmd[0:5];

    initial begin
        // CMD0
        cmd[0]=8'h40; cmd[1]=8'h00; cmd[2]=8'h00; 
        cmd[3]=8'h00; cmd[4]=8'h00; cmd[5]=8'h95;
        state = 0; byte_cnt = 0;
    end

    always @(posedge CLOCK_50 or negedge KEY0) begin
        if(!KEY0) begin
            uart_write <= 0; Spi_selected <= 0;
            bus_write_enable <= 0; bus_read_enable <= 0;
            state <= 0; byte_cnt <= 0;
        end else begin
            uart_write <= 0;
            Spi_selected <= 0;
            bus_write_enable <= 0;
            bus_read_enable <= 0;

            case(state)
                0: begin
                    // Print 'P' for test
                    uart_data <= {24'd0,"P"};
                    uart_write <= 1;
                    state <= 1;
                end
                1: begin
                    // Assert SS low
                    Spi_selected <= 1;
                    bus_write_enable <= 1;
                    bus_address <= 3'd4; // SPI_SLAVESELECT
                    bus_write_data <= 16'd1;
                    byte_cnt <= 0;
                    state <= 2;
                end
                2: begin
                    // Send CMD0 bytes
                    Spi_selected <= 1;
                    bus_write_enable <= 1;
                    bus_address <= 3'd1; // SPI_TXDATA
                    bus_write_data <= {8'd0, cmd[byte_cnt]};
                    if(byte_cnt == 5) state <= 3;
                    else byte_cnt <= byte_cnt + 1;
                end
                3: begin
                    // Read response
                    Spi_selected <= 1;
                    bus_read_enable <= 1;
                    bus_address <= 3'd0; // SPI_RXDATA
                    uart_data <= {24'd0, spi_read_data_wire[7:0]};
                    uart_write <= 1;
                    state <= 4;
                end
                4: state <= 4; // Halt
            endcase
        end
    end

    // -----------------------------
    // SPI IP
    // -----------------------------
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

    assign LEDR0 = (state<4); // LED on while active

endmodule
