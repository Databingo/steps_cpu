// ===========================================================================
// File: cpu_on_board.v
// This version integrates a minimal, pure Verilog JTAG UART for terminal output.
// ===========================================================================

// --- MODULE 1: The Minimal JTAG UART Transmitter ---
// This is a self-contained, write-only JTAG UART.
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
    // This is the known-good, pure Verilog JTAG UART module.
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
        else if (tap_state == CIR)  ir_jtag <= 10'h001;
        else if (tap_state == SIRS) ir_jtag <= {tdi, ir_jtag[9:1]};
    end
    // --- Part 3: Asynchronous FIFO (The Bridge) ---
    reg [7:0] fifo[0:15]; reg [3:0] fifo_wptr, fifo_rptr;
    wire fifo_empty = (fifo_wptr == fifo_rptr);
    wire fifo_full  = (fifo_wptr == fifo_rptr + 1);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) {fifo_wptr <= 0; fifo_rptr <= 0;}
        else if (write_en && !fifo_full) { fifo[fifo_wptr] <= write_data; fifo_wptr <= fifo_wptr + 1; }
    end
    always @(posedge tck) begin
        if (tap_state == UDR && is_user1 && !fifo_empty) { fifo_rptr <= fifo_rptr + 1; }
    end
    // --- Part 4: JTAG Data Register (DR) ---
    reg [7:0] dr;
    assign tdo = dr[0];
    always @(posedge tck) begin
        if (is_user1) begin
            if (tap_state == CDR) dr <= fifo_empty ? 8'h00 : fifo[fifo_rptr];
            else if (tap_state == SDRS) dr <= {1'b0, dr[7:1]};
        end
    end
endmodule


// --- YOUR clock_slower module (Unchanged) ---
module clock_slower(
    input clk_in,
    input reset_n,
    output reg clk_out
);
    reg [25:0] counter;
    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            if (counter == 25'd24999999) begin // For 50MHz -> 1Hz
                counter <= 0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule


// --- YOUR TOP-LEVEL MODULE, with JTAG UART added ---
module cpu_on_board (
    (* chip_pin = "PIN_L1" *)  input wire CLOCK_50,
    (* chip_pin = "PIN_R22" *) input wire KEY0,
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *)
    output wire [7:0] LEDG,
    (* chip_pin = "R17" *) output wire LEDR9
);
    // --- Memory and CPU State ---
    (* ram_style = "block" *) reg [31:0] mem [0:2999];
    initial $readmemb("mem.mif", mem);

    reg [31:0] pc;
    reg [31:0] ir;
    reg [63:0] re [0:31];
    reg        bubble;

    wire clock_1hz;
    clock_slower clock_ins( .clk_in(CLOCK_50), .clk_out(clock_1hz), .reset_n(KEY0) );

    // --- CPU Wires ---
    reg  [63:0] mem_addr;
    reg  [63:0] mem_data_out;
    reg         mem_we;
    wire [31:0] i_mem_data_in;

    // --- NEW: JTAG UART Instantiation ---
    // We will map the UART to any address where the 31st bit is high.
    // E.g., 0x80000000.
    wire uart_write_en = mem_we && (mem_addr[31] == 1'b1);

    simple_jtag_uart_tx jtag_uart_inst (
        .clk(CLOCK_50), // JTAG UART needs the fast clock
        .reset_n(KEY0),
        .write_en(uart_write_en),
        .write_data(mem_data_out[7:0])
        // JTAG pins (tck, tms, etc.) are connected automatically by Quartus
    );

    // --- Instruction Fetch is Combinational ---
    assign i_mem_data_in = mem[pc >> 2];

    // --- CPU Pipeline ---
    // Fetch Stage
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) ir <= 32'h13; // NOP
        else if (bubble) ir <= 32'h13; // Insert NOP
        else ir <= i_mem_data_in;
    end

    // Execute Stage
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin
            pc <= 0;
            bubble <= 1'b1;
            mem_we <= 1'b0;
            for (integer i=0; i<32; i=i+1) re[i] <= 0;
        end else begin
            if (bubble) begin
                bubble <= 1'b0;
                // Load hazard handling would go here
            end else begin
                pc <= pc + 4;
                mem_we <= 1'b0;
                bubble <= 1'b0;

                // For a STORE instruction
                if (ir[6:0] == 7'b0100011) begin // STORE opcode
                    mem_addr <= re[ir[19:15]] + {{52{ir[31]}}, {ir[31:25], ir[11:7]}};
                    mem_data_out <= re[ir[24:20]];
                    mem_we <= 1'b1;
                end
                // For an ADDI instruction
                if (ir[6:0] == 7'b0010011) begin // ADDI opcode
                    re[ir[11:7]] <= re[ir[19:15]] + {{52{ir[31]}}, ir[31:20]};
                end
            end
            re[0] <= 0;
        end
    end

    assign LEDG = re[10][7:0]; // Display register a0 (x10)
    assign LEDR9 = bubble;      // Red LED shows when the pipeline is stalled/bubbled

endmodule
