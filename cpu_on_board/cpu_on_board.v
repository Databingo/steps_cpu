
module cpu_on_board (
    input  wire CLOCK_50,
    input  wire KEY0,           // active-low reset
    output reg  SPI_SCLK,       // SD_CLK (V20)
    output reg  SPI_MOSI,       // SD_CMD (Y20)
    input  wire SPI_MISO,       // SD_DAT0 (W20)
    output reg  SPI_SS_n,       // SD_DAT3 (U20)
    output reg  LEDR0
);

    // -----------------------------
    // JTAG UART interface (simple)
    // -----------------------------
    reg  [31:0] uart_writedata;
    reg         uart_write;
    jtag_uart_system uart0 (
        .clk_clk(CLOCK_50),
        .reset_reset_n(KEY0),
        .jtag_uart_0_avalon_jtag_slave_address(1'b0),
        .jtag_uart_0_avalon_jtag_slave_writedata(uart_writedata),
        .jtag_uart_0_avalon_jtag_slave_write_n(~uart_write),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        .jtag_uart_0_avalon_jtag_slave_read_n(1'b1)
    );

    // UART print one character
    task print_char;
        input [7:0] c;
        begin
            uart_writedata <= {24'd0, c};
            uart_write <= 1;
            #1 uart_write <= 0;
        end
    endtask

    // -----------------------------
    // SPI slow clock divider (~400 kHz)
    // -----------------------------
    reg [7:0] div;
    always @(posedge CLOCK_50 or negedge KEY0)
        if (!KEY0) begin
            div <= 0; SPI_SCLK <= 0;
        end else if (div == 62) begin
            div <= 0; SPI_SCLK <= ~SPI_SCLK;
        end else div <= div + 1;

    // -----------------------------
    // Simple SPI CMD0 test
    // -----------------------------
    reg [2:0] state;
    reg [7:0] byte_cnt, bit_cnt;
    reg [7:0] cmd [0:5];
    reg [7:0] resp;
    reg [15:0] waitcnt;

    initial begin
        cmd[0]=8'h40; cmd[1]=0; cmd[2]=0; cmd[3]=0; cmd[4]=0; cmd[5]=8'h95;
        SPI_SS_n=1; SPI_MOSI=1; LEDR0=0;
        state=0; byte_cnt=0; bit_cnt=7;
    end

    always @(posedge SPI_SCLK or negedge KEY0) begin
        if (!KEY0) begin
            state <= 0; SPI_SS_n <= 1; SPI_MOSI <= 1; LEDR0 <= 0;
        end else case (state)
            0: begin
                SPI_SS_n <= 1; SPI_MOSI <= 1;
                if (byte_cnt==10) begin
                    print_char("S"); print_char("T"); print_char("A"); print_char("R"); print_char("T"); print_char(10);
                    byte_cnt<=0; state<=1;
                end else byte_cnt<=byte_cnt+1;
            end
            1: begin
                SPI_SS_n <= 0;
                SPI_MOSI <= cmd[byte_cnt][bit_cnt];
                if (bit_cnt==0) begin
                    bit_cnt<=7;
                    if (byte_cnt==5) begin
                        byte_cnt<=0; waitcnt<=0; state<=2;
                        print_char("C"); print_char("M"); print_char("D"); print_char("0"); print_char(10);
                    end else byte_cnt<=byte_cnt+1;
                end else bit_cnt<=bit_cnt-1;
            end
            2: begin
                SPI_MOSI<=1; resp<={resp[6:0],SPI_MISO};
                waitcnt<=waitcnt+1;
                if (resp==8'h01) begin
                    LEDR0<=1; print_char("O"); print_char("K"); print_char(10); state<=3;
                end else if (waitcnt==16'hFFFF) begin
                    print_char("T"); print_char("O"); print_char("!"); print_char(10); state<=3;
                end
            end
            3: SPI_SS_n <= 1;
        endcase
    end
endmodule
