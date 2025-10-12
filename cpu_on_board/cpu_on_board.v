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
// print D 0
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

`timescale 1ns/1ps
module cpu_on_board (
    input  wire CLOCK_50,      // 50 MHz
    input  wire KEY0,          // Active low reset

    output reg  LEDR0,         // Status LED
    output reg  SPI_SCLK,      // SD CLK
    output reg  SPI_MOSI,      // SD CMD
    input  wire SPI_MISO,      // SD DAT
    output reg  SPI_SS_n       // SD DAT3
);

    // -----------------------------
    // JTAG UART
    // -----------------------------
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

    // -----------------------------
    // SPI Clock divider: 50MHz -> ~400kHz
    // -----------------------------
    reg [7:0] clk_div;
    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            clk_div <= 0;
            SPI_SCLK <= 0;
        end else begin
            if (clk_div == 62) begin
                clk_div <= 0;
                SPI_SCLK <= ~SPI_SCLK;
            end else clk_div <= clk_div + 1;
        end
    end

    // -----------------------------
    // SD Initialization & CMD0
    // -----------------------------
    reg [7:0] init_cnt;
    reg       init_done;
    reg [2:0] state;
    reg [2:0] bit_cnt;
    reg [2:0] byte_cnt;
    reg [7:0] miso_shift;

    reg [7:0] cmd [0:5]; // CMD0
    initial begin
        cmd[0] = 8'h40; cmd[1] = 8'h00; cmd[2] = 8'h00;
        cmd[3] = 8'h00; cmd[4] = 8'h00; cmd[5] = 8'h95;
        SPI_SS_n = 1'b1;
        SPI_MOSI = 1'b1;
        LEDR0 = 1'b0;
        state = 0;
        init_cnt = 0;
        init_done = 0;
        bit_cnt = 7;
        byte_cnt = 0;

        // Print "A" for UART test
        uart_data = 32'h41;  // ASCII 'A'
        uart_write = 1'b1;
    end

    always @(posedge SPI_SCLK or negedge KEY0) begin
        if (!KEY0) begin
            state <= 0;
            SPI_SS_n <= 1'b1;
            SPI_MOSI <= 1'b1;
            LEDR0 <= 1'b0;
            init_cnt <= 0;
            init_done <= 0;
            bit_cnt <= 7;
            byte_cnt <= 0;
            uart_write <= 0;
        end else begin
            case (state)
                // Step 0: 80 clocks with CS high
                0: begin
                    SPI_SS_n <= 1'b1;
                    SPI_MOSI <= 1'b1;
                    if (init_cnt < 80) init_cnt <= init_cnt + 1;
                    else begin
                        init_done <= 1;
                        state <= 1;
                    end
                end

                // Step 1: Send CMD0
                1: begin
                    SPI_SS_n <= 1'b0;
                    SPI_MOSI <= cmd[byte_cnt][bit_cnt];
                    if (bit_cnt == 0) begin
                        bit_cnt <= 7;
                        if (byte_cnt == 5) begin
                            byte_cnt <= 0;
                            state <= 2;
                        end else byte_cnt <= byte_cnt + 1;
                    end else bit_cnt <= bit_cnt - 1;
                end

                // Step 2: Wait SD response
                2: begin
                    SPI_MOSI <= 1'b1;
                    miso_shift <= {miso_shift[6:0], SPI_MISO};
                    if (miso_shift != 8'h00) begin
                        LEDR0 <= 1'b1;          // LED ON: SD responded
                        uart_data <= {24'd0, miso_shift};  // Print SD response
                        uart_write <= 1'b1;
                        state <= 3;
                    end
                end

                // Step 3: Idle
                3: begin
                    SPI_SS_n <= 1'b1;
                    SPI_MOSI <= 1'b1;
                    uart_write <= 0;
                end
            endcase
        end
    end

endmodule
