`include "header.vh"

module cpu_on_board (
    // -- Pin mapping --
    (* chip_pin = "PIN_L1" *)  input  wire CLOCK_50,
    (* chip_pin = "PIN_R22" *) input  wire KEY0,
    (* chip_pin = "V20" *)     output reg  SPI_SCLK, // SD_CLK
    (* chip_pin = "Y20" *)     output reg  SPI_MOSI, // SD_CMD
    (* chip_pin = "W20" *)     input  wire SPI_MISO, // SD_DAT
    (* chip_pin = "U20" *)     output reg  SPI_SS_n, // SD_DAT3
    (* chip_pin = "R20" *)     output reg  LEDR0
);

    // -------------------
    // JTAG UART signals
    // -------------------
    wire [31:0] uart_readdata;
    reg  [31:0] uart_writedata;
    reg         uart_write_trigger_pulse;
    wire        uart_waitrequest;
    wire        uart_chipselect = 1'b1;

    // JTAG UART IP instance
    jtag_uart_system my_jtag_system (
        .clk_clk(CLOCK_50),
        .reset_reset_n(KEY0),
        .jtag_uart_0_avalon_jtag_slave_address(1'b0),
        .jtag_uart_0_avalon_jtag_slave_writedata(uart_writedata),
        .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write_trigger_pulse),
        .jtag_uart_0_avalon_jtag_slave_chipselect(uart_chipselect),
        .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
    );

    // Simple UART print task (one character per call)
    task uart_print_char(input [7:0] c);
    begin
        uart_writedata <= {24'b0, c};
        uart_write_trigger_pulse <= 1'b1;
        @(posedge CLOCK_50);
        uart_write_trigger_pulse <= 1'b0;
        repeat (2) @(posedge CLOCK_50);
    end
    endtask

    // Helper to print a string
    task uart_print_string(input [8*32-1:0] str);
        integer i;
        reg [7:0] c;
    begin
        for (i = 31; i >= 0; i = i - 1) begin
            c = str[i*8 +: 8];
            if (c != 8'h00)
                uart_print_char(c);
        end
    end
    endtask

    // -------------------
    // SPI Clock Divider
    // -------------------
    reg [7:0] clk_div;
    reg spi_clk_en;
    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            clk_div <= 0;
            SPI_SCLK <= 0;
            spi_clk_en <= 0;
        end else begin
            clk_div <= clk_div + 1;
            if (clk_div >= 62) begin
                clk_div <= 0;
                SPI_SCLK <= ~SPI_SCLK;
                spi_clk_en <= 1;
            end else
                spi_clk_en <= 0;
        end
    end

    // -------------------
    // SPI Test FSM
    // -------------------
    reg [7:0] cmd [0:5];  // CMD0 = 0x40 00 00 00 00 95
    reg [2:0] state;
    reg [7:0] bit_cnt;
    reg [7:0] byte_cnt;
    reg [7:0] miso_shift;
    reg [15:0] timeout;

    initial begin
        cmd[0] = 8'h40; cmd[1] = 8'h00; cmd[2] = 8'h00; cmd[3] = 8'h00; cmd[4] = 8'h00; cmd[5] = 8'h95;
        SPI_SS_n = 1'b1;
        SPI_MOSI = 1'b1;
        SPI_SCLK = 1'b0;
        LEDR0 = 1'b0;
        state = 0;
        byte_cnt = 0;
        bit_cnt = 7;
        timeout = 0;
    end

    always @(posedge SPI_SCLK or negedge KEY0) begin
        if (!KEY0) begin
            state <= 0;
            SPI_SS_n <= 1'b1;
            SPI_MOSI <= 1'b1;
            LEDR0 <= 1'b0;
        end else begin
            case (state)
                0: begin
                    // 80 dummy clocks with CS high
                    SPI_SS_n <= 1'b1;
                    SPI_MOSI <= 1'b1;
                    if (byte_cnt == 10) begin
                        byte_cnt <= 0;
                        bit_cnt <= 7;
                        uart_print_string("START\n");
                        state <= 1;
                    end else
                        byte_cnt <= byte_cnt + 1;
                end
                1: begin
                    // Send CMD0
                    SPI_SS_n <= 1'b0;
                    SPI_MOSI <= cmd[byte_cnt][bit_cnt];
                    if (bit_cnt == 0) begin
                        bit_cnt <= 7;
                        if (byte_cnt == 5) begin
                            byte_cnt <= 0;
                            state <= 2;
                            uart_print_string("CMD0 sent\n");
                        end else
                            byte_cnt <= byte_cnt + 1;
                    end else
                        bit_cnt <= bit_cnt - 1;
                end
                2: begin
                    // Wait for response (0x01)
                    SPI_MOSI <= 1'b1;
                    miso_shift <= {miso_shift[6:0], SPI_MISO};
                    timeout <= timeout + 1;
                    if (miso_shift == 8'h01) begin
                        LEDR0 <= 1'b1;
                        uart_print_string("CMD0 OK\n");
                        state <= 3;
                    end else if (timeout > 16'hFFFF) begin
                        uart_print_string("TIMEOUT\n");
                        state <= 3;
                    end
                end
                3: begin
                    SPI_SS_n <= 1'b1;
                end
            endcase
        end
    end

endmodule
