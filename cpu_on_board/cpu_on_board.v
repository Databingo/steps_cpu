`include "header.vh"

module cpu_on_board (
    // -- Pin --
    (* chip_pin = "PIN_L1" *)  input wire CLOCK_50, // 50 MHz clock
    (* chip_pin = "PIN_R22" *) input wire KEY0,     // Active-low reset button
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *) output wire [7:0] LEDG, // 8 green LEDs
    (* chip_pin = "R17" *) output reg LEDR9, // 1 red LEDs breath left most 
    //(* chip_pin = "U18, Y18, V19, T18, Y19, U19, R19, R20" *) output wire [7:0] LEDR0_0, // 8 red LEDs right
    (* chip_pin = "R20" *) output wire LEDR0, // 
    (* chip_pin = "R19" *) output wire LEDR1, // 
    (* chip_pin = "U18, Y18, V19, T18, Y19, U19" *) output wire [5:0] LEDR_PC, // 8 red LEDs right

    (* chip_pin = "F4" *)  output wire HEX30,

    (* chip_pin = "G5" *)  output wire HEX20,
    (* chip_pin = "G6" *)  output wire HEX21,

    (* chip_pin = "E1" *)  output wire HEX10,
    (* chip_pin = "H6" *)  output wire HEX11,

    (* chip_pin = "J2" *)  output wire HEX00,
    (* chip_pin = "J1" *)  output wire HEX01,
    (* chip_pin = "H2" *)  output wire HEX02,
    (* chip_pin = "H1" *)  output wire HEX03,

    (* chip_pin = "H15" *)  input wire PS2_CLK, 
    (* chip_pin = "J14" *)  input wire PS2_DAT,


    (* chip_pin = "V20" *)  output wire SPI_SCLK, //SD_CLK
    (* chip_pin = "Y20" *)  output wire SPI_MOSI, // SD_CMD
    (* chip_pin = "W20" *)  input wire SPI_MISO,// SD_DAT
    (* chip_pin = "U20" *)  output wire SPI_SS_n // SD_DAT3


    
    input  wire CLOCK_50,        // 50 MHz
    input  wire KEY0,            // Active low reset

    //output reg  SPI_SCLK,        // SD CLK  (V20)
    //output reg  SPI_MOSI,        // SD CMD  (Y20)
    //input  wire SPI_MISO,        // SD DAT0 (W20)
    //output reg  SPI_SS_n,        // SD DAT3 (U20) -> CS
    output reg  LEDR0            // Status LED
);

    // Clock divider: 50 MHz -> 400 kHz for SD init
    // (50,000,000 / (2 * 400,000) = 62)
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

    // Simple SPI state machine
    reg [7:0] cmd [0:5];  // CMD0 = 0x40 00 00 00 00 95
    reg [2:0] state;
    reg [7:0] bit_cnt;
    reg [7:0] byte_cnt;
    reg [7:0] response;
    reg [7:0] miso_shift;

    initial begin
        cmd[0] = 8'h40; cmd[1] = 8'h00; cmd[2] = 8'h00; cmd[3] = 8'h00; cmd[4] = 8'h00; cmd[5] = 8'h95;
        SPI_SS_n = 1'b1;
        SPI_MOSI = 1'b1;
        SPI_SCLK = 1'b0;
        LEDR0 = 1'b0;
        state = 0;
        byte_cnt = 0;
        bit_cnt = 7;
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
                    // Provide 80 clocks with CS high to enter SPI mode
                    SPI_SS_n <= 1'b1;
                    SPI_MOSI <= 1'b1;
                    if (byte_cnt >= 10) begin
                        byte_cnt <= 0;
                        bit_cnt <= 7;
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
                        end else
                            byte_cnt <= byte_cnt + 1;
                    end else
                        bit_cnt <= bit_cnt - 1;
                end
                2: begin
                    // Wait for response
                    SPI_MOSI <= 1'b1;
                    miso_shift <= {miso_shift[6:0], SPI_MISO};
                    if (miso_shift == 8'h01) begin
                        LEDR0 <= 1'b1; // got 0x01 = success
                        state <= 3;
                    end
                end
                3: begin
                    // Idle
                    SPI_SS_n <= 1'b1;
                end
            endcase
        end
    end

endmodule



