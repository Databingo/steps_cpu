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

    // =======================================================
    // Heartbeat LED
    // =======================================================
    reg [23:0] blink_counter;
    assign LEDR0 = blink_counter[23];

    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0)
            blink_counter <= 0;
        else
            blink_counter <= blink_counter + 1'b1;
    end

    // =======================================================
    // JTAG UART
    // =======================================================
    reg [31:0] uart_data;
    reg        uart_write;

    // REVERTED TO YOUR ORIGINAL JTAG UART INSTANTIATION
    jtag_uart_system uart0 (
        .clk_clk(CLOCK_50),
        .reset_reset_n(KEY0),
        .jtag_uart_0_avalon_jtag_slave_address(1'b0),
        .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
        .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
    );

    // Helper task for printing a single character
    task print_char;
        input [7:0] char_to_print;
        begin
            uart_data <= {24'b0, char_to_print};
            uart_write <= 1'b1;
            // A small delay or a proper handshake with the JTAG UART IP might be needed
            // For a simple FSM, holding uart_write high for one clock cycle is often sufficient
            // or adding a delay counter here if the JTAG UART IP has a read_n/write_n handshake
            // but for this example, we'll assume it's combinatorial or 1-cycle latency.
        end
    endtask


    // =======================================================
    // SD IP Avalon-MM wires
    // =======================================================
    wire        sd_chipselect;
    reg  [2:0]  sd_address; // Made reg to control it from FSM
    reg         sd_read;    // Made reg to control it from FSM
    reg         sd_write;   // Made reg to control it from FSM
    wire [3:0]  sd_byteenable = 4'b1111;
    reg  [31:0] sd_writedata; // Made reg to control it from FSM
    wire [31:0] sd_readdata;
    wire        sd_waitrequest; // Your IP does not use this, it should be connected to '0' or left unconnected if Qsys ties it off.

    // =======================================================
    // Instantiate Altera SD Card IP
    // =======================================================
    sd u_sd (
        .clk_clk(CLOCK_50),
        .reset_reset_n(KEY0),

        // Physical SD pins
        .altera_up_sd_card_avalon_interface_0_conduit_end_b_SD_cmd(SD_CMD),
        // CORRECTED: Your SdCardSlave IP has b_SD_dat, not b_SD_dat0.
        // Also, the top-level port is SD_DAT0, so it maps to the IP's b_SD_dat.
        .altera_up_sd_card_avalon_interface_0_conduit_end_b_SD_dat(SD_DAT0),
        // CORRECTED: Your SdCardSlave IP has b_SD_dat3.
        .altera_up_sd_card_avalon_interface_0_conduit_end_b_SD_dat3(SD_DAT3),
        .altera_up_sd_card_avalon_interface_0_conduit_end_o_SD_clock(SD_CLK),

        // Avalon-MM slave
        .altera_up_sd_card_avalon_interface_0_avalon_sdcard_slave_chipselect(sd_chipselect),
        .altera_up_sd_card_avalon_interface_0_avalon_sdcard_slave_address(sd_address),
        .altera_up_sd_card_avalon_interface_0_avalon_sdcard_slave_read(sd_read),
        .altera_up_sd_card_avalon_interface_0_avalon_sdcard_slave_write(sd_write),
        .altera_up_sd_card_avalon_interface_0_avalon_sdcard_slave_byteenable(sd_byteenable),
        .altera_up_sd_card_avalon_interface_0_avalon_sdcard_slave_writedata(sd_writedata),
        .altera_up_sd_card_avalon_interface_0_avalon_sdcard_slave_readdata(sd_readdata),
        .altera_up_sd_card_avalon_interface_0_avalon_sdcard_slave_waitrequest(1'b0) // Tie off waitrequest, as SdCardSlave relies on polling
    );

    // =======================================================
    // SD IP status bit definitions (from sd.h / sd.c)
    // =======================================================
    localparam SD_CMDFINISHED = (1<<1);
    localparam SD_RESPONSEFINISHED = (1<<2);
    localparam SD_IDLEFINISHED = (1<<3);
    localparam SD_RDFIFOEMPTY = (1<<4);
    localparam SD_RDFIFOFULL = (1<<5);


    // =======================================================
    // SD FSM (Simplified - for demonstration)
    // =======================================================
    reg [3:0] state; // More states needed
    reg [23:0] delay_counter;
    reg [7:0] sd_cmd_crc;
    reg [47:0] current_cmd_packet; // To hold the full 48-bit command
    reg [31:0] cmd_arg;
    reg [31:0] r3_response_ocr; // Added for holding OCR response


    // CRC7 calculation (simplified, for demonstration, not fully optimized)
    function [6:0] calculate_crc7;
        input [40:0] data_in; // 6 bits cmd_idx + 32 bits argument + 3 dummy bits
        reg [6:0] crc;
        reg [40:0] shifted_data;
        integer i;
    begin
        crc = 7'b0;
        shifted_data = data_in;
        for (i = 40; i >= 0; i = i - 1) begin
            crc = crc << 1;
            if (((crc >> 6) ^ shifted_data[i]) & 1'b1) // Check MSB of CRC + data bit
                crc = crc ^ 7'h09; // Polynomial for CRC7: x^7 + x^3 + 1 (0x09)
            crc = crc & 7'h7F; // Keep 7 bits
        end
        calculate_crc7 = crc;
    end
    endfunction


    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            state <= 0;
            delay_counter <= 0;
            sd_read <= 0;
            sd_write <= 0;
            sd_address <= 0;
            sd_writedata <= 0;
            uart_data <= 0;
            uart_write <= 0;
            current_cmd_packet <= 0;
            cmd_arg <= 0;
            r3_response_ocr <= 0;
        end else begin
            // Clear write pulse after 1 cycle to avoid continuous writing
            // This is a common pattern for single-cycle peripheral writes
            if (uart_write) uart_write <= 0;

            // Default to no action on Avalon bus for SD IP
            sd_read <= 0;
            sd_write <= 0;
            sd_chipselect <= 1'b1; // Always select the SD card for this test, assuming no other slaves on the bus

            case (state)
                0: begin // Initial Power-up Delay + Print 'S'
                    if (delay_counter < 24'd5_000_000) begin // Approx 100ms @ 50MHz
                        delay_counter <= delay_counter + 1;
                    end else begin
                        print_char("S");
                        delay_counter <= 0;
                        state <= 1; // Go to SD card initialization
                    end
                end

                // --- SD Initialization Sequence (Simplified) ---
                // (Refer to my previous response for detailed explanation of each state's purpose)

                // State 1: Send CMD0 (GO_IDLE_STATE)
                1: begin
                    cmd_arg <= 32'b0;
                    sd_cmd_crc = calculate_crc7({6'b000000, 32'b0}); // CMD0, arg 0
                    current_cmd_packet = {1'b0, 6'b000000, 32'b0, sd_cmd_crc, 1'b1}; // Start, CMD0, Arg, CRC7, End

                    sd_address <= 1; // SDCMD0/SDCMD1 are combined in the slave.v for 48-bit command
                    sd_writedata <= current_cmd_packet[31:0]; // Lower 32 bits (Arg LSB + CRC + End)
                    sd_write <= 1;
                    state <= 2; // Move to write upper 16 bits
                end

                // State 2: Write upper 16 bits of CMD0 and trigger
                2: begin
                    sd_address <= 2; // SDCMD1 for CMD ID and Arg MSB
                    sd_writedata <= {16'b0, current_cmd_packet[47:32]}; // Upper 16 bits of command packet
                    sd_write <= 1;
                    state <= 3; // Now trigger the command
                end

                // State 3: Trigger CMD0
                3: begin
                    sd_address <= 0; // SDCNT
                    sd_writedata <= 32'd1; // Set bit 0 to initiate command (SD_SendCmd in C code does this)
                    sd_write <= 1;
                    state <= 4; // Wait for command finished
                end

                // State 4: Wait for CMD0 to finish (check SDCNT)
                4: begin
                    sd_address <= 0; // SDCNT
                    sd_read <= 1;
                    if (sd_readdata & SD_CMDFINISHED) begin
                        print_char("0"); // Indicate CMD0 finished
                        delay_counter <= 0;
                        state <= 5; // Move to send CMD55
                    end
                end

                // State 5: Send CMD55 (APP_CMD)
                5: begin
                    cmd_arg <= 32'b0; // RCA is 0 for initial CMD55
                    sd_cmd_crc = calculate_crc7({6'b110111, 32'b0}); // CMD55 index 55, arg 0
                    current_cmd_packet = {1'b0, 6'b110111, 32'b0, sd_cmd_crc, 1'b1};

                    sd_address <= 1;
                    sd_writedata <= current_cmd_packet[31:0];
                    sd_write <= 1;
                    state <= 6;
                end

                // State 6: Write upper 16 bits of CMD55 and trigger
                6: begin
                    sd_address <= 2;
                    sd_writedata <= {16'b0, current_cmd_packet[47:32]};
                    sd_write <= 1;
                    state <= 7;
                end

                // State 7: Trigger CMD55
                7: begin
                    sd_address <= 0; // SDCNT
                    sd_writedata <= 32'd1;
                    sd_write <= 1;
                    state <= 8;
                end

                // State 8: Wait for CMD55 to finish
                8: begin
                    sd_address <= 0; // SDCNT
                    sd_read <= 1;
                    if (sd_readdata & SD_CMDFINISHED) begin
                        print_char("5"); // Indicate CMD55 finished
                        delay_counter <= 0;
                        state <= 9; // Move to send ACMD41
                    end
                end

                // State 9: Send ACMD41 (SD_SEND_OP_COND)
                9: begin
                    cmd_arg <= 32'h0FF00000; // VDD voltage window + HCS
                    sd_cmd_crc = calculate_crc7({6'b101001, cmd_arg}); // ACMD41 index 41
                    current_cmd_packet = {1'b0, 6'b101001, cmd_arg, sd_cmd_crc, 1'b1};

                    sd_address <= 1;
                    sd_writedata <= current_cmd_packet[31:0];
                    sd_write <= 1;
                    state <= 10;
                end

                // State 10: Write upper 16 bits of ACMD41 and trigger
                10: begin
                    sd_address <= 2;
                    sd_writedata <= {16'b0, current_cmd_packet[47:32]};
                    sd_write <= 1;
                    state <= 11;
                end

                // State 11: Trigger ACMD41
                11: begin
                    sd_address <= 0; // SDCNT
                    sd_writedata <= 32'd1;
                    sd_write <= 1;
                    state <= 12;
                end

                // State 12: Wait for ACMD41 to finish and read response
                12: begin
                    sd_address <= 0; // SDCNT
                    sd_read <= 1;
                    if (sd_readdata & SD_CMDFINISHED) begin
                        // Read Response for R3 (OCR register)
                        // In SdCardSlave, Response is stored across SDCMD0-SDCMD4.
                        // For ACMD41 R3, we need the OCR. Your C code extracts it from response[0], which means
                        // it's probably the lower 32-bits of the 136-bit response, which correspond to SDCMD0
                        // in the current SdCardSlave mapping based on how SD_WaitResponse is coded.
                        // Let's read SDCMD0 after the command is finished.
                        sd_address <= 1; // SDCMD0
                        sd_read <= 1; // Read SDCMD0 (which is the actual register named SDCMD0 in SdCardSlave.v)
                        r3_response_ocr <= sd_readdata; // Capture the OCR

                        print_char("A"); // Indicate ACMD41 finished
                        print_char((r3_response_ocr >> 24) & 8'hFF); // Print MSB of OCR
                        print_char((r3_response_ocr >> 16) & 8'hFF);
                        print_char((r3_response_ocr >> 8) & 8'hFF);
                        print_char(r3_response_ocr & 8'hFF); // Print LSB of OCR

                        // Check the busy bit (bit 31) of the OCR
                        if (r3_response_ocr & 32'h80000000) begin
                            state <= 13; // Card is ready
                            print_char("R"); // Ready
                        end else begin
                            // Card still busy, retry ACMD41 (go back to State 5 to send CMD55 again)
                            delay_counter <= 0; // Reset delay counter
                            state <= 5; // Loop back for another CMD55/ACMD41 sequence
                            print_char("B"); // Busy, retrying
                        end
                    end
                end

                // State 13: SD Card Initialized (Placeholder for reading data)
                13: begin
                    print_char("K"); // Indicate successful init
                    state <= 14; // Move to actual data read
                end

                // State 14: Placeholder for actual data read (e.g., CMD17)
                // This would be similar to CMD0/CMD55/ACMD41, but for CMD17
                // and then reading from the FIFO at address 6.
                14: begin
                    // For now, just stay here.
                    state <= 14;
                end

                default: state <= 0; // Should not happen
            endcase
        end
    end

endmodule
