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
    (* chip_pin = "W20" *) inout  wire SD_DAT0, // SD_DAT0 - Renamed from SD_DAT in your IP, assuming DAT0 is what it meant
    (* chip_pin = "U20" *) output wire SD_DAT3  // SD_CS - This should be SD_DAT3, not CS for 4-bit mode. If it's CS, the IP might need modification.
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
    // Renamed from jtag_uart_system to match a common instance name for Qsys generated component
    jtag_uart_0 uart0 (
        .clk_clk(CLOCK_50),
        .reset_reset_n(KEY0),
        .avalon_jtag_slave_address(1'b0),
        .avalon_jtag_slave_writedata(uart_data),
        .avalon_jtag_slave_write_n(~uart_write),
        .avalon_jtag_slave_chipselect(1'b1),
        .avalon_jtag_slave_read_n(1'b1)
    );

    reg [31:0] uart_data;
    reg        uart_write;

    // Helper task for printing a single character
    task print_char;
        input [7:0] char_to_print;
        begin
            uart_data <= {24'b0, char_to_print};
            uart_write <= 1'b1;
            // Delay for one clock cycle to ensure write is registered
            // This is a simplification; a proper handshake might be needed
            #1; // Non-blocking in always block, but useful for tasks
            uart_write <= 1'b0;
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
        .altera_up_sd_card_avalon_interface_0_conduit_end_b_SD_dat(SD_DAT0),
        .altera_up_sd_card_avalon_interface_0_conduit_end_b_SD_dat3(SD_DAT3), // Assuming this is SD_DAT3, not CS
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
            if ((crc ^ shifted_data[i]) & 7'h40) // Check MSB of CRC + data bit
                crc = (crc << 1) ^ 7'h09; // Polynomial for CRC7
            else
                crc = crc << 1;
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
        end else begin
            uart_write <= 0; // Clear write pulse after 1 cycle

            // Default to no action on Avalon bus
            sd_read <= 0;
            sd_write <= 0;
            sd_chipselect <= 1'b1; // Always select the SD card for this test, assuming no other slaves on the bus

            case (state)
                0: begin // Initial Power-up Delay + Print 'S'
                    if (delay_counter < 24'd5_000_000) begin
                        delay_counter <= delay_counter + 1;
                    end else begin
                        print_char("S");
                        delay_counter <= 0;
                        state <= 1; // Go to SD card initialization
                    end
                end

                // --- SD Initialization Sequence (Simplified) ---

                // State 1: Send CMD0 (GO_IDLE_STATE)
                1: begin
                    // CMD0: 0x40 (start bit + cmd index 0) + 0x00000000 (argument) + CRC7 + end bit
                    cmd_arg <= 32'b0;
                    // Calculate CRC7 for CMD0 (0x40 | 0x00) with arg 0
                    // cmd_idx = 0; cmd_bit = 6'b000000; arg = 32'b0;
                    // CRC calculation needs the 6-bit command index and 32-bit argument
                    sd_cmd_crc = calculate_crc7({6'b000000, 32'b0, 3'b000}); // dummy bits for alignment

                    current_cmd_packet[47] = 1'b0; // Start Bit
                    current_cmd_packet[46:40] = 6'b000000; // CMD0 Index (actual value is 0, plus transmission bit)
                    current_cmd_packet[39:8] = 32'b0; // Argument
                    current_cmd_packet[7:1] = sd_cmd_crc; // CRC7
                    current_cmd_packet[0] = 1'b1; // End Bit

                    sd_address <= 2; // SDCMD1 for CMD ID and Arg MSB
                    sd_writedata <= {current_cmd_packet[47:32]}; // CMD index and arg upper part
                    sd_write <= 1;
                    delay_counter <= delay_counter + 1; // Small delay for write to take effect
                    if (delay_counter == 2) begin
                        sd_address <= 1; // SDCMD0 for Arg LSB and CRC
                        sd_writedata <= {current_cmd_packet[31:0]};
                        sd_write <= 1;
                        delay_counter <= 0; // Reset for next state
                        state <= 2; // Move to initiate command
                    end
                end

                // State 2: Trigger CMD0
                2: begin
                    sd_address <= 0; // SDCNT
                    sd_writedata <= 32'd1; // Set bit 0 to initiate command
                    sd_write <= 1;
                    state <= 3; // Wait for command finished
                end

                // State 3: Wait for CMD0 to finish (check SDCNT)
                3: begin
                    sd_address <= 0; // SDCNT
                    sd_read <= 1;
                    if (sd_readdata & SD_CMDFINISHED) begin
                        print_char("0"); // Indicate CMD0 finished
                        delay_counter <= 0;
                        state <= 4; // Move to send CMD55
                    end
                end

                // State 4: Send CMD55 (APP_CMD)
                4: begin
                    // CMD55: 0x40+55 (0x77) + Argument RCA (0 for now) + CRC7 + end bit
                    cmd_arg <= 32'b0; // RCA is 0 for initial CMD55
                    sd_cmd_crc = calculate_crc7({6'b110111, 32'b0, 3'b000}); // CMD55 index 55

                    current_cmd_packet[47] = 1'b0; // Start Bit
                    current_cmd_packet[46:40] = 6'b110111; // CMD55 Index
                    current_cmd_packet[39:8] = 32'b0; // Argument
                    current_cmd_packet[7:1] = sd_cmd_crc; // CRC7
                    current_cmd_packet[0] = 1'b1; // End Bit

                    sd_address <= 2;
                    sd_writedata <= {current_cmd_packet[47:32]};
                    sd_write <= 1;
                    delay_counter <= delay_counter + 1;
                    if (delay_counter == 2) begin
                        sd_address <= 1;
                        sd_writedata <= {current_cmd_packet[31:0]};
                        sd_write <= 1;
                        delay_counter <= 0;
                        state <= 5; // Trigger CMD55
                    end
                end

                // State 5: Trigger CMD55
                5: begin
                    sd_address <= 0; // SDCNT
                    sd_writedata <= 32'd1; // Set bit 0 to initiate command
                    sd_write <= 1;
                    state <= 6; // Wait for CMD55 finished
                end

                // State 6: Wait for CMD55 to finish
                6: begin
                    sd_address <= 0; // SDCNT
                    sd_read <= 1;
                    if (sd_readdata & SD_CMDFINISHED) begin
                        print_char("5"); // Indicate CMD55 finished
                        delay_counter <= 0;
                        state <= 7; // Move to send ACMD41
                    end
                end

                // State 7: Send ACMD41 (SD_SEND_OP_COND)
                7: begin
                    // ACMD41: 0x40+41 (0x69) + Argument (OCR, e.g., 0x0FF00000 for high voltage, HCS for SDHC) + CRC7 + end bit
                    // Assuming SDSC card or leaving voltage range up to card for now
                    cmd_arg <= 32'h0FF00000; // VDD voltage window + HCS
                    sd_cmd_crc = calculate_crc7({6'b101001, cmd_arg, 3'b000}); // ACMD41 index 41

                    current_cmd_packet[47] = 1'b0; // Start Bit
                    current_cmd_packet[46:40] = 6'b101001; // ACMD41 Index
                    current_cmd_packet[39:8] = cmd_arg; // Argument (OCR value)
                    current_cmd_packet[7:1] = sd_cmd_crc; // CRC7
                    current_cmd_packet[0] = 1'b1; // End Bit

                    sd_address <= 2;
                    sd_writedata <= {current_cmd_packet[47:32]};
                    sd_write <= 1;
                    delay_counter <= delay_counter + 1;
                    if (delay_counter == 2) begin
                        sd_address <= 1;
                        sd_writedata <= {current_cmd_packet[31:0]};
                        sd_write <= 1;
                        delay_counter <= 0;
                        state <= 8; // Trigger ACMD41
                    end
                end

                // State 8: Trigger ACMD41
                8: begin
                    sd_address <= 0; // SDCNT
                    sd_writedata <= 32'd1; // Set bit 0 to initiate command
                    sd_write <= 1;
                    state <= 9; // Wait for ACMD41 finished
                end

                // State 9: Wait for ACMD41 to finish and check busy bit
                9: begin
                    sd_address <= 0; // SDCNT
                    sd_read <= 1;
                    if (sd_readdata & SD_CMDFINISHED) begin
                        // Read Response for R3 (OCR register)
                        reg [31:0] r3_response_ocr;
                        sd_address <= 1; // SDCMD0 holds part of R3 response
                        sd_read <= 1;
                        // For a proper R3, you'd need to read SDCMD0-SDCMD4 to reconstruct the full 128-bit response
                        // For ACMD41, we just need the OCR register, which is the 32-bit argument of the response.
                        // Assuming response[0] contains the OCR from your C code, which is SDCMD0 in the IP.
                        // The R3 response format for ACMD41 is usually R3: Command Index (6 bits) + 32-bit OCR + CRC7
                        // Your IP's SDCMD0-SDCMD4 read out the 136-bit response.
                        // The OCR is effectively bits 31-0 of the argument field in the response.
                        // In `SD_SendCmd` in C, `response[0]` gets the OCR. This maps to the `Response` register in Verilog.
                        // For the `SdCardSlave`, the response is in `Response[135:8]`, so the OCR (if it's in the first 32 bits)
                        // would be in `Response[39:8]` (if your C code extracts it correctly from the 136-bit Response).
                        // Let's print the status bits for now, and assume the C code is correct for OCR parsing.

                        // Read response[0] (SDCMD0) after CMD finished.
                        sd_address <= 1; // SDCMD0
                        sd_read <= 1;
                        r3_response_ocr = sd_readdata;

                        print_char("A"); // Indicate ACMD41 finished
                        print_char((r3_response_ocr >> 24) & 8'hFF); // Print MSB of OCR
                        print_char((r3_response_ocr >> 16) & 8'hFF);
                        print_char((r3_response_ocr >> 8) & 8'hFF);
                        print_char(r3_response_ocr & 8'hFF); // Print LSB of OCR

                        // Check the busy bit (bit 31) of the OCR
                        if (r3_response_ocr & 32'h80000000) begin
                            state <= 10; // Card is ready
                            print_char("R"); // Ready
                        end else begin
                            // Card still busy, retry ACMD41 (go back to State 4 or 7)
                            delay_counter <= 0;
                            state <= 4; // Loop back for another CMD55/ACMD41 sequence
                            print_char("B"); // Busy, retrying
                        end
                    end
                end

                // State 10: SD Card Initialized (Placeholder for reading data)
                10: begin
                    print_char("K"); // Indicate successful init
                    state <= 11; // Move to actual data read
                end

                // State 11: Placeholder for actual data read (e.g., CMD17)
                // This would be similar to CMD0/CMD55/ACMD41, but for CMD17
                // and then reading from the FIFO at address 6.
                11: begin
                    // This is where you would implement CMD17 and FIFO reading.
                    // For now, just stay here.
                    state <= 11;
                end


                default: state <= 0; // Should not happen
            endcase
        end
    end

endmodule
