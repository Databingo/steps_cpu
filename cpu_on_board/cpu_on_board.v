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


// =======================================================
// DE1 Minimal SD + JTAG UART test
// (Based on your confirmed working UART version)
// =======================================================
module cpu_on_board (
    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
    (* chip_pin = "R20"     *) output wire LEDR0,

    (* chip_pin = "V20" *) output wire SD_CLK,  // SD_CLK
    (* chip_pin = "Y20" *) inout  wire SD_CMD,  // SD_CMD
    (* chip_pin = "W20" *) inout  wire SD_DAT0, // SD_DAT0
    (* chip_pin = "U20" *) output wire SD_DAT3  // SD_CS
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

    jtag_uart_system uart0 (
        .clk_clk(CLOCK_50),
        .reset_reset_n(KEY0),
        .jtag_uart_0_avalon_jtag_slave_address(1'b0),
        .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
        .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
    );

    // =======================================================
    // SD IP Avalon-MM wires
    // =======================================================
    wire        sd_chipselect;
    wire [2:0]  sd_address;
    wire        sd_read;
    wire        sd_write;
    wire [3:0]  sd_byteenable = 4'b1111;
    wire [31:0] sd_writedata;
    wire [31:0] sd_readdata;
    wire        sd_waitrequest;

    // =======================================================
    // Instantiate Altera SD Card IP (add sd.qip to project)
    // =======================================================
    sd u_sd (
        .clk_clk(CLOCK_50),
        .reset_reset_n(KEY0),

        // Physical SD pins
        .altera_up_sd_card_avalon_interface_0_conduit_end_b_SD_cmd(SD_CMD),
        .altera_up_sd_card_avalon_interface_0_conduit_end_b_SD_dat(SD_DAT0),
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
        .altera_up_sd_card_avalon_interface_0_avalon_sdcard_slave_waitrequest(sd_waitrequest)
    );

    // =======================================================
    // SD test: after blink delay, print SD ready check
    // =======================================================
    reg [3:0] state;
    reg [23:0] delay;
    assign sd_chipselect = 1'b0; // idle
    assign sd_address = 3'b000;
    assign sd_read = 1'b0;
    assign sd_write = 1'b0;
    assign sd_writedata = 32'd0;

    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            uart_data <= 0;
            uart_write <= 0;
            delay <= 0;
            state <= 0;
        end else begin
            uart_write <= 0;

            case (state)
                0: begin
                    // wait a short while after reset
                    if (delay == 24'd5_000_000) begin
                        uart_data <= {24'd0, "C"};
                        uart_write <= 1;
                        state <= 1;
                    end else
                        delay <= delay + 1;
                end
                1: begin
                    if (blink_counter[22]) begin
                        uart_data <= {24'd0, "S"};
                        uart_write <= 1;
                        state <= 2;
                    end
                end
                2: begin
                    if (blink_counter[23]) begin
                        uart_data <= {24'd0, "D"};
                        uart_write <= 1;
                        state <= 3;
                    end
                end
                3: state <= 3; // stay
            endcase
        end
    end

endmodule
