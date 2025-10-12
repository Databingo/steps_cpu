module cpu_on_board (
    //input  wire CLOCK_50,        // 50 MHz
    //input  wire KEY0,            // Active low reset
    //output reg  SPI_SCLK,        // SD CLK  (V20)
    //output reg  SPI_MOSI,        // SD CMD  (Y20)
    //input  wire SPI_MISO,        // SD DAT0 (W20)
    //output reg  SPI_SS_n,        // SD DAT3 (U20)
    //output reg  LEDR0            // Status LED

    // -- Pin --
    (* chip_pin = "PIN_L1" *)  input wire CLOCK_50, // 50 MHz clock
    (* chip_pin = "PIN_R22" *) input wire KEY0,     // Active-low reset button
    (* chip_pin = "R20" *) output wire LEDR0, // 
    (* chip_pin = "V20" *)  output wire SPI_SCLK, //SD_CLK
    (* chip_pin = "Y20" *)  output wire SPI_MOSI, // SD_CMD
    (* chip_pin = "W20" *)  input wire SPI_MISO,// SD_DAT
    (* chip_pin = "U20" *)  output wire SPI_SS_n // SD_DAT3





);

    // -------------------------
    // UART (JTAG UART simple)
    // -------------------------
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

    // Print helper (one ASCII char)
    task print_char;
        input [7:0] c;
        begin
            uart_data <= {24'd0, c};
            uart_write <= 1;
            #1 uart_write <= 0;
        end
    endtask

    // -------------------------
    // SPI clock divider (400 kHz)
    // -------------------------
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

    // -------------------------
    // SD SPI state machine
    // -------------------------
    reg [7:0] cmd [0:5];  // CMD0 = 0x40 00 00 00 00 95
    reg [2:0] state;
    reg [7:0] bit_cnt, byte_cnt, resp;
    reg [15:0] wait_cnt;

    initial begin
        cmd[0] = 8'h40; cmd[1] = 8'h00; cmd[2] = 8'h00; cmd[3] = 8'h00; cmd[4] = 8'h00; cmd[5] = 8'h95;
        SPI_SS_n = 1'b1;
        SPI_MOSI = 1'b1;
        SPI_SCLK = 1'b0;
        LEDR0 = 1'b0;
        state = 0; bit_cnt = 7; byte_cnt = 0;
    end

    // Main logic
    always @(posedge SPI_SCLK or negedge KEY0) begin
        if (!KEY0) begin
            state <= 0; SPI_SS_n <= 1; SPI_MOSI <= 1; LEDR0 <= 0;
        end else case (state)
            0: begin
                // print test char once
                print_char("A");
                SPI_SS_n <= 1; SPI_MOSI <= 1;
                if (byte_cnt >= 10) begin
                    byte_cnt <= 0; state <= 1;
                    print_char("S"); print_char("D"); print_char(10);
                end else
                    byte_cnt <= byte_cnt + 1;
            end

            1: begin
                // Send CMD0
                SPI_SS_n <= 0;
                SPI_MOSI <= cmd[byte_cnt][bit_cnt];
                if (bit_cnt == 0) begin
                    bit_cnt <= 7;
                    if (byte_cnt == 5) begin
                        byte_cnt <= 0; state <= 2; wait_cnt <= 0;
                        print_char("C"); print_char("M"); print_char("D"); print_char("0"); print_char(10);
                    end else
                        byte_cnt <= byte_cnt + 1;
                end else
                    bit_cnt <= bit_cnt - 1;
            end

            2: begin
                // Wait for response 0x01
                SPI_MOSI <= 1;
                resp <= {resp[6:0], SPI_MISO};
                wait_cnt <= wait_cnt + 1;
                if (resp == 8'h01) begin
                    LEDR0 <= 1; print_char("O"); print_char("K"); print_char(10); state <= 3;
                end else if (wait_cnt == 16'hFFFF) begin
                    print_char("T"); print_char("O"); print_char(10); state <= 3;
                end
            end

            3: SPI_SS_n <= 1; // done
        endcase
    end
endmodule
