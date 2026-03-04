module buffin
(
	input [7:0] data,
	input wre,read,clk,clr,back,forw,
	output  reg  [7:0] q,out,
	output  reg [6:0] count,
	output full,empt,endf
);

	//parameter DATA_WIDTH = 8;
	//parameter ADDR_WIDTH = 7;
		
	reg [7:0] ram[127:0];
	reg [15:0] fini;

	reg [6:0] ptr,ptri,ptro,befw;
	reg ful,emp,flgw,flge,fg,fll;
	
	assign full=ful;
	assign empt=emp;
	assign endf=fg;
	
	always @ (posedge clk,negedge clr)
	if (!clr) 
	begin
		emp<= 1;
		ful<= 0;
	end
	else
	begin 
		if (count==0)emp<=1;
		else emp<=0;
		if (count==127)ful<=1;
		else ful<=0;
		
	end

	
	always @ (posedge clk ,negedge clr)
	begin
	if (!clr)
	begin
		count<=0;
		ptr<=0;
		ptri<=0;
		ptro<=0;
		flgw<=0;
		flge<=0;
		fini<=0;
		fg <= 0;
		fll<=0;
	end
	else
	begin
		if (back) 
			if (ptr>0)
				begin 
					ptr<=ptr-1; 
					q<=ram[ptr-1];
					fll<=1;
				end
		if (forw) 
			if (ptr<126)
				begin 
					ptr<=ptr+1;
					q<=ram[ptr+1];
					fll<=1;
				end

		// Ïò´æ´¢Æ÷Ð´Êý¾Ý£º
		if (wre)
		begin
			if (fll) 
				begin 
					ram[ptr] <= data;
					fll<=0;
					befw<=ptr;
					flgw<=1;
				end
			else
			begin
				befw<=ptri;
				flgw<=1;
				if (count<127 && count>=0)
				begin
					ram[ptri] <= data;
					count<=count+1;
					ptri<=ptri+1;
				end
				else if (count==127) 
					begin 
						ram[ptri] <= data;
					end
	//			q<=data;
			 end				
		end
		else
		begin
			if (read)
				
				if (count>0 && count<=127)
					begin
						ptro<=ptro+1;
						count<=count-1;
						out<=ram[ptro];
						flge<=flge+1;
						fini<={fini[7:0],ram[ptro]};
						if (flge && fini[7:0]==8'h00 && ram[ptro]==8'h80) fg<=1;
						else fg<=0;
					end
				
		
			if (flgw) begin q<=ram[befw]; flgw<=0; end //last write show
		end			
	end		
	end			
	
	
endmodule
