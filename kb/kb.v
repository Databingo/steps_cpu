module kb (

input in,   
input clk,
output reg out,
);

reg [22:0] count;
	always @(posedge(clk))
		begin
			if(in==1)
				begin
					if (count == 0)
						begin 
							out <= ~out;
						end
						count <= count + 1;
				end 
				else 
					begin 
						out <= 0;
						count <= 1;
					end
				end	
endmodule

// -----Blink ok-----
// Device: EP2C20F484C7
// Handbook:
// Cyclone II FPGA Starter Board
// Pin map:
// in : SW0-PIN_R20
// out: LEDR0-PIN_L22
// clk: CLK-PIN_L1 
