module buffint
(
	input [7:0] data,
	input wre,read,clk,clr,
	output  reg  [7:0] q,out,
	output  [6:0] count,opro,
	output full,empt,endf
);
	reg [7:0] ram [127:0];

	reg [6:0] cou;	
	reg [6:0] ptri,ptro,pj;
	reg ful,emp,flg;
	reg bzhi,biaozhi;
	
	assign full=ful;
	assign empt=emp;
	assign count=cou;
	assign endf=flg;
	assign opro=ptro;
	
	always @ (posedge clk,negedge clr)
	if (!clr) 
	begin
		emp<= 1;
		ful<= 0;
	end
	else
	begin
	    if (cou==127) ful<=1; else ful<=0;
		if (cou==0)   emp<=1; else emp<=0;
	end
		
	always @ (posedge clk ,negedge clr)
	begin
	if (!clr)
	begin
		cou<=0;
		ptri<=0;
		ptro<=0;
		flg<=0;
		pj<=0;
		biaozhi<=0;
	end
	else
	begin
		// Ïò´æ´¢Æ÷Ð´Êý¾Ý£º
		if (wre)
		begin
			if (!ful)
			begin
				ram[ptri] <= data;
				cou<=cou+1;
				ptri<=ptri+1;
				pj<=ptri;	//the write location
				biaozhi<=1;	//write flag
			end				
		end
		else
		begin
			if (read)
				begin
				if (!emp)
					begin
						ptro<=ptro+1;
						cou<=cou-1;
						out<=ram[ptro];
						if (ram[ptro]==8'b10000000)
						flg<=1;
					end
				end
			else
			   if (biaozhi) 
				begin
					q <= ram[pj];	//display the write data
					biaozhi<=0;
				end
		end			
	end		
	end			
	
	
endmodule
