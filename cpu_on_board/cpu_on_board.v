//// 74 cycles 0xFF to MOSI
//// CMD0
////
////
////
//// print D 0 by chatgpt5
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
//                    if (counter == 32'd9_000_000) begin
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
//        //.spi_0_reset_reset_n(KEY0),
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



module cpu_on_board (
    input  wire CLOCK_50,
    input  wire KEY0,        // Active-low reset
    output wire LEDR0,
    output wire SPI_SCLK,
    output wire SPI_MOSI,
    input  wire SPI_MISO,
    output wire SPI_SS_n
);

    // ---------------- UART ----------------
    reg  [31:0] uart_data;
    reg         uart_write;

    jtag_uart_system uart0 (
        .clk_clk(CLOCK_50),
        .reset_reset_n(KEY0),
        .jtag_uart_0_avalon_jtag_slave_address(1'b0),
        .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
        .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
    );

    // ---------------- SPI -----------------
    wire [15:0] spi_read_data_wire;
    reg  [15:0] bus_write_data;
    reg  [2:0]  bus_address;
    reg         bus_write_enable, bus_read_enable, Spi_selected;

    // ---------------- State machine --------
    reg [2:0] state;
    reg [6:0] counter;
    reg [7:0] cmd[0:5];

    initial begin
        cmd[0]=8'h40; cmd[1]=8'h00; cmd[2]=8'h00;
        cmd[3]=8'h00; cmd[4]=8'h00; cmd[5]=8'h95;
        state=0; counter=0;
    end

    always @(posedge CLOCK_50 or negedge KEY0) begin
        if(!KEY0) begin
            uart_write<=0; Spi_selected<=0;
            bus_write_enable<=0; bus_read_enable<=0;
            state<=0; counter<=0;
        end else begin
            uart_write<=0; Spi_selected<=0;
            bus_write_enable<=0; bus_read_enable<=0;

            case(state)
                0: begin
                    uart_data<={24'd0,"P"}; uart_write<=1;
                    counter<=10;               // 80 dummy clocks
                    state<=1;
                end
                1: begin                     // Send 10 dummy 0xFF bytes
                    Spi_selected<=1;
                    bus_write_enable<=1;
                    bus_address<=3'd1;        // TXDATA
                    bus_write_data<=16'hFF;
                    if(counter>0) counter<=counter-1;
                    else state<=2;
                end
                2: begin                     // Assert SS low
                    Spi_selected<=1;
                    bus_write_enable<=1;
                    bus_address<=3'd4;        // SLAVESELECT
                    bus_write_data<=16'd1;
                    counter<=0;
                    state<=3;
                end
                3: begin                     // Send CMD0 bytes
                    Spi_selected<=1;
                    bus_write_enable<=1;
                    bus_address<=3'd1;
                    bus_write_data<={8'd0,cmd[counter]};
                    if(counter==5) state<=4;
                    else counter<=counter+1;
                end
                4: begin                     // Read response
                    Spi_selected<=1;
                    bus_read_enable<=1;
                    bus_address<=3'd0;        // RXDATA
                    uart_data<={24'd0,spi_read_data_wire[7:0]};
                    uart_write<=1;
                    state<=5;
                end
                5: state<=5;                 // Halt
            endcase
        end
    end

    // ---------------- SPI IP ----------------
    spi my_spi_system (
        .clk_clk(CLOCK_50),
        .reset_reset_n(KEY0),
       // .spi_0_reset_reset_n(KEY0),
        .spi_0_spi_control_port_chipselect (Spi_selected),
        .spi_0_spi_control_port_address    (bus_address),
        .spi_0_spi_control_port_read_n     (~(bus_read_enable && Spi_selected)),
        .spi_0_spi_control_port_readdata   (spi_read_data_wire),
        .spi_0_spi_control_port_write_n    (~(bus_write_enable && Spi_selected)),
        .spi_0_spi_control_port_writedata  (bus_write_data),
        .spi_0_external_MISO(SPI_MISO),
        .spi_0_external_MOSI(SPI_MOSI),
        .spi_0_external_SCLK(SPI_SCLK),
        .spi_0_external_SS_n(SPI_SS_n)
    );

    assign LEDR0 = (state<5);   // LED on while active

endmodule
