// 分步设计制作CPU 2024.10.04 解释权陈钢Email:databingo@foxmail.com


module s3 (reset_n, clock, oir, opc, ojp, o_opcode, ofunc3, ofunc7,

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







// 自动读取程序机
reg [31:0] irom [0:61];// 程序存储器:32位宽度，62行深度

// 初始化开关
input reset_n;

// 计数工具
input clock;  // 时钟
reg [64:0] pc; // 程序计数器 64 位宽度
reg [2:0] jp;  // 程序节拍器
reg [31:0] ir; // 程序指令寄存器: 32 位宽度
//reg [6:0] opcode;
//reg [2:0] func3;

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

// 连接显示器
assign oir = ir[31:0];  // 显示 32 位指令
assign opc = pc[63:0];// 显示 64 位程序计数器值
assign ojp = jp[2:0]; // 显示 3 位节拍计数器
assign o_opcode = ir[6:0];// 显示 7 位操作码
assign ofunc3 = ir[14:12]; //显示 func3 值
assign ofunc7 = ir[31:25]; //显示 func7 值
  
assign oLui = Lui; // 显示 Lui 标志线
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
	// 初始化各项 0 值
	if (!reset_n)
	begin
	  pc <=0;
	  jp <=0;
	  //ir <=0;
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
	    0: begin // 取指令
	    	   ir <=irom[pc]; 
	    	   jp <=1; 
	       end
	    1: begin // 分析指令
	    	   case(ir[6:0])
                   // Load-class
		   7'b0110111: Lui <= 1'b1; // set Lui Flag
	           7'b0010111: Auipc <= 1'b1; // set Auipc Flag
		   7'b0000011:begin
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
                   // Store-class
	           7'b0100011:begin
			        case(ir[14:12]) // func3
			          3'b000: Sb  <= 1'b1; // set Sb  Flag 
			          3'b001: Sh  <= 1'b1; // set Sh  Flag 
			          3'b010: Sw  <= 1'b1; // set Sw  Flag 
			          3'b011: Sd  <= 1'b1; // set Sd  Flag  
				endcase
			      end
                   // Math-Logic-Shift-Register class
	           7'b0110011:begin 
			        case(ir[14:12]) // func3
				  3'b000:begin
				          case(ir[31:25]) // func7
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
				          case(ir[31:25]) // func7
				            7'b0000000:Srl  <= 1'b1; // set Srl Flag 
				            7'b0100000:Sra  <= 1'b1; // set Sra Flag  
				          endcase
				         end 
				endcase
			      end
                   // Math-Logic-Shift-Immediate class
	           7'b0010011:begin 
			        case(ir[14:12]) // func3
			          3'b000: Addi  <= 1'b1; // set Addi  Flag 
			          3'b010: Slti  <= 1'b1; // set Slti  Flag 
			          3'b011: Sltiu <= 1'b1; // set Sltiu Flag 
			          3'b110: Ori   <= 1'b1; // set Ori   Flag 
			          3'b111: Andi  <= 1'b1; // set Andi  Flag 
			          3'b100: Xori  <= 1'b1; // set Xori  Flag 
			          3'b001: Slli  <= 1'b1; // set Slli  Flag  // 32-->64 one more bit
				  3'b101: begin
				          case(ir[31:25]) // func7
				            7'b0000000: Srli  <= 1'b1; // set Srli  Flag // 32-->64 one more bit64
				            7'b0100000: Srai  <= 1'b1; // set Srai  Flag // 32-->64 one more bit64
				          endcase
				         end 
				endcase
			      end
                   // Math-Logic-Shift-Immediate-64 class
	           7'b0011011:begin 
			        case(ir[14:12]) // func3
			          3'b000: Addiw  <= 1'b1; // set Addiw  Flag 
			          3'b001: Slliw  <= 1'b1; // set Slliw  Flag 
				  3'b101: begin
				          case(ir[31:25]) // func7
				            7'b0000000: Srliw  <= 1'b1; // set Srliw  Flag 
				            7'b0100000: Sraiw <= 1'b1; // set Sraiw  Flag 
				          endcase
				         end 
				endcase
		              end
                   // Math-Logic-Shift-Register-64 class
	           7'b0111011:begin 
			        case(ir[14:12]) // func3
				  3'b000: begin
				          case(ir[31:25]) // func7
				            7'b0000000: Addw  <= 1'b1; // set Addw  Flag 
				            7'b0100000: Subw  <= 1'b1; // set Subw  Flag 
				          endcase
				         end 
			          3'b001: Sllw  <= 1'b1; // set Sllw  Flag 
				  3'b101: begin
				          case(ir[31:25]) // func7
				            7'b0000000: Srlw  <= 1'b1; // set Srlw  Flag 
				            7'b0100000: Sraw  <= 1'b1; // set Sraw  Flag 
				          endcase
				         end 
				endcase
		              end
                   // Jump
	           7'b1101111:begin 
                                Jal <= 1'b1; // set Jal Flag 
                              end
                   // RJump
	           7'b1100111:begin 
                                Jalr <= 1'b1; // set Jalr Flag 
                              end
                   // Branch class
	           7'b1100011:begin 
			        case(ir[14:12]) // func3
			          3'b000: Beq  <= 1'b1; // set Beq  Flag 
			          3'b001: Bne  <= 1'b1; // set Bne  Flag 
			          3'b100: Blt  <= 1'b1; // set Blt  Flag 
			          3'b101: Bge  <= 1'b1; // set Bge  Flag 
			          3'b110: Bltu <= 1'b1; // set Bltu Flag 
			          3'b111: Bgeu <= 1'b1; // set Bgeu Flag 
				endcase
		              end
                   // Fence class
	           7'b0001111:begin
			        case(ir[14:12]) // func3
			          3'b000: Fence  <= 1'b1; // set Fence Flag 
			          3'b001: Fencei <= 1'b1; // set Fencei Flag 
				endcase
		              end
                   // Enverioment class
	           7'b1110011:begin
			        case(ir[14:12]) // func3
				  3'b000: begin
				          case(ir[31:20]) // func12
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
		              end


	    	   endcase
	    	   jp <=2;
	       end
	    //######## // 指令执行 // Close Flage
	    2: begin 
	    	   case(ir[6:0])
                   // Load class
		   7'b0110111: Lui <= 1'b0; // close Lui Flag
	           7'b0010111: Auipc <= 1'b0; // close Auipc Flag
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
		              end
                   // Store class
	           7'b0100011:begin 
		                case(ir[14:12]) // func3
		                  3'b000: Sb  <= 1'b0; // close Sb Flag 
		                  3'b001: Sh  <= 1'b0; // close Sh Flag 
		                  3'b010: Sw  <= 1'b0; // close Sw Flag 
		                  3'b011: Sd  <= 1'b0; // close Sd Flag  
		        	endcase
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
		              end
                   // Jump
	           7'b1101111:begin
                                Jal <= 1'b0; // close Jal Flag 
                              end
                   // RJump
	           7'b1100111:begin 
                                Jalr <= 1'b0; // close Jalr Flag 
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
		              end
                   // Fence class
	           7'b0001111:begin 
			        case(ir[14:12]) // func3
			          3'b000: Fence  <= 1'b0; // close Fence Flag 
			          3'b001: Fencei <= 1'b0; // close Fencei Flag 
				endcase
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
		              end

		   endcase
		   pc <= pc + 1;   // 程序计数器加一
	    	   jp <=0;
	       end
	    endcase
        end
end
endmodule
