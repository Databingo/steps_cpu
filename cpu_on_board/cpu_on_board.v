// 74 cycles 0xFF to MOSI
// CMD0
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
//    // SPI Register Offsets (consistent with standard Altera/Intel SPI IP)
//    localparam SPI_RXDATA      = 3'd0;
//    localparam SPI_TXDATA      = 3'd1;
//    localparam SPI_STATUS      = 3'd2;
//    localparam SPI_CONTROL     = 3'd3; // <-- THIS IS NEWLY USED
//    localparam SPI_SLAVESELECT = 3'd4;
//
//    // Status Register Bits
//    localparam TRDY_BIT = 5; // Transmit Ready
//    localparam RRDY_BIT = 6; // Receive Ready
//
//    // State definitions (adjusted states due to new S_CONFIG_SPI_CLOCK)
//    localparam S_IDLE              = 4'd0;
//    localparam S_PRINT_SD_PRE      = 4'd1;
//    localparam S_PRINT_SD_MID      = 4'd2;
//    localparam S_PRINT_SD_POST     = 4'd3;
//    localparam S_CONFIG_SPI_CLOCK  = 4'd4; // <--- NEW STATE
//    localparam S_POWER_ON_CLK      = 4'd5; // Shifted state
//    localparam S_CMD0_TX           = 4'd6; // Shifted state
//    localparam S_CMD0_RX_POLL      = 4'd7; // Shifted state
//    localparam S_PRINT_R1          = 4'd8; // Shifted state
//    localparam S_DONE_ERROR        = 4'd9; // Shifted state
//
//    reg [7:0] cmd[0:5];
//    reg [3:0] state;
//    reg [31:0] byte_counter; // Renamed 'counter' to 'byte_counter' for clarity
//    reg [7:0] sd_r1_response; // To store the R1 response
//
//    initial begin // CMD0
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
//            state <= S_IDLE; // Use named state
//            Spi_selected <= 0; // CS high
//            bus_write_enable <= 0;
//            bus_read_enable <= 0;
//            byte_counter <= 0; // Use named counter
//            sd_r1_response <= 8'hFF; // Initialize
//        end else begin
//            uart_write <= 0;  // default off
//
//            case (state)
//                S_IDLE: begin // Original state 0: Wait for a bit
//                    byte_counter <= byte_counter + 1; // Use for delay
//                    if (byte_counter == 32'd4_000_000) begin
//                        byte_counter <= 0; // Reset for next stage
//                        state <= S_PRINT_SD_PRE;
//                    end
//                end
//                S_PRINT_SD_PRE: begin // Original state 1: "S"
//                    uart_data <= {24'd0, "S"}; uart_write <= 1;
//                    state <= S_PRINT_SD_MID;
//                end
//                S_PRINT_SD_MID: begin // Original state 2: "D"
//                    uart_data <= {24'd0, "D"}; uart_write <= 1;
//                    state <= S_PRINT_SD_POST;
//                end
//                S_PRINT_SD_POST: begin // Original state 3: " "
//                    uart_data <= {24'd0, " "}; uart_write <= 1;
//                    byte_counter <= 0; // Reset for S_CONFIG_SPI_CLOCK
//                    state <= S_CONFIG_SPI_CLOCK; // <--- JUMP TO NEW STATE
//                end
//
//                // --- NEW STATE ---
//                S_CONFIG_SPI_CLOCK: begin
//                    // Configure SPI baud rate divisor for initial slow clock (e.g., 400 kHz)
//                    // If CLOCK_50 is 50MHz, for 400kHz, divisor = 50MHz / (2 * 400kHz) - 1 = 61.5 -> ~62
//                    // A divisor of 62 (0x3E) would give 50MHz / (2 * (62+1)) = 50MHz / 126 ~= 396kHz
//                    // Check your SPI IP's documentation for exact divisor formula.
//                    // This is a single write, no TRDY/RRDY check needed for config.
//                    bus_address <= SPI_CONTROL;
//                    bus_write_enable <= 1'b1;
//                    // Assuming SPI_CONTROL[15:0] is baud divisor.
//                    // Assuming divisor = (CLK_FREQ / (2 * TARGET_FREQ)) - 1
//                    // For 50MHz to 400kHz: (50_000_000 / (2 * 400_000)) - 1 = (50_000_000 / 800_000) - 1 = 62.5 - 1 = 61.5
//                    // Let's try 62 (0x3E) or slightly higher to be safe, e.g., 124 (0x7C) for ~200kHz
//                    // Let's use 0x7C for minimal clock. This makes the clock 50MHz / (2*(124+1)) = 50MHz/250 = 200kHz.
//                    bus_write_data <= 16'h007C; // Divisor value 124 (for ~200kHz)
//                    state <= S_POWER_ON_CLK; // Move to power-on clocking
//                end
//                // --- END NEW STATE ---
//
//                S_POWER_ON_CLK: begin
//                    Spi_selected <= 0; // Ensure CS is HIGH
//                    bus_address <= SPI_STATUS;
//                    bus_read_enable <= 1'b1; // Check status for TRDY
//
//                    if (spi_read_data_wire[TRDY_BIT]) begin // Only proceed if TX is ready
//                        bus_address <= SPI_TXDATA; // Write to TX register
//                        bus_write_data <= 16'hFF; // Send 0xFF dummy byte
//                        bus_write_enable <= 1'b1;
//                        byte_counter <= byte_counter + 1;
//                        if (byte_counter == 10) begin // After 10 dummy bytes
//                            byte_counter <= 0; // Reset for CMD0 byte index
//                            state <= S_CMD0_TX; // Go to CMD0 transmission
//                        end
//                    end
//                end
//
//                S_CMD0_TX: begin // Original states 3-8, now consolidated and fixed
//                    Spi_selected <= 1'b1; // Assert CS (SS_n low)
//                    if (byte_counter == 0) begin // Only do this once at the start of CMD0_TX
//                        bus_address <= SPI_SLAVESELECT; // Select slave 0
//                        bus_write_enable <= 1'b1;
//                        bus_write_data <= 16'd0; // Write 0 to assert CS
//                    end
//
//                    bus_address <= SPI_STATUS;
//                    bus_read_enable <= 1'b1; // Check status for TRDY
//                    if (spi_read_data_wire[TRDY_BIT]) begin // Only proceed if TX is ready
//                        bus_address <= SPI_TXDATA; // Correct address for TX
//                        bus_write_enable <= 1'b1;
//                        bus_write_data <= {8'd0, cmd[byte_counter]};
//
//                        byte_counter <= byte_counter + 1;
//                        if (byte_counter == 6) begin // All 6 bytes of CMD0 sent
//                            byte_counter <= 0; // Reset for response polling
//                            state <= S_CMD0_RX_POLL; // Go to response polling
//                        end
//                    end
//                end
//
//                S_CMD0_RX_POLL: begin // Original state 9-10, now with RRDY checks & polling
//                    Spi_selected <= 1'b1; // Keep CS asserted
//                    bus_address <= SPI_STATUS;
//                    bus_read_enable <= 1'b1; // Check status for RRDY
//
//                    if (spi_read_data_wire[RRDY_BIT]) begin // If a byte has been received
//                        bus_address <= SPI_RXDATA;
//                        bus_read_enable <= 1'b1; // Read the received byte
//                        sd_r1_response <= spi_read_data_wire[7:0]; // Store response
//
//                        if (sd_r1_response == 8'h01) begin // Expected R1 response for CMD0
//                            state <= S_PRINT_R1; // Success! Print the result.
//                        end else if (byte_counter < 100 && sd_r1_response == 8'hFF) begin
//                            // Keep polling: SD cards send 0xFF until response is ready
//                            byte_counter <= byte_counter + 1;
//                            // Stay in this state; the next clock cycle will send another dummy byte via TRDY
//                        end else if (sd_r1_response != 8'hFF) begin // Unexpected R1
//                            uart_data <= {24'd0, 8'h45}; // Print 'E' for Error
//                            uart_write <= 1;
//                            state <= S_DONE_ERROR;
//                        end else begin // Timeout after 100 attempts without 0x01
//                            uart_data <= {24'd0, 8'h54}; // Print 'T' for Timeout
//                            uart_write <= 1;
//                            state <= S_DONE_ERROR;
//                        end
//                    end else if (spi_read_data_wire[TRDY_BIT]) begin
//                        // If no data received, but TX is ready, send a dummy byte to clock MISO
//                        bus_address <= SPI_TXDATA;
//                        bus_write_enable <= 1'b1;
//                        bus_write_data <= 16'hFF;
//                    end
//                end
//
//                S_PRINT_R1: begin // Original state 10 printing result
//                    uart_data <= {24'd0, sd_r1_response + 8'h30}; // Convert 0x01 to ASCII '1'
//                    uart_write <= 1;
//                    state <= S_DONE_ERROR;
//                end
//
//                S_DONE_ERROR: begin // Original state 11: Halt
//                    Spi_selected <= 0; // De-assert CS
//                    state <= S_DONE_ERROR;
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
//    // LEDR0 is high if not in DONE or ERROR state
//    assign LEDR0 = (state != S_DONE_ERROR);
//
//endmodule
module cpu_on_board (
    // -- Pins --
    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
    (* chip_pin = "R20"     *) output wire LEDR0,

    (* chip_pin = "V20" *) output wire SPI_SCLK,  // SD_CLK
    (* chip_pin = "Y20" *) output wire SPI_MOSI,  // SD_CMD
    (* chip_pin = "W20" *) input  wire SPI_MISO,  // SD_DAT0
    (* chip_pin = "U20" *) output wire SPI_SS_n   // SD_DAT3 / CS - This is the actual CS line
);

    // ================================================================
    // UART for debug
    // ================================================================
    reg  [31:0] uart_data;
    reg         uart_write_pulse; // Renamed to indicate a pulse
    reg         uart_busy; // To prevent rapid writes

    // Debounce for reset key (optional, but good practice)
    reg [9:0] key_debounce_cnt;
    reg       reset_n_sync, reset_n_prev;

    always @(posedge CLOCK_50) begin
        reset_n_prev <= KEY0;
        if (KEY0 == reset_n_prev) begin // Only update counter if input stable
            if (key_debounce_cnt < 10'd500) begin // Adjust debounce time as needed
                key_debounce_cnt <= key_debounce_cnt + 1;
            end else begin
                reset_n_sync <= KEY0; // Synchronized debounced value
            end
        end else begin
            key_debounce_cnt <= 0; // Reset counter on change
        end
    end


    jtag_uart_system uart0 (
        .clk_clk(CLOCK_50),
        .reset_reset_n(reset_n_sync), // Use debounced reset
        .jtag_uart_0_avalon_jtag_slave_address(1'b0),
        .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
        .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write_pulse), // active low
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        .jtag_uart_0_avalon_jtag_slave_read_n(1'b1), // Not reading
        .jtag_uart_0_avalon_jtag_slave_waitrequest(uart_busy) // Connect waitrequest
    );

    // ================================================================
    // SPI signals
    // ================================================================
    wire [15:0] spi_read_data_wire; // Data read from SPI IP
    reg [15:0]  bus_write_data;     // Data to write to SPI IP
    reg [2:0]   bus_address;        // Address for SPI IP registers
    reg         bus_write_enable_reg; // Enable for writing to SPI IP
    reg         bus_read_enable_reg;  // Enable for reading from SPI IP
    // Note: Spi_selected is no longer directly driving a port on spi_0,
    // it's now used to instruct the FSM to write to the SLAVESELECT register.

    // ================================================================
    // CMD0 sequence state machine
    // ================================================================
    // SPI Register Offsets (consistent with standard Altera/Intel SPI IP)
    localparam SPI_RXDATA      = 3'd0;
    localparam SPI_TXDATA      = 3'd1;
    localparam SPI_STATUS      = 3'd2;
    localparam SPI_CONTROL     = 3'd3;
    localparam SPI_SLAVESELECT = 3'd4; // This writes to the SS_n physical pin

    // Status Register Bits
    localparam TRDY_BIT = 5; // Transmit Ready
    localparam RRDY_BIT = 6; // Receive Ready
    localparam E_BIT    = 7; // Error bit, good to check but not critical for initial state

    // State definitions
    localparam S_RESET_DELAY       = 4'd0; // Added for initial stabilization
    localparam S_PRINT_SD_PRE      = 4'd1;
    localparam S_PRINT_SD_MID      = 4'd2;
    localparam S_PRINT_SD_POST     = 4'd3;
    localparam S_CONFIG_SPI_CLOCK  = 4'd4;
    localparam S_POWER_ON_CLK_INIT = 4'd5; // New state to ensure CS high, then send dummy bytes
    localparam S_POWER_ON_CLK_TX   = 4'd6; // Shifted state for sending dummy bytes
    localparam S_CMD0_INIT_CS      = 4'd7; // Assert CS
    localparam S_CMD0_TX           = 4'd8;
    localparam S_CMD0_RX_POLL      = 4'd9;
    localparam S_PRINT_R1          = 4'd10;
    localparam S_DONE_SUCCESS      = 4'd11; // Separate success from error
    localparam S_DONE_ERROR        = 4'd12;

    reg [7:0] cmd[0:5];
    reg [3:0] state;
    reg [31:0] byte_counter; // Used for various delays and byte indices
    reg [7:0] sd_r1_response; // To store the R1 response
    reg [3:0] cmd_idx; // Index for sending CMD bytes

    initial begin // CMD0
        cmd[0] = 8'h40; // CMD0
        cmd[1] = 8'h00; // Arg byte 3
        cmd[2] = 8'h00; // Arg byte 2
        cmd[3] = 8'h00; // Arg byte 1
        cmd[4] = 8'h00; // Arg byte 0
        cmd[5] = 8'h95; // CRC7 + End bit for CMD0 with argument 0x0
    end

    // Signals for driving SPI peripheral (registered outputs)
    reg         spi_tx_start; // Pulse to send a byte
    reg         spi_rx_start; // Pulse to read a byte

    // --- Output logic for SPI peripheral ---
    // These should be pulsed.
    // Ensure bus_write_enable_reg and bus_read_enable_reg are pulsed for one cycle.
    // They are internally handled by the FSM's `always @(posedge CLOCK_50)` block.

    always @(posedge CLOCK_50 or negedge reset_n_sync) begin // Use debounced reset
        if (!reset_n_sync) begin // Active low reset
            uart_data <= 0;
            uart_write_pulse <= 0;
            state <= S_RESET_DELAY; // Start with a delay after reset
            bus_write_enable_reg <= 0;
            bus_read_enable_reg <= 0;
            bus_address <= 0;
            bus_write_data <= 0;
            byte_counter <= 0;
            cmd_idx <= 0;
            sd_r1_response <= 8'hFF;
        end else begin
            // Default to off, pulsed high when needed
            uart_write_pulse <= 0;
            bus_write_enable_reg <= 0;
            bus_read_enable_reg <= 0;

            case (state)
                S_RESET_DELAY: begin // Give JTAG UART and SPI IP time to stabilize after reset
                    byte_counter <= byte_counter + 1;
                    if (byte_counter == 32'd500_000) begin // ~10ms delay
                        byte_counter <= 0;
                        state <= S_PRINT_SD_PRE;
                    end
                end

                S_PRINT_SD_PRE: begin // "S"
                    if (!uart_busy) begin // Only write if UART is not busy
                        uart_data <= {24'd0, "S"}; uart_write_pulse <= 1;
                        state <= S_PRINT_SD_MID;
                    end
                end
                S_PRINT_SD_MID: begin // "D"
                    if (!uart_busy) begin
                        uart_data <= {24'd0, "D"}; uart_write_pulse <= 1;
                        state <= S_PRINT_SD_POST;
                    end
                end
                S_PRINT_SD_POST: begin // " "
                    if (!uart_busy) begin
                        uart_data <= {24'd0, " "}; uart_write_pulse <= 1;
                        byte_counter <= 0;
                        state <= S_CONFIG_SPI_CLOCK;
                    end
                end

                S_CONFIG_SPI_CLOCK: begin
                    bus_address <= SPI_CONTROL;
                    bus_write_data <= 16'h007C; // Divisor 124 for ~200kHz @ 50MHz
                    bus_write_enable_reg <= 1'b1; // Pulse write enable
                    state <= S_POWER_ON_CLK_INIT;
                end

                S_POWER_ON_CLK_INIT: begin
                    // Ensure CS is high before sending power-on clocks (by de-asserting slave 0)
                    bus_address <= SPI_SLAVESELECT;
                    bus_write_data <= 16'd1; // Write 1 to de-assert SS_n for slave 0
                    bus_write_enable_reg <= 1'b1;
                    byte_counter <= 0; // Reset for dummy byte count
                    state <= S_POWER_ON_CLK_TX;
                end

                S_POWER_ON_CLK_TX: begin
                    // Send at least 74 clock cycles with MOSI high (0xFF) while CS is high
                    // Wait for TRDY to ensure previous write (if any) is done and TX FIFO has space
                    bus_address <= SPI_STATUS;
                    bus_read_enable_reg <= 1'b1; // Read status to check TRDY

                    if (spi_read_data_wire[TRDY_BIT]) begin // If TX is ready
                        bus_address <= SPI_TXDATA;
                        bus_write_data <= 16'hFF; // Send dummy byte
                        bus_write_enable_reg <= 1'b1;
                        byte_counter <= byte_counter + 1;
                        if (byte_counter == 10) begin // Send 10 bytes (80 clocks) as specified
                            byte_counter <= 0; // Reset for CMD0 byte index
                            cmd_idx <= 0;
                            state <= S_CMD0_INIT_CS;
                        end
                    end
                end

                S_CMD0_INIT_CS: begin
                    // Assert CS (pull SS_n low) before sending CMD0
                    bus_address <= SPI_SLAVESELECT;
                    bus_write_data <= 16'd0; // Write 0 to assert SS_n for slave 0
                    bus_write_enable_reg <= 1'b1;
                    state <= S_CMD0_TX;
                end

                S_CMD0_TX: begin
                    // Wait for TRDY to send CMD0 bytes
                    bus_address <= SPI_STATUS;
                    bus_read_enable_reg <= 1'b1;

                    if (spi_read_data_wire[TRDY_BIT]) begin // If TX is ready
                        if (cmd_idx < 6) begin // Send all 6 bytes of CMD0
                            bus_address <= SPI_TXDATA;
                            bus_write_data <= {8'd0, cmd[cmd_idx]}; // Send command byte
                            bus_write_enable_reg <= 1'b1;
                            cmd_idx <= cmd_idx + 1;
                        end else begin // All 6 bytes sent
                            byte_counter <= 0; // Reset for response polling timeout
                            state <= S_CMD0_RX_POLL;
                        end
                    end
                end

                S_CMD0_RX_POLL: begin
                    // Keep polling for R1 response (0x01)
                    // Send dummy bytes on MOSI to clock in MISO data.
                    bus_address <= SPI_STATUS;
                    bus_read_enable_reg <= 1'b1;

                    if (spi_read_data_wire[RRDY_BIT]) begin // If a byte has been received
                        bus_address <= SPI_RXDATA;
                        bus_read_enable_reg <= 1'b1; // Read the received byte
                        sd_r1_response <= spi_read_data_wire[7:0]; // Store response

                        if (sd_r1_response == 8'h01) begin // Expected R1 response for CMD0
                            state <= S_PRINT_R1; // Success! Print the result.
                        end else if (byte_counter < 100 && sd_r1_response == 8'hFF) begin
                            // Still getting 0xFF, keep polling. Increment counter only if 0xFF
                            byte_counter <= byte_counter + 1;
                            // Stay in this state; the next cycle will check TRDY/RRDY again.
                            // If RRDY not set, TRDY might be, sending another dummy byte.
                        end else if (sd_r1_response != 8'hFF) begin // Unexpected R1
                            if (!uart_busy) begin
                                uart_data <= {24'd0, 8'h45}; // Print 'E' for Error
                                uart_write_pulse <= 1;
                            end
                            state <= S_DONE_ERROR;
                        end else begin // Timeout after 100 attempts (getting 0xFF but no 0x01)
                            if (!uart_busy) begin
                                uart_data <= {24'd0, 8'h54}; // Print 'T' for Timeout
                                uart_write_pulse <= 1;
                            end
                            state <= S_DONE_ERROR;
                        end
                    end else if (spi_read_data_wire[TRDY_BIT]) begin
                        // If no data received, but TX is ready, send a dummy byte to clock MISO
                        // This prevents deadlock if RRDY isn't set, but we need to clock.
                        bus_address <= SPI_TXDATA;
                        bus_write_data <= 16'hFF;
                        bus_write_enable_reg <= 1'b1;
                    end
                    // If neither RRDY nor TRDY, just wait.
                end

                S_PRINT_R1: begin
                    if (!uart_busy) begin
                        // Convert 0x01 to ASCII '1'. If response is multi-bit, this will be wrong.
                        // Assuming a single-digit response for now for simple debug.
                        // If sd_r1_response is actually 0x01, it will print '1'.
                        uart_data <= {24'd0, sd_r1_response + 8'h30};
                        uart_write_pulse <= 1;
                        state <= S_DONE_SUCCESS; // Success state
                    end
                end

                S_DONE_SUCCESS: begin
                    // Final state for successful operation, hold here.
                    // Keep CS de-asserted
                    bus_address <= SPI_SLAVESELECT;
                    bus_write_data <= 16'd1; // De-assert SS_n
                    bus_write_enable_reg <= 1'b1;
                    state <= S_DONE_SUCCESS;
                end

                S_DONE_ERROR: begin
                    // Final state for error/timeout, hold here.
                    // Keep CS de-asserted
                    bus_address <= SPI_SLAVESELECT;
                    bus_write_data <= 16'd1; // De-assert SS_n
                    bus_write_enable_reg <= 1'b1;
                    state <= S_DONE_ERROR;
                end
            endcase
        end
    end

    // ================================================================
    // SPI IP instantiation
    // ================================================================
    // It's critical that the "spi" IP is configured correctly in Platform Designer
    // to match the external pins and its internal register map.
// ================================================================
    // SPI IP instantiation
    // ================================================================
    // It's critical that the "spi" IP is configured correctly in Platform Designer
    // to match the external pins and its internal register map.
    spi my_spi_system (
        .clk_clk(CLOCK_50),
        .reset_reset_n(reset_n_sync), // Use debounced reset
        .spi_0_reset_reset_n(reset_n_sync), // SPI IP's specific reset, tie to debounced
        // The chipselect for the Avalon bus slave of the SPI IP, NOT the SD card CS.
        // It should always be high (active) for direct register access from the FSM.
        .spi_0_spi_control_port_chipselect (1'b1), // Corrected port name
        .spi_0_spi_control_port_address    (bus_address), // Corrected port name
        .spi_0_spi_control_port_read_n     (~bus_read_enable_reg), // Corrected port name: active low, directly from FSM
        .spi_0_spi_control_port_readdata   (spi_read_data_wire), // Corrected port name
        .spi_0_spi_control_port_write_n    (~bus_write_enable_reg), // Corrected port name: active low, directly from FSM
        .spi_0_spi_control_port_writedata  (bus_write_data), // Corrected port name
        .spi_0_external_MISO(SPI_MISO),
        .spi_0_external_MOSI(SPI_MOSI),
        .spi_0_external_SCLK(SPI_SCLK),
        .spi_0_external_SS_n(SPI_SS_n) // This is the actual physical SS_n pin, controlled by SPI_SLAVESELECT register
    );
    // LEDR0 is high if not in DONE_ERROR state
    assign LEDR0 = (state != S_DONE_ERROR);

endmodule
