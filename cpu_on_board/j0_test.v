// =================================================================================
// Original CPU file with minimal changes to add the Qsys JTAG UART
// =================================================================================

module cpu_on_board (
    (* chip_pin = "PIN_L1" *)  input wire CLOCK_50, // 50 MHz clock
    (* chip_pin = "PIN_R22" *) input wire KEY0,     // Active-low reset button
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *) output wire [7:0] LEDG, // 8 green LEDs
    (* chip_pin = "R17" *) output reg LEDR9, // 1 red LEDs breath left most 
    (* chip_pin = "U18, Y18, V19, T18, Y19, U19, R19, R20" *) output wire [7:0] LEDR7_0 // 8 red LEDs right
);

    // --- Memory and Original CPU State (Unchanged) ---
    (* ram_style = "block" *) reg [31:0] mem [0:2999]; // Unified Memory
    initial $readmemb("mem.mif", mem);

    reg [24:0] counter; // Original, unused counter
    reg [31:0] addr_pc; // Original, unused pc
    
    reg [31:0] ir;
    wire [31:0] ir_bd; assign ir_bd = mem[pc>>2];
    wire [31:0] ir_ld; assign ir_ld = {ir_bd[7:0], ir_bd[15:8], ir_bd[23:16], ir_bd[31:24]}; // Endianness swap

    reg [31:0] pc;
    reg [63:0] re [0:31]; // General-purpose registers (x0-x31)
    integer i; // <<< NEW: Added integer for reset loop

    wire clock_1hz;
    clock_slower clock_ins(
        .clk_in(CLOCK_50),
        .clk_out(clock_1hz),
        .reset_n(KEY0)
    );

    // --- Immediate decoders (Unchanged) --- 
    wire signed [63:0] w_imm_i = {{52{ir[31]}}, ir[31:20]};
    wire signed [63:0] w_imm_s = {{52{ir[31]}}, ir[31:25], ir[11:7]};
    wire signed [63:0] w_imm_b = {{51{ir[31]}}, ir[7],  ir[30:25], ir[11:8], 1'b0};
    wire signed [63:0] w_imm_u = {{32{ir[31]}}, ir[31:12], 12'b0};
    wire signed [63:0] w_imm_j = {{43{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0};
  
    // --- Instruction Decoding (Unchanged, but now used) ---
    wire [4:0] w_rd  = ir[11:7];
    wire [4:0] w_rs1 = ir[19:15];
    wire [4:0] w_rs2 = ir[24:20];

    // --- NEW: Bus signals from CPU to peripherals ---
    reg [63:0] mem_addr;
    reg        mem_we;

    // --- NEW: Wires for Avalon-MM Interface to Qsys System ---
    wire [0:0]  avalon_address;
    wire        avalon_write;
    wire [31:0] avalon_writedata;

    // --- NEW: Instantiate the Qsys system with the JTAG UART ---
    jtag_uart_system my_jtag_system (
        .clk_clk                             (CLOCK_50),
        .reset_reset_n                       (KEY0),
        .jtag_uart_0_avalon_jtag_slave_address   (avalon_address),
        .jtag_uart_0_avalon_jtag_slave_writedata (avalon_writedata),
        .jtag_uart_0_avalon_jtag_slave_write_n   (~avalon_write),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        .jtag_uart_0_avalon_jtag_slave_read_n    (1'b1)
    );

    // IF ir (Unchanged)
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin 
            LEDR9 <= 1'b0; 
            ir <= 32'h00000000; 
        end else begin
            LEDR9 <= ~LEDR9; // heartbeat
            ir <= ir_ld;
        end
    end

    // EXE pc (Changed to add more instructions and reset logic)
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin 
            pc <= 0;
            mem_we <= 1'b0; // <<< NEW
            for (i=0; i<32; i=i+1) re[i] <= 0; // <<< NEW: Reset all registers
        end else begin
            pc <= pc + 4;
            mem_we <= 1'b0; // <<< NEW: Default to no write
            
	    // <<< CHANGED: add Addi SB
	    casez(ir)
            32'b???????_?????_?????_???_?????_0110111:  re[w_rd] <= w_imm_u; // Lui
            32'b???????_?????_?????_???_?????_0010011:  re[w_rd] <= re[w_rs1] + w_imm_i; //Addi
	    32'b???????_?????_?????_???_?????_0100011:  begin mem_addr <= re[w_rs1] + w_imm_s; mem_we <= 1'b1; end // SB trigger UART
 	    endcase

            re[0] <= 0; // <<< NEW: Enforce x0 is always zero
        end
    end

   // LED Assignments (Unchanged)
   assign LEDG = ir[7:0];
   assign LEDR7_0 = re[31][19:12];
   
   // --- NEW: Avalon Bus Driver Logic ---
   // This translates the CPU's memory write into an Avalon bus transaction.
   assign avalon_write     = mem_we && (mem_addr[31]); // Write to UART if address is high
   assign avalon_address   = mem_addr[0]; // UART data register is at address 0
   assign avalon_writedata = {24'd0, re[w_rs2][7:0]}; // Send the lowest byte of rs2

endmodule


// clock_slower module (Unchanged)
module clock_slower(
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
        end else begin
            if (counter == 25000000 - 1) begin
                counter <= 0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule
