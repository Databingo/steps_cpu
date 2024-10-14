// 分步设计制作CPU 2024.10.04 解释权陈钢Email:databingo@foxmail.com


module s3 (reset_n, clock, oir, opc, ojp, o_opcode,ofunc3,ofunc7,

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
oBgeu






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






// 连接显示器
assign oir = ir[31:0];  // 显示 32 位指令
assign opc = pc[63:0];// 显示 64 位程序计数器值
assign ojp = jp[2:0]; // 显示 3 位节拍计数器
assign o_opcode = ir[6:0];// 显示 7 位操作码
assign ofunc3 = ir[14:12]; //显示 func3 值
assign ofunc7 = ir[31:25]; //显示 func7 值
//
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
	  // Addi <=0;
	  // Slti <=0;
	  //Sltiu <=0;
	  //  Ori <=0;
	  // Andi <=0;
	  // Xori <=0;
	  // Slli <=0;
	  // Srli <=0;
	  // Srai <=0;
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
	  //
	  //
	  //
	  //
	  //
	  //
	  //
	  //
	  //


	  //opcode <=0;
	  //func3 <=0;
	end
	else
        // 开始指令节拍
	begin
	    case(jp)
	    //0: begin // 空拍，pc 传值到程序存储器前端的地址寄存器 
	    //	   jp <=1;
	    //   end
	    0: begin // 取指令
	    	   ir <=irom[pc]; 
	           //opcode <= irom[pc][6:0];
		   //func3 <= irom[pc][14:12];
	    	   jp <=1; 
	       end
	    1: begin // 分析指令
	    	   case(ir[6:0])
		   7'b0110111: Lui <= 1'b1; // set Lui Flag
	           7'b0010111: Auipc <= 1'b1; // set Auipc Flag
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
	           7'b0100011:begin // S-type
			        case(ir[14:12]) // func3
			          3'b000: Sb  <= 1'b1; // set Sb  Flag 
			          3'b001: Sh  <= 1'b1; // set Sh  Flag 
			          3'b010: Sw  <= 1'b1; // set Sw  Flag 
			          3'b011: Sd  <= 1'b1; // set Sd  Flag  
				endcase
			      end
	           7'b0110011:begin // Math-Logic-Register type
			        case(ir[14:12]) // func3
				  3'b000:begin
				          case(ir[31:25]) // func7
				            7'b0000000:Add  <= 1'b1; // set Add Flag  
				            7'b0100000:Sub  <= 1'b1; // set Sub Flag  
				          endcase
				        end 
			          3'b001: Sll  <= 1'b1; // set Sll Flag 
			          3'b010: Slt  <= 1'b1; // set Slt Flag 
			          3'b011: Sltu <= 1'b1; // set Sltu Flag  
			          3'b100: Xor  <= 1'b1; // set Xor Flag 
				  3'b101:begin 
				          case(ir[31:25]) // func7
				            7'b0000000:Srl  <= 1'b1; // set Srl Flag 
				            7'b0100000:Sra  <= 1'b1; // set Sra Flag  
				          endcase
				         end 
			          3'b110: Or   <= 1'b1; // set Or Flag 
			          3'b111: And  <= 1'b1; // set And Flag 
				endcase
			      end
	           7'b0010011:begin // Math-logic-Imm type
			        case(ir[14:12]) // func3
			          3'b000: Addi  <= 1'b1; // set Addi  Flag 
			          3'b010: Slti  <= 1'b1; // set Slti  Flag 
			          3'b011: Sltiu <= 1'b1; // set Sltiu Flag 
			          3'b110: Ori   <= 1'b1; // set Ori   Flag 
			          3'b111: Andi  <= 1'b1; // set Andi  Flag 
			          3'b100: Xori  <= 1'b1; // set Xori  Flag 
			          3'b001: Slli  <= 1'b1; // set Slli  Flag 
				  3'b101: begin
				          case(ir[31:25]) // func7
				            7'b0000000: Srli  <= 1'b1; // set Srli  Flag 
				            7'b0100000: Srai  <= 1'b1; // set Srai  Flag 
				          endcase
				         end 
				endcase
			      end
	           7'b0011011:begin // Math-logic-Imm-64 type
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
	           7'b0111011:begin // Math-logic-R-64 type
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
	           7'b1101111:begin // Jump
                                Jal <= 1'b1; // set Jal Flag 
                              end
	           7'b1100111:begin // RJump
                                Jalr <= 1'b1; // set Jalr Flag 
                              end
 
	           7'b1100011:begin // Branch type
			        case(ir[14:12]) // func3
			          3'b000: Beq  <= 1'b1; // set Beq  Flag 
			          3'b001: Bne  <= 1'b1; // set Bne  Flag 
			          3'b100: Blt  <= 1'b1; // set Blt  Flag 
			          3'b101: Bge  <= 1'b1; // set Bge  Flag 
			          3'b110: Bltu <= 1'b1; // set Bltu Flag 
			          3'b111: Bgeu <= 1'b1; // set Bgeu Flag 
				endcase
		              end
 

	    	   endcase
	    	   jp <=2;
	       end
	    2: begin // 指令执行
	    	   case(ir[6:0])
		   7'b0110111: Lui <= 1'b0; // close Lui Flag
	           7'b0010111: Auipc <= 1'b0; // close Auipc Flag
		   7'b0000011:begin // L-type
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
	           7'b0110011:begin // Math-Logic-type
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
	           7'b0010011:begin // Math-logic-Imm type
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
	           7'b0011011:begin // Math-logic-I-64 type
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
	           7'b0111011:begin // Math-logic-R-64 type
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
	           7'b1101111:begin // Jump
                                Jal <= 1'b0; // close Jal Flag 
                              end
	           7'b1100111:begin // RJump
                                Jalr <= 1'b0; // close Jalr Flag 
                              end
	           7'b1100011:begin // Branch type
			        case(ir[14:12]) // func3
			          3'b000: Beq  <= 1'b0; // close Beq  Flag 
			          3'b001: Bne  <= 1'b0; // close Bne  Flag 
			          3'b100: Blt  <= 1'b0; // close Blt  Flag 
			          3'b101: Bge  <= 1'b0; // close Bge  Flag 
			          3'b110: Bltu <= 1'b0; // close Bltu Flag 
			          3'b111: Bgeu <= 1'b0; // close Bgeu Flag 
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
