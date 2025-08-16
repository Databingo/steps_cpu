module cpu_on_board (
    (* chip_pin = "PIN_L1" *)  input wire CLOCK_50, // 50 MHz clock
    (* chip_pin = "PIN_R22" *) input wire KEY0,     // Active-low reset button
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *) 
    output wire [7:0] LEDG, // 8 green LEDs
    (* chip_pin = "R20" *) output reg LEDR0, // 2 red LEDs  
    (* chip_pin = "R17" *) output reg LEDR9 // 2 red LEDs  
    //(* chip_pin = "PIN_U22, PIN_U21, PIN_V22, PIN_V21, PIN_W22, PIN_W21, PIN_Y22, PIN_Y21" *) 
    //(* chip_pin = "PIN_R17, PIN_R18, PIN_U18, PIN_Y18, PIN_V19, PIN_T18, PIN_Y19, PIN_U19, PIN_R19, PIN_R20" *) output reg [9:0] LEDR // 10 red LEDs  
    //(* chip_pin = "R17, R18, U18, Y18, V19, T18, Y19, U19, R19, R20" *) output reg [9:0] LEDR // 10 red LEDs  
);

    (* ram_style = "block" *) reg [7:0] mem [0:2999]; // Unified Memory
    initial $readmemb("mem.mif", mem);

    reg [24:0] counter;
    reg [31:0] addr_pc;
    //
    reg [31:0] ir;
    reg [31:0] pc;
//    reg [63:0] re [0:31]; // General-purpose registers (x0-x31)

    wire clock_1hz;
    clock_slower clock_ins(
	.clk_in(CLOCK_50),
	.clk_out(clock_1hz),
	.reset_n(KEY0)
    );

    // --- Immediate decoders --- 
//    wire signed [63:0] w_imm_i = {{52{ir[31]}}, ir[31:20]};   // I-type immediate Lb Lh Lw Lbu Lhu Lwu Ld Jalr Addi Slti Sltiu Xori Ori Andi Addiw
//    wire signed [63:0] w_imm_s = {{52{ir[31]}}, ir[31:25], ir[11:7]};  // S-type immediate Sb Sh Sw Sd
//    wire signed [63:0] w_imm_b = {{51{ir[31]}}, ir[7],  ir[30:25], ir[11:8], 1'b0}; // SB-type immediate Beq Bne Blt Bge Bltu Bgeu // read immediate & padding last 0, total 12 + 1 = 13 bits
//    wire signed [63:0] w_imm_u = {{32{ir[31]}}, ir[31:12], 12'b0}; // U-type immediate Lui Auipc
//    wire signed [63:0] w_imm_j = {{43{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0}; // UJ-type immediate Jal  // read immediate & padding last 0, total 20 + 1 = 21 bits
//
//    // --- Instruction Decoding ---
//    wire [ 6:0] w_op = ir[6:0];
//    wire [ 4:0] w_rd = ir[11:7];
//    wire [ 2:0] w_f3 = ir[14:12]; 
//    wire [ 4:0] w_rs1 = ir[19:15];
//    wire [ 4:0] w_rs2 = ir[24:20];
//    wire [ 6:0] w_f7 = ir[31:25];
//    wire [ 5:0] w_shamt = ir[25:20]; // If 6 bits the highest is always 0??
//    wire [11:0] w_csr = ir[31:20];   // CSR address
//    wire [11:0] w_f12 = ir[31:20];   // ecall 0, ebreak 1
//    wire [ 4:0] w_zimm = ir[19:15];  // CSR zimm

    // IF ir
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin
	    //LEDG <= 8'h00;
	    LEDR0 <= 1'b0;
	    addr_pc <= 3;
       
	    //
	    ir <= 32'h00000000;
        end
        else begin
	        LEDR0 <= ~LEDR0; // heartbeat
	        //LEDG <= mem[addr_pc];//[7:0];
		addr_pc <= addr_pc + 4;
		  
		//
		//ir <= {mem[pc+3], mem[pc+2], mem[pc+1], mem[pc]};
		ir[7:0]<= mem[pc];

        end
    end

    // EXE pc
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin
	    pc <=0;
	end
	else begin
	    pc <= pc + 4;
	    //LEDG <= ir;
    	    //casez(ir) 
	    //// U-type
            ////32'b???????_?????_?????_???_?????_0110111: re[w_rd] <= w_imm_u; // Lui
            //32'b???????_?????_?????_???_?????_0110111: LEDR9 <= 1'b1;
	    //endcase
	end
    end

   assign LEDG = ir[7:0];



    // Memory controller 
    //always @(posedge clock_1hz or negedge KEY0) begin
    //end

endmodule





module clock_slower(
    input wire clk_in,
    input wire reset_n,
    output reg clk_out
    );

    reg [24:0] counter; 

    initial begin
	clk_out <= 0;
	counter <=0;
    end

    always @(posedge clk_in or negedge reset_n) begin
	if (!reset_n) begin
	    clk_out <= 0;
	    counter <=0;
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



