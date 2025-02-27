module clk18 (
input clk_27m,
output reg clk9m
);//9m*3=27m

reg [1:0] half=0;
always @(posedge clk_27m)
 if (half==2)
	begin 
		half=0; 
		clk9m=~clk9m;
	end
 else half<=half+1;
endmodule
