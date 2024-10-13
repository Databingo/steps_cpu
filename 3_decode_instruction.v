// 分步设计制作CPU 2024.10.04 解释权陈钢Email:databingo@foxmail.com


module s3 (reset_n, clock, oir, opc, ojp, o_opcode, oLb, oLui, ofunc3);
 

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
reg [2:0] Lb ;
reg Lui;

// 显示器
output [31:0] oir;
output [31:0] opc;
output [2:0] ojp;
output [6:0] o_opcode;
output [2:0] oLb ;
output [1:0] oLui;
output [2:0] ofunc3;

assign oir = ir[31:0];  // 显示 32 位指令
assign opc = pc[63:0];// 显示 64 位程序计数器值
assign ojp = jp[2:0]; // 显示 3 位节拍计数器
assign o_opcode = ir[6:0];// 显示 7 位操作码
assign oLb = Lb[2:0];
assign oLui = Lui; // 显示 Lui 标志线
assign ofunc3 = ir[15:13]; //显示 func 值

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
	  //opcode <=0;
	  Lb <=0;
	  Lui <=0;
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
			      case(ir[14:12]) 
			      3'b000: 
			      begin
			       Lb <= 1'b1; // set Flag Lb 
	    	              // jp <=3;
			      end
			      endcase
		              end 
		   7'b0110111:begin 
		                  Lui <= 1'b1; // set Flag
	    	                 // jp <=3;
			      end
	    	   endcase
	    	   jp <=3;
	       end
	    3: begin // 指令执行
	           //opcode <= ir[6:0];
	    	   case(ir[6:0])
		   7'b0000011:begin 
			      case(ir[14:12]) 
			      3'b000: 
			      begin
		                  // doing .... done
			          Lb <= 1'b0; // close Flag
		                  //pc <= pc + 1;   // 程序计数器加一
			          //jp <=0;
				 end
			      endcase
			      end
		   7'b0110111:begin 
		                  // doing .... done
		                  Lui <= 1'b0; // close Flag
		                  //pc <= pc + 1;   // 程序计数器加一
			          //jp <=0;
			      end
		   endcase
		   pc <= pc + 1;   // 程序计数器加一
	    	   jp <=0;
	       end
	    endcase
        end
end
endmodule
