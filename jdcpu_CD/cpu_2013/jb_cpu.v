//�򵥼��������� 2009-4-29  ����Ȩ��ӽ�� Email:accsys@126.com
//�ο���:��ӽ��.PMC����������Ӧ��.�廪��ѧ������.2008-5
//˵������������ļ򵥼��������ƣ��ǳ�ѧ�������Ƶ����ʵ����

//��������ʱ��clock
//��λ���ƣ�reset_n,�͵�λ��Ч
//���������o
//����洢��iram,16λ����5λ����ָ�����,��imem16_1.mif��ʼ��
//���ݴ洢��dram,16λ�����������ļ���ʼ��
//��lpm�洢����ַ�����ź�Ҫ�ȶ�1�ģ��ſ��Զ�д����

//ָ���ʽ:��5λָ�����,11λ��ַ��,16λ������(�ָߵ�8λ)

module jb_cpu
	(
		clock,
		reset_n,
		empty,
		data,
		read,
		brak,
		reset,
		endf,
		o,
		//�������(���Բ�Ҫ)��
		opc,
/*			ojp,
		olda,
		oadd,
		oout,
		osdal,
		osdah,
		ostr,
		osub,
		ojmp,
		ojz,
		ojn,
		ocall,
		oret,
		ozf,osp,*/
		oqw,
		oir, 
		oda,
		orup
	);

	input	clock;
	input	reset_n;
	input	brak;
	input	reset;
	input	empty;
	input [7:0]	data;
	input  endf;
	output read;
	output [15:0]	o;
	
	output [15:0]	oqw,oda,oir;
	output [10:0]	opc;
	output 	orup;
	/*,osp;
	output [2:0]	ojp;
	output			oiro,lda,oadd,oout,osdal,osdah,ostr,osub,ojmp,ojz,ojn,ocall,oret,ozf;*/
	
	reg 		iwren,dwren,swren,over,rea,rup;
	wire [15:0] q_w,q_data,q_s;
    reg  [15:0] ir,x;
	reg	 [15:0]	b,a,da,oo,idata,ddata;
	reg  [10:0]	pc,pc_back,mar,sp,ptr;
	reg  [2:0]	jp;		//����
//ָ��:
	reg 		lda,	//ȡ��:�����ݵ�Ԫȡ����da
				add,	//��:da�����ݵ�Ԫ��ӣ��������da
				out,	//���:�����ݵ�Ԫ�������������Ĵ���
				sdal,	//��8λ������:��8λ����������Ϊ16λ��da
				sdah,	//��8λ������:��8λ��������Ϊ��8λ����ԭda��8λ���ӳ�16λ����da��
				str,	//da�����ݴ洢��Ԫ:
				sub,	//��:da�����ݵ�Ԫ������������da
				jmp,	//��ת
				jz,		//daΪ0��ת
				jn,		//daΪ����ת
				call,	//�����ӳ���
				ret,	//����
				iptr,	//da->[ptr]
				inl,		//->da
				inc,	//
				dec,	//
				datp,	//
				jk,		//
				jend,	//
				inh,
				ting,
				mult,
				divi,
				stp;	//ֹͣ
//�����ź����:
	assign o    = oo;
	assign read    = rea;
	assign oqw	= q_w;
	assign opc  = pc;
	assign orup  =rup;
/*	assign osp  = sp;
	assign ojp	= jp;
	assign olda=lda;
	assign oadd=add;
	assign osub=sub;
	assign oout=out;
	assign ojmp=jmp;
	assign ostr=str;
	assign osdal=sdal;
	assign osdah=sdah;
	assign ocall=call;
	assign oret=ret;
	assign ojz=jz;
	assign ojn=jn;
	assign ozf=~|da; */
	assign oir=ir;
	assign oda=da;
	
//ָ��洢��:	 
	lpm_ram_dq iram(.data(idata),.address(pc),.we(iwren),.inclock(clock),.q(q_w));  //����洢��
	defparam iram.lpm_width = 16;
	defparam iram.lpm_widthad = 11;
	defparam iram.lpm_outdata = "UNREGISTERED";
	defparam iram.lpm_indata = "REGISTERED";
	defparam iram.lpm_address_control = "REGISTERED";
	defparam iram.lpm_file = "imem16_2.mif";  //��ʼ���ļ�,���ó���
//���ݴ洢��:	
	lpm_ram_dq dram(.data(ddata),.address(mar),.we(dwren),.inclock(clock),.q(q_data)); //���ݴ洢��
	defparam dram.lpm_width = 16;
	defparam dram.lpm_widthad = 11;
	defparam dram.lpm_outdata = "UNREGISTERED";
	defparam dram.lpm_indata = "REGISTERED";
	defparam dram.lpm_address_control = "REGISTERED";
	
	lpm_ram_dq sram(.data(pc_back),.address(sp),.we(swren),.inclock(clock),.q(q_s)); //��ջ
	defparam sram.lpm_width = 11;
	defparam sram.lpm_widthad = 10;
	defparam sram.lpm_outdata = "UNREGISTERED";
	defparam sram.lpm_indata = "REGISTERED";
	defparam sram.lpm_address_control = "REGISTERED";

	
		always @(posedge clock or negedge reset_n)
begin
	if (!reset_n)
	begin
		pc 	 	<= 0;
		ptr	 	<= 0;
		sp		<= 0;
		lda 	<= 0;   
		add 	<= 0;   
		out 	<= 0;	
		sdal 	<= 0;	
		sdah 	<= 0;	
		str 	<= 0;
		sub		<= 0;
		jmp 	<= 0;
		jz 		<= 0;
		jn 		<= 0;
		call 	<= 0;
		ret 	<= 0;
		iptr<= 0;	//
		inl<= 0;	//
		inc<= 0;	//
		dec<= 0;	//
		datp<= 0;	//
		jk<= 0;		//
		jend<= 0;	//
		inh<= 0;	//
		ting<=0;	//
		mult<=0;	//
		divi<=0;	//
		jp<= 0;
		over<=0;
		rup<=0;
	end
	else
	begin
		
//	����jpָ����״̬�� 
		case (jp)
		0:	begin
				if (brak) jp<=0;
				else if (reset) jp<=1; 
			end			
		1:	begin
				ir<=q_w;
				case (q_w[15:11])
				5'b00001:	lda 	<= 1;	//lda:00001
				5'b00010:	add 	<= 1;	//add:00010
				5'b00011:   out 	<= 1;	//out:00011
				5'b00100:   sdal	<= 1;	//��8λ�������з���16λ
				5'b00101:   sdah 	<= 1;	//��8λ����ǰ���8λ����ϳ�16λ
				5'b00110:   str 	<= 1;	//da�����ݵ�Ԫ
				5'b00111:   sub 	<= 1;	
				5'b01000:   jmp 	<= 1;
				5'b01001:   if (da==0) jz 		<= 1;
				5'b01010:   if (da<0)  jn 		<= 1;
				5'b01011:   begin pc_back <= pc+1; call <= 1; end
				5'b01100:   ret 	<= 1;
				5'b01101: begin
							pc_back <= pc+1;
							pc<=ptr;
							idata<=da;
							iptr<= 1;
						end //da->ptr:iram
				5'b01110:   begin rea<=1;  inl<= 1;	end	//
				5'b01111:   inc<= 1;	//
				5'b10001:   datp<= 1;	//
				5'b10010:   if (empty) jk<= 1;		//
				5'b10011:   if (endf) jend<= 1;		//
				5'b10100:   begin rea<=1; inh<= 1; end		//
				5'b10101:   if (empty) ting<=1;		//
				5'b10110:   dec<= 1;	//
				5'b10111:   mult<= 1;	//
				5'b11000:   divi<= 1;	//
				5'b11111:   begin jp <=0; stp 	<= 1; end
				default:    jp <= 0;
				endcase
				jp <= 2;
			end   /**/
		2:	begin
				case (ir[15:11])
				5'b00001:	begin  //lda 	<= 1;	
								mar<=ir[10:0];
								jp <= 3;
							end
				5'b00010:	begin  //add 	<= 1;	
								mar<=ir[10:0];
								jp <= 3;
							end
				5'b00011:   begin  //out 	<= 1;
								mar<=ir[10:0];
								jp <= 3;
							end
					
				5'b00100:   begin  //sdal	<= 1;
								da <= {{8{ir[7]}},ir[7:0]};        //����16λ�з�����
								sdal<= 0;
								pc <= pc+1;
								jp<= 0;
							end
					
				5'b00101:   begin  //sdah 	<= 1;
								da[15:0] <= {ir[7:0],da[7:0]};
								sdah <= 0;
								pc <= pc+1;
								jp<= 0;
							end 
					
				5'b00110:   begin  //str 	<= 1;
								mar<=ir[10:0];
								ddata <= da;
								jp <= 3;
							end
				5'b00111:   begin  //sub 	<= 1;	
								mar<=ir[10:0];
								jp <= 3;
							end
				
				5'b01000:   begin  //jmp 	<= 1;
								pc <= ir[10:0];
								jmp <=0;
								jp <= 0;
							end
				5'b01001:   begin  //jz 		<= 1;
								if (jz) pc <= ir[10:0];
								else 		pc <= pc+1;
								jz <=0;
								jp <= 0;
							end
				
				5'b01010:   begin  //jn 		<= 1;
								if (jn) pc <= ir[10:0];
								else 		pc <= pc+1;
								jn<=0;
								jp <= 0;
							end
				5'b01011:   begin  //call 	<= 1;
									jp <= 3;
							end

				5'b01100:   begin  //ret 	<= 1;
									jp <= 3;
							end
				5'b01101:   begin  //iptr 	<= 1;
									jp <= 3;
							end
				5'b01110:   begin  //inl 	<= 1;
									rea<=0;
									jp <= 3;
							end
				5'b01111:   begin  //inc 		<= 1;
								ptr <= ptr+1;
								pc <= pc+1;
								inc<=0;
								jp <= 0;
							end
				5'b10001:   begin  //datp 		<= 1;
								ptr <= da;
								pc <= pc+1;
								datp<=0;
								jp <= 0;
							end
				5'b10010:   begin  //jk 		<= 1;
								if (jk) pc <= ir[10:0];
								else 		pc <= pc+1;
								jk<=0;
								jp <= 0;
							end
				5'b10011:   begin  //jend 		<= 1;
								if (endf) pc <= ir[10:0];
								else 		pc <= pc+1;
								jend<=0;
								jp <= 0;
							end
				5'b10100:   begin  //inh 	<= 1;
									rea<=0;
									jp <= 3;
							end
				5'b10101:   begin  //ting 	<= 1;
								if (ting) 
								begin
									rup<=1;
									jp<=3;
								end
								else 
								begin
									pc <= pc+1;
									ting <= 0;
									jp <= 0;
								end
							end
				5'b10110:   begin  //dec 		<= 1;
								ptr <= ptr-1;
								pc <= pc+1;
								dec<=0;
								jp <= 0;
							end
				5'b10111:	begin  //mult 	<= 1;	
								mar<=ir[10:0];
								jp <= 3;
							end
				5'b11000:	begin  //divi 	<= 1;	
								mar<=ir[10:0];
								jp <= 3;
							end
				5'b11111:	jp<=0;
				default:    jp <= 0;
				endcase
			end 
		3:	begin 
				case (ir[15:11])
				5'b00001:	begin  //lda 	<= 1;	
								jp <= 4;
							end
				5'b00010:	begin  //add 	<= 1;	
								jp <= 4;
							end
				5'b00011:   begin  //out 	<= 1;
								jp <= 4;
							end
					
				5'b00110:   begin  //str 	<= 1;
								dwren <= 1;
								jp <= 4;     
							end
				5'b00111:   begin  //sub 	<= 1;	
								jp <= 4;
							end
				
				5'b01011:   begin  //call 	<= 1;
									swren <= 1;
									jp <= 4;
							end

				5'b01100:   begin  //ret 	<= 1;
									sp <= sp-1;
									jp <= 4;
							end
				5'b01101:   begin  //iptr 	<= 1;
									iwren<=1;
									jp <= 4;
							end
				5'b01110:   begin  //inl 	<= 1;
									
									da[7:0]<=data;
									pc <= pc+1;
									inl<=0;
									jp <= 0;
							end
				5'b10100:   begin  //inh 	<= 1;
								da[15:8]<=data;
								pc <= pc+1;
								inh<=0;
								jp <= 0;
							end
				5'b10101:   begin  //ting 	<= 1;
								rup<=0;
								ting<=0;
								jp <= 0;
							end
				5'b10111:	begin  //mult 	<= 1;	
								jp <= 4;
							end
				5'b11000:	begin  //divi 	<= 1;	
								jp <= 4;
							end
				default:    jp <= 0;
				endcase
			end
			
		4:	begin
				case (ir[15:11])
				5'b00001:	begin  //lda 	<= 1;	
								da<=q_data;
								pc <= pc+1;
								jp <= 0;
								lda<= 0;
							end
				5'b00010:	begin  //add 	<= 1;	
								b<=q_data;
								a<=da;
								jp <= 5;
							end
				5'b00011:   begin  //out 	<= 1;
								oo <= q_data;
								pc <= pc+1;
								jp <= 0;
								out<= 0;
							end
					
				5'b00110:   begin  //str 	<= 1;
								jp <= 5;     
							end
				5'b00111:   begin  //sub 	<= 1;	
								b<=q_data;
								a<=da;
								jp <= 5;
							end
				
				5'b01011:   begin  //call 	<= 1;
									swren<=0;
									sp <= sp+1;
									jp <= 5;
							end

				5'b01100:   begin  //ret 	<= 1;
									jp <= 5;
							end
				5'b01101:   begin  //iptr 	<= 1;
									iwren <=0;
									pc<=pc_back;
									iptr<=0;
									jp <= 0;
							end
				5'b10111:	begin  //mult 	<= 1;	
								b<=q_data;
								a<=da;
								jp <= 5;
							end
				5'b11000:	begin  //divi 	<= 1;	
								b<=q_data;
								a<=da;
								jp <= 5;
							end
				default:    jp <= 0;
				endcase
			end
			5:	begin
				case (ir[15:11])
				5'b00010:	begin  //add 	<= 1;	
								da<=a+b;
								pc <= pc+1;
								add <=0;
								jp <= 0;
							end
				5'b00011:   begin  //out 	<= 1;
								oo <= q_data;
								pc <= pc+1;
								jp <= 0;
								out<= 0;
							end
					
				5'b00110:   begin  //str 	<= 1;
								dwren <= 0;
								pc <= pc+1;
								str <=0;
								jp <= 0;     
							end
				5'b00111:   begin  //sub 	<= 1;	
								da<=a-b;
								pc <= pc+1;
								sub<=0;
								jp <= 0;
							end
				5'b01011:   begin  //call 	<= 1;
									pc<=ir[10:0];
									call<=0;
									jp<=0;
							end

				5'b01100:   begin  //ret 	<= 1;
									pc <= q_s;
									ret<=0;
									jp <= 0;
							end
				5'b10111:	begin  //mult 	<= 1;	
								da<=a*b;
								pc <= pc+1;
								mult <=0;
								jp <= 0;
							end
				5'b11000:	begin  //divi 	<= 1;	
								da<=a/b;
								pc <= pc+1;
								divi <=0;
								jp <= 0;
							end
				default:    jp <= 0;
				endcase
				end			
			

		endcase
	end 
end

		endmodule
 
//////  ����ʵ��: ��64*8�����ѭ������ ////////
//
//			���			����   		
//a0:		sdal 1			2001		
//			str	one			3001
//			sub	one			3801
//			str	result		3002
//			str	n			3005
//			sdal 64			2040
//			str	x			3003
//			sdal 8			2008
//			str	y			3004
//loop:		lda	y			0804
//			jz	exit			48b2
//			sub	one			3801
//			str	y			3004
//			lda	result		0802	
//			add	x			1003
//			str	result		3002
//			call loopno			58b4
//			jmp	loop			40a9
//exit:		out	result		1802
//			stp				ffff
//loopno:	lda	n			0805
//			add one			1001
//			str n			3005
//			out n			1805
//			sdal 126		207f
//			str  k			3006
//time:		lda	k			0806
//			jz	timeend			48bf
//			sub	one			3801
//			str	k			3006
//			jmp time			40ba
//timeend:	ret				6000
//					
//		�������16������д��imem16_1.mif 	
//		 						 
///////  16���ƽ�����:0200  //////////////////
//
/////// ������ص�����������������������֮��Ҫ����ʱ�ӳ���
//
//��ҵ��ƣ��������һ�������걸�ļ����������PMC110��������������������С�

//start:	ting			10101 00000000000	A800
//			sdal  32		00100 00000100000	2020
//			datp			10001				8800
//loop:		ting			10101				A800
//			in				01110				7000
//			inh				10100				A000
//			jend excute		10011 00000001010	980A
//			iptr			01101				6800
//			inc				01111				7800
//			jmp	loop		01000 00000000011	4003
//excute:	call  32		01011 00000100000	5820
//			jmp	start		01000 00000000000	4000
//
//exaple: call h00a0		01011 00010100000	58A0
//			ret				01100 00000000000	6000
//			end				10000 00000000000	8000

//����2:��8!	�����ļ�imem16_2.mif
//
//0 main: 		sdal	1				2001  	
//1				str 	one				3001	
//2				str		result			3002  	
//3				sdal	8				2008  	
//4				str		x				3003  	
//5	loop:		lda		x				0803	
//6				jz 		exit			48ad	
//8				mult	result			b802	
//7				str		result 			3002	
//9				lda		x				0803	
//a				sub		one				3801	
//b 	 		str     x 				3003	
//c				jmp		loop			40a5	
//d	exit:		out 	result			1802	
//e				ret						6000	
//f				end						
//�����h9d80=40320

