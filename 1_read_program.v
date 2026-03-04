// 分步设计制作CPU 2024.10.04 解释权陈钢Email:databingo@foxmail.com


module s1 (reset_n, clock, o, opc, ojp);
 

// 自动读取程序机
reg [63:0] irom [0:1];// 程序存储器:64位宽度，2行深度
// 写入两行程序
//irom[0] = 64'b00000000_00000000_00000000_00000000_000000000001_00000_100_00000_0000011;
//irom[1] = 64'b00000000_00000000_00000000_00000000_000000000001_00000_100_00000_1111111;

// 初始化开关
input reset_n;

// 计数工具
input clock;  // 时钟
reg [2:0] pc; // 程序计数器
reg [2:0] jp; // 程序节拍器

// 读取器
reg [63:0] ir; // 程序寄存器:64位宽度

// 显示器
output [6:0] o;
output [2:0] opc;
output [2:0] ojp;

// 显示低 7 位
assign o = ir[6:0];
assign opc = pc[2:0];
assign ojp = jp[2:0];

//initial $readmemb("./programb.txt", irom);

always @(posedge clock or negedge reset_n)
begin
	// 初始化各项 0 值
	if (!reset_n)
	begin
	  pc <=0;
	  jp <=0;
     // 写入两行程序
     irom[0] <= 64'b00000000_00000000_00000000_00000000_000000000001_00000_100_00000_0000011;
     irom[1] <= 64'b00000000_00000000_00000000_00000000_000000000001_00000_100_00000_1111111;
	end
	else
   // 开始指令节拍
	begin
	    case(jp)
	    0: begin // 空拍，pc 传值到程序存储器前端的地址寄存器 
	    	   jp <=1;
	       end
	    1: begin // 取指令
	    	   ir <= irom[pc];
		      pc <= pc + 1; // 程序计数器加一
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
