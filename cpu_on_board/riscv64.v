module riscv64(
    input wire clk, 
    input wire reset,     // Active-low reset button
    input wire [31:0] instruction,
    output reg [31:0] pc,
    output reg [31:0] ir,
    output reg [63:0] re [0:31],
    output wire  heartbeat,

    input wire [3:0] interrupt_vector,
    output reg interrupt_done,

    output reg [63:0] bus_address,
    output reg [63:0] bus_write_data,
    output reg        bus_write_enable,
    output wire        bus_read_enable,
    input  wire [63:0] bus_read_data


);

    // -- Interrupter --
    always @(posedge clk or negedge reset) begin
	if (!reset) begin
	    bus_read_enable <= 0;
	    bus_write_enable <= 0;
	    interrupt_done <= 0;
	end else begin
	    bus_read_enable <= 0;
	    bus_write_enable <= 0;
	    interrupt_done <= 0;
	    // different interrupte vector
	    if (interrupt_vector == 1) begin
	        bus_address <= 32'h8000_0010; // Key_base ;
	        bus_read_enable <= 1;
	        if (bus_read_enable) begin
                    //keyboard_data_reg <= bus_read_data;
	            bus_address <= 32'h8000_0000; // Art_base ;
	            bus_write_data <= bus_read_data;
	            bus_write_enable <= 1;
		    interrupt_done <=1;
	         end
	    end
	end
    end
    
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

endmodule
