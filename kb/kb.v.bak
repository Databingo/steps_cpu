module key_board (in,out,clk);

input in,clk;
output reg out;
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
