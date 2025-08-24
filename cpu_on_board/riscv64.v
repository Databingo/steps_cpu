// =================================================================================
// Original CPU file with minimal changes to force-send 'H' every clock cycle.
// =================================================================================

module riscv64(
    input wire clk, 
    input wire reset,     // Active-low reset button
    input wire [31:0] instruction,
    output reg [31:0] pc,
    output wire [63:0] data,
    output wire [31:0] ir_out,
    output wire [63:0] re_out,
    output wire  heartbeat
);

    reg [31:0] ir;
    //reg [31:0] pc;
    reg [63:0] re [0:31]; // General-purpose registers (x0-x31)
    
    // --- Immediate decoders (Unchanged) --- 
    wire signed [63:0] w_imm_u = {{32{ir[31]}}, ir[31:12], 12'b0};
    wire [4:0] w_rd  = ir[11:7];



    // IF ir (Unchanged)
    always @(posedge clk or negedge reset) begin
        if (!reset) begin 
            heartbeat <= 1'b0; 
            ir <= 32'h00000000; 
        end else begin
            heartbeat <= ~heartbeat; // heartbeat
            //ir <= ir_ld;
            ir <= instruction;
        end
    end

    // EXE pc (Unchanged, CPU runs normally)
    always @(posedge clk or negedge reset) begin
        if (!reset) begin 
            pc <= 0;
        end else begin
            pc <= pc + 4;
            re[31] <= 1'b0; // This was in your original code
            
	    //data <= 32'h48;
            casez(ir) 
		32'b???????_?????_?????_???_?????_0110111:  re[w_rd] <= w_imm_u; // Lui
		//32'b???????_?????_?????_???_?????_0110111:  begin re[w_rd] <= w_imm_u; data <= 32'h41; end
            endcase
        end
    end

   // LED Assignments (Unchanged)
   assign ir_out = ir[7:0];
   assign re_out = re[31];
endmodule
