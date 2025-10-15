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

// Print K
//module cpu_on_board (
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    (* chip_pin = "V20" *) output wire SD_CLK,  // SD_CLK
//    (* chip_pin = "Y20" *) inout  wire SD_CMD,  // SD_CMD (MOSI)
//    (* chip_pin = "W20" *) inout  wire SD_DAT0, // SD_DAT0 (MISO)
//    (* chip_pin = "U20" *) output wire SD_DAT3  // SD_CS
//);
//
//    // =======================================================
//    // Heartbeat LED
//    // =======================================================
//    reg [23:0] blink_counter;
//    assign LEDR0 = blink_counter[23];
//
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0)
//            blink_counter <= 0;
//        else
//            blink_counter <= blink_counter + 1'b1;
//    end
//
//    // =======================================================
//    // JTAG UART
//    // =======================================================
//    reg [31:0] uart_data;
//    reg        uart_write;
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
//    // =======================================================
//    // Slow pulse clock for SD init (~100 kHz)
//    // =======================================================
//    reg [8:0] clkdiv = 0;
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0)
//            clkdiv <= 0;
//        else
//            clkdiv <= clkdiv + 1;
//    end
//    wire clk_pulse_slow = (clkdiv == 0);
//
//    // =======================================================
//    // SD controller connection
//    // =======================================================
//    wire [7:0] sd_dout;
//    wire sd_ready;
//    wire [4:0] sd_status;
//    wire sd_cs, sd_mosi, sd_sclk;
//
//    sd_controller sd0 (
//        .cs(sd_cs),
//        .mosi(sd_mosi),
//        .miso(SD_DAT0),
//        .sclk(sd_sclk),
//
//        .rd(1'b0),
//        .wr(1'b0),
//        .dout(sd_dout),
//        .byte_available(),
//        .din(8'h00),
//        .ready_for_next_byte(),
//        .reset(~KEY0),
//        .ready(sd_ready),
//        .address(32'h00000000),
//        .clk(CLOCK_50),
//        .clk_pulse_slow(clk_pulse_slow),
//        .status(sd_status),
//        .recv_data()
//    );
//
//    // Connect physical pins
//    assign SD_CLK  = sd_sclk;
//    assign SD_DAT3 = sd_cs;
//    assign SD_CMD  = sd_mosi;
//
//    // =======================================================
//    // UART debug: print when SD is ready
//    // =======================================================
//    reg printed = 0;
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0) begin
//            uart_write <= 0;
//            printed <= 0;
//        end else begin
//            uart_write <= 0;
//            if (sd_ready && !printed) begin
//                uart_data  <= {24'd0, "K"};  // Print "K" when SD ready
//                uart_write <= 1;
//                printed <= 1;
//            end
//        end
//    end
//
//endmodule
//
//
//





module cpu_on_board (
    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
    (* chip_pin = "R20"     *) output wire LEDR0,

    (* chip_pin = "V20" *) output wire SD_CLK,  // SD_CLK
    (* chip_pin = "Y20" *) inout  wire SD_CMD,  // SD_CMD (MOSI)
    (* chip_pin = "W20" *) inout  wire SD_DAT0, // SD_DAT0 (MISO)
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
    // Slow pulse clock for SD init (~100 kHz)
    // =======================================================
    reg [8:0] clkdiv = 0;
    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0)
            clkdiv <= 0;
        else
            clkdiv <= clkdiv + 1;
    end
    wire clk_pulse_slow = (clkdiv == 0);

    // =======================================================
    // SD controller connection
    // =======================================================
    wire [7:0] sd_dout;
    wire sd_byte_available;
    wire sd_ready;
    wire [4:0] sd_status;
    wire sd_cs, sd_mosi, sd_sclk;
    reg sd_rd;

    sd_controller sd0 (
        .cs(sd_cs),
        .mosi(sd_mosi),
        .miso(SD_DAT0),
        .sclk(sd_sclk),

        .rd(sd_rd),
        .wr(1'b0),
        .dout(sd_dout),
        .byte_available(sd_byte_available),
        .din(8'h00),
        .ready_for_next_byte(),
        .reset(~KEY0),
        .ready(sd_ready),
        .address(32'h00000000),  // Read from block 0 (sector 0)
        .clk(CLOCK_50),
        .clk_pulse_slow(clk_pulse_slow),
        .status(sd_status),
        .recv_data()
    );

    // Connect physical pins
    assign SD_CLK  = sd_sclk;
    assign SD_DAT3 = sd_cs;
    assign SD_CMD  = sd_mosi;

    // =======================================================
    // State machine: Init -> Read -> Print
    // =======================================================
    reg [2:0] test_state;
    reg [31:0] wait_counter;
    reg [8:0] byte_count;
    
    parameter STATE_WAIT_READY = 0;
    parameter STATE_START_READ = 1;
    parameter STATE_READING = 2;
    parameter STATE_PRINT_K = 3;
    parameter STATE_PRINT_DATA = 4;
    parameter STATE_DONE = 5;

    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            uart_write <= 0;
            sd_rd <= 0;
            test_state <= STATE_WAIT_READY;
            wait_counter <= 0;
            byte_count <= 0;
        end else begin
            uart_write <= 0;
            
            case (test_state)
                STATE_WAIT_READY: begin
                    if (sd_ready) begin
                        test_state <= STATE_START_READ;
                        wait_counter <= 50_000_000;  // Wait 1 second
                    end
                end
                
                STATE_START_READ: begin
                    if (wait_counter == 0) begin
                        sd_rd <= 1;  // Start read operation
                        test_state <= STATE_READING;
                        byte_count <= 0;
                    end else begin
                        wait_counter <= wait_counter - 1;
                    end
                end
                
                STATE_READING: begin
                    sd_rd <= 0;  // De-assert after one cycle
                    
                    if (sd_byte_available) begin
                        // Got a byte from SD card!
                        if (byte_count == 0) begin
                            // Print 'K' first
                            test_state <= STATE_PRINT_K;
                        end else begin
                            // We already have the first byte, print it
                            test_state <= STATE_PRINT_DATA;
                        end
                    end
                    
                    if (!sd_ready) begin
                        // Still reading...
                        byte_count <= byte_count + 1;
                    end
                end
                
                STATE_PRINT_K: begin
                    uart_data <= {24'd0, 8'h4B};  // Print "K"
                    uart_write <= 1;
                    test_state <= STATE_READING;  // Go back to get more bytes
                end
                
                STATE_PRINT_DATA: begin
                    uart_data <= {24'd0, sd_dout};  // Print the byte from SD card
                    uart_write <= 1;
                    test_state <= STATE_DONE;
                end
                
                STATE_DONE: begin
                    // Stay here, done
                end
                
                default: test_state <= STATE_WAIT_READY;
            endcase
        end
    end

endmodule
