module cpu_on_board (
    (* chip_pin = "PIN_L1" *)  input wire CLOCK_50, // 50 MHz clock
    (* chip_pin = "PIN_R22" *) input wire KEY0,     // Active-low reset button
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *) 
    output wire [7:0] LEDG, // 8 green LEDs
    (* chip_pin = "R20" *) output reg LEDR0 // 2 red LEDs  
    //(* chip_pin = "PIN_U22, PIN_U21, PIN_V22, PIN_V21, PIN_W22, PIN_W21, PIN_Y22, PIN_Y21" *) 
    //(* chip_pin = "PIN_R17, PIN_R18, PIN_U18, PIN_Y18, PIN_V19, PIN_T18, PIN_Y19, PIN_U19, PIN_R19, PIN_R20" *) output reg [9:0] LEDR // 10 red LEDs  
    //(* chip_pin = "R17, R18, U18, Y18, V19, T18, Y19, U19, R19, R20" *) output reg [9:0] LEDR // 10 red LEDs  
);

    (* ram_style = "block" *) reg [7:0] mem [0:2999]; // Unified Memory
    initial $readmemb("mem.mif", mem);

    reg [24:0] counter;
    reg [31:0] addr_pc;
    reg [7:0] ir;
    reg [31:0] pc;

    wire clock_1hz;
    clock_slower clock_ins(
	.clk_in(CLOCK_50),
	.clk_out(clock_1hz),
	.reset_n(KEY0)
    );

    // IF ir
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin
	    //LEDG <= 8'h00;
	    LEDR0 <= 1'b0;
	    addr_pc <= 3;
       
	    //
	    ir <= 8'b00000000;
        end
        else begin
	        LEDR0 <= ~LEDR0; // heartbeat
	        //LEDG <= mem[addr_pc];//[7:0];
		addr_pc <= addr_pc + 4;
		  
		//
		ir <= mem[pc];

        end
    end

    // EXE pc
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin
	    pc <=3;
	end
	else begin
	    pc <= pc + 4;
	    //LEDG <= ir;
	end
    end

   assign LEDG = ir[7:0];
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



