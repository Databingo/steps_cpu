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
reg [63:0] re [0:31];// 64 位宽度，32 行深度 x0, x1, x2... x31
// CSR 寄存器列表 4096 个(预设个数 2**12=4096)
reg [63:0] csre [0:4096];// 64 位宽度，4096 行深度

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
// assign w_ir = {irom[pc], irom[pc+1], irom[pc+2], irom[pc+3]};  // Big endian
assign w_ir = {irom[pc+3], irom[pc+2], irom[pc+1], irom[pc]};  // Little endian

// 组合数据线，避免使用寄存器浪费时钟
wire [31:0] w_ir;
wire [ 6:0] w_op;
wire [ 5:0] w_rd;
wire [ 5:0] w_rs1;
wire [ 5:0] w_rs2;
wire [ 5:0] w_f3; 
wire [ 6:0] w_f7;
wire [11:0] w_f12;   // ecall 0, ebreak 1
wire [11:0] w_imm;   // I-type immediate Lb Lh Lw Lbu Lhu Lwu Ld Jalr Addi Slti Sltiu Xori Ori Andi Addiw
wire [19:0] w_upimm; // U-type immediate Lui Auipc
wire [20:0] w_jimm;  // UJ-type immediate Jal
wire [11:0] w_simm;  // S-type immediate Sb Sh Sw Sd
wire [12:0] w_bimm;  // SB-type immediate Beq Bne Blt Bge Bltu Bgeu
wire [ 5:0] w_shamt; // If 6 bits the highest is always 0??
wire [11:0] w_csr;   // CSR address
wire [ 5:0] w_zimm;  // CSR zimm

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
assign w_op  = w_ir[6:0]; 
assign w_rd  = w_ir[11:7]; 
assign w_f3  = w_ir[14:12];
assign w_rs1 = w_ir[19:15]; 
assign w_rs2 = w_ir[24:20]; 
assign w_f7  = w_ir[31:25]; 
assign w_f12 = w_ir[31:20]; 
assign w_imm = w_ir[31:20];
assign w_upimm = w_ir[31:12];
assign w_jimm  = {w_ir[31], w_ir[19:12], w_ir[20], w_ir[30:21], 1'b0}; // read immediate & padding last 0, total 20 + 1 = 21 bits
assign w_simm  = {w_ir[31:25], w_ir[11:7]};
assign w_bimm  = {w_ir[31], w_ir[7],  w_ir[30:25], w_ir[11:8], 1'b0};// read immediate & padding last 0, total 12 + 1 = 13 bits
assign w_shamt = w_ir[25:20];
assign w_csr = w_ir[31:20];
assign w_zimm = w_ir[19:15];

// 连接显示器
assign oir = w_ir;       // 显示 32 位指令
assign opc = pc[63:0];      // 显示 64 位程序计数器值
assign ojp = jp[2:0];       // 显示 3 位节拍计数器
assign oop = w_op;       // 显示 7 位操作码
assign of3 = w_f3;       // 显示 func3 值
assign of7 = w_f7;       // 显示 func7 值
assign oimm = w_imm;     // 显示 imm 值
assign oupimm = w_upimm; // 显示 upimm 值
assign oshamt = w_shamt;
assign ox0 = re[0];       // 显示 x0 值
assign ox1 = re[1];       
assign ox2 = re[2];       
assign ox3 = re[3];
assign ox4 = re[4];
assign ox5 = re[5];
assign ox6 = re[6]; 
assign ox7 = re[7];
assign ox8 = re[8];
assign ox9 = re[9]; 
assign ox10 = re[10];
assign ox11 = re[11];
assign ox12 = re[12];
assign ox13 = re[13];
assign ox14 = re[14];
assign ox15 = re[15];
assign ox16 = re[16];
assign ox17 = re[17];
assign ox18 = re[18];
assign ox19 = re[19];
assign ox20 = re[20];
assign ox21 = re[21];
assign ox22 = re[22];
assign ox23 = re[23];
assign ox24 = re[24];
assign ox25 = re[25];
assign ox26 = re[26];
assign ox27 = re[27];
assign ox28 = re[28];
assign ox29 = re[29];
assign ox30 = re[30];
assign ox31 = re[31];

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
 sum = re[w_rs1] + re[w_rs2];
 sum_imm = re[w_rs1] + {{52{w_imm[11]}}, w_imm};
 sum_imm_32 = re[w_rs1][31:0] + {{20{w_imm[11]}}, w_imm};
 mirro_rs2 = ~re[w_rs2] + 1;
 mirro_imm = ~{{52{w_imm[11]}}, w_imm} + 1;
 sub = re[w_rs1] + mirro_rs2;
 sub_imm = re[w_rs1] + mirro_imm;
 sign_extended_bimm = {{51{w_ir[31]}}, w_bimm};  //bimm is 13 bits length
 slliw_s1 = re[w_rs1][31:0] << w_shamt[4:0]; 
 srliw_s1 = re[w_rs1][31:0] >> w_shamt[4:0]; 
 sraiw_s1 = $signed(re[w_rs1][31:0]) >>> w_shamt[4:0]; 
end 

always @(posedge clock or negedge reset_n)
begin
	//start #### 初始化各项 0 值
	if (!reset_n)
	begin
	  pc <=0;
	  current_privilege_mode <= M_mode; // init from M-mode for all RISCV processor
	  for (integer i = 0; i < 32; i = i + 1) re[i] <= 64'h0;  //!!初始化零否则新启用寄存器就不灵
	end
	else
	begin // 取指令 + 分析指令 + 执行 | 或 准备数据 (分析且备好该指令所需的数据）
	   pc <= pc +4 ;// Default: advance PC for most instructions; override in jumps/branches/traps //ir <= w_ir ; 
           csr_id = csr_index(w_csr); // ----------------------------SYSTEM 
    	   casez(w_ir) 
           // Load-class
           32'b???????_?????_?????_???_?????_0110111: begin re[w_rd] <= {{32{w_upimm[19]}}, w_upimm, 12'b0}; end // Lui
	   32'b???????_?????_?????_???_?????_0010111: begin re[w_rd] <= pc + {{32{w_upimm[19]}}, w_upimm, 12'b0}; end // Auipc
	   32'b???????_?????_?????_000_?????_0000011: begin re[w_rd] <= {{56{drom[re[w_rs1]+ {{52{w_imm[11]}},w_imm}][7]}}, drom[re[w_rs1]+ {{52{w_imm[11]}},w_imm}]};end  // Lb
	   32'b???????_?????_?????_100_?????_0000011: begin re[w_rd] <= {56'b0, drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}]}; end // Lbu
	   32'b???????_?????_?????_001_?????_0000011: begin re[w_rd] <= {{48{drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}+ 1][7]}}, 
				                                                  drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}+ 1], 
										  drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}] }; end // Lh
	   32'b???????_?????_?????_101_?????_0000011: begin re[w_rd] <= {48'b0, drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}+ 1], drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}]}; end // Lhu
	   32'b???????_?????_?????_010_?????_0000011: begin re[w_rd] <= {{32{drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}+ 3][7]}}, 
                                                                                  drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}+3], 
                                 			                          drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}+2], 
                                 			                          drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}+1], 
							                          drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}]}; end // Lw
	   32'b???????_?????_?????_110_?????_0000011: begin re[w_rd] <= {32'b0, drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}+3], 
                                                                                     drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}+2], 
                                                                                     drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}+1], 
							                             drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}]}; end // Lwu
	   32'b???????_?????_?????_011_?????_0000011: begin re[w_rd] <= {drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}+7], 
                                                                              drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}+6], 
                                                                              drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}+5], 
                                                                              drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}+4],
                                                                              drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}+3], 
                                                                              drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}+2], 
                                                                              drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}+1], 
						                              drom[re[w_rs1]+{{52{w_imm[11]}},w_imm}  ]}; end // Ld
           // Store-class  // ld and sb are different direction: 
	   32'b???????_?????_?????_000_?????_0100011: begin drom[re[w_rs1]+{{52{w_simm[11]}},w_simm}]   <= re[w_rs2][7:0]; end // Sb
	   32'b???????_?????_?????_001_?????_0100011: begin drom[re[w_rs1]+{{52{w_simm[11]}},w_simm}]   <= re[w_rs2][7:0];
	                                                    drom[re[w_rs1]+{{52{w_simm[11]}},w_simm}+1] <= re[w_rs2][15:8]; end // Sh
	   32'b???????_?????_?????_010_?????_0100011: begin drom[re[w_rs1]+{{52{w_simm[11]}},w_simm}]   <= re[w_rs2][7:0];
				                            drom[re[w_rs1]+{{52{w_simm[11]}},w_simm}+1] <= re[w_rs2][15:8];
				                            drom[re[w_rs1]+{{52{w_simm[11]}},w_simm}+2] <= re[w_rs2][23:16];
				                            drom[re[w_rs1]+{{52{w_simm[11]}},w_simm}+3] <= re[w_rs2][31:24]; end // Sw
	   32'b???????_?????_?????_011_?????_0100011: begin drom[re[w_rs1]+{{52{w_simm[11]}},w_simm}]   <= re[w_rs2][7:0];
				                            drom[re[w_rs1]+{{52{w_simm[11]}},w_simm}+1] <= re[w_rs2][15:8];
				                            drom[re[w_rs1]+{{52{w_simm[11]}},w_simm}+2] <= re[w_rs2][23:16];
				                            drom[re[w_rs1]+{{52{w_simm[11]}},w_simm}+3] <= re[w_rs2][31:24];
				                            drom[re[w_rs1]+{{52{w_simm[11]}},w_simm}+4] <= re[w_rs2][39:32];
				                            drom[re[w_rs1]+{{52{w_simm[11]}},w_simm}+5] <= re[w_rs2][47:40];
				                            drom[re[w_rs1]+{{52{w_simm[11]}},w_simm}+6] <= re[w_rs2][55:48];
				                            drom[re[w_rs1]+{{52{w_simm[11]}},w_simm}+7] <= re[w_rs2][63:56]; end // Sd
           // Math-Logic-Shift-Register class
	   32'b0000000_?????_?????_000_?????_0110011: begin re[w_rd] <= re[w_rs1] + re[w_rs2]; 
			                              if ((re[w_rs1][63] ~^ re[w_rs2][63]) && (re[w_rs1][63] ^ sum[63])) 
					              begin re[3] <= 1; re[4] <= re[w_rs1][63]; end end  // Add
	   32'b0100000_?????_?????_000_?????_0110011: begin re[w_rd] <= sub;
			                              if ((re[w_rs1][63] ~^ mirro_rs2 [63]) && (re[w_rs1][63] ^ sub[63])) 
					              begin re[3] <= 1; re[4] <= re[w_rs1][63]; end end // Sub
	   32'b???????_?????_?????_010_?????_0110011: begin 
				                      if ((re[w_rs1][63] ~^ mirro_rs2[63]) && re[w_rs1][63] == 1) re[w_rd] <= 1'b1; 
				                      else if ((re[w_rs1][63] ^ mirro_rs2[63]) && (sub[63] == 1)) re[w_rd] <= 1'b1; 
				                      else re[w_rd] <= 1'b0; end // Slt
	   32'b???????_?????_?????_011_?????_0110011: begin if (re[w_rs1] < re[w_rs2]) re[w_rd] <= 1'b1; else re[w_rd] <= 1'b0; end // Sltu
	   32'b???????_?????_?????_110_?????_0110011: begin re[w_rd] <= (re[w_rs1] | re[w_rs2]); end // Or
	   32'b???????_?????_?????_111_?????_0110011: begin re[w_rd] <= (re[w_rs1] & re[w_rs2]); end // And
	   32'b???????_?????_?????_100_?????_0110011: begin re[w_rd] <= (re[w_rs1] ^ re[w_rs2]); end // Xor
	   32'b???????_?????_?????_001_?????_0110011: begin re[w_rd] <= re[w_rs1] << re[w_rs2][5:0]; end // Sll
           32'b0000000_?????_?????_101_?????_0110011: begin re[w_rd] <= (re[w_rs1] >> re[w_rs2][5:0]); end // Srl
	   32'b0100000_?????_?????_101_?????_0110011: begin re[w_rd] <= ($signed(re[w_rs1]) >>> re[w_rs2][5:0]); end // Sra
           // Math-Logic-Shift-Immediate class
	   32'b???????_?????_?????_000_?????_0010011: begin re[w_rd] <= re[w_rs1] + {{52{w_imm[11]}}, w_imm}; 
			                             if ((re[w_rs1][63] ~^ w_imm[11]) && (re[w_rs1][63] ^ sum_imm[63])) 
			                             begin re[3] <= 1; re[4] <= re[w_rs1][63]; end end // Addi
	   32'b???????_?????_?????_010_?????_0010011: begin if ((re[w_rs1][63] ~^ mirro_imm[63]) && re[w_rs1][63] == 1) re[w_rd] <= 1'b1; 
				                     else if ((re[w_rs1][63] ^ mirro_imm[63]) && (sub_imm[63] == 1)) re[w_rd] <= 1'b1; 
				                     else re[w_rd] <= 1'b0; end // Slti
	   32'b???????_?????_?????_011_?????_0010011: begin if (re[w_rs1] < {{52{w_imm[11]}}, w_imm} ) re[w_rd] <= 1'b1; else re[w_rd] <= 1'b0; end // Sltiu
	   32'b???????_?????_?????_110_?????_0010011: begin re[w_rd] <= (re[w_rs1] | {{52{w_imm[11]}}, w_imm}); end // Ori
	   32'b???????_?????_?????_111_?????_0010011: begin re[w_rd] <= (re[w_rs1] & {{52{w_imm[11]}}, w_imm}); end // Andi
	   32'b???????_?????_?????_100_?????_0010011: begin re[w_rd] <= (re[w_rs1] ^ {{52{w_imm[11]}}, w_imm}); end // Xori
	   32'b???????_?????_?????_001_?????_0010011: begin re[w_rd] <= (re[w_rs1] << w_shamt ); end // Slli
	   32'b000000?_?????_?????_101_?????_0010011: begin re[w_rd] <= (re[w_rs1] >> w_shamt ); end // Srli // func7->6 // rv64 shame take w_f7[0]
	   32'b010000?_?????_?????_101_?????_0010011: begin re[w_rd] <= ($signed(re[w_rs1]) >>> w_shamt ); end // Srai
           // Math-Logic-Shift-Immediate-64 class
	   32'b???????_?????_?????_000_?????_0011011: begin re[w_rd] <= {{32{sum_imm_32[31]}}, re[w_rs1][31:0] + {{20{w_imm[11]}}, w_imm}}; end // Addiw
	   32'b???????_?????_?????_001_?????_0011011: begin re[w_rd] <= {{32{slliw_s1[31]}}, slliw_s1[31:0]}; end // Slliw
	   32'b0000000_?????_?????_101_?????_0011011: begin re[w_rd] <= {{32{srliw_s1[31]}}, srliw_s1[31:0]}; end // Srliw
	   32'b0100000_?????_?????_101_?????_0011011: begin re[w_rd] <= {{32{sraiw_s1[31]}}, sraiw_s1[31:0]}; end // Sraiw
           // Math-Logic-Shift-Register-64 class
	   32'b0000000_?????_?????_000_?????_0111011: begin re[w_rd] <= {{32{sum[31]}}, re[w_rs1][31:0] + re[w_rs2][31:0]}; end // Addw
	   32'b0100000_?????_?????_000_?????_0111011: begin re[w_rd] <= {{32{sub[31]}}, re[w_rs1][31:0] - re[w_rs2][31:0]}; end // Subw
	   32'b???????_?????_?????_001_?????_0111011: begin re[w_rd] <= {{32{re[w_rs1][31-re[w_rs2][4:0]]}}, (re[w_rs1][31:0] << re[w_rs2][4:0])}; end // Sllw
	   32'b0000000_?????_?????_101_?????_0111011: begin if (re[w_rs2][4:0] == 0) re[w_rd] <= {{32{re[w_rs1][31]}}, re[w_rs1][31:0]}; 
	                                              else re[w_rd] <= (re[w_rs1][31:0] >> re[w_rs2][4:0]); end // Srlw
	   32'b0100000_?????_?????_101_?????_0111011: begin re[w_rd] <= {{32{re[w_rs1][31]}}, ($signed(re[w_rs1][31:0]) >>> re[w_rs2][4:0])}; end // Sraw
	   32'b???????_?????_?????_???_?????_1101111: begin re[w_rd] <= pc + 4; pc <= pc +  {{43{w_jimm[20]}}, w_jimm}; end // Jal
	   32'b???????_?????_?????_???_?????_1100111: begin re[w_rd] <= pc + 4; pc <= (re[w_rs1] +  {{52{w_imm[11]}}, w_imm}) & 64'hFFFFFFFFFFFFFFFE ; end // Jalr
           // Branch class
	   32'b???????_?????_?????_000_?????_1100011: begin if (re[w_rs1] == re[w_rs2]) pc <= pc + sign_extended_bimm; else pc <= pc + 4; end // Beq
	   32'b???????_?????_?????_001_?????_1100011: begin if (re[w_rs1] != re[w_rs2]) pc <= pc + sign_extended_bimm; else pc <= pc + 4; end // Bne
	   32'b???????_?????_?????_100_?????_1100011: begin if ($signed(re[w_rs1]) < $signed(re[w_rs2])) pc <= pc + sign_extended_bimm; else pc <= pc + 4; end // Blt
	   32'b???????_?????_?????_101_?????_1100011: begin if ($signed(re[w_rs1]) >= $signed(re[w_rs2])) pc <= pc + sign_extended_bimm; else pc <= pc + 4; end // Bge
	   32'b???????_?????_?????_110_?????_1100011: begin if (re[w_rs1] < re[w_rs2]) pc <= pc + sign_extended_bimm; else pc <= pc + 4; end // Bltu
	   32'b???????_?????_?????_111_?????_1100011: begin if (re[w_rs1] >= re[w_rs2]) pc <= pc + sign_extended_bimm; else pc <= pc + 4; end // Bgeu
	   32'b???????_?????_?????_000_?????_0001111: begin end // Fence
	   32'b???????_?????_?????_001_?????_0001111: begin end // Fencei
           //csr_id <=  csr_index(w_csr);// ----------------------------SYSTEM 
	   32'b???????_?????_?????_001_?????_1110011: begin if (w_rd !== 5'b00000) re[w_rd] <= csre[csr_id]; csre[csr_id] <= re[w_rs1]; end // Csrrw
	   32'b???????_?????_?????_010_?????_1110011: begin re[w_rd] <= csre[csr_id]; if (w_rs1 !== 5'b00000) csre[csr_id] <= re[w_rs1] | csre[csr_id]; end // Csrrs
	   32'b???????_?????_?????_011_?????_1110011: begin re[w_rd] <= csre[csr_id]; if (w_rs1 !== 5'b00000) csre[csr_id] <= ~re[w_rs1] & csre[csr_id]; end // Csrrc
	   32'b???????_?????_?????_101_?????_1110011: begin if (w_rd !== 5'b00000) re[w_rd] <= csre[csr_id]; csre[csr_id] <= {59'b0, w_zimm}; end // Csrrwi
	   32'b???????_?????_?????_110_?????_1110011: begin re[w_rd] <= csre[csr_id]; if (w_zimm !== 5'b00000) csre[csr_id] <= {59'b0, w_zimm } | csre[csr_id]; end // csrrsi
	   32'b???????_?????_?????_111_?????_1110011: begin re[w_rd] <= irom[w_csr]; if (w_zimm !== 5'b00000) csre[csr_id] <= ~{59'b0, w_zimm } & csre[csr_id]; end // Csrrci
	   32'b0000000_00000_?????_000_?????_1110011: begin  // func12 // Ecall
                                               // Trap into S-mode
		                               if (current_privilege_mode == U_mode && medeleg[8] == 1)
					       begin
					           csre[scause][63] <= 0; //63_type 0exception 1interrupt|value
					           csre[scause][62:0] <= 8; // 8 indicate Ecall from U-mode; 9 call from S-mode; 11 call from M-mode
					           csre[sepc] <= pc;
					           csre[sstatus][8] <= 0; // save previous privilege mode(user0 super1) to SPP 
					           csre[sstatus][5] <= csre[sstatus][1]; // save interrupt enable(SIE) to SPIE 
					           csre[sstatus][1] <= 0; // clear SIE
					           //if ((csre[scause][63]==1'b1) && (csre[stvec][1:0]== 2'b01)) pc <= (csre[stvec][63:2] << 2) + (csre[scause][62:0] << 2);
					           pc <= (csre[stvec][63:2] << 2);
						   current_privilege_mode <= S_mode;
					       end
					       // Trap into M-mode
					       else 
					       begin
					           csre[mcause][63] <= 0; //63_type 0exception 1interrupt|value
					           csre[mepc] <= pc;
					           csre[mstatus][7] <= csre[mstatus][3]; // save interrupt enable(MIE) to MPIE 
					           csre[mstatus][3] <= 0; // clear MIE (not enabled)
					           pc <= (csre[mtvec][63:2] << 2);
		                                   if (current_privilege_mode == U_mode && medeleg[8] == 0) csre[mcause][62:0] <= 8; // save cause 
		                                   if (current_privilege_mode == S_mode) csre[mcause][62:0] <= 9; 
					           if (current_privilege_mode == M_mode) csre[mcause][62:0] <= 11; 
						   csre[mstatus][12:11] <= current_privilege_mode; // save privilege mode to MPP 
						   current_privilege_mode <= M_mode;  // set current privilege mode
					       end
					       end
	   32'b0000000_00001_?????_000_?????_1110011: begin  end // Ebreak
	   32'b0001000_00010_?????_000_?????_1110011: begin      // Sret
					       if (csre[sstatus][8] == 0) current_privilege_mode <= U_mode;
					       if (csre[sstatus][8] == 1) current_privilege_mode <= S_mode;
					       csre[sstatus][1] <= csre[sstatus][5]; // set back interrupt enable(SIE) by SPIE 
					       csre[sstatus][5] <= 1; // set previous interrupt enable(SIE) to be 1 (enable)
					       csre[sstatus][8] <= 0; // set previous privilege mode(SPP) to be 0 (U-mode)
					       pc <=  csre[sepc]; // sepc was +4 by the software handler and written back to sepc
					       end
	   32'b0011000_00010_?????_000_?????_1110011: begin  // Mret
					       csre[mstatus][3] <= csre[mstatus][7]; // set back interrupt enable(MIE) by MPIE 
					       csre[mstatus][7] <= 1; // set previous interrupt enable(MIE) to be 1 (enable)
					       if (csre[mstatus][12:11] < M_mode) csre[mstatus][17] <= 0; // set mprv to 0
					       current_privilege_mode  <= csre[mstatus][12:11]; // set back previous mode
					       csre[mstatus][12:11] <= 2'b00; // set previous privilege mode(MPP) to be 00 (U-mode)
					       pc <=  csre[mepc]; // mepc was +4 by the software handler and written back to sepc
					       end
    	   endcase
           re[0] <= 64'h0;  // x0 恒为 0
        end
    end
endmodule
