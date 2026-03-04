// --- clock divider (Unchanged) ---
module clock_slower(
    input wire clk_in,
    input wire reset_n,
    output reg clk_out
);
    reg [24:0] counter = 0;
    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 0;
            clk_out <= 1'b0;
        end else begin
            if (counter == 25000000 - 1) begin // 50MHz -> 1Hz
                counter <= 0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule


// --- TOP-LEVEL MODULE ---
module cpu_on_board (
    (* chip_pin = "PIN_L1" *)  input  wire CLOCK_50,
    (* chip_pin = "PIN_R22" *) input  wire KEY0,
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *)
    output wire [7:0] LEDG,
    (* chip_pin = "R17" *)     output wire LEDR9,
    (* chip_pin = "U18, Y18, V19, T18, Y19, U19, R19, R20" *) 
    output wire [7:0] LEDR7_0
);

    // --- Memory and CPU State ---
    (* ram_style = "block" *) reg [31:0] mem [0:2999];
    initial $readmemb("mem.mif", mem);

    reg [31:0] pc;
    reg [31:0] ir;
    reg [63:0] re [0:31];
    integer i;

    wire clock_1hz;
    clock_slower clock_ins(
        .clk_in(CLOCK_50),
        .clk_out(clock_1hz),
        .reset_n(KEY0)
    );

    // --- Simple Bus signals from CPU ---
    reg [63:0] mem_addr;
    reg [63:0] mem_data_out;
    reg        mem_we;

    // --- Immediate and Register Decoders ---
    wire signed [63:0] w_imm_i = {{52{ir[31]}}, ir[31:20]};
    wire signed [63:0] w_imm_s = {{52{ir[31]}}, ir[31:25], ir[11:7]};
    wire [4:0] w_rd  = ir[11:7];
    wire [4:0] w_rs1 = ir[19:15];
    wire [4:0] w_rs2 = ir[24:20];

    // --- Wires for Avalon-MM Interface to Qsys System ---
    wire [0:0]  avalon_address;   // Address for Qsys. JTAG UART only needs 1 address bit.
    wire        avalon_write;     // Write signal for Qsys.
    wire [31:0] avalon_writedata; // 32-bit data bus for Qsys.

    // --- Instantiate the Qsys system with the JTAG UART ---
    // The module name comes from the 'Top-Level Name' in Qsys.
    jtag_uart_system my_jtag_system (
        .clk_clk                             (CLOCK_50),      // Connect to fast 50MHz clock
        .reset_reset_n                       (KEY0),          // Connect to active-low reset
        
        // Connect the Avalon slave port
        .jtag_uart_0_avalon_jtag_slave_address   (avalon_address),
        .jtag_uart_0_avalon_jtag_slave_writedata (avalon_writedata),
        .jtag_uart_0_avalon_jtag_slave_write_n   (~avalon_write), // Avalon uses active-low write_n
        
        // Tie off unused signals
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),         // Always selected
        .jtag_uart_0_avalon_jtag_slave_read_n    (1'b1)          // Never read
        // Readdata, waitrequest, etc. are outputs from the Qsys system and can be left open.
    );

    // --- Instruction Fetch ---
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin
            ir <= 32'h13; // NOP on reset
        end else begin
            ir <= mem[pc >> 2];
        end
    end

    // --- Execute and Decode Stage ---
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin
            pc <= 0;
            mem_we <= 1'b0;
            for (i=0; i<32; i=i+1) re[i] <= 0;
        end else begin
            pc <= pc + 4;
            mem_we <= 1'b0; // Default to no write

            // Decode and execute based on opcode ir[6:0]
            case (ir[6:0])
                // ADDI (I-type)
                7'b0010011: begin
                    re[w_rd] <= re[w_rs1] + w_imm_i;
                end
                
                // LUI (U-type)
                7'b0110111: begin
                    re[w_rd] <= {{32{ir[31]}}, ir[31:12], 12'b0};
                end

                // SB, SH, SW, SD (S-type, Store instructions)
                7'b0100011: begin
                    mem_addr <= re[w_rs1] + w_imm_s;
                    mem_data_out <= re[w_rs2];
                    mem_we <= 1'b1; // Signal a memory write
                end

            endcase
            re[0] <= 0; // x0 is always zero
        end
    end

    // --- Avalon Bus Driver Logic ---
    // This logic translates the CPU's memory write into an Avalon bus transaction.
    // It will only be active for one cycle when mem_we is high.
    assign avalon_write     = mem_we && (mem_addr[31]); // Write to JTAG UART if address is high
    assign avalon_address   = mem_addr[0]; // The JTAG UART data register is at address 0
    assign avalon_writedata = {24'd0, mem_data_out[7:0]}; // Send the lowest byte

    // --- Connect to LEDs ---
    assign LEDG = re[10][7:0];    // Display register a0 (x10)
    assign LEDR7_0 = pc[11:4]; // Display part of the PC
    assign LEDR9 = ~KEY0;         // Show reset status
endmodule
