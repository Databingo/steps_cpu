// 分步设计制作CPU 2024.10.04 解释权陈钢Email:databingo@foxmail.com
//
module steps_cpu
 (
 reset_n,
 clock,
 o
 );
 
//// 总过程
//reg [7:0] data_source [1:0]; // 数据源:8位宽度，2行深度
////data_source[1] = 8'b00000110; // 设定第二行数据为6
//
//reg [7:0] dest; //目的地
//
//reg [63:0] irom [2:0];// instruction_rom 一行程序：读取数据源第二行的数据,放入目的地
//irom[0]<=64'b00000000_00000000_00000000_00000000_000000000001_00000_100_00000_0000011;
//// [imm[12]-2048~2047 rs1[5] func100[3] rd[5] 0000011[7]] LBU
//// lbu rd imm(sr)
// 
//// 分步执行
//reg [2:0] pc; // 程序计数器
//reg [2:0] jp; // 节拍器
//input clock;  // 时钟
//
//// 计数工具
//reg [63:0] ir; // instruction_register 程序寄存器 
//input clock;
//input reset_n;


// 自动读取程序机
reg [63:0] irom[1:0];// 程序存储器:64位宽度，2行深度
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

assign o = ir[6:0];


always @(posedge clock or negedge reset_n)
begin
	// 初始化 0 值
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
 
//always @(posedge clock or negedge reset_n)
//begin
//	// 闂佸憡甯楃换鍌烇綖閹版澘绀	if (!reset_n)
//	begin
//		pc <=0;
//		jp <=0;
//	end
//	else
//	begin
//	    // 閻庢鍠掗崑鎾斥攽椤旂⒈鍎撳┑鈽嗗弮楠    case(jp)
//	    0: begin
//	    	jp <=1;
//	       end
//	    1: begin
//	    	ir <= irom[pc];
//		pc <= pc + 1;
//	    	jp <=2;
//	       end
//	    2: begin
//	    	case(ir[6:0])
//	    		7'b0000011: dest <= data_source[1];
//	    		jp <= 0;
//	    	endcase
//	       end
//	    endcase
//          end
//  end
//  endmodule
