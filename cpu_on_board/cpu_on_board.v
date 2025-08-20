// ===========================================================================
// File: cpu_on_board.v
// This is the final, minimalist design integrating the CPU with a
// self-contained JTAG UART for terminal output.
// ===========================================================================

// --- MODULE 1: The JTAG UART Transmitter ---
// This is essential for talking to nios2-terminal/USB-Blaster.
module jtag_uart_tx (
    // JTAG Interface (From USB-Blaster)
    input wire tck,
    input wire tms,
    input wire tdi,
    output wire tdo,

    // CPU / System Interface
    input wire clk,         // System clock
    input wire rst_n,       // Active-low reset
    input wire write_en,    // A pulse to signal a new byte is ready
    input wire [7:0] write_data // The 8-bit byte to send
);

    // --- JTAG TAP Controller State Machine (Simplified Standard) ---
    reg [3:0] tap_state;
    localparam TLR=4'h0, RTI=4'h1, SDR=4'h2, CDR=4'h3, SDRS=4'h4,
               E1DR=4'h5, UDR=4'h8, SIR=4'h9, CIR=4'hA, SIRS=4'hB, UIR=4'hF;

    always @(posedge tck or negedge rst_n) begin
        if (!rst_n) tap_state <= TLR;
        else case(tap_state) 
            TLR:  tap_state <= tms ? RTI : TLR; RTI:  tap_state <= tms ? SDR : RTI;
            SDR:  tap_state <= tms ? SIR : CDR; CDR:  tap_state <= tms ? E1DR : SDRS;
            SDRS: tap_state <= tms ? E1DR : SDRS; E1DR: tap_state <= tms ? UDR : 4'h6 /*PDR*/; // Simplified
            UDR:  tap_state <= tms ? SDR : RTI;
            SIR:  tap_state <= tms ? TLR : CIR; CIR:  tap_state <= tms ? E1IR : SIRS;
            SIRS: tap_state <= tms ? E1IR : SIRS; UIR: tap_state <= tms ? SDR : RTI;
            default: tap_state <= TLR;
        endcase
    end

    // --- JTAG Instruction Register (IR) ---
    reg [9:0] ir_reg;
    wire is_user1_instruction = (ir_reg == 10'h001); // USER1 instruction

    always @(posedge tck or negedge rst_n) begin
        if (!rst_n) ir_reg <= 0;
        else if (tap_state == CIR)  ir_reg <= 10'h001;
        else if (tap_state == SIRS) ir_reg <= {tdi, ir_reg[9:1]};
    end

    // --- Asynchronous FIFO (Bridge) ---
    reg [7:0] fifo[0:15];
    reg [3:0] fifo_wptr, fifo_rptr;
    wire fifo_empty = (fifo_wptr == fifo_rptr);
    
    // Write side (System Clock)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin fifo_wptr <= 0; end 
        else if (write_en && (fifo_wptr != fifo_rptr + 1)) begin // Simplified check for full
            fifo[fifo_wptr] <= write_data;
            fifo_wptr <= fifo_wptr + 1;
        end
    end
    
    // Read side (TCK Clock)
    always @(posedge tck or negedge rst_n) begin
        if (!rst_n) begin fifo_rptr <= 0; end 
        else if (tap_state == UDR && is_user1_instruction && !fifo_empty) {
            fifo_rptr <= fifo_rptr + 1;
        }
    end

    // --- JTAG Data Register (DR) ---
    reg [7:0] dr;
    assign tdo = dr[0];

    always @(posedge tck) begin
        if (is_user1_instruction) begin
            if (tap_state == CDR) begin
                dr <= fifo_empty ? 8'h00 : fifo[fifo_rptr];
            end else if (tap_state == SDRS) begin
                dr <= {1'b0, dr[7:1]};
            }
        end
    end
endmodule


// --- The CPU Module ---
module cpu (  
    input wire clock,
    input wire reset_n,
    // for instruction
    output reg [63:0] i_mem_addr,
    input wire [31:0] i_mem_data_in,
    // for data
    output reg [63:0] mem_addr,
    output reg [63:0] mem_data_out,
    output reg mem_we,
    input wire [63:0] mem_data_in,
    // Debug and Control
    output wire [31:0] ir_out,
    output wire [63:0] re_a0 // Expose a0 for direct connection
); 
  
    // --- Internal State ---
    reg [31:0] ir;
    reg [63:0] pc;
    reg [63:0] re [0:31];
    reg bubble; // Pipeline flush signal
    assign ir_out = ir;
    assign re_a0 = re[10]; // a0 is register x10

    // --- Instruction Decoding (Use your clean wires) ---
    wire [6:0] w_op = ir[6:0];
    wire [4:0] w_rd = ir[11:7];
    wire [2:0] w_f3 = ir[14:12]; 
    wire [4:0] w_rs1 = ir[19:15];
    wire [4:0] w_rs2 = ir[24:20];
    wire [6:0] w_f7 = ir[31:25];
    // Immediate decoders
    wire signed [63:0] w_imm_i = {{52{ir[31]}}, ir[31:20]};
    wire signed [63:0] w_imm_s = {{52{ir[31]}}, ir[31:25], ir[11:7]};
    wire signed [63:0] w_imm_b = {{51{ir[31]}}, ir[7],  ir[30:25], ir[11:8], 1'b0};
    wire signed [63:0] w_imm_u = {{32{ir[31]}}, ir[31:12], 12'b0};
    wire signed [63:0] w_imm_j = {{43{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0};
    
    // Stage 1: Instruction Fetch
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            ir <= 32'h00000013;
        end else begin
            i_mem_addr <= pc;
            ir <= i_mem_data_in;
        end
    end

    // Stage 2: Execute and PC Update
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            bubble <= 1'b0;
            pc <= 64'h0;
            for (integer i = 0; i < 32; i = i + 1) re[i] <= 64'h0;
            mem_we <= 0;
            mem_addr <= 0;
            mem_data_out <= 0;
        end else begin
            mem_we <= 0;
            if (bubble) begin 
                bubble <= 1'b0;
            end else begin 
                pc <= pc + 4;
                mem_we <= 0;
                
                casez(w_op) 
                    7'h13: begin // ADDI
                        if (w_f3 == 3'b000) re[w_rd] <= re[w_rs1] + w_imm_i;
                    end
                    // JAL and JALR logic
                    7'h6F: begin re[w_rd] <= pc + 4; pc <= pc + w_imm_j; bubble <= 1'b1; end // Jal
                    7'h67: begin re[w_rd] <= pc + 4; pc <= (re[w_rs1] + w_imm_i) & 64'hFFFFFFFFFFFFFFFE; bubble <= 1'b1; end // Jalr
                    // Branches
                    7'h63: begin
                        if (w_f3 == 3'b000 && re[w_rs1] == re[w_rs2]) begin pc <= pc + w_imm_b; bubble <= 1'b1; end // BEQ
                    end
                endcase
            end 
            re[0] <= 64'h0;
        end
    end
endmodule


// --- Clock Divider Module ---
module clock_divider(
    input wire clk_in,
    input wire reset_n,
    output reg clk_out
);
    reg [24:0] counter; 
    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            clk_out <= 0;
            counter <=0;
        end else if (counter == 25000000 - 1) begin
            counter <= 0;
            clk_out <= ~clk_out;
        end else begin
            counter <= counter + 1;
        end
    end
endmodule


// --- Top-Level Board Module (Main System) ---
module cpu_on_board (
    input wire CLOCK_50,
    input wire KEY0,
    // External JTAG pins for the JTAG UART
    input wire TCK, input wire TMS, input wire TDI, output wire TDO,
    // LEDs
    output wire [7:0] LEDG,
    output wire LEDR0,
    output wire [7:0] LEDR7_0
);

    // --- Wires and Internal Memory ---
    wire clk_cpu;
    wire [31:0] i_rdata; // Instruction Read Data
    wire [63:0] mem_addr, d_rdata, mem_wdata;
    wire mem_we;
    wire [63:0] reg_a0_show; // x10

    (* ram_style = "block" *) reg [31:0] mem [0:3999]; // Unified Memory
    initial $readmemh("mem.mif", mem);

    // --- 1. Clock Instantiation ---
    clock_divider clock_inst (
        .clk_in(CLOCK_50), .reset_n(KEY0), .clk_out(clk_cpu)
    );

    // --- 2. CPU Instantiation ---
    cpu cpu_inst (
        .clock(clk_cpu),
        .reset_n(KEY0),
        .i_mem_addr(mem_addr),
        .i_mem_data_in(i_rdata),
        .mem_addr(mem_addr),
        .mem_data_in(d_rdata),
        .mem_data_out(mem_wdata),
        .mem_we(mem_we),
        .ir_out(i_rdata), // Connect IR to the output wire
        .re_a0(reg_a0_show)
    );

    // --- 3. Memory Connection (Von Neumann Architecture) ---
    // Instruction Fetch: Combinational read from PC address
    assign i_rdata = mem[mem_addr >> 2];
    
    // Data Read: Synchronous read (simplified)
    always @(posedge clk_cpu) begin
        d_rdata <= {32'b0, mem[mem_addr >> 2]};
        // Data Write: Synchronous write
        if (mem_we) begin
            mem[mem_addr >> 2] <= mem_wdata[31:0];
        end
    end
    
    // --- 4. JTAG UART Instantiation ---
    // We will memory map the JTAG UART to 0xFFFF0000 (Example high address)
    wire jtag_write_en = mem_we & (mem_addr == 64'hFFFF0000);
    wire jtag_read_data; // Unused for TX test

    jtag_uart_tx uart_inst (
        .tck(TCK), .tms(TMS), .tdi(TDI), .tdo(TDO),
        .clk(CLOCK_50), // Use fast clock for UART timing
        .rst_n(KEY0),
        .write_en(jtag_write_en),
        .write_data(mem_wdata[7:0])
    );

    // --- 5. LED Display ---
    assign LEDG = i_rdata[7:0]; // Show the instruction byte
    assign LEDR7_0 = reg_a0_show[7:0]; // Show register a0 on Red LEDs
    assign LEDR0 = clk_cpu; // Heartbeat

endmodule
