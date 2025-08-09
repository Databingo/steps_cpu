// 声明指令控制线
reg Lui, Auipc, Lb, Lbu, Lh, Lhu, Lw, Lwu, Ld, Sb, Sh, Sw, Sd, Add, Sub, Sll, Slt, Sltu, Xor, Srl, Sra, Or, And, Addi, Slti, Sltiu, Ori, Andi, Xori, Slli, Srli, Srai, Addiw, Slliw, Srliw, Sraiw, Addw, Subw, Sllw, Srlw, Sraw, Jal, Jalr, Beq, Bne, Blt, Bge, Bltu, Bgeu, Fence, Fencei, Ecall, Ebreak, Csrrw, Csrrs, Csrrc, Csrrwi, Csrrsi, Csrrci;


localparam M_mode = 2'b11;
localparam S_mode = 2'b01;
localparam U_mode = 2'b00;
reg [1:0] current_privilege_mode;

// CSR pre 00 user 01 super 10 hyper 11 machine
// Supervisor Trap Setup
integer sstatus = 12'h100; // 63_SD|WPRI|33:32_UXL10|WPRI|19_MXR|18_SUM|17_WPRI|16:15_XS10|14:13_FS10|WPRI|8_SPP|7_WPRI|6_UBE|5_SPIE|WPRI|1_SIE|0_WPRI
integer sedeleg = 12'h102;
integer sideleg = 12'h103;
integer sie = 12'h104;   // Supervisor interrupt-enable register
integer stvec = 12'h105; // Supervisor Trap Vector Base Address//63-2_BASE|1-0_MODE|(auto padding last 00 base) Mode:00direct to base<<2; 01vectord to base if ecall base+4*scause[62:0] if interrupt;10,11
integer scounteren = 12'h106; //Supervisor counter enable
// Supervisor Trap Handling
integer sscratch = 12'h140;
integer sepc = 12'h141; //
integer scause = 12'h142;//  //63_type 0exception 1interrupt|value
integer stval = 12'h143; 
integer sip = 12'h144; // Supervisor interrupt pending
// Supervisor Protection and Translation
integer satp = 12'h180; // Supervisor address translation and protection
// Debug/Trace Registers
integer scontext = 12'h5a8; // Supervisor-mode context register

// Machine Information Registers
integer mvendorid = 12'hF11;    // 0xF11 MRO Vendor ID
integer marchid= 'hF12; 	// 0xF12 MRO Architecture ID
integer mimpid= 'hF13; 	        // 0xF13 MRO Implementation ID
integer mhartid= 'hF14; 	// 0xF14 MRO Hardware thread ID
integer mconfigptr= 'hF11; 	// 0xF15 MRO Pointer to configuration data structure
// Machine Trap Setup
integer mstatus = 12'h300;     // 0x300 MRW Machine status reg   // 63_SD|37_MBE|36_SBE|35:34_SXL10|22_TSR|21_TW|20_TVW|17_MPRV|12:11_MPP10|7_MPIE|3_MIE|1_SIE|0_WPRI
integer misa = 12'h301;         // 0x301 MRW ISA and extensions
integer medeleg = 12'h302;      // 0x302 MRW Machine exception delegation register
integer mideleg = 12'h303;      // 0x303 MRW Machine interrupt delegation register
integer mie = 12'h304;          // 0x304 MRW Machine interrupt-enable register *
integer mtvec = 12'h305;        // 0x305 MRW Machine trap-handler base address *
integer mcounteren = 12'h306;   // 0x306 MRW Machine counter enable
integer mtvt = 12'h307;         // 0x307 MRW Machine Trap-Handler vector table base address
integer mstatush = 12'h310;     // 0x310 MRW Additional machine status register, RV32 only
// Machine Trap Handling
integer mscratch = 12'h340;     // 0x340 MRW Scratch register for machine trap handlers *
integer mepc = 12'h341;         // 0x341 MRW Machine exception program counter *
integer mcause = 12'h342;       // 0x342 MRW Machine trap casue *
integer mtval =12'h343;         // 0x343 MRW Machine bad address or instruction *
integer mip = 12'h344;          // 0x344 MRW Machine interrupt pending *
integer mtinst = 12'h34A;       // 0x34A MRW Machine trap instruction (transformed)
integer mtval2 = 12'h34B;       // 0x34B MRW Machine bad guset physical address
// Machine Configuration
integer menvcfg = 12'h30A;      // 0x30A MRW Machine environment configuration register
integer menvcfgh = 12'h31A;     // 0x31A MRW Additional machine env. conf. register, RV32 only
integer mseccfg = 12'h747;      // 0x747 MRW Machine security configuration register
integer mseccfgh = 12'h757;     // 0x757 MRW Additional machine security conf. register, RV32 only



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

	12'h100: csr_index = 5'd31;	                           // 0x3AF MRW pmpcfg15  





   
   
   
    default: csr_index = 5'b00000;
  endcase
 end
endfunction

reg [4:0] csr_id; 
reg [11:0] csr_nu; 

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
reg [7:0] irom [0:9999];// 8 位宽度，400 行深度
// 数据存储器
reg [7:0] drom [0:9999];// 8 位宽度，400 行深度
// 堆栈存储器
reg [7:0] srom [0:399];// 8 位宽度，400 行深度

// 通用寄存器列表 32 个
reg [63:0] rram [0:31];// 64 位宽度，32 行深度 x0, x1, x2... x31
// CSR 寄存器列表 4096 个(预设个数 2**12=4096)
reg [63:0] csrram [0:4096];// 64 位宽度，4096 行深度

// --- 3 input---
input reset_n; // 初始化开关
input clock;  // 时钟 // 计数工具
// irom as program input of model

reg [63:0] pc; // 程序计数寄存器 64 位宽度
reg [2:0] jp;  // 程序节寄存拍器

// 程序指令寄存器: 32 位宽度
reg [31:0] ir; 


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
assign wire_jimm  = {wire_ir[31], wire_ir[19:12], wire_ir[20], wire_ir[30:21], 1'b0}; // read immediate & padding last 0, total 20 + 1 = 21 bits
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
initial $readmemb("./binary_instructions.txt", irom);
//initial $readmemb("./firmware.out", irom);
//initial $readmemb("./data.txt", drom);
//initial $readmemh("./data_lb.txt", drom);
initial $readmemh("./data_test.txt", drom);

reg [63:0] sum; // 加法结果组合逻辑寄存器
reg [63:0] sum_imm; // 加法结果组合逻辑寄存器
reg [31:0] sum_imm_32; // 32位加法结果组合逻辑寄存器
reg [63:0] mirro_rs2; // rs2 相反数，取反加一，减法变加法用
reg [63:0] mirro_imm; // imm 相反数，取反加一，减法变加法用
reg [63:0] sub; // 减法结果组合逻辑寄存器
reg [63:0] sub_imm; // 减法结果组合逻辑寄存器
reg [63:0] sign_extended_bimm; // 符号扩展的 bimm (branch imm)
reg [31:0] slliw_s1; // 逻辑左移word
reg [31:0] srliw_s1; // 算数左移word
reg [31:0] sraiw_s1; // 算数右移word

// 组合逻辑（电路即时生效,无需等待时钟周期）
always @(*)
begin
 sum = rram[wire_rs1] + rram[wire_rs2];
 sum_imm = rram[wire_rs1] + {{52{wire_imm[11]}}, wire_imm};
 sum_imm_32 = rram[wire_rs1][31:0] + {{20{wire_imm[11]}}, wire_imm};
 mirro_rs2 = ~rram[wire_rs2] + 1;
 mirro_imm = ~{{52{wire_imm[11]}}, wire_imm} + 1;
 sub = rram[wire_rs1] + mirro_rs2;
 sub_imm = rram[wire_rs1] + mirro_imm;
 sign_extended_bimm = {{51{wire_ir[31]}}, wire_bimm};  //bimm is 13 bits length
 slliw_s1 = rram[wire_rs1][31:0] << wire_shamt[4:0]; 
 srliw_s1 = rram[wire_rs1][31:0] >> wire_shamt[4:0]; 
 sraiw_s1 = $signed(rram[wire_rs1][31:0]) >>> wire_shamt[4:0]; 
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
	  rram[1] <=0; rram[2] <=0; rram[3] <=0; rram[30] <=0; rram[31] <=0;
	  for (integer i = 0; i < 32; i = i + 1)  //!!初始化零否则新启用寄存器就不灵
	      rram[i] <= 64'h0;
	      current_privilege_mode <= M_mode; // init from M-mode for all RISCV processor
	end
	else
        // 开始指令节拍  // Did every circle have to clean registers like upper !! initial?
	begin
	    case(jp)
	    0: begin // 取指令 + 分析指令 + 执行 | 或 准备数据 (分析且备好该指令所需的数据）
	 	   //current_privilege_mode <= current_privilege_mode; // update mode
	    	   ir <= wire_ir ; 
		   // parse: op->func3->func7
	    	   //case(wire_op)
	    	   case(wire_ir)
                   // Load-class
		   //7'b0110111:begin
		   //             Lui <= 1'b1; // set Lui Flag
		   //     	//put 20 bits immediate to upper 20 bits of rd left lower 12 bits 0, sext to 64
		   //     	rram[wire_rd] <= {{32{wire_upimm[19]}}, wire_upimm, 12'b0};
		   //     	pc <= pc + 4; 
	    	   //             jp <=0;
		   //           end
	           32'b????????????????????_?????_0110111: begin rram[wire_rd] <= {{32{wire_upimm[19]}}, wire_upimm, 12'b0}; end // Lui
		   //7'b0010111:begin
		   //             Auipc <= 1'b1; // set Auipc Flag
		   //     	//left shift 20 bits immediate 12bits sext to 64 add pc then put to rd
		   //     	rram[wire_rd] <= pc + {{32{wire_upimm[19]}}, wire_upimm, 12'b0};
		   //     	pc <= pc + 4; 
	    	   //             jp <=0;
		   //end
		   32'b????????????????????_?????_0010111: begin rram[wire_rd] <= pc + {{32{wire_upimm[19]}}, wire_upimm, 12'b0}; end // Auipc
		   //7'b0000011:begin
	    	   //             case(wire_f3) // func3 case(ir[14:12])
		   //     	  3'b000:begin 
		   //     	           //lb/lbu/lh/lhu/lw/lwu/ld rd, rs1, simm12  
		   //     	           Lb  <= 1'b1; // set Lb  Flag 
		   //     	           //load 8 bite sign extend to 64 bits at imm(s1) to rd
		   //     	           rram[wire_rd] <= {{56{drom[rram[wire_rs1]+ {{52{wire_imm[11]}},wire_imm}][7]}}, 
		   //     		                         drom[rram[wire_rs1]+ {{52{wire_imm[11]}},wire_imm}]}; 
		   //     	           //rram[wire_rd] <= 48;
		   //     	           pc <= pc + 4; 
	    	   //                        jp <=0;
		   //     	         end 
		   32'b????????????_?????_000_?????_0000011: begin rram[wire_rd] <= {{56{drom[rram[wire_rs1]+ {{52{wire_imm[11]}},wire_imm}][7]}}, 
		                                                                         drom[rram[wire_rs1]+ {{52{wire_imm[11]}},wire_imm}]};end  // Lb
		//		  3'b100:begin 
		//		           Lbu  <= 1'b1; // set Lbu  Flag 
		//		           //load 8 bite unsign to 64 bits at imm(s1) to rd
		//		           rram[wire_rd] <= {56'b0, drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}]}; 
		//		           pc <= pc + 4; 
	    	//                           jp <=0;
		//		         end 
		   32'b????????????_?????_100_?????_0000011: begin rram[wire_rd] <= {56'b0, drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}]}; end // Lbu
		//		  3'b001:begin 
                //                           Lh  <= 1'b1; // set Lh  Flag 
		//		           //load 16 bite sign extend to 64 bits at imm(s1) to rd
		//		           rram[wire_rd] <= {{48{drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+ 1][7]}}, 
		//			                         drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+ 1], 
		//						 drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}] }; 
		//		           pc <= pc + 4; 
	    	//                           jp <=0;
		//		         end 
		   32'b????????????_?????_001_?????_0000011: begin rram[wire_rd] <= {{48{drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+ 1][7]}}, 
					                                                 drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+ 1], 
											 drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}] }; end // Lh
		//		  3'b101:begin 
                //                           Lhu <= 1'b1; // set Lhu Flag  
		//		           //load 16 bite unsign to 64 bits at imm(s1) to rd
		//		           rram[wire_rd] <= {48'b0, drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+ 1], 
		//			                            drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}]}; 
		//		           pc <= pc + 4; 
	    	//                           jp <=0;
		//		         end 
		   32'b????????????_?????_101_?????_0000011: begin rram[wire_rd] <= {48'b0, drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+ 1], 
		                                                                            drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}]}; end // Lhu
		//		  3'b010:begin 
                //                           Lw  <= 1'b1; // set Lw  Flag
		//			   //load 32 bite sign extend to 64 bits at imm(s1) to rd
	        //                           rram[wire_rd] <= {{32{drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+ 3][7]}}, 
	        //                                                 drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+3], 
	        //                         			 drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+2], 
	        //                         			 drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+1], 
	        //                         			 drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}]}; 
		//		           pc <= pc + 4; 
	    	//                           jp <=0;
		//		         end 
		   32'b????????????_?????_010_?????_0000011: begin rram[wire_rd] <= {{32{drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+ 3][7]}}, 
	                                                         drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+3], 
	                                 			 drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+2], 
	                                 			 drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+1], 
								 drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}]}; end // Lw
		//		  3'b110:begin 
                //                           Lwu <= 1'b1; // set Lwu Flag 
		//			   //load 32 bite unsign to 64 bits at imm(s1) to rd
	        //                           rram[wire_rd] <= {32'b0, drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+3], 
	        //                                                    drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+2], 
	        //                                                    drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+1], 
	        //                                                    drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}]}; 
		//		           pc <= pc + 4; 
	    	//                           jp <=0;
		//		         end 
		   32'b????????????_?????_110_?????_0000011: begin rram[wire_rd] <= {32'b0, drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+3], 
	                                                            drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+2], 
	                                                            drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+1], 
								    drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}]}; end // Lwu
		//		  3'b011:begin 
                //                           Ld  <= 1'b1; // set Ld  Flag 
		//			   //load 64 bite sign to 64 bits at imm(s1) to rd
	        //                           rram[wire_rd] <= {drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+7], 
	        //                                             drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+6], 
	        //                                             drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+5], 
	        //                                             drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+4],
	        //                                             drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+3], 
	        //                                             drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+2], 
	        //                                             drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+1], 
	        //                                             drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}  ]}; 
		//		           pc <= pc + 4; 
	    	//                           jp <=0;
		//		         end 
		//	        endcase
		//              end 
		   32'b????????????_?????_011_?????_0000011: begin rram[wire_rd] <= {drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+7], 
	                                                     drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+6], 
	                                                     drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+5], 
	                                                     drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+4],
	                                                     drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+3], 
	                                                     drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+2], 
	                                                     drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}+1], 
							     drom[rram[wire_rs1]+{{52{wire_imm[11]}},wire_imm}  ]}; end // Ld
                   // Store-class  // ld and sb are different direction: 
		   // lb rd,  imm(rs1); rd  <- rs1+imm
		   // sb rs2, imm(rs1); rs2 -> rs1+imm
	        //   7'b0100011:begin
	    	//                case(wire_f3) // func3 case(ir[14:12])
		//		  3'b000:begin 
		//		           //sb/sh/sw rs2, rs1, simm12  
		//			   //store byte, write low 8 bits of rs2 to rs1's imm.12
		//		           Sb  <= 1'b1; // set Sb  Flag 
		//			   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}] <= rram[wire_rs2][7:0];
		//		           pc <= pc + 4; 
	    	//                           jp <=0;
		//		         end 
		   32'b????????????_?????_000_?????_0100011: begin drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}] <= rram[wire_rs2][7:0]; end // Sb
		//		  3'b001:begin 
		//		           //store half word, write low 16 bits of rs2 to rs1's imm.12 
		//		           Sh  <= 1'b1; // set Sh  Flag 
		//			   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}] <= rram[wire_rs2][7:0];
		//			   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+1] <= rram[wire_rs2][15:8];
		//		           pc <= pc + 4; 
	    	//                           jp <=0;
		//		         end 
		   32'b????????????_?????_001_?????_0100011: begin drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}] <= rram[wire_rs2][7:0];
		                                                   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+1] <= rram[wire_rs2][15:8]; end // Sh
		//		  3'b010:begin 
		//		           //store word, write low 16 bits of rs2 to rs1's imm.12
		//		           Sw  <= 1'b1; // set Sw  Flag  
		//			   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}] <= rram[wire_rs2][7:0];
		//			   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+1] <= rram[wire_rs2][15:8];
		//			   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+2] <= rram[wire_rs2][23:16];
		//			   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+3] <= rram[wire_rs2][31:24];
		//		           pc <= pc + 4; 
	    	//                           jp <=0;
		//		         end 
		   32'b????????????_?????_010_?????_0100011: begin drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}] <= rram[wire_rs2][7:0];
					   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+1] <= rram[wire_rs2][15:8];
					   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+2] <= rram[wire_rs2][23:16];
					   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+3] <= rram[wire_rs2][31:24]; end // Sw
		//		  3'b011:begin 
		//		           //store double words, write 64 bits of rs2 to rs1's imm.12
		//		           Sd  <= 1'b1; // set Sd  Flag  
		//			   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}] <= rram[wire_rs2][7:0];
		//			   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+1] <= rram[wire_rs2][15:8];
		//			   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+2] <= rram[wire_rs2][23:16];
		//			   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+3] <= rram[wire_rs2][31:24];
		//			   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+4] <= rram[wire_rs2][39:32];
		//			   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+5] <= rram[wire_rs2][47:40];
		//			   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+6] <= rram[wire_rs2][55:48];
		//			   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+7] <= rram[wire_rs2][63:56];
		//		           pc <= pc + 4; 
	    	//                           jp <=0;
		//		         end 
		//		endcase
		//	      end
		   32'b????????????_?????_011_?????_0100011: begin drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}] <= rram[wire_rs2][7:0];
					   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+1] <= rram[wire_rs2][15:8];
					   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+2] <= rram[wire_rs2][23:16];
					   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+3] <= rram[wire_rs2][31:24];
					   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+4] <= rram[wire_rs2][39:32];
					   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+5] <= rram[wire_rs2][47:40];
					   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+6] <= rram[wire_rs2][55:48];
					   drom[rram[wire_rs1]+{{52{wire_simm[11]}},wire_simm}+7] <= rram[wire_rs2][63:56]; end // Sd
                   // Math-Logic-Shift-Register class
	        //   7'b0110011:begin 
		//	        case(wire_f3) // func3
		//		  3'b000:begin
		//		          case(wire_f7) // func7
		//		            7'b0000000:begin 
		//		                     Add  <= 1'b1; // set Add Flag
		//				      // 执行加法:
		//		                     rram[wire_rd] <= rram[wire_rs1] + rram[wire_rs2]; 
		//				      
		//		                     if ((rram[wire_rs1][63] ~^ rram[wire_rs2][63]) && (rram[wire_rs1][63] ^ sum[63])) 
		//				     begin
	    	//                                      rram[3] <= 1; // 溢出标志
	    	//                                      rram[4] <= rram[wire_rs1][63]; // 溢出值
		//				     end
		//		                     pc <= pc + 4; 
	    	//                                     jp <=0;
		//		                   end 
		   32'b0000000_?????_?????_000_?????_0110011: begin rram[wire_rd] <= rram[wire_rs1] + rram[wire_rs2]; 
						     // 溢出判断：
				                     if ((rram[wire_rs1][63] ~^ rram[wire_rs2][63]) && (rram[wire_rs1][63] ^ sum[63])) 
						      begin // 溢出标志
	    	                                      rram[3] <= 1; rram[4] <= rram[wire_rs1][63]; // 溢出值
						      end
						     end  // Add
		//			    7'b0100000:begin
		//		                     Sub  <= 1'b1; // set Sub Flag  
		//		                     rram[wire_rd] <= sub;
		//				     // 溢出判断：
		//		                     if ((rram[wire_rs1][63] ~^ mirro_rs2 [63]) && (rram[wire_rs1][63] ^ sub[63])) 
		//				     begin
	    	//                                      rram[3] <= 1; // 溢出标志
	    	//                                      rram[4] <= rram[wire_rs1][63]; // 溢出值
		//				     end
		//		                     pc <= pc + 4; 
	    	//                                     jp <=0;
		//		                   end 
		//		          endcase
		//		        end 
		   32'b0100000_?????_?????_000_?????_0110011: begin rram[wire_rd] <= sub;
						     // 溢出判断：
				                     if ((rram[wire_rs1][63] ~^ mirro_rs2 [63]) && (rram[wire_rs1][63] ^ sub[63])) 
						     begin// 溢出标志
	    	                                      rram[3] <= 1; rram[4] <= rram[wire_rs1][63]; // 溢出值
						     end
						     end // Sub
		//		  3'b010:begin 
		//		           Slt  <= 1'b1; // set Slt Flag 
		//		           // if rs1 less than rs2 both as sign-extended then put 1 in rd else 0
		//			   // 电路方式: 一周期实现比较 
		//			   // 计算 rs1 - rs2 < 0  转化 Sub -> Add
		//			   // 同号相加, 号即大小: 1: rs1 小于 rs2
		//			    if ((rram[wire_rs1][63] ~^ mirro_rs2[63]) && rram[wire_rs1][63] == 1)
                //                                     rram[wire_rd] <= 1'b1; 
		//			   // 异号相加, 果即大小 |1: rs1 小于 rs2 |000: 相等 |0xxx: rs1 大于 rs2
		//			    else if ((rram[wire_rs1][63] ^ mirro_rs2[63]) && (sub[63] == 1))
                //                                     rram[wire_rd] <= 1'b1; 
                //                           // 否则 rs1 大于 rs2
		//			    else rram[wire_rd] <= 1'b0;
		//			   // 代码模式 
		//			   // if (rram[wire_rs1] - rram[wire_rs2] < 0 ) rram[wire_rd] <= 1'b1; 
		//		           pc <= pc + 4; 
	    	//                           jp <=0;
		//		         end 
		   //32'b0000000_?????_?????_010_?????_0110011: begin 
		   32'b???????_?????_?????_010_?????_0110011: begin 
					    if ((rram[wire_rs1][63] ~^ mirro_rs2[63]) && rram[wire_rs1][63] == 1)
                                                     rram[wire_rd] <= 1'b1; 
					    else if ((rram[wire_rs1][63] ^ mirro_rs2[63]) && (sub[63] == 1))
                                                     rram[wire_rd] <= 1'b1; 
					    else rram[wire_rd] <= 1'b0;
					    end // Slt
			//	    3'b011:begin 
			//	           Sltu <= 1'b1; // set Sltu Flag  
			//	           // if rs1 less than rs2 both as unsign then put 1 in rd else 0
			//		   if (rram[wire_rs1] < rram[wire_rs2]) rram[wire_rd] <= 1'b1; 
			//		   else rram[wire_rd] <= 1'b0;
			//	           pc <= pc + 4; 
	    	        //                   jp <=0;
			//	         end 
		   32'b???????_?????_?????_011_?????_0110011: begin if (rram[wire_rs1] < rram[wire_rs2]) rram[wire_rd] <= 1'b1; else rram[wire_rd] <= 1'b0; end // Sltu
			//	    3'b110:begin
			//		   Or   <= 1'b1; // set Or Flag 
                        //                   // bitwise OR  rs1 and rs2 then put reslut in rd
			//		   rram[wire_rd] <= (rram[wire_rs1] | rram[wire_rs2]); 
			//	           pc <= pc + 4; 
	    	        //                   jp <=0;
			//		   end
		   32'b???????_?????_?????_110_?????_0110011: begin rram[wire_rd] <= (rram[wire_rs1] | rram[wire_rs2]); end // Or
			//	   3'b111:begin 
			//		   And  <= 1'b1; // set And Flag 
                        //                   // bitwise AND  rs1 and rs2 then put reslut in rd
			//		   rram[wire_rd] <= (rram[wire_rs1] & rram[wire_rs2]); 
			//	           pc <= pc + 4; 
	    	        //                   jp <=0;
			//		   end
		   32'b???????_?????_?????_111_?????_0110011: begin rram[wire_rd] <= (rram[wire_rs1] & rram[wire_rs2]); end // And
			//	   3'b100:begin 
			//		   Xor  <= 1'b1; // set Xor Flag
                        //                   // bitwise XOR  rs1 and rs2 then put reslut in rd
			//		   rram[wire_rd] <= (rram[wire_rs1] ^ rram[wire_rs2]); 
			//	           pc <= pc + 4; 
	    	        //                   jp <=0;
			//		   end
		   32'b???????_?????_?????_100_?????_0110011: begin rram[wire_rd] <= (rram[wire_rs1] ^ rram[wire_rs2]); end // Xor
			//	    3'b001:begin 
			//	           Sll  <= 1'b1; // set Sll Flag 
			//		   // shift lift  logicl rs1 by rs2's value [low5/6.unsign] padding 0 to rd
			//		   rram[wire_rd] <= rram[wire_rs1] << rram[wire_rs2][5:0]; 
			//	           pc <= pc + 4; 
	    	        //                   jp <=0;
			//		   end
		   32'b???????_?????_?????_001_?????_0110011: begin rram[wire_rd] <= rram[wire_rs1] << rram[wire_rs2][5:0]; end // Sll
			//	  3'b101:begin 
			//	          case(wire_f7) // func7
			//		    7'b0000000:begin
			//		               Srl  <= 1'b1; // set Srl Flag 
			//		               // shift right logicl rs1 by rs2[low5/6.unsign] padding 0 to rd
			//		               rram[wire_rd] <= (rram[wire_rs1] >> rram[wire_rs2][5:0]); 
			//	                       pc <= pc + 4; 
	    	        //                               jp <=0;
			//			       end
	           32'b0000000_?????_?????_101_?????_0110011: begin rram[wire_rd] <= (rram[wire_rs1] >> rram[wire_rs2][5:0]); end // Srl
			//		    7'b0100000:begin 
			//		               Sra  <= 1'b1; // set Sra Flag  
			//		               // shift right arithmatical rs1 by imm.12[low5.unsign] padding 0 to rd
			//		               rram[wire_rd] <= ($signed(rram[wire_rs1]) >>> rram[wire_rs2][5:0]); 
			//	                       pc <= pc + 4; 
	    	        //                               jp <=0;
			//			       end
			//	          endcase
			//	         end 
			//	endcase
			//      end
		   32'b0100000_?????_?????_101_?????_0110011: begin rram[wire_rd] <= ($signed(rram[wire_rs1]) >>> rram[wire_rs2][5:0]); end // Sra
                   // Math-Logic-Shift-Immediate class
	        ///   7'b0010011:begin 
		///	        case(wire_f3) // func3
		///		  3'b000:begin
		///		         Addi  <= 1'b1; // set Addi  Flag 
		///		         //sign-extend imm.12 to 64 add to sr1, send overflow ingnored result to rd 
		///		         // 执行加法:
		///		         rram[wire_rd] <= rram[wire_rs1] + {{52{wire_imm[11]}}, wire_imm}; 
		///		         // 溢出判断：
		///		         if ((rram[wire_rs1][63] ~^ wire_imm[11]) && (rram[wire_rs1][63] ^ sum_imm[63])) 
		///		           begin
	    	///                           rram[3] <= 1; // 溢出标志
	    	///                           rram[4] <= rram[wire_rs1][63]; // 溢出值
		///		           end
		///		         pc <= pc + 4; 
	    	///                         jp <=0;
		///		         end
		   32'b????????????_?????_000_?????_0010011: begin rram[wire_rd] <= rram[wire_rs1] + {{52{wire_imm[11]}}, wire_imm}; 
				         if ((rram[wire_rs1][63] ~^ wire_imm[11]) && (rram[wire_rs1][63] ^ sum_imm[63])) 
				           begin // 溢出标志
	    	                           rram[3] <= 1; rram[4] <= rram[wire_rs1][63]; // 溢出值
				           end
				           end // Addi
		//		 3'b010:begin
		//			  Slti  <= 1'b1; // set Slti  Flag 
		//		           // if rs1 is less than imm.12 both as sign-extended then put 1 in rd else 0
		//			   // 电路方式: 一周期实现比较 
		//			   // 计算 rs1 - imm < 0  转化 Sub -> Add
		//			   // 同号相加, 号即大小: 1: rs1 小于 imm 
		//			    if ((rram[wire_rs1][63] ~^ mirro_imm[63]) && rram[wire_rs1][63] == 1)
                //                                     rram[wire_rd] <= 1'b1; 
		//			   // 异号相加, 果即大小：1: rs1 小于 imm
		//			    else if ((rram[wire_rs1][63] ^ mirro_imm[63]) && (sub_imm[63] == 1))
                //                                     rram[wire_rd] <= 1'b1; 
                //                           // 否则 rs1 大于 imm 
		//			    else rram[wire_rd] <= 1'b0;
		//			   // 代码模式 
		//			   // if (rram[wire_rs1] - imm < 0 ) rram[wire_rd] <= 1'b1; 
		//		           pc <= pc + 4; 
	    	//                           jp <=0;
		//		         end 
		   32'b????????????_?????_010_?????_0010011: begin if ((rram[wire_rs1][63] ~^ mirro_imm[63]) && rram[wire_rs1][63] == 1)
                                                     rram[wire_rd] <= 1'b1; 
					    else if ((rram[wire_rs1][63] ^ mirro_imm[63]) && (sub_imm[63] == 1))
                                                     rram[wire_rd] <= 1'b1; 
					    else rram[wire_rd] <= 1'b0;
					    end // Slti
			//	 3'b011:begin
			//		   Sltiu <= 1'b1; // set Sltiu Flag 
			//	           // if rs1 less than imm both as unsign then put 1 in rd else 0
			//		   if (rram[wire_rs1] < {{52{wire_imm[11]}}, wire_imm} ) rram[wire_rd] <= 1'b1; 
			//		   else rram[wire_rd] <= 1'b0; 
			//	           pc <= pc + 4; 
	    	        //                   jp <=0;
			//	         end 
		   32'b????????????_?????_011_?????_0010011: begin if (rram[wire_rs1] < {{52{wire_imm[11]}}, wire_imm} ) rram[wire_rd] <= 1'b1; else rram[wire_rd] <= 1'b0; end // Sltiu
			//	 3'b110:begin 
			//	           Ori   <= 1'b1; // set Ori   Flag 
                        //                   // bitwise OR  rs1 and sign-extend imm.12 put reslut in rd
			//		   rram[wire_rd] <= (rram[wire_rs1] | {{52{wire_imm[11]}}, wire_imm}); 
			//	           pc <= pc + 4; 
	    	        //                   jp <=0;
			//		   end
		   32'b????????????_?????_110_?????_0010011: begin rram[wire_rd] <= (rram[wire_rs1] | {{52{wire_imm[11]}}, wire_imm}); end // Ori
			//	 3'b111:begin 
			//	           Andi  <= 1'b1; // set Andi  Flag 
                        //                   // bitwise AND rs1 and sign-extend imm.12 put reslut in rd
			//		   rram[wire_rd] <= (rram[wire_rs1] & {{52{wire_imm[11]}}, wire_imm}); 
			//	           pc <= pc + 4; 
	    	        //                   jp <=0;
			//		   end
		   32'b????????????_?????_111_?????_0010011: begin rram[wire_rd] <= (rram[wire_rs1] & {{52{wire_imm[11]}}, wire_imm}); end // Andi
			//	 3'b100:begin 
			//	           Xori  <= 1'b1; // set Xori  Flag 
                        //                   // bitwise XORI  rs1 and rs2 then put reslut in rd
			//		   rram[wire_rd] <= (rram[wire_rs1] ^ {{52{wire_imm[11]}}, wire_imm}); 
			//	           pc <= pc + 4; 
	    	        //                   jp <=0;
			//		   end
		   32'b????????????_?????_100_?????_0010011: begin rram[wire_rd] <= (rram[wire_rs1] ^ {{52{wire_imm[11]}}, wire_imm}); end // Xori
			//	 3'b001:begin// func3 001 for left 
			//		   Slli  <= 1'b1; // set Slli  Flag  // 32-->64 one more bit
			//		   // shift lift  logicl rs1 by imm.12[low6.unsign] padding 0 to rd
			//		   rram[wire_rd] <= (rram[wire_rs1] << wire_shamt ); 
			//	           pc <= pc + 4; 
	    	        //                   jp <=0;
			//		   end
		   32'b????????????_?????_001_?????_0010011: begin rram[wire_rd] <= (rram[wire_rs1] << wire_shamt ); end // Slli
			//	  3'b101: begin // func3 101 for right
			//	          case(wire_f7[6:1]) // func7->6 // rv64 shame take wire_f7[0]
			//		  //7'b0000000:begin
			//		    7'b000000:begin
			//		               Srli  <= 1'b1; // set Srli  Flag // 32-->64 one more bit64
			//		               // shift right logicl rs1 by imm.12[low6.unsign] padding 0 to rd
			//		               rram[wire_rd] <= (rram[wire_rs1] >> wire_shamt ); 
			//	                       pc <= pc + 4; 
	    	        //                               jp <=0;
			//			       end
		   32'b000000?_?????_?????_101_?????_0010011: begin rram[wire_rd] <= (rram[wire_rs1] >> wire_shamt ); end // Srli // func7->6 // rv64 shame take wire_f7[0]
		//			   //7'b0100000:begin 
		//			     7'b010000:begin 
		//			               Srai  <= 1'b1; // set Srai  Flag // 32-->64 one more bit64
		//			               // shift right arithmatical rs1 by imm.12[low6.unsign] padding?
		//			               rram[wire_rd] <= ($signed(rram[wire_rs1]) >>> wire_shamt ); 
		//		                       pc <= pc + 4; 
	    	//                                       jp <=0;
		//				       end
		//		          endcase
		//		         end 
		//		endcase
		//	      end
		   32'b010000?_?????_?????_101_?????_0010011: begin rram[wire_rd] <= ($signed(rram[wire_rs1]) >>> wire_shamt ); end // Srai
                   // Math-Logic-Shift-Immediate-64 class
	        //   7'b0011011:begin 
		//	        case(wire_f3) // func3
		//		  3'b000: begin
		//		         Addiw  <= 1'b1; // set Addiw  Flag 
		//		         //sign-extend imm.12 to 32 add to sr1.low32, sign-extend to 64 to rd 
		//		         rram[wire_rd] <=   {{32{sum_imm_32[31]}}, rram[wire_rs1][31:0] + {{20{wire_imm[11]}}, wire_imm}}; 
		//		         pc <= pc + 4; 
	    	//                         jp <=0;
		//		         end
		   32'b???????_?????_?????_000_?????_0011011: begin rram[wire_rd] <=   {{32{sum_imm_32[31]}}, rram[wire_rs1][31:0] + {{20{wire_imm[11]}}, wire_imm}}; end // Addiw
			// 	 3'b001:begin// func3 001 for left 
			// 		   Slliw  <= 1'b1; // set Slliw  Flag  
			// 		   // shift lift  logicl rs1.low32 by imm.12[low5.unsign] padding 0 to rd
			// 		   rram[wire_rd] <= {{32{slliw_s1[31]}}, slliw_s1[31:0]};
			// 	           pc <= pc + 4; 
	    	        //                    jp <=0;
			// 		   end
		   32'b???????_?????_?????_001_?????_0011011: begin rram[wire_rd] <= {{32{slliw_s1[31]}}, slliw_s1[31:0]}; end // Slliw
			//	  3'b101: begin
			//	          case(wire_f7) // func7
			//		      7'b0000000:begin 
			//			Srliw  <= 1'b1; // set Srliw  Flag 
			//		        rram[wire_rd] <= {{32{srliw_s1[31]}}, srliw_s1[31:0]};
			//	                pc <= pc + 4; 
	    	        //                        jp <=0;
			//		        end
		   32'b0000000_?????_?????_101_?????_0011011: begin rram[wire_rd] <= {{32{srliw_s1[31]}}, srliw_s1[31:0]}; end // Srliw
		//			      7'b0100000:begin 
		//				Sraiw <= 1'b1; // set Sraiw  Flag 
		//			        rram[wire_rd] <= {{32{sraiw_s1[31]}}, sraiw_s1[31:0]};
		//		                pc <= pc + 4; 
	    	//                                jp <=0;
		//			        end
		//		          endcase
		//		         end 
		//		endcase
		//              end
		   32'b0100000_?????_?????_101_?????_0011011: begin rram[wire_rd] <= {{32{sraiw_s1[31]}}, sraiw_s1[31:0]}; end // Sraiw
                   // Math-Logic-Shift-Register-64 class
	        //   7'b0111011:begin 
		//	        case(wire_f3) // func3
		//		  3'b000: begin
		//		          case(wire_f7) // func7
		//			      7'b0000000: begin 
		//			                  Addw  <= 1'b1; // set Addw  Flag 
		//		                          rram[wire_rd] <= {{32{sum[31]}}, rram[wire_rs1][31:0] + rram[wire_rs2][31:0]}; 
		//		                          pc <= pc + 4; 
	    	//                                          jp <=0;
		//				          end
		   32'b0000000_?????_?????_000_?????_0111011: begin rram[wire_rd] <= {{32{sum[31]}}, rram[wire_rs1][31:0] + rram[wire_rs2][31:0]}; end // Addw
				//	      7'b0100000: begin
				//			  Subw  <= 1'b1; // set Subw  Flag 
				//                          rram[wire_rd] <= {{32{sub[31]}}, rram[wire_rs1][31:0] - rram[wire_rs2][31:0]}; 
				//                          pc <= pc + 4; 
	    	                //                          jp <=0;
				//		          end
				//          endcase
				//         end 
		   32'b0100000_?????_?????_000_?????_0111011: begin rram[wire_rd] <= {{32{sub[31]}}, rram[wire_rs1][31:0] - rram[wire_rs2][31:0]}; end // Subw
				//  3'b001: begin
				//           Sllw  <= 1'b1; // set Sllw Flag 
				//	   // shift lift  logicl rs1.32 by rs2's value [low5.unsign], take the l32 sext to 64 put into rd
				//	   rram[wire_rd] <= {{32{rram[wire_rs1][31-rram[wire_rs2][4:0]]}}, (rram[wire_rs1][31:0] << rram[wire_rs2][4:0])}; 
				//           pc <= pc + 4; 
	    	                //           jp <=0;
				//          end
		   32'b???????_?????_?????_001_?????_0111011: begin rram[wire_rd] <= {{32{rram[wire_rs1][31-rram[wire_rs2][4:0]]}}, (rram[wire_rs1][31:0] << rram[wire_rs2][4:0])}; end // Sllw
			//	  3'b101: begin
			//	          case(wire_f7) // func7
			//		    7'b0000000: begin
			//			        Srlw  <= 1'b1; // set Srlw  Flag 
			//		                if (rram[wire_rs2][4:0] == 0) rram[wire_rd] <= {{32{rram[wire_rs1][31]}}, rram[wire_rs1][31:0]}; 
			//		                else rram[wire_rd] <= (rram[wire_rs1][31:0] >> rram[wire_rs2][4:0]); 
			//	                        pc <= pc + 4; 
	    	        //                                jp <=0;
			//		                end
		   32'b0000000_?????_?????_101_?????_0111011: begin if (rram[wire_rs2][4:0] == 0) rram[wire_rd] <= {{32{rram[wire_rs1][31]}}, rram[wire_rs1][31:0]}; 
		                                              else rram[wire_rd] <= (rram[wire_rs1][31:0] >> rram[wire_rs2][4:0]); end // Srlw
		//			    7'b0100000: begin
		//				       Sraw  <= 1'b1; // set Sraw  Flag 
		//			               // shift right arithmatical rs1.l32 by sr2[low5.unsign] cut 32 sext 64 to rd
		//			               rram[wire_rd] <= {{32{rram[wire_rs1][31]}}, ($signed(rram[wire_rs1][31:0]) >>> rram[wire_rs2][4:0])}; 
		//		                       pc <= pc + 4; 
	    	//                                       jp <=0;
		//				       end
		//		          endcase
		//		         end 
		//		endcase
		//              end
		   32'b0100000_?????_?????_101_?????_0111011: begin rram[wire_rd] <= {{32{rram[wire_rs1][31]}}, ($signed(rram[wire_rs1][31:0]) >>> rram[wire_rs2][4:0])}; end // Sraw
	           //7'b1101111:begin 
                   //             Jal <= 1'b1; // set Jal Flag 
		   //     	//jump PC to PC+imm(padding 0) and place return address PC+4 in rd
		   //     	rram[wire_rd] <= pc + 4;
		   //     	pc <= pc +  {{43{wire_jimm[20]}}, wire_jimm};
	    	   //             jp <=0;
                   //           end
		   32'b???????_?????_?????_???_?????_1101111: begin rram[wire_rd] <= pc + 4; pc <= pc +  {{43{wire_jimm[20]}}, wire_jimm}; end // Jal
	           //7'b1100111:begin 
                   //             Jalr <= 1'b1; // set Jalr Flag 
		   //             //jump PC to address imm(rs1) and place return address PC+4 in rd (no need padding last 0 not as JAL)
		   //     	rram[wire_rd] <= pc + 4;
		   //     	pc <= (rram[wire_rs1] +  {{52{wire_imm[11]}}, wire_imm}) & 64'hFFFFFFFFFFFFFFFE ;
	    	   //             jp <=0;
                   //           end
		   32'b???????_?????_?????_???_?????_1100111: begin rram[wire_rd] <= pc + 4; pc <= (rram[wire_rs1] +  {{52{wire_imm[11]}}, wire_imm}) & 64'hFFFFFFFFFFFFFFFE ; end // Jalr
                   // Branch class
	        //   7'b1100011:begin 
		//	        case(wire_f3) // func3
		//		  3'b000:begin
		//		         Beq  <= 1'b1; // set Beq  Flag 
		//		         //  take branch if rs1 rs2 equal to PC+(sign-extend imm_0)
		//			 if (rram[wire_rs1] == rram[wire_rs2]) pc <= pc + sign_extended_bimm;
		//			 else pc <= pc + 4; 
	    	//                         jp <=0;
		//		         end
		   32'b???????_?????_?????_000_?????_1100011: begin if (rram[wire_rs1] == rram[wire_rs2]) pc <= pc + sign_extended_bimm; else pc <= pc + 4; end // Beq
		//		  3'b001:begin 
		//			 Bne  <= 1'b1; // set Bne  Flag 
		//		         //  take branch if rs1 rs2 not equal to PC+(sign-extend imm_0)
		//			 if (rram[wire_rs1] != rram[wire_rs2]) pc <= pc + sign_extended_bimm;
		//			 else pc <= pc + 4; 
	    	//                         jp <=0;
		//		         end
		   32'b???????_?????_?????_001_?????_1100011: begin if (rram[wire_rs1] != rram[wire_rs2]) pc <= pc + sign_extended_bimm; else pc <= pc + 4; end // Bne
		//		  3'b100:begin 
		//			 Blt  <= 1'b1; // set Blt  Flag 
		//		         //  take branch if rs1 smaller than rs2 to PC+(sign-extend imm_0)
		//			 if ($signed(rram[wire_rs1]) < $signed(rram[wire_rs2])) pc <= pc + sign_extended_bimm;
		//			  else pc <= pc + 4;
	    	//                         jp <=0;
		//		         end
		   32'b???????_?????_?????_100_?????_1100011: begin if ($signed(rram[wire_rs1]) < $signed(rram[wire_rs2])) pc <= pc + sign_extended_bimm; else pc <= pc + 4; end // Blt
		//		  3'b101:begin 
		//			 Bge  <= 1'b1; // set Bge  Flag 
		//		         //  take branch if rs1 bigger than or equite to rs2 to PC+(sign-extend imm_0)
		//			 if ($signed(rram[wire_rs1]) >= $signed(rram[wire_rs2])) pc <= pc + sign_extended_bimm;
		//			  else pc <= pc + 4;
	    	//                         jp <=0;
		//			 end
		   32'b???????_?????_?????_101_?????_1100011: begin if ($signed(rram[wire_rs1]) >= $signed(rram[wire_rs2])) pc <= pc + sign_extended_bimm; else pc <= pc + 4; end // Bge
		//		  3'b110:begin
		//			 Bltu <= 1'b1; // set Bltu Flag 
		//			 //take branch if rs1 < rs2 in unsigned comparison 
		//			    if (rram[wire_rs1] < rram[wire_rs2]) pc <= pc + sign_extended_bimm;
		//			    else pc <= pc + 4;
	    	//                            jp <=0;
		//		         end 
		   32'b???????_?????_?????_110_?????_1100011: begin if (rram[wire_rs1] < rram[wire_rs2]) pc <= pc + sign_extended_bimm; else pc <= pc + 4; end // Bltu
		//		  3'b111:begin
		//			 Bgeu <= 1'b1; // set Bgeu Flag 
		//			 //take branch if rs1 >= rs2 in unsigned comparison 
		//			    if (rram[wire_rs1] >= rram[wire_rs2]) pc <= pc + sign_extended_bimm;
		//			    else pc <= pc + 4;
	    	//                            jp <=0;
		//		         end 
		//		endcase
		//              end
		   32'b???????_?????_?????_111_?????_1100011: begin if (rram[wire_rs1] >= rram[wire_rs2]) pc <= pc + sign_extended_bimm; else pc <= pc + 4; end // Bgeu
                   // Fence class
	        //   7'b0001111:begin
		//	        case(irom[pc][14:12]) // func3
		//	          3'b000: Fence  <= 1'b1; // set Fence Flag 
		   32'b???????_?????_?????_000_?????_0001111: begin end // Fence
		//	          3'b001: Fencei <= 1'b1; // set Fencei Flag 
		//		endcase
		//              end
		   32'b???????_?????_?????_001_?????_0001111: begin end // Fencei
		   // ----------------------------
	           7'b1110011:begin // system 
		                csr_id =  csr_index(wire_csr);
			        case(wire_f3) // func3
				  3'b000: begin // priv
				          case(wire_f12) // func12
					    12'b000000000000:begin 
					               Ecall  <= 1'b1; // set Ecall  Flag 
                                                       // Trap into S-mode
			                               if (current_privilege_mode == U_mode && medeleg[8] == 1)
						       begin
						           csrram[scause][63] <= 0; //63_type 0exception 1interrupt|value
						           csrram[scause][62:0] <= 8; // 8 indicate Ecall from U-mode; 9 call from S-mode; 11 call from M-mode
						           csrram[sepc] <= pc;
						           csrram[sstatus][8] <= 0; // save previous privilege mode(user0 super1) to SPP 
						           csrram[sstatus][5] <= csrram[sstatus][1]; // save interrupt enable(SIE) to SPIE 
						           csrram[sstatus][1] <= 0; // clear SIE
						           //if ((csrram[scause][63]==1'b1) && (csrram[stvec][1:0]== 2'b01)) pc <= (csrram[stvec][63:2] << 2) + (csrram[scause][62:0] << 2);
						           pc <= (csrram[stvec][63:2] << 2);
							   current_privilege_mode <= S_mode;
						       end
						       // Trap into M-mode
						       else 
						       begin
						           csrram[mcause][63] <= 0; //63_type 0exception 1interrupt|value
						           csrram[mepc] <= pc;
						           csrram[mstatus][7] <= csrram[mstatus][3]; // save interrupt enable(MIE) to MPIE 
						           csrram[mstatus][3] <= 0; // clear MIE (not enabled)
						           pc <= (csrram[mtvec][63:2] << 2);
			                                   if (current_privilege_mode == U_mode && medeleg[8] == 0) csrram[mcause][62:0] <= 8; // save cause 
			                                   if (current_privilege_mode == S_mode) csrram[mcause][62:0] <= 9; 
						           if (current_privilege_mode == M_mode) csrram[mcause][62:0] <= 11; 
							   csrram[mstatus][12:11] <= current_privilege_mode; // save privilege mode to MPP 
							   current_privilege_mode <= M_mode;  // set current privilege mode
						       end
						       end
					    12'b000000000001:begin 
					               Ebreak <= 1'b1; // set Ebreak Flag 
						       end
					    12'b000100000010:begin 
					               //Sret <= 1'b1; // set Sret Flag 
						       if (csrram[sstatus][8] == 0) current_privilege_mode <= U_mode;
						       if (csrram[sstatus][8] == 1) current_privilege_mode <= S_mode;
						       csrram[sstatus][1] <= csrram[sstatus][5]; // set back interrupt enable(SIE) by SPIE 
						       csrram[sstatus][5] <= 1; // set previous interrupt enable(SIE) to be 1 (enable)
						       csrram[sstatus][8] <= 0; // set previous privilege mode(SPP) to be 0 (U-mode)
						       pc <=  csrram[sepc]; // sepc was +4 by the software handler and written back to sepc
						       end
					    12'b001100000010:begin 
					               //Mret <= 1'b1; // set Mret Flag 
						       csrram[mstatus][3] <= csrram[mstatus][7]; // set back interrupt enable(MIE) by MPIE 
						       csrram[mstatus][7] <= 1; // set previous interrupt enable(MIE) to be 1 (enable)
						       if (csrram[mstatus][12:11] < M_mode) csrram[mstatus][17] <= 0; // set mprv to 0
						       current_privilege_mode  <= csrram[mstatus][12:11]; // set back previous mode
						       csrram[mstatus][12:11] <= 2'b00; // set previous privilege mode(MPP) to be 00 (U-mode)
						       pc <=  csrram[mepc]; // mepc was +4 by the software handler and written back to sepc
						       end
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
                   //pc <= pc + 4; 
                   //jp <=0;
	       end
	    //######## // 指令执行 // Close Flage
	    //1: begin 
	    //   end
	    endcase
        end
end
endmodule
