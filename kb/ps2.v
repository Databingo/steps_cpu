module ps2(clk, ps2_clk, ps2_data,code);

input clk, ps2_clk, ps2_data;
output reg [7:0] code;
reg [10:0] buffer;
reg [3:0] count;
reg last_clk;

always @(posedge clk) begin
    last_clk <= ps2_clk;
    if (last_clk && !ps2_clk)begin
	buffer <= {ps2_data, buffer[10:1]};
	count <= count + 1;
	if (count == 10) begin
	    if (!buffer[0] && buffer[10] && (^buffer[9:1])) // start 0; stop 1; odd parity
		code <= buffer[8:1];
	    count <= 0;
	end
    end
end
endmodule


