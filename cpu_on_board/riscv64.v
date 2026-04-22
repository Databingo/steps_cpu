`include "header.vh"

module riscv64(
    input wire clk, 
    input wire reset,     // Active-low reset button
    input wire [31:0] instruction,
    //input wire valid_address,
    output wire [63:0] ppc,
    //output wire  heartbeat,
    output reg [63:0] bus_address,     // 39 bit for real Sv39 standard?
    output reg [63:0] bus_write_data,
    output reg        bus_write_enable,
    output reg        bus_read_enable,
    output reg [2:0]  bus_ls_type, // lb lh lw ld lbu lhu lwu // sb sh sw sd sbu shu swu 

    output reg [63:0] mtime,    // map to 0x0200_bff8 
    //inout wire [63:0] mtimecmp, // map to 0x0200_4000 + 8byte*hartid
    input wire [63:0] mtimecmp, // map to 0x0200_4000 + 8byte*hartid

    input wire meip_interrupt, // from PLIC
    input wire seip_interrupt, // from Supervisor External
    //input wire msip_interrupt, // from CLINT
    //input wire mtip_interrupt, // from Machine Time

    input  reg        bus_read_done,
    input  reg        bus_write_done,
    input  wire [63:0] bus_read_data   // from outside
);

wire meip = Csrs[mip][MEIP] && Csrs[mie][MEIE];  // mip:P Hardware say pending;|mie:E Software allow this pending;|mstatus[MIE]:cpu globally allow interrup # 3 conditions for a interrup run
wire mtip = Csrs[mip][MTIP] && Csrs[mie][MTIE];  // irq level: MEI MTI MSI 7
wire msip = Csrs[mip][MSIP] && Csrs[mie][MSIE];  // opensbi csr set
wire seip = Csrs[mip][SEIP] && Csrs[mie][SEIE];  // hardware sip-> local sie-> global mstatus.SIE-> cpu take by irq-> trap spie=sie/sie=0 (this need after mideleg)
wire stip = Csrs[mip][STIP] && Csrs[mie][STIE];  // opensbi trap in mtip -> set stip 5
wire ssip = Csrs[mip][SSIP] && Csrs[mie][SSIE];  // software csr set


wire m_interrupts = (meip || msip || mtip) && (current_privilege_mode < M_mode || (current_privilege_mode == M_mode && Csrs[mstatus][MIE]));
wire s_interrupts = (seip || ssip || stip) && (current_privilege_mode < S_mode || (current_privilege_mode == S_mode && Csrs[sstatus][SIE]));
wire any_interrupt = (m_interrupts || s_interrupts);


(* keep = 1 *) reg [63:0] pc;
wire [31:0] ir;

(* ram_style = "logic" *) reg [63:0] re [0:31]; // General Registers 32s
(* ram_style = "logic" *) reg [63:0] sre [0:10]; // Shadow Registers 11s
reg mmu_da=0;
reg mmu_pc = 0;
//reg debug = 0;
reg did = 1;
reg in_debug = 0;
reg i_cache_refill=0;
wire STrap = (mmu_pc || mmu_da || i_cache_refill || in_debug);
wire is_mem_access = (op == 7'b0000011 || op == 7'b0100011 || op == 7'b0101111); //load/store/atm
reg [63:0] saved_user_pc;
integer i; 

// --- Privilege Modes ---
localparam M_mode = 2'b11;
localparam S_mode = 2'b01;
localparam U_mode = 2'b00;
reg [1:0] current_privilege_mode;

// -- Immediate decoders  -- 
wire signed [63:0] w_imm_u = {{32{ir[31]}}, ir[31:12], 12'b0};  // U-type immediate Lui Auipc
wire signed [63:0] w_imm_i = {{52{ir[31]}}, ir[31:20]};   // I-type immediate Lb Lh Lw Lbu Lhu Lwu Ld Jalr Addi Slti Sltiu Xori Ori Andi Addiw 
wire signed [63:0] w_imm_s = {{52{ir[31]}}, ir[31:25], ir[11:7]};  // S-type immediate Sb Sh Sw Sd
wire signed [63:0] w_imm_j = {{44{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0}; // UJ-type immediate Jal  // read immediate & padding last 0, total 20 + 1 = 21 bits
wire signed [63:0] w_imm_b = {{52{ir[31]}}, ir[7],  ir[30:25], ir[11:8], 1'b0}; // B-type immediate Beq Bne Blt Bge Bltu Bgeu // read immediate & padding last 0, total 12 + 1 = 13 bits
wire        [63:0] w_imm_z = {59'b0, ir[19:15]};  // CSR zimm zero-extending unsigned
wire [5:0] w_shamt = ir[25:20]; // If 6 bits the highest is always 0??
// -- Register decoder --
wire [4:0] w_rd  = ir[11:7];
wire [4:0] w_rs1 = ir[19:15];
wire [4:0] w_rs2 = ir[24:20];
// -- Func decoder --
wire [2:0] w_func3   = ir[14:12];
wire [4:0] w_func5   = ir[31:27];
wire [6:0] w_func7   = ir[31:25]; 
wire [11:0] w_func12 = ir[31:20]; 
// -- rs1 rs2 value --
wire signed [63:0] rs1 = re[w_rs1];
wire signed [63:0] rs2 = re[w_rs2];
// -- op --
wire [6:0] op = ir[6:0];
//wire [11:0] w_f12 = ir[31:20];   // ecall 0, ebreak 1
//-- csr --
wire [11:0] w_csr = ir[31:20];   // CSR official address
wire [63:0] pc_4 = pc - 4;

// Shared Arithmetic Units
wire use_imm = (op == 7'b0010011 || op == 7'b0011011 || op == 7'b1100111); //math-i math-i-w jalr 
wire is_sub = (op == 7'b0110011 || op == 7'b0111011) && ir[30]; // sub/subw
wire [63:0] alu_op2 = use_imm ? w_imm_i : rs2;
wire [63:0] alu_op2_inv = is_sub ? ~alu_op2 : alu_op2;
//wire [63:0] shared_add = $signed(rs1) + $signed(alu_op2_inv) + $signed({63'b0, is_sub});
//wire [31:0] shared_addw_32 = rs1[31:0] + alu_op2_inv[31:0] + is_sub;
//wire [63:0] shared_addw = {{32{shared_addw_32[31]}}, shared_addw_32};
wire [63:0] shared_add = rs1 + alu_op2_inv + is_sub;
wire [63:0] shared_addw= $signed(rs1[31:0] + alu_op2_inv[31:0] + is_sub);

wire [63:0] alu_add  = shared_add; 
wire [63:0] alu_sub  = shared_add;  
wire [63:0] alu_addi = shared_add; 
wire [63:0] alu_addw = shared_addw;  
wire [63:0] alu_subw = shared_addw;  
wire [63:0] alu_addiw= shared_addw; 

wire [63:0] alu_slt  = ($signed(rs1) < $signed(alu_op2)) ? 1:0;
wire [63:0] alu_slti = alu_slt;
wire [63:0] alu_sltu = ($unsigned(rs1) < $unsigned(alu_op2)) ? 1:0;
wire [63:0] alu_sltiu= alu_sltu;

wire [63:0] alu_xor  = rs1 ^ alu_op2;
wire [63:0] alu_xori = alu_xor;
wire [63:0] alu_and  = rs1 & alu_op2;
wire [63:0] alu_andi = alu_and;
wire [63:0] alu_or   = rs1 | alu_op2;
wire [63:0] alu_ori  = alu_or;

wire [63:0] branch = pc_4 + w_imm_b; //branch

wire is_imm_shift  = (op == 7'b0010011 || op == 7'b0011011); // Slli Srli Srai || Slliw Srliw Sraiw
wire is_word_shift = (op == 7'b0111011 || op == 7'b0011011); // Sllw Srlw Sraw || Slliw Srliw Sraiw
wire is_arith_shift = ir[30]; // sra/sraw/srai/sraiw

wire [5:0] shift_amt = is_imm_shift ? w_shamt : rs2[5:0];
wire [5:0] final_shift_amt = is_word_shift ? {1'b0, shift_amt[4:0]} : shift_amt;
wire [63:0] shift_to_right = is_word_shift ? {{32{is_arith_shift & rs1[31]}}, rs1[31:0]}: rs1;

wire [63:0] raw_sll = rs1 << final_shift_amt;
wire [63:0] raw_srl_sra = is_arith_shift ? ($signed(shift_to_right) >>> final_shift_amt): (shift_to_right >> final_shift_amt);

wire [63:0] shared_sll = is_word_shift ? {{32{raw_sll[31]}}, raw_sll[31:0]} : raw_sll;
wire [63:0] shared_srl_sra = is_word_shift ? {{32{raw_srl_sra[31]}}, raw_srl_sra[31:0]} : raw_srl_sra;

wire [63:0] w_load_data =
    (w_func3 == 3'b000) ? {{56{bus_read_data[ 7]}}, bus_read_data[ 7:0]} : // lb
    (w_func3 == 3'b001) ? {{48{bus_read_data[15]}}, bus_read_data[15:0]} : // lh
    (w_func3 == 3'b010) ? {{32{bus_read_data[31]}}, bus_read_data[31:0]} : // lw
    (w_func3 == 3'b100) ? { 56'b0,                  bus_read_data[ 7:0]} : // lbu
    (w_func3 == 3'b101) ? { 48'b0,                  bus_read_data[15:0]} : // lhu
    (w_func3 == 3'b110) ? { 32'b0,                  bus_read_data[31:0]} : // lhw
    bus_read_data ; // ld (011)

wire [63:0] w_store_data = 
    (w_func3 == 3'b000) ? {56'b0, rs2[ 7:0]} : // sb
    (w_func3 == 3'b001) ? {48'b0, rs2[15:0]} : // sh
    (w_func3 == 3'b010) ? {32'b0, rs2[31:0]} : // sw
    rs2;        // sd (011)
// AMO prepare -----------
wire is_word_op = (w_func3 == 3'b010);  // word as signed 32-bit values
wire [63:0] amo_op_mem = is_word_op ? {{32{bus_read_data[31]}}, bus_read_data[31:0]} : bus_read_data;
wire [63:0] amo_op_rs2 = is_word_op ? {{32{rs2[31]}}, rs2[31:0]} : rs2;

// Unin amomin amomax/amominu amomaxu 11xxx (unsigned w_func5[3]== 1)
wire amo_less_than = w_func5[3] ? (amo_op_mem < amo_op_rs2) : ($signed(amo_op_mem) < $signed(amo_op_rs2));

// selecet min/max resutl
wire amo_pick_mem = (w_func5[2] == 0) ? amo_less_than : !amo_less_than;
wire [63:0] val_minmax = amo_pick_mem ? amo_op_mem : amo_op_rs2;

// calculate
wire [63:0] val_add = amo_op_mem + amo_op_rs2;
wire [63:0] val_xor = amo_op_mem ^ amo_op_rs2;
wire [63:0] val_and = amo_op_mem & amo_op_rs2;
wire [63:0] val_or  = amo_op_mem | amo_op_rs2;

// write back memory data
wire [63:0] w_amo_calc_data = 
    (w_func5 == 5'b00001) ? amo_op_rs2 : // swap
    (w_func5 == 5'b00000) ? val_add    : // add
    (w_func5 == 5'b00100) ? val_xor    : // xor
    (w_func5 == 5'b01100) ? val_and    : // and
    (w_func5 == 5'b01000) ? val_or     : // or
    val_minmax ; // min/max/minu/maxu
// formatting sc.w/sc.d/amo
wire [63:0] w_atomic_write_data = (op == 7'b0101111 && w_func5[4:0] == 5'b00011) ? // SC
    (is_word_op ? {32'b0, rs2[31:0]} : rs2) : // sc.w/sc.d
    w_amo_calc_data; // AMOs -----------

// Indepenedent Multiplier Mul // Booth algorithim + Signed-correct
reg [6:0]   mul_cnt;
reg [127:0] mul_acc;  // result|multiplier
reg [63:0]  mul_a_reg; // 被乘数(绝对值)
reg         mul_active;
reg         mul_done;
reg         mul_enable;

reg mul_neg_result;
reg [2:0] mul_op_type;

reg  mul_is_w_latched;
reg  [63:0] raw_a_latched;
reg  [63:0] raw_b_latched;
reg  a_is_signed_latched;
reg  b_is_signed_latched;
reg  [63:0] abs_a_latched;
reg  [63:0] abs_b_latched;
reg  [4:0] mul_rd_latched;

// 000mul 001mulh 010mulhsu 011mulhu
wire mul_is_w = (op == 7'b0111011); // Mulw (opc 0111011)
wire [63:0] raw_a = mul_is_w ? {{32{rs1[31]}}, rs1[31:0]} : rs1;
wire [63:0] raw_b = mul_is_w ? {{32{rs2[31]}}, rs2[31:0]} : rs2;

wire a_is_signed = mul_is_w ? 1'b1 : (w_func3 != 3'b011); // signed except Mulhu
wire b_is_signed = mul_is_w ? 1'b1 : (w_func3 == 3'b000 || w_func3 == 3'b001); // signed Mul/Mulh

wire [63:0] abs_a = (a_is_signed & raw_a[63])? (~raw_a+64'd1):raw_a; 
wire [63:0] abs_b = (b_is_signed & raw_b[63])? (~raw_b+64'd1):raw_b; 
wire [64:0] add_res = {1'b0, mul_acc[127:64]} + {1'b0, mul_a_reg};

always @(posedge clk or negedge reset) begin  
    if (!reset) begin
	mul_active <= 0;
	mul_done   <= 0;
	mul_cnt    <= 0;	    
	mul_acc    <= 0;
    end else begin
	if (mul_enable && !mul_active && !mul_done) begin // Start phase
	    mul_active <= 1;
	    mul_cnt    <= 0;
	    mul_a_reg  <= abs_a_latched;
	    mul_acc <= {64'b0, abs_b_latched};
	    mul_neg_result <= (a_is_signed_latched && raw_a_latched[63]) ^ (b_is_signed_latched && raw_b_latched[63]);

	end else if (mul_active) begin // Compute phase (64 cycles)
	    if (mul_cnt < 64) begin
		if (mul_acc[0]) mul_acc <= {add_res, mul_acc[63:1]}; // is 1,  + and >> 1
		else mul_acc <= {1'b0, mul_acc[127:1]}; // is 0, only >> 1, preserve sign bit
		mul_cnt <= mul_cnt + 1;
	end else begin // Finish phase
	    mul_active <= 0;
	    mul_done   <= 1;
	end
    end else if (!mul_enable) mul_done <= 0; // reset handshake
end
    end

    wire [127:0] final_mul_res = mul_neg_result ? ~mul_acc+128'd1 : mul_acc;
    wire is_high_mul = (mul_op_type == 3'b001) || (mul_op_type == 3'b010) || (mul_op_type == 3'b011);
    wire [63:0] w_mul_out = 
	(mul_is_w_latched) ? {{32{final_mul_res[31]}}, final_mul_res[31:0]}: // mulw
	(is_high_mul) ? final_mul_res[127:64]:// mulh, mulhsu, mulhu
	final_mul_res[63:0];// mul

	// Independent divider Div
	reg [6:0]   div_cnt;
	reg [127:0] div_rem;   // remainder|quotient
	reg [63:0]  div_a;    // be divided
	reg [63:0]  div_b;    // divisor
	reg         div_active; // 1computing, 0idle
	reg         div_done;   // handshake 1result ready
	reg         div_enable; // handshake 1start request
	reg         div_is_rem; // 1rem, 0div
	reg [63:0]  div_result_out; // final output buffer
	reg [4:0]   div_rd; 
	reg         div_op_signed;
	reg         div_is_w_latched;

	wire div_is_w = (op == 7'b0111011); //  divw100 divuw101  remw110 remuw111 (opc 0111011)
	wire a_is_neg = div_op_signed && div_a[63];
	wire b_is_neg = div_op_signed && div_b[63];
	wire [63:0] div_abs_a = a_is_neg ? (~div_a + 64'd1):div_a;
	wire [63:0] div_abs_b = b_is_neg ? (~div_b + 64'd1):div_b;
	wire out_sign_quo = div_op_signed && (div_a[63] ^ div_b[63]);
	wire out_sign = div_is_rem ? a_is_neg : out_sign_quo;
	wire [63:0] raw_out = div_is_rem ? div_rem[127:64] : div_rem[63:0];
	wire [63:0] final_out = out_sign ? (~raw_out+64'd1): raw_out;

	always @(posedge clk or negedge reset) begin
	    if (!reset) begin
		div_active <= 0;
		div_done   <= 0;
		div_cnt    <= 0;
	    end else begin
		if (div_enable && !div_active && !div_done) begin // start phase
		    div_active <= 1;
		    div_cnt <= 0;
		    if (div_b == 0) begin // handle corner case
			div_result_out <= div_is_rem ? div_a : ~64'd0; // divide by zero
			div_active <= 0;
			div_done <= 1; // finish immediately
		    end
		    else if (div_op_signed && div_a == 64'h8000000000000000 && div_b == ~64'd0) begin // ?? Overflow INT_MIN/-1 = INT_MIN
			div_result_out <= div_is_rem ? 64'd0 : div_a; // signed overflow
		    div_active <= 0;
		    div_done <= 1; // finish immediately
		end
		else begin 
		    div_rem <= {64'd0, div_abs_a};
		end
	    end else if (div_active) begin // compute phase (64 cycles)
		if (div_cnt < 64) begin
		    if (div_rem[126:63] >= div_abs_b) begin
			div_rem <= {div_rem[126:63] - div_abs_b, div_rem[62:0], 1'b1};
		    end else begin
			div_rem <= {div_rem[126:0], 1'b0};
		    end
		    div_cnt <= div_cnt + 1;
		end else begin // finish phase
		    div_active <= 0;
		    div_done   <= 1;
		    div_result_out <= final_out;
		end
	    end else if (!div_enable) div_done <= 0; // reset handshake
	end
end

// --Machine CSR --
localparam mstatus    = 0 ; localparam MPRV=17,MPP=11,SPP=8,MPIE=7,SPIE=5,MIE=3,SIE=1,UIE=0;//63_SD|37_MBE|36_SBE|35:34_SXL10|22_TSR|21_TW|20_TVW|17_MPRV|12:11MPP|8SPP|7MPIE|5SPIE|3MIE|1SIE|0UIE
localparam sstatus    = 0 ; localparam SD=63,UXL=32,MXR=19,SUM=18,XS=15,FS=13,VS=9,UBE=6; //SPP=8,SPIE=5,SIE=1,//63SD|33:32UXL|19MXR|18SUM|16:15XS|14:13FS|10:9VS|8SPP|6UBE|5SPIE|1SIE
localparam sstatus_mask  = 64'h8000_0003_000D_E122; // SD,UXL,MXR,SUM,XS,FS,SPP,SPIE,SIE only from mirror mstatus, RVV E722

localparam mtvec      = 1 ; localparam BASE=2,MODE=0; // 63:2BASE|1:0MDOE  // 0x305 MRW Machine trap-handler base address * 0 direct 1vec
localparam mscratch   = 2 ;  // 
localparam mepc       = 3 ;  
localparam mcause     = 4 ; localparam INTERRUPT=63,CAUSE=0,ILLEGAL_INSTRUCTION=2,PAGE_F_I=12,PAGE_F_L=13,PAGE_F_S=15;//0x342 MRW Machine trap casue*63InterruptAsync/ErrorSync|62:0CauseCode

localparam mie        = 5 ; localparam SGEIE=12,MEIE=11,VSEIE=10,SEIE=9,MTIE=7,VSTIE=6,STIE=5,MSIE=3,VSSIE=2,SSIE=1; // Machine Interrupt Enable from OS software set enable
localparam sie        = 5;  // Supervisor interrupt-enable register
localparam sie_sip_mask   = 64'h0000_0000_0000_0222; // SEIE9, STIE5, SSIE1

localparam mip        = 6 ; localparam SGEIP=12,MEIP=11,VSEIP=10,SEIP=9,MTIP=7,VSTIP=6,STIP=5,MSIP=3,VSSIP=2,SSIP=1; // Machine Interrupt Pending from HardWare timer,uart,PLIC.11Exter7Time3Software
localparam sip        = 6;  // Supervisor interrupt pending
//localparam sip_mask   = 64'h0000_0000_0000_0222; // SEIP, STIP, SSIP
localparam sip_write_mask   = 64'h0000_0000_0000_0002; // SSIP
wire [63:0] csr_mask  = (w_csr == 12'h100) ? sstatus_mask : (w_csr == 12'h104) ? (sie_sip_mask & Csrs[mideleg]) : (w_csr == 12'h144) ? (sie_sip_mask   & Csrs[mideleg]) : 64'hffff_ffff_ffff_ffff;
wire [63:0] csr_mask_w= (w_csr == 12'h100) ? sstatus_mask : (w_csr == 12'h104) ? (sie_sip_mask & Csrs[mideleg]) : (w_csr == 12'h144) ? (sip_write_mask & Csrs[mideleg]) : 64'hffff_ffff_ffff_ffff;
//wire [63:0] csr_read  = Csrs[w_csr_id] & csr_mask;
//wire [63:0] csr_read = (w_csr == 12'hC01) ? mtime : Csrs[w_csr_id] & csr_mask;
wire [63:0] csr_read = (w_csr == 12'h301) ? 64'h8000000000141101 : // misa(RV64IMASU)
                       (w_csr == 12'hF11) ? 64'h0 : // mvendorid
                       (w_csr == 12'hF12) ? 64'h0 : // marchid
                       (w_csr == 12'hF13) ? 64'h0 : // mimpid
                       (w_csr == 12'hF14) ? 64'h0 : // mhartid
                       (w_csr == 12'hC01) ? mtime : // clint_time
		        Csrs[w_csr_id] & csr_mask;  // Other
wire [63:0] csr_write_re  = rs1 & csr_mask_w;
wire [63:0] csr_write_im  = w_imm_z & csr_mask_w;

localparam medeleg    = 7 ; localparam MECALL=11,SECALL=9,UECALL=8,BREAK=3; // bit_index=mcause_value 8UECALL|9SECALL
localparam mideleg    = 8 ;  //
localparam sedeleg    = 9;  
localparam sideleg    = 10;  
localparam stvec      = 11;  //localparam ; //BASE=2,MODE=0 63:2BASE|1:0MDOE Supervisor trap handler base address
localparam scounteren = 12;  
localparam sscratch   = 13;  
localparam sepc       = 14;  
localparam scause     = 15;  //localparam ; //INTERRUPT=63,CAUSE=0 *  63InterruptAsync/ErrorSync|62:0CauseCode// 
localparam stval      = 16;  
localparam satp       = 17;  // Supervisor address translation and protection satp[63:60].MODE=0:off|8:SV39 satp[59:44].asid vpn2:9 vpn1:9 vpn0:9 satp[43:0]:rootpage physical addr
localparam mtval      = 18;  // Machine Trap Value Register (bad address or instruction)

localparam marchid    = 19;  // 0
localparam mimpid     = 19;  // 0
localparam mhartid    = 19;  // Hardware Thread ID 0 for single-core
localparam misa       = 19;  // Machine ISA Register (IMA is 0x8000000000001101)
localparam mvendorid  = 19;  // 0
localparam clint_time = 19;  // read only

localparam pmpcfg0    = 20;  // Physical Memory Protection
localparam pmpaddr0   = 21;  // 
localparam mdebug     = 22;  // 
//localparam pmpaddr1   = 29;  // 
//localparam pmpaddr2   = 30;  // 
//localparam pmpaddr3   = 31;  // 
//localparam pmpaddr4   = 32;  // 
//localparam pmpaddr5   = 33;  // 
//localparam pmpaddr6   = 34;  // 
//localparam pmpaddr7   = 35;  // 

//localparam pmpaddr1   = 29;  // 
//localparam pmpaddr2   = 29;  // 
//localparam pmpaddr3   = 29;  // 
//localparam pmpaddr4   = 29;  // 
//localparam pmpaddr5   = 29;  // 
//localparam pmpaddr6   = 29;  // 
//localparam pmpaddr7   = 29;  // 
//integer scontext = 12'h5a8; 
reg [62:0] CAUSE_CODE;
reg  [5:0] w_csr_id;             // CSR id (64)
localparam XCSR = 63;  //  miss csr that not deployed
always @(*) begin
    case(w_csr)
	12'h300 : w_csr_id = mstatus    ;    
	12'h301 : w_csr_id = misa       ;    
	12'h305 : w_csr_id = mtvec      ;    
	12'h340 : w_csr_id = mscratch   ;    
	12'h341 : w_csr_id = mepc       ;    
	12'h342 : w_csr_id = mcause     ;    
	12'h343 : w_csr_id = mtval      ;    
	12'h304 : w_csr_id = mie        ;    
	12'h344 : w_csr_id = mip        ;    
	12'h302 : w_csr_id = medeleg    ;    
	12'h303 : w_csr_id = mideleg    ;    
	12'h100 : w_csr_id = sstatus    ;    
	12'h102 : w_csr_id = sedeleg    ;   
	12'h103 : w_csr_id = sideleg    ;   
	12'h104 : w_csr_id = sie        ;   
	12'h105 : w_csr_id = stvec      ;   
	12'h106 : w_csr_id = scounteren ;   
	12'h140 : w_csr_id = sscratch   ;   
	12'h141 : w_csr_id = sepc       ;   
	12'h142 : w_csr_id = scause     ;   
	12'h143 : w_csr_id = stval      ;   
	12'h144 : w_csr_id = sip        ;   
	12'h180 : w_csr_id = satp       ;   
	12'hF14 : w_csr_id = mhartid    ;   
	12'hF11 : w_csr_id = mvendorid  ;   
	12'hF12 : w_csr_id = marchid    ;   
	12'hF13 : w_csr_id = mimpid     ;   
	12'h3A0 : w_csr_id = pmpcfg0    ;   
	12'h3B0 : w_csr_id = pmpaddr0   ;   
	12'hC01 : w_csr_id = clint_time ;   
	//12'h3B1 : w_csr_id = pmpaddr1   ;   
	//12'h3B2 : w_csr_id = pmpaddr2   ;   
	//12'h3B3 : w_csr_id = pmpaddr3   ;   
	//12'h3B4 : w_csr_id = pmpaddr4   ;   
	//12'h3B5 : w_csr_id = pmpaddr5   ;   
	//12'h3B6 : w_csr_id = pmpaddr6   ;   
	//12'h3B7 : w_csr_id = pmpaddr7   ;   
	//default : w_csr_id = 36; 
	12'h7CC : w_csr_id = mdebug     ;   
	default : w_csr_id = XCSR; 
    endcase
end


//(* ram_style = "logic" *) reg [63:0] Csrs [0:36]; // 36 CSRs for now // totally 4096
(* ram_style = "logic" *) reg [63:0] Csrs [0:22]; // 36 CSRs for now // totally 4096
wire [3:0]  satp_mmu  = Csrs[satp][63:60]; // 0:bare, 8:sv39, 9:sv48  satp.MODE!=0, privilegae is not M-mode, mstatus.MPRN is not set or in MPP's mode?

// -- Timer --
always @(posedge clk or negedge reset) begin if (!reset) mtime <= 0; else mtime <= mtime + 1; end
wire mtip_interrupt = (mtime >= mtimecmp);

// -- Innerl signal --
reg bubble;
reg [1:0] load_step;
reg [1:0] store_step;

// -- Atomic & Sync state --
reg [63:0] reserve_addr;
reg        reserve_valid;

//// -- TLB -- 8 pages
//(* ram_style = "logic" *) reg [26:0] tlb_vpn [0:7]; // vpn number VA[38:12]  Sv39
//(* ram_style = "logic" *) reg [43:0] tlb_ppn [0:7]; // ppn number PA[55:12]
//(* ram_style = "logic" *) reg tlb_vld [0:7];
// -- TLB i -- 4 pages
(* ram_style = "logic" *) reg [26:0] tlb_vpn [0:3]; // vpn number VA[38:12]  Sv39
(* ram_style = "logic" *) reg [43:0] tlb_ppn [0:3]; // ppn number PA[55:12]
(* ram_style = "logic" *) reg tlb_vld [0:3];

// TLB-I
wire [26:0] pc_vpn = pc[38:12];
reg [43:0] pc_ppn;
reg tlb_i_hit;

//wire [7:0] tlb_i_match; // 8page
wire [3:0] tlb_i_match; // 4page
assign tlb_i_match[0] = tlb_vld[0] && (tlb_vpn[0] == pc_vpn);
assign tlb_i_match[1] = tlb_vld[1] && (tlb_vpn[1] == pc_vpn);
assign tlb_i_match[2] = tlb_vld[2] && (tlb_vpn[2] == pc_vpn);
assign tlb_i_match[3] = tlb_vld[3] && (tlb_vpn[3] == pc_vpn);
//assign tlb_i_match[4] = tlb_vld[4] && (tlb_vpn[4] == pc_vpn);
//assign tlb_i_match[5] = tlb_vld[5] && (tlb_vpn[5] == pc_vpn);
//assign tlb_i_match[6] = tlb_vld[6] && (tlb_vpn[6] == pc_vpn);
//assign tlb_i_match[7] = tlb_vld[7] && (tlb_vpn[7] == pc_vpn);
// pc_ppn hit
always @(*) begin
    tlb_i_hit = |tlb_i_match;
    pc_ppn =   ({44{tlb_i_match[0]}} & tlb_ppn[0]) |
	({44{tlb_i_match[1]}} & tlb_ppn[1]) | //; end
	({44{tlb_i_match[2]}} & tlb_ppn[2]) |
	({44{tlb_i_match[3]}} & tlb_ppn[3]) ; end
	//({44{tlb_i_match[3]}} & tlb_ppn[3]) |
	//({44{tlb_i_match[4]}} & tlb_ppn[4]) |
	//({44{tlb_i_match[5]}} & tlb_ppn[5]) |
	//({44{tlb_i_match[6]}} & tlb_ppn[6]) |
	//({44{tlb_i_match[7]}} & tlb_ppn[7]) ; end
   
   
//// -- TLB d -- 2 pages
//(* ram_style = "logic" *) reg [26:0] tlb_d_vpn [0:1]; // vpn number VA[38:12]  Sv39
//(* ram_style = "logic" *) reg [43:0] tlb_d_ppn [0:1]; // ppn number PA[55:12]
//(* ram_style = "logic" *) reg tlb_d_vld [0:1]; // only 2 entries
// -- TLB d -- 4 pages
(* ram_style = "logic" *) reg [26:0] tlb_d_vpn [0:3]; // vpn number VA[38:12]  Sv39
(* ram_style = "logic" *) reg [43:0] tlb_d_ppn [0:3]; // ppn number PA[55:12]
(* ram_style = "logic" *) reg tlb_d_vld [0:3]; // only 4 entries
   
	// TLB-D tlb d hit
	wire [63:0] ls_va_offset = (op == 7'b0000011) ? w_imm_i : (op == 7'b0100011) ?  w_imm_s : 64'h0; // load/store/atom
	wire [63:0] ls_va = rs1 + ls_va_offset;
	wire [63:0] pda;
	reg [43:0] data_ppn;
	reg tlb_d_hit;

	//wire [7:0] tlb_d_match;
	wire [3:0] tlb_d_match;
	//wire [1:0] tlb_d_match;
	assign tlb_d_match[0] = tlb_d_vld[0] && (tlb_d_vpn[0] == ls_va[38:12]);
	assign tlb_d_match[1] = tlb_d_vld[1] && (tlb_d_vpn[1] == ls_va[38:12]);
	assign tlb_d_match[2] = tlb_d_vld[2] && (tlb_d_vpn[2] == ls_va[38:12]);
	assign tlb_d_match[3] = tlb_d_vld[3] && (tlb_d_vpn[3] == ls_va[38:12]);
	//assign tlb_d_match[4] = tlb_vld[4] && (tlb_vpn[4] == ls_va[38:12]);
	//assign tlb_d_match[5] = tlb_vld[5] && (tlb_vpn[5] == ls_va[38:12]);
	//assign tlb_d_match[6] = tlb_vld[6] && (tlb_vpn[6] == ls_va[38:12]);
	//assign tlb_d_match[7] = tlb_vld[7] && (tlb_vpn[7] == ls_va[38:12]);
	// data_ppn hit
	always @(*) begin
	    tlb_d_hit = |tlb_d_match;
	    data_ppn = ({44{tlb_d_match[0]}} & tlb_d_ppn[0]) |
		({44{tlb_d_match[1]}} & tlb_d_ppn[1]) | //; end
		({44{tlb_d_match[2]}} & tlb_d_ppn[2]) |
		({44{tlb_d_match[3]}} & tlb_d_ppn[3]) ; end
		//({44{tlb_d_match[3]}} & tlb_ppn[3]) |
		//({44{tlb_d_match[4]}} & tlb_ppn[4]) |
		//({44{tlb_d_match[5]}} & tlb_ppn[5]) |
		//({44{tlb_d_match[6]}} & tlb_ppn[6]) |
		//({44{tlb_d_match[7]}} & tlb_ppn[7]) ; end
		// concat physical address
		wire need_trans = satp_mmu && !STrap && (current_privilege_mode != M_mode);
		assign ppc = need_trans ? {8'h0, pc_ppn, pc[11:0]} : pc;
		assign pda = need_trans ? {8'h0, data_ppn, ls_va[11:0]} : ls_va;

		// TLB Refill
		//reg [2:0] tlb_ptr = 0; // 8 entries TLB
		reg [1:0] tlb_ptr = 0; // 4 entries i TLB
		//reg       tlb_d_ptr = 0; // 2 entries d TLB
		reg [1:0] tlb_d_ptr = 0; // 4 entries d TLB
		//reg tlb_flush_pre = 0;
		//reg tlb_flush;
		always @(posedge clk or negedge reset) begin
		    //tlb_flush_pre <= tlb_flush;
		    if (!reset) begin
			tlb_ptr <= 0; // hit->trap(save va to x9)->refill assembly(fetch pa to x9)-> sd x9, `Tlb -> here to refill tlb
			tlb_vld[0] <= 0; tlb_vld[1] <= 0; tlb_vld[2] <= 0; tlb_vld[3] <= 0; 
			tlb_d_ptr <= 0;
			tlb_d_vld[0] <= 0; tlb_d_vld[1] <= 0; tlb_d_vld[2] <= 0; tlb_d_vld[3] <= 0;  
		    end else if (STrap && bus_write_enable && bus_address == `Tlb) begin // for the last fill: sd ppa, Tlb
			if (re[8] == 12) begin
			tlb_vpn[tlb_ptr] <= re[9][38:12]; // VA from x1 saved by trapp mmu_pc/mmu_da
			tlb_ppn[tlb_ptr] <= bus_write_data[55:12] ; // real 
			tlb_vld[tlb_ptr] <= 1;
			tlb_ptr <= tlb_ptr + 1; 
		        end else begin
			tlb_d_vpn[tlb_d_ptr] <= re[9][38:12]; // VA from x1 saved by trapp mmu_pc/mmu_da
			tlb_d_ppn[tlb_d_ptr] <= bus_write_data[55:12] ; // real 
			tlb_d_vld[tlb_d_ptr] <= 1;
			tlb_d_ptr <= tlb_d_ptr + 1; 
		        end 
		    end else if (!bubble && tlb_i_hit && i_cache_hit) begin // sfence.vma flush any way if ir is (not be bubbled)
			casez (ir) 32'b0001001??????????_000_?????_1110011: begin 
			    tlb_vld[0] <= 0; tlb_vld[1] <= 0; tlb_vld[2] <= 0; tlb_vld[3] <= 0; 
			    tlb_d_vld[0] <= 0; tlb_d_vld[1] <= 0; tlb_d_vld[2] <= 0; tlb_d_vld[3] <= 0; end
		        endcase 
		        //if (tlb_flush_pre != tlb_flush) begin tlb_vld[0] <= 0; tlb_vld[1] <= 0; tlb_vld[2] <= 0; tlb_vld[3] <= 0; end
		    end
	    end

	    // Cache I_cache_hit 63:13 tag, 12:4 index 3:0 offset Cache line 16B (4 instructions) 512 lines
	    reg [127:0] cache_line = 128'h0; //reg [51:0]  cache_tag = 52'h0;
	    reg [58:0]  cache_tag = 58'h0;
	    reg [63:0]  ppc_pre = 64'h0; // for read
	    reg [63:0]  ask_i_data; // for write
	    //(* ram_style = "block" *) reg [127:0] Cache_L [0:1023]; // 16KB
	    (* ram_style = "block" *) reg [63:0] Cache_L_Low [0:511]; // 4KB
	    (* ram_style = "block" *) reg [63:0] Cache_L_High [0:511]; // 4KB
	    //(* ram_style = "block" *) reg [50:0] Cache_T [0:511];  // ~4KB (addr: 51(tag) + 9(index) + 4(offset))
	    //reg [511:0] cache_valid_bits = 0;
	    (* ram_style = "block" *) reg [58:0] Cache_T [0:511];  // 8-bit epoth + 51-bit tag
	    reg [7:0] cache_epoch = 1;

	    reg flush_pre = 0; 
	    reg flush = 0;
	    always @(posedge clk) begin 
		// Flush
		flush_pre <= flush;
		//if (flush_pre != flush) cache_valid_bits <= 512'b0;
		if (flush_pre != flush) cache_epoch <= cache_epoch + 1;
		// Read
	    cache_line <= {Cache_L_High[ppc[12:4]], Cache_L_Low[ppc[12:4]]}; 
	    //cache_tag <= {cache_valid_bits[ppc[12:4]], Cache_T[ppc[12:4]]}; 
	    cache_tag <= Cache_T[ppc[12:4]]; 
	    ppc_pre <= ppc;
	    // Write
	    if (i_cache_refill && bus_write_enable && bus_address == `CacheI_L) begin Cache_L_Low[ask_i_data[12:4]] <= bus_write_data; end
	    if (i_cache_refill && bus_write_enable && bus_address == `CacheI_H) begin 
		Cache_L_High[ask_i_data[12:4]] <= bus_write_data; 
		//Cache_T[ask_i_data[12:4]] <= ask_i_data[63:13]; 
		//cache_valid_bits[ask_i_data[12:4]] <= 1'b1;
		Cache_T[ask_i_data[12:4]] <= {cache_epoch, ask_i_data[63:13]}; 
	    end
	end

	//wire i_cache_hit = cache_tag[51] && (ppc_pre[63:13] == cache_tag[50:0]);
	//wire i_cache_hit = (cache_tag[58:51] == cache_epoch) && (ppc_pre[63:13] == cache_tag[50:0]);
	wire i_cache_hit = (cache_tag[58:51] == cache_epoch) && (ppc_pre[63:13] == cache_tag[50:0]) && (flush_pre == flush);
	wire [31:0] cache_i = cache_line[ppc_pre[3:2]*32 +: 32];
	//assign ir = (mmu_pc || mmu_da || i_cache_refill) ? instruction : i_cache_hit ? cache_i : 32'h00000013; // NOP:addi x0, x0, 0;
	assign ir = STrap ? instruction : i_cache_hit ? cache_i : 32'h00000013; // NOP:addi x0, x0, 0;

	// NO cache test
	// wire i_cache_hit = 1;    // no cache trap
	// assign ir = instruction; // no cache
	// -----
	reg do_trap;
	reg trap_is_interrupt;
	reg [62:0] trap_cause;
	reg [63:0] trap_val;
	reg [63:0] trap_epc;

	wire csr_writable = (w_csr_id != misa) && (w_csr_id !=  mvendorid) && (w_csr_id != marchid) && (w_csr_id != mimpid) && (w_csr_id !=  mhartid) && (w_csr_id != clint_time);


	// EXE Instruction 
	always @(posedge clk or negedge reset) begin
	    if (!reset) begin 
		current_privilege_mode <= M_mode;
		bubble <= 1'b0;
		pc <= `Ram_base;
		load_step <= 0;
		store_step <= 0;
		bus_read_enable <= 0;
		bus_write_enable <= 0;
		bus_write_data <= 0;
		bus_address <= `Ram_base;
		// Interrupt re-enable
		Csrs[mstatus][MIE] <= 1;
		mmu_da <= 0;
		for (i=0;i<11;i=i+1) begin sre[i]<= 64'b0; end 
		for (i=0;i<=22;i=i+1) begin Csrs[i]<= 64'b0; end
		Csrs[medeleg] <= 64'hb1af; // delegate to S-mode 1011000110101111 // see VII 3.1.15 mcasue exceptions
		Csrs[mideleg] <= 64'h0222; // delegate to S-mode 0000001000100010 see VII 3.1.15 mcasue interrupt 1/5/9 SSIP(supervisor software interrupt) STIP(time) SEIP(external)
		// Initialize Machine Info for OpenSBI
		//Csrs[misa] <= 64'h8000000000141101; //RV64IMASU extensions(63:62=2 64bits | 1<<0 Atomic| 1<<8 Integer| 1<<12 Multiply| 1<<18 Supervisor| 1 <<20 User) so: 64'h8000000000141101; RV64IMASU
		//Csrs[mhartid] <= 64'd0; // single Core 0
		// mvendorid, marchid, mimpid remain 0
		mmu_pc <= 0;
		in_debug <= 0;
		reserve_addr <= 0;
		reserve_valid <= 0;

	    end else begin
		pc <= pc + 4; // Default PC+4    (1.Could be overwrite 2.Take effect next cycle) 
		bus_read_enable <= 0;
		bus_write_enable <= 0; 

		do_trap = 0;
		trap_is_interrupt = 0;
		trap_cause = 0;
		trap_val = 0;
		trap_epc = 0;

		//if (bus_read_done && bus_write_done && !load_step && !store_step) debug <= 1;
		//if (!STrap && !bubble && !load_step && !store_step && did) begin did <= 0;
		//if (!STrap && !bubble && bus_read_done && bus_write_done && did)  begin did <= 0;
		if (!STrap && !bubble && did)  begin did <= 0; end
		// -- UPPER is default change for EXE stage --- but (1.Could be overwrite 2.Take effect next cycle) 
    
                // meip/seip is triggered by Plic_pending, mtip is triggered by inner Timer, stip is set by mtip trap handler, msip set by opensbi csr, ssip set by software csr
		Csrs[mip][MEIP] <= meip_interrupt; 
		Csrs[mip][MTIP] <= mtip_interrupt; // MTIP linux will see then jump to its handler  mtime>=mtimecmp
		Csrs[mip][SEIP] <= seip_interrupt;
		//Csrs[mip][MSIP] <= msip_interrupt;  

		//  i-tlb miss STrap
            if (need_trans && !tlb_i_hit) begin //OPEN 
                mmu_pc <= 1; // MMU_PC ON 
                pc <= 0;     // trap to isr_router
                bubble <= 1'b1; // bubble IF for new pc value 
                saved_user_pc <= pc_4; // !!! save pc (EXE was flushed so record-redo it, previous pc)
                //if (bubble || ir==32'b0001001??????????_000_?????_1110011) saved_user_pc <= pc ; // !!! save pc (j/b EXE was flushed currectly, vma executed anyway no need back-redo)
                if (bubble) saved_user_pc <= pc ; // !!! save pc (j/b EXE was flushed currectly, vma executed only in EXEcuting)
                for (i=1;i<11;i=i+1) begin sre[i]<= re[i]; end // save re
                re[9] <= pc;// - 4; // save this vpc to x1 //!!!! We also need to refill pc - 4' ppc for re-executeing pc-4, with hit(if satp in for very next sfence.vma) 
                re[8] <= 12 ;// save in x8 trap type 0 i-tlb trap so record as instruciont page fault for prepare
                //Csrs[mstatus][MPIE] <= Csrs[mstatus][MIE]; // disable interrupt during shadow mmu walking
                //Csrs[mstatus][MIE] <= 0; !!

                // Bubble
            end else if (bubble) begin bubble <= 1'b0; // Flush this cycle & Clear bubble signal for the next cycle

            // i-cache miss STrap (at EXE stage without stap/tlb_hit sensitive)
	    end else if (!STrap && !i_cache_hit) begin //OPEN 
		i_cache_refill <= 1; // 
		pc <= 0; // trap to isr_router
		bubble <= 1'b1; // bubble 
		for (i=1;i<11;i=i+1) begin sre[i]<= re[i]; end // save re
		saved_user_pc <= pc_4  ; // ??!!! save pc (j/b EXE was flushed currectly)
		re[9] <= {ppc_pre[63:4], 4'b0};// save missed ppc_pre cache_line address for handler
		ask_i_data <= {ppc_pre[63:4], 4'b0};// save missed ppc_pre cache_line address for hardware
		if (pc == `Ram_base) begin // initial situation
		    saved_user_pc <= pc; // first pc
		    re[9] <= {ppc[63:4], 4'b0};// save missed ppc_pre cache_line address for handler
		    ask_i_data <= {ppc[63:4], 4'b0};// save missed ppc_pre cache_line address for hardware
		end
		re[8] <= 1;// save x2 trap type 1 i-cache trap

		// d-tlb miss STrap load/store/atom
	    //end else if (need_trans && !tlb_d_hit && (op == 7'b0000011 || op == 7'b0100011 || op == 7'b0101111) ) begin  
	    end else if (need_trans && !tlb_d_hit && is_mem_access) begin  
		mmu_da <= 1; // MMU_DA ON
		pc <= 0; // trap to isr_router
		bubble <= 1'b1; // bubble
		saved_user_pc <= pc_4; // save pc EXE l/s/a
		for (i=1;i<11;i=i+1) begin sre[i]<= re[i]; end // save re
		re[9] <= ls_va; //save va to x1
		re[8] <= (op == 7'b0000011) ? 13 : 15;// save x2 trap type load/store_atom
		//Csrs[mstatus][MIE] <= Csrs[mstatus][MPIE]; // set back interrupt status
    
	    //end else if (!STrap && !valid_address && is_mem_access) begin
	    //    mmu_da <= 1; // MMU_DA ON
	    //    pc <= 0; // trap to isr_router
	    //    bubble <= 1'b1; // bubble
	    //    saved_user_pc <= pc_4; // save pc EXE l/s/a
	    //    for (i=1;i<11;i=i+1) begin sre[i]<= re[i]; end // save re
	    //    re[9] <= ls_va; //save va to x1
	    //    //re[8] <= (op == 7'b0000011) ? 13 : 14;// save x2 trap type load/store_atom
	    //    re[8] <= 17; // save 17 for invalid address
            //    Csrs[mimpid] <=  pda;
            //    Csrs[marchid] <= ppc;
            //    Csrs[mvendorid] <= ir;
	    end else if (Csrs[mdebug] && !STrap && !did && !load_step && !store_step && !mul_enable && !div_enable) begin
		in_debug <= 1;
		pc <= 0; // trap to isr_router
		bubble <= 1'b1; // bubble
		saved_user_pc <= pc_4; // save pc EXE l/s/a
		for (i=1;i<11;i=i+1) begin sre[i]<= re[i]; end // save re
		re[9] <= ls_va; //save va to x1
		//re[8] <= (op == 7'b0000011) ? 13 : 14;// save x2 trap type load/store_atom
		re[8] <= 18; // save 18 for debug
                Csrs[mimpid] <=  pda;
                Csrs[marchid] <= ppc;
                Csrs[mvendorid] <= ir;

            // Back from STrap
	    end else if (STrap && ir == 32'b00110000001000000000000001110011) begin // for the fauld fill: sd ppa, Tlb_fault
		pc <= saved_user_pc; // recover from shadow when see Mret
		bubble <= 1'b1; // bubble
		for (i=1;i<11;i=i+1) begin re[i]<= sre[i]; end // recover usr re
		mmu_pc <= 0; mmu_da <= 0; i_cache_refill<= 0;
		//debug <= 0;
		in_debug <= 0;
		did <= 1;
		if (re[8]!=0) begin // Trap to Page Fault
		    do_trap = 1;
		    trap_cause = re[8];
		    trap_val = re[9];
		    trap_epc = saved_user_pc;
		end

		// Async Interrupt PLIC full (Platform-Level-Interrupt-Control)  MMIO (hardwire timers uart plic)
	    //end else if ((meip_interrupt || msip_interrupt || mtip_interrupt || seip_interrupt) && Csrs[mstatus][MIE]==1 && !STrap && !load_step && !store_step) begin //mstatus[3] MIE
	    //end else if ((meip|| msip|| mtip|| seip || stip) && Csrs[mstatus][MIE]==1 && !STrap && !load_step && !store_step) begin //mstatus[3] MIE
	    end else if (any_interrupt && !STrap && !load_step && !store_step) begin //mstatus[3] MIE // cpu0_intc
		//Csrs[mip][MTIP] <= mtip_interrupt; // MTIP linux will see then jump to its handler
		//Csrs[mip][MEIP] <= meip_interrupt; // MEIP
		//Csrs[mip][MSIP] <= seip_interrupt; // MSIP
    
		//reserve_valid <= 0; // Interrupt clear lr.w/lr.d
		//do_trap = 1; trap_is_interrupt =1; trap_val = 0; trap_epc = pc_4;
		//if (meip_interrupt) trap_cause = 11; // Cause 11 for Machine External Interrupt
		//else if (msip_interrupt) trap_cause = 3;  // Cause 3 for Machine Sofeware Interrupt
		//else if (mtip_interrupt) trap_cause = 7;  // Cause 7 for Machine Timer Interrupt
		//else if (seip_interrupt) trap_cause = 9;  // Cause 9 for Supervisor External

		reserve_valid <= 0; // Interrupt clear lr.w/lr.d
		do_trap = 1; trap_is_interrupt =1; trap_val = 0; trap_epc = pc_4;
		if (meip) trap_cause = 11; // Cause 11 for Machine External Interrupt
		else if (msip) trap_cause = 3;  // Cause 3 for Machine Sofeware Interrupt
		else if (mtip) trap_cause = 7;  // Cause 7 for Machine Timer Interrupt
		else if (seip) trap_cause = 9;  // Cause 9 for Supervisor External
		else if (stip) trap_cause = 5;  // Cause 5 for Supervisor Timer Interrupt (set by opensbi via csrw when it see MTIP)
		else if (ssip) trap_cause = 1;  // Cause 1 for Supervisor Software Interrupt (set by os)

		// IR
	    end else begin 
		casez(ir)
	            // U-type
	            32'b???????_?????_?????_???_?????_0110111: re[w_rd] <= w_imm_u; // Lui
	            32'b???????_?????_?????_???_?????_0010111: re[w_rd] <= w_imm_u + pc_4; // Auipc
                    // Load after TLB
                    32'b???????_?????_?????_???_?????_0000011: begin 
                        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc_4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
                        if (load_step == 1 && bus_read_done == 0) begin pc <= pc_4; bubble <= 1; end // bus working
                        if (load_step == 1 && bus_read_done == 1) begin re[w_rd] <= w_load_data; load_step <= 0; end 
                    end
                    // Store after TLB
                    32'b???????_?????_?????_???_?????_0100011: begin 
                        if (store_step == 0) begin bus_address <= pda; bus_write_data <= w_store_data; bus_write_enable <= 1; pc <= pc_4; bubble <= 1; store_step <= 1; bus_ls_type <= w_func3; end
                        if (store_step == 1 && bus_write_done == 0) begin pc <= pc_4; bubble <= 1; end // bus working
                        if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; if (bus_address == reserve_addr && reserve_valid) reserve_valid <= 0; end 
                    end   
                    // Math-I
	            32'b???????_?????_?????_000_?????_0010011: re[w_rd] <= alu_addi;  // Addi
	            32'b???????_?????_?????_100_?????_0010011: re[w_rd] <= alu_xori; // Xori
	            32'b???????_?????_?????_111_?????_0010011: re[w_rd] <= alu_andi; // Andi
	            32'b???????_?????_?????_110_?????_0010011: re[w_rd] <= alu_ori; // Ori
	            32'b000000?_?????_?????_001_?????_0010011: re[w_rd] <= shared_sll; // Slli
	            32'b000000?_?????_?????_101_?????_0010011: re[w_rd] <= shared_srl_sra; // Srli // func7->6 // rv64 shame take w_f7[0]
	            32'b010000?_?????_?????_101_?????_0010011: re[w_rd] <= shared_srl_sra; // Srai
	            32'b???????_?????_?????_010_?????_0010011: re[w_rd] <= alu_slti; // Slti
	            32'b???????_?????_?????_011_?????_0010011: re[w_rd] <= alu_sltiu; // Sltiu
                    // Math-I (Word)
	            32'b???????_?????_?????_000_?????_0011011: re[w_rd] <= alu_addiw;// Addiw
	            32'b0000000_?????_?????_001_?????_0011011: re[w_rd] <= shared_sll;// Slliw
	            32'b0000000_?????_?????_101_?????_0011011: re[w_rd] <= shared_srl_sra;// Srliw
	            32'b0100000_?????_?????_101_?????_0011011: re[w_rd] <= shared_srl_sra;// Sraiw
                    // Math-R
	            32'b0000000_?????_?????_000_?????_0110011: re[w_rd] <= alu_add ;  // Add
	            32'b0100000_?????_?????_000_?????_0110011: re[w_rd] <= alu_sub ;  // Sub;
	            32'b0000000_?????_?????_100_?????_0110011: re[w_rd] <= alu_xor ;  // Xor
	            32'b0000000_?????_?????_111_?????_0110011: re[w_rd] <= alu_and  ;  // And
	            32'b0000000_?????_?????_110_?????_0110011: re[w_rd] <= alu_or ;  // Or
	            32'b0000000_?????_?????_001_?????_0110011: re[w_rd] <= shared_sll ; // Sll 6 length
                    32'b0000000_?????_?????_101_?????_0110011: re[w_rd] <= shared_srl_sra ; // Srl 6 length
	            32'b0100000_?????_?????_101_?????_0110011: re[w_rd] <= shared_srl_sra ; // Sra 6 length
	            32'b0000000_?????_?????_010_?????_0110011: re[w_rd] <= alu_slt;  // Slt
	            32'b0000000_?????_?????_011_?????_0110011: re[w_rd] <= alu_sltu; // Sltu
                    // Math-R (Word)
	            32'b0000000_?????_?????_000_?????_0111011: re[w_rd] <= alu_addw;  // Addw
	            32'b0100000_?????_?????_000_?????_0111011: re[w_rd] <= alu_subw;  // Subw
                    32'b0000000_?????_?????_001_?????_0111011: re[w_rd] <= shared_sll;  // Sllw
                    32'b0000000_?????_?????_101_?????_0111011: re[w_rd] <= shared_srl_sra;  // Srlw
                    32'b0100000_?????_?????_101_?????_0111011: re[w_rd] <= shared_srl_sra;  // Sraw
                    // Jump
	            32'b???????_?????_?????_???_?????_1101111: begin pc <= pc_4 + w_imm_j; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1'b1; end // Jal
	            32'b???????_?????_?????_???_?????_1100111: begin pc <= alu_addi & 64'hFFFFFFFFFFFFFFFE; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1; end // Jalr (re[w_rs1] + w_imm_i)
                    // Branch 
		    32'b???????_?????_?????_000_?????_1100011: begin if (re[w_rs1] == re[w_rs2]) begin pc <= branch; bubble <= 1'b1; end end // Beq
		    32'b???????_?????_?????_001_?????_1100011: begin if (re[w_rs1] != re[w_rs2]) begin pc <= branch; bubble <= 1'b1; end end // Bne
		    32'b???????_?????_?????_100_?????_1100011: begin if ($signed(re[w_rs1]) < $signed(re[w_rs2])) begin pc <= branch; bubble <= 1'b1; end end // Blt
		    32'b???????_?????_?????_101_?????_1100011: begin if ($signed(re[w_rs1]) >= $signed(re[w_rs2])) begin pc <= branch; bubble <= 1'b1; end end // Bge
		    32'b???????_?????_?????_110_?????_1100011: begin if ($unsigned(re[w_rs1]) < $unsigned(re[w_rs2])) begin pc <= branch; bubble <= 1'b1; end end // Bltu
		    32'b???????_?????_?????_111_?????_1100011: begin if ($unsigned(re[w_rs1]) >= $unsigned(re[w_rs2])) begin pc <= branch; bubble <= 1'b1; end end // Bgeu
		    // System-CSR 
		    32'b???????_?????_?????_001_?????_1110011: begin if (w_csr_id==XCSR) begin do_trap = 1; trap_is_interrupt =0; trap_val = ir; trap_epc = pc_4; trap_cause = ILLEGAL_INSTRUCTION; end
		                                                     else begin
                                                                     if (w_rd != 0) re[w_rd] <= csr_read;
		                                                     if (csr_writable) Csrs[w_csr_id] <= (Csrs[w_csr_id] & ~csr_mask_w)| csr_write_re; end //  (rs1 & csr_mask_w); end // Csrrw logic
		                                                     //if (w_csr_id==satp) begin tlb_flush <= ~tlb_flush; pc<=pc; bubble<=1; end end // flush pipelien on satp write
								     end
		    32'b???????_?????_?????_010_?????_1110011: begin if (w_csr_id==XCSR) begin do_trap = 1; trap_is_interrupt =0; trap_val = ir; trap_epc = pc_4; trap_cause = ILLEGAL_INSTRUCTION; end 
		                                                     else begin
                                                                     if (w_rd != 0) re[w_rd] <= csr_read;
		                                                     if (w_rs1 != 0 && csr_writable) Csrs[w_csr_id] <= (Csrs[w_csr_id] | csr_write_re); end //  (rs1 & csr_mask_w)); end // Csrrs
								     end
		    32'b???????_?????_?????_011_?????_1110011: begin if (w_csr_id==XCSR) begin do_trap = 1; trap_is_interrupt =0; trap_val = ir; trap_epc = pc_4; trap_cause = ILLEGAL_INSTRUCTION; end
		                                                     else begin
                                                                     if (w_rd != 0) re[w_rd] <= csr_read;
		                                                     if (w_rs1 != 0 && csr_writable) Csrs[w_csr_id] <= (Csrs[w_csr_id] & ~csr_write_re); end //  (rs1 & csr_mask_w)); end // Csrrc
								     end
		    32'b???????_?????_?????_101_?????_1110011: begin if (w_csr_id==XCSR) begin do_trap = 1; trap_is_interrupt =0; trap_val = ir; trap_epc = pc_4; trap_cause = ILLEGAL_INSTRUCTION; end
		                                                     else begin
                                                                     if (w_rd != 0) re[w_rd] <= csr_read;
		                                                     if (csr_writable) Csrs[w_csr_id] <= (Csrs[w_csr_id] & ~csr_mask_w) | csr_write_im; end //  (w_imm_z & csr_mask_w); end // Csrrwi
								     end
		    32'b???????_?????_?????_110_?????_1110011: begin if (w_csr_id==XCSR) begin do_trap = 1; trap_is_interrupt =0; trap_val = ir; trap_epc = pc_4; trap_cause = ILLEGAL_INSTRUCTION; end
		                                                     else begin
                                                                     if (w_rd != 0) re[w_rd] <= csr_read;
		                                                     if (w_imm_z != 0 && csr_writable) Csrs[w_csr_id] <= (Csrs[w_csr_id] | csr_write_im); end //  (w_imm_z & csr_mask_w)); end // csrrsi
								     end
		    32'b???????_?????_?????_111_?????_1110011: begin if (w_csr_id==XCSR) begin do_trap = 1; trap_is_interrupt =0; trap_val = ir; trap_epc = pc_4; trap_cause = ILLEGAL_INSTRUCTION; end
		                                                     else begin
                                                                     if (w_rd != 0) re[w_rd] <= csr_read;
		                                                     if (w_imm_z != 0 && csr_writable) Csrs[w_csr_id] <= (Csrs[w_csr_id] & ~csr_write_im); end //  (w_imm_z & csr_mask_w)); end // Csrrci
								     end
                    // Ecall
	            32'b0000000_00000_?????_000_?????_1110011: begin 
	                                                if      (current_privilege_mode == U_mode) trap_cause = UECALL; // 8 indicate Ecall from U-mode; 9 call from S-mode; 11 call from M-mode
	                                                else if (current_privilege_mode == S_mode) trap_cause = SECALL; // block assign attaintion!
	                                                else if (current_privilege_mode == M_mode) trap_cause = MECALL;
                                                        do_trap = 1; trap_is_interrupt = 0; trap_val = 0; trap_epc = pc_4; end
                    // Ebreak
	            32'b0000000_00001_?????_000_?????_1110011: begin do_trap = 1; trap_is_interrupt = 0; trap_val = 0; trap_epc = pc_4; trap_cause = BREAK; end
                    // Mret
	            32'b0011000_00010_?????_000_?????_1110011: begin  
	               			       Csrs[mstatus][MIE] <= Csrs[mstatus][MPIE]; // set back interrupt enable(MIE) by MPIE 
	               			       Csrs[mstatus][MPIE] <= 1; // set previous interrupt enable(MIE) to be 1 (enable)
	               			       if (Csrs[mstatus][MPP+1:MPP] < M_mode) Csrs[mstatus][MPRV] <= 0; // set mprv to 0, modified privilege, 1 using in MPP not current
	               			       current_privilege_mode  <= Csrs[mstatus][MPP+1:MPP]; // set back previous mode
	               			       Csrs[mstatus][MPP+1:MPP] <= 2'b00; // set previous privilege mode(MPP) to be 00 (U-mode)
	               			       pc <=  Csrs[mepc]; // mepc was +4 by the software handler and written back to sepc
		          		       bubble <= 1'b1; end
                    // Sret
	            32'b0001000_00010_?????_000_?????_1110011: begin      
	               			       Csrs[sstatus][SIE] <= Csrs[sstatus][SPIE]; // restore interrupt enable(SIE) by SPIE 
	               			       Csrs[sstatus][SPIE] <= 1; // next trap will have SPIE=1
	               			       if (Csrs[sstatus][SPP] == 0) current_privilege_mode <= U_mode; else current_privilege_mode  <= S_mode;
	               			       Csrs[sstatus][SPP] <= 0; // set previous privilege mode(SPP) to be 0 (U-mode)
	               			       pc <=  Csrs[sepc]; // sepc was +4 by the software handler and written back to sepc
		          		       bubble <= 1'b1; end 
		    32'b00010000010100000000000001110011: begin end // Wfi
		    32'b?????????????????_000_?????_0001111: begin end // Fence
		    32'b?????????????????_001_?????_0001111: begin flush <= ~flush; end // Fence.i 
		    32'b0001001??????????_000_?????_1110011: begin bubble <=1; pc <= pc; end // Sfence.vma (supervisor fence for virtual memory address) have to bubble the fetch next ir from old tlb, redo
		    // Atomic after TLB // -- ATOMIC instructions (A-extension) opcode: 0101111
		    32'b00010_??_?????_?????_01?_?????_0101111: begin  // lr Lr._mmu 3 cycles lr.w010 lr.d011
		        if (load_step == 0) begin bus_address <= pda; bus_read_enable <=1; pc <= pc_4; bubble <=1; load_step <=1; bus_ls_type <= w_func3; reserve_addr <= pda; reserve_valid <=1; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc_4; bubble <= 1; end // bus working
		        if (load_step == 1 && bus_read_done == 1) begin re[w_rd] <= amo_op_mem; load_step <= 0; end end
	            32'b00011_??_?????_?????_01?_?????_0101111: begin  // sc sc.w010 sc.d011
		        if (store_step == 0) begin 
		            if (!reserve_valid || reserve_addr != pda) begin re[w_rd] <= 1; reserve_valid <= 0; end // finish failed 1 in rd cycle without bubble & clear reserve
		            else begin bus_address <= pda; 
			    bus_write_data<= w_atomic_write_data;
			    bus_write_enable<=1;pc<=pc_4;bubble<=1;store_step<=1;bus_ls_type<=w_func3;reserve_valid<=0;end end //consumed
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc_4; bubble <= 1; end // bus working 1 bubble2 this3
		        if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; re[w_rd] <= 0; end end // sc.w successed return 0 in rd
	           // Amos(swap, add, xor, and, or, min, max) w/d
	            32'b?????_??_?????_?????_01?_?????_0101111: begin // not 00010lr/00011sc
		        if (load_step == 0 && store_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc_4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc_4; bubble <= 1; end // bus working
		        if (load_step == 1 && bus_read_done == 1) begin 
			    re[w_rd] <= amo_op_mem; load_step <= 0;  // finish load
		            bus_address <= pda;bus_write_enable<=1;pc<=pc_4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; // start store
			    bus_write_data <= w_atomic_write_data;
		        end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc_4; bubble <= 1; end
		        if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end
                    // M-Mul
		    32'b0000001_?????_?????_0??_?????_0110011, // Mul, Mulh, Mulhsu, Mulhu
		    32'b0000001_?????_?????_000_?????_0111011: // Mulw
		        begin
		            if (!mul_done) begin
		                mul_enable <= 1;
		                if (!mul_enable) begin // latch
                                    mul_is_w_latched <=  mul_is_w;
                                    raw_a_latched <= raw_a;
                                    raw_b_latched <= raw_b;
                                    a_is_signed_latched <= a_is_signed;
                                    b_is_signed_latched <= b_is_signed;
                                    abs_a_latched <= abs_a;
                                    abs_b_latched <= abs_b;
		                    mul_op_type <= w_func3;
		                    mul_rd_latched <= w_rd;
		                end // stall pipeline
		                pc <= pc_4;
		                bubble <= 1;
		            end else  begin // if (mul_done)
		                re[mul_rd_latched] <= w_mul_out;
		                mul_enable <= 0;
		                pc <= pc; // wait mul_done from Mul driver for very next similar mulx start
		                bubble <= 1;
		            end
		        end
		    // M-Div
		    32'b0000001_?????_?????_1??_?????_0110011, //Div100 divu101 rem110 remu111
		    32'b0000001_?????_?????_1??_?????_0111011: begin // divw100 divuw101  remw110 remuw111
			if (!div_done) begin
			    div_enable <= 1;
			    if (!div_enable) begin // latch
                                div_a <= div_is_w ? (w_func3[0] ? {32'b0, rs1[31:0]} : {{32{rs1[31]}}, rs1[31:0]}) : rs1;    // be divided
                                div_b <= div_is_w ? (w_func3[0] ? {32'b0, rs2[31:0]} : {{32{rs2[31]}}, rs2[31:0]}) : rs2;    // divisro
                                div_op_signed <= !w_func3[0];  // func3[0] == 0 is signed // 100div/w 101divu 110rem/w 111remu
                                div_is_rem <= w_func3[1];   // func3[1] == 1 is rem
                                div_rd <= w_rd; 
				div_is_w_latched <= div_is_w;
			    end // stall pipeline
			    pc <= pc_4;
			    bubble <= 1;
			end else begin
			    re[div_rd] <= div_is_w_latched ? {{32{div_result_out[31]}}, div_result_out[31:0]} : div_result_out;
			    div_enable <= 0;
			    pc <= pc; // wait div_done from Div driver for very next similar div/rem start
			    bubble <= 1;
			end
		    end
                    // FD...
		    // Unknow instructions
		    default: begin do_trap = 1; trap_is_interrupt = 0; trap_val = ir; trap_epc = pc_4; trap_cause = ILLEGAL_INSTRUCTION ; end
               endcase
	    end 
	    // Trap
	    if (do_trap) begin
		if ((trap_is_interrupt ? Csrs[mideleg][trap_cause] : Csrs[medeleg][trap_cause]) == 1'b1 && current_privilege_mode <= S_mode) begin // Trap in S-mode
	                 			           Csrs[scause][INTERRUPT] <= trap_is_interrupt; //63_type 0exception 1interrupt|value
	                 			           Csrs[scause][CAUSE+62:CAUSE] <= trap_cause;
	                 			           Csrs[sepc] <= trap_epc;
							   Csrs[stval] <= trap_val; 
	                 			           Csrs[sstatus][SPP] <= (current_privilege_mode == U_mode ? 0 : 1); // save previous privilege mode(user0 super1) to SPP 
	                 			           Csrs[sstatus][SPIE] <= Csrs[sstatus][SIE]; // save interrupt enable(SIE) to SPIE 
	                 			           Csrs[sstatus][SIE] <= 0; // clear SIE
							   if (trap_is_interrupt && Csrs[stvec][MODE+1:MODE] == 1) pc <= (Csrs[stvec][BASE+61:BASE] << 2) + (trap_cause << 2); //vectorily  
							   else  pc <= (Csrs[stvec][BASE+61:BASE] << 2) ; // directly Exceptions Never vector 1 will be ignore
	                 				   current_privilege_mode <= S_mode;
		    				           bubble <= 1'b1;
	                 			       end else begin // Trap into M-mode
	                 			           Csrs[mcause][INTERRUPT] <= trap_is_interrupt ; //63_type 0exception 1interrupt|value
	                 			           Csrs[mcause][CAUSE+62:CAUSE] <= trap_cause; 
	                 			           Csrs[mepc] <= trap_epc;
							   Csrs[mtval] <= trap_val;
	                 			           Csrs[mstatus][MPIE] <= Csrs[mstatus][MIE]; // save interrupt enable(MIE) to MPIE 
	                 			           Csrs[mstatus][MIE] <= 0; // clear MIE (not enabled, blocked when trap)
							   if (trap_is_interrupt && Csrs[mtvec][MODE+1:MODE] == 1) pc <= (Csrs[mtvec][BASE+61:BASE] << 2) + (trap_cause << 2);
							   else  pc <= (Csrs[mtvec][BASE+61:BASE] << 2);
	                 				   Csrs[mstatus][MPP+1:MPP] <= current_privilege_mode; // save privilege mode to MPP 
	                 				   current_privilege_mode <= M_mode;  // set current privilege mode
		    				           bubble <= 1'b1;
	                 			       end
	    end
        end
	re[0]<= 64'h0; 
	sre[0]<= 64'h0;
    end
endmodule
