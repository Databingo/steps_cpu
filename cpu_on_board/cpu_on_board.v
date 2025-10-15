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




////print K<<<<<<<<.<<<��������.���BBBBBBBB.BBBSSSSSSSS.SSSDDDDDDDD.DDD
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
//    wire [7:0] sd_recv_data;
//    wire sd_byte_available;
//
//    reg rd_sig = 0;
//    reg wr_sig = 0;
//    reg [31:0] address = 0;
//
//    sd_controller sd0 (
//        .cs(sd_cs),
//        .mosi(sd_mosi),
//        .miso(SD_DAT0),
//        .sclk(sd_sclk),
//
//        .rd(rd_sig),
//        .wr(wr_sig),
//        .dout(sd_dout),
//        .byte_available(sd_byte_available),
//        .din(8'h00),
//        .ready_for_next_byte(),
//        .reset(~KEY0),
//        .ready(sd_ready),
//        .address(address),
//        .clk(CLOCK_50),
//        .clk_pulse_slow(clk_pulse_slow),
//        .status(sd_status),
//        .recv_data(sd_recv_data)
//    );
//
//    // Connect physical pins
//    assign SD_CLK  = sd_sclk;
//    assign SD_DAT3 = sd_cs;
//    assign SD_CMD  = sd_mosi;
//
//    // =======================================================
//    // Read boot sector, calculate root dir sector, read it, print file name
//    // =======================================================
//    reg [7:0] boot_sector [0:511];
//    reg [7:0] root_dir [0:511];
//    reg [9:0] byte_idx = 0;
//    reg do_read = 0;
//    reg read_root = 0;
//    reg calculating = 0;
//    reg [31:0] calculated_address = 0;
//    reg printed_k = 0;
//    reg [4:0] print_name_state = 0;
//
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0) begin
//            uart_write <= 0;
//            printed_k <= 0;
//            do_read <= 0;
//            rd_sig <= 0;
//            wr_sig <= 0;
//            byte_idx <= 0;
//            read_root <= 0;
//            calculating <= 0;
//            calculated_address <= 0;
//            print_name_state <= 0;
//            address <= 0;
//        end else begin
//            uart_write <= 0;
//            if (sd_ready && !printed_k) begin
//                uart_data <= {24'd0, "K"};  // Print "K" when SD ready
//                uart_write <= 1;
//                printed_k <= 1;
//            end
//            if (printed_k && !do_read && !read_root) begin
//                address <= 0;
//                rd_sig <= 1;
//                do_read <= 1;
//            end else if (read_root && !do_read) begin
//                address <= calculated_address;
//                rd_sig <= 1;
//                do_read <= 1;
//            end else if (do_read && (sd_status != 6)) begin
//                rd_sig <= 0;
//            end
//            if (sd_byte_available) begin
//                if (!read_root) begin
//                    boot_sector[byte_idx] <= sd_dout;
//                end else begin
//                    root_dir[byte_idx] <= sd_dout;
//                end
//                byte_idx <= byte_idx + 1;
//            end
//            if (byte_idx == 512) begin
//                byte_idx <= 0;
//                if (!read_root) begin
//                    calculating <= 1;
//                end else begin
//                    print_name_state <= 1;
//                end
//                do_read <= 0;
//            end
//            if (calculating) begin
//                if (boot_sector[82] == 8'h46) begin  // 'F' for FAT32
//                    calculated_address <= {16'h0000, boot_sector[15], boot_sector[14]} + 
//                                          ({24'h000000, boot_sector[16]} * {boot_sector[39], boot_sector[38], boot_sector[37], boot_sector[36]}) + 
//                                          ({boot_sector[47], boot_sector[46], boot_sector[45], boot_sector[44]} - 32'h00000002) * {24'h000000, boot_sector[13]};
//                end else begin  // FAT16
//                    calculated_address <= {16'h0000, boot_sector[15], boot_sector[14]} + 
//                                          ({24'h000000, boot_sector[16]} * {16'h0000, boot_sector[23], boot_sector[22]});
//                end
//                calculating <= 0;
//                read_root <= 1;
//            end
//            if (print_name_state != 0) begin
//                case (print_name_state)
//                    1: begin uart_data <= {24'd0, root_dir[64]}; uart_write <= 1; print_name_state <= 2; end
//                    2: print_name_state <= 3;
//                    3: begin uart_data <= {24'd0, root_dir[65]}; uart_write <= 1; print_name_state <= 4; end
//                    4: print_name_state <= 5;
//                    5: begin uart_data <= {24'd0, root_dir[66]}; uart_write <= 1; print_name_state <= 6; end
//                    6: print_name_state <= 7;
//                    7: begin uart_data <= {24'd0, root_dir[67]}; uart_write <= 1; print_name_state <= 8; end
//                    8: print_name_state <= 9;
//                    9: begin uart_data <= {24'd0, root_dir[68]}; uart_write <= 1; print_name_state <= 10; end
//                    10: print_name_state <= 11;
//                    11: begin uart_data <= {24'd0, root_dir[69]}; uart_write <= 1; print_name_state <= 12; end
//                    12: print_name_state <= 13;
//                    13: begin uart_data <= {24'd0, root_dir[70]}; uart_write <= 1; print_name_state <= 14; end
//                    14: print_name_state <= 15;
//                    15: begin uart_data <= {24'd0, root_dir[71]}; uart_write <= 1; print_name_state <= 16; end
//                    16: print_name_state <= 17;
//                    17: begin uart_data <= {24'd0, "."}; uart_write <= 1; print_name_state <= 18; end
//                    18: print_name_state <= 19;
//                    19: begin uart_data <= {24'd0, root_dir[72]}; uart_write <= 1; print_name_state <= 20; end
//                    20: print_name_state <= 21;
//                    21: begin uart_data <= {24'd0, root_dir[73]}; uart_write <= 1; print_name_state <= 22; end
//                    22: print_name_state <= 23;
//                    23: begin uart_data <= {24'd0, root_dir[74]}; uart_write <= 1; print_name_state <= 0; end
//                endcase
//            end
//        end
//    end
//
//endmodule


//// still print K<<<<<<<<.<<<��������.���BBBBBBBB.BBBSSSSSSSS.SSSDDDDDDDD.DDD    K<<<<<<
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
//    wire [7:0] sd_recv_data;
//    wire sd_byte_available;
//
//    reg rd_sig = 0;
//    reg wr_sig = 0;
//    reg [31:0] address = 0;
//
//    sd_controller sd0 (
//        .cs(sd_cs),
//        .mosi(sd_mosi),
//        .miso(SD_DAT0),
//        .sclk(sd_sclk),
//
//        .rd(rd_sig),
//        .wr(wr_sig),
//        .dout(sd_dout),
//        .byte_available(sd_byte_available),
//        .din(8'h00),
//        .ready_for_next_byte(),
//        .reset(~KEY0),
//        .ready(sd_ready),
//        .address(address),
//        .clk(CLOCK_50),
//        .clk_pulse_slow(clk_pulse_slow),
//        .status(sd_status),
//        .recv_data(sd_recv_data)
//    );
//
//    // Connect physical pins
//    assign SD_CLK  = sd_sclk;
//    assign SD_DAT3 = sd_cs;
//    assign SD_CMD  = sd_mosi;
//
//    // =======================================================
//    // Read boot sector, calculate root dir sector, read it, print file name
//    // =======================================================
//    reg [7:0] boot_sector [0:511];
//    reg [7:0] root_dir [0:511];
//    reg [9:0] byte_idx = 0;
//    reg do_read = 0;
//    reg read_root = 0;
//    reg calculating = 0;
//    reg [31:0] calculated_address = 0;
//    reg printed_k = 0;
//    reg [4:0] print_name_state = 0;
//
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0) begin
//            uart_write <= 0;
//            printed_k <= 0;
//            do_read <= 0;
//            rd_sig <= 0;
//            wr_sig <= 0;
//            byte_idx <= 0;
//            read_root <= 0;
//            calculating <= 0;
//            calculated_address <= 0;
//            print_name_state <= 0;
//            address <= 0;
//        end else begin
//            uart_write <= 0;
//            if (sd_ready && !printed_k) begin
//                uart_data <= {24'd0, "K"};  // Print "K" when SD ready
//                uart_write <= 1;
//                printed_k <= 1;
//            end
//            if (printed_k && !do_read && !read_root) begin
//                address <= 0;
//                rd_sig <= 1;
//                do_read <= 1;
//            end else if (read_root && !do_read) begin
//                address <= calculated_address;
//                rd_sig <= 1;
//                do_read <= 1;
//            end else if (do_read && (sd_status != 6)) begin
//                rd_sig <= 0;
//            end
//            if (sd_byte_available) begin
//                if (!read_root) begin
//                    boot_sector[byte_idx] <= sd_dout;
//                end else begin
//                    root_dir[byte_idx] <= sd_dout;
//                end
//                byte_idx <= byte_idx + 1;
//            end
//            if (byte_idx == 512) begin
//                byte_idx <= 0;
//                if (!read_root) begin
//                    calculating <= 1;
//                end else begin
//                    print_name_state <= 1;
//                end
//                do_read <= 0;
//            end
//            if (calculating) begin
//                if (boot_sector[17] == 0 && boot_sector[18] == 0) begin // FAT32 if root entries == 0
//                    calculated_address <= ({16'h0000, boot_sector[15], boot_sector[14]} + 
//                                          ({24'h000000, boot_sector[16]} * {boot_sector[39], boot_sector[38], boot_sector[37], boot_sector[36]}) + 
//                                          ({boot_sector[47], boot_sector[46], boot_sector[45], boot_sector[44]} - 32'h00000002) * {24'h000000, boot_sector[13]}) << 9;
//                end else begin // FAT16
//                    calculated_address <= ({16'h0000, boot_sector[15], boot_sector[14]} + 
//                                          ({24'h000000, boot_sector[16]} * {16'h0000, boot_sector[23], boot_sector[22]})) << 9;
//                end
//                calculating <= 0;
//                read_root <= 1;
//            end
//            if (print_name_state != 0) begin
//                case (print_name_state)
//                    1: begin uart_data <= {24'd0, root_dir[0]}; uart_write <= 1; print_name_state <= 2; end
//                    2: print_name_state <= 3;
//                    3: begin uart_data <= {24'd0, root_dir[1]}; uart_write <= 1; print_name_state <= 4; end
//                    4: print_name_state <= 5;
//                    5: begin uart_data <= {24'd0, root_dir[2]}; uart_write <= 1; print_name_state <= 6; end
//                    6: print_name_state <= 7;
//                    7: begin uart_data <= {24'd0, root_dir[3]}; uart_write <= 1; print_name_state <= 8; end
//                    8: print_name_state <= 9;
//                    9: begin uart_data <= {24'd0, root_dir[4]}; uart_write <= 1; print_name_state <= 10; end
//                    10: print_name_state <= 11;
//                    11: begin uart_data <= {24'd0, root_dir[5]}; uart_write <= 1; print_name_state <= 12; end
//                    12: print_name_state <= 13;
//                    13: begin uart_data <= {24'd0, root_dir[6]}; uart_write <= 1; print_name_state <= 14; end
//                    14: print_name_state <= 15;
//                    15: begin uart_data <= {24'd0, root_dir[7]}; uart_write <= 1; print_name_state <= 16; end
//                    16: print_name_state <= 17;
//                    17: begin uart_data <= {24'd0, "."}; uart_write <= 1; print_name_state <= 18; end
//                    18: print_name_state <= 19;
//                    19: begin uart_data <= {24'd0, root_dir[8]}; uart_write <= 1; print_name_state <= 20; end
//                    20: print_name_state <= 21;
//                    21: begin uart_data <= {24'd0, root_dir[9]}; uart_write <= 1; print_name_state <= 22; end
//                    22: print_name_state <= 23;
//                    23: begin uart_data <= {24'd0, root_dir[10]}; uart_write <= 1; print_name_state <= 0; end
//                endcase
//            end
//        end
//    end
//
//endmodule

//// Print KEB
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
//    wire [7:0] sd_recv_data;
//    wire sd_byte_available;
//
//    reg rd_sig = 0;
//    reg wr_sig = 0;
//
//    sd_controller sd0 (
//        .cs(sd_cs),
//        .mosi(sd_mosi),
//        .miso(SD_DAT0),
//        .sclk(sd_sclk),
//
//        .rd(rd_sig),
//        .wr(wr_sig),
//        .dout(sd_dout),
//        .byte_available(sd_byte_available),
//        .din(8'h00),
//        .ready_for_next_byte(),
//        .reset(~KEY0),
//        .ready(sd_ready),
//        .address(32'h00000000),
//        .clk(CLOCK_50),
//        .clk_pulse_slow(clk_pulse_slow),
//        .status(sd_status),
//        .recv_data(sd_recv_data)
//    );
//
//    // Connect physical pins
//    assign SD_CLK  = sd_sclk;
//    assign SD_DAT3 = sd_cs;
//    assign SD_CMD  = sd_mosi;
//
//    // =======================================================
//    // UART debug: print when SD is ready, then read and print first byte in hex
//    // =======================================================
//    reg printed_k = 0;
//    reg do_read = 0;
//    reg printed_byte = 0;
//    reg [2:0] print_hex_state = 0;
//    reg [7:0] captured_byte;
//    
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0) begin
//            uart_write <= 0;
//            printed_k <= 0;
//            do_read <= 0;
//            rd_sig <= 0;
//            wr_sig <= 0;
//            printed_byte <= 0;
//            print_hex_state <= 0;
//            captured_byte <= 0;
//        end else begin
//            uart_write <= 0;
//            if (sd_ready && !printed_k) begin
//                uart_data  <= {24'd0, "K"};  // Print "K" when SD ready
//                uart_write <= 1;
//                printed_k <= 1;
//            end
//            if (sd_ready && printed_k && !do_read) begin
//                rd_sig <= 1;
//                do_read <= 1;
//            end else if (do_read && (sd_status != 6)) begin
//                rd_sig <= 0;
//            end
//            if (do_read && sd_byte_available && !printed_byte) begin
//                captured_byte <= sd_dout;
//                printed_byte <= 1;
//                print_hex_state <= 1;
//            end
//            if (print_hex_state == 1) begin
//                uart_data <= {24'd0, (captured_byte[7:4] < 4'd10) ? (8'h30 + captured_byte[7:4]) : (8'h41 + (captured_byte[7:4] - 4'd10))};
//                uart_write <= 1;
//                print_hex_state <= 2;
//            end else if (print_hex_state == 2) begin
//                print_hex_state <= 3;
//            end else if (print_hex_state == 3) begin
//                uart_data <= {24'd0, (captured_byte[3:0] < 4'd10) ? (8'h30 + captured_byte[3:0]) : (8'h41 + (captured_byte[3:0] - 4'd10))};
//                uart_write <= 1;
//                print_hex_state <= 0;
//            end
//        end
//    end
//
//endmodule


//// print long KBC0234004E4020102020000100F000000FF00099C61EF0E1D5000061416000A1
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
//    wire [7:0] sd_recv_data;
//    wire sd_byte_available;
//
//    reg rd_sig = 0;
//    reg wr_sig = 0;
//
//    sd_controller sd0 (
//        .cs(sd_cs),
//        .mosi(sd_mosi),
//        .miso(SD_DAT0),
//        .sclk(sd_sclk),
//
//        .rd(rd_sig),
//        .wr(wr_sig),
//        .dout(sd_dout),
//        .byte_available(sd_byte_available),
//        .din(8'h00),
//        .ready_for_next_byte(),
//        .reset(~KEY0),
//        .ready(sd_ready),
//        .address(32'h00000000),
//        .clk(CLOCK_50),
//        .clk_pulse_slow(clk_pulse_slow),
//        .status(sd_status),
//        .recv_data(sd_recv_data)
//    );
//
//    // Connect physical pins
//    assign SD_CLK  = sd_sclk;
//    assign SD_DAT3 = sd_cs;
//    assign SD_CMD  = sd_mosi;
//
//    // =======================================================
//    // UART debug: print "K" then print all 512 bytes in hex
//    // =======================================================
//    reg printed_k = 0;
//    reg do_read = 0;
//    reg [8:0] byte_index = 0;       // 0..511
//    reg [2:0] print_hex_state = 0;
//    reg [7:0] captured_byte;
//    reg sd_byte_available_d = 0;
//
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0) begin
//            uart_write <= 0;
//            printed_k <= 0;
//            do_read <= 0;
//            rd_sig <= 0;
//            wr_sig <= 0;
//            byte_index <= 0;
//            print_hex_state <= 0;
//            captured_byte <= 0;
//            sd_byte_available_d <= 0;
//        end else begin
//            uart_write <= 0;
//            sd_byte_available_d <= sd_byte_available; // store previous state
//
//            // Print "K" when SD ready
//            if (sd_ready && !printed_k) begin
//                uart_data  <= {24'd0, "K"};
//                uart_write <= 1;
//                printed_k  <= 1;
//                rd_sig     <= 1;       // start read after K
//                byte_index <= 0;
//            end
//
//            // Stop asserting rd once SD controller leaves IDLE (state != IDLE)
//            if (do_read && (sd_status != 6))
//                rd_sig <= 0;
//
//            // Capture byte on rising edge of byte_available
//            if (sd_byte_available && !sd_byte_available_d) begin
//                captured_byte <= sd_dout;
//                print_hex_state <= 1;
//                do_read <= 1;
//            end
//
//            // Print captured byte as two hex chars
//            if (print_hex_state == 1) begin
//                uart_data  <= {24'd0, (captured_byte[7:4] < 10) ? (8'h30 + captured_byte[7:4]) : (8'h41 + captured_byte[7:4] - 10)};
//                uart_write <= 1;
//                print_hex_state <= 2;
//            end else if (print_hex_state == 2) begin
//                uart_data  <= {24'd0, (captured_byte[3:0] < 10) ? (8'h30 + captured_byte[3:0]) : (8'h41 + captured_byte[3:0] - 10)};
//                uart_write <= 1;
//                print_hex_state <= 0;
//                byte_index <= byte_index + 1;
//
//                // If more bytes left, request next byte
//                if (byte_index < 511)
//                    rd_sig <= 1;
//            end
//        end
//    end
//
//endmodule


//// print 9irjqjtgj904i504jtkgj
//module cpu_on_board (
//    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
//    (* chip_pin = "PIN_R22" *) input  wire KEY0,
//    (* chip_pin = "R20"     *) output wire LEDR0,
//
//    (* chip_pin = "V20" *) output wire SD_CLK,
//    (* chip_pin = "Y20" *) inout  wire SD_CMD,
//    (* chip_pin = "W20" *) inout  wire SD_DAT0,
//    (* chip_pin = "U20" *) output wire SD_DAT3
//);
//
//    // =======================================================
//    // Heartbeat LED
//    // =======================================================
//    reg [23:0] blink_counter;
//    assign LEDR0 = blink_counter[23];
//    always @(posedge CLOCK_50 or negedge KEY0)
//        if (!KEY0)
//            blink_counter <= 0;
//        else
//            blink_counter <= blink_counter + 1'b1;
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
//    task uart_char(input [7:0] c);
//    begin
//        uart_data  <= {24'd0, c};
//        uart_write <= 1;
//    end
//    endtask
//
//    // =======================================================
//    // SD controller
//    // =======================================================
//    wire [7:0] sd_dout;
//    wire       sd_ready;
//    wire [4:0] sd_status;
//    wire       sd_cs, sd_mosi, sd_sclk;
//    wire [7:0] sd_recv_data;
//    wire       sd_byte_available;
//
//    reg rd_sig = 0;
//    reg wr_sig = 0;
//
//    sd_controller sd0 (
//        .cs(sd_cs),
//        .mosi(sd_mosi),
//        .miso(SD_DAT0),
//        .sclk(sd_sclk),
//        .rd(rd_sig),
//        .wr(wr_sig),
//        .dout(sd_dout),
//        .byte_available(sd_byte_available),
//        .din(8'h00),
//        .ready_for_next_byte(),
//        .reset(~KEY0),
//        .ready(sd_ready),
//        .address(32'h00000000),
//        .clk(CLOCK_50),
//        .clk_pulse_slow(1'b1),
//        .status(sd_status),
//        .recv_data(sd_recv_data)
//    );
//
//    assign SD_CLK  = sd_sclk;
//    assign SD_DAT3 = sd_cs;
//    assign SD_CMD  = sd_mosi;
//
//    // =======================================================
//    // FSM for reading and printing until 0x55AA
//    // =======================================================
//    reg printed_k = 0;
//    reg sd_byte_available_d = 0;
//    reg [8:0] byte_index = 0;
//    reg [7:0] captured_byte;
//    reg [15:0] last_two = 0;
//    reg [1:0] state = 0;
//    localparam ST_IDLE = 0, ST_WAIT = 1, ST_PRINT_HI = 2, ST_PRINT_LO = 3;
//
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0) begin
//            uart_write <= 0;
//            printed_k <= 0;
//            rd_sig <= 0;
//            byte_index <= 0;
//            sd_byte_available_d <= 0;
//            captured_byte <= 0;
//            last_two <= 0;
//            state <= ST_IDLE;
//        end else begin
//            uart_write <= 0;
//            sd_byte_available_d <= sd_byte_available;
//
//            // Step 1: print K once SD ready
//            if (sd_ready && !printed_k) begin
//                uart_char("K");
//                printed_k <= 1;
//                rd_sig <= 1;
//                state <= ST_WAIT;
//            end
//
//            // Step 2: only trigger on rising edge of sd_byte_available
//            if (sd_byte_available && !sd_byte_available_d) begin
//                rd_sig <= 0;
//                captured_byte <= sd_dout;
//                state <= ST_PRINT_HI;
//            end
//
//            // Step 3: print high nibble
//            if (state == ST_PRINT_HI) begin
//                uart_char((captured_byte[7:4] < 10) ?
//                          (8'h30 + captured_byte[7:4]) :
//                          (8'h41 + captured_byte[7:4] - 10));
//                state <= ST_PRINT_LO;
//            end
//
//            // Step 4: print low nibble, request next
//            else if (state == ST_PRINT_LO) begin
//                uart_char((captured_byte[3:0] < 10) ?
//                          (8'h30 + captured_byte[3:0]) :
//                          (8'h41 + captured_byte[3:0] - 10));
//
//                last_two <= {last_two[7:0], captured_byte};
//                byte_index <= byte_index + 1;
//
//                if (last_two == 16'h55AA) begin
//                    uart_char("!");
//                    rd_sig <= 0;
//                    state <= ST_IDLE;
//                end else if (byte_index < 512) begin
//                    rd_sig <= 1;   // request next byte
//                    state <= ST_WAIT;
//                end else begin
//                    rd_sig <= 0;
//                    uart_char("#"); // end marker after 512 bytes
//                    state <= ST_IDLE;
//                end
//            end
//        end
//    end
//
//endmodule

//// use sdcard print long same
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
//    // SD card connection
//    // =======================================================
//    wire [31:0] spo;
//    reg [15:0] mem_a = 16'h2010;
//    reg [31:0] mem_d = 0;
//    reg mem_we = 0;
//    wire sd_ncd = 1'b0;
//    wire sd_wp = 1'b0;
//    wire irq;
//    wire sd_dat1;
//    wire sd_dat2;
//
//    sdcard sd0 (
//        .clk(CLOCK_50),
//        .rst(~KEY0),
//        .sd_dat0(SD_DAT0),
//        .sd_ncd(sd_ncd),
//        .sd_wp(sd_wp),
//        .sd_dat1(sd_dat1),
//        .sd_dat2(sd_dat2),
//        .sd_dat3(SD_DAT3),
//        .sd_cmd(SD_CMD),
//        .sd_sck(SD_CLK),
//        .a(mem_a),
//        .d(mem_d),
//        .we(mem_we),
//        .spo(spo),
//        .irq(irq)
//    );
//
//    // =======================================================
//    // UART debug: print "K" then print all 512 bytes in hex
//    // =======================================================
//    reg printed_k = 0;
//    reg [8:0] byte_index = 0;       // 0..511
//    reg [2:0] print_hex_state = 0;
//    reg [7:0] captured_byte;
//    reg [3:0] fsm_state = 0;
//    reg [1:0] sub_byte = 0;
//
//    always @(posedge CLOCK_50 or negedge KEY0) begin
//        if (!KEY0) begin
//            uart_write <= 0;
//            printed_k <= 0;
//            byte_index <= 0;
//            print_hex_state <= 0;
//            captured_byte <= 0;
//            fsm_state <= 0;
//            mem_a <= 16'h2010;
//            mem_d <= 0;
//            mem_we <= 0;
//            sub_byte <= 0;
//        end else begin
//            uart_write <= 0;
//            mem_we <= 0;
//
//            if (fsm_state == 0) begin
//                if (spo[0] && !printed_k) begin
//                    uart_data  <= {24'd0, "K"};
//                    uart_write <= 1;
//                    printed_k  <= 1;
//                    fsm_state  <= 1;
//                end
//            end else if (fsm_state == 1) begin
//                mem_a   <= 16'h1000;
//                mem_d   <= 32'h00000000;
//                mem_we  <= 1;
//                fsm_state <= 2;
//            end else if (fsm_state == 2) begin
//                mem_a   <= 16'h1004;
//                mem_d   <= 32'h00000001;
//                mem_we  <= 1;
//                fsm_state <= 3;
//            end else if (fsm_state == 3) begin
//                mem_a <= 16'h2010;
//                if (!spo[0]) begin
//                    fsm_state <= 4;
//                end
//            end else if (fsm_state == 4) begin
//                mem_a <= 16'h2010;
//                if (spo[0]) begin
//                    fsm_state <= 5;
//                    mem_a <= 0;
//                    sub_byte <= 0;
//                    byte_index <= 0;
//                end
//            end else if (fsm_state == 5) begin
//                if (print_hex_state == 0) begin
//                    case (sub_byte)
//                        2'd0: captured_byte <= spo[31:24];
//                        2'd1: captured_byte <= spo[23:16];
//                        2'd2: captured_byte <= spo[15:8];
//                        2'd3: captured_byte <= spo[7:0];
//                    endcase
//                    print_hex_state <= 1;
//                end else if (print_hex_state == 1) begin
//                    uart_data  <= {24'd0, (captured_byte[7:4] < 10) ? (8'h30 + captured_byte[7:4]) : (8'h41 + captured_byte[7:4] - 10)};
//                    uart_write <= 1;
//                    print_hex_state <= 2;
//                end else if (print_hex_state == 2) begin
//                    uart_data  <= {24'd0, (captured_byte[3:0] < 10) ? (8'h30 + captured_byte[3:0]) : (8'h41 + captured_byte[3:0] - 10)};
//                    uart_write <= 1;
//                    print_hex_state <= 0;
//                    byte_index <= byte_index + 1;
//                    sub_byte <= sub_byte + 1;
//                    if (sub_byte == 3) begin
//                        mem_a <= mem_a + 4;
//                    end
//                    if (byte_index == 511) begin
//                        fsm_state <= 6;
//                    end
//                end
//            end
//        end
//    end
//
//endmodule

// print 0-15 sectors
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
    // SD card connection
    // =======================================================
    wire [31:0] spo;
    reg [15:0] mem_a = 16'h2010;
    reg [31:0] mem_d = 0;
    reg mem_we = 0;
    wire sd_ncd = 1'b0;
    wire sd_wp = 1'b0;
    wire irq;
    wire sd_dat1;
    wire sd_dat2;

    sdcard sd0 (
        .clk(CLOCK_50),
        .rst(~KEY0),
        .sd_dat0(SD_DAT0),
        .sd_ncd(sd_ncd),
        .sd_wp(sd_wp),
        .sd_dat1(sd_dat1),
        .sd_dat2(sd_dat2),
        .sd_dat3(SD_DAT3),
        .sd_cmd(SD_CMD),
        .sd_sck(SD_CLK),
        .a(mem_a),
        .d(mem_d),
        .we(mem_we),
        .spo(spo),
        .irq(irq)
    );

    // =======================================================
    // UART debug: print "K" then print all 512 bytes in hex for sectors 0-15
    // =======================================================
    reg printed_k = 0;
    reg [8:0] byte_index = 0;       // 0..511
    reg [3:0] print_hex_state = 0;
    reg [7:0] captured_byte;
    reg [3:0] fsm_state = 0;
    reg [1:0] sub_byte = 0;
    reg [4:0] current_sector = 0;

    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            uart_write <= 0;
            printed_k <= 0;
            byte_index <= 0;
            print_hex_state <= 0;
            captured_byte <= 0;
            fsm_state <= 0;
            mem_a <= 16'h2010;
            mem_d <= 0;
            mem_we <= 0;
            sub_byte <= 0;
            current_sector <= 0;
        end else begin
            uart_write <= 0;
            mem_we <= 0;

            if (fsm_state == 0) begin
                if (spo[0] && !printed_k) begin
                    uart_data  <= {24'd0, "K"};
                    uart_write <= 1;
                    printed_k  <= 1;
                    fsm_state  <= 1;
                end
            end else if (fsm_state == 1) begin
                mem_a   <= 16'h1000;
                mem_d   <= current_sector;
                mem_we  <= 1;
                fsm_state <= 2;
            end else if (fsm_state == 2) begin
                mem_a   <= 16'h1004;
                mem_d   <= 32'h00000001;
                mem_we  <= 1;
                fsm_state <= 3;
            end else if (fsm_state == 3) begin
                mem_a <= 16'h2010;
                if (spo[0] == 1) begin
                    fsm_state <= 3;
                end else begin
                    fsm_state <= 4;
                end
            end else if (fsm_state == 4) begin
                mem_a <= 16'h2010;
                if (spo[0] == 0) begin
                    fsm_state <= 4;
                end else begin
                    fsm_state <= 5;
                    mem_a <= 0;
                    sub_byte <= 0;
                    byte_index <= 0;
                end
            end else if (fsm_state == 5) begin
                if (print_hex_state == 0) begin
                    case (sub_byte)
                        2'd0: captured_byte <= spo[31:24];
                        2'd1: captured_byte <= spo[23:16];
                        2'd2: captured_byte <= spo[15:8];
                        2'd3: captured_byte <= spo[7:0];
                    endcase
                    print_hex_state <= 1;
                end else if (print_hex_state == 1) begin
                    uart_data  <= {24'd0, (captured_byte[7:4] < 10) ? (8'h30 + captured_byte[7:4]) : (8'h41 + captured_byte[7:4] - 10)};
                    uart_write <= 1;
                    print_hex_state <= 2;
                end else if (print_hex_state == 2) begin
                    uart_data  <= {24'd0, (captured_byte[3:0] < 10) ? (8'h30 + captured_byte[3:0]) : (8'h41 + captured_byte[3:0] - 10)};
                    uart_write <= 1;
                    print_hex_state <= (byte_index == 511) ? 4'd3 : 4'd0;
                    if (byte_index != 511) begin
                        byte_index <= byte_index + 1;
                        if (sub_byte == 3) begin
                            sub_byte <= 0;
                            mem_a <= mem_a + 4;
                        end else begin
                            sub_byte <= sub_byte + 1;
                        end
                    end
                end else if (print_hex_state == 3) begin
                    uart_data  <= {24'd0, 8'h0A};
                    uart_write <= 1;
                    print_hex_state <= 0;
                    if (current_sector == 15) begin
                        fsm_state <= 6;
                    end else begin
                        current_sector <= current_sector + 1;
                        fsm_state <= 1;
                    end
                end
            end
        end
    end

endmodule
