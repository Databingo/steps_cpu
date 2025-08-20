module cpu_on_board (
    (* chip_pin = "PIN_L1" *) input wire CLOCK_50, // 50 MHz clock (DE2-115)
    (* chip_pin = "PIN_R22" *) input wire KEY0,    // Active-low reset
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *) 
    output wire [7:0] LEDG, // 8 green LEDs
    (* chip_pin = "R20" *) output reg LEDR0,   // Red LED
    (* chip_pin = "R17" *) output reg LEDR9    // Red LED
);

    (* ram_style = "block" *) reg [31:0] mem [0:2999]; // Word-addressable BRAM
    initial $readmemb("mem.mif", mem);

    reg [31:0] pc; // Byte-addressed PC
    wire [31:0] ir; // Instruction as wire
    reg [31:0] re; // Register file (example)
    wire clock_1hz;

    // JTAG pins (auto-connected by Quartus to USB-Blaster)
    wire tck, tms, tdi, tdo;

    // JTAG UART signals
    wire [7:0] tx_data; // Data to transmit
    reg tx_trigger;     // Trigger transmission
    wire tx_busy;       // Transmission busy

    // Instantiate JTAG UART transmitter
    simple_jtag_uart_tx jtag_uart_inst (
        .clk(CLOCK_50),
        .reset_n(KEY0),
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(tdo),
        .write_en(tx_trigger),
        .write_data(tx_data)
    );

    clock_slower clock_ins (
        .clk_in(CLOCK_50),
        .clk_out(clock_1hz),
        .reset_n(KEY0)
    );

    // IF stage: Fetch instruction
    assign ir = mem[pc >> 2]; // Little-endian

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

module simple_jtag_uart_tx (
    // JTAG Interface (These are special wires connected automatically by Quartus)
    input  wire tck,
    input  wire tms,
    input  wire tdi,
    output wire tdo,

    // CPU / System Interface
    input  wire clk,         // System clock (must be fast, e.g., 50 MHz)
    input  wire reset_n,     // Active-low reset
    input  wire write_en,    // A pulse to signal a new byte is ready
    input  wire [7:0] write_data // The 8-bit byte to send
);
    // --- Part 1: JTAG Test Access Port (TAP) Controller ---
    reg [3:0] tap_state;
    localparam TLR=4'h0, RTI=4'h1, SDR=4'h2, CDR=4'h3, SDRS=4'h4,
               E1DR=4'h5, PDR=4'h6, E2DR=4'h7, UDR=4'h8, SIR=4'h9,
               CIR=4'hA, SIRS=4'hB, E1IR=4'hC, PIR=4'hD, E2IR=4'hE, UIR=4'hF;
    always @(posedge tck or negedge reset_n) begin
        if (!reset_n) tap_state <= TLR;
        else case(tap_state)
            TLR:  tap_state <= tms ? RTI : TLR; RTI:  tap_state <= tms ? SDR : RTI;
            SDR:  tap_state <= tms ? SIR : CDR; CDR:  tap_state <= tms ? E1DR : SDRS;
            SDRS: tap_state <= tms ? E1DR : SDRS; E1DR: tap_state <= tms ? UDR : PDR;
            PDR:  tap_state <= tms ? E2DR : PDR; E2DR: tap_state <= tms ? UDR : SDRS;
            UDR:  tap_state <= tms ? SDR : RTI; SIR:  tap_state <= tms ? TLR : CIR;
            CIR:  tap_state <= tms ? E1IR : SIRS; SIRS: tap_state <= tms ? E1IR : SIRS;
            E1IR: tap_state <= tms ? UIR : PIR; PIR:  tap_state <= tms ? E2IR : PIR;
            E2IR: tap_state <= tms ? UIR : SIRS; UIR:  tap_state <= tms ? SDR : RTI;
            default: tap_state <= TLR;
        endcase
    end
    // --- Part 2: JTAG Instruction Register (IR) ---
    reg [9:0] ir_jtag;
    wire is_user1 = (ir_jtag == 10'h001);
    always @(posedge tck or negedge reset_n) begin
        if (!reset_n) ir_jtag <= 0;
        else if (tap_state == CIR) ir_jtag <= 10'h001;
        else if (tap_state == SIRS) ir_jtag <= {tdi, ir_jtag[9:1]};
    end
    // --- Part 3: Asynchronous FIFO (The Bridge) ---
    reg [7:0] fifo[0:15]; reg [3:0] fifo_wptr, fifo_rptr;
    wire fifo_empty = (fifo_wptr == fifo_rptr);
    wire fifo_full = (fifo_wptr == fifo_rptr + 1);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            fifo_wptr <= 0;
            fifo_rptr <= 0;
        end else if (write_en && !fifo_full) begin
            fifo[fifo_wptr] <= write_data;
            fifo_wptr <= fifo_wptr + 1;
        end
    end
    always @(posedge tck or negedge reset_n) begin
        if (!reset_n) begin
            fifo_rptr <= 0;
        end else if (tap_state == UDR && is_user1 && !fifo_empty) begin
            fifo_rptr <= fifo_rptr + 1;
        end
    end
    // --- Part 4: JTAG Data Register (DR) ---
    reg [7:0] dr;
    assign tdo = dr[0];
    always @(posedge tck or negedge reset_n) begin
        if (!reset_n) dr <= 8'h00;
        else if (is_user1) begin
            if (tap_state == CDR) dr <= fifo_empty ? 8'h00 : fifo[fifo_rptr];
            else if (tap_state == SDRS) dr <= {1'b0, dr[7:1]};
        end
    end
endmodule

module clock_slower (
    input wire clk_in,
    input wire reset_n,
    output reg clk_out
);
    reg [25:0] counter;
    localparam HALF_PERIOD = 25'd24999999; // For 50MHz -> 1Hz

    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 0;
            clk_out <= 1'b0;
        end else begin
            if (counter == HALF_PERIOD) begin
                counter <= 0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule
