// 分步设计制作CPU 2024.10.04 解释权陈钢Email:databingo@foxmail.com


module s3 (reset_n, clock, oir, opc, ojp, o_opcode,ofunc3,
oLui, 

oLb,
oLbu,
oLh, 
oLhu,
oLw,
oLwu,
oLd,

oSb,
oSh,
oSw,
oSd,




);







// 自动读取程序机
reg [31:0] irom [0:61];// 程序存储器:32位宽度，62行深度

// 初始化开关
input reset_n;

// 计数工具
input clock;  // 时钟
reg [64:0] pc; // 程序计数器 64 位长度
reg [2:0] jp;  // 程序节拍器
reg [31:0] ir; // 程序指令寄存器: 32 位宽度
//reg [6:0] opcode;
//reg [2:0] func3;
reg Lui;

// 
reg Lb;
reg Lbu;
reg Lh; 
reg Lhu;
reg Lw;
reg Lwu;
reg Ld;


reg Sb;
reg Sh;
reg Sw;
reg Sd;







// 显示器
output [31:0] oir;
output [31:0] opc;
output [2:0]  ojp;
output [6:0]  o_opcode;
output [2:0]  ofunc3;


output oLui;

output oLb;
output oLbu;
output oLh; 
output oLhu;
output oLw;
output oLwu;
output oLd;

output oSb;
output oSh;
output oSw;
output oSd;









assign oir = ir[31:0];  // 显示 32 位指令
assign opc = pc[63:0];// 显示 64 位程序计数器值
assign ojp = jp[2:0]; // 显示 3 位节拍计数器
assign o_opcode = ir[6:0];// 显示 7 位操作码
assign ofunc3 = ir[14:12]; //显示 func3 值
assign oLui = Lui; // 显示 Lui 标志线

assign oLb = Lb;
assign oLbu = Lbu;
assign oLh = Lh; 
assign oLhu = Lhu;
assign oLw = Lw;
assign oLwu = Lwu;
assign oLd = Ld;

assign oSb = Sb;
assign oSh = Sh;
assign oSw = Sw;
assign oSd = Sd;






// 从文件读取程序到 irom
initial $readmemb("./programb.txt", irom);

always @(posedge clock or negedge reset_n)
begin
	// 初始化各项 0 值
	if (!reset_n)
	begin
	  pc <=0;
	  jp <=0;
	  //ir <=0;
	  //Lui <=0;
	  //Lb <=0;
	  //Lbu <=0;
          //Lh <=0; 
          //Lhu <=0;
          //Lw <=0;
          //Lwu <=0;
          //Ld <=0;
          //Sb <=0;
          //Sh <=0;
          //Sw <=0;
          //Sd <=0;


	  //opcode <=0;
	  //func3 <=0;
	end
	else
        // 开始指令节拍
	begin
	    case(jp)
	    0: begin // 空拍，pc 传值到程序存储器前端的地址寄存器 
	    	   jp <=1;
	       end
	    1: begin 
	    	   ir <=irom[pc]; // 取指令
	           //opcode <= irom[pc][6:0];
		   //func3 <= irom[pc][14:12];
	    	   jp <=2; 
	       end
	    2: begin // 分析指令
	    	   case(ir[6:0])
		   7'b0000011:begin  // L-type
			        case(ir[14:12]) // func3
			          3'b000: Lb  <= 1'b1; // set Lb  Flag 
			          3'b100: Lbu <= 1'b1; // set Lbu Flag 
			          3'b001: Lh  <= 1'b1; // set Lh  Flag 
			          3'b101: Lhu <= 1'b1; // set Lhu Flag  
			          3'b010: Lw  <= 1'b1; // set Lw  Flag 
			          3'b110: Lwu <= 1'b1; // set Lwu Flag 
			          3'b011: Ld  <= 1'b1; // set Ld  Flag 
			        endcase
		              end 
		   7'b0110111:begin 
		                  Lui <= 1'b1; // set Flag
			      end
	           7'b0100011:begin // S-type
			        case(ir[14:12]) // func3
			          3'b000: Sb  <= 1'b1; // set Sb  Flag 
			          3'b001: Sh  <= 1'b1; // set Sh  Flag 
			          3'b010: Sw  <= 1'b1; // set Sw  Flag 
			          3'b011: Sd  <= 1'b1; // set Sd  Flag  
				endcase
			      end
	    	   endcase
	    	   jp <=3;
	       end
	    3: begin // 指令执行
	           //opcode <= ir[6:0];
	    	   case(ir[6:0])
		   7'b0000011:begin // Load type
			        case(ir[14:12])  // func3
			          3'b000: Lb  <= 1'b0; // close Lb  Flag 
			          3'b100: Lbu <= 1'b0; // close Lbu Flag 
			          3'b001: Lh  <= 1'b0; // close Lh  Flag 
			          3'b101: Lhu <= 1'b0; // close Lhu Flag  
			          3'b010: Lw  <= 1'b0; // close Lw  Flag 
			          3'b110: Lwu <= 1'b0; // close Lwu Flag 
			          3'b011: Ld  <= 1'b0; // close Ld  Flag 
			        endcase
			      end
	           7'b0100011:begin // S-type
			        case(ir[14:12]) // func3
			          3'b000: Sb  <= 1'b0; // close Sb Flag 
			          3'b001: Sh  <= 1'b0; // close Sh Flag 
			          3'b010: Sw  <= 1'b0; // close Sw Flag 
			          3'b011: Sd  <= 1'b0; // close Sd Flag  
				endcase
			      end
		   7'b0110111:begin 
		                  // doing .... done
		                  Lui <= 1'b0; // close Flag
			      end
		   endcase
		   pc <= pc + 1;   // 程序计数器加一
	    	   jp <=0;
	       end
	    endcase
        end
end
endmodule
