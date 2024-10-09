// 分步设计制作CPU 2024.10.04 解释权陈钢Email:databingo@foxmail.com


module s2 (reset_n, clock, o, opc, ojp);
 

// 自动读取程序机
reg [31:0] irom [0:61];// 程序存储器:32位宽度，62行深度

// 初始化开关
input reset_n;

// 计数工具
input clock;  // 时钟
reg [64:0] pc; // 程序计数器 64 位长度
reg [2:0] jp;  // 程序节拍器

// 程序寄存器
reg [31:0] ir; // 程序指令寄存器: 32 位宽度

// 显示器
output [31:0] o;
output [31:0] opc;
output [2:0] ojp;
assign o = ir[31:0];  // 显示 32 位指令
assign opc = pc[63:0];// 显示 64 位程序计数器值
assign ojp = jp[2:0]; // 现实 3 位节拍计数器

// 从文件读取程序到 irom
initial $readmemb("./programb.txt", irom);

always @(posedge clock or negedge reset_n)
begin
	// 初始化各项 0 值
	if (!reset_n)
	begin
	  pc <=0;
	  jp <=0;
	end
	else
        // 开始指令节拍
	begin
	    case(jp)
	    0: begin // 空拍，pc 传值到程序存储器前端的地址寄存器 
	    	   jp <=1;
	       end
	    1: begin 
	    	   ir <= irom[pc]; // 取指令
		   pc <= pc + 1;   // 程序计数器加一
	    	   jp <=1; 
	       end
	    //2: begin // 分析指令
	    //	case(ir[6:0])
	    //		7'b0000011: dest <= data_source[1];
	    //		jp <= 0;
	    //	endcase
	    //   end
	    endcase
   end
end
endmodule
