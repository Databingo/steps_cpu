module jcq
	(
		input [15:0] data,
		input clock,con_in,con_out,clr_n,
		output [15:0] q
	);
	reg [15:0] qq;
	assign q =(con_out) ? qq : 16'hzzzz;
	always @(posedge clock , negedge clr_n)
	begin
		if (!clr_n)
			qq<=16'h0000;
		else
			if (con_in) qq<=data;
	end


endmodule
