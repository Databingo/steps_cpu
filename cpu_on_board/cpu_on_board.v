module cpu_on_board (
    (* chip_pin = "PIN_L1" *) input wire CLOCK_50, // 50 MHz clock (DE2-115)
    (* chip_pin = "PIN_R22" *) input wire KEY0,    // Active-low reset
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *) 
    output wire [7:0] LEDG, // 8 green LEDs
    (* chip_pin = "R20" *) output reg LEDR0,   // Red LED
    (* chip_pin = "R17" *) output reg LEDR9    // Red LED
);

    // BRAM with explicit attributes for M4K inference
    (* ramstyle = "M4K" *) reg [31:0] mem [0:2999]; // 32-bit x 3000 words
    initial $readmemb("mem.mif", mem);

    reg [31:0] pc; // Byte-addressed PC
    reg [31:0] ir; // Instruction register (synchronous for RAM inference)
    reg [31:0] re; // Register file (example)
    wire clock_1hz;

    // JTAG UART signals
    wire tdo;           // JTAG output
    wire [7:0] tx_data; // Data to transmit
    reg tx_trigger;     // Trigger transmission
    wire tx_busy;       // Transmission busy

    // Instantiate JTAG UART transmitter
    jtag_uart_tx jtag_uart_inst (
        .clk(CLOCK_50),
        .rst_n(KEY0),
        .tx_data(tx_data),
        .tx_trigger(tx_trigger),
        .tx_busy(tx_busy),
        .tdo(tdo)
    );

    clock_slower clock_ins (
        .clk_in(CLOCK_50),
        .clk_out(clock_1hz),
        .reset_n(KEY0)
    );

    // Synchronous memory read to ensure RAM inference
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin
            ir <= 32'b0;
        end
        else begin
            ir <= mem[pc >> 2]; // Little-endian, word-addressed
        end
    end

    // Update PC, re, and JTAG trigger
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin 
            LEDR0 <= 1'b0;
            pc <= 0;
            re <= 32'h0;
            tx_trigger <= 1'b0;
        end
        else begin
            LEDR0 <= ~LEDR0; // Heartbeat
            pc <= (pc == 11996) ? 0 : pc + 4; // Increment by 4 bytes
            re <= re + 1; // Example: replace with actual logic
            tx_trigger <= !tx_busy; // Trigger when not busy
        end
    end

    // EXE stage: Process instruction and re[0]
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin
            LEDR9 <= 1'b0;
        end
        else begin
            LEDR9 <= (ir[6:0] == 7'b0110111) || re[0]; // LUI or re[0]
        end
    end

    // Transmit ir[7:0] as ASCII (0x01 -> '1')
    assign tx_data = (ir[7:0] <= 9) ? ir[7:0] + 8'h30 : 8'h2E; // 0-9 to '0'-'9', else '.'

    // Display big-endian byte
    assign LEDG = mem[pc >> 2][31:24]; // 0x93 for 0x93000201

endmodule

module jtag_uart_tx (
    input wire clk,        // System clock (50 MHz)
    input wire rst_n,      // Active-low reset
    input wire [7:0] tx_data, // Data to transmit
    input wire tx_trigger, // Trigger transmission
    output reg tx_busy,    // Transmission busy
    output reg tdo         // JTAG data out
);

    // Simplified JTAG states
    localparam IDLE = 2'd0, SHIFT_DR = 2'd1, UPDATE_DR = 2'd2;
    reg [1:0] state, next_state;
    reg [7:0] shift_reg; // Shift register for data
    reg [3:0] bit_count; // Bit counter for 8-bit data
    reg tck_sim; // Simulated TCK for simplicity

    // Simulate TCK (10 MHz, derived from 50 MHz clk)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) tck_sim <= 0;
        else tck_sim <= ~tck_sim; // Toggle every cycle (~25 MHz, simplified)
    end

    // JTAG state machine
    always @(posedge tck_sim or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            shift_reg <= 8'b0;
            bit_count <= 4'b0;
            tdo <= 1'b0;
            tx_busy <= 1'b0;
        end
        else begin
            state <= next_state;
            if (state == SHIFT_DR) begin
                if (bit_count < 8) begin
                    tdo <= shift_reg[0]; // Shift out LSB
                    shift_reg <= {1'b0, shift_reg[7:1]}; // Shift right
                    bit_count <= bit_count + 1;
                end
            end
            else if (state == IDLE && tx_trigger && !tx_busy) begin
                shift_reg <= tx_data; // Load new data
                bit_count <= 4'b0;
                tx_busy <= 1'b1;
            end
            else if (state == UPDATE_DR) begin
                tx_busy <= 1'b0; // Transmission complete
            end
        end
    end

    // Next state logic (simplified, no external TCK/TMS/TDI)
    always @(*) begin
        case (state)
            IDLE: next_state = tx_trigger ? SHIFT_DR : IDLE;
            SHIFT_DR: next_state = (bit_count == 7) ? UPDATE_DR : SHIFT_DR;
            UPDATE_DR: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

endmodule

module clock_slower (
    input wire clk_in,
    input wire reset_n,
    output reg clk_out
);
    reg [24:0] counter; 
    initial begin
        clk_out <= 0;
        counter <= 0;
    end
    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            clk_out <= 0;
            counter <= 0;
        end
        else begin
            if (counter == 25000000 - 1) begin
                counter <= 0;
                clk_out <= ~clk_out;
            end
            else begin
                counter <= counter + 1;
            end
        end
    end
endmodule
