
// ===========================================================================
// File: cpu_on_board.v
// Minimal, pure-Verilog JTAG-ish TX (demo only) + simple CPU scaffold
// NOTE: Group multiple statements with begin/end, not {...}.
// ===========================================================================

// --- MODULE 1: The Minimal JTAG UART Transmitter (demo) ---
module simple_jtag_uart_tx (
    // These pins are placeholders; Intel tools do NOT auto-connect them.
    input  wire tck,
    input  wire tms,
    input  wire tdi,
    output wire tdo,

    input  wire clk,           // fast system clock (e.g., 50MHz)
    input  wire reset_n,       // active-low reset
    input  wire write_en,      // pulse to send a byte
    input  wire [7:0] write_data
);
    // --- TAP state machine (toy) ---
    reg [3:0] tap_state;
    localparam TLR=4'h0, RTI=4'h1, SDR=4'h2, CDR=4'h3, SDRS=4'h4,
               E1DR=4'h5, PDR=4'h6, E2DR=4'h7, UDR=4'h8, SIR=4'h9,
               CIR=4'hA, SIRS=4'hB, E1IR=4'hC, PIR=4'hD, E2IR=4'hE, UIR=4'hF;

    always @(posedge tck or negedge reset_n) begin
        if (!reset_n) tap_state <= TLR;
        else case (tap_state)
            TLR:   tap_state <= tms ? RTI  : TLR;
            RTI:   tap_state <= tms ? SDR  : RTI;
            SDR:   tap_state <= tms ? SIR  : CDR;
            CDR:   tap_state <= tms ? E1DR : SDRS;
            SDRS:  tap_state <= tms ? E1DR : SDRS;
            E1DR:  tap_state <= tms ? UDR  : PDR;
            PDR:   tap_state <= tms ? E2DR : PDR;
            E2DR:  tap_state <= tms ? UDR  : SDRS;
            UDR:   tap_state <= tms ? SDR  : RTI;
            SIR:   tap_state <= tms ? TLR  : CIR;
            CIR:   tap_state <= tms ? E1IR : SIRS;
            SIRS:  tap_state <= tms ? E1IR : SIRS;
            E1IR:  tap_state <= tms ? UIR  : PIR;
            PIR:   tap_state <= tms ? E2IR : PIR;
            E2IR:  tap_state <= tms ? UIR  : SIRS;
            UIR:   tap_state <= tms ? SDR  : RTI;
            default: tap_state <= TLR;
        endcase
    end

    // --- IR (toy) ---
    reg [9:0] ir_jtag;
    wire is_user1 = (ir_jtag == 10'h001);
    always @(posedge tck or negedge reset_n) begin
        if (!reset_n) ir_jtag <= 10'h000;
        else if (tap_state == CIR)  ir_jtag <= 10'h001;
        else if (tap_state == SIRS) ir_jtag <= {tdi, ir_jtag[9:1]};
    end

    // --- Tiny async FIFO (demo only; not CDC-safe) ---
    reg [7:0] fifo[0:15];
    reg [3:0] fifo_wptr, fifo_rptr;
    wire fifo_empty = (fifo_wptr == fifo_rptr);
    wire fifo_full  = ((fifo_wptr + 4'd1) == fifo_rptr);

    // write side (clk)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            fifo_wptr <= 4'd0;
            fifo_rptr <= 4'd0;
        end else if (write_en && !fifo_full) begin
            fifo[fifo_wptr] <= write_data;
            fifo_wptr <= fifo_wptr + 4'd1;
        end
    end

    // read side (tck)
    always @(posedge tck or negedge reset_n) begin
        if (!reset_n) begin
            // keep rptr at reset value
        end else if (tap_state == UDR && is_user1 && !fifo_empty) begin
            fifo_rptr <= fifo_rptr + 4'd1;
        end
    end

    // --- DR shift ---
    reg [7:0] dr;
    assign tdo = dr[0];

    always @(posedge tck or negedge reset_n) begin
        if (!reset_n) begin
            dr <= 8'h00;
        end else if (is_user1) begin
            if (tap_state == CDR)
                dr <= fifo_empty ? 8'h00 : fifo[fifo_rptr];
            else if (tap_state == SDRS)
                dr <= {1'b0, dr[7:1]};
        end
    end
endmodule

// --- clock divider to ~1Hz from 50MHz ---
module clock_slower(
    input  wire clk_in,
    input  wire reset_n,
    output reg  clk_out
);
    reg [25:0] counter;
    localparam HALF_PERIOD = 26'd24_999_999; // 50MHz -> 1Hz

    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 26'd0;
            clk_out <= 1'b0;
        end else begin
            if (counter == HALF_PERIOD) begin
                counter <= 26'd0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 26'd1;
            end
        end
    end
endmodule

// --- TOP ---
module cpu_on_board (
    (* chip_pin = "PIN_L1" *)  input  wire CLOCK_50,
    (* chip_pin = "PIN_R22" *) input  wire KEY0,
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *)
    output wire [7:0] LEDG,
    (* chip_pin = "R17" *) output wire LEDR9
);
    // memory
    (* ram_style = "block" *) reg [31:0] mem [0:2999];
    initial $readmemb("mem.mif", mem);

    // state
    reg [31:0] pc;
    reg [31:0] ir;
    reg [63:0] re [0:31];
    reg        bubble;
    integer i;

    // slow clock
    wire clock_1hz;
    clock_slower clock_ins(
        .clk_in (CLOCK_50),
        .reset_n(KEY0),
        .clk_out(clock_1hz)
    );

    // simple “bus”
    reg  [63:0] mem_addr;
    reg  [63:0] mem_data_out;
    reg         mem_we;
    wire [31:0] i_mem_data_in;

    // “UART” write when addr[31]==1
    wire uart_write_en = mem_we && mem_addr[31];

    // NOTE: tck/tms/tdi/tdo are unconnected here; this is a placeholder.
    simple_jtag_uart_tx jtag_uart_inst (
        .tck(1'b0), .tms(1'b0), .tdi(1'b0), .tdo(),   // TODO: replace with a real JTAG/Virtual JTAG
        .clk(CLOCK_50),
        .reset_n(KEY0),
        .write_en(uart_write_en),
        .write_data(mem_data_out[7:0])
    );

    // instruction fetch (word addressed)
    assign i_mem_data_in = mem[pc[31:2]];

    // FETCH
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0)       ir <= 32'h00000013; // NOP
        else if (bubble) ir <= 32'h00000013;
        else             ir <= i_mem_data_in;
    end

    // EXECUTE (toy)
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin
            pc     <= 32'd0;
            bubble <= 1'b1;
            mem_we <= 1'b0;
            for (i=0; i<32; i=i+1) re[i] <= 64'd0;
        end else begin
            if (bubble) begin
                bubble <= 1'b0;
            end else begin
                pc     <= pc + 32'd4;
                mem_we <= 1'b0;

                // STORE (S-type)
                if (ir[6:0] == 7'b0100011) begin
                    mem_addr     <= re[ir[19:15]] + {{52{ir[31]}}, ir[31:25], ir[11:7]};
                    mem_data_out <= re[ir[24:20]];
                    mem_we       <= 1'b1;
                end
                // ADDI (I-type)
                if (ir[6:0] == 7'b0010011) begin
                    re[ir[11:7]] <= re[ir[19:15]] + {{52{ir[31]}}, ir[31:20]};
                end
            end
            re[0] <= 64'd0;
        end
    end

    assign LEDG  = re[10][7:0];  // x10 low byte
    assign LEDR9 = bubble;

endmodule
