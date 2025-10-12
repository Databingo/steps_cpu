module cpu_on_board (
    // -- Pin mapping --
    (* chip_pin = "PIN_L1"  *) input  wire CLOCK_50,
    (* chip_pin = "PIN_R22" *) input  wire KEY0,        // Active-low reset
    (* chip_pin = "R20"     *) output wire LEDR0,

    (* chip_pin = "V20" *) output wire SPI_SCLK,  // SD_CLK
    (* chip_pin = "Y20" *) output wire SPI_MOSI,  // SD_CMD
    (* chip_pin = "W20" *) input  wire SPI_MISO,  // SD_DAT0
    (* chip_pin = "U20" *) output wire SPI_SS_n   // SD_CS
);

    // ================================================================
    // 1. UART Test: print "A" periodically through JTAG UART IP
    // ================================================================
    reg [31:0] uart_data;
    reg uart_write;
    reg [23:0] counter;

    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            counter <= 0;
            uart_data <= 32'h41;   // ASCII "A"
            uart_write <= 0;
        end else begin
            counter <= counter + 1;
            if (counter == 24'd12_000_000) begin  // roughly every 0.24 sec at 50MHz
                uart_write <= 1;
            end else if (counter == 24'd12_000_010) begin
                uart_write <= 0;
                counter <= 0;
            end
        end
    end

    jtag_uart_system uart0 (
        .clk_clk(CLOCK_50),
        .reset_reset_n(KEY0),
        .jtag_uart_0_avalon_jtag_slave_address(1'b0),
        .jtag_uart_0_avalon_jtag_slave_writedata(uart_data),
        .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
    );

    // ================================================================
    // 2. SPI Test: basic toggle of SPI lines via IP core
    // ================================================================
    wire [15:0] spi_read_data_wire;
    reg [15:0] bus_write_data;
    reg [2:0]  bus_address;
    reg        bus_write_enable, bus_read_enable, Spi_selected;

    // Dummy activity to verify SPI toggling
    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            bus_write_data   <= 16'hA5A5;
            bus_write_enable <= 1'b0;
            bus_read_enable  <= 1'b0;
            Spi_selected     <= 1'b0;
            bus_address      <= 3'b000;
        end else begin
            bus_write_enable <= ~bus_write_enable; // toggle to make SPI clock visible
            Spi_selected     <= 1'b1;
        end
    end

    spi my_spi_system (
        .clk_clk(CLOCK_50),
        .reset_reset_n(KEY0),
        .spi_0_reset_reset_n(KEY0),
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

    // LED blinks as SPI toggles
    assign LEDR0 = Spi_selected;

endmodule
