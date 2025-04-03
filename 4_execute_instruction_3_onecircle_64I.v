// 分步设计制作CPU 2024.10.04 解释权陈钢Email:databingo@foxmail.com
//`include "var.v"

// 声明指令控制线
reg Lui, Auipc, Lb, Lbu, Lh, Lhu, Lw, Lwu, Ld, Sb, Sh, Sw, Sd, Add, Sub, Sll, Slt, Sltu, Xor, Srl, Sra, Or, And, Addi, Slti, Sltiu, Ori, Andi, Xori, Slli, Srli, Srai, Addiw, Slliw, Srliw, Sraiw, Addw, Subw, Sllw, Srlw, Sraw, Jal, Jalr, Beq, Bne, Blt, Bge, Bltu, Bgeu, Fence, Fencei, Ecall, Ebreak, Csrrw, Csrrs, Csrrc, Csrrwi, Csrrsi, Csrrci;

// 定义 csr 选择器
function [4:0] csr_index;
 input [11:0] csr_wire;
 begin
  case (csr_wire)                                                  // Machine Information Registers
        12'hF11: csr_index = 5'd1;                                 // 0xF11 MRO mvendorid Vendor ID
	12'hF12: csr_index = 5'd2; 	                           // 0xF12 MRO marchid Architecture ID
	12'hF13: csr_index = 5'd3; 	                           // 0xF13 MRO mimpid Implementation ID
	12'hF14: csr_index = 5'd4; 	                           // 0xF14 MRO mhartid Hardware thread ID
	12'hF11: csr_index = 5'd5; 	                           // 0xF15 MRO mconfigptr Pointer to configuration data structure
	                              	                           // Machine Trap Setup
	12'h300: csr_index = 5'd6;	                           // 0x300 MRW mstatus Machine status register *
	12'h301: csr_index = 5'd7;	                           // 0x301 MRW misa ISA and extensions
	12'h302: csr_index = 5'd8;	                           // 0x302 MRW medeleg Machine exception delegation register
	12'h303: csr_index = 5'd9;	                           // 0x303 MRW mideleg Machine interrupt delegation register
	12'h304: csr_index = 5'd10;	                           // 0x304 MRW mie Machine interrupt-enable register *
	12'h305: csr_index = 5'd11;	                           // 0x305 MRW mtvec Machine trap-handler base address *
	12'h306: csr_index = 5'd12;	                           // 0x306 MRW mcounteren Machine counter enable
	12'h307: csr_index = 5'd13;	                           // 0x307 MRW mtvt Machine Trap-Handler vector table base address
	12'h310: csr_index = 5'd14;	                           // 0x310 MRW mstatush Additional machine status register, RV32 only
	                          	                           // Machine Trap Handling
	12'h340: csr_index = 5'd15;	                           // 0x340 MRW mscratch Scratch register for machine trap handlers *
	12'h341: csr_index = 5'd16;	                           // 0x341 MRW mepc Machine exception program counter *
	12'h342: csr_index = 5'd17;	                           // 0x342 MRW mcasue Machine trap casue *
	12'h343: csr_index = 5'd18;	                           // 0x343 MRW mtval Machine bad address or instruction *
	12'h344: csr_index = 5'd19;	                           // 0x344 MRW mip Machine interrupt pending *
	12'h34A: csr_index = 5'd20;	                           // 0x34A MRW mtinst Machine trap instruction (transformed)
	12'h34B: csr_index = 5'd21;	                           // 0x34B MRW mtval2 Machine bad guset physical address
                                    	                           // Machine Configuration
	12'h30A: csr_index = 5'd22;	                           // 0x30A MRW menvcfg Machine environment configuration register
	12'h31A: csr_index = 5'd23;	                           // 0x31A MRW menvcfgh Additional machine env. conf. register, RV32 only
	12'h747: csr_index = 5'd24;	                           // 0x747 MRW mseccfg Machine security configuration register
	12'h757: csr_index = 5'd25;	                           // 0x757 MRW mseccfgh Additional machine security conf. register, RV32 only
	                          	                           // Machine Memory Protection
	12'h3A0: csr_index = 5'd26;	                           // 0x3A0 MRW pmpcfg0  Physical memory protection configuration.
	12'h3A1: csr_index = 5'd27;	                           // 0x3A1 MRW pmpcfg1  Physical memory protection configuration, RV32 only.
	12'h3A2: csr_index = 5'd28;	                           // 0x3A2 MRW pmpcfg2  Physical memory protection configuration.
	12'h3A3: csr_index = 5'd29;	                           // 0x3A3 MRW pmpcfg3  Physical memory protection configuration.
	                          	                           // ...
	12'h3AE: csr_index = 5'd30;	                           // 0x3AE MRW pmpcfg14  
	12'h3AF: csr_index = 5'd31;	                           // 0x3AF MRW pmpcfg15  
	//12'h3B0: csr_index = 5'd32;	                           // 0x3B0 MRW pmpaddr0 Physical memory protection address register.
	//12'h3B1: csr_index = 5'd33;	                           // 0x3B1 MRW pmpaddr0
	//                          	                           // ...
	//12'h3EF: csr_index = 5'd34;	                           // 0x3EF MRW pmpaddr0
    default: csr_index = 5'b00000;
  endcase
 end
endfunction

reg [4:0] csr_id; 

//#------------------
//# mcause table
//#------------------
//# 0x8000000B # MSB: 0 exception, 1 interrupt; 
//#              LSB: interrupt 11 M-mode 
//# Exception 0
//# 0 Instruction Address Misaligned
//# 1 Instruction Access Fault         
//# 2 Illegal Instruction          
//# 3 Breakpoint          
//# 4 Load Address Misaligned          
//# 5 Load Access Fault         
//# 6 Store/AMO(Atomic Memory Operation) Address Misaligned          
//# 7 Store/AMO(Atomic Memory Operation) Access Fault
//# 8 Environment Call from U-mode (ECALL)          
//# 9 Environment Call from S-mode (ECALL)                   
//# 10 Reserved           
//# 11 Environment Call from M-mode (ECALL)                   
//# 12 Instruction Page Fault         
//# 13 Load Page Fault         
//# 14 Reserved           
//# 15 Store/AMO(Atomic Memory Operation) Page Fault
//
//# Interrupt 1
//# 0 User Software Interrupt
//# 1 Supervisor Software Interrupt          
//# 2 Reserved          
//# 3 Machine Software Interrupt                     
//# 4 User Timer Interrupt          
//# 5 Supervisor Timer Interrupt                     
//# 6 Reserved                    
//# 7 Machine Timer Interrupt                     
//# 8 User External Interrupt          
//# 9 Supervisor External Interrupt          
//# 10 Reserved                              
//# 11 Machine External Interrupt          

module s4 (reset_n, clock, oir, opc, ojp, oop, of3, of7,
oimm, oupimm,oshamt, 
ox1, ox2, ox3, ox4, ox5, ox6, ox7, ox8, ox9, ox10, ox11, ox12, ox13, ox14, ox15, ox16, ox17, ox18, ox19, ox20, ox21, ox22, ox23, ox24, ox25, ox26, ox27, ox28, ox29, ox30, ox31,
osign_extended_bimm,
oLui, oAuipc,
oLb, oLbu, oLh, oLhu, oLw, oLwu, oLd,
oSb, oSh, oSw, oSd,
oAdd, oSub, oSlt, oSltu, oOr, oAnd, oXor, oSll, oSrl, oSra,
oAddi, oSlti, oSltiu, oOri, oAndi, oXori, oSlli, oSrli, oSrai,
oAddiw, oSlliw, oSrliw, oSraiw,
oAddw, oSubw, oSllw, oSrlw, oSraw,
oJal, oJalr,
oBeq, oBne, oBlt, oBge, oBltu, oBgeu,
oFence, oFencei,
oEcall, oEbreak, oCsrrw, oCsrrs, oCsrrc, oCsrrwi, oCsrrsi, oCsrrci
);

// 自动顺序读取程序机-> [带跳转的]自动顺序读取程序机
// jal rd, imm       # rd = pc+4; pc = pc  + imm_0
// jal x1, 0
// jalr rd, rs1, imm # rd = pc+4; pc = rs1 + imm
// return: jalr x0, x1, 0

//  程序存储器 
reg [7:0] irom [0:399];// 8 位宽度，400 行深度
// 数据存储器
reg [7:0] drom [0:399];// 8 位宽度，400 行深度
// 堆栈存储器
reg [7:0] srom [0:399];// 8 位宽度，400 行深度
// 通用寄存器列表 32 个
reg [63:0] rram [0:31];// 64 位宽度，32 行深度 x0, x1, x2... x31
// CSR 寄存器列表 32 个(预设个数 2**12=4096)
reg [63:0] csrram [0:31];// 64 位宽度，32 行深度

// 计数工具
input clock;  // 时钟
reg [64:0] pc; // 程序计数寄存器 64 位宽度
reg [2:0] jp;  // 程序节寄存拍器

// 程序指令寄存器: 32 位宽度
reg [31:0] ir; 

// 初始化开关
input reset_n;

// 指令显示器
output [31:0] oir;
output [31:0] opc;
output [2:0]  ojp;
output [6:0]  oop;
output [2:0]  of3;
output [6:0]  of7;
output [11:0] oimm;
output [19:0] oupimm;
output [5:0] oshamt;
// 寄存器显示器
output [63:0] ox1, ox2, ox3, ox4, ox5, ox6, ox7, ox8, ox9, ox10, ox11, ox12, ox13, ox14, ox15, ox16, ox17, ox18, ox19, ox20, ox21, ox22, ox23, ox24, ox25, ox26, ox27, ox28, ox29, ox30, ox31;
output [63:0] osign_extended_bimm;
// 控制线显示器
output oLui; output oAuipc;
output oLb; output oLbu; output oLh; output oLhu; output oLw; output oLwu; output oLd;
output oSb; output oSh; output oSw; output oSd;
output oAdd; output oSub; output oSll; output oSlt; output oSltu; output oXor; output oSrl; output oSra; output oOr; output oAnd;
output oAddi; output oSlti; output oSltiu; output oOri; output oAndi; output oXori; output oSlli; output oSrli; output oSrai;
output oAddiw; output oSlliw; output oSrliw; output oSraiw;
output oAddw; output oSubw; output oSllw; output oSrlw; output oSraw;
output oJal; output oJalr;
output oBeq; output oBne; output oBlt; output oBge; output oBltu; output oBgeu;
output oFence; output oFencei;
output oEcall; output oEbreak; output oCsrrw; output oCsrrs; output oCsrrc; output oCsrrwi; output oCsrrsi; output oCsrrci;


// 根据 pc 组合出指令 
// combine 8 bits of 4 bytes into a 32 bit instruction
// assign wire_ir = {irom[pc], irom[pc+1], irom[pc+2], irom[pc+3]};  // Big endian
assign wire_ir = {irom[pc+3], irom[pc+2], irom[pc+1], irom[pc]};  // Little endian

// 组合数据线，避免使用寄存器浪费时钟
wire [31:0] wire_ir;
wire [ 6:0] wire_op;
wire [ 5:0] wire_rd;
wire [ 5:0] wire_rs1;
wire [ 5:0] wire_rs2;
wire [ 5:0] wire_f3; 
wire [ 6:0] wire_f7;
wire [11:0] wire_f12;   // ecall 0, ebreak 1
wire [11:0] wire_imm;   // I-type immediate Lb Lh Lw Lbu Lhu Lwu Ld Jalr Addi Slti Sltiu Xori Ori Andi Addiw
wire [19:0] wire_upimm; // U-type immediate Lui Auipc
wire [20:0] wire_jimm;  // UJ-type immediate Jal
wire [11:0] wire_simm;  // S-type immediate Sb Sh Sw Sd
wire [12:0] wire_bimm;  // SB-type immediate Beq Bne Blt Bge Bltu Bgeu
wire [ 5:0] wire_shamt; // If 6 bits the highest is always 0??
wire [11:0] wire_csr;   // CSR address
wire [ 5:0] wire_zimm;  // CSR zimm

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
assign wire_op  = wire_ir[6:0]; 
assign wire_rd  = wire_ir[11:7]; 
assign wire_f3  = wire_ir[14:12];
assign wire_rs1 = wire_ir[19:15]; 
assign wire_rs2 = wire_ir[24:20]; 
assign wire_f7  = wire_ir[31:25]; 
assign wire_f12 = wire_ir[31:20]; 
assign wire_imm = wire_ir[31:20];
assign wire_upimm = wire_ir[31:12];
assign wire_jimm  = {wire_ir[31], wire_ir[19:12], wire_ir[20], wire_ir[31:20], 1'b0}; // read immediate & padding last 0, total 20 + 1 = 21 bits
assign wire_simm  = {wire_ir[31:25], wire_ir[11:7]};
assign wire_bimm  = {wire_ir[31], wire_ir[7],  wire_ir[30:25], wire_ir[11:8], 1'b0};// read immediate & padding last 0, total 12 + 1 = 13 bits
assign wire_shamt = wire_ir[25:20];
assign wire_csr = wire_ir[31:20];
assign wire_zimm = wire_ir[19:15];

// 连接显示器
assign oir = wire_ir;       // 显示 32 位指令
assign opc = pc[63:0];      // 显示 64 位程序计数器值
assign ojp = jp[2:0];       // 显示 3 位节拍计数器
assign oop = wire_op;       // 显示 7 位操作码
assign of3 = wire_f3;       // 显示 func3 值
assign of7 = wire_f7;       // 显示 func7 值
assign oimm = wire_imm;     // 显示 imm 值
assign oupimm = wire_upimm; // 显示 upimm 值
assign oshamt = wire_shamt;
assign ox0 = rram[0];       // 显示 x0 值
assign ox1 = rram[1];       
assign ox2 = rram[2];       
assign ox3 = rram[3];
assign ox4 = rram[4];
assign ox5 = rram[5];
assign ox6 = rram[6]; 
assign ox7 = rram[7];
assign ox8 = rram[8];
assign ox9 = rram[9]; 
assign ox10 = rram[10];
assign ox11 = rram[11];
assign ox12 = rram[12];
assign ox13 = rram[13];
assign ox14 = rram[14];
assign ox15 = rram[15];
assign ox16 = rram[16];
assign ox17 = rram[17];
assign ox18 = rram[18];
assign ox19 = rram[19];
assign ox20 = rram[20];
assign ox21 = rram[21];
assign ox22 = rram[22];
assign ox23 = rram[23];
assign ox24 = rram[24];
assign ox25 = rram[25];
assign ox26 = rram[26];
assign ox27 = rram[27];
assign ox28 = rram[28];
assign ox29 = rram[29];
assign ox30 = rram[30];
assign ox31 = rram[31];

assign osign_extended_bimm = sign_extended_bimm[63:0];
assign oLui = Lui; assign oAuipc = Auipc;
assign oLb = Lb; assign oLbu = Lbu; assign oLh = Lh; assign oLhu = Lhu; assign oLw = Lw; assign oLwu = Lwu; assign oLd = Ld;
assign oSb = Sb; assign oSh = Sh; assign oSw = Sw; assign oSd = Sd;
assign oAdd  = Add; assign oSub  = Sub; assign oSll  = Sll; assign oSlt  = Slt; assign oSltu = Sltu; assign oXor  = Xor; assign oSrl  = Srl; assign oSra  = Sra; assign oOr   = Or; assign oAnd  = And;
assign oAddi = Addi; assign oSlti = Slti; assign oSltiu=Sltiu; assign oOri  =  Ori; assign oAndi = Andi; assign oXori = Xori; assign oSlli = Slli; assign oSrli = Srli; assign oSrai = Srai;
assign oAddiw= Addiw; assign oSlliw= Slliw; assign oSrliw= Srliw; assign oSraiw= Sraiw;
assign oAddw= Addw; assign oSubw= Subw; assign oSllw= Sllw; assign oSrlw= Srlw; assign oSraw= Sraw;
assign oJal=Jal; assign oJalr=Jalr;
assign oBeq=Beq; assign oBne=Bne; assign oBlt=Blt; assign oBge=Bge; assign oBltu=Bltu; assign oBgeu=Bgeu;
assign oFence=Fence; assign oFencei=Fencei;
assign oEcall= Ecall; assign oEbreak=Ebreak; assign oCsrrw= Csrrw; assign oCsrrs= Csrrs; assign oCsrrc= Csrrc; assign oCsrrwi=Csrrwi; assign oCsrrsi=Csrrsi; assign oCsrrci=Csrrci;

// 从文件读取程序到 irom
//initial $readmemb("./programb.txt", irom);
//initial $readmemb("./asm/binary_instructions.txt", irom);
initial $readmemb("./binary_instructions.txt", irom);
//initial $readmemb("./firmware.out", irom);
initial $readmemb("./data.txt", drom);

reg [63:0] sum; // 加法结果组合逻辑寄存器
reg [63:0] sum_imm; // 加法结果组合逻辑寄存器
reg [63:0] mirro_rs2; // rs2 相反数，取反加一，减法变加法用
reg [63:0] mirro_imm; // imm 相反数，取反加一，减法变加法用
reg [63:0] sub; // 减法结果组合逻辑寄存器
reg [63:0] sub_imm; // 减法结果组合逻辑寄存器
reg [63:0] sign_extended_bimm; // 符号扩展的 bimm

// 组合逻辑（电路即时生效,无需等待时钟周期）
always @(*)
begin
 sum = rram[wire_rs1] + rram[wire_rs2];
 sum_imm = rram[wire_rs1] + {{52{wire_imm[11]}}, wire_imm};
 mirro_rs2 = ~rram[wire_rs2] + 1;
 mirro_imm = ~{{52{wire_imm[11]}}, wire_imm} + 1;
 sub = rram[wire_rs1] + mirro_rs2;
 sub_imm = rram[wire_rs1] + mirro_imm;
 sign_extended_bimm = {{51{wire_ir[31]}}, wire_bimm};  //bimm is 13 bits length
end 


always @(posedge clock or negedge reset_n)
begin
	//#### 初始化各项 0 值
	if (!reset_n)
	begin
	  pc <=0;
	  jp <=0;
	  //ir <=0;
	  //imm <=0;
          rram[0] <= 64'h0;  // x0 恒为 0 
	  rram[1] <=0;
	  rram[2] <=0;
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
	  //opcode <=0;
	  //func3 <=0;
	end
	else
        // 开始指令节拍
	begin
	    case(jp)
	    0: begin // 取指令 + 分析指令 + 执行 | 或 准备数据 (分析且备好该指令所需的数据）
	    	   ir <= wire_ir ; 
		   // parse: op->func3->func7
	    	   case(wire_op)
                   // Load-class
		   7'b0110111:begin
		                Lui <= 1'b1; // set Lui Flag
				//put 20 bits immediate to upper 20 bits of rd left lower 12 bits 0
				rram[wire_rd] <= wire_upimm << 12;
				pc <= pc + 4; 
	    	                jp <=0;
		              end
		   7'b0010111:begin
		                Auipc <= 1'b1; // set Auipc Flag
				//left shift the 20 bits immediate 12 bits add pc then put to rd
				rram[wire_rd] <= pc + (wire_upimm << 12); 
				pc <= pc + 4; 
	    	                jp <=0;
		   end
		   7'b0000011:begin
	    	                case(wire_f3) // func3 case(ir[14:12])
				  3'b000:begin 
				           Lb  <= 1'b1; // set Lb  Flag 
				           //load 8 bite sign extend to 64 bits at imm(s1) to rd
				           rram[wire_rd] <= {{56{drom[rram[wire_rs1]+wire_imm][7]}}, 
					                         drom[rram[wire_rs1]+wire_imm]}; 
				           pc <= pc + 4; 
	    	                           jp <=0;
				         end 
				  3'b100:begin 
				           Lbu  <= 1'b1; // set Lbu  Flag 
				           //load 8 bite unsign to 64 bits at imm(s1) to rd
				           rram[wire_rd] <= {56'b0, drom[rram[wire_rs1]+wire_imm]}; 
				           pc <= pc + 4; 
	    	                           jp <=0;
				         end 
				  3'b001:begin 
                                           Lh  <= 1'b1; // set Lh  Flag 
				           //load 16 bite sign extend to 64 bits at imm(s1) to rd
				           rram[wire_rd] <= {{48{drom[rram[wire_rs1]+wire_imm + 1][7]}}, 
					                         drom[rram[wire_rs1]+wire_imm + 1], 
								 drom[rram[wire_rs1]+wire_imm] }; 
				           pc <= pc + 4; 
	    	                           jp <=0;
				         end 
				  3'b101:begin 
                                           Lhu <= 1'b1; // set Lhu Flag  
				           //load 16 bite unsign to 64 bits at imm(s1) to rd
				           rram[wire_rd] <= {48'b0, drom[rram[wire_rs1]+wire_imm + 1], 
					                            drom[rram[wire_rs1]+wire_imm] }; 
				           pc <= pc + 4; 
	    	                           jp <=0;
				         end 
				  3'b010:begin 
                                           Lw  <= 1'b1; // set Lw  Flag
					   //load 32 bite sign extend to 64 bits at imm(s1) to rd
	                                   rram[wire_rd] <= {{32{drom[rram[wire_rs1]+wire_imm + 3][7]}}, 
	                                                         drom[rram[wire_rs1]+wire_imm+3], 
	                                 			 drom[rram[wire_rs1]+wire_imm+2], 
	                                 			 drom[rram[wire_rs1]+wire_imm+1], 
	                                 			 drom[rram[wire_rs1]+wire_imm]}; 
				           pc <= pc + 4; 
	    	                           jp <=0;
				         end 
				  3'b110:begin 
                                           Lwu <= 1'b1; // set Lwu Flag 
					   //load 32 bite unsign to 64 bits at imm(s1) to rd
	                                   rram[wire_rd] <= {32'b0, drom[rram[wire_rs1]+wire_imm+3], 
	                                                            drom[rram[wire_rs1]+wire_imm+2], 
	                                                            drom[rram[wire_rs1]+wire_imm+1], 
	                                                            drom[rram[wire_rs1]+wire_imm]}; 
				           pc <= pc + 4; 
	    	                           jp <=0;
				         end 
				  3'b011:begin 
                                           Ld  <= 1'b1; // set Ld  Flag 
					   //load 64 bite sign to 64 bits at imm(s1) to rd
	                                   rram[wire_rd] <= {drom[rram[wire_rs1]+wire_imm+7], 
	                                                     drom[rram[wire_rs1]+wire_imm+6], 
	                                                     drom[rram[wire_rs1]+wire_imm+5], 
	                                                     drom[rram[wire_rs1]+wire_imm+4],
	                                                     drom[rram[wire_rs1]+wire_imm+3], 
	                                                     drom[rram[wire_rs1]+wire_imm+2], 
	                                                     drom[rram[wire_rs1]+wire_imm+1], 
	                                                     drom[rram[wire_rs1]+wire_imm  ]}; 
				           pc <= pc + 4; 
	    	                           jp <=0;
				         end 
			        endcase
		              end 
                   // Store-class
	           7'b0100011:begin
	    	                case(wire_f3) // func3 case(ir[14:12])
				  3'b000:begin 
				           //store byte, write low 8 bits of rs1 to rs2's imm.12
				           Sb  <= 1'b1; // set Sb  Flag 
					   drom[rram[wire_rs1]+wire_simm] <= rram[wire_rs2][7:0];
				           pc <= pc + 4; 
	    	                           jp <=0;
				         end 
				  3'b001:begin 
				           //store half word, write low 16 bits of rs1 to rs2's imm.12
				           Sh  <= 1'b1; // set Sh  Flag 
					   drom[rram[wire_rs1]+wire_simm] <= rram[wire_rs2][7:0];
					   drom[rram[wire_rs1]+wire_simm+1] <= rram[wire_rs2][15:8];
				           pc <= pc + 4; 
	    	                           jp <=0;
				         end 
				  3'b010:begin 
				           //store word, write low 16 bits of rs1 to rs2's imm.12
				           Sw  <= 1'b1; // set Sw  Flag  
					   drom[rram[wire_rs1]+wire_simm] <= rram[wire_rs2][7:0];
					   drom[rram[wire_rs1]+wire_simm+1] <= rram[wire_rs2][15:8];
					   drom[rram[wire_rs1]+wire_simm+2] <= rram[wire_rs2][23:16];
					   drom[rram[wire_rs1]+wire_simm+3] <= rram[wire_rs2][31:24];
				           pc <= pc + 4; 
	    	                           jp <=0;
				         end 
				  3'b011:begin 
				           //store double words, write 64 bits of rs1 to rs2's imm.12
				           Sd  <= 1'b1; // set Sd  Flag  
					   drom[rram[wire_rs1]+wire_simm] <= rram[wire_rs2][7:0];
					   drom[rram[wire_rs1]+wire_simm+1] <= rram[wire_rs2][15:8];
					   drom[rram[wire_rs1]+wire_simm+2] <= rram[wire_rs2][23:16];
					   drom[rram[wire_rs1]+wire_simm+3] <= rram[wire_rs2][31:24];
					   drom[rram[wire_rs1]+wire_simm+4] <= rram[wire_rs2][39:32];
					   drom[rram[wire_rs1]+wire_simm+5] <= rram[wire_rs2][47:40];
					   drom[rram[wire_rs1]+wire_simm+6] <= rram[wire_rs2][55:48];
					   drom[rram[wire_rs1]+wire_simm+7] <= rram[wire_rs2][63:56];
				           pc <= pc + 4; 
	    	                           jp <=0;
				         end 
				endcase
			      end
                   // Math-Logic-Shift-Register class
	           7'b0110011:begin 
			        case(wire_f3) // func3
				  3'b000:begin
				          case(wire_f7) // func7
				            7'b0000000:begin 
				                     Add  <= 1'b1; // set Add Flag
				                     // Add s1 to s2 then send ignore overfloat to rd 
						     // 同号相加或异号相减会有溢出，异号相减可以变成同号相加，因此只有同号相加才会有溢出，
						     // 溢出是加数与结果首异
						     // 符号是加数的符号
						     // 同号相减和异号相加，都可以变成异号相加, 结果不会溢出，符号以运算结果为准, 1 就是负，0就是正。静默
						     // 无符号相加只是有符号0数同号分段相加，高一段接受低一段进位, 最高一段接受溢出判断
						     
						      // 执行加法:
				                     rram[wire_rd] <= rram[wire_rs1] + rram[wire_rs2]; 
						      // 溢出判断：
						      // 同号与结果最高位变化则为溢出
						      // (a[gao] ~^ b[gao]) & (a[gao] ^ c[gao]) == 1 溢出 
						      // 电路： 
						      // B----|
						      //      XNOR--
						      // A----|     |--AND-->
						      //      XOR---
						      // C----|
						      // 结果扩充一个同号数位
						      // 加法和溢出判断可以通过电路设计在一个时钟周期内完成
						      
				                     if ((rram[wire_rs1][63] ~^ rram[wire_rs2][63]) && (rram[wire_rs1][63] ^ sum[63])) 
						     begin
	    	                                      rram[3] <= 1; // 溢出标志
	    	                                      rram[4] <= rram[wire_rs1][63]; // 溢出值
						     end
				                     pc <= pc + 4; 
	    	                                     jp <=0;

				                   end 
					    7'b0100000:begin
				                     Sub  <= 1'b1; // set Sub Flag  
				                     // Sub rs2 from rs1 then send ignore overfloat to rd
						     // 转化成加法：加相反数-反码加一, 使用加法器，加法流程
						     // 执行加法:
				                     //rram[wire_rd] <= rram[wire_rs1] + (~rram[wire_rs2]+1);
				                     rram[wire_rd] <= sub;
						     // 溢出判断：
				                     if ((rram[wire_rs1][63] ~^ mirro_rs2 [63]) && (rram[wire_rs1][63] ^ sub[63])) 
						     begin
	    	                                      rram[3] <= 1; // 溢出标志
	    	                                      rram[4] <= rram[wire_rs1][63]; // 溢出值
						     end
				                     pc <= pc + 4; 
	    	                                     jp <=0;
				                   end 
				          endcase
				        end 
				  3'b010:begin 
				           Slt  <= 1'b1; // set Slt Flag 
				           // if rs1 less than rs2 both as sign-extended then put 1 in rd else 0
					   
					   // 电路方式: 一周期实现比较 
					   // 计算 rs1 - rs2 < 0  转化 Sub -> Add
					   // 同号相加, 号即大小: 1: rs1 小于 rs2
					    if ((rram[wire_rs1][63] ~^ mirro_rs2[63]) && rram[wire_rs1][63] == 1)
                                                     rram[wire_rd] <= 1'b1; 
					   // 异号相加, 果即大小 |1: rs1 小于 rs2 |000: 相等 |0xxx: rs1 大于 rs2
					    else if ((rram[wire_rs1][63] ^ mirro_rs2[63]) && (sub[63] == 1))
                                                     rram[wire_rd] <= 1'b1; 
                                           // 否则 rs1 大于 rs2
					    else rram[wire_rd] <= 1'b0;
					  
					   // 代码模式 
					   // if (rram[wire_rs1] - rram[wire_rs2] < 0 ) rram[wire_rd] <= 1'b1; 

				           pc <= pc + 4; 
	    	                           jp <=0;
				         end 
				    3'b011:begin 
				           Sltu <= 1'b1; // set Sltu Flag  
				           // if rs1 less than rs2 both as unsign then put 1 in rd else 0
					   
					   // 电路方式: 一周期实现比较 
					   // 计算 rs1 - rs2 < 0  转化 Sub -> Add
					   // 异号相加, 果即大小：1: rs1 小于 rs2
					   // 溢出位 0 取反为 1 负
					   // 次首位进位判断：a==b==1; a^b && c==0
					   // 进位后为 正(或0) 大于等于
					    if (rram[wire_rs1][63] == mirro_rs2[63] == 1)
                                                     rram[wire_rd] <= 1'b0; 
					    else if ((rram[wire_rs1][63] ^ mirro_rs2[63]) && (sub[63] == 0))
                                                     rram[wire_rd] <= 1'b0; 
                                           // 否则 rs1 小于 rs2
					    else rram[wire_rd] <= 1'b1;
					  
					   // 代码模式 
					   // if (rram[wire_rs1] - rram[wire_rs2] < 0 ) rram[wire_rd] <= 1'b1; 

				           pc <= pc + 4; 
	    	                           jp <=0;
				         end 
				    3'b110:begin
					   Or   <= 1'b1; // set Or Flag 
                                           // bitwise OR  rs1 and rs2 then put reslut in rd
					   rram[wire_rd] <= (rram[wire_rs1] | rram[wire_rs2]); 
				           pc <= pc + 4; 
	    	                           jp <=0;
					   end
				   3'b111:begin 
					   And  <= 1'b1; // set And Flag 
                                           // bitwise AND  rs1 and rs2 then put reslut in rd
					   rram[wire_rd] <= (rram[wire_rs1] & rram[wire_rs2]); 
				           pc <= pc + 4; 
	    	                           jp <=0;
					   end
				   3'b100:begin 
					   Xor  <= 1'b1; // set Xor Flag
                                           // bitwise XOR  rs1 and rs2 then put reslut in rd
					   rram[wire_rd] <= (rram[wire_rs1] ^ rram[wire_rs2]); 
				           pc <= pc + 4; 
	    	                           jp <=0;
					   end
				    3'b001:begin 
				           Sll  <= 1'b1; // set Sll Flag 
					   // shift lift  logicl rs1 by imm.12[low5.unsign] padding 0 to rd
					   rram[wire_rd] <= (rram[wire_rs1] << wire_shamt ); 
				           pc <= pc + 4; 
	    	                           jp <=0;
					   end
				  3'b101:begin 
				          case(wire_f7) // func7
					    7'b0000000:begin
					               Srl  <= 1'b1; // set Srl Flag 
					               // shift right logicl rs1 by imm.12[low5.unsign] padding 0 to rd
					               rram[wire_rd] <= (rram[wire_rs1] >> wire_shamt ); 
				                       pc <= pc + 4; 
	    	                                       jp <=0;
						       end
					    7'b0100000:begin 
					               Sra  <= 1'b1; // set Sra Flag  
					               // shift right arithmatical rs1 by imm.12[low5.unsign] padding 0 to rd
					               rram[wire_rd] <= (rram[wire_rs1] >>> wire_shamt ); 
				                       pc <= pc + 4; 
	    	                                       jp <=0;
						       end
				          endcase
				         end 
				endcase
			      end
                   // Math-Logic-Shift-Immediate class
	           7'b0010011:begin 
			        case(wire_f3) // func3
				  3'b000:begin
				         Addi  <= 1'b1; // set Addi  Flag 
				         //add sign-extend imm.12 to sr1, send overflow ingnored result to rd 
				         // 执行加法:
				         rram[wire_rd] <= rram[wire_rs1] + {{52{wire_imm[11]}}, wire_imm}; 
				         // 溢出判断：
				         if ((rram[wire_rs1][63] ~^ wire_imm[11]) && (rram[wire_rs1][63] ^ sum_imm[63])) 
				           begin
	    	                         rram[3] <= 1; // 溢出标志
	    	                         rram[4] <= rram[wire_rs1][63]; // 溢出值
				           end
				         pc <= pc + 4; 
	    	                         jp <=0;
				         end
				 3'b010:begin
					  Slti  <= 1'b1; // set Slti  Flag 
				           // if rs1 is less than imm.12 both as sign-extended then put 1 in rd else 0
					   
					   // 电路方式: 一周期实现比较 
					   // 计算 rs1 - imm < 0  转化 Sub -> Add
					   // 同号相加, 号即大小: 1: rs1 小于 imm 
					    if ((rram[wire_rs1][63] ~^ mirro_imm[63]) && rram[wire_rs1][63] == 1)
                                                     rram[wire_rd] <= 1'b1; 
					   // 异号相加, 果即大小：1: rs1 小于 imm
					    else if ((rram[wire_rs1][63] ^ mirro_imm[63]) && (sub_imm[63] == 1))
                                                     rram[wire_rd] <= 1'b1; 
                                           // 否则 rs1 大于 imm 
					    else rram[wire_rd] <= 1'b0;
					   // 代码模式 
					   // if (rram[wire_rs1] - imm < 0 ) rram[wire_rd] <= 1'b1; 

				           pc <= pc + 4; 
	    	                           jp <=0;
				         end 
				 3'b011:begin
					   Sltiu <= 1'b1; // set Sltiu Flag 
				           // if rs1 less than imm both as unsign then put 1 in rd else 0
					   
					   // 电路方式: 一周期实现比较 
					   // 计算 rs1 - imm < 0  转化 Sub -> Add
					   // 异号相加, 果即大小：1: rs1 小于 imm 
					   // 溢出位 0 取反为 1 负
					   // 次首位进位判断：a==b==1; a^b && c==0
					   // 进位后为 正(或0) 大于等于
					    if (rram[wire_rs1][63] == mirro_imm[63] == 1)
                                                     rram[wire_rd] <= 1'b0; 
					    else if ((rram[wire_rs1][63] ^ mirro_imm[63]) && (sub_imm[63] == 0))
                                                     rram[wire_rd] <= 1'b0; 
                                           // 否则 rs1 小于 rs2
					    else rram[wire_rd] <= 1'b1;
					  
					   // 代码模式 
					   // if ({[0],rram[wire_rs1]} - {[0],imm} < 0 ) rram[wire_rd] <= 1'b1; 

				           pc <= pc + 4; 
	    	                           jp <=0;
				         end 
				 3'b110:begin 
				           Ori   <= 1'b1; // set Ori   Flag 
                                           // bitwise OR  rs1 and sign-extend imm.12 put reslut in rd
					   rram[wire_rd] <= (rram[wire_rs1] | {{52{wire_imm[11]}}, wire_imm}); 
				           pc <= pc + 4; 
	    	                           jp <=0;
					   end
				 3'b111:begin 
				           Andi  <= 1'b1; // set Andi  Flag 
                                           // bitwise AND rs1 and sign-extend imm.12 put reslut in rd
					   rram[wire_rd] <= (rram[wire_rs1] & {{52{wire_imm[11]}}, wire_imm}); 
				           pc <= pc + 4; 
	    	                           jp <=0;
					   end
				 3'b100:begin 
				           Xori  <= 1'b1; // set Xori  Flag 
                                           // bitwise XORI  rs1 and rs2 then put reslut in rd
					   rram[wire_rd] <= (rram[wire_rs1] ^ {{52{wire_imm[11]}}, wire_imm}); 
				           pc <= pc + 4; 
	    	                           jp <=0;
					   end
				 3'b001:begin// func3 001 for left 
					   Slli  <= 1'b1; // set Slli  Flag  // 32-->64 one more bit
					   // shift lift  logicl rs1 by imm.12[low6.unsign] padding 0 to rd
					   rram[wire_rd] <= (rram[wire_rs1] << wire_shamt ); 
				           pc <= pc + 4; 
	    	                           jp <=0;
					   end
				  3'b101: begin // func3 101 for right
				          case(wire_f7[6:1]) // func7 // rv64 shame take wire_f7[0]
					  //7'b0000000:begin
					    7'b000000:begin
					               Srli  <= 1'b1; // set Srli  Flag // 32-->64 one more bit64
					               // shift right logicl rs1 by imm.12[low6.unsign] padding 0 to rd
					               rram[wire_rd] <= (rram[wire_rs1] >> wire_shamt ); 
				                       pc <= pc + 4; 
	    	                                       jp <=0;
						       end
					   //7'b0100000:begin 
					     7'b010000:begin 
					               Srai  <= 1'b1; // set Srai  Flag // 32-->64 one more bit64
					               // shift right arithmatical rs1 by imm.12[low6.unsign] padding?
					               rram[wire_rd] <= ($signed(rram[wire_rs1]) >>> wire_shamt ); 
				                       pc <= pc + 4; 
	    	                                       jp <=0;
						       end
				          endcase
				         end 
				endcase
			      end
                   // Math-Logic-Shift-Immediate-64 class
	           7'b0011011:begin 
			        case(wire_f3) // func3
			                    //+++++++++++++++++++++++++++++++++
			          3'b000: Addiw  <= 1'b1; // set Addiw  Flag 
			          3'b001: Slliw  <= 1'b1; // set Slliw  Flag 
				  3'b101: begin
				          case(wire_f7) // func7
				            7'b0000000: Srliw  <= 1'b1; // set Srliw  Flag 
				            7'b0100000: Sraiw <= 1'b1; // set Sraiw  Flag 
				          endcase
				         end 
				endcase
	    	   //jp <=1;
		              end
                   // Math-Logic-Shift-Register-64 class
	           7'b0111011:begin 
			        case(wire_f3) // func3
				  3'b000: begin
				          case(wire_f7) // func7
				            7'b0000000: Addw  <= 1'b1; // set Addw  Flag 
				            7'b0100000: Subw  <= 1'b1; // set Subw  Flag 
				          endcase
				         end 
			          3'b001: Sllw  <= 1'b1; // set Sllw  Flag 
				  3'b101: begin
				          case(wire_f7) // func7
				            7'b0000000: Srlw  <= 1'b1; // set Srlw  Flag 
				            7'b0100000: Sraw  <= 1'b1; // set Sraw  Flag 
				          endcase
				         end 
				endcase
	    	   //jp <=1;
		              end
                   // Jump
	           7'b1101111:begin 
                                Jal <= 1'b1; // set Jal Flag 
				//jump PC to PC+imm(padding 0) and place return address PC+4 in rd
				rram[wire_rd] <= pc + 4;
				pc <= pc + wire_jimm;
	    	                jp <=0;
                              end
                   // RJump
	           7'b1100111:begin 
                                Jalr <= 1'b1; // set Jalr Flag 
		                //jump PC to address imm(rs1) and place return address PC+4 in rd (no need padding last 0 not as JAL)
				rram[wire_rd] <= pc + 4;
				pc <= rram[wire_rs1] + wire_imm;
	    	                jp <=0;
                              end
                   // Branch class
	           7'b1100011:begin 
			        case(wire_f3) // func3
				  3'b000:begin
				         Beq  <= 1'b1; // set Beq  Flag 
				         //  take branch if rs1 rs2 equal to PC+(sign-extend imm_0)
					 if (rram[wire_rs1] == rram[wire_rs2])
				             pc <= pc + sign_extended_bimm;
					 else pc <= pc + 4; 
	    	                         jp <=0;
				         end
				  3'b001:begin 
					 Bne  <= 1'b1; // set Bne  Flag 
				         //  take branch if rs1 rs2 not equal to PC+(sign-extend imm_0)
					 if (rram[wire_rs1] != rram[wire_rs2])
				             pc <= pc + sign_extended_bimm;
					 else pc <= pc + 4; 
	    	                         jp <=0;
				         end
				  3'b100:begin 
					 Blt  <= 1'b1; // set Blt  Flag 
				         //  take branch if rs1 smaller than rs2 to PC+(sign-extend imm_0)
					 //
					 // 电路方式: 一周期实现比较 
					 // 计算 rs1 - rs2 < 0  转化 Sub -> Add
					 // 同号相加, 号即大小: 1: rs1 小于 rs2
					  if ((rram[wire_rs1][63] ~^ mirro_rs2[63]) && rram[wire_rs1][63] == 1)
				             pc <= pc + sign_extended_bimm;
					 // 异号相加, 果即大小：1: rs1 小于 rs2
					  else if ((rram[wire_rs1][63] ^ mirro_rs2[63]) && (sub[63] == 1))
				             pc <= pc + sign_extended_bimm;
                                         // 否则 rs1 大于或等于 rs2
					  else pc <= pc + 4;
					 
					 // 代码模式 
	    	                         jp <=0;
				         end
				  3'b101:begin 
					 Bge  <= 1'b1; // set Bge  Flag 
				         //  take branch if rs1 bigger than or equite to rs2 to PC+(sign-extend imm_0)
					 //
					 // 电路方式: 一周期实现比较 
					 // 计算 rs1 - rs2 > 0  转化 Sub -> Add
					 // 同号相加, 号即大小: 0: rs1 大于 rs2
					  if ((rram[wire_rs1][63] ~^ mirro_rs2[63]) && rram[wire_rs1][63] == 0)
				             pc <= pc + sign_extended_bimm;
					 // 异号相加, 果即大小：0: rs1 大于(或等于) rs2
					  else if ((rram[wire_rs1][63] ^ mirro_rs2[63]) && (sub[63] == 0))
				             pc <= pc + sign_extended_bimm;
                                         // 否则 rs1 小于 rs2
					  else pc <= pc + 4;
					 
	    	                         jp <=0;
					 // 代码模式 
					 end
				  3'b110:begin
			                 //+++++++++++++++++++++++++++++++++
					 Bltu <= 1'b1; // set Bltu Flag 
					 //take branch if rs1 < rs2 in unsigned comparison 
					 // 电路方式: 一周期实现比较 
					 // 计算 rs1 - rs2 < 0  转化 Sub -> Add 正数相加变成了正数减去负数
					 // 异号相加, 果即大小：1: rs1 小于 rs2
					 // 溢出位 0 取反为 1 负
					 // 次首位进位判断：a==b==1; a^b && c==0
					 // 进位后为 正(或0) 大于等于
					  if (rram[wire_rs1][63] == mirro_rs2[63] == 1)
					      pc <= pc + 4;
					  else if ((rram[wire_rs1][63] ^ mirro_rs2[63]) && (sub[63] == 0))
					      pc <= pc + 4;
                                         // 否则 rs1 小于 rs2
					  else pc <= pc + sign_extended_bimm;
	    	                          jp <=0;
					 // 代码模式 
				         end 
					 
				  3'b111:begin
					 Bgeu <= 1'b1; // set Bgeu Flag 
					 //take branch if rs1 >= rs2 in unsigned comparison 
					 // 电路方式: 一周期实现比较 
					 // 计算 rs1 - rs2 > 0  转化 Sub -> Add 正数相加变成了正数减去负数
					 // 异号相加, 果即大小：0: rs1 大于 rs2
					 // 溢出位 0 取反为 1 负
					 // 次首位进位判断：a==b==1; a^b && c==0
					 // 进位后为 正(或0) 大于等于
					  if (rram[wire_rs1][63] == mirro_rs2[63] == 1)
                                              pc <= pc + sign_extended_bimm;
					  else if ((rram[wire_rs1][63] ^ mirro_rs2[63]) && (sub[63] == 0))
                                              pc <= pc + sign_extended_bimm;
                                         // 否则 rs1 小于 rs2
					  else pc <= pc + 4;

	    	                          jp <=0;
					 
					 // 代码模式 
					 // if (rram[wire_rs1] - rram[wire_rs2] < 0 ) rram[wire_rd] <= 1'b1; 
				         end 
				endcase
		              end
                   // Fence class
	           7'b0001111:begin
			        case(irom[pc][14:12]) // func3
			          3'b000: Fence  <= 1'b1; // set Fence Flag 
			          3'b001: Fencei <= 1'b1; // set Fencei Flag 
				endcase
	    	   //jp <=1;
		              end
                   // Enverioment class
		   //
		   // M mode (must) 
		   // 1.sync error 同步异常（内部异常）: inner instructions, 5-type: access, break, ecall, opcode, address 
		   // 2.async interrupt 异步中断（外部中断）: outer event, that is not instructions, such as software, timer, keyboard/mouse
		   //
		   // 8 CSRs for M mode necessary
		   // mepc: refer to the error instruction(machine exception program counter)
		   // mtvec: keep the address of the interrupt-handler address or re-continue address in async interrupt
		   // mcause: cause, type of interrupt
		   // mtval: trap value, address of the error address, instruction of the error instruction, or 0
		   // mie: machine interrupt enable that indicate can deal and have to ignore, all interrupt have a position here
		   // mip: machine interrupt pending same position as mie
		   // mscratch: one word data
		   // mstatus: keep global interrupt enable and other status
		   // timer interrupt must mstatus[3].MIE(global interrupt enable) = 1, mie[7](M timer interrupt enable) = 1, mip[7](dealing interrupt) = 1
		   //
		   // Deal steps:
		   // mepc <= pc
		   // pc <= mtvec (mtvec refer to error instruction as Error, refer to re-continue instruction as Interrupe)
		   // mcasue <= casue
		   // mtval <= value
		   // mstatus.MIE <= 0 (disable other Interrupt)
		   // MPIE <= MIE keep pre mie to mpie
		   // mstatus.MPP <= 11 (change privilage to M[User 00, Supervisor 01, Machine 11])
		   //
		   // Return step:
		   // mret
		   // pc <= mepc
		   // mstatus.MIE <= mstatus.MPIE
		   // mstatus.MPP <= mstatus.MPP pre
		   // 
		   // for upgraded(or embeded) interrupe, keep mepc mcause mtval mstatus to stack of ram and recover them to csr before return
		   //
		   // wfi：wait for interrupt
		   //
		   // Register
		   // ----------------------------
		   // x0     0    
		   // x1     ra    return address
		   // x2     sp    stack pointer
		   // x3     gp    global pointer
		   // x4     tp    thread pointer
		   // x5-7   t0-2  temporary registers
		   // x8     s0/fp saved registers/frame pointer
		   // x9     s1
		   // x10-11 a0-1  function arguments/return values
		   // x12-17 a2-7
		   // x18-27 s2-11 saved registers
		   // x28-31 t3-6  temporary registers
		   // ----------------------------
		   // CS Register[12:0]    
		   // [11:10] read/write 00、01、01rw/11read only 
		   // [9:8] privilege 00user 01supervisor 10hypervisor 11machine
		   // ----------------------------
		   // Machine Information Registers
		   // 0xF11 MRO mvendorid Vendor ID
		   // 0xF12 MRO marchid Architecture ID
		   // 0xF13 MRO mimpid Implementation ID
		   // 0xF14 MRO mhartid Hardware thread ID
		   // 0xF15 MRO mconfigptr Pointer to configuration data structure
		   // Machine Trap Setup
		   // 0x300 MRW mstatus Machine status register
		   // 0x301 MRW misa ISA and extensions
		   // 0x302 MRW medeleg Machine exception delegation register
		   // 0x303 MRW mideleg Machine interrupt delegation register
		   // 0x304 MRW mie Machine interrupt-enable register
		   // 0x305 MRW mtvec Machine trap-handler base address
		   // 0x306 MRW mcounteren Machine counter enable
		   // 0x307 MRW mtvt Machine Trap-Handler vector table base address
		   // 0x310 MRW mstatush Additional machine status register, RV32 only
		   // Machine Trap Handling
		   // 0x340 MRW mscratch Scratch register for machine trap handlers
		   // 0x341 MRW mepc Machine exception program counter
		   // 0x342 MRW mcasue Machine trap casue
		   // 0x343 MRW mtval Machine bad address or instruction
		   // 0x344 MRW mip Machine interrupt pending
		   // 0x34A MRW mtinst Machine trap instruction (transformed)
		   // 0x34B MRW mtval2 Machine bad guset physical address
		   // Machine Configuration
		   // 0x30A MRW menvcfg Machine environment configuration register
		   // 0x31A MRW menvcfgh Additional machine env. conf. register, RV32 only
		   // 0x747 MRW mseccfg Machine security configuration register
		   // 0x757 MRW mseccfgh Additional machine security conf. register, RV32 only
		   // Machine Memory Protection
		   // 0x3A0 MRW pmpcfg0  Physical memory protection configuration.
		   // 0x3A1 MRW pmpcfg1  Physical memory protection configuration, RV32 only.
		   // 0x3A2 MRW pmpcfg2  Physical memory protection configuration.
		   // 0x3A3 MRW pmpcfg3  Physical memory protection configuration.
		   // ...
		   // 0x3AE MRW pmpcfg14  
		   // 0x3AF MRW pmpcfg15  
		   // 0x3B0 MRW pmpaddr0 Physical memory protection address register.
		   // 0x3B1 MRW pmpaddr0
		   // ...
		   // 0x3EF MRW pmpaddr0
		   //mpie 
		   // ----------------------------
	           7'b1110011:begin
		                csr_id =  csr_index(wire_csr);
			        case(wire_f3) // func3
				  3'b000: begin
				          case(wire_f12) // func12
			                    //+++++++++++++++++++++++++++++++++
				            12'b000000000000: Ecall  <= 1'b1; // set Ecall  Flag 
				            12'b000000000001: Ebreak <= 1'b1; // set Ebreak Flag 
				          endcase
				         end 
                                  // CSRRW  |csr.12|rs1.5|001.3|rd.5|1110011.7| atomic write, put 0-extend csr value! in rd(if rd=x0 not read), then put sr1 to csr
				  // csrr rd, csr -> csrrs rd, csr, x0 | read
				  // csrw csr, rs -> csrrw x0, csr, rs | write
				  3'b001:begin
				         Csrrw  <= 1'b1; // set Csrrw  Flag 
					 if (wire_rd !== 5'b00000) rram[wire_rd] <= csrram[csr_id];
					 csrram[csr_id] <= rram[wire_rs1];
		                         pc <= pc + 4; 
                                         jp <=0;
				         end
                                  // CSRRS  |csr.12|rs1.5|001.3|rd.5|1110011.7| atomic set, put 0-extend csr in rd, sr1(if sr1=x0 not write) as 1 mask set csr 1 correspond
                                  // csrs csr, rs -> csrrs x0, csr, rs
				  3'b010:begin
				         Csrrs  <= 1'b1; // set Csrrs  Flag 
					 rram[wire_rd] <= csrram[csr_id];
					 if (wire_rs1 !== 5'b00000) csrram[csr_id] <= rram[wire_rs1] | csrram[csr_id];
		                         pc <= pc + 4; 
                                         jp <=0;
				         end
                                  // CSRRC  |csr.12|rs1.5|011.3|rd.5|1110011.7| atomic clear, put 0-extend csr in rd, sr1(if sr1=x0 not write) as 1 mask set csr 0 under
                                  // csrc csr, rs -> csrrc x0, csr, rs
				  3'b011:begin
				         Csrrc  <= 1'b1; // set Csrrc  Flag 
					 rram[wire_rd] <= csrram[csr_id];
					 if (wire_rs1 !== 5'b00000) csrram[csr_id] <= ~rram[wire_rs1] & csrram[csr_id];
		                         pc <= pc + 4; 
                                         jp <=0;
				         end
                                  // CSRRWI |csr.12|zim.5|101.3|rd.5|1110011.7| atomic write, put 0-extend csr in rd(if rd=x0 not read), 0-extend 5unsigned zimm to csr 
                                  // csrwi csr, imm -> csrrwi x0, csr, imm
				  3'b101:begin
				         Csrrwi <= 1'b1; // set Csrrwi Flag 
					 if (wire_rd !== 5'b00000) rram[wire_rd] <= csrram[csr_id];
					 csrram[csr_id] <= {59'b0, wire_zimm};
		                         pc <= pc + 4; 
                                         jp <=0;
				         end
                                  // CSRRSI |csr.12|zim.5|110.3|rd.5|1110011.7| atomic set, 0-extend csr in rd, 0-extended 5unsigned zimm(if zimm == 0 not write) as 1 mask set csr 1
                                  // csrsi csr, imm -> csrrsi x0, csr, imm
				  3'b110:begin 
				         Csrrsi <= 1'b1; // set Csrrsi Flag 
					 rram[wire_rd] <= csrram[csr_id];
					 if (wire_zimm !== 5'b00000) csrram[csr_id] <= {59'b0, wire_zimm } | csrram[csr_id];
		                         pc <= pc + 4; 
                                         jp <=0;
				         end
                                  // CSRRCI |csr.12|zim.5|111.3|rd.5|1110011.7| atomic clear, 0-extend csr in rd, 0-extended 5unsigned zimm(if zimm == 0 not write) as 1 mask set csr0
                                  // csrci csr, imm -> csrrci x0, csr, imm
				  3'b111:begin
				         Csrrci <= 1'b1; // set Csrrci Flag 
					 rram[wire_rd] <= irom[wire_csr];
					 if (wire_zimm !== 5'b00000) csrram[csr_id] <= ~{59'b0, wire_zimm } & csrram[csr_id];
		                         pc <= pc + 4; 
                                         jp <=0;
				         end
				endcase
		              end


	    	   endcase
	    	   //jp <=1;
                   rram[0] <= 64'h0;  // x0 恒为 0
	       end
	    //######## // 指令执行 // Close Flage
	    //1: begin 
	    //	   case(wire_op)
            //       // Load class
	    //       7'b0110111: 
	    //                  begin
            //                    Lui <= 1'b0; // close Lui Flag
	    //                    pc <= pc + 4;   // 程序计数器加一
	    //	                jp <=0;
	    //                  end
	    //       7'b0010111: 
	    //                  begin
            //                    Auipc <= 1'b0; // close Auipc Flag
	    //                    pc <= pc + 4;   // 程序计数器加一
	    //	                jp <=0;
	    //                  end
	    //       7'b0000011:begin 
	    //                    case(ir[14:12])  // func3
	    //                      3'b000: Lb  <= 1'b0; // close Lb  Flag 
	    //                      3'b100: Lbu <= 1'b0; // close Lbu Flag 
	    //                      3'b001: Lh  <= 1'b0; // close Lh  Flag 
	    //                      3'b101: Lhu <= 1'b0; // close Lhu Flag  
	    //                      3'b010: Lw  <= 1'b0; // close Lw  Flag 
	    //                      3'b110: Lwu <= 1'b0; // close Lwu Flag 
	    //                      3'b011: Ld  <= 1'b0; // close Ld  Flag 
	    //                    endcase
	    //                      pc <= pc + 4;   // 程序计数器加一
	    //	                  jp <=0;
	    //                  end
            //       // Store class
	    //       7'b0100011:begin 
	    //                    case(ir[14:12]) // func3
	    //                      3'b000: Sb  <= 1'b0; // close Sb Flag 
	    //                      3'b001: Sh  <= 1'b0; // close Sh Flag 
	    //                      3'b010: Sw  <= 1'b0; // close Sw Flag 
	    //                      3'b011: Sd  <= 1'b0; // close Sd Flag  
	    //            	endcase
	    //                      pc <= pc + 4;   // 程序计数器加一
	    //	                  jp <=0;
	    //                  end
            //       // Math-Logic-Shift-Register class
	    //       7'b0110011:begin 
	    //    	        case(ir[14:12]) // func3
	    //    		  3'b000:begin
	    //    		          case(ir[31:25]) // func7
	    //    		            7'b0000000:Add  <= 1'b0; // close Add Flag  
	    //    		            7'b0100000:Sub  <= 1'b0; // close Sub Flag  
	    //    		          endcase
	    //    		        end 
	    //    	          3'b001: Sll  <= 1'b0; // close Sll Flag 
	    //    	          3'b010: Slt  <= 1'b0; // close Slt Flag 
	    //    	          3'b011: Sltu <= 1'b0; // close Sltu Flag  
	    //    	          3'b100: Xor  <= 1'b0; // close Xor Flag 
	    //    		  3'b101:begin 
	    //    		          case(ir[31:25]) // func7
	    //    		            7'b0000000:Srl  <= 1'b0; // close Srl Flag 
	    //    		            7'b0100000:Sra  <= 1'b0; // close Sra Flag  
	    //    		          endcase
	    //    		         end 
	    //    	          3'b110: Or   <= 1'b0; // close Or Flag 
	    //    	          3'b111: And  <= 1'b0; // close And Flag 
	    //    		endcase
	    //                      pc <= pc + 4;   // 程序计数器加一
	    //	                  jp <=0;
	    //    	      end
            //       // Math-Logic-Shift-Immediate class
	    //       7'b0010011:begin 
	    //    	        case(ir[14:12]) // func3
	    //    	          3'b000: Addi  <= 1'b0; // close Addi  Flag 
	    //    	          3'b010: Slti  <= 1'b0; // close Slti  Flag 
	    //    	          3'b011: Sltiu <= 1'b0; // close Sltiu Flag 
	    //    	          3'b110: Ori   <= 1'b0; // close Ori   Flag 
	    //    	          3'b111: Andi  <= 1'b0; // close Andi  Flag 
	    //    	          3'b100: Xori  <= 1'b0; // close Xori  Flag 
	    //    	          3'b001: Slli  <= 1'b0; // close Slli  Flag 
	    //    		  3'b101: begin
	    //    		          case(ir[31:25]) // func7
	    //    		            7'b0000000: Srli  <= 1'b0; // set Srli  Flag 
	    //    		            7'b0100000: Srai  <= 1'b0; // set Srai  Flag 
	    //    		          endcase
	    //    		         end 
	    //    		endcase
	    //                      pc <= pc + 4;   // 程序计数器加一
	    //	                  jp <=0;
	    //    	      end
            //       // Math-Logic-Shift-Immediate-64 class
	    //       7'b0011011:begin
	    //    	        case(ir[14:12]) // func3
	    //    	          3'b000: Addiw  <= 1'b0; // close Addiw  Flag 
	    //    	          3'b001: Slliw  <= 1'b0; // close Slliw  Flag 
	    //    		  3'b101: begin
	    //    		          case(ir[31:25]) // func7
	    //    		            7'b0000000: Srliw <= 1'b0; // close Srliw  Flag 
	    //    		            7'b0100000: Sraiw <= 1'b0; // close Sraiw  Flag 
	    //    		          endcase
	    //    		         end 
	    //    		endcase
	    //                      pc <= pc + 4;   // 程序计数器加一
	    //	                  jp <=0;
	    //                  end
            //       // Math-Logic-Shift-Register-64 class
	    //       7'b0111011:begin
	    //    	        case(ir[14:12]) // func3
	    //    		  3'b000: begin
	    //    		          case(ir[31:25]) // func7
	    //    		            7'b0000000: Addw  <= 1'b0; // close Addw  Flag 
	    //    		            7'b0100000: Subw  <= 1'b0; // close Subw  Flag 
	    //    		          endcase
	    //    		         end 
	    //    	          3'b001: Sllw  <= 1'b0; // close Sllw  Flag 
	    //    		  3'b101: begin
	    //    		          case(ir[31:25]) // func7
	    //    		            7'b0000000: Srlw  <= 1'b0; // close Srlw  Flag 
	    //    		            7'b0100000: Sraw  <= 1'b0; // close Sraw  Flag 
	    //    		          endcase
	    //    		         end 
	    //    		endcase
	    //                      pc <= pc + 4;   // 程序计数器加一
	    //	                  jp <=0;
	    //                  end
            //       // Jump
	    //       //e####
	    //       7'b1101111:begin
            //                    Jal <= 1'b0; // close Jal Flag 
	    //	                jp <=0;
            //                  end
            //       // RJump
	    //       7'b1100111:begin 
            //                    Jalr <= 1'b0; // close Jalr Flag 
	    //                    //pc <= pc + 1;   // 程序计数器加一
	    //	                jp <=0;
            //                  end
            //       // Branch class
	    //       7'b1100011:begin 
	    //    	        case(wire_f3) // func3
	    //    	          3'b000: Beq  <= 1'b0; // close Beq  Flag 
	    //    	          3'b001: Bne  <= 1'b0; // close Bne  Flag 
	    //    	          3'b100: Blt  <= 1'b0; // close Blt  Flag 
	    //    	          3'b101: Bge  <= 1'b0; // close Bge  Flag 
	    //    	          3'b110: Bltu <= 1'b0; // close Bltu Flag 
	    //    	          3'b111: Bgeu <= 1'b0; // close Bgeu Flag 
	    //    		endcase
	    //                      pc <= pc + 4;   // 程序计数器加一
	    //	                  jp <=0;
	    //                  end
            //       // Fence class
	    //       7'b0001111:begin 
	    //    	        case(ir[14:12]) // func3
	    //    	          3'b000: Fence  <= 1'b0; // close Fence Flag 
	    //    	          3'b001: Fencei <= 1'b0; // close Fencei Flag 
	    //    		endcase
	    //                      pc <= pc + 4;   // 程序计数器加一
	    //	                  jp <=0;
	    //                  end
            //       // Enverioment class
	    //       7'b1110011:begin 
	    //    	        case(ir[14:12]) // func3
	    //    		  3'b000: begin
	    //    		          case(ir[31:20]) // func12
	    //    		            12'b000000000000: Ecall  <= 1'b0; // close Ecall  Flag 
	    //    		            12'b000000000001: Ebreak <= 1'b0; // close Ebreak Flag 
	    //    		          endcase
	    //    		         end 
	    //    	          3'b001: Csrrw  <= 1'b0; // close Csrrw  Flag 
	    //    	          3'b010: Csrrs  <= 1'b0; // close Csrrs  Flag 
	    //    	          3'b011: Csrrc  <= 1'b0; // close Csrrc  Flag 
	    //    	          3'b101: Csrrwi <= 1'b0; // close Csrrwi Flag 
	    //    	          3'b110: Csrrsi <= 1'b0; // close Csrrsi Flag 
	    //    	          3'b111: Csrrci <= 1'b0; // close Csrrci Flag 
	    //    		endcase
	    //                      pc <= pc + 4;   // 程序计数器加一
	    //	                  jp <=0;
	    //                  end

	    //       endcase
	    //   end
	    endcase
        end
end
endmodule




//interrupte document
//https://www.reddit.com/r/RISCV/comments/fy09gs/riscv_interrupt_architecture/
//https://riscv.org/wp-content/uploads/2017/12/Tue1642_PLIC_Richard_Herveille.pdf
//https://domipheus.com/blog/designing-a-risc-v-cpu-in-vhdl-part-20-interrupts-and-exceptions/
//https://sifive.cdn.prismic.io/sifive%2F834354f0-08e6-423c-bf1f-0cb58ef14061_fu540-c000-v1.0.pdf
//https://cdn2.hubspot.net/hubfs/3020607/An%20Introduction%20to%20the%20RISC-V%
//20Architecture.pdf
//https://sifive.cdn.prismic.io/sifive/0d163928-2128-42be-a75a-464df65e04e0_sifive-interrupt-cookbook.pdf
//https://github.com/riscv/riscv-plic-spec/blob/master/riscv-plic.adoc
//https://five-embeddev.com/riscv-priv-isa-manual/Priv-v1.12/plic.html
//https://github.com/riscv/riscv-fast-interrupt

//whole core code
//https://sergeykhbr.github.io/riscv_vhdl/

//run linux example:
//https://riscv.org/wp-content/uploads/2019/12/12.10-12.50-RISC-V_Summit_Fu_Wei_.pdf
