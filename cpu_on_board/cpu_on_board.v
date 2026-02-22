`include "header.vh"

module riscv64(
    input wire clk, 
    input wire reset,     // Active-low reset button
    input wire [31:0] instruction,
    output wire [63:0] ppc,
    output wire  heartbeat,
    output reg [63:0] bus_address,     // 39 bit for real Sv39 standard?
    output reg [63:0] bus_write_data,
    output reg        bus_write_enable,
    output reg        bus_read_enable,
    output reg [2:0]  bus_ls_type, // lb lh lw ld lbu lhu lwu // sb sh sw sd sbu shu swu 
      
    output reg [63:0] mtime,    // map to 0x0200_bff8 
    inout wire [63:0] mtimecmp, // map to 0x0200_4000 + 8byte*hartid

    input wire meip_interrupt, // from PLIC
    input wire msip_interrupt, // from Software
      
    input  reg        bus_read_done,
    input  reg        bus_write_done,
    input  wire [63:0] bus_read_data   // from outside
);

    (* keep = 1 *) reg [63:0] pc;
    reg check=0;
    reg tlb=0;
    wire [31:0] ir;
            
    (* ram_style = "logic" *) reg [63:0] re [0:31]; // General Registers 32s
    (* ram_style = "logic" *) reg [63:0] sre [0:9]; // Shadow Registers 10s
    reg mmu_da=0;
    reg mmu_pc = 0;
    reg mmu_cache_refill=0;
    reg [63:0] saved_user_pc;
    integer i; 

    // --- Privilege Modes ---
    localparam M_mode = 2'b11;
    localparam S_mode = 2'b01;
    localparam U_mode = 2'b00;
    reg [1:0] current_privilege_mode;
    // -- newend --

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

    // Shared Arithmetic Units
    wire [63:0] alu_add  = rs1 + rs2;
    wire [63:0] alu_sub  = rs1 - rs2;
    wire [63:0] alu_xor  = rs1 ^ rs2;
    wire [63:0] alu_or   = rs1 | rs2;
    wire [63:0] alu_and  = rs1 & rs2;
    wire [63:0] alu_sll  = rs1 << rs2[5:0];
    wire [63:0] alu_srl  = rs1 >> rs2[5:0];
    wire [63:0] alu_sra  = $signed(rs1) >>> rs2[5:0];
    wire [63:0] alu_slt  = ($signed(rs1) < $signed(rs2)) ? 1:0;
    wire [63:0] alu_sltu = ($unsigned(rs1) < $unsigned(rs2)) ? 1:0;

    wire [63:0] alu_addw = $signed(rs1[31:0] + rs2[31:0]);  // Addw
    wire [63:0] alu_subw = $signed(rs1[31:0] - rs2[31:0]);  // Subw
    wire [63:0] alu_sllw = $signed(rs1[31:0] << rs2[4:0]);  // Sllw 5 length
    wire [63:0] alu_srlw = $signed(rs1[31:0] >> rs2[4:0]);  // Srlw 5 length
    wire [63:0] alu_sraw = $signed(rs1[31:0]) >>> rs2[4:0]; // Sraw 5 length

    wire [63:0] alu_addi = rs1 + w_imm_i;  // Addi
    wire [63:0] alu_xori = rs1 ^ w_imm_i ; // Xori
    wire [63:0] alu_andi = rs1 & w_imm_i ; // Andi
    wire [63:0] alu_ori  = rs1 | w_imm_i ; // Ori
    wire [63:0] alu_slli = rs1 << w_shamt; // Slli
    wire [63:0] alu_srli = rs1 >> w_shamt; // Srli // func7->6 // rv64 shame take w_f7[0]
    wire [63:0] alu_srai = $signed(rs1) >>> w_shamt; // Srai
    wire [63:0] alu_slti = $signed(rs1) < w_imm_i ? 1:0; // Slti
    wire [63:0] alu_sltiu= ($unsigned(rs1) < w_imm_i) ?  1:0; // Sltiu

    wire [63:0] alu_addiw = $signed(rs1[31:0] + w_imm_i[31:0]); // Addiw
    wire [63:0] alu_slliw = $signed(rs1[31:0] << w_shamt[4:0]); // Slliw
    wire [63:0] alu_srliw = $signed(rs1[31:0] >> w_shamt[4:0]); // Srliw
    wire [63:0] alu_sraiw = $signed(rs1[31:0]) >>> w_shamt[4:0]; // Sraiw
    wire [63:0] branch = pc - 4 + w_imm_b; //branch

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
    // AMO prepare
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
				      w_amo_calc_data; // AMOs
    // -- mul rela --
    // Indepenedent Multiplier // Booth algorithim + Signed-correct
    reg [6:0]   mul_cnt;
    reg [128:0] mul_acc;  // sign|result|multiplier
    reg [64:0]  mul_a_reg;
    reg         mul_active;
    reg         mul_done;
    reg         mul_enable;
    reg         mul_b_is_signed;
    reg [1:0]   mul_out_sel;
    
    // 000mul 001mulh 010mulhsu 011mulhu
    wire mul_is_w = (op == 7'b0111011); // Mulw (opc 0111011)
    wire mul_sign_a = mul_is_w ? 1'b1 : (w_func3 != 3'b011); // signed except Mulhu
    wire mul_sign_b = mul_is_w ? 1'b1 : (w_func3 == 3'b000 || w_func3 == 3'b001); // signed Mul/Mulh

    wire [63:0] raw_a = mul_is_w ? {{32{rs1[31]}}, rs1[31:0]} : rs1;
    wire [63:0] raw_b = mul_is_w ? {{32{rs2[31]}}, rs2[31:0]} : rs2;
    wire [64:0] ext_a = {mul_sign_a & raw_a[63], raw_a}; 
    //wire [64:0] ext_b = {mul_sign_b & raw_b[63], raw_b}; 
    wire is_last_cycle = (mul_cnt == 7'd63);
    wire do_sub = is_last_cycle && mul_b_is_signed;
    wire [64:0] adder_input_a = do_sub ? ~mul_a_reg : mul_a_reg;
    wire [64:0] sum_upper = mul_acc[128:64] + adder_input_a + do_sub;

    always @(posedge clk or negedge reset) begin  
        if (!reset) begin
            mul_active <= 0;
            mul_done   <= 0;
            mul_cnt    <=0;	    
	end else begin
            if (mul_enable && !mul_active && !mul_done) begin
		// Start phase
		mul_active <= 1;
		mul_cnt    <= 0;
		// 1. Determine output mode
	        if (mul_is_w) mul_out_sel <= 2; // mulw
		else if (w_func3 == 0) mul_out_sel <= 0; // mul
		else mul_out_sel <= 1;   // mulh* 
		mul_a_reg <= ext_a;
		mul_acc <= {65'd0, raw_b};
		mul_b_is_signed <= mul_sign_b;
	    end else if (mul_active) begin
		// Compute phase (64 cycles)
		if (mul_cnt < 64) begin
		    if (mul_acc[0]) mul_acc <= {sum_upper[64], sum_upper, mul_acc[63:1]}; // is 1,  + and << 1
		    else mul_acc <= {mul_acc[128], mul_acc[128:1]}; // is 0, only << 1, preserve sign bit
		    mul_cnt <= mul_cnt + 1;
		end else begin
	            // Finish phase
	            mul_active <= 0;
		    mul_done   <= 1;
		end
	    end else if (!mul_enable) mul_done <= 0; // reset handshake
	end
    end

    // Independent divider
    reg [6:0]   div_cnt;
    reg [127:0] div_rem;   // remainder|quotient
    reg [63:0]  div_b;    // divisor
    reg         div_active; // 1computing, 0idle
    reg         div_done;   // handshake 1result ready
    reg         div_enable; // handshake 1start request
    reg         div_sign_quotient; // sige of quotient
    reg         div_sign_reminder; // sige of remainder
    reg         div_is_rem; // 1rem, 0div
    reg [63:0]  div_result_out; // final output buffer
    
    // signal 100div/w 101divu 110rem/w 111remu
    wire div_op_signed = !ir[12];  // func3[0] == 0 is signed
    wire div_op_is_rem = ir[13];   // func3[1] == 1 is rem

    always @(posedge clk or negedge reset) begin
	if (!reset) begin
	    div_active <= 0;
	    div_done   <= 0;
	    div_cnt    <= 0;
	end else begin
            if (div_enable && !div_active && !div_done) begin
		// start phase
		div_active <= 1;
		div_cnt <= 0;
		div_is_rem <= div_op_is_rem;
		// handle corner case
		if (rs2 == 0) begin
		    // divide by zero
		    div_result_out <= div_op_is_rem ? rs1 : -64'd1;
		    div_active <= 0;
		    div_done <= 1; // finish immediately
		end
		else if (div_op_signed && rs1 == 64'h8000000000000000 && rs2 == -64'd1) begin // ??
		    // signed overflow
		    div_result_out <= div_op_is_rem ? 64'd0 : rs1;
		    div_active <= 0;
		    div_done <= 1; // finish immediately
		end
		else begin 
		    // mormal division setup
		    // 1. determine signs
		    div_sign_reminder <= div_op_signed ?  rs1[63] :0;
		    div_sign_quotient <= div_op_signed ? (rs1[63] & rs2[63]) :0;
		    // 2. load absoulte values
		    div_rem <= {64'd0, (div_op_signed && rs1[63]) ? -rs1 :rs1};
		    div_b <= (div_op_signed && rs2[63]) ? -rs2 : rs2;
		end
            end else if (div_active) begin
		// compute phase (64 cycles)
		if (div_cnt < 64) begin
		    if (div_rem[126:63] >= div_b) begin
		        div_rem <= {div_rem[126:63] - div_b, div_rem[62:0], 1'b1};
		    end else begin
		        div_rem <= {div_rem[126:0], 1'b0};
		    end
		    div_cnt <= div_cnt + 1;
	        end else begin
		    // finish phase
		    div_active <= 0;
		    div_done   <= 1;
		    if (div_is_rem) div_result_out <= div_sign_reminder ? -div_rem[127:64] : div_rem[127:64];
		    else div_result_out <= div_sign_quotient ? -div_rem[63:0] : div_rem[63:0];
		end
	    end else if (!div_enable) div_done <= 0; // reset handshake
	end
    end

    // --Machine CSR --
   localparam mstatus    = 0 ; localparam MPRV=17,MPP=11,SPP=8,MPIE=7,SPIE=5,MIE=3,SIE=1,UIE=0;//63_SD|37_MBE|36_SBE|35:34_SXL10|22_TSR|21_TW|20_TVW|17_MPRV|12:11_MPP|8_SPP|7_MPIE|5_SPIE|3_MIE|1_SIE|0_UIE
   localparam mtvec      = 1 ; localparam BASE=2,MODE=0; // 63:2BASE|1:0MDOE  // 0x305 MRW Machine trap-handler base address * 0 direct 1vec
   localparam mscratch   = 2 ;  // 
   localparam mepc       = 3 ;  
   localparam mcause     = 4 ; localparam INTERRUPT=63,CAUSE=0; // 0x342 MRW Machine trap casue *  63InterruptAsync/ErrorSync|62:0CauseCode
   localparam mie        = 5 ; localparam SGEIE=12,MEIE=11,VSEIE=10,SEIE=9,MTIE=7,VSTIE=6,STIE=5,MSIE=3,VSSIE=2,SSIE=1; // Machine Interrupt Enable from OS software set enable
   localparam mip        = 6 ; localparam SGEIP=12,MEIP=11,VSEIP=10,SEIP=9,MTIP=7,VSTIP=6,STIP=5,MSIP=3,VSSIP=2,SSIP=1; // Machine Interrupt Pending from HardWare timer,uart,PLIC..11Exter 7Time 3Software
   localparam medeleg    = 7 ; localparam MECALL=11,SECALL=9,UECALL=8,BREAK=3; // bit_index=mcause_value 8UECALL|9SECALL
   localparam mideleg    = 8 ;  //
   localparam sstatus    = 9 ; localparam SD=63,UXL=32,MXR=19,SUM=18,XS=15,FS=13,VS=9,UBE=6; //SPP=8,SPIE=5,SIE=1,//63SD|33:32UXL|19MXR|18SUM|16:15XS|14:13FS|10:9VS|8SPP|6UBE|5SPIE|1SIE
   localparam sedeleg    = 10;  
   localparam sideleg    = 11;  
   localparam sie        = 12;  // Supervisor interrupt-enable register
   localparam stvec      = 13; //localparam ; //BASE=2,MODE=0 63:2BASE|1:0MDOE Supervisor trap handler base address
   localparam scounteren = 14;  
   localparam sscratch   = 15;  
   localparam sepc       = 16;  
   localparam scause     = 17; //localparam ; //INTERRUPT=63,CAUSE=0 *  63InterruptAsync/ErrorSync|62:0CauseCode// 
   localparam stval      = 18;  
   localparam sip        = 19;  // Supervisor interrupt pending
   localparam satp       = 20;  // Supervisor address translation and protection satp[63:60].MODE=0:off|8:SV39 satp[59:44].asid vpn2:9 vpn1:9 vpn0:9 satp[43:0]:rootpage physical addr
   localparam mtval      = 21;  // Machine Trap Value Register (bad address or instruction)
   localparam mhartid    = 22;  // Hardware Thread ID 0 for single-core
   localparam misa       = 23;  // Machine ISA Register (IMA is 0x8000000000001101)
   localparam mvendorid  = 24;  // 0
   localparam marchid    = 25;  // 0
   localparam mimpid     = 26;  // 0
    //integer scontext = 12'h5a8; 
   reg [62:0] CAUSE_CODE;
   reg  [5:0] w_csr_id;             // CSR id (32)
    always @(*) begin
	case(w_csr)
            12'h300 : w_csr_id = mstatus    ;    
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
	    default : w_csr_id = 64; 
	endcase
    end

    (* ram_style = "logic" *) reg [63:0] Csrs [0:31]; // 32 CSRs for now
    wire [3:0]  satp_mmu  = Csrs[satp][63:60]; // 0:bare, 8:sv39, 9:sv48  satp.MODE!=0, privilegae is not M-mode, mstatus.MPRN is not set or in MPP's mode?
    wire [15:0] satp_asid = Csrs[satp][59:44]; // Address Space ID for TLB
    wire [43:0] satp_ppn  = Csrs[satp][43:0];  // Root Page Table PPN physical page number

    // -- Timer --
    always @(posedge clk or negedge reset) begin 
	if (!reset) mtime <= 0;
	else mtime <= mtime + 1; end
    wire time_interrupt = (mtime >= mtimecmp);
      
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
    // -- TLB -- 4 pages
    (* ram_style = "logic" *) reg [26:0] tlb_vpn [0:3]; // vpn number VA[38:12]  Sv39
    (* ram_style = "logic" *) reg [43:0] tlb_ppn [0:3]; // ppn number PA[55:12]
    (* ram_style = "logic" *) reg tlb_vld [0:3];

    // tlb i hit
    wire [26:0] pc_vpn = pc[38:12];
    reg [43:0] pc_ppn;
    reg tlb_i_hit;

    //wire [7:0] tlb_i_match;
    wire [3:0] tlb_i_match;
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
                   ({44{tlb_i_match[1]}} & tlb_ppn[1]) |
                   ({44{tlb_i_match[2]}} & tlb_ppn[2]) |
		   ({44{tlb_i_match[3]}} & tlb_ppn[3]) ; end
                   //({44{tlb_i_match[3]}} & tlb_ppn[3]) |
                   //({44{tlb_i_match[4]}} & tlb_ppn[4]) |
                   //({44{tlb_i_match[5]}} & tlb_ppn[5]) |
                   //({44{tlb_i_match[6]}} & tlb_ppn[6]) |
                   //({44{tlb_i_match[7]}} & tlb_ppn[7]) ; end
    // --------
    // tlb d hit
    wire [63:0] ls_va_offset = (op == 7'b0000011) ? w_imm_i : (op == 7'b0100011) ?  w_imm_s : 64'h0; // load/store/atom
    wire [63:0] ls_va = rs1 + ls_va_offset;
    wire [63:0] pda;
    reg [43:0] data_ppn;
    reg tlb_d_hit;

    //wire [7:0] tlb_d_match;
    wire [3:0] tlb_d_match;
    assign tlb_d_match[0] = tlb_vld[0] && (tlb_vpn[0] == ls_va[38:12]);
    assign tlb_d_match[1] = tlb_vld[1] && (tlb_vpn[1] == ls_va[38:12]);
    assign tlb_d_match[2] = tlb_vld[2] && (tlb_vpn[2] == ls_va[38:12]);
    assign tlb_d_match[3] = tlb_vld[3] && (tlb_vpn[3] == ls_va[38:12]);
    //assign tlb_d_match[4] = tlb_vld[4] && (tlb_vpn[4] == ls_va[38:12]);
    //assign tlb_d_match[5] = tlb_vld[5] && (tlb_vpn[5] == ls_va[38:12]);
    //assign tlb_d_match[6] = tlb_vld[6] && (tlb_vpn[6] == ls_va[38:12]);
    //assign tlb_d_match[7] = tlb_vld[7] && (tlb_vpn[7] == ls_va[38:12]);
    // data_ppn hit
    always @(*) begin
        tlb_d_hit = |tlb_d_match;
        data_ppn = ({44{tlb_d_match[0]}} & tlb_ppn[0]) |
                   ({44{tlb_d_match[1]}} & tlb_ppn[1]) |
                   ({44{tlb_d_match[2]}} & tlb_ppn[2]) |
		   ({44{tlb_d_match[3]}} & tlb_ppn[3]) ; end
                   //({44{tlb_d_match[3]}} & tlb_ppn[3]) |
                   //({44{tlb_d_match[4]}} & tlb_ppn[4]) |
                   //({44{tlb_d_match[5]}} & tlb_ppn[5]) |
                   //({44{tlb_d_match[6]}} & tlb_ppn[6]) |
                   //({44{tlb_d_match[7]}} & tlb_ppn[7]) ; end
    // concat physical address
    wire need_trans = satp_mmu   && !mmu_pc && !mmu_da && !mmu_cache_refill;
    assign ppc = need_trans ? {8'h0, pc_ppn, pc[11:0]} : pc;
    assign pda = need_trans ? {8'h0, data_ppn, ls_va[11:0]} : ls_va;
        
    // TLB Refill
    //reg [2:0] tlb_ptr = 0; // 8 entries TLB
    reg [1:0] tlb_ptr = 0; // 4 entries TLB
    always @(posedge clk or negedge reset) begin
        if (!reset) tlb_ptr <= 0; // hit->trap(save va to x9)->refill assembly(fetch pa to x9)-> sd x9, `Tlb -> here to refill tlb
        else if ((mmu_pc || mmu_da) && bus_write_enable && bus_address == `Tlb) begin // for the last fill: sd ppa, Tlb
            tlb_vpn[tlb_ptr] <= re[9][38:12]; // VA from x9 saved by trapp mmu_pc/mmu_da
            tlb_ppn[tlb_ptr] <= {17'h0, re[9][38:12]}; // mimic copy now | real need walking assembly
            tlb_vld[tlb_ptr] <= 1;
            tlb_ptr <= tlb_ptr + 1; 
        end
    end

    // -----
    // cache_i_hit 63:13 tag, 12:4 index 3:0 offset Cache line 16B (4 instructions) 512 lines
    reg [127:0] cache_line = 128'h0;
    reg [51:0] cache_tag = 52'h0;
    reg [63:0] ppc_pre = 64'h0; // for read
    reg [63:0] ask_i_data; // for write
    //(* ram_style = "block" *) reg [127:0] Cache_L [0:1023]; // 16KB
    (* ram_style = "block" *) reg [63:0] Cache_L_Low [0:511]; // 4KB
    (* ram_style = "block" *) reg [63:0] Cache_L_High [0:511]; // 4KB
    (* ram_style = "block" *) reg [51:0] Cache_T [0:511];  // ~4KB (addr: 1(valit) + 51(tag) + 9(index) + 4(offset))
    always @(posedge clk) begin 
	// Read
	cache_line <= {Cache_L_High[ppc[12:4]], Cache_L_Low[ppc[12:4]]}; 
	cache_tag <= Cache_T[ppc[12:4]]; 
	ppc_pre <= ppc;
	// Write
        if (mmu_cache_refill && bus_write_enable && bus_address == `CacheI_L) begin Cache_L_Low[ask_i_data[12:4]] <= bus_write_data; end
        if (mmu_cache_refill && bus_write_enable && bus_address == `CacheI_H) begin 
	    Cache_L_High[ask_i_data[12:4]] <= bus_write_data; 
	    Cache_T[ask_i_data[12:4]] <= {1'b1, ask_i_data[63:13]}; 
	end
    end
    wire cache_i_hit = cache_tag[51] && (ppc_pre[63:13] == cache_tag[50:0]);
    wire [31:0] cache_i = cache_line[ppc_pre[3:2]*32 +: 32];

    assign ir = (mmu_pc || mmu_da || mmu_cache_refill) ? instruction : cache_i_hit ? cache_i : 32'h00000013; // NOP:addi x0, x0, 0;
    // -----

    //assign ir = instruction;
    //initial begin end !!

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
	    Csrs[mstatus][MIE] <= 0;
	    //interrupt_ack <= 0;
	    mmu_da <= 0;
	    for (i=0;i<10;i=i+1) begin sre[i]<= 64'b0; end
	    for (i=0;i<32;i=i+1) begin Csrs[i]<= 64'b0; end
	    Csrs[medeleg] <= 64'hb1af; // delegate to S-mode 1011000110101111 // see VII 3.1.15 mcasue exceptions
	    Csrs[mideleg] <= 64'h0222; // delegate to S-mode 0000001000100010 see VII 3.1.15 mcasue interrupt 1/5/9 SSIP(supervisor software interrupt) STIP(time) SEIP(external)
	    mmu_pc <= 0;
            reserve_addr <= 0;
            reserve_valid <= 0;


        end else begin
            pc <= pc + 4; // Default PC+4    (1.Could be overide 2.Take effect next cycle) 
	    //interrupt_ack <= 0;
	    bus_read_enable <= 0;
	    bus_write_enable <= 0; 

	    //  mmu_pc  I-TLB miss Trap
	    if (satp_mmu && !mmu_pc && !mmu_da && !mmu_cache_refill && !tlb_i_hit) begin //OPEN 
       		mmu_pc <= 1; // MMU_PC ON 
       	        pc <= 0; // I-TLB refill Handler
       	 	bubble <= 1'b1; // bubble 
	        saved_user_pc <= pc - 4; // !!! save pc (EXE was flushed so record-redo it, previous pc)
	        if (bubble) saved_user_pc <= pc ; // !!! save pc (j/b EXE was flushed currectly)
		for (i=0;i<10;i=i+1) begin sre[i]<= re[i]; end // save re
		re[9] <= pc;// - 4; // save this vpc to x1 //!!!! We also need to refill pc - 4' ppc for re-executeing pc-4, with hit(if satp in for very next sfence.vma) 
		//Csrs[mstatus][MPIE] <= Csrs[mstatus][MIE]; // disable interrupt during shadow mmu walking
		//Csrs[mstatus][MIE] <= 0;
		// Infront of bubble just for trapping jump/branch instrucion

            // Bubble
	    end else if (bubble) begin bubble <= 1'b0; // Flush this cycle & Clear bubble signal for the next cycle

	    end else if (mmu_pc && ir == 32'b00110000001000000000000001110011) begin // end hiject mret & recover from shadow when see Mret
		pc <= saved_user_pc; // recover from shadow when see Mret
	 	bubble <= 1'b1; // bubble
		for (i=0;i<10;i=i+1) begin re[i]<= sre[i]; end // recover usr re
		mmu_pc <= 0; // MMU_PC OFF
		//Csrs[mstatus][MIE] <= Csrs[mstatus][MPIE]; // set back interrupt status
    
	    // ----- 
	    //  mmu_cache_i at EXE stage without stap/tlb_hit sensitive
	    end else if (!mmu_pc && !mmu_da && !mmu_cache_refill && !cache_i_hit) begin //OPEN 
	    //end else if (!cache_i_hit) begin //OPEN 
       		mmu_cache_refill <= 1; // 
       	        pc <= 72; //
       	 	bubble <= 1'b1; // bubble 
		for (i=0;i<10;i=i+1) begin sre[i]<= re[i]; end // save re
	        saved_user_pc <= pc -4  ; // ??!!! save pc (j/b EXE was flushed currectly)
		re[9] <= {ppc_pre[63:4], 4'b0};// save missed ppc_pre cache_line address for handler
		ask_i_data <= {ppc_pre[63:4], 4'b0};// save missed ppc_pre cache_line address for hardware
		if (pc == `Ram_base) begin // initial situation
		    saved_user_pc <= pc; // first pc
		    re[9] <= {ppc[63:4], 4'b0};// save missed ppc_pre cache_line address for handler
		    ask_i_data <= {ppc[63:4], 4'b0};// save missed ppc_pre cache_line address for hardware
		end
	    end else if (mmu_cache_refill && ir == 32'b00110000001000000000000001110011) begin // end hiject mret & recover from shadow when see Mret
		pc <= saved_user_pc; // recover from shadow when see Mret
	 	bubble <= 1'b1; // bubble
		for (i=0;i<10;i=i+1) begin re[i]<= sre[i]; end // recover usr re
		mmu_cache_refill <= 0; // OFF
	    // -----

            //  mmu_da  D-TLB miss Trap // load/store/atom
	    end else if (satp_mmu && !mmu_pc && !mmu_da && !mmu_cache_refill && tlb_i_hit && !tlb_d_hit && (op == 7'b0000011 || op == 7'b0100011 || op == 7'b0101111) ) begin  
		mmu_da <= 1; // MMU_DA ON
		pc <= 36; // D-TLB refill Handler
	 	bubble <= 1'b1; // bubble
	        saved_user_pc <= pc - 4; // save pc EXE l/s/a
		for (i=0;i<10;i=i+1) begin sre[i]<= re[i]; end // save re
		re[9] <= ls_va; //save va to x1
		//Csrs[mstatus][MPIE] <= Csrs[mstatus][MIE]; // disable interrupt during shadow mmu walking
		//Csrs[mstatus][MIE] <= 0;
	    end else if (mmu_da && ir == 32'b00110000001000000000000001110011) begin // hiject mret 
		pc <= saved_user_pc; // recover from shadow when see Mret
		bubble <= 1; // bubble
		for (i=0;i<10;i=i+1) begin re[i]<= sre[i]; end // recover usr re
		mmu_da <= 0; // MMU_DA OFF
		//Csrs[mstatus][MIE] <= Csrs[mstatus][MPIE]; // set back interrupt status
		
            // Interrupt PLIC full (Platform-Level-Interrupt-Control)  MMIO
	    end else if ((meip_interrupt || msip_interrupt) && Csrs[mstatus][MIE]==1) begin //mstatus[3] MIE
	    //end else if ((meip_interrupt || msip_interrupt) && Csrs[mstatus][MIE]==1 && !mmu_pc && !mmu_da && !mmu_cache_refill && !load_step && !store_step) begin //mstatus[3] MIE
                Csrs[mip][MTIP] <= time_interrupt; // MTIP linux will see then jump to its handler
                Csrs[mip][MEIP] <= meip_interrupt; // MEIP
                Csrs[mip][MSIP] <= msip_interrupt; // MSIP

		Csrs[mcause][INTERRUPT] <= 1; // MSB 1 for interrupts 0 for exceptions
                if (msip_interrupt) Csrs[mcause][CAUSE+62:CAUSE] <= 3; // Cause 3 for Sofeware Interrupt
                if (time_interrupt) Csrs[mcause][CAUSE+62:CAUSE] <= 7; // Cause 7 for Timer Interrupt
                if (meip_interrupt) Csrs[mcause][CAUSE+62:CAUSE] <= 11; // Cause 11 for External Interrupt

	        //Csrs[mepc] <= pc; // save next pc (interrupt asynchronize)
	        Csrs[mepc] <= pc-4; // save interruptec pc (interrupt asynchronize) ?? M-mode 3.1.15
		Csrs[mstatus][MPIE] <= Csrs[mstatus][MIE];
		Csrs[mstatus][MIE] <= 0;
		Csrs[mstatus][MPP+1:MPP] <= current_privilege_mode; // MPP = old mode
		if (Csrs[mtvec][MODE+1:MODE] == 1) begin // vec-mode 1
                    if (msip_interrupt) pc <= (Csrs[mtvec][BASE+61:BASE] << 2) + (MSIP << 2); // vectorily BASE & CAUSE_CODE are 4 bytes aligned already number need << 2
                    if (time_interrupt) pc <= (Csrs[mtvec][BASE+61:BASE] << 2) + (MTIP << 2);
                    if (meip_interrupt) pc <= (Csrs[mtvec][BASE+61:BASE] << 2) + (MEIP << 2); 
		end else pc <= (Csrs[mtvec][BASE+61:BASE] << 2);// jump to mtvec addrss (directly mode 0, need C or Assembly code of handlers deciding) 
		bubble <= 1'b1; // bubble wrong fetched instruciton by IF
		reserve_valid <= 0;// Interrupt clear lr.w/lr.d

	    // IR
	    end else begin 
                casez(ir)
	            // U-type
	            32'b???????_?????_?????_???_?????_0110111: re[w_rd] <= w_imm_u; // Lui
	            32'b???????_?????_?????_???_?????_0010111: re[w_rd] <= w_imm_u + (pc - 4); // Auipc
                    // Load after TLB
                    32'b???????_?????_?????_???_?????_0000011: begin 
                        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
                        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
                        if (load_step == 1 && bus_read_done == 1) begin re[w_rd] <= w_load_data; load_step <= 0; end 
                    end

                    // Store after TLB
                    32'b???????_?????_?????_???_?????_0100011: begin 
                        if (store_step == 0) begin bus_address <= pda; bus_write_data <= w_store_data; bus_write_enable <= 1; pc <= pc - 4; bubble <= 1; store_step <= 1; bus_ls_type <= w_func3; end
                        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
                        if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end 
                    end   
                    // Math-I
	            32'b???????_?????_?????_000_?????_0010011: re[w_rd] <= alu_addi;  // Addi
	            32'b???????_?????_?????_100_?????_0010011: re[w_rd] <= alu_xori; // Xori
	            32'b???????_?????_?????_111_?????_0010011: re[w_rd] <= alu_andi; // Andi
	            32'b???????_?????_?????_110_?????_0010011: re[w_rd] <= alu_ori; // Ori
	            32'b???????_?????_?????_001_?????_0010011: re[w_rd] <= alu_slli; // Slli
	            32'b000000?_?????_?????_101_?????_0010011: re[w_rd] <= alu_srli; // Srli // func7->6 // rv64 shame take w_f7[0]
	            32'b010000?_?????_?????_101_?????_0010011: re[w_rd] <= alu_srai; // Srai
	            32'b???????_?????_?????_010_?????_0010011: re[w_rd] <= alu_slti; // Slti
	            32'b???????_?????_?????_011_?????_0010011: re[w_rd] <= alu_sltiu; // Sltiu

                    // Math-I (Word)
	            32'b???????_?????_?????_000_?????_0011011: re[w_rd] <= alu_addiw;// Addiw
	            32'b???????_?????_?????_001_?????_0011011: re[w_rd] <= alu_slliw;// Slliw
	            32'b0000000_?????_?????_101_?????_0011011: re[w_rd] <= alu_srliw;// Srliw
	            32'b0100000_?????_?????_101_?????_0011011: re[w_rd] <= alu_sraiw;// Sraiw


                    // Math-R
	            32'b0000000_?????_?????_000_?????_0110011: re[w_rd] <= alu_add ;  // Add
	            32'b0100000_?????_?????_000_?????_0110011: re[w_rd] <= alu_sub ;  // Sub;
	            32'b???????_?????_?????_100_?????_0110011: re[w_rd] <= alu_xor ;  // Xor
	            32'b???????_?????_?????_111_?????_0110011: re[w_rd] <= alu_or  ;  // And
	            32'b???????_?????_?????_110_?????_0110011: re[w_rd] <= alu_and ;  // Or
	            32'b???????_?????_?????_001_?????_0110011: re[w_rd] <= alu_sll ; // Sll 6 length
                    32'b0000000_?????_?????_101_?????_0110011: re[w_rd] <= alu_srl ; // Srl 6 length
	            32'b0100000_?????_?????_101_?????_0110011: re[w_rd] <= alu_sra ; // Sra 6 length
	            32'b???????_?????_?????_010_?????_0110011: re[w_rd] <= alu_slt;  // Slt
	            32'b???????_?????_?????_011_?????_0110011: re[w_rd] <= alu_sltu; // Sltu

                    // Math-R (Word)
	            32'b0000000_?????_?????_000_?????_0111011: re[w_rd] <= alu_addw;  // Addw
	            32'b0100000_?????_?????_000_?????_0111011: re[w_rd] <= alu_subw;  // Subw
	            32'b???????_?????_?????_001_?????_0111011: re[w_rd] <= alu_sllw;  // Sllw 5 length
                    32'b0000000_?????_?????_101_?????_0111011: re[w_rd] <= alu_srlw;  // Srlw 5 length
	            32'b0100000_?????_?????_101_?????_0111011: re[w_rd] <= alu_sraw;  // Sraw 5 length
                    // Jump
	            32'b???????_?????_?????_???_?????_1101111: begin pc <= pc - 4 + w_imm_j; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1'b1; end // Jal
	            //32'b???????_?????_?????_???_?????_1100111: begin pc <= (re[w_rs1] + w_imm_i) & 64'hFFFFFFFFFFFFFFFE; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1; end // Jalr
	            32'b???????_?????_?????_???_?????_1100111: begin pc <= alu_addi & 64'hFFFFFFFFFFFFFFFE; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1; end // Jalr
                    // Branch 
		    32'b???????_?????_?????_000_?????_1100011: begin if (re[w_rs1] == re[w_rs2]) begin pc <= branch; bubble <= 1'b1; end end // Beq
		    32'b???????_?????_?????_001_?????_1100011: begin if (re[w_rs1] != re[w_rs2]) begin pc <= branch; bubble <= 1'b1; end end // Bne
		    32'b???????_?????_?????_100_?????_1100011: begin if ($signed(re[w_rs1]) < $signed(re[w_rs2])) begin pc <= branch; bubble <= 1'b1; end end // Blt
		    32'b???????_?????_?????_101_?????_1100011: begin if ($signed(re[w_rs1]) >= $signed(re[w_rs2])) begin pc <= branch; bubble <= 1'b1; end end // Bge
		    32'b???????_?????_?????_110_?????_1100011: begin if ($unsigned(re[w_rs1]) < $unsigned(re[w_rs2])) begin pc <= branch; bubble <= 1'b1; end end // Bltu
		    32'b???????_?????_?????_111_?????_1100011: begin if ($unsigned(re[w_rs1]) >= $unsigned(re[w_rs2])) begin pc <= branch; bubble <= 1'b1; end end // Bgeu
		    // System-CSR 
	            32'b???????_?????_?????_001_?????_1110011: begin if (w_rd != 0) re[w_rd] <= Csrs[w_csr_id]; Csrs[w_csr_id] <= rs1; end // Csrrw  bram read first old data
	            32'b???????_?????_?????_010_?????_1110011: begin if (w_rd != 0) re[w_rd] <= Csrs[w_csr_id]; if (w_rs1 != 0) Csrs[w_csr_id] <= (Csrs[w_csr_id] |  rs1); end // Csrrs
	            32'b???????_?????_?????_011_?????_1110011: begin if (w_rd != 0) re[w_rd] <= Csrs[w_csr_id]; if (w_rs1 != 0) Csrs[w_csr_id] <= (Csrs[w_csr_id] & ~rs1); end // Csrrc
	            32'b???????_?????_?????_101_?????_1110011: begin if (w_rd != 0) re[w_rd] <= Csrs[w_csr_id]; Csrs[w_csr_id] <= w_imm_z; end // Csrrwi
	            32'b???????_?????_?????_110_?????_1110011: begin if (w_rd != 0) re[w_rd] <= Csrs[w_csr_id]; if (w_imm_z != 0) Csrs[w_csr_id] <= (Csrs[w_csr_id] |  w_imm_z); end // csrrsi
	            32'b???????_?????_?????_111_?????_1110011: begin if (w_rd != 0) re[w_rd] <= Csrs[w_csr_id]; if (w_imm_z != 0) Csrs[w_csr_id] <= (Csrs[w_csr_id] & ~w_imm_z); end // Csrrci
                    // Ecall
	            32'b0000000_00000_?????_000_?????_1110011: begin 
	                                                if      (current_privilege_mode == U_mode) CAUSE_CODE = UECALL; // 8 indicate Ecall from U-mode; 9 call from S-mode; 11 call from M-mode
	                                                else if (current_privilege_mode == S_mode) CAUSE_CODE = SECALL; // block assign attaintion!
	                                                else if (current_privilege_mode == M_mode) CAUSE_CODE = MECALL;
						        if (Csrs[medeleg][CAUSE_CODE] == 1) // UECALL8 SECALL9 MECALL11 delegate to S-mode
	                 			        begin // Trap into S-mode
	                 			           Csrs[scause][INTERRUPT] <= 0; //63_type 0exception 1interrupt|value
	                 			           Csrs[scause][CAUSE+62:CAUSE] <= CAUSE_CODE; // 8 indicate Ecall from U-mode; 9 call from S-mode; 11 call from M-mode
	                 			           Csrs[sepc] <= pc - 4;  // Ecall is sycronized, back and repeat pc
							   Csrs[stval] <= 0; // mandatory
	                 			           Csrs[sstatus][SPP] <= (current_privilege_mode == U_mode ? 0 : 1); // save previous privilege mode(user0 super1) to SPP 
	                 			           Csrs[sstatus][SPIE] <= Csrs[sstatus][SIE]; // save interrupt enable(SIE) to SPIE 
	                 			           Csrs[sstatus][SIE] <= 0; // clear SIE
							   if (Csrs[stvec][MODE+1:MODE] == 0) pc <= (Csrs[stvec][BASE+61:BASE] << 2); // directly  
							   else  pc <= (Csrs[stvec][BASE+61:BASE] << 2) + (CAUSE_CODE << 2); // vectorily BASE & CAUSE_CODE are 4 bytes aligned already number need << 2
	                 				   current_privilege_mode <= S_mode;
		    				           bubble <= 1'b1;
	                 			       end
	                 			       else begin // Trap into M-mode
	                 			           Csrs[mcause][INTERRUPT] <= 0; //63_type 0exception 1interrupt|value
	                 			           Csrs[mcause][CAUSE+62:CAUSE] <= CAUSE_CODE; // 8 indicate Ecall from U-mode; 9 call from S-mode; 11 call from M-mode
	                 			           Csrs[mepc] <= pc - 4; 
							   Csrs[mtval] <= 0;
	                 			           Csrs[mstatus][MPIE] <= Csrs[mstatus][MIE]; // save interrupt enable(MIE) to MPIE 
	                 			           Csrs[mstatus][MIE] <= 0; // clear MIE (not enabled, blocked when trap)
							   if (Csrs[mtvec][MODE+1:MODE] == 0) pc <= (Csrs[mtvec][BASE+61:BASE] << 2); // directly
							   else  pc <= (Csrs[mtvec][BASE+61:BASE] << 2) + (CAUSE_CODE << 2); // vectorily
	                 				   Csrs[mstatus][MPP+1:MPP] <= current_privilege_mode; // save privilege mode to MPP 
	                 				   current_privilege_mode <= M_mode;  // set current privilege mode
		    				           bubble <= 1'b1;
	                 			       end
	                 			   end
                    // Ebreak
	            32'b0000000_00001_?????_000_?????_1110011: begin 
	                                                //CAUSE_CODE <= 3; // Breakpoint is 3
						        if (Csrs[medeleg][BREAK] == 1) // BREAK3 UECALL8 SECALL9 MECALL11 delegate to S-mode
	                 			        begin // Trap into S-mode
	                 			           Csrs[scause][INTERRUPT] <= 0; //63_type 0exception 1interrupt|value
	                 			           Csrs[scause][CAUSE+62:CAUSE] <= BREAK; // 8 indicate Ecall from U-mode; 9 call from S-mode; 11 call from M-mode
	                 			           Csrs[sepc] <= pc - 4;  // Ecall is sycronized, back and repeat pc
							   Csrs[stval] <= 0; // mandatory
	                 			           Csrs[sstatus][SPP] <= (current_privilege_mode == U_mode ? 0 : 1); // save previous privilege mode(user0 super1) to SPP 
	                 			           Csrs[sstatus][SPIE] <= Csrs[sstatus][SIE]; // save interrupt enable(SIE) to SPIE 
	                 			           Csrs[sstatus][SIE] <= 0; // clear SIE
							   if (Csrs[stvec][MODE+1:MODE] == 0) pc <= (Csrs[stvec][BASE+61:BASE] << 2); // directly  
							   else  pc <= (Csrs[stvec][BASE+61:BASE] << 2) + (BREAK << 2); // vectorily BASE & CAUSE_CODE are 4 bytes aligned already number need << 2
	                 				   current_privilege_mode <= S_mode;
		    				           bubble <= 1'b1;
	                 			       end
	                 			       else begin // Trap into M-mode
	                 			           Csrs[mcause][INTERRUPT] <= 0; //63_type 0exception 1interrupt|value
	                 			           Csrs[mcause][CAUSE+62:CAUSE] <= BREAK; // 8 indicate Ecall from U-mode; 9 call from S-mode; 11 call from M-mode
	                 			           Csrs[mepc] <= pc - 4; 
							   Csrs[mtval] <= 0;
	                 			           Csrs[mstatus][MPIE] <= Csrs[mstatus][MIE]; // save interrupt enable(MIE) to MPIE 
	                 			           Csrs[mstatus][MIE] <= 0; // clear MIE (not enabled, blocked when trap)
							   if (Csrs[mtvec][MODE+1:MODE] == 0) pc <= (Csrs[mtvec][BASE+61:BASE] << 2); // directly
							   else  pc <= (Csrs[mtvec][BASE+61:BASE] << 2) + (BREAK << 2); // vectorily
	                 				   Csrs[mstatus][MPP+1:MPP] <= current_privilege_mode; // save privilege mode to MPP 
	                 				   current_privilege_mode <= M_mode;  // set current privilege mode
		    				           bubble <= 1'b1;
	                 			       end
	                 			   end
                    // Mret
	            32'b0011000_00010_?????_000_?????_1110011: begin  
	               			       Csrs[mstatus][MIE] <= Csrs[mstatus][MPIE]; // set back interrupt enable(MIE) by MPIE 
	               			       Csrs[mstatus][MPIE] <= 1; // set previous interrupt enable(MIE) to be 1 (enable)
	               			       if (Csrs[mstatus][MPP+1:MPP] < M_mode) Csrs[mstatus][MPRV] <= 0; // set mprv to 0, modified privilege, 1 using in MPP not current
	               			       current_privilege_mode  <= Csrs[mstatus][MPP+1:MPP]; // set back previous mode
	               			       Csrs[mstatus][MPP+1:MPP] <= 2'b00; // set previous privilege mode(MPP) to be 00 (U-mode)
	               			       pc <=  Csrs[mepc]; // mepc was +4 by the software handler and written back to sepc
		          		       bubble <= 1'b1;
	               			       end
                    // Sret
	            32'b0001000_00010_?????_000_?????_1110011: begin      
	               			       Csrs[sstatus][SIE] <= Csrs[sstatus][SPIE]; // restore interrupt enable(SIE) by SPIE 
	               			       Csrs[sstatus][SPIE] <= 1; // next trap will have SPIE=1
	               			       if (Csrs[sstatus][SPP] == 0) current_privilege_mode <= U_mode;
					       else current_privilege_mode  <= S_mode;
	               			       Csrs[sstatus][SPP] <= 0; // set previous privilege mode(SPP) to be 0 (U-mode)
	               			       pc <=  Csrs[sepc]; // sepc was +4 by the software handler and written back to sepc
		          		       bubble <= 1'b1;
	               			       end 
		    // Wfi
		    32'b00010000010100000000000001110011: begin end
		    // Fence
		    32'b?????????????????_000_?????_0001111: begin end
		    // Fence.i
		    32'b?????????????????_001_?????_0001111: begin end
		    // Sfence.vma
		    32'b0001001??????????_000_?????_1110011: begin end
		    // RV64IMAFD(G)C  RVA23U64
		    // Atomic after TLB // -- ATOMIC instructions (A-extension) opcode: 0101111
		    // lr
		    32'b00010_??_?????_?????_01?_?????_0101111: begin  // Lr._mmu 3 cycles lr.w010 lr.d011
		        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; reserve_addr <= pda; reserve_valid <= 1; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		        if (load_step == 1 && bus_read_done == 1) begin 
		            //if (w_func3 == 3'b010) re[w_rd]<= $signed(bus_read_data[31:0]);  // lr.w
		            //if (w_func3 == 3'b011) re[w_rd]<= bus_read_data;  // lr.d
			    re[w_rd] <= amo_op_mem;
		            load_step <= 0; end end
		    // sc
	            32'b00011_??_?????_?????_01?_?????_0101111: begin  // sc.w010 sc.d011
		        if (store_step == 0) begin 
		            if (!reserve_valid || reserve_addr != pda) begin re[w_rd] <= 1; reserve_valid <= 0; end // finish failed 1 in rd cycle without bubble & clear reserve
		            else begin bus_address <= pda; 
			    bus_write_data<= w_atomic_write_data;
			    bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3;reserve_valid<=0;end end//consumed
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		        if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; re[w_rd] <= 0; end end // sc.w successed return 0 in rd

	           // amos(swap, add, xor, and, or, min, max) w/d
	            32'b?????_??_?????_?????_01?_?????_0101111: begin // not 00010lr/00011sc
		        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		        if (load_step == 1 && bus_read_done == 1) begin 
			    // finish load
			    re[w_rd] <= amo_op_mem; load_step <= 0;  // finish load
			    // start store
		            bus_address <= pda;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; 
			    bus_write_data <= w_atomic_write_data;
		        end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		        if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
	            // -- ATOMIC end --

                    // M-Extension 
		    // M mul mulh mulhsu mulhu 
		    32'b0000001_?????_?????_0??_?????_0110011, // Mul, Mulh, Mulhsu, Mulhu
		    32'b0000001_?????_?????_000_?????_0111011: // Mulw
		    begin
			if (!mul_done) begin
			    // request start
			    mul_enable <= 1;
			    // stall pipeline
			    pc <= pc - 4;
			    bubble <= 1;
			end else begin
			    // result ready
			    mul_enable <= 0;
			    // select output based on cached type
			    if (mul_out_sel == 0)      re[w_rd] <= mul_acc[63:0]; // Mul
			    else if (mul_out_sel == 1) re[w_rd] <= mul_acc[127:64]; // Mulh*
			    else                       re[w_rd] <= {{32{mul_acc[31]}}, mul_acc[31:0]}; // Mulw
			end
		    end

		    // M-Extension
		    // div divu rem remu mulw divw divuw remuw
		    32'b0000001_?????_?????_1??_?????_0110011: begin
			if (!div_done) begin
			    div_enable <= 1;
			    pc <= pc - 4;
			    bubble <= 1;
			end else begin
			    re[w_rd] <= div_result_out;
			    div_enable <= 0;
			end
		    end

	            // F (reg f0-f31)
	            // flw fsw fadd.s fsub.s fmul.s fdiv.s fsqrt.s fmadd.s
	            // fmsub.s fnmsub.s fcvt.w.s fcvt.wu.s fcvt.s.w fcvt.s.wu
	            // fmv.x.w fclass.s feq.s flt.s fle.s fsgnj.s fsgnjn.s
	            // fsgnjx.s fmin.s fmax.s
	            // D fld fsd fadd.d fsub.d fdiv.d fsqrt.d fmadd.s fcvt.d.s fcvt.s.d
	            // C
	            default: $display("unknow instruction %h, %b", ir, ir);
               endcase
	    end
        end
	re[0]<= 64'h0; 
	sre[0]<= 64'h0;
    end

endmodule

`include "header.vh"

module cpu_on_board (
    // -- Pin --
    (* chip_pin = "PIN_L1" *)  input wire CLOCK_50, // 50 MHz clock
    (* chip_pin = "PIN_R22" *) input wire KEY0,     // Active-low reset button
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *) output wire [7:0] LEDG, // 8 green LEDs
    (* chip_pin = "R17" *) output reg LEDR9, // 1 red LEDs breath left most 
    (* chip_pin = "R20" *) output wire LEDR0, // 
    (* chip_pin = "R19" *) output wire LEDR1, // 
    (* chip_pin = "U18, Y18, V19, T18, Y19, U19" *) output wire [5:0] LEDR_PC, // 8 red LEDs right
    (* chip_pin = "J2" *)  output wire HEX00,
    (* chip_pin = "J1" *)  output wire HEX01,
    (* chip_pin = "H2" *)  output wire HEX02,
    (* chip_pin = "H1" *)  output wire HEX03,
    (* chip_pin = "F2" *)  output wire HEX04,
    (* chip_pin = "F1" *)  output wire HEX05,
    (* chip_pin = "E2" *)  output wire HEX06,
    (* chip_pin = "E1" *)  output wire HEX10,
    (* chip_pin = "H6" *)  output wire HEX11,
    (* chip_pin = "H5" *)  output wire HEX12,
    (* chip_pin = "H4" *)  output wire HEX13,
    (* chip_pin = "G5" *)  output wire HEX20,
    (* chip_pin = "G6" *)  output wire HEX21,
    (* chip_pin = "C2" *)  output wire HEX22,
    (* chip_pin = "C1" *)  output wire HEX23,
    (* chip_pin = "F4" *)  output wire HEX30,
    (* chip_pin = "D5" *)  output wire HEX31,
    (* chip_pin = "D6" *)  output wire HEX32,
    (* chip_pin = "J4" *)  output wire HEX33,
    (* chip_pin = "L8" *)  output wire HEX34,
    (* chip_pin = "F3" *)  output wire HEX35,
    (* chip_pin = "D4" *)  output wire HEX36,
    (* chip_pin = "H15" *)  input wire PS2_CLK, 
    (* chip_pin = "J14" *)  input wire PS2_DAT,
    (* chip_pin = "V20" *)  output wire SD_CLK, //SD_CLK
    (* chip_pin = "Y20" *)  inout wire SD_CMD, // SD_CMD (MOSI)
    (* chip_pin = "W20" *)  inout wire SD_DAT0, // SD_DAT (MISO)
    (* chip_pin = "U20" *)  output wire SD_DAT3, // SD_DAT3
//);

    // -- SDRAM pins -- 
    (* chip_pin = "N6, W3, N4, P3, P5, P6, R5, R6, Y4, Y3, W5, W4" *)  output wire [11:0] DRAM_ADDR,
    (* chip_pin = "T2, T1, R2, R1, P2, P1, N2, N1, Y2, Y1, W2, W1, V2, V1, U2, U1" *)  inout wire [15:0] DRAM_DQ,
    (* chip_pin = "V4, U3" *)  output wire [1:0] DRAM_BA, // Bank address
    (* chip_pin = "T3" *)  output wire DRAM_CAS_N, // Column address strobe
    (* chip_pin = "T5" *)  output wire DRAM_RAS_N, // Row address strobe
    (* chip_pin = "U4" *)  output wire DRAM_CLK, 
    (* chip_pin = "N3" *)  output wire DRAM_CKE,  // Clock enable
    (* chip_pin = "R8" *)  output wire DRAM_WE_N, // write enable
    (* chip_pin = "T6" *)  output wire DRAM_CS_N,  // chip selected
    (* chip_pin = "M5, R7" *)  output wire [1:0] DRAM_DQM   // High-low byte data mask
);

reg [21:0] sdram_addr;
reg [15:0] sdram_wrdata;
reg [1:0]  sdram_byte_en; // Enable all bytes (active low);
// Control
reg sdram_write_en;
reg sdram_read_en;

wire [15:0] sdram_rddata;   
wire        sdram_req_wait;
wire sdram_ready;

sdram_controller sdram_ctrl (
    .sys_clk(clock_1hz),
    .rstn(KEY0),
    // to bus (software)
    .avl_addr(sdram_addr),
    .avl_byte_en(sdram_byte_en),
    .avl_WRITEen(sdram_write_en),
    .avl_READen(sdram_read_en),
    .avl_WRDATA(sdram_wrdata),
    .avl_RDDATA(sdram_rddata),
    .avl_req_wait(sdram_req_wait),
    .avl_ready(sdram_ready),
    // to pin (hardware)
    .addr(DRAM_ADDR),        // new_sdram_controller_0_wire.addr
    .BA(DRAM_BA),            //                            .ba
    .CASn(DRAM_CAS_N),       //                            .cas_n
    .CSn(DRAM_CS_N),         //                            .cs_n
    .DQ(DRAM_DQ),            //                            .dq
    .DQM(DRAM_DQM),          //                            .dqm
    .RASn(DRAM_RAS_N),       //                            .ras_n
    .WEn(DRAM_WE_N)          //                            .we_n
);
assign DRAM_CLK = clock_1hz;
assign DRAM_CKE = 1; // always enable

    // -- MEM -- minic L1 cache
    //(* ram_style = "block" *) reg [31:0] Cache [0:2000];
    (* ram_style = "block" *) reg [31:0] Cache [0:511]; // 2KB
    //(* ram_style = "block" *) reg [31:0] Cache [0:383]; // 1.5KB
    integer i;
    initial begin
        $readmemb("rom.mif", Cache, `Rom_base>>2);
        $readmemb("ram.mif", Cache, `Ram_base>>2);
    end

    // -- Clock --
    wire clock_1hz;
    clock_slower clock_ins(
        .clk_in(CLOCK_50),
        .clk_out(clock_1hz),
        .reset_n(KEY0)
    );
    

    wire [63:0] ppc;
    reg [31:0] ir_bd;
    //wire bubble;
    // IR_LD BRAM Port A read
    always @(posedge clock_1hz) begin ir_bd <= Cache[ppc>>2]; end
    wire [31:0] ir_ld; assign ir_ld = ir_bd;//{ir_bd[7:0], ir_bd[15:8], ir_bd[23:16], ir_bd[31:24]}; // Endianness swap
    assign LEDR_PC = ppc/4;
    assign LEDG = ir_ld;

    // -- CPU --
    riscv64 cpu (
        //.clk(clock_1hz), 
        .clk(clock_1hz), 
        .reset(KEY0),     
        .instruction(ir_ld),
        //.pc(pc),
        .ppc(ppc),
        //.bubble(bubble),
        //.ir(LEDG),
        .heartbeat(LEDR9),

        .bus_address(bus_address),
        .bus_write_data(bus_write_data),
        .bus_write_enable(bus_write_enable),
        .bus_read_enable(bus_read_enable),

        .bus_ls_type(bus_ls_type), // lb lh lw ld lbu lhu lwu sb sh sw sd 
	.mtime(mtime),
	.mtimecmp(mtimecmp),
	.meip_interrupt(meip_interrupt),
	.msip_interrupt(msip_interrupt),

        .bus_read_data(bus_read_data),
        .bus_read_done(bus_read_done),
        .bus_write_done(bus_write_done)
    );

    // -- Keyboard -- 
    reg [7:0] ascii;
    reg [7:0] scan;
    reg key_pressed_delay;
    wire key_pressed;
    wire key_released;

    ps2_decoder ps2_decoder_inst (
        .clk(clock_1hz),
        .ps2_clk_async(PS2_CLK),
        .ps2_data_async(PS2_DAT),
        .scan_code(scan),
        .ascii_code(ascii),
        .key_pressed(key_pressed),
        .key_released(key_released)
     );
    always @(posedge clock_1hz) begin key_pressed_delay <= key_pressed; end
    wire key_pressed_edge = key_pressed && !key_pressed_delay;

    // -- Monitor -- Connected to Bus
    reg uart_write_pulse;
    reg uart_write_step;
    reg uart_read_pulse;
    reg uart_read_step;
    wire uart_waitrequest;
    jtag_uart_system my_jtag_system (
        .clk_clk                                 (clock_1hz),
        .reset_reset_n                           (KEY0),
        //.jtag_uart_0_avalon_jtag_slave_address   (bus_address[0:0]),
        .jtag_uart_0_avalon_jtag_slave_address   (~bus_address[2]), // 0x00 for Data, 0x04 for Control
        .jtag_uart_0_avalon_jtag_slave_writedata (bus_write_data[31:0]),
        //.jtag_uart_0_avalon_jtag_slave_write_n   (~uart_write_trigger_pulse),
        .jtag_uart_0_avalon_jtag_slave_write_n   (~uart_write_pulse),
        .jtag_uart_0_avalon_jtag_slave_chipselect(1'b1),
        //.jtag_uart_0_avalon_jtag_slave_read_n    (~(bus_read_done==0 && Art_selected)),
        .jtag_uart_0_avalon_jtag_slave_read_n    (~uart_read_pulse),
	
        .jtag_uart_0_avalon_jtag_slave_readdata    (uart_readdata),
        .jtag_uart_0_avalon_jtag_slave_waitrequest (uart_waitrequest),
	.jtag_uart_0_irq_irq(uart_irq)                        
    );

    // -- Bus --
    reg  [63:0] bus_read_data;
    wire [63:0] bus_address;
    wire        bus_read_enable;
    wire [63:0] bus_write_data;
    wire        bus_write_enable;
    wire [2:0]  bus_ls_type; // lb lbu...sbhwd...
    wire [63:0] mtime;
    reg  [63:0] mtimecmp;


    // -- PLIC --
    (* ram_style = "logic" *) reg [2:0]  Plic_priority [0:5];  // 0x000 + 4 per id
    reg [31:0] Plic_pending; // 0x1000 Global pending Bitmap 
    reg [31:0] Plic_enable [0:1];  // 0x2000 per context +0x80
    reg [2:0]  Plic_threshold [0:1]; // 0x200000 4B per hart
    //# PER PRIORITY(id) = base + 4 * id (000-fff) array
    //# base + 0x1000 id 1-32 ... bitmap
    //# base + 0x2000 + ContextID*0x80 0hart0M 1hart0S... bitmap
    //# base + 0x200000 + ContextID*0x1000 0hart0M 1hart0S...4B 
    //# base + 0x200004 + ContextID*0x1000 0hart0M 1hart0S...4B
    //
    // Address Decoding --
    wire Rom_selected = (bus_address >= `Rom_base && bus_address < `Rom_base + `Rom_size);
    wire Ram_selected = (bus_address >= `Ram_base && bus_address < `Ram_base + `Ram_size);
    wire Key_selected = (bus_address == `Key_base);
    wire Art_selected = (bus_address == `Art_base || bus_address == `ArtC_base);
    wire Sdc_addr_selected = (bus_address == `Sdc_addr);
    wire Sdc_read_selected = (bus_address == `Sdc_read);
    wire Sdc_write_selected = (bus_address == `Sdc_write);
    wire Sdc_ready_selected = (bus_address == `Sdc_ready);
    wire Sdc_cache_selected = (bus_address >= `Sdc_base && bus_address < (`Sdc_base + 512));
    wire Sdc_avail_selected = (bus_address == `Sdc_avail);
    wire Sdram_selected = (bus_address >= `Sdram_min && bus_address < `Sdram_max);
    wire Mtime_selected = (bus_address == `Mtime);
    wire Mtimecmp_selected = (bus_address == `Mtimecmp);
    //wire CacheI_selected = (bus_address == `CacheI);
    //---
    wire CacheI_L_selected = (bus_address == `CacheI_L);
    wire CacheI_H_selected = (bus_address == `CacheI_H);
    //---
    wire Tlb_selected = (bus_address == `Tlb);

    // Plic mapping
    wire Plic_priority_selected = (bus_address >= `Plic_base && bus_address < `Plic_pending);
    wire Plic_pending_selected = (bus_address == `Plic_pending);
    wire Plic_enable_ctx0_selected = (bus_address == `Plic_enable);
    wire Plic_enable_ctx1_selected = (bus_address == `Plic_enable + 64'h80);
    wire Plic_threshold_ctx0_selected = (bus_address == `Plic_threshold);
    wire Plic_threshold_ctx1_selected = (bus_address == `Plic_threshold + 64'h1000);
    wire Plic_claim_ctx0_selected = (bus_address == `Plic_claim );
    wire Plic_claim_ctx1_selected = (bus_address == `Plic_claim + 64'h1000);
    //wire Plic_claim_ctx0_selected = (bus_address >= `Plic_claim && bus_address < `Plic_claim+1024*0x1000+4);
    reg [31:0] claim_interrupt_id_ctx [0:1]; // 0 for hart0M 1 for hart0S

    always @(*) begin
        claim_interrupt_id_ctx[0] = 0; 
        claim_interrupt_id_ctx[1] = 0; 
        if (Plic_pending[1] && Plic_enable[0][1]) claim_interrupt_id_ctx[0] = 1; 
        if (Plic_pending[1] && Plic_enable[1][1]) claim_interrupt_id_ctx[1] = 1; 
    end

    wire meip_interrupt = (claim_interrupt_id_ctx[0] != 0);
    wire msip_interrupt = (claim_interrupt_id_ctx[1] != 0);
    wire uart_irq;
    reg uart_irq_pre;
    wire [31:0] uart_readdata;


    // Read & Write BRAM Port B 
    reg [63:0] bus_address_reg;
    reg [63:0] bus_address_reg_full;
    reg [5:0] step = 0;
    reg bus_read_done = 1;
    reg bus_write_done = 1;
    reg [63:0] next_addr;
    wire [4:0] plic_id = (bus_address - `Plic_base) >> 2; // id = offset /4

    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) begin
            bus_read_done <= 1;
            bus_write_done <= 1;
	    bus_address_reg <= 0;
	    bus_address_reg_full <= 0;
	    next_addr <= 0;
	    step <= 0;
	    bus_read_data <= 0;
	    uart_write_pulse <= 0;
	    uart_read_pulse <= 0;
	    uart_read_step <= 0;
	    mtimecmp <=  64'h80000000;
	    uart_irq_pre <= 0;
	end else begin
        bus_address_reg <= bus_address>>2;
        bus_address_reg_full <= bus_address;
        sd_rd_start <= 0;
        uart_write_pulse <= 0;
	uart_read_pulse <= 0;
	uart_irq_pre <= uart_irq;
	if (uart_irq && !uart_irq_pre) Plic_pending[1] <= 1;
	//if (key_pressed_edge) Plic_pending[1] <= 1;

        if (bus_read_enable) begin bus_read_done <= 0; cid <= (bus_address-`Sdc_base); end 
        if (bus_write_enable) begin bus_write_done <= 0; end

        // Read
        //if (!bus_read_enable && bus_read_done==0) begin 
        if (bus_read_done==0) begin 
            if (Key_selected) begin bus_read_data <= {32'd0, 24'd0, ascii}; bus_read_done <= 1; end
	    if (Ram_selected) begin 
	        casez(bus_ls_type)
	            3'b011: begin // 011Ld
		        case(step)
			    0: begin bus_read_data[31:0]  <= Cache[bus_address_reg]; bus_address_reg <= bus_address_reg +1; step <= 1; end
		            1: begin bus_read_data[63:32] <= Cache[bus_address_reg]; step <= 0; bus_read_done <= 1; end
			endcase
		    end 
		    default: begin bus_read_data <= Cache[bus_address_reg] >> (8*bus_address_reg_full[1:0]); bus_read_done <= 1; end // 000Lb 001Lh 010Lw 101Lhu 100Lbu 110Lwu
		endcase
	    end

            if (Sdc_ready_selected) begin bus_read_data <= {63'd0, sd_ready}; bus_read_done <= 1; end
	    if (Sdc_cache_selected) begin bus_read_data <= {56'd0, sd_cache[cid]}; bus_read_done <= 1; end // one byte for all load
            if (Sdc_avail_selected) begin bus_read_data <= {63'd0, sd_cache_available}; bus_read_done <= 1; end 

            if (Mtime_selected) begin bus_read_data <= mtime; bus_read_done <= 1; end 
            if (Mtimecmp_selected) begin bus_read_data <= mtimecmp; bus_read_done <= 1; end 

	    if (Art_selected) begin 
	        if (uart_read_step ==0) begin uart_read_pulse <= 1; uart_read_step <= 1; end
	        //if (uart_read_step ==1 &&  uart_waitrequest) begin uart_read_pulse <= 1; end
	        //if (uart_read_step ==1 && !uart_waitrequest) begin bus_read_data <= uart_readdata; uart_read_step <= 0; bus_read_done <=1; uart_read_pulse <= 0;end
	        if (uart_read_step ==1 && !uart_waitrequest) begin bus_read_data <= uart_readdata; uart_read_step <= 0; bus_read_done <=1; end
	    end

	    if (Sdram_selected) begin
		case(bus_ls_type)
	            3'b000: begin //lb
			    case(step)
				0: if (sdram_ready) begin sdram_addr <= bus_address[22:1]; sdram_byte_en <= bus_address[0] ? 2'b10 : 2'b01; sdram_read_en <= 1;  step <= 1; end
			        1: if (sdram_req_wait==0) begin 
			              case(bus_address[0])
			                  0: begin bus_read_data <= {{56{sdram_rddata[7]}}, sdram_rddata[7:0]}; end  // byte 0
			                  1: begin bus_read_data <= {{56{sdram_rddata[15]}}, sdram_rddata[15:8]}; end // byte 1
			              endcase
			              sdram_read_en <= 0; bus_read_done <= 1; step <= 0;
			           end
			    endcase
		            end
	            3'b100: begin //lbu
			    case(step)
				0: if (sdram_ready) begin sdram_addr <= bus_address[22:1]; sdram_byte_en <= bus_address[0] ? 2'b10 : 2'b01; sdram_read_en <= 1; step <= 1; end
			        1: if (sdram_req_wait==0) begin 
			               case(bus_address[0])
			                   0: begin bus_read_data <= {56'b0, sdram_rddata[7:0]}; end  // byte 0
			                   1: begin bus_read_data <= {56'b0, sdram_rddata[15:8]}; end // byte 1
			               endcase
			               sdram_read_en <= 0; bus_read_done <= 1; step <= 0;
			           end
			    endcase
		            end
	            3'b001: begin // lh
			    case(step)
				0: if (sdram_ready) begin sdram_addr <= bus_address[22:1]; sdram_byte_en <= 2'b11; sdram_read_en <= 1; step <= 1; end
			        1: if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data <= {{48{sdram_rddata[15]}}, sdram_rddata[15:0]}; bus_read_done <= 1; step <= 0; end
		            endcase
		            end
	            3'b101: begin // lhu 
			    case(step)
				0: if (sdram_ready) begin sdram_addr <= bus_address[22:1]; sdram_byte_en <= 2'b11; sdram_read_en <= 1; step <= 1; end
			        1: if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data <= {48'b0, sdram_rddata[15:0]}; bus_read_done <= 1; step <= 0; end
		            endcase
		            end
	            3'b010: begin // lw
		        case(step)
			    0: if (sdram_ready) begin sdram_addr <= bus_address[22:1]; sdram_byte_en <= 2'b11; sdram_read_en <= 1; step <= 1; end
			    1: if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data<= {48'b0, sdram_rddata[15:0]};bus_read_done <= 0; step <=2; end
			    2: if (sdram_ready) begin sdram_addr <= bus_address[22:1]+1; sdram_byte_en <= 2'b11; sdram_read_en <= 1; step <= 3; end
			    3: if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data[63:16] <= {{32{sdram_rddata[15]}}, sdram_rddata[15:0]}; bus_read_done <= 1; step <=0; end
			endcase
		        end
	            3'b110: begin // lwu 
		        case(step)
			    0: if (sdram_ready) begin sdram_addr <= bus_address[22:1]; sdram_byte_en <= 2'b11; sdram_read_en <= 1; step <= 1; end
			    1: if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data<= {48'b0, sdram_rddata[15:0]};bus_read_done <= 0; step <=2; end
			    2: if (sdram_ready) begin sdram_addr <= bus_address[22:1]+1; sdram_byte_en <= 2'b11; sdram_read_en <= 1;  step <= 3; end
			    3: if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data[31:16] <= sdram_rddata[15:0]; bus_read_done <= 1; step <=0; end
			endcase
		        end
	        //    3'b011: begin // ld 
		//        case(step)
		//	    0: begin sdram_addr <= bus_address[22:1];   sdram_byte_en <= 2'b11; sdram_read_en <= 1; step <= 1; end 
		//	    1: if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data<= {48'b0, sdram_rddata[15:0]};bus_read_done <= 0; step <=2; end
		//            2: begin sdram_addr <= bus_address[22:1]+1; sdram_byte_en <= 2'b11; sdram_read_en <= 1; step <= 3; end  
		//	    3: if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data[31:16] <= sdram_rddata[15:0]; bus_read_done <= 0; step <=4; end
		//            4: begin sdram_addr <= bus_address[22:1]+2; sdram_byte_en <= 2'b11; sdram_read_en <= 1; step <= 5; end  
		//	    5: if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data[47:32] <= sdram_rddata[15:0]; bus_read_done <= 0; step <=6; end
		//            6: begin sdram_addr <= bus_address[22:1]+3; sdram_byte_en <= 2'b11; sdram_read_en <= 1; step <= 7; end  
		//	    7: if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data[63:48] <= sdram_rddata[15:0]; bus_read_done <= 1; step <=0; end
		//	endcase
	            3'b011: begin // ld  // add infinite count force done=1
		        case(step)
			    0: if (sdram_ready) begin sdram_addr <= bus_address[22:1];   sdram_byte_en <= 2'b11; sdram_read_en <= 1; step <= 1; end 
			    1: if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data<= {48'b0, sdram_rddata[15:0]};bus_read_done <= 0; step <=2; end
		            2: if (sdram_ready) begin sdram_addr <= bus_address[22:1]+1; sdram_byte_en <= 2'b11; sdram_read_en <= 1; step <= 3; end  
			    3: if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data[31:16] <= sdram_rddata[15:0]; bus_read_done <= 0; step <=4; end
		            4: if (sdram_ready) begin sdram_addr <= bus_address[22:1]+2; sdram_byte_en <= 2'b11; sdram_read_en <= 1; step <= 5; end  
			    5: if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data[47:32] <= sdram_rddata[15:0]; bus_read_done <= 0; step <=6; end
		            6: if (sdram_ready) begin sdram_addr <= bus_address[22:1]+3; sdram_byte_en <= 2'b11; sdram_read_en <= 1; step <= 7; end  
			    7: if (sdram_req_wait==0) begin sdram_read_en <= 0; bus_read_data[63:48] <= sdram_rddata[15:0]; bus_read_done <= 1; step <=0; end
			endcase
		    end
		endcase
                // 000Lb 001Lh 010Lw  011Ld // 100Lbu 101Lhu 110Lwu
	    end
            // Plic read
	    if (Plic_priority_selected) begin bus_read_data <= Plic_priority[plic_id]; bus_read_done <= 1; end
	    else if (Plic_pending_selected) begin bus_read_data <= Plic_pending; bus_read_done <= 1; end
	    // context 0 M-mode
	    else if (Plic_enable_ctx0_selected) begin bus_read_data <= Plic_enable[0]; bus_read_done <= 1; end
	    else if (Plic_threshold_ctx0_selected) begin bus_read_data <= Plic_threshold[0]; bus_read_done <= 1; end
	    else if (Plic_claim_ctx0_selected) begin bus_read_data <= claim_interrupt_id_ctx[0]; Plic_pending[claim_interrupt_id_ctx[0]]<=0; bus_read_done <= 1; end
	    // context 1 S-mode
	    else if (Plic_enable_ctx1_selected) begin bus_read_data <= Plic_enable[1]; bus_read_done <= 1; end
	    else if (Plic_threshold_ctx1_selected) begin bus_read_data <= Plic_threshold[1]; bus_read_done <= 1; end
	    else if (Plic_claim_ctx1_selected) begin bus_read_data <= claim_interrupt_id_ctx[1]; Plic_pending[claim_interrupt_id_ctx[1]]<=0; bus_read_done <= 1; end


        end

        // Write
        //if (bus_write_enable || sd!=0 ) begin 
        //if (!bus_write_enable && bus_write_done == 0) begin 
        if (bus_write_done == 0) begin 
	    if (Ram_selected) begin 
		casez(bus_ls_type) // 000sb 001sh 010sw 011sd
		    3'b000: begin //sb
			if (bus_address[1:0] == 0) Cache[bus_address[63:2]][7:0] <= bus_write_data[7:0];
			if (bus_address[1:0] == 1) Cache[bus_address[63:2]][15:8] <= bus_write_data[7:0];
			if (bus_address[1:0] == 2) Cache[bus_address[63:2]][23:16] <= bus_write_data[7:0];
			if (bus_address[1:0] == 3) Cache[bus_address[63:2]][31:24] <= bus_write_data[7:0];
		        bus_write_done <= 1;
			end
		    3'b001: begin //sh
			if (bus_address[1:0] == 0) Cache[bus_address[63:2]][15:0] <= bus_write_data[15:0];
			if (bus_address[1:0] == 2) Cache[bus_address[63:2]][31:16] <= bus_write_data[15:0];
		        bus_write_done <= 1;
			end
		    3'b010: begin Cache[bus_address[63:2]] <= bus_write_data[31:0]; bus_write_done <= 1; end
		    3'b011: begin //sd
		        case(step)
		            0: begin Cache[bus_address[63:2]] <= bus_write_data[31:0]; step <= 1; next_addr <= bus_address[63:2]+1; bus_write_done <= 0; end
			    1: begin Cache[next_addr] <= bus_write_data[63:32]; step <= 0; bus_write_done <= 1; end
			endcase
			end
	        endcase
	    end

	    if (Sdc_addr_selected) begin sd_addr <= bus_write_data[31:0]; bus_write_done <= 1; end
	    if (Sdc_read_selected) begin sd_rd_start <= 1; bus_write_done <= 1; end

	    //if (Art_selected) begin uart_write_pulse <= 1; bus_write_done <=1; end
	    if (Art_selected) begin 
	        if (uart_write_step ==0) begin uart_write_pulse <= 1; uart_write_step <= 1; end
	        //if (uart_write_step ==1 &&  uart_waitrequest) begin uart_write_pulse <= 1; end
	        //if (uart_write_step ==1 && !uart_waitrequest) begin uart_write_step <= 0; bus_write_done <=1; uart_write_pulse <= 0;end
	        if (uart_write_step ==1 && !uart_waitrequest) begin uart_write_step <= 0; bus_write_done <=1; end
	    end
        
	

	    if (Mtimecmp_selected) begin mtimecmp <= bus_write_data; bus_write_done <= 1; end
	    //if (Sdram_selected) begin if (sdram_req_wait==0) bus_write_done <= 1; end

            if (Tlb_selected) bus_write_done <= 1; 
	    //if (CacheI_selected) bus_write_done <= 1; 
	    if (CacheI_L_selected) bus_write_done <= 1; 
	    if (CacheI_H_selected) bus_write_done <= 1; 
	    
            // Plic write
	    if (Plic_priority_selected) begin Plic_priority[plic_id] <= bus_write_data; bus_write_done <= 1; end
	    // context 0
	    else if (Plic_enable_ctx0_selected) begin Plic_enable[0] <= bus_write_data; bus_write_done <= 1; end
	    else if (Plic_threshold_ctx0_selected) begin Plic_threshold[0] <= bus_write_data; bus_write_done <= 1; end
	    else if (Plic_claim_ctx0_selected) begin bus_write_done <= 1; end // set to 0 when read already
	    //else if (Plic_claim_ctx0_selected) begin Plic_pending[bus_write_data] <= 0; bus_write_done <= 1; end
	    // context 1
	    else if (Plic_enable_ctx1_selected) begin Plic_enable[1] <= bus_write_data; bus_write_done <= 1; end
	    else if (Plic_threshold_ctx1_selected) begin Plic_threshold[1] <= bus_write_data; bus_write_done <= 1; end
	    else if (Plic_claim_ctx1_selected) begin bus_write_done <= 1; end // set to 0 when read already
	    //else if (Plic_claim_ctx1_selected) begin Plic_pending[bus_write_data] <= 0; bus_write_done <= 1; end
	    
        end

	    if (Sdram_selected && bus_write_done==0) begin 
		case(bus_ls_type)
	            3'b000: begin //sb
		            case(step)
		                0: if (sdram_ready) begin sdram_addr<=bus_address[22:1];
		                                          sdram_wrdata<={bus_write_data[7:0],bus_write_data[7:0]};
		                                          sdram_write_en<=1;
		                                          sdram_byte_en <= bus_address[0] ? 2'b10 : 2'b01; 
							  step <= 1;
						    end
		                1: if (sdram_req_wait==0) begin sdram_write_en <= 0; bus_write_done <= 1; step <= 0; end 
			    endcase
		    end
		    3'b001: begin //sh
		            case(step)
				0: if (sdram_ready) begin sdram_addr <= bus_address[22:1]; sdram_wrdata <= bus_write_data[15:0]; sdram_write_en <= 1; sdram_byte_en <= 2'b11; step <= 1; end
			        1: if (sdram_req_wait==0) begin sdram_write_en <= 0; bus_write_done <= 1; step <= 0; end
			    endcase
		    end
		    3'b010: begin //sw
		        case(step)
			    0: if (sdram_ready) begin sdram_addr <= bus_address[22:1]; sdram_wrdata <= bus_write_data[15:0]; sdram_write_en <= 1; sdram_byte_en <= 2'b11; step <= 1; end
			    1: if (sdram_req_wait==0) begin sdram_write_en <= 0; bus_write_done <= 0; step <= 2; end 
			    2: if (sdram_ready) begin sdram_addr <= bus_address[22:1]+1; sdram_wrdata <= bus_write_data[31:16]; sdram_write_en <= 1; sdram_byte_en <= 2'b11; step <= 3; end
			    3: if (sdram_req_wait==0) begin sdram_write_en <= 0; bus_write_done <= 1; step <= 0; end
			endcase
		    end
		    3'b011: begin //sd
		        case(step)
			    0: if (sdram_ready) begin sdram_addr <= bus_address[22:1];   sdram_wrdata <= bus_write_data[15:0];  sdram_write_en <= 1; sdram_byte_en <= 2'b11; step <= 1; end
			    1: if (sdram_req_wait==0) begin sdram_write_en <= 0; bus_write_done <= 0; step <= 2; end
			    2: if (sdram_ready) begin sdram_addr <= bus_address[22:1]+1; sdram_wrdata <= bus_write_data[31:16]; sdram_write_en <= 1; sdram_byte_en <= 2'b11; step <= 3; end
			    3: if (sdram_req_wait==0) begin sdram_write_en <= 0; bus_write_done <= 0; step <= 4; end
			    4: if (sdram_ready) begin sdram_addr <= bus_address[22:1]+2; sdram_wrdata <= bus_write_data[47:32]; sdram_write_en <= 1; sdram_byte_en <= 2'b11; step <= 5; end
			    5: if (sdram_req_wait==0) begin sdram_write_en <= 0; bus_write_done <= 0; step <= 6; end 
			    6: if (sdram_ready) begin sdram_addr <= bus_address[22:1]+3; sdram_wrdata <= bus_write_data[63:48]; sdram_write_en <= 1; sdram_byte_en <= 2'b11; step <= 7; end
			    7: if (sdram_req_wait==0) begin sdram_write_en <= 0; bus_write_done <= 1; step <= 0; end 
			endcase
		    end
		 //000sb 001sh 010sw 011sd
	        endcase
	    end



    end
end

    // -- SD Card --
    //wire [11:0] cid = (bus_address-`Sdc_base);
    reg [11:0] cid;
    //reg [7:0] sd_cache [0:511];
    (* ram_style = "block" *) reg [7:0] sd_cache [0:511];
    reg [9:0] byte_index = 0;
    reg sd_cache_available = 0;
    reg sd_byte_available_d = 0;
    reg do_read = 0;
    wire [4:0] sd_status;
    always @(posedge clock_1hz or negedge KEY0) begin
	if (!KEY0) begin
	    //sd_rd_start <= 0;
	    byte_index <= 0;
	    do_read <=0;
	    sd_cache_available <= 0;
	    //sd_byte_available <= 0;
	    sd_byte_available_d <= 0;
	end
	else begin
	    //sd_cache_available <= 0;
            sd_byte_available_d  <= sd_byte_available;
            if (sd_byte_available && !sd_byte_available_d) begin
	        sd_cache[byte_index] <= sd_dout;
	        byte_index <= byte_index + 1;
	        do_read <=1;
	    end
	    if (byte_index == 10) sd_cache_available <= 0;
	    //if (do_read && sd_status !=6) begin 
	    if (byte_index == 512) begin 
	        //sd_rd_start <= 0;
	        byte_index <= 0;
	        do_read <=0;
	        sd_cache_available <= 1;
	    end
        end
    end

    // Slow pulse clock for SD init (~100 kHz)
    reg [8:0] clkdiv = 0;
    always @(posedge clock_1hz or negedge KEY0) begin
        if (!KEY0) clkdiv <= 0;
        else clkdiv <= clkdiv + 1;
    end
    wire clk_pulse_slow = (clkdiv == 0);

    // SD Controller Bridge
    reg [31:0] sd_addr = 0;           // Sector address
    reg sd_rd_start;                  // Trigger rd

    wire [7:0] sd_dout;
    wire sd_ready;
    wire sd_byte_available;

    // SD Controller Instantiation
    sd_controller sdctrl (
        .cs(SD_DAT3),
        .mosi(SD_CMD),
        .miso(SD_DAT0),
        .sclk(SD_CLK),

        .rd(sd_rd_start),
        .wr(1'b0),
        .dout(sd_dout),
        .byte_available(sd_byte_available),

        .din(8'd0),
        .ready_for_next_byte(),
        .reset(~KEY0),
        .ready(sd_ready),
        .address(sd_addr),
        .clk(clock_1hz),
        .clk_pulse_slow(clk_pulse_slow),
        .status(sd_status),
        .recv_data()
    );

    // Debug LEDs
    assign HEX30 = ~Key_selected;
    assign HEX20 = ~|bus_read_data;
    assign HEX21 = ~bus_read_enable;
    assign HEX10 = ~|bus_write_data;
    assign HEX11 = ~bus_write_enable;
    assign HEX00 = ~Art_selected;
    assign HEX01 = ~Ram_selected;
    assign HEX02 = ~Rom_selected;
    //assign HEX03 = ~Sdram_selected ;
    assign HEX03 = (bus_address >= `Sdram_min && bus_address < `Sdram_max);

    assign HEX31 = ~Sdram_selected;
    //assign HEX32 = ~sdram_readdatavalid;
    //assign HEX33 = sdram_read_n;
    assign HEX33 = ~sdram_read_en;
    //assign HEX34 = sdram_write_n;
    assign HEX34 = ~sdram_write_en;
    //assign HEX35 = ~sdram_waitrequest;
    assign HEX35 = ~sdram_req_wait;
    //assign HEX36 = ~|sdram_readdata;
    assign HEX36 = ~|sdram_rddata;
    assign HEX04 = ~uart_irq;
    assign HEX05 = ~Plic_priority_selected;
    assign HEX06 = ~meip_interrupt;

endmodule
