module cpu_on_board (
    (* chip_pin = "PIN_L1" *)  input wire CLOCK_50, // 50 MHz clock
    (* chip_pin = "PIN_R22" *) input wire KEY0,     // Active-low reset button
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *) output wire [7:0] LEDG, // 8 green LEDs
    (* chip_pin = "R17" *) output reg LEDR9 // red LEDs breath left most 
    //(* chip_pin = "R20" *) output reg LEDR0, // red LEDs  
    (* chip_pin = "U18, Y18, V19, T18, Y19, U19, R19, R20" *) output wire [7:0] LEDR7_0 // 8 red LEDs right
    //(* chip_pin = "R17, R18, U18, Y18, V19, T18, Y19, U19, R19, R20" *) output reg [9:0] LEDR // 10 red LEDs  
);

    (* ram_style = "block" *) reg [31:0] mem [0:2999]; // Unified Memory
    initial $readmemb("mem.mif", mem);

    reg [24:0] counter;
    reg [31:0] addr_pc;
    //
    reg [31:0] ir;
    wire [31:0] ir_bd; assign ir_bd = mem[pc>>2];
    wire [31:0] ir_ld; assign ir_ld = {ir_bd[7:0], ir_bd[15:8], ir_bd[23:16], ir_bd[31:24]};

    reg [31:0] pc;
    reg [63:0] re [0:31]; // General-purpose registers (x0-x31)

    wire clock_1hz;
    clock_slower clock_ins(
	.clk_in(CLOCK_50),
	.clk_out(clock_1hz),
	.reset_n(KEY0)
    );

    // IF ir (only fetch)
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin 
	    LEDR9 <= 1'b0; 
	    ir <= 32'h00000000; 
	end
        else begin
	    LEDR9 <= ~LEDR9; // heartbeat
	    ir <= ir_ld;
        end
    end

    // EXE pc (only one always driver a net)
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin 
	    pc <=0;
	end
	else begin
	    pc <= pc + 4;
            re[0] <= 1'b0;
    	    casez(ir) 
	    // U-type
            //32'b???????_?????_?????_???_?????_0110111: re[w_rd] <= w_imm_u; // Lui
            //32'b???????_?????_?????_???_?????_0000111: LEDR9 <= 1'b1;
            //32'b???????_?????_?????_???_?????_0110111:  LEDR9 <= 1'b1;
            32'b???????_?????_?????_???_?????_0110111:  re[0] <= 1'b1;
	    endcase
	end
    end

   assign LEDG = ir[7:0];
   assign LEDR7_0 = re[0][7:0];



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



