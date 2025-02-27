module buffcpu (
				data,		//��������
				wre,		//дʹ��
				back,		//������
				forw,		//��ǰ���
				clk,		//ʱ��
				clr,		//��λ
				brak,		//�ж�
				oh,			//������ֽ�
				ol,			//������ֽ�
				qb,			//�������
				count,		//����������
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
wire w3,w4,w5;		//�м����
wire [7:0] w6;
wire [7:0] w2;
assign qb=w2; 
assign oread=w6;
assign oendf=w5;
assign rea=w3;
				
	//����CPU��			
	sjls_cpum cpum(.clock(clk),.clr_n(clr),.brak(brak),.read(w3),.oda(oda),
		.empty(w4),.orup(irup),.endf(w5),.idata(w6),.odata({oh,ol}));
//���û�������
	buffin buff0(.data(data),.wre(wre),.back(back),.clk(clk),.clr(clr),
		.read(w3),.forw(forw),.empt(w4),.endf(w5),.q(w2),.count(count),
		.out(w6));
endmodule 
