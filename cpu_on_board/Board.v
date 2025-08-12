// Two-Stage (Fetch/Execute) Pipelined CPU
module cpu (  
    input wire clock,
    input wire reset_n,
    // for instruction
    output reg [63:0] i_mem_addr,   // Address of instruction
    input wire [31:0] i_mem_data_in, // Instruction backs from memory
    // for data
    output reg [63:0] mem_addr,     // Memory address for load/store
    output reg [63:0] mem_data_out, // Data to write to memory (store)
    output reg mem_we,              // Memory write enable
    input wire [63:0] mem_data_in   // Data read from memory (load)
    ); 
  
    reg [31:0] ir;

    // --- Privilege Modes ---
    localparam M_mode = 2'b11;
    localparam S_mode = 2'b01;
    localparam U_mode = 2'b00;
    reg [1:0] current_privilege_mode;

    // --- CSR Registers ---
    reg [63:0] csre [0:4096]; // Maximal 12-bit = 4096
      
    // --- Machine Mode ---
    // Machine Information Registers
    integer mvendorid = 12'hF11;    // 0xF11 MRO Vendor ID
    integer marchid = 'hF12; 	// 0xF12 MRO Architecture ID
    integer mimpid = 'hF13; 	        // 0xF13 MRO Implementation ID
    integer mhartid = 'hF14; 	// 0xF14 MRO Hardware thread ID
    integer mconfigptr = 'hF15; 	// 0xF15 MRO Pointer to configuration data structure
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
    // --- Supervisor Mode ---
    // Supervisor Trap Setup
    integer sstatus = 12'h100; // 63_SD|WPRI|33:32_UXL10|WPRI|19_MXR|18_SUM|17_WPRI|16:15_XS10|14:13_FS10|WPRI|8_SPP|7_WPRI|6_UBE|5_SPIE|WPRI|1_SIE|0_WPRI
    integer sedeleg = 12'h102;
    integer sideleg = 12'h103;
    integer sie = 12'h104;   // Supervisor interrupt-enable register
    integer stvec = 12'h105;//Supervisor Trap Vector Base Address//63-2_BASE|1-0_MODE|(auto padding last 00base) Mode:00direct to base<<2; 01vectord to base if ecall base+4*scause[62:0] if interrupt;10,11
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

    // --- CSR Index Function ---
    function [4:0] csr_index;
     input [11:0] csr_wire;
     begin
      case (csr_wire)                                              // Machine Information Registers
        12'hF11: csr_index = 5'd1;                                 // 0xF11 MRO mvendorid Vendor ID
    	12'hF12: csr_index = 5'd2; 	                           // 0xF12 MRO marchid Architecture ID
    	12'hF13: csr_index = 5'd3; 	                           // 0xF13 MRO mimpid Implementation ID
    	12'hF14: csr_index = 5'd4; 	                           // 0xF14 MRO mhartid Hardware thread ID
    	12'hF15: csr_index = 5'd5; 	                           // 0xF15 MRO mconfigptr Pointer to configuration data structure
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

    // --- Regisers and Memories ---
    reg [63:0] re [0:31]; // General-purpose registers (x0-x31)
    reg [63:0] pc; // Program counter

//    --- Immediate decoders --- 
//    wire signed [63:0] w_imm_i = {{52{ir[31]}}, ir[31:20]};   // I-type immediate Lb Lh Lw Lbu Lhu Lwu Ld Jalr Addi Slti Sltiu Xori Ori Andi Addiw
//    wire signed [63:0] w_imm_s = {{52{ir[31]}}, ir[31:25], ir[11:7]};  // S-type immediate Sb Sh Sw Sd
//    wire signed [63:0] w_imm_b = {{51{ir[31]}}, ir[7],  ir[30:25], ir[11:8], 1'b0}; // SB-type immediate Beq Bne Blt Bge Bltu Bgeu // read immediate & padding last 0, total 12 + 1 = 13 bits
//    wire signed [63:0] w_imm_u = {{32{ir[31]}}, ir[31:12], 12'b0}; // U-type immediate Lui Auipc
//    wire signed [63:0] w_imm_j = {{43{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0}; // UJ-type immediate Jal  // read immediate & padding last 0, total 20 + 1 = 21 bits
  
    // --- Instruction Decoding ---
    wire [ 6:0] w_op = ir[6:0];
    wire [ 4:0] w_rd = ir[11:7];
    wire [ 2:0] w_f3 = ir[14:12]; 
    wire [ 4:0] w_rs1 = ir[19:15];
    wire [ 4:0] w_rs2 = ir[24:20];
    wire [ 6:0] w_f7 = ir[31:25];
    wire [11:0] w_imm = ir[31:20];   // I-type immediate Lb Lh Lw Lbu Lhu Lwu Ld Jalr Addi Slti Sltiu Xori Ori Andi Addiw
    wire [19:0] w_upimm = ir[31:12]; // U-type immediate Lui Auipc
    wire [20:0] w_jimm = {ir[31], ir[19:12], ir[20], ir[30:21], 1'b0}; // UJ-type immediate Jal  // read immediate & padding last 0, total 20 + 1 = 21 bits
    wire [11:0] w_simm = {ir[31:25], ir[11:7]};  // S-type immediate Sb Sh Sw Sd
    wire [12:0] w_bimm = {ir[31], ir[7],  ir[30:25], ir[11:8], 1'b0}; // SB-type immediate Beq Bne Blt Bge Bltu Bgeu // read immediate & padding last 0, total 12 + 1 = 13 bits
    wire [ 5:0] w_shamt = ir[25:20]; // If 6 bits the highest is always 0??
    wire [11:0] w_csr = ir[31:20];   // CSR address
    wire [11:0] w_f12 = ir[31:20];   // ecall 0, ebreak 1
    wire [ 4:0] w_zimm = ir[19:15];  // CSR zimm

    // --- Combinational Logic (Immediate)---
    wire [63:0]    sum = re[w_rs1] + re[w_rs2];
    wire [63:0]    sum_imm = re[w_rs1] + {{52{w_imm[11]}}, w_imm};
    wire [31:0]    sum_imm_32 = re[w_rs1][31:0] + {{20{w_imm[11]}}, w_imm};
    wire [63:0]    sub = re[w_rs1] - re[w_rs2];
    wire [63:0]    sub_imm = re[w_rs1] - {{52{w_imm[11]}}, w_imm};
    wire [63:0]    sign_extended_bimm = {{51{ir[31]}}, w_bimm};  //bimm is 13 bits length
    wire [31:0]    slliw_s1 = re[w_rs1][31:0] << w_shamt[4:0]; 
    wire [31:0]    srliw_s1 = re[w_rs1][31:0] >> w_shamt[4:0]; 
    wire [31:0]    sraiw_s1 = $signed(re[w_rs1][31:0]) >>> w_shamt[4:0]; 

    // --- Memory Access ---
    wire [63:0] l_addr = re[w_rs1] + {{52{w_imm[11]}}, w_imm}; // Load address
    wire [63:0] s_addr = re[w_rs1] + {{52{w_simm[11]}}, w_simm}; // Store address
      
    // --- Flush signal ---
    reg bubble;

    // ---  Stage 1: IF (instruction fetch by PC) ---
    always @(posedge clock or negedge reset_n) begin
	if (!reset_n) begin
	    ir <= 32'h00000013;  // On reset load NOP 
	end else begin
	    i_mem_addr <= pc;    // sent out current PC to instruction memeory
	    ir <= i_mem_data_in; // latch the PC-refered instruciton back in cpu
	end
    end

    // ---  Stage 2: Execute (decode & execute & set PC) ---
    reg [4:0] csr_id; 
    always @(posedge clock or negedge reset_n) begin
	if (!reset_n) begin
	    bubble <= 1'b0;
	    pc <= 64'h0;
	    current_privilege_mode <= M_mode; // init from M-mode for all RISCV processor
	    for (integer i = 0; i < 32; i = i + 1) re[i] <= 64'h0;  //!!初始化零否则新启用寄存器就不灵
	    mem_we <= 0;
            mem_addr <= 0;
	    mem_data_out <= 0;
	end else begin // 取指令 + 分析指令 + 执行 | 或 准备数据 (分析且备好该指令所需的数据）
            pc <= pc +4 ;// Default: advance PC for most instructions; override in jumps/branches/traps 
	    if (bubble) begin 
		bubble <= 1'b0; // Flush this cycle & Clear flush signal for the next cycle
	    end else begin 
	        mem_we <= 0; // Default: no memeory write
                csr_id = csr_index(w_csr); // ----------------------------SYSTEM 
    	        casez(ir) 
	        // U-type
                32'b???????_?????_?????_???_?????_0110111: re[w_rd] <= {{32{w_upimm[19]}}, w_upimm, 12'b0}; // Lui
	        32'b???????_?????_?????_???_?????_0010111: re[w_rd] <= pc + {{32{w_upimm[19]}}, w_upimm, 12'b0}; // Auipc
                // Load
	        32'b???????_?????_?????_000_?????_0000011: begin mem_addr <= l_addr; re[w_rd] <= {{56{mem_data_in[7]}}, mem_data_in[7:0]}; end // Lb
		//32'b???????_?????_?????_100_?????_0000011: begin mem_addr <= l_addr; re[w_rd] <= {56'b0, mem_data_in[7:0]}; end // Lbu
	        //32'b???????_?????_?????_001_?????_0000011: begin mem_addr <= l_addr; re[w_rd] <= {{48{mem_data_in[15]}}, mem_data_in[15:0]}; end // Lh
	        //32'b???????_?????_?????_101_?????_0000011: begin mem_addr <= l_addr; re[w_rd] <= {48'b0, mem_data_in[15:0]}; end // Lhu
		//32'b???????_?????_?????_010_?????_0000011: begin mem_addr <= l_addr; re[w_rd] <= {{32{mem_data_in[31]}}, mem_data_in[31:0]}; end // Lw
		//32'b???????_?????_?????_110_?????_0000011: begin mem_addr <= l_addr; re[w_rd] <= {32'b0, mem_data_in[31:0]}; end // Lwu
		//32'b???????_?????_?????_011_?????_0000011: begin mem_addr <= l_addr; re[w_rd] <= mem_data_in; end // Ld
                //// Store
	        //32'b???????_?????_?????_000_?????_0100011: begin mem_addr <= s_addr; mem_we <= 1; mem_data_out <= re[w_rs2][7:0]; end // Sb
	        //32'b???????_?????_?????_001_?????_0100011: begin mem_addr <= s_addr; mem_we <= 1; mem_data_out <= re[w_rs2][15:0]; end// Sh
	        //32'b???????_?????_?????_010_?????_0100011: begin mem_addr <= s_addr; mem_we <= 1; mem_data_out <= re[w_rs2][31:0]; end// Sw
	        //32'b???????_?????_?????_011_?????_0100011: begin mem_addr <= s_addr; mem_we <= 1; mem_data_out <= re[w_rs2]; end// Sd
                //// Math-R
	        //32'b0000000_?????_?????_000_?????_0110011: re[w_rd] <= re[w_rs1] + re[w_rs2];  // Add
	        //32'b0100000_?????_?????_000_?????_0110011: re[w_rd] <= re[w_rs1] - re[w_rs2];  // Sub;
	        //32'b???????_?????_?????_010_?????_0110011: re[w_rd] <= ($signed(re[w_rs1]) < $signed(re[w_rs2])) ? 64'h1: 64'h0;  // Slt
	        //32'b???????_?????_?????_011_?????_0110011: re[w_rd] <= re[w_rs1] < re[w_rs2] ? 64'h1 : 64'h0; // Sltu
	        //32'b???????_?????_?????_110_?????_0110011: re[w_rd] <= re[w_rs1] | re[w_rs2]; // Or
	        //32'b???????_?????_?????_111_?????_0110011: re[w_rd] <= re[w_rs1] & re[w_rs2]; // And
	        //32'b???????_?????_?????_100_?????_0110011: re[w_rd] <= re[w_rs1] ^ re[w_rs2]; // Xor
	        //32'b???????_?????_?????_001_?????_0110011: re[w_rd] <= re[w_rs1] << re[w_rs2][5:0]; // Sll
                //32'b0000000_?????_?????_101_?????_0110011: re[w_rd] <= re[w_rs1] >> re[w_rs2][5:0]; // Srl
	        //32'b0100000_?????_?????_101_?????_0110011: re[w_rd] <= $signed(re[w_rs1]) >>> re[w_rs2][5:0]; // Sra
                //// Math-R (Word)
	        //32'b0000000_?????_?????_000_?????_0111011: re[w_rd] <= {{32{sum[31]}}, sum[31:0]}; // Addw
	        //32'b0100000_?????_?????_000_?????_0111011: re[w_rd] <= {{32{sub[31]}}, sub[31:0]}; // Subw
	        //32'b???????_?????_?????_001_?????_0111011: re[w_rd] <= {{32{re[w_rs1][31-re[w_rs2][4:0]]}}, (re[w_rs1][31:0] << re[w_rs2][4:0])}; // Sllw
                //32'b0000000_?????_?????_101_?????_0111011: re[w_rd] <= (re[w_rs2][4:0] == 0) ? {{32{re[w_rs1][31]}}, re[w_rs1][31:0]} : (re[w_rs1][31:0] >> re[w_rs2][4:0]); // Srlw
	        //32'b0100000_?????_?????_101_?????_0111011: re[w_rd] <= {{32{re[w_rs1][31]}}, ($signed(re[w_rs1][31:0]) >>> re[w_rs2][4:0])}; // Sraw
                //// Math-I
	        //32'b???????_?????_?????_000_?????_0010011: re[w_rd] <= re[w_rs1] + {{52{w_imm[11]}}, w_imm};  // Addi
	        //32'b???????_?????_?????_010_?????_0010011: re[w_rd] <= ($signed(re[w_rs1]) < $signed({{52{w_imm[11]}}, w_imm})) ? 64'h1 : 64'h0 ; // Slti
	        //32'b???????_?????_?????_011_?????_0010011: re[w_rd] <= (re[w_rs1] < {{52{w_imm[11]}}, w_imm}) ?  64'h1 : 64'h0; // Sltiu
	        //32'b???????_?????_?????_110_?????_0010011: re[w_rd] <= re[w_rs1] | {{52{w_imm[11]}}, w_imm}; // Ori
	        //32'b???????_?????_?????_111_?????_0010011: re[w_rd] <= re[w_rs1] & {{52{w_imm[11]}}, w_imm}; // Andi
	        //32'b???????_?????_?????_100_?????_0010011: re[w_rd] <= re[w_rs1] ^ {{52{w_imm[11]}}, w_imm}; // Xori
	        //32'b???????_?????_?????_001_?????_0010011: re[w_rd] <= re[w_rs1] << w_shamt; // Slli
	        //32'b000000?_?????_?????_101_?????_0010011: re[w_rd] <= re[w_rs1] >> w_shamt; // Srli // func7->6 // rv64 shame take w_f7[0]
	        //32'b010000?_?????_?????_101_?????_0010011: re[w_rd] <= $signed(re[w_rs1]) >>> w_shamt; // Srai
                //// Math-I (Word)
	        //32'b???????_?????_?????_000_?????_0011011: re[w_rd] <= {{32{sum_imm_32[31]}}, sum_imm_32}; // Addiw
	        //32'b???????_?????_?????_001_?????_0011011: re[w_rd] <= {{32{slliw_s1[31]}}, slliw_s1}; // Slliw
	        //32'b0000000_?????_?????_101_?????_0011011: re[w_rd] <= {{32{srliw_s1[31]}}, srliw_s1}; // Srliw
	        //32'b0100000_?????_?????_101_?????_0011011: re[w_rd] <= {{32{sraiw_s1[31]}}, sraiw_s1}; // Sraiw
	        //// Jamp
	        //32'b???????_?????_?????_???_?????_1101111: begin re[w_rd] <= pc + 4; pc <= pc +  {{43{w_jimm[20]}}, w_jimm}; bubble <= 1'b1; end // Jal
	        //32'b???????_?????_?????_???_?????_1100111: begin re[w_rd] <= pc + 4; pc <= (re[w_rs1] +  {{52{w_imm[11]}}, w_imm}) & 64'hFFFFFFFFFFFFFFFE ; bubble <= 1'b1; end // Jalr
                //// Branch 
		//32'b???????_?????_?????_000_?????_1100011: begin if (re[w_rs1] == re[w_rs2]) begin pc <= pc + sign_extended_bimm; bubble <= 1'b1; end end // Beq
		//32'b???????_?????_?????_001_?????_1100011: begin if (re[w_rs1] != re[w_rs2]) begin pc <= pc + sign_extended_bimm; bubble <= 1'b1; end end // Bne
		//32'b???????_?????_?????_100_?????_1100011: begin if ($signed(re[w_rs1]) < $signed(re[w_rs2])) begin pc <= pc + sign_extended_bimm; bubble <= 1'b1; end end // Blt
		//32'b???????_?????_?????_101_?????_1100011: begin if ($signed(re[w_rs1]) >= $signed(re[w_rs2])) begin pc <= pc + sign_extended_bimm; bubble <= 1'b1; end end // Bge
		//32'b???????_?????_?????_110_?????_1100011: begin if (re[w_rs1] < re[w_rs2]) begin pc <= pc + sign_extended_bimm; bubble <= 1'b1; end end // Bltu
		//32'b???????_?????_?????_111_?????_1100011: begin if (re[w_rs1] >= re[w_rs2]) begin pc <= pc + sign_extended_bimm; bubble <= 1'b1; end end // Bgeu
                //// CSR
	        //32'b???????_?????_?????_001_?????_1110011: begin if (w_rd !== 5'b00000) re[w_rd] <= csre[csr_id]; csre[csr_id] <= re[w_rs1]; end // Csrrw
	        //32'b???????_?????_?????_010_?????_1110011: begin re[w_rd] <= csre[csr_id]; if (w_rs1 !== 5'b00000) csre[csr_id] <= re[w_rs1] | csre[csr_id]; end // Csrrs
	        //32'b???????_?????_?????_011_?????_1110011: begin re[w_rd] <= csre[csr_id]; if (w_rs1 !== 5'b00000) csre[csr_id] <= ~re[w_rs1] & csre[csr_id]; end // Csrrc
	        //32'b???????_?????_?????_101_?????_1110011: begin if (w_rd !== 5'b00000) re[w_rd] <= csre[csr_id]; csre[csr_id] <= {59'b0, w_zimm}; end // Csrrwi
	        //32'b???????_?????_?????_110_?????_1110011: begin re[w_rd] <= csre[csr_id]; if (w_zimm !== 5'b00000) csre[csr_id] <= {59'b0, w_zimm } | csre[csr_id]; end // csrrsi
	        //32'b???????_?????_?????_111_?????_1110011: begin re[w_rd] <= csre[csr_id]; if (w_zimm !== 5'b00000) csre[csr_id] <= ~{59'b0, w_zimm } & csre[csr_id]; end // Csrrci
	        //// Fence
	        //32'b???????_?????_?????_000_?????_0001111: begin end // Fence
	        //32'b???????_?????_?????_001_?????_0001111: begin end // Fencei
                //// Ecall
	        //32'b0000000_00000_?????_000_?????_1110011: begin  // func12 
                //                                    // Trap into S-mode
	        //                                    if (current_privilege_mode == U_mode && medeleg[8] == 1)
	        //     			       begin
	        //     			           csre[scause][63] <= 0; //63_type 0exception 1interrupt|value
	        //     			           csre[scause][62:0] <= 8; // 8 indicate Ecall from U-mode; 9 call from S-mode; 11 call from M-mode
	        //     			           csre[sepc] <= pc;
	        //     			           csre[sstatus][8] <= 0; // save previous privilege mode(user0 super1) to SPP 
	        //     			           csre[sstatus][5] <= csre[sstatus][1]; // save interrupt enable(SIE) to SPIE 
	        //     			           csre[sstatus][1] <= 0; // clear SIE
	        //     			           //if ((csre[scause][63]==1'b1) && (csre[stvec][1:0]== 2'b01)) pc <= (csre[stvec][63:2] << 2) + (csre[scause][62:0] << 2);
	        //     			           pc <= (csre[stvec][63:2] << 2);
	        //     				   current_privilege_mode <= S_mode;
		//				   bubble <= 1'b1;
	        //     			       end
	        //     			       // Trap into M-mode
	        //     			       else 
	        //     			       begin
	        //     			           csre[mcause][63] <= 0; //63_type 0exception 1interrupt|value
	        //     			           csre[mepc] <= pc;
	        //     			           csre[mstatus][7] <= csre[mstatus][3]; // save interrupt enable(MIE) to MPIE 
	        //     			           csre[mstatus][3] <= 0; // clear MIE (not enabled)
	        //     			           pc <= (csre[mtvec][63:2] << 2);
	        //                                        if (current_privilege_mode == U_mode && medeleg[8] == 0) csre[mcause][62:0] <= 8; // save cause 
	        //                                        if (current_privilege_mode == S_mode) csre[mcause][62:0] <= 9; 
	        //     			           if (current_privilege_mode == M_mode) csre[mcause][62:0] <= 11; 
	        //     				   csre[mstatus][12:11] <= current_privilege_mode; // save privilege mode to MPP 
	        //     				   current_privilege_mode <= M_mode;  // set current privilege mode
		//				   bubble <= 1'b1;
	        //     			       end
	        //     			       end
                //// Ebreak
	        //32'b0000000_00001_?????_000_?????_1110011: begin  end
	        //// Sret
	        //32'b0001000_00010_?????_000_?????_1110011: begin      
	        //     			       if (csre[sstatus][8] == 0) current_privilege_mode <= U_mode;
	        //     			       if (csre[sstatus][8] == 1) current_privilege_mode <= S_mode;
	        //     			       csre[sstatus][1] <= csre[sstatus][5]; // set back interrupt enable(SIE) by SPIE 
	        //     			       csre[sstatus][5] <= 1; // set previous interrupt enable(SIE) to be 1 (enable)
	        //     			       csre[sstatus][8] <= 0; // set previous privilege mode(SPP) to be 0 (U-mode)
	        //     			       pc <=  csre[sepc]; // sepc was +4 by the software handler and written back to sepc
		//			       bubble <= 1'b1;
	        //     			       end
                //// Mret
	        //32'b0011000_00010_?????_000_?????_1110011: begin  
	        //   			       csre[mstatus][3] <= csre[mstatus][7]; // set back interrupt enable(MIE) by MPIE 
	        //   			       csre[mstatus][7] <= 1; // set previous interrupt enable(MIE) to be 1 (enable)
	        //   			       if (csre[mstatus][12:11] < M_mode) csre[mstatus][17] <= 0; // set mprv to 0
	        //   			       current_privilege_mode  <= csre[mstatus][12:11]; // set back previous mode
	        //   			       csre[mstatus][12:11] <= 2'b00; // set previous privilege mode(MPP) to be 00 (U-mode)
	        //   			       pc <=  csre[mepc]; // mepc was +4 by the software handler and written back to sepc
		//      		       bubble <= 1'b1;
	        //   			       end
    	        endcase
	   end
           re[0] <= 64'h0;  // x0 hardwared 0
        end
    end
endmodule



module clock_divider(
    input wire clk_in,
    output reg clk_out
    );
    reg [24:0] counter;
    initial begin
	clk_out <= 0;
	counter <= 0;
    end
    always @(posedge clk_in) begin
	if (counter == 0) clk_out <= ~clk_out;
	counter <= counter + 1;
    end
endmodule


module Board (
    input wire CLOCK_50,
    input wire KEY0,
    output wire [7:0] LEDG
    );
    
    wire clk_1hz;
    clock_divider clk_inst (
	.clk_in(CLOCK_50),
	.clk_out(clk_1hz)
    );

    wire [63:0] mem_addr, mem_data_in, mem_data_out;
    wire mem_we;

    wire [63:0] i_mem_addr;   // Address of instruction
    wire [31:0] i_mem_data_in; // Instruction backs from memory
    cpu cpu_inst (
	.clock(clk_1hz),
	.reset_n(KEY0),
	.mem_addr(mem_addr),
	.mem_data_in(mem_data_in),
	.mem_data_out(mem_data_out),
        .mem_we(mem_we),
	.i_mem_addr(i_mem_addr),
	.i_mem_data_in(i_mem_data_in)
    );

    (* ram_style = "block" *) reg [63:0] mem [0:3999]; // Unified Memory
    initial $readmemb("mem.mif", mem);

    always @(posedge clk_1hz) begin
        if (mem_we) mem[mem_addr] <= mem_data_out;
        mem_data_in <= mem[mem_addr];
        i_mem_data_in <= mem[i_mem_addr];
    end
    //
   
    // LED display
    reg [1:0] cnt;
    always @(posedge clk_1hz)begin
	cnt <= cnt + 1;
	case (cnt)
	    0: LEDG <= i_mem_data_in[7:0];
	    1: LEDG <= i_mem_data_in[15:8];
	    2: LEDG <= i_mem_data_in[23:16];
	    3: LEDG <= i_mem_data_in[31:24];
	endcase
    end
endmodule


//psf
//set_location_assignment PIN_L1 -to CLOCK_50
//set_location_assignment PIN_R22 -to KEY0
//set_location_assignment PIN_U22 -to LEDG[0]
//set_location_assignment PIN_U21 -to LEDG[1]
//set_location_assignment PIN_V22 -to LEDG[2]
//set_location_assignment PIN_V21 -to LEDG[3]
//set_location_assignment PIN_W22 -to LEDG[4]
//set_location_assignment PIN_W21 -to LEDG[5]
//set_location_assignment PIN_Y22 -to LEDG[6]
//set_location_assignment PIN_Y21 -to LEDG[7]

//mem.mif
//00000001
//00000011
//00000111
//00001111
//00011111
//00111111
//01111111
//11111111
