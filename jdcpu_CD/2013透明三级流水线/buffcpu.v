module buffcpu (
				data,		//输入数据
				wre,		//写使能
				back,		//向回浏览
				forw,		//往前浏览
				clk,		//时钟
				clr,		//复位
				brak,		//中断
				oh,			//输出高字节
				ol,			//输出低字节
				qb,			//输出数据
				count,		//缓冲区计数
				oread,
				oendf,
				rea,
				oda
				);
input wre,back,forw,clk,clr,brak;
input [7:0] data;
output [7:0] oh,ol;
output [7:0] qb,oread;
output [6:0] count;
output oendf,rea;
output [15:0] oda;
wire w3,w4,w5;		//中间变量
wire [7:0] w6;
wire [7:0] w2;
assign qb=w2; 
assign oread=w6;
assign oendf=w5;
assign rea=w3;
				
	//调用CPU：			
	sjls_cpum cpum(.clock(clk),.clr_n(clr),.brak(brak),.read(w3),.oda(oda),
		.empty(w4),.orup(irup),.endf(w5),.idata(w6),.odata({oh,ol}));
//调用缓冲区：
	buffin buff0(.data(data),.wre(wre),.back(back),.clk(clk),.clr(clr),
		.read(w3),.forw(forw),.empt(w4),.endf(w5),.q(w2),.count(count),
		.out(w6));
endmodule 
