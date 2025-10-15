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
    // SD Card Module Instance
    // This instance replaces the direct sd_controller connection
    // =======================================================
    wire sd_ncd_wire = 0; // Assuming card is always inserted for testing
    wire sd_wp_wire = 0;  // Assuming not write-protected for testing
    wire sd_dat1_wire;
    wire sd_dat2_wire;
    wire sd_cmd_wire;
    wire sd_sck_wire;
    wire sd_dat3_wire;

    reg [15:0] sd_addr_in = 0;
    reg [31:0] sd_data_in = 0;
    reg sd_we_in = 0;
    wire [31:0] sd_data_out; // This is 'spo' from sdcard module
    wire sd_irq; // Not used in this example, but available

    sdcard sd_mem_mapped_inst (
        .clk(CLOCK_50),
        .rst(~KEY0),

        .sd_dat0(SD_DAT0), // MISO
        .sd_ncd(sd_ncd_wire),
        .sd_wp(sd_wp_wire),
        .sd_dat1(sd_dat1_wire),
        .sd_dat2(sd_dat2_wire),
        .sd_dat3(sd_dat3_wire), // CS
        .sd_cmd(sd_cmd_wire),   // MOSI
        .sd_sck(sd_sck_wire),   // SCLK

        .a(sd_addr_in),
        .d(sd_data_in),
        .we(sd_we_in),
        .spo(sd_data_out),
        .irq(sd_irq)
    );

    // Connect physical SD pins
    assign SD_CLK  = sd_sck_wire;
    assign SD_DAT3 = sd_dat3_wire;
    assign SD_CMD  = sd_cmd_wire;
    // Note: SD_DAT1 and SD_DAT2 are outputs from sdcard module,
    // and should be connected to the respective physical pins if used
    // on a board with full SD interface. For SPI, they are often tied high.

    // =======================================================
    // UART debug: State machine to perform memory-mapped SD operations
    // =======================================================
    localparam NUM_BYTES_TO_READ = 512;
    localparam LINE_BREAK_BYTES = 16; // Print a newline every 16 bytes for readability

    reg [3:0] main_state = 0;       // State machine for SD ops
    reg [31:0] delay_counter = 0;   // General purpose delay
    reg [10:0] cache_byte_idx = 0;  // Index for reading bytes from cache (0 to 511)
    reg [7:0] current_byte_to_print; // Holds one byte from the 32-bit word
    reg [1:0] hex_print_sub_state = 0; // 0: Idle, 1: Printing high nibble, 2: Delay, 3: Printing low nibble, 4: Delay/Next byte

    // Helper task to write to the sdcard module's memory-mapped interface
    task write_sdcard_reg;
        input [15:0] address;
        input [31:0] data;
        begin
            sd_addr_in <= address;
            sd_data_in <= data;
            sd_we_in <= 1;
            @(posedge CLOCK_50);
            sd_we_in <= 0; // De-assert write enable after one cycle
            sd_addr_in <= 0; // Reset address
            sd_data_in <= 0; // Reset data
        end
    endtask

    // Helper task to read from the sdcard module's memory-mapped interface
    function [31:0] read_sdcard_reg;
        input [15:0] address;
        begin
            sd_addr_in <= address;
            sd_we_in <= 0; // Ensure write enable is low for read
            @(posedge CLOCK_50); // Give a cycle for spo to update
            read_sdcard_reg = sd_data_out;
            sd_addr_in <= 0; // Reset address
        end
    endfunction


    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            uart_write <= 0;
            sd_addr_in <= 0;
            sd_data_in <= 0;
            sd_we_in <= 0;
            main_state <= 0;
            delay_counter <= 0;
            cache_byte_idx <= 0;
            current_byte_to_print <= 0;
            hex_print_sub_state <= 0;
        end else begin
            uart_write <= 0; // Default to no UART write

            case (main_state)
                0: begin // Initial state: Wait for SD card module to be ready internally
                    // This delay allows the internal sd_controller to initialize
                    if (delay_counter < 100_000_000) begin // Adjust as needed, longer delay for full init
                        delay_counter <= delay_counter + 1;
                    end else begin
                        delay_counter <= 0;
                        main_state <= 1; // Proceed to print 'K' and start SD operations
                    end
                end

                1: begin // Print 'K' (SD Init Done)
                    uart_data <= {24'd0, "K"};
                    uart_write <= 1;
                    delay_counter <= 0; // Reset delay for next step
                    main_state <= 2;
                end

                2: begin // Delay after 'K' and before first SD command
                    if (delay_counter < 50_000_000) begin // Delay ~1 second
                        delay_counter <= delay_counter + 1;
                    end else begin
                        delay_counter <= 0;
                        main_state <= 3; // Move to set address
                    end
                end

                3: begin // Set block address to 0x00 (sector 0)
                    write_sdcard_reg(16'h1000, 32'h00000000); // Set address for R/W
                    main_state <= 4; // Move to trigger read
                end

                4: begin // Trigger a read operation
                    write_sdcard_reg(16'h1004, 32'd1); // Do a read at the set address
                    main_state <= 5; // Move to poll ready status
                end

                5: begin // Poll 0x2010 (ready) until it's 1
                    sd_addr_in <= 16'h2010;
                    sd_we_in <= 0;
                    if (sd_data_out[0] == 1) begin // Check the LSB of spo for ready
                        main_state <= 6; // SD card is ready, start reading cache
                        cache_byte_idx <= 0; // Reset cache index
                        hex_print_sub_state <= 0; // Reset printing state
                    end
                end

                6: begin // Read and print data from cache (0x0000 - 0x01FC)
                    if (cache_byte_idx < NUM_BYTES_TO_READ) begin
                        // Read 32-bit word, then extract 8-bit bytes
                        if (hex_print_sub_state == 0) begin // Read new 32-bit word if starting new word printing
                            if (cache_byte_idx % 4 == 0) begin // Read a new 32-bit word every 4 bytes
                                sd_addr_in <= {4'h0, cache_byte_idx[8:2]}; // Access block[cache_byte_idx/4]
                                sd_we_in <= 0; // Ensure it's a read
                            end
                            // Extract byte from the 32-bit word based on cache_byte_idx % 4
                            case (cache_byte_idx[1:0]) // Which byte within the 32-bit word
                                2'b00: current_byte_to_print <= sd_data_out[31:24];
                                2'b01: current_byte_to_print <= sd_data_out[23:16];
                                2'b10: current_byte_to_print <= sd_data_out[15:8];
                                2'b11: current_byte_to_print <= sd_data_out[7:0];
                            endcase
                            hex_print_sub_state <= 1; // Move to print high nibble
                        end
                        else begin // Print the captured byte
                            case (hex_print_sub_state)
                                1: begin // Print high nibble
                                    uart_data <= {24'd0, (current_byte_to_print[7:4] < 4'd10) ? (8'h30 + current_byte_to_print[7:4]) : (8'h41 + (current_byte_to_print[7:4] - 4'd10))};
                                    uart_write <= 1;
                                    hex_print_sub_state <= 2;
                                end
                                2: begin // Print low nibble
                                    uart_data <= {24'd0, (current_byte_to_print[3:0] < 4'd10) ? (8'h30 + current_byte_to_print[3:0]) : (8'h41 + (current_byte_to_print[3:0] - 4'd10))};
                                    uart_write <= 1;
                                    hex_print_sub_state <= 3;
                                end
                                3: begin // After printing both hex digits
                                    cache_byte_idx <= cache_byte_idx + 1; // Increment byte counter
                                    // Optionally print a space or newline for readability
                                    if (cache_byte_idx < NUM_BYTES_TO_READ && (cache_byte_idx + 1) % LINE_BREAK_BYTES == 0) begin
                                        uart_data <= {24'd0, "\n"}; // Newline for readability
                                        uart_write <= 1;
                                    end else if (cache_byte_idx < NUM_BYTES_TO_READ) begin
                                        uart_data <= {24'd0, " "}; // Space between bytes
                                        uart_write <= 1;
                                    end
                                    hex_print_sub_state <= 0; // Go back to wait for the next byte/word from cache
                                end
                            endcase
                        end
                    end else begin
                        // All bytes read, optionally print a final newline
                        if (cache_byte_idx == NUM_BYTES_TO_READ) begin
                            uart_data <= {24'd0, "\n"};
                            uart_write <= 1;
                            cache_byte_idx <= cache_byte_idx + 1; // To ensure this only happens once
                        end
                        main_state <= 7; // Done
                    end
                end

                7: begin // Done state
                    // The system can halt here, or you could add more commands.
                end

            endcase
        end
    end

endmodule
