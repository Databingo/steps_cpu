// Two-Stage (Fetch/Execute) Pipelined CPU
module cpu (  
    input wire clock,
    input wire reset_n,
    // for instruction
    output reg [63:0] i_mem_addr,   // Address of instruction
    input wire [31:0] i_mem_data_in, // Instruction backs from memory
    // for data
    output reg [63:0] mem_addr,     // Memory address for load/store
    output reg [63:0] mem_data_out, // Data to write to memory (store)
    output reg mem_we,              // Memory write enable
    input wire [63:0] mem_data_in,   // Data read from memory (load)

    output reg [31:0] ir_out // Address of instruction
    ); 
  

    // --- Regisers and Memories ---
    reg [31:0] ir; // Instruction register
    reg [63:0] re [0:31]; // General-purpose registers (x0-x31)
    reg [63:0] pc; // Program counter
    assign ir_out = ir;
  
    // --- Instruction Decoding ---
    wire [ 6:0] w_op = ir[6:0];
    wire [ 4:0] w_rd = ir[11:7];
    wire [ 2:0] w_f3 = ir[14:12]; 
    wire [ 4:0] w_rs1 = ir[19:15];
    wire [ 4:0] w_rs2 = ir[24:20];
    wire [ 6:0] w_f7 = ir[31:25];
    wire [11:0] w_imm = ir[31:20];   // I-type immediate Lb Lh Lw Lbu Lhu Lwu Ld Jalr Addi Slti Sltiu Xori Ori Andi Addiw
    wire [19:0] w_upimm = ir[31:12]; // U-type immediate Lui Auipc
    wire [20:0] w_jimm = {ir[31], ir[19:12], ir[20], ir[30:21], 1'b0}; // UJ-type immediate Jal  // read immediate & padding last 0, total 20 + 1 = 21 bits
    wire [11:0] w_simm = {ir[31:25], ir[11:7]};  // S-type immediate Sb Sh Sw Sd
    wire [12:0] w_bimm = {ir[31], ir[7],  ir[30:25], ir[11:8], 1'b0}; // SB-type immediate Beq Bne Blt Bge Bltu Bgeu // read immediate & padding last 0, total 12 + 1 = 13 bits
    wire [ 5:0] w_shamt = ir[25:20]; // If 6 bits the highest is always 0??
    wire [11:0] w_csr = ir[31:20];   // CSR address
    wire [11:0] w_f12 = ir[31:20];   // ecall 0, ebreak 1
    wire [ 4:0] w_zimm = ir[19:15];  // CSR zimm

    // --- Combinational Logic (Immediate)---
    wire [63:0] sum = re[w_rs1] + re[w_rs2];
    wire [63:0] sum_imm = re[w_rs1] + {{52{w_imm[11]}}, w_imm};
    wire [31:0] sum_imm_32 = re[w_rs1][31:0] + {{20{w_imm[11]}}, w_imm};
    wire [63:0] sub = re[w_rs1] - re[w_rs2];
    wire [63:0] sub_imm = re[w_rs1] - {{52{w_imm[11]}}, w_imm};
    wire [63:0] sign_extended_bimm = {{51{ir[31]}}, w_bimm};  //bimm is 13 bits length
    wire [31:0] slliw_s1 = re[w_rs1][31:0] << w_shamt[4:0]; 
    wire [31:0] srliw_s1 = re[w_rs1][31:0] >> w_shamt[4:0]; 
    wire [31:0] sraiw_s1 = $signed(re[w_rs1][31:0]) >>> w_shamt[4:0]; 

    // --- Memory Access ---
    wire [63:0] l_addr = re[w_rs1] + {{52{w_imm[11]}}, w_imm}; // Load address
    wire [63:0] s_addr = re[w_rs1] + {{52{w_simm[11]}}, w_simm}; // Store address
      
    // --- Flush signal ---
    reg bubble;

    // ---  Stage 1: IF (instruction fetch by PC) ---
    always @(posedge clock or negedge reset_n) begin
	if (!reset_n) begin
	    ir <= 32'h00000013;  // On reset load NOP 
	end else begin
	    i_mem_addr <= pc;    // sent out current PC to instruction memeory
	    ir <= i_mem_data_in; // latch the PC-refered instruciton back in cpu
	end
    end

    // ---  Stage 2: Execute (decode & execute & set PC) ---
    always @(posedge clock or negedge reset_n) begin
	if (!reset_n) begin
	    bubble <= 1'b0;
	    pc <= 64'h0;
	    for (integer i = 0; i < 32; i = i + 1) re[i] <= 64'h0;  //!!初始化零否则新启用寄存器就不灵
	    mem_we <= 0;
            mem_addr <= 0;
	    mem_data_out <= 0;
	end else begin // 取指令 + 分析指令 + 执行 | 或 准备数据 (分析且备好该指令所需的数据）
            pc <= pc +4 ;// Default: advance PC for most instructions; override in jumps/branches/traps 
	    if (bubble) begin 
		bubble <= 1'b0; // Flush this cycle & Clear flush signal for the next cycle
	    end else begin 
	        mem_we <= 0; // Default: no memeory write
    	        casez(ir) 
	        // U-type
                32'b???????_?????_?????_???_?????_0110111: re[w_rd] <= {{32{w_upimm[19]}}, w_upimm, 12'b0}; // Lui
	        32'b???????_?????_?????_???_?????_0010111: re[w_rd] <= pc + {{32{w_upimm[19]}}, w_upimm, 12'b0}; // Auipc
                // Load
	        32'b???????_?????_?????_000_?????_0000011: begin mem_addr <= l_addr; re[w_rd] <= {{56{mem_data_in[7]}}, mem_data_in[7:0]}; end // Lb
    	        endcase
	   end
           re[0] <= 64'h0;  // x0 hardwared 0
        end
    end
endmodule

module clock_divider(
    input wire clk_in,
    output reg clk_out
    );
    reg [24:0] counter;
    initial begin
	clk_out <= 0;
	counter <= 0;
    end
    always @(posedge clk_in) begin
	if (counter == 0) clk_out <= ~clk_out;
	counter <= counter + 1;
    end
endmodule


module board (
    input wire CLOCK_50,
    input wire KEY0,
    output wire [7:0] LEDG
    );
    
    wire clk_1hz;
    clock_divider clk_inst (
	.clk_in(CLOCK_50),
	.clk_out(clk_1hz)
    );

    //
    wire [31:0] i_mem_data_in;
    wire [63:0] i_mem_addr;

    wire [63:0] mem_addr, mem_data_in, mem_data_out;
    wire mem_we;
    wire [31:0] ir_show;

    cpu cpu_inst (
	.clock(clk_1hz),
	.reset_n(KEY0),
	//
        .i_mem_addr(i_mem_addr),
        .i_mem_data_in(i_mem_data_in),
	//
	.ir_out(ir_show),
	.mem_addr(mem_addr),
	.mem_data_in(mem_data_in),
	.mem_data_out(mem_data_out),
        .mem_we(mem_we)
    );

    (* ram_style = "block" *) reg [63:0] mem [0:2999]; // Unified Memory
    initial $readmemh("mem.mif", mem);

    //always @(posedge clk_1hz) begin
    //    if (mem_we) mem[mem_addr] <= mem_data_out;
    //    mem_data_in <= mem[mem_addr];
    //    i_mem_data_in <= mem[mem_addr];
    //end

    assign i_mem_data_in = mem[i_mem_addr >> 2];

    // LED display
    assign LEDG = ir_show[7:0];

    //reg [1:0] mux_cnt;
    //always @(posedge clk_1hz)begin
    //    mux_cnt <= mux_cnt + 1;
    //    case (mux_cnt)
    //        0: LEDG <= mem_data_in[7:0];
    //        1: LEDG <= mem_data_in[15:8];
    //        2: LEDG <= mem_data_in[23:16];
    //        3: LEDG <= mem_data_in[31:24];
    //    endcase
    //end
endmodule

//psf
//set_location_assignment PIN_L1 -to CLOCK_50
//set_location_assignment PIN_R22 -to KEY0
//set_location_assignment PIN_U22 -to LEDG[0]
//set_location_assignment PIN_U21 -to LEDG[1]
//set_location_assignment PIN_V22 -to LEDG[2]
//set_location_assignment PIN_V21 -to LEDG[3]
//set_location_assignment PIN_W22 -to LEDG[4]
//set_location_assignment PIN_W21 -to LEDG[5]
//set_location_assignment PIN_Y22 -to LEDG[6]
//set_location_assignment PIN_Y21 -to LEDG[7]

