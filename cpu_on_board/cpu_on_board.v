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
//    // UART debug: print "K" then print all 512 bytes in hex for sectors 0-15
//    // =======================================================
//    reg printed_k = 0;
//    reg [8:0] byte_index = 0;       // 0..511
//    reg [3:0] print_hex_state = 0;
//    reg [7:0] captured_byte;
//    reg [3:0] fsm_state = 0;
//    reg [1:0] sub_byte = 0;
//    reg [4:0] current_sector = 0;
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
//            current_sector <= 0;
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
//                mem_d   <= current_sector;
//                mem_we  <= 1;
//                fsm_state <= 2;
//            end else if (fsm_state == 2) begin
//                mem_a   <= 16'h1004;
//                mem_d   <= 32'h00000001;
//                mem_we  <= 1;
//                fsm_state <= 3;
//            end else if (fsm_state == 3) begin
//                mem_a <= 16'h2010;
//                if (spo[0] == 1) begin
//                    fsm_state <= 3;
//                end else begin
//                    fsm_state <= 4;
//                end
//            end else if (fsm_state == 4) begin
//                mem_a <= 16'h2010;
//                if (spo[0] == 0) begin
//                    fsm_state <= 4;
//                end else begin
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
//                    print_hex_state <= (byte_index == 511) ? 4'd3 : 4'd0;
//                    if (byte_index != 511) begin
//                        byte_index <= byte_index + 1;
//                        if (sub_byte == 3) begin
//                            sub_byte <= 0;
//                            mem_a <= mem_a + 4;
//                        end else begin
//                            sub_byte <= sub_byte + 1;
//                        end
//                    end
//                end else if (print_hex_state == 3) begin
//                    uart_data  <= {24'd0, 8'h0A};
//                    uart_write <= 1;
//                    print_hex_state <= 0;
//                    if (current_sector == 15) begin
//                        fsm_state <= 6;
//                    end else begin
//                        current_sector <= current_sector + 1;
//                        fsm_state <= 1;
//                    end
//                end
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
    // SD card connection (sdcard.v module)
    // =======================================================
    wire [31:0] spo;           // Single Port Output (read data)
    reg [15:0] sd_addr_in = 0; // Address input for memory-mapped SD
    reg [31:0] sd_data_in = 0; // Write data input for memory-mapped SD
    reg sd_we_in = 0;          // Write Enable for memory-mapped SD
    wire sd_ncd = 1'b0;        // Not Card Detect - assumed low (card present)
    wire sd_wp = 1'b0;         // Write Protect - assumed low (not write protected)
    wire irq;                  // Interrupt output - not used
    wire sd_dat1;              // SD_DAT1 - not used for SPI
    wire sd_dat2;              // SD_DAT2 - not used for SPI

    sdcard sd0 (
        .clk(CLOCK_50),
        .rst(~KEY0),
        .sd_dat0(SD_DAT0),
        .sd_ncd(sd_ncd),
        .sd_wp(sd_wp),
        .sd_dat1(sd_dat1),
        .sd_dat2(sd_dat2),
        .sd_dat3(SD_DAT3), // SD_CS
        .sd_cmd(SD_CMD),   // SD_MOSI
        .sd_sck(SD_CLK),   // SD_SCLK
        .a(sd_addr_in),
        .d(sd_data_in),
        .we(sd_we_in),
        .spo(spo),
        .irq(irq)
    );

    // =======================================================
    // UART debug: print "K" then print all 512 bytes in hex for sectors 0-15
    // =======================================================
    localparam NUM_BYTES_PER_SECTOR = 512;
    localparam LINE_BREAK_BYTES = 16; // Print a newline every 16 bytes for readability
    localparam MAX_SECTOR = 15;     // Read sectors 0 to 15

    // FSM States
    localparam S_INIT_DELAY      = 0;
    localparam S_PRINT_K         = 1;
    localparam S_SECTOR_HEADER   = 2; // Consolidated header printing
    localparam S_SET_ADDR        = 3;
    localparam S_TRIGGER_READ    = 4;
    localparam S_WAIT_BUSY_LOW   = 5;
    localparam S_WAIT_READY_HIGH = 6;
    localparam S_READ_CACHE      = 7;
    localparam S_FINISH_SECTOR   = 8;
    localparam S_DONE            = 9;

    reg [3:0] fsm_state = S_INIT_DELAY;
    reg [31:0] delay_counter = 0;
    reg printed_k = 0;

    reg [4:0] current_sector = 0; // 0 to 15
    reg [10:0] cache_byte_idx = 0; // 0 to 511 (for each sector)

    reg [1:0] hex_print_sub_state = 0; // 0: Idle, 1: High nibble, 2: Low nibble, 3: Space/Newline
    reg [7:0] current_byte_to_print;
    reg [31:0] last_read_data_word = 0; // Store the 32-bit word from spo

    // For printing "Sector XX:" header
    reg [4:0] sector_header_idx = 0; // Index for characters in "Sector XX: "
    reg [7:0] sector_digit_char;

    // Small delay for UART characters
    localparam UART_CHAR_DELAY_COUNT = 100_000; // Adjust as needed (e.g., 2ms @ 50MHz)
    reg [31:0] uart_delay_counter = 0;
    reg uart_waiting = 0; // Flag to indicate we are waiting for UART delay

    // Helper to request UART write and start delay
    // This is not a task/function as they cannot be used in always blocks for synthesis in this way.
    // Instead, we implement a simple request/acknowledge mechanism.
    reg uart_request_char = 0;
    reg [7:0] uart_char_to_send = 0;

    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            uart_delay_counter <= 0;
            uart_waiting <= 0;
            uart_write <= 0;
            uart_request_char <= 0;
            uart_char_to_send <= 0;
        end else begin
            // UART delay management
            if (uart_waiting) begin
                if (uart_delay_counter < UART_CHAR_DELAY_COUNT) begin
                    uart_delay_counter <= uart_delay_counter + 1;
                    uart_write <= 0; // Keep UART write low during delay
                end else begin
                    uart_delay_counter <= 0;
                    uart_waiting <= 0;
                    uart_write <= 0; // Ensure write pulse is one cycle
                end
            end else if (uart_request_char) begin
                uart_data <= {24'd0, uart_char_to_send};
                uart_write <= 1;
                uart_request_char <= 0; // Clear request
                uart_waiting <= 1; // Start delay
            end else begin
                uart_write <= 0; // Default to no UART write
            end
        end
    end


    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            // Reset all main FSM registers
            sd_addr_in <= 0;
            sd_data_in <= 0;
            sd_we_in <= 0;
            fsm_state <= S_INIT_DELAY;
            delay_counter <= 0;
            printed_k <= 0;
            current_sector <= 0;
            cache_byte_idx <= 0;
            hex_print_sub_state <= 0;
            current_byte_to_print <= 0;
            last_read_data_word <= 0;
            sector_header_idx <= 0; // Reset for next run
            sector_digit_char <= 0;
        end else begin
            // sd_we_in and sd_addr_in are controlled by the FSM state
            sd_we_in <= 0; // Default to no write unless set by state
            sd_addr_in <= 0; // Default address for reads if not specified by state

            // Only advance FSM if not waiting for UART or if we are requesting a char
            // This ensures UART delay doesn't block FSM when FSM is not printing
            if (uart_waiting && uart_request_char == 0) begin
                // FSM is paused waiting for UART delay, do nothing here.
            end else begin
                case (fsm_state)
                    S_INIT_DELAY: begin // Initial state: Wait for SD card module to be ready internally
                        if (delay_counter < 100_000_000) begin
                            delay_counter <= delay_counter + 1;
                        end else begin
                            delay_counter <= 0;
                            fsm_state <= S_PRINT_K;
                        end
                    end

                    S_PRINT_K: begin // Print 'K' (SD Init Done)
                        if (!printed_k) begin
                            uart_char_to_send <= "K";
                            uart_request_char <= 1;
                            printed_k <= 1;
                        end
                        // Wait for UART to finish sending 'K' (via uart_waiting)
                        if (!uart_waiting) begin
                            // Add a small delay after printing 'K' before proceeding
                            if (delay_counter < 5_000_000) begin // ~100ms delay
                                delay_counter <= delay_counter + 1;
                            end else begin
                                delay_counter <= 0;
                                fsm_state <= S_SECTOR_HEADER; // Proceed to read first sector
                            end
                        end
                    end

                    S_SECTOR_HEADER: begin // Print "Sector XX:" header
                        // Characters for "Sector XX: "
                        localparam S_STR = "S";
                        localparam E_STR = "e";
                        localparam C_STR = "c";
                        localparam T_STR = "t";
                        localparam O_STR = "o";
                        localparam R_STR = "r";
                        localparam SPACE_STR = " ";
                        localparam COLON_STR = ":";

                        if (!uart_waiting) begin // Only advance if UART is ready for next char
                            case (sector_header_idx)
                                0: begin uart_char_to_send <= S_STR; uart_request_char <= 1; sector_header_idx <= sector_header_idx + 1; end
                                1: begin uart_char_to_send <= E_STR; uart_request_char <= 1; sector_header_idx <= sector_header_idx + 1; end
                                2: begin uart_char_to_send <= C_STR; uart_request_char <= 1; sector_header_idx <= sector_header_idx + 1; end
                                3: begin uart_char_to_send <= T_STR; uart_request_char <= 1; sector_header_idx <= sector_header_idx + 1; end
                                4: begin uart_char_to_send <= O_STR; uart_request_char <= 1; sector_header_idx <= sector_header_idx + 1; end
                                5: begin uart_char_to_send <= R_STR; uart_request_char <= 1; sector_header_idx <= sector_header_idx + 1; end
                                6: begin uart_char_to_send <= SPACE_STR; uart_request_char <= 1; sector_header_idx <= sector_header_idx + 1; end
                                7: begin // High digit of current_sector
                                    sector_digit_char <= (current_sector / 10 < 10) ? (8'h30 + (current_sector / 10)) : (8'h41 + (current_sector / 10) - 10);
                                    uart_char_to_send <= sector_digit_char; uart_request_char <= 1; sector_header_idx <= sector_header_idx + 1;
                                end
                                8: begin // Low digit of current_sector
                                    sector_digit_char <= (current_sector % 10 < 10) ? (8'h30 + (current_sector % 10)) : (8'h41 + (current_sector % 10) - 10);
                                    uart_char_to_send <= sector_digit_char; uart_request_char <= 1; sector_header_idx <= sector_header_idx + 1;
                                end
                                9: begin uart_char_to_send <= COLON_STR; uart_request_char <= 1; sector_header_idx <= sector_header_idx + 1; end
                                10: begin uart_char_to_send <= SPACE_STR; uart_request_char <= 1; sector_header_idx <= 0; // Reset for next sector
                                    cache_byte_idx <= 0; // Reset byte index for the new sector
                                    hex_print_sub_state <= 0; // Reset hex print state
                                    fsm_state <= S_SET_ADDR; // Move to set address for current_sector
                                end
                            endcase
                        end
                    end

                    S_SET_ADDR: begin // Set block address to current_sector
                        sd_addr_in <= 16'h1000;
                        sd_data_in <= {16'h0000, current_sector}; // Set Logical Block Address (LBA)
                        sd_we_in <= 1;
                        fsm_state <= S_TRIGGER_READ;
                    end

                    S_TRIGGER_READ: begin // Trigger a read operation for the set address
                        sd_addr_in <= 16'h1004;
                        sd_data_in <= 32'd1; // Trigger Read (bit 0 high)
                        sd_we_in <= 1;
                        fsm_state <= S_WAIT_BUSY_LOW; // Wait for SD module to indicate busy
                    end

                    S_WAIT_BUSY_LOW: begin // Poll 0x2010 (ready) until it goes LOW (busy)
                        sd_addr_in <= 16'h2010; // Read status register
                        if (spo[0] == 1) begin // Still ready (not busy yet)
                            // fsm_state stays S_WAIT_BUSY_LOW
                        end else begin // spo[0] is 0, now busy
                            fsm_state <= S_WAIT_READY_HIGH; // Proceed to wait for ready
                        end
                    end

                    S_WAIT_READY_HIGH: begin // Poll 0x2010 (ready) until it goes HIGH (done reading)
                        sd_addr_in <= 16'h2010; // Read status register
                        if (spo[0] == 0) begin // Still busy
                            // fsm_state stays S_WAIT_READY_HIGH
                        end else begin // spo[0] is 1, operation complete, data in cache
                            fsm_state <= S_READ_CACHE; // Start reading from cache
                            cache_byte_idx <= 0; // Reset cache index
                            hex_print_sub_state <= 0; // Reset printing state
                        end
                    end

                    S_READ_CACHE: begin // Read and print data from cache (512 bytes)
                        if (cache_byte_idx < NUM_BYTES_PER_SECTOR) begin
                            if (!uart_waiting) begin // Only advance if UART is ready for next char
                                case (hex_print_sub_state)
                                    0: begin // If starting to process a new 32-bit word
                                        if (cache_byte_idx % 4 == 0) begin
                                            sd_addr_in <= {4'h0, cache_byte_idx[8:2]}; // Read 32-bit word from cache (0x0000 - 0x007C)
                                            last_read_data_word <= spo; // Capture spo on this cycle
                                        end
                                        // Extract byte from the 32-bit word based on cache_byte_idx % 4
                                        case (cache_byte_idx[1:0])
                                            2'b00: current_byte_to_print <= last_read_data_word[31:24]; // MSB
                                            2'b01: current_byte_to_print <= last_read_data_word[23:16];
                                            2'b10: current_byte_to_print <= last_read_data_word[15:8];
                                            2'b11: current_byte_to_print <= last_read_data_word[7:0];   // LSB
                                        endcase
                                        hex_print_sub_state <= 1; // Move to print high nibble
                                    end
                                    1: begin // Print high nibble
                                        uart_char_to_send <= (current_byte_to_print[7:4] < 4'd10) ? (8'h30 + current_byte_to_print[7:4]) : (8'h41 + (current_byte_to_print[7:4] - 4'd10));
                                        uart_request_char <= 1;
                                        hex_print_sub_state <= 2;
                                    end
                                    2: begin // Print low nibble
                                        uart_char_to_send <= (current_byte_to_print[3:0] < 4'd10) ? (8'h30 + current_byte_to_print[3:0]) : (8'h41 + (current_byte_to_print[3:0] - 4'd10));
                                        uart_request_char <= 1;
                                        hex_print_sub_state <= 3; // Move to print space/newline
                                    end
                                    3: begin // After printing both hex digits, decide on space/newline
                                        if (cache_byte_idx < NUM_BYTES_PER_SECTOR - 1) begin // If not the last byte of the sector
                                            if ((cache_byte_idx + 1) % LINE_BREAK_BYTES == 0) begin // End of a line, print newline
                                                uart_char_to_send <= "\n";
                                                uart_request_char <= 1;
                                            end else begin // Print space
                                                uart_char_to_send <= " ";
                                                uart_request_char <= 1;
                                            end
                                        end
                                        cache_byte_idx <= cache_byte_idx + 1; // Increment byte counter
                                        hex_print_sub_state <= 0; // Go back to read next byte/word from cache (or next byte from current word)
                                    end
                                endcase
                            end
                        end else begin // All bytes of the current sector have been read and printed
                            fsm_state <= S_FINISH_SECTOR;
                        end
                    end

                    S_FINISH_SECTOR: begin
                        if (!uart_waiting) begin
                            // Print a final newline if the last byte wasn't a line break or if the sector was empty
                            if ((cache_byte_idx % LINE_BREAK_BYTES != 0) || (cache_byte_idx == 0 && NUM_BYTES_PER_SECTOR != 0)) begin
                                uart_char_to_send <= "\n";
                                uart_request_char <= 1;
                            end

                            // Once UART is done with potential final newline, decide next action
                            if (!uart_request_char) begin // Ensure the newline request has been sent
                                if (current_sector < MAX_SECTOR) begin
                                    current_sector <= current_sector + 1;
                                    // Add a small delay between sectors for readability and stability
                                    if (delay_counter < 1_000_000) begin // e.g., 20ms delay
                                        delay_counter <= delay_counter + 1;
                                    end else begin
                                        delay_counter <= 0;
                                        fsm_state <= S_SECTOR_HEADER; // Loop back to print header for next sector
                                    end
                                end else begin
                                    fsm_state <= S_DONE; // All sectors read
                                end
                            end
                        end
                    end

                    S_DONE: begin
                        // System halts here
                    end

                endcase
            end // end else (not uart_waiting)
        end
    end

endmodule
