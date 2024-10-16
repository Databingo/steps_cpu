// 分步设计制作CPU 2024.10.04 解释权陈钢Email:databingo@foxmail.com

function [3:0] my_case_function;
  input [1:0] selector;
  
  begin
    case (selector)
      2'b00: my_case_function = 4'b0001;
      2'b01: my_case_function = 4'b0010;
      2'b10: my_case_function = 4'b0100;
      2'b11: my_case_function = 4'b1000;
      default: my_case_function = 4'b0000;
    endcase
  end
endfunction




module s4 (reset_n, clock, oir, opc, ojp, o_opcode, ofunc3, ofunc7,

oimm,
oupimm,
ox1,


oLui, 
oAuipc,

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

oAdd,
oSub,
oSlt,
oSltu,
oOr,
oAnd,
oXor,
oSll,
oSrl,
oSra,

oAddi, 
oSlti, 
oSltiu,
oOri, 
oAndi,
oXori,
oSlli,
oSrli,
oSrai,

oAddiw,
oSlliw,
oSrliw,
oSraiw,

oAddw,
oSubw,
oSllw,
oSrlw,
oSraw,

oJal,
oJalr,

oBeq, 
oBne, 
oBlt, 
oBge, 
oBltu,
oBgeu,

oFence, 
oFencei,

oEcall, 
oEbreak,
oCsrrw,
oCsrrs,
oCsrrc,
oCsrrwi,
oCsrrsi,
oCsrrci

);






// 自动顺序读取程序机-> [带跳转的]自动顺序读取程序机
// jal rd, imm       # rd = pc+4; pc = pc  + imm_0
// jal x1, 0
// jalr rd, rs1, imm # rd = pc+4; pc = rs1 + imm
// return: jalr x0, x1, 0

//  程序存储器 
reg [7:0] irom [0:399];// 8 位宽度，400 行深度
  
// 寄存器列表 32 个
reg [63:0] rram [0:31];// 64位宽度，32行深度, 0行x0, 1行x1... 31行x31

// 寄存器编号
parameter x0 = 0;
parameter x1 = 1;
parameter x2 = 2;
parameter x3 = 3;
parameter x4 = 4;
parameter x5 = 5;
parameter x6 = 6;
parameter x7 = 7;
parameter x8 = 8;
parameter x9 = 9;
parameter x10 = 10;
parameter x11 = 11;
parameter x12 = 12;
parameter x13 = 13;
parameter x14 = 14;
parameter x15 = 15;
parameter x16 = 16;
parameter x17 = 17;
parameter x18 = 18;
parameter x19 = 19;
parameter x20 = 20;
parameter x21 = 21;
parameter x22 = 22;
parameter x23 = 23;
parameter x24 = 24;
parameter x25 = 25;
parameter x26 = 26;
parameter x27 = 27;
parameter x28 = 28;
parameter x29 = 29;
parameter x30 = 30;
parameter x31 = 31;

// 数据存储器
reg [63:0] drom [0:61];// 64位宽度，62行深度
// 堆栈存储器
reg [63:0] srom [0:61];// 64位宽度，62行深度

// 初始化开关
input reset_n;

// 计数工具
input clock;  // 时钟
reg [64:0] pc; // 程序计数寄存器 64 位宽度
reg [2:0] jp;  // 程序节寄存拍器
  
// 程序指令寄存器: 32 位宽度
reg [31:0] ir; 

reg Lui;
reg Auipc; 
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

reg Add;
reg Sub;
reg Sll;
reg Slt;
reg Sltu;
reg Xor ;
reg Srl;
reg Sra;
reg Or;
reg And;

reg Addi; 
reg Slti;
reg Sltiu;
reg Ori; 
reg Andi;
reg Xori;
reg Slli;
reg Srli;
reg Srai;

reg Addiw;
reg Slliw;
reg Srliw;
reg Sraiw;

reg Addw;
reg Subw;
reg Sllw;
reg Srlw;
reg Sraw;

reg Jal;   
reg Jalr;

reg Beq;
reg Bne;
reg Blt;
reg Bge;
reg Bltu;
reg Bgeu;

reg Fence;
reg Fencei;    

reg Ecall; 
reg Ebreak;
reg Csrrw;
reg Csrrs;
reg Csrrc;
reg Csrrwi;
reg Csrrsi;
reg Csrrci;


// 显示器
output [31:0] oir;
output [31:0] opc;
output [2:0]  ojp;
output [6:0]  o_opcode;
output [2:0]  ofunc3;
output [6:0]  ofunc7;
output [11:0] oimm;
output [19:0] oupimm;
output [63:0] ox1;

// 控制线显示器
output oLui;
output oAuipc; 

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

output oAdd;
output oSub;
output oSll;
output oSlt;
output oSltu;
output oXor; 
output oSrl;
output oSra;
output oOr;
output oAnd;

output oAddi; 
output oSlti;
output oSltiu;
output oOri; 
output oAndi;
output oXori;
output oSlli;
output oSrli;
output oSrai;

output oAddiw;
output oSlliw;
output oSrliw;
output oSraiw;

output oAddw;
output oSubw;
output oSllw;
output oSrlw;
output oSraw;

output oJal;
output oJalr;

output oBeq;
output oBne;
output oBlt;
output oBge;
output oBltu;
output oBgeu;

output oFence;
output oFencei;

output oEcall; 
output oEbreak;
output oCsrrw;
output oCsrrs;
output oCsrrc;
output oCsrrwi;
output oCsrrsi;
output oCsrrci;


// 连接到显示器
assign oir = wire_ir;  // 显示 32 位指令
assign opc = pc[63:0];// 显示 64 位程序计数器值
assign ojp = jp[2:0]; // 显示 3 位节拍计数器
assign o_opcode = wire_op;// 显示 7 位操作码
assign ofunc3 = wire_func3; //显示 func3 值
assign ofunc7 = wire_func7; //显示 func7 值
assign oimm = wire_imm; // 显示 imm 值
assign oupimm = wire_upimm; // 显示 upimm 值
assign ox1 = rram[x1]; // 显示 x1 值

// 根据 pc 组合出完整指令 
// combine 8 bits of 4 bytes into a 32 bit instruction
assign wire_ir = {irom[pc], irom[pc+1], irom[pc+2], irom[pc+3]}; 

// 分析组合数据线，避免使用寄存器浪费时钟
// parse instruction by type
// ______________________________________________
//|31        25 24 20 19 15 14 12 11        7 6 0|
//|func7       |rs2  |rs1  |func3|rd         |op |R
//|imm[11:0]         |rs1  |func3|rd         |op |I
//|imm[11:5]   |rs2  |rs1  |func3|imm[4:0]   |op |S
//|imm[12|10:5]|rs2  |rs1  |func3|imm[4:1|11]|op |SB
//|imm[31:12]                    |rd         |op |U
//|imm[20|10:1|11|19:12]         |rd         |op |UJ
//````````````````````````````````````````````````
wire [31:0] wire_ir;
wire [ 6:0] wire_op;
wire [ 5:0] wire_rd;
wire [ 5:0] wire_rs1;
wire [ 5:0] wire_rs2;
wire [ 5:0] wire_func3;
wire [ 5:0] wire_func7;
wire [11:0] wire_imm;   // I- Lb Lh Lw Lbu Lhu Lwu Ld Jalr Addi Slti Sltiu Xori Ori Andi Addiw
wire [19:0] wire_upimm; // U- Lui Auipc
wire [20:0] wire_jimm;  // UJ- Jal
wire [11:0] wire_simm;  // S- Sb Sh Sw Sd
wire [12:0] wire_bimm;  // SB- Beq Bne Blt Bge Bltu Bgeu
wire [ 5:0] wire_shamt; // If 6 bits the highest is always 0

assign wire_op = wire_ir[6:0]; 
assign wire_rd = wire_ir[11:7]; 
assign wire_func3 = wire_ir[14:12];
assign wire_rs1 = wire_ir[19:15]; 
assign wire_rs2 = wire_ir[24:20]; 
assign wire_func7 = wire_ir[31:25]; 
assign wire_imm = wire_ir[31:20];
assign wire_upimm = wire_ir[31:12];
assign wire_jpimm = {wire_ir[31], wire_ir[19:12], wire_ir[20], wire_ir[31:20], 1'b0};
assign wire_simm = {wire_ir[31:25], wire_ir[11:7]};
assign wire_bimm = {wire_ir[31], wire_ir[19:12], wire_ir[20], wire_ir[30:21],  1'b0};
assign wire_shamt = wire_ir[25:20];

// 显示标志线
assign oLui = Lui; 
assign oAuipc = Auipc;

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

assign oAdd  = Add;
assign oSub  = Sub;
assign oSll  = Sll;
assign oSlt  = Slt;
assign oSltu = Sltu;
assign oXor  = Xor;
assign oSrl  = Srl;
assign oSra  = Sra;
assign oOr   = Or;
assign oAnd  = And;

assign oAddi = Addi; 
assign oSlti = Slti;
assign oSltiu=Sltiu;
assign oOri  =  Ori; 
assign oAndi = Andi;
assign oXori = Xori;
assign oSlli = Slli;
assign oSrli = Srli;
assign oSrai = Srai;

assign oAddiw= Addiw;
assign oSlliw= Slliw;
assign oSrliw= Srliw;
assign oSraiw= Sraiw;

assign oAddw= Addw;
assign oSubw= Subw;
assign oSllw= Sllw;
assign oSrlw= Srlw;
assign oSraw= Sraw;

assign oJal=Jal;
assign oJalr=Jalr;

assign oBeq=Beq;
assign oBne=Bne;
assign oBlt=Blt;
assign oBge=Bge;
assign oBltu=Bltu;
assign oBgeu=Bgeu;

assign oFence=Fence;
assign oFencei=Fencei;

assign oEcall= Ecall; 
assign oEbreak=Ebreak;
assign oCsrrw= Csrrw;
assign oCsrrs= Csrrs;
assign oCsrrc= Csrrc;
assign oCsrrwi=Csrrwi;
assign oCsrrsi=Csrrsi;
assign oCsrrci=Csrrci;

// 从文件读取程序到 irom
initial $readmemb("./programb.txt", irom);

always @(posedge clock or negedge reset_n)
begin
	//#### 初始化各项 0 值
	if (!reset_n)
	begin
	  pc <=0;
	  jp <=0;
	  //ir <=0;
	  //imm <=0;
          rram[x0] <= 64'h0;  // x0 恒为 0
	  rram[x1] <=0;
	  //Lui <=0;
	  //Auipc <=0;  
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
	  //Add <=0;
	  //Sub <=0;
	  //Sll <=0;
	  //Slt <=0;
	  //Sltu <=0;
	  //Xor <=0;
	  //Srl <=0;
	  //Sra <=0;
	  //Or <=0;
	  //And <=0;
	  //Addi <=0;
	  //Slti <=0;
	  //Sltiu <=0;
	  //Ori <=0;
	  //Andi <=0;
	  //Xori <=0;
	  //Slli <=0;
	  //Srli <=0;
	  //Srai <=0;
	  //Addiw <=0;
	  //Slliw <=0;
	  //Srliw <=0;
	  //Sraiw <=0;
	  //Addw <=0;
	  //Subw <=0;
	  //Sllw <=0;
	  //Srlw <=0;
	  //Sraw <=0;
	  //Jal <=0;
	  //Jalr <=0;
	  //Beq <=0;
	  //Bne <=0;
	  //Blt <=0;
	  //Bge <=0;
	  //Bltu <=0;
	  //Bgeu <=0;
	  //Fence <=0;
	  //Fencei <=0;
	  //Ecall <=0; 
	  //Ebreak <=0;
	  //Csrrw <=0;
	  //Csrrs <=0;
	  //Csrrc <=0;
	  //Csrrwi <=0;
	  //Csrrsi <=0;
	  //Csrrci <=0;
	  //
	  //
	  //opcode <=0;
	  //func3 <=0;
	end
	else
        // 开始指令节拍
	begin
	    case(jp)
	    0: begin // 取指令 + 分析指令 + 执行 | 或 准备数据 (分析且备好该指令所需的数据）
	    	   ir <= wire_ir ; 
	    	   case(wire_op)
                   // Load-class
		   7'b0110111:begin
		                Lui <= 1'b1; // set Lui Flag
				//put 20 bits immediate to upper 20 bits of rd left lower 12 bits 0
				rram[wire_rd] <= wire_upimm << 12; // execution
				// prepare next instruction
				pc <= pc + 4; 
	    	                jp <=0;
		              end
		   7'b0010111:begin
		                Auipc <= 1'b1; // set Auipc Flag
				//left shift the 20 bits immediate 12 bits add pc then put to rd
				rram[wire_rd] <= pc + (wire_upimm << 12); // execution
				// prepare next instruction
				pc <= pc + 4; 
	    	                jp <=0;
		   end
		   7'b0000011:begin
	    	                case(irom[pc][14:12]) // func3 case(ir[14:12])
			          3'b000: Lb  <= 1'b1; // set Lb  Flag 
			          3'b100: Lbu <= 1'b1; // set Lbu Flag 
			          3'b001: Lh  <= 1'b1; // set Lh  Flag 
			          3'b101: Lhu <= 1'b1; // set Lhu Flag  
			          3'b010: Lw  <= 1'b1; // set Lw  Flag 
			          3'b110: Lwu <= 1'b1; // set Lwu Flag 
			          3'b011: Ld  <= 1'b1; // set Ld  Flag 
			        endcase
	    	   jp <=1;
		              end 
                   // Store-class
	           7'b0100011:begin
	    	                case(irom[pc][14:12]) // func3 case(ir[14:12])
			          3'b000: Sb  <= 1'b1; // set Sb  Flag 
			          3'b001: Sh  <= 1'b1; // set Sh  Flag 
			          3'b010: Sw  <= 1'b1; // set Sw  Flag 
			          3'b011: Sd  <= 1'b1; // set Sd  Flag  
				endcase
	    	   jp <=1;
			      end
                   // Math-Logic-Shift-Register class
	           7'b0110011:begin 
			        case(irom[pc][14:12]) // func3
				  3'b000:begin
				          case(irom[pc][31:25]) // func7
				            7'b0000000:Add  <= 1'b1; // set Add Flag  
				            7'b0100000:Sub  <= 1'b1; // set Sub Flag  
				          endcase
				        end 
			          3'b010: Slt  <= 1'b1; // set Slt Flag 
			          3'b011: Sltu <= 1'b1; // set Sltu Flag  
			          3'b110: Or   <= 1'b1; // set Or Flag 
			          3'b111: And  <= 1'b1; // set And Flag 
			          3'b100: Xor  <= 1'b1; // set Xor Flag 
			          3'b001: Sll  <= 1'b1; // set Sll Flag 
				  3'b101:begin 
				          case(irom[pc][31:25]) // func7
				            7'b0000000:Srl  <= 1'b1; // set Srl Flag 
				            7'b0100000:Sra  <= 1'b1; // set Sra Flag  
				          endcase
				         end 
				endcase
	    	   jp <=1;
			      end
                   // Math-Logic-Shift-Immediate class
	           7'b0010011:begin 
			        case(irom[pc][14:12]) // func3
			          3'b000: Addi  <= 1'b1; // set Addi  Flag 
			          3'b010: Slti  <= 1'b1; // set Slti  Flag 
			          3'b011: Sltiu <= 1'b1; // set Sltiu Flag 
			          3'b110: Ori   <= 1'b1; // set Ori   Flag 
			          3'b111: Andi  <= 1'b1; // set Andi  Flag 
			          3'b100: Xori  <= 1'b1; // set Xori  Flag 
			          3'b001: Slli  <= 1'b1; // set Slli  Flag  // 32-->64 one more bit
				  3'b101: begin
				          case(irom[pc][31:25]) // func7
				            7'b0000000: Srli  <= 1'b1; // set Srli  Flag // 32-->64 one more bit64
				            7'b0100000: Srai  <= 1'b1; // set Srai  Flag // 32-->64 one more bit64
				          endcase
				         end 
				endcase
	    	   jp <=1;
			      end
                   // Math-Logic-Shift-Immediate-64 class
	           7'b0011011:begin 
			        case(irom[pc][14:12]) // func3
			          3'b000: Addiw  <= 1'b1; // set Addiw  Flag 
			          3'b001: Slliw  <= 1'b1; // set Slliw  Flag 
				  3'b101: begin
				          case(irom[pc][31:25]) // func7
				            7'b0000000: Srliw  <= 1'b1; // set Srliw  Flag 
				            7'b0100000: Sraiw <= 1'b1; // set Sraiw  Flag 
				          endcase
				         end 
				endcase
	    	   jp <=1;
		              end
                   // Math-Logic-Shift-Register-64 class
	           7'b0111011:begin 
			        case(irom[pc][14:12]) // func3
				  3'b000: begin
				          case(irom[pc][31:25]) // func7
				            7'b0000000: Addw  <= 1'b1; // set Addw  Flag 
				            7'b0100000: Subw  <= 1'b1; // set Subw  Flag 
				          endcase
				         end 
			          3'b001: Sllw  <= 1'b1; // set Sllw  Flag 
				  3'b101: begin
				          case(irom[pc][31:25]) // func7
				            7'b0000000: Srlw  <= 1'b1; // set Srlw  Flag 
				            7'b0100000: Sraw  <= 1'b1; // set Sraw  Flag 
				          endcase
				         end 
				endcase
	    	   jp <=1;
		              end
                   // Jump
	           7'b1101111:begin 
		                //imm[19:0] <= {irom[pc][31], irom[pc][19:12], irom[pc][20], irom[pc][30:21], 1'b0}; // read immediate & padding last 0
				rram[irom[pc][11:7]] <= pc + 1;
				pc <= pc + {irom[pc][31], irom[pc][19:12], irom[pc][20], irom[pc][30:21], 1'b0};
                                Jal <= 1'b1; // set Jal Flag 
	    	                jp <=0;
	    	   //jp <=1;
                              end
                   // RJump
	           7'b1100111:begin 
		                //imm[11:0] <= irom[pc][31:20]; // read immediate (no need padding last 0 not as JAL)
				rram[irom[pc][11:7]] <= pc + 1;
				pc <= rram[irom[pc][19:15]] + irom[pc][31:20];
                                Jalr <= 1'b1; // set Jalr Flag 
	    	                jp <=0;
	    	   //jp <=1;
                              end
                   // Branch class
	           7'b1100011:begin 
			        case(irom[pc][14:12]) // func3
			          3'b000: Beq  <= 1'b1; // set Beq  Flag 
			          3'b001: Bne  <= 1'b1; // set Bne  Flag 
			          3'b100: Blt  <= 1'b1; // set Blt  Flag 
			          3'b101: Bge  <= 1'b1; // set Bge  Flag 
			          3'b110: Bltu <= 1'b1; // set Bltu Flag 
			          3'b111: Bgeu <= 1'b1; // set Bgeu Flag 
				endcase
	    	   jp <=1;
		              end
                   // Fence class
	           7'b0001111:begin
			        case(irom[pc][14:12]) // func3
			          3'b000: Fence  <= 1'b1; // set Fence Flag 
			          3'b001: Fencei <= 1'b1; // set Fencei Flag 
				endcase
	    	   jp <=1;
		              end
                   // Enverioment class
	           7'b1110011:begin
			        case(irom[pc][14:12]) // func3
				  3'b000: begin
				          case(irom[pc][31:20]) // func12
				            12'b000000000000: Ecall  <= 1'b1; // set Ecall  Flag 
				            12'b000000000001: Ebreak <= 1'b1; // set Ebreak Flag 
				          endcase
				         end 
			          3'b001: Csrrw  <= 1'b1; // set Csrrw  Flag 
			          3'b010: Csrrs  <= 1'b1; // set Csrrs  Flag 
			          3'b011: Csrrc  <= 1'b1; // set Csrrc  Flag 
			          3'b101: Csrrwi <= 1'b1; // set Csrrwi Flag 
			          3'b110: Csrrsi <= 1'b1; // set Csrrsi Flag 
			          3'b111: Csrrci <= 1'b1; // set Csrrci Flag 
				endcase
	    	   jp <=1;
		              end


	    	   endcase
	    	   //jp <=1;
	       end
	    //######## // 指令执行 // Close Flage
	    1: begin 
	    	   case(ir[6:0])
                   // Load class
		   7'b0110111: 
		              begin
                                Lui <= 1'b0; // close Lui Flag
		                pc <= pc + 4;   // 程序计数器加一
	    	                jp <=0;
		              end
	           7'b0010111: 
		              begin
                                Auipc <= 1'b0; // close Auipc Flag
		                pc <= pc + 4;   // 程序计数器加一
	    	                jp <=0;
		              end
		   7'b0000011:begin 
		                case(ir[14:12])  // func3
		                  3'b000: Lb  <= 1'b0; // close Lb  Flag 
		                  3'b100: Lbu <= 1'b0; // close Lbu Flag 
		                  3'b001: Lh  <= 1'b0; // close Lh  Flag 
		                  3'b101: Lhu <= 1'b0; // close Lhu Flag  
		                  3'b010: Lw  <= 1'b0; // close Lw  Flag 
		                  3'b110: Lwu <= 1'b0; // close Lwu Flag 
		                  3'b011: Ld  <= 1'b0; // close Ld  Flag 
		                endcase
		                  pc <= pc + 4;   // 程序计数器加一
	    	                  jp <=0;
		              end
                   // Store class
	           7'b0100011:begin 
		                case(ir[14:12]) // func3
		                  3'b000: Sb  <= 1'b0; // close Sb Flag 
		                  3'b001: Sh  <= 1'b0; // close Sh Flag 
		                  3'b010: Sw  <= 1'b0; // close Sw Flag 
		                  3'b011: Sd  <= 1'b0; // close Sd Flag  
		        	endcase
		                  pc <= pc + 4;   // 程序计数器加一
	    	                  jp <=0;
		              end
                   // Math-Logic-Shift-Register class
	           7'b0110011:begin 
			        case(ir[14:12]) // func3
				  3'b000:begin
				          case(ir[31:25]) // func7
				            7'b0000000:Add  <= 1'b0; // close Add Flag  
				            7'b0100000:Sub  <= 1'b0; // close Sub Flag  
				          endcase
				        end 
			          3'b001: Sll  <= 1'b0; // close Sll Flag 
			          3'b010: Slt  <= 1'b0; // close Slt Flag 
			          3'b011: Sltu <= 1'b0; // close Sltu Flag  
			          3'b100: Xor  <= 1'b0; // close Xor Flag 
				  3'b101:begin 
				          case(ir[31:25]) // func7
				            7'b0000000:Srl  <= 1'b0; // close Srl Flag 
				            7'b0100000:Sra  <= 1'b0; // close Sra Flag  
				          endcase
				         end 
			          3'b110: Or   <= 1'b0; // close Or Flag 
			          3'b111: And  <= 1'b0; // close And Flag 
				endcase
		                  pc <= pc + 4;   // 程序计数器加一
	    	                  jp <=0;
			      end
                   // Math-Logic-Shift-Immediate class
	           7'b0010011:begin 
			        case(ir[14:12]) // func3
			          3'b000: Addi  <= 1'b0; // close Addi  Flag 
			          3'b010: Slti  <= 1'b0; // close Slti  Flag 
			          3'b011: Sltiu <= 1'b0; // close Sltiu Flag 
			          3'b110: Ori   <= 1'b0; // close Ori   Flag 
			          3'b111: Andi  <= 1'b0; // close Andi  Flag 
			          3'b100: Xori  <= 1'b0; // close Xori  Flag 
			          3'b001: Slli  <= 1'b0; // close Slli  Flag 
				  3'b101: begin
				          case(ir[31:25]) // func7
				            7'b0000000: Srli  <= 1'b0; // set Srli  Flag 
				            7'b0100000: Srai  <= 1'b0; // set Srai  Flag 
				          endcase
				         end 
				endcase
		                  pc <= pc + 4;   // 程序计数器加一
	    	                  jp <=0;
			      end
                   // Math-Logic-Shift-Immediate-64 class
	           7'b0011011:begin
			        case(ir[14:12]) // func3
			          3'b000: Addiw  <= 1'b0; // close Addiw  Flag 
			          3'b001: Slliw  <= 1'b0; // close Slliw  Flag 
				  3'b101: begin
				          case(ir[31:25]) // func7
				            7'b0000000: Srliw <= 1'b0; // close Srliw  Flag 
				            7'b0100000: Sraiw <= 1'b0; // close Sraiw  Flag 
				          endcase
				         end 
				endcase
		                  pc <= pc + 4;   // 程序计数器加一
	    	                  jp <=0;
		              end
                   // Math-Logic-Shift-Register-64 class
	           7'b0111011:begin
			        case(ir[14:12]) // func3
				  3'b000: begin
				          case(ir[31:25]) // func7
				            7'b0000000: Addw  <= 1'b0; // close Addw  Flag 
				            7'b0100000: Subw  <= 1'b0; // close Subw  Flag 
				          endcase
				         end 
			          3'b001: Sllw  <= 1'b0; // close Sllw  Flag 
				  3'b101: begin
				          case(ir[31:25]) // func7
				            7'b0000000: Srlw  <= 1'b0; // close Srlw  Flag 
				            7'b0100000: Sraw  <= 1'b0; // close Sraw  Flag 
				          endcase
				         end 
				endcase
		                  pc <= pc + 4;   // 程序计数器加一
	    	                  jp <=0;
		              end
                   // Jump
		   //e####
	           7'b1101111:begin
                                Jal <= 1'b0; // close Jal Flag 
	    	                jp <=0;
                              end
                   // RJump
	           7'b1100111:begin 
                                Jalr <= 1'b0; // close Jalr Flag 
		                //pc <= pc + 1;   // 程序计数器加一
	    	                jp <=0;
                              end
                   // Branch class
	           7'b1100011:begin 
			        case(ir[14:12]) // func3
			          3'b000: Beq  <= 1'b0; // close Beq  Flag 
			          3'b001: Bne  <= 1'b0; // close Bne  Flag 
			          3'b100: Blt  <= 1'b0; // close Blt  Flag 
			          3'b101: Bge  <= 1'b0; // close Bge  Flag 
			          3'b110: Bltu <= 1'b0; // close Bltu Flag 
			          3'b111: Bgeu <= 1'b0; // close Bgeu Flag 
				endcase
		                  pc <= pc + 4;   // 程序计数器加一
	    	                  jp <=0;
		              end
                   // Fence class
	           7'b0001111:begin 
			        case(ir[14:12]) // func3
			          3'b000: Fence  <= 1'b0; // close Fence Flag 
			          3'b001: Fencei <= 1'b0; // close Fencei Flag 
				endcase
		                  pc <= pc + 4;   // 程序计数器加一
	    	                  jp <=0;
		              end
                   // Enverioment class
	           7'b1110011:begin 
			        case(ir[14:12]) // func3
				  3'b000: begin
				          case(ir[31:20]) // func12
				            12'b000000000000: Ecall  <= 1'b0; // close Ecall  Flag 
				            12'b000000000001: Ebreak <= 1'b0; // close Ebreak Flag 
				          endcase
				         end 
			          3'b001: Csrrw  <= 1'b0; // close Csrrw  Flag 
			          3'b010: Csrrs  <= 1'b0; // close Csrrs  Flag 
			          3'b011: Csrrc  <= 1'b0; // close Csrrc  Flag 
			          3'b101: Csrrwi <= 1'b0; // close Csrrwi Flag 
			          3'b110: Csrrsi <= 1'b0; // close Csrrsi Flag 
			          3'b111: Csrrci <= 1'b0; // close Csrrci Flag 
				endcase
		                  pc <= pc + 4;   // 程序计数器加一
	    	                  jp <=0;
		              end

		   endcase
	       end
	    endcase
        end
end
endmodule
