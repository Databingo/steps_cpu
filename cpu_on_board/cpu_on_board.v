//module cpu_on_board (
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    (* chip_pin = "V20" *) output wire SD_CLK,  // SD_CLK
//    (* chip_pin = "Y20" *) inout  wire SD_CMD,  // SD_CMD
//    (* chip_pin = "W20" *) inout  wire SD_DAT0, // SD_DAT0
//    (* chip_pin = "U20" *) output wire SD_DAT3  // SD_CS
//);
//
//// =======================================================
//// Heartbeat LED
//// =======================================================
//reg [23:0] blink_counter;
//assign LEDR0 = blink_counter[23];
//
//always @(posedge CLOCK_50 or negedge KEY0) begin
//    if (!KEY0)
//        blink_counter <= 0;
//    else
//        blink_counter <= blink_counter + 1'b1;
//end
//
//// =======================================================
//// JTAG UART
//// =======================================================
//reg [31:0] uart_data;
//reg        uart_write;
//
//jtag_uart_system uart0 (
//    .clk_clk(CLOCK_50),
//    .reset_reset_n(KEY0),
//    .jtag_uart_0_avalon_jtag_slave_address(1'b0),
//    .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
//    .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
//    .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
//    .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
//);
//
//// =======================================================
//// SD SPI lines
//// =======================================================
//reg sd_cmd_out;
//reg sd_cmd_oe;
//reg [15:0] clk_div;
//reg sd_clk_reg;
//
//assign SD_CMD = sd_cmd_oe ? sd_cmd_out : 1'bz;
//assign SD_CLK = sd_clk_reg;
//assign SD_DAT3 = 1'b1;  // CS high (not used)
//assign SD_DAT0 = 1'bz;   // read only for now
//
//// Slow clock for SD (~100 kHz)
//always @(posedge CLOCK_50 or negedge KEY0) begin
//    if (!KEY0) begin
//        clk_div <= 0;
//        sd_clk_reg <= 0;
//    end else begin
//        clk_div <= clk_div + 1;
//        if (clk_div == 250) begin   // 50MHz / 250 / 2 = 100 kHz
//            sd_clk_reg <= ~sd_clk_reg;
//            clk_div <= 0;
//        end
//    end
//end
//
//// =======================================================
//// SD CMD0 sequence
//// =======================================================
//reg [7:0]  init_cnt;
//reg [5:0]  bit_cnt;
//reg [47:0] cmd_shift;
//reg        cmd_start;
//reg [7:0]  response;
//
//always @(posedge CLOCK_50 or negedge KEY0) begin
//    if (!KEY0) begin
//        init_cnt <= 0;
//        bit_cnt <= 0;
//        cmd_start <= 0;
//        sd_cmd_oe <= 0;
//        sd_cmd_out <= 1;
//        cmd_shift <= 48'h40_00_00_00_00_95; // CMD0 with CRC
//        uart_write <= 0;
//        uart_data <= 0;
//    end else begin
//        uart_write <= 0;
//
//        // 80 clocks with CMD high before CMD0
//        if (init_cnt < 80) begin
//            sd_cmd_oe <= 1;
//            sd_cmd_out <= 1;
//            init_cnt <= init_cnt + 1;
//        end
//        // Send CMD0
//        else if (init_cnt < 80+48) begin
//            sd_cmd_oe <= 1;
//            sd_cmd_out <= cmd_shift[47];
//            cmd_shift <= {cmd_shift[46:0],1'b1};
//            bit_cnt <= bit_cnt + 1;
//            init_cnt <= init_cnt + 1;
//        end
//        // Release CMD line
//        else if (init_cnt == 80+48) begin
//            sd_cmd_oe <= 0;
//            init_cnt <= init_cnt + 1;
//        end
//        // Read response (simplified: just read DAT0 after 8 clocks)
//        else if (init_cnt > 80+48 && init_cnt < 80+48+16) begin
//            // This is just a placeholder; real SPI read requires proper sampling
//            // Here we assume card responds and just print success
//            if (init_cnt == 80+48+15) begin
//                uart_data <= {24'd0, "C"}; // CMD0 OK
//                uart_write <= 1;
//            end
//            init_cnt <= init_cnt + 1;
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
//    (* chip_pin = "U20" *) output wire SD_DAT3  // SD_CS
//);
//
//// =======================================================
//// Heartbeat LED
//// =======================================================
//reg [23:0] blink_counter;
//assign LEDR0 = blink_counter[23];
//reg cmd_start;
//
//always @(posedge CLOCK_50 or negedge KEY0) begin
//    if (!KEY0)
//        blink_counter <= 0;
//    else
//        blink_counter <= blink_counter + 1'b1;
//end
//
//// =======================================================
//// JTAG UART
//// =======================================================
//reg [31:0] uart_data;
//reg        uart_write;
//
//jtag_uart_system uart0 (
//    .clk_clk(CLOCK_50),
//    .reset_reset_n(KEY0),
//    .jtag_uart_0_avalon_jtag_slave_address(1'b0),
//    .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
//    .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
//    .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
//    .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
//);
//
//// =======================================================
//// SD SPI lines
//// =======================================================
//reg sd_cmd_out;
//reg sd_cmd_oe;
//reg [15:0] clk_div;
//reg sd_clk_reg;
//
//assign SD_CMD = sd_cmd_oe ? sd_cmd_out : 1'bz;
//assign SD_CLK = sd_clk_reg;
//assign SD_DAT3 = 1'b1;  // CS high
//assign SD_DAT0 = 1'bz;   // read-only
//
//// Slow SD clock ~100 kHz
//always @(posedge CLOCK_50 or negedge KEY0) begin
//    if (!KEY0) begin
//        clk_div <= 0;
//        sd_clk_reg <= 0;
//    end else begin
//        clk_div <= clk_div + 1;
//        if (clk_div == 250) begin
//            sd_clk_reg <= ~sd_clk_reg;
//            clk_div <= 0;
//        end
//    end
//end
//
//// =======================================================
//// SD command FSM
//// =======================================================
//reg [7:0]  init_cnt;
//reg [5:0]  bit_cnt;
//reg [47:0] cmd_shift;
//reg [4:0]  state;
//
//always @(posedge CLOCK_50 or negedge KEY0) begin
//    if (!KEY0) begin
//        init_cnt <= 0;
//        bit_cnt <= 0;
//        cmd_shift <= 48'h40_00_00_00_00_95; // CMD0 reset
//        cmd_start <= 0;
//        sd_cmd_oe <= 0;
//        sd_cmd_out <= 1;
//        uart_write <= 0;
//        uart_data <= 0;
//        state <= 0;
//    end else begin
//        uart_write <= 0;
//
//        case(state)
//            0: begin
//                // 80 clocks CMD high before CMD0
//                if (init_cnt < 80) begin
//                    sd_cmd_oe <= 1;
//                    sd_cmd_out <= 1;
//                    init_cnt <= init_cnt + 1;
//                end else begin
//                    state <= 1;
//                    init_cnt <= 0;
//                    bit_cnt <= 0;
//                    cmd_shift <= 48'h40_00_00_00_00_95; // CMD0
//                end
//            end
//
//            // Send CMD0
//            1: begin
//                sd_cmd_oe <= 1;
//                sd_cmd_out <= cmd_shift[47];
//                cmd_shift <= {cmd_shift[46:0],1'b1};
//                bit_cnt <= bit_cnt + 1;
//                if (bit_cnt == 47) begin
//                    sd_cmd_oe <= 0;  // release CMD line
//                    state <= 2;
//                    init_cnt <= 0;
//                end
//            end
//
//            // Wait some clocks, print "0"
//            2: begin
//                if (init_cnt == 15) begin
//                    uart_data <= {24'd0, "0"}; uart_write <= 1;
//                    state <= 3;
//                end else
//                    init_cnt <= init_cnt + 1;
//            end
//
//            // CMD55 (APP_CMD)
//            3: begin
//                cmd_shift <= 48'h77_00_00_00_00_65; // CMD55
//                bit_cnt <= 0;
//                state <= 4;
//            end
//
//            4: begin
//                sd_cmd_oe <= 1;
//                sd_cmd_out <= cmd_shift[47];
//                cmd_shift <= {cmd_shift[46:0],1'b1};
//                bit_cnt <= bit_cnt + 1;
//                if (bit_cnt == 47) begin
//                    sd_cmd_oe <= 0;
//                    state <= 5;
//                end
//            end
//
//            5: begin
//                uart_data <= {24'd0, "5"}; uart_write <= 1;
//                state <= 6;
//            end
//
//            // ACMD41
//            6: begin
//                cmd_shift <= 48'h69_40_00_00_00_00; // ACMD41 simplified
//                bit_cnt <= 0;
//                state <= 7;
//            end
//
//            7: begin
//                sd_cmd_oe <= 1;
//                sd_cmd_out <= cmd_shift[47];
//                cmd_shift <= {cmd_shift[46:0],1'b1};
//                bit_cnt <= bit_cnt + 1;
//                if (bit_cnt == 47) begin
//                    sd_cmd_oe <= 0;
//                    state <= 8;
//                end
//            end
//
//            8: begin
//                uart_data <= {24'd0, "A"}; uart_write <= 1;
//                state <= 9;
//            end
//
//            9: begin
//                uart_data <= {24'd0, "D"}; uart_write <= 1;
//                state <= 10;
//            end
//
//            10: state <= 10; // stop
//        endcase
//    end
//end
//
//endmodule


`timescale 1ns / 1ps

module cpu_on_board (
    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
    (* chip_pin = "R20"     *) output wire LEDR0,

    (* chip_pin = "V20" *) output wire SD_CLK,  // SD_CLK
    (* chip_pin = "Y20" *) inout  wire SD_CMD,  // SD_CMD
    (* chip_pin = "W20" *) inout  wire SD_DAT0, // SD_DAT0 (this is the actual SD_DAT from your IP)
    (* chip_pin = "U20" *) output wire SD_DAT3  // SD_DAT3 (this is the actual SD_DAT3 from your IP)
);
    // Internal signals for clock and reset
    wire clk_sys = CLOCK_50;
    wire reset_n_sys = KEY; // Assuming KEY provides an active-low reset, so direct connection is active-low.

    // Internal signals for SD card Avalon slave interface (these would be driven by a Nios II or custom master)
    wire sd_chipselect;
    wire [7:0] sd_address;
    wire sd_read;
    wire sd_write;
    wire [3:0] sd_byteenable;
    wire [31:0] sd_writedata;
    wire [31:0] sd_readdata;
    wire sd_waitrequest;

    // Internal signals for JTAG UART Avalon slave interface (these would be driven by a Nios II)
    wire jtag_uart_chipselect;
    wire jtag_uart_address;
    wire jtag_uart_read_n;
    wire [31:0] jtag_uart_readdata;
    wire jtag_uart_write_n;
    wire [31:0] jtag_uart_writedata;
    wire jtag_uart_waitrequest;


    // Instantiate the SD Card IP Core
    sd sd_inst (
        .clk_clk                                                      (clk_sys),
        .reset_reset_n                                                (reset_n_sys),
        .altera_up_sd_card_avalon_interface_0_conduit_end_b_SD_cmd    (SD_CMD),
        .altera_up_sd_card_avalon_interface_0_conduit_end_b_SD_dat    (SD_DATA),
        .altera_up_sd_card_avalon_interface_0_conduit_end_b_SD_dat3   (SD_DATA3),
        .altera_up_sd_card_avalon_interface_0_conduit_end_o_SD_clock  (SD_CLK),
        // Avalon Slave connections (dummy assignments for this example, would be driven by a master)
        .altera_up_sd_card_avalon_interface_0_avalon_sdcard_slave_chipselect (sd_chipselect),
        .altera_up_sd_card_avalon_interface_0_avalon_sdcard_slave_address    (sd_address),
        .altera_up_sd_card_avalon_interface_0_avalon_sdcard_slave_read       (sd_read),
        .altera_up_sd_card_avalon_interface_0_avalon_sdcard_slave_write      (sd_write),
        .altera_up_sd_card_avalon_interface_0_avalon_sdcard_slave_byteenable (sd_byteenable),
        .altera_up_sd_card_avalon_interface_0_avalon_sdcard_slave_writedata  (sd_writedata),
        .altera_up_sd_card_avalon_interface_0_avalon_sdcard_slave_readdata   (sd_readdata),
        .altera_up_sd_card_avalon_interface_0_avalon_sdcard_slave_waitrequest(sd_waitrequest)
    );

    // Instantiate the JTAG UART
    jtag_uart_system jtag_uart_inst (
        .clk_clk                                   (clk_sys),
        .reset_reset_n                             (reset_n_sys),
        // Avalon Slave connections (dummy assignments for this example, would be driven by a Nios II)
        .jtag_uart_0_avalon_jtag_slave_chipselect  (jtag_uart_chipselect),
        .jtag_uart_0_avalon_jtag_slave_address     (jtag_uart_address),
        .jtag_uart_0_avalon_jtag_slave_read_n      (jtag_uart_read_n),
        .jtag_uart_0_avalon_jtag_slave_readdata    (jtag_uart_readdata),
        .jtag_uart_0_avalon_jtag_slave_write_n     (jtag_uart_write_n),
        .jtag_uart_0_avalon_jtag_slave_writedata   (jtag_uart_writedata),
        .jtag_uart_0_avalon_jtag_slave_waitrequest (jtag_uart_waitrequest)
    );

    // --- Dummy/Minimal Avalon Master for basic interaction (for simulation purposes only) ---
    // In a real system, a Nios II processor would drive these signals.
    // For a minimal test, we can try to assert some signals, but it won't actually
    // perform a meaningful SD card operation without proper protocol handling.

    // Assign dummy values for Avalon signals to prevent floating inputs in simulation
    // and to show how they would typically be set (e.g., chipselect always low for single slave)
    assign sd_chipselect = 1'b0; // Active low chip select for SD card (adjust based on actual system)
    assign sd_address = 8'h00;   // Example address
    assign sd_read = 1'b0;       // No read active
    assign sd_write = 1'b0;      // No write active
    assign sd_byteenable = 4'b1111; // All bytes enabled
    assign sd_writedata = 32'h0; // No data written

    assign jtag_uart_chipselect = 1'b0; // Active low chip select for JTAG UART (adjust based on actual system)
    assign jtag_uart_address = 1'b0;    // Example address
    assign jtag_uart_read_n = 1'b1;     // No read active (active low)
    assign jtag_uart_write_n = 1'b1;    // No write active (active low)
    assign jtag_uart_writedata = 32'h0; // No data written

    // A simple counter for very basic interaction (highly simplified and not a functional SD driver)
    reg [2:0] state = 3'd0;
    reg [7:0] data_to_write;
    reg read_cmd_issued = 1'b0;
    reg [31:0] sd_cmd_arg;
    reg [1:0] sd_cmd_id;

    // This section would be replaced by a proper Avalon master (e.g., Nios II)
    always @(posedge clk_sys or negedge reset_n_sys) begin
        if (!reset_n_sys) begin
            state <= 3'd0;
            sd_chipselect <= 1'b0; // Ensure chip select is off during reset
            sd_read <= 1'b0;
            sd_write <= 1'b0;
            sd_address <= 8'h00;
            sd_writedata <= 32'h0;
            read_cmd_issued <= 1'b0;
            sd_cmd_arg <= 32'h0;
            sd_cmd_id <= 2'h0;
        end else begin
            // Simplified state machine to illustrate interaction.
            // This is NOT a complete SD card driver, but shows Avalon signal interaction.
            case(state)
                3'd0: begin // Idle state, wait for a trigger (e.g., from Nios II)
                    // For a standalone test, you might automatically start.
                    // For now, let's just transition.
                    state <= 3'd1;
                end
                3'd1: begin // Initialize or setup a command argument
                    // Example: Set CMD_ARG register (offset 0x22C in Table 2 for Nios II mapping if 0x1000 base)
                    // Assuming a base address of 0 for the IP core's slave.
                    // From document P3 Table 2: CMD_ARG offset is 556 (0x22C)
                    // From document P5 Figure 2: command_argument_register = ((int *)(0x0000122C));
                    // Let's assume the base address given to the IP core is 0x1000
                    // So, offset is 0x22C
                    sd_address <= 8'h22C; // CMD_ARG register offset
                    sd_writedata <= 32'h00001000; // Example address to read from SD card
                    sd_chipselect <= 1'b1; // Activate chip select
                    sd_write <= 1'b1;      // Perform a write
                    state <= 3'd2;
                end
                3'd2: begin // Wait for write to complete and issue command
                    if (!sd_waitrequest) begin // If previous write is complete
                        sd_write <= 1'b0; // Deassert write
                        sd_chipselect <= 1'b0; // Deassert chip select

                        // Issue READ_BLOCK command (offset 0x230 in Table 2, P5 Figure 2)
                        sd_address <= 8'h230; // CMD register offset
                        sd_writedata <= 32'h00000011; // READ_BLOCK command ID (0x11)
                        sd_chipselect <= 1'b1; // Activate chip select
                        sd_write <= 1'b1;      // Perform a write
                        state <= 3'd3;
                    end
                end
                3'd3: begin // Wait for command write to complete
                    if (!sd_waitrequest) begin
                        sd_write <= 1'b0;
                        sd_chipselect <= 1'b0;
                        read_cmd_issued <= 1'b1; // Indicate a command has been sent
                        state <= 3'd4;
                    end
                end
                3'd4: begin // Poll ASR register for completion (offset 0x234 in Table 2, P5 Figure 2)
                    sd_address <= 8'h234; // ASR register offset
                    sd_chipselect <= 1'b1; // Activate chip select
                    sd_read <= 1'b1;       // Perform a read
                    state <= 3'd5;
                end
                3'd5: begin // Read ASR and check bit 2 (command in progress)
                    if (!sd_waitrequest) begin
                        sd_read <= 1'b0;
                        sd_chipselect <= 1'b0;
                        // Check bit 2 of readdata for "most recently sent command is still in progress"
                        if ((sd_readdata & 32'h00000004) == 32'h00000000) begin // Command complete
                            state <= 3'd6; // Command complete, proceed to read data buffer
                        end else begin
                            state <= 3'd4; // Command still in progress, poll again
                        end
                    end
                end
                3'd6: begin // Read from RXTX_BUFFER (offset 0x000 in Table 2)
                    sd_address <= 8'h000; // RXTX_BUFFER offset
                    sd_chipselect <= 1'b1;
                    sd_read <= 1'b1;
                    // In a real system, you'd read 512 bytes here.
                    // For this simple example, we'll just read one value and then stop.
                    state <= 3'd7;
                end
                3'd7: begin // Data read complete
                    if (!sd_waitrequest) begin
                        sd_read <= 1'b0;
                        sd_chipselect <= 1'b0;
                        // Data from SD card is now in sd_readdata
                        // You would typically store this in a memory or process it.
                        // For now, we'll just stay in this state or go back to idle.
                        state <= 3'd7; // Stay here, or go back to 3'd0 to repeat or wait.
                    end
                end
            endcase
        end
    end


endmodule
