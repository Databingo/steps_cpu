`include "header.vh"

module riscv64(
    input wire clk, 
    input wire reset,     // Active-low reset button
    input wire [31:0] instruction,
    //output reg [63:0] pc,
    output reg [38:0] pc,
    output reg [31:0] ir,
    //output reg [63:0] re [0:31], // General Registers 32s
    output wire  heartbeat,
    input  reg [3:0] interrupt_vector, // notice from outside
    output reg  interrupt_ack,         // reply to outside
    //output reg [63:0] bus_address,     // 39 bit for real standard? 64 bit now
    output reg [38:0] bus_address,     // 39 bit for real Sv39 standard?
    output reg [63:0] bus_write_data,
    output reg        bus_write_enable,
    output reg        bus_read_enable,
    output reg [2:0]  bus_ls_type, // lb lh lw ld lbu lhu lwu // sb sh sw sd sbu shu swu 
    //output reg [2:0]  bus_ls_type, // sb sh sw sd sbu shu swu 
      
    output reg [63:0] mtime,    // map to 0x0200_bff8 
    inout wire [63:0] mtimecmp, // map to 0x0200_4000 + 8byte*hartid

    input wire meip_interrupt, // from PLIC
    input wire msip_interrupt, // from Software
      
      
    input  reg        bus_read_done,
    input  reg        bus_write_done,
    input  wire [63:0] bus_read_data   // from outside
);

// -- new --
    reg [63:0] re [0:31]; // General Registers 32s
    reg [63:0] sre [0:9]; // Shadow Registers 10s
    reg mmu_da=0;
    reg mmu_cache_refill=0;
    reg [38:0] saved_user_pc;
    reg [38:0] pa;
    reg [38:0] va;
    reg got_pda=0;
    integer i; 

    // MMU
    function [31:0] get_shadow_ir; // 0-5 mmu 
        input [63:0] spc;
        begin
    	case(spc) /// only x0-x9 could use, x9 is the value passer
	    // mmu_da
            0:  get_shadow_ir = 32'b00000000000000000010000010110111; // lui x1, 0x2
            4:  get_shadow_ir = 32'b00000000010000001000000010010011; // addi x1, x1, 0x4
            8:  get_shadow_ir = 32'b00000101111000000000000100010011; // addi x2, x0, 0x5e
            12: get_shadow_ir = 32'b00000000001000001011000000100011; // sd x2, 0(x1)      print ^
            16: get_shadow_ir = 32'b00110000001000000000000001110011; // mret                         
	    // mmu_pc
    	    20: get_shadow_ir = 32'b00000000000000000010000010110111; // lui x1, 0x2     
    	    24: get_shadow_ir = 32'b00000000010000001000000010010011; // addi x1, x1, 0x4 
    	    28: get_shadow_ir = 32'b00000010101000000000000100010011; // addi x2, x0, 0x2a
    	    32: get_shadow_ir = 32'b00000000001000001011000000100011; // sd x2, 0(x1)      print *
    	    36: get_shadow_ir = 32'b00110000001000000000000001110011; // mret             
	    // I-TLB Handler
            40: get_shadow_ir = 32'hf0000437; // lui x8, 0xf0000
            44: get_shadow_ir = 32'h00943023; // sd x9, 0(x8)
            48: get_shadow_ir = 32'h30200073; // mret
	    // D-TLB Handler
            60: get_shadow_ir = 32'hf0000437; // lui x8, 0xf0000
            64: get_shadow_ir = 32'h00943023; // sd x9, 0(x8)
            68: get_shadow_ir = 32'h30200073; // mret
	    // CacheI Handler
            100: get_shadow_ir = 32'h0004b383; // ld x7, 0(x9) 
            104: get_shadow_ir = 32'hf0001437; // lui x8, 0xf0001
            108: get_shadow_ir = 32'h00743023; // sd x7, 0(x8) 
            112: get_shadow_ir = 32'h30200073; // mret

    	    default: get_shadow_ir = 32'h00000013; // NOP:addi x0, x0, 0
    	endcase
        end
    endfunction
    // vpc
    reg mmu_pc = 0;
    //reg new_vpc = 1;
    reg [38:0] vpc;
    reg is_ppc;

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
    wire signed [63:0] w_imm_j = {{43{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0}; // UJ-type immediate Jal  // read immediate & padding last 0, total 20 + 1 = 21 bits
    wire signed [63:0] w_imm_b = {{51{ir[31]}}, ir[7],  ir[30:25], ir[11:8], 1'b0}; // B-type immediate Beq Bne Blt Bge Bltu Bgeu // read immediate & padding last 0, total 12 + 1 = 13 bits
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
    wire [63:0] rs1 = re[w_rs1];
    wire [63:0] rs2 = re[w_rs2];
    // -- op --
    wire [6:0] op = ir[6:0];
    //wire [11:0] w_f12 = ir[31:20];   // ecall 0, ebreak 1
    //-- csr --
    wire [11:0] w_csr = ir[31:20];   // CSR official address

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
	    default : w_csr_id = 64; 
	endcase
    end

    reg [63:0] Csrs [0:31]; // 32 CSRs for now
    wire [3:0]  satp_mmu  = Csrs[satp][63:60]; // 0:bare, 8:sv39, 9:sv48  satp.MODE!=0, privilegae is not M-mode, mstatus.MPRN is not set or in MPP's mode?
    wire [15:0] satp_asid = Csrs[satp][59:44]; // Address Space ID for TLB
    wire [43:0] satp_ppn  = Csrs[satp][43:0];  // Root Page Table PPN physical page number

    // -- CSR Bits --
   //localparam mstatus    = 0 ;  // 0x300 MRW Machine status reg   // 63_SD|37_MBE|36_SBE|35:34_SXL10|22_TSR|21_TW|20_TVW|17_MPRV|12:11_MPP|8_SPP|7_MPIE|5_SPIE|3_MIE|1_SIE|0_UIE
    //wire mie_MEIE = csr[mie][11];
    //wire mip_MEIP = csr[mie][11];
    //wire mstatus_MIE = Csrs[mstatus][MIE];
    // -- CSR Other Registers -- use BRAM in FPGA then SRAM in ASIC port?
    //reg [63:0] other_csr [0:4096]; // Maximal 12-bit length = 4096 
      
      
    // -- Timer --
    //reg [63:0] mtime;    // map to 0x0200_bff8    
    //reg [63:0] mtimecmp; // map to 0x0200_4000 + 8*hartid
    always @(posedge clk or negedge reset) begin 
	if (!reset) mtime <= 0;
	else mtime <= mtime + 1; end
    wire time_interrupt = (mtime >= mtimecmp);
      
      
    // -- Innerl signal --
    reg bubble;
    reg [1:0] load_step;
    reg [1:0] store_step;


    // -- Atomic & Sync state --
    reg [1:0]  atom_step;
    reg [63:0] atom_tmp_value;
    reg [63:0] reserve_addr;
    reg        reserve_valid;

    // -- TLB -- 8 pages
    reg [26:0] tlb_vpn [0:7]; // vpn number VA[38:12]  Sv39
    reg [43:0] tlb_ppn [0:7]; // ppn number PA[55:12]
    reg tlb_vld [0:7];
    // i map
    wire [26:0] pc_vpn = pc[38:12];
    reg [43:0] pc_ppn;
    // TLB i hit
    reg tlb_i_hit;
    always @(*) begin
	tlb_i_hit = 0;
	pc_ppn = 0;
	if      (tlb_vld[0] && tlb_vpn[0] == pc_vpn) begin tlb_i_hit = 1; pc_ppn = tlb_ppn[0]; end
	else if (tlb_vld[1] && tlb_vpn[1] == pc_vpn) begin tlb_i_hit = 1; pc_ppn = tlb_ppn[1]; end
	else if (tlb_vld[2] && tlb_vpn[2] == pc_vpn) begin tlb_i_hit = 1; pc_ppn = tlb_ppn[2]; end
	else if (tlb_vld[3] && tlb_vpn[3] == pc_vpn) begin tlb_i_hit = 1; pc_ppn = tlb_ppn[3]; end
	else if (tlb_vld[4] && tlb_vpn[4] == pc_vpn) begin tlb_i_hit = 1; pc_ppn = tlb_ppn[4]; end
	else if (tlb_vld[5] && tlb_vpn[5] == pc_vpn) begin tlb_i_hit = 1; pc_ppn = tlb_ppn[5]; end
	else if (tlb_vld[6] && tlb_vpn[6] == pc_vpn) begin tlb_i_hit = 1; pc_ppn = tlb_ppn[6]; end
	else if (tlb_vld[7] && tlb_vpn[7] == pc_vpn) begin tlb_i_hit = 1; pc_ppn = tlb_ppn[7]; end
    end
    // d map
    reg [38:0] ls_va;
    always @(*) begin
        case(op)
	   7'b0000011: ls_va = rs1 + w_imm_i; // load address
	   7'b0100011: ls_va = rs1 + w_imm_s; // store address
	   7'b0101111: ls_va = rs1;           // atomic address
	   default: ls_va = 0;
       endcase
    end
    wire [26:0] data_vpn = ls_va[38:12];
    reg [43:0] data_ppn;
    // TLB d hit
    reg tlb_d_hit;
    always @(*) begin
	 tlb_d_hit = 0;
	 data_ppn = 0;
	 if      (tlb_vld[0] && tlb_vpn[0] == data_vpn) begin tlb_d_hit = 1; data_ppn=tlb_ppn[0]; end
	 else if (tlb_vld[1] && tlb_vpn[1] == data_vpn) begin tlb_d_hit = 1; data_ppn=tlb_ppn[1]; end
	 else if (tlb_vld[2] && tlb_vpn[2] == data_vpn) begin tlb_d_hit = 1; data_ppn=tlb_ppn[2]; end
	 else if (tlb_vld[3] && tlb_vpn[3] == data_vpn) begin tlb_d_hit = 1; data_ppn=tlb_ppn[3]; end
	 else if (tlb_vld[4] && tlb_vpn[4] == data_vpn) begin tlb_d_hit = 1; data_ppn=tlb_ppn[4]; end
	 else if (tlb_vld[5] && tlb_vpn[5] == data_vpn) begin tlb_d_hit = 1; data_ppn=tlb_ppn[5]; end
	 else if (tlb_vld[6] && tlb_vpn[6] == data_vpn) begin tlb_d_hit = 1; data_ppn=tlb_ppn[6]; end
	 else if (tlb_vld[7] && tlb_vpn[7] == data_vpn) begin tlb_d_hit = 1; data_ppn=tlb_ppn[7]; end
     end
     // concat physical address
     wire need_trans = satp_mmu && !mmu_pc && !mmu_da;
     wire [55:0] ppc = need_trans ? {pc_ppn, pc[11:0]} : pc;
     wire [55:0] pda = need_trans ? {data_ppn, ls_va[11:0]} : ls_va;
     // I_Cache
    (* ram_style = "block" *) reg [63:0] I_Cache [0:2047]; // 11 bits address  16KB Cache
    (* ram_style = "block" *) reg [20:0] I_Tag [0:511]; // 9 bits address
     // Read Indices
     wire [10:0] data_index = ppc[13:3]; // 11 bits for 2048 entries
     wire [8:0]  tag_index = ppc[13:5];  // 9 bits for 512 lines(4 entries= 4*8=32 bytes/line)
     wire [17:0] tag_req = ppc[31:14];  // Tag is upper bits
     // Hardware read
     wire [63:0] cache_block = I_Cache[data_index];
     wire [18:0] tag_vld = I_Tag[tag_index]; // [18]valid [17:0]tag
    //  Hit Calculation
     wire cache_hit = tag_vld[18] && (tag_vld[17:0] == tag_req) && (need_trans ? tlb_i_hit : 1);
     wire [31:0] cache_data = ppc[2] ? cache_block[63:32] : cache_block[31:0];

    // TLB Refill
    reg [2:0] tlb_ptr = 0; // 8 entries TLB
    always @(posedge clk or negedge reset) begin
	if (!reset) tlb_ptr <= 0;
	else if (bus_write_enable && bus_address == `Tlb) begin
	    tlb_vpn[tlb_ptr] <= re[9][38:12]; // VA from x9 trapped by mmu_pc/mmu_da
	    tlb_ppn[tlb_ptr] <= {24'b0, re[9][38:12]}; // mimic copy now
	    tlb_vld[tlb_ptr] <= 1;
	    tlb_ptr <= tlb_ptr + 1; end
        else if (bus_write_enable && bus_address == `CacheI) begin
	    I_Cache[re[9][13:3]] <= bus_write_data; // 64 bits use Sd
	    I_Tag[re[9][13:5]] <= {1'b1, re[9][31:14]}; end
    end


    // IF Instruction (Only drive IR)
    always @(posedge clk or negedge reset) begin
        if (!reset) begin 
            heartbeat <= 1'b0; 
            ir <= 32'h00000001; 
        end else begin
            heartbeat <= ~heartbeat; // heartbeat
	    if (mmu_da || mmu_pc) ir <= get_shadow_ir(pc);  // Runing shadow code
            //else ir <= instruction; // 
            else if (cache_hit) ir <= cache_data; // Cache hit
	    else ir <= 32'h00000013; // TLB miss or Cache miss: Nop(stall)
        end
    end

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
	    interrupt_ack <= 0;
	    mmu_da <= 0;
	    got_pda <= 0;
	    for (i=0;i<10;i=i+1) begin sre[i]<= 64'b0; end
	    for (i=0;i<32;i=i+1) begin Csrs[i]<= 64'b0; end
	    Csrs[medeleg] <= 64'hb1af; // delegate to S-mode 1011000110101111 // see VII 3.1.15 mcasue exceptions
	    Csrs[mideleg] <= 64'h0222; // delegate to S-mode 0000001000100010 see VII 3.1.15 mcasue interrupt 1/5/9 SSIP(supervisor software interrupt) STIP(time) SEIP(external)
	    mmu_pc <= 0;
	    is_ppc <= 0; // current using address is physical addr

            atom_step <= 0;
            atom_tmp_value <= 0;
            reserve_addr <= 0;
            reserve_valid <= 0;





        end else begin
	    // Default PC+4    (1.Could be overide 2.Take effect next cycle) 
            pc <= pc + 4;
	    interrupt_ack <= 0;
	    bus_read_enable <= 0;
	    bus_write_enable <= 0; 
            //Csrs[mip][MTIP] <= time_interrupt; // MTIP linux will see then jump to its handler
            //Csrs[mip][MEIP] <= meip_interrupt; // MEIP
            //Csrs[mip][MSIP] <= msip_interrupt; // MSIP

            // Bubble
	    if (bubble) begin bubble <= 1'b0; // Flush this cycle & Clear bubble signal for the next cycle

	    //  mmu_pc  I-TLB miss Trap
	    end else if (satp_mmu && !mmu_pc && !mmu_da && !mmu_cache_refill && !tlb_i_hit) begin //OPEN 
		mmu_pc <= 1; // MMU_PC ON 
	        //pc <= 20; // I-TLB refill Handler
	        pc <= 40; // I-TLB refill Handler
	 	bubble <= 1'b1; // bubble 
	        saved_user_pc <= pc-4; // save pc 
		for (i=0;i<=9;i=i+1) begin sre[i]<= re[i]; end // save re
		re[9]<= pc - 4; // save vpc to x1
		Csrs[mstatus][MPIE] <= Csrs[mstatus][MIE]; // disable interrupt during shadow mmu walking
		Csrs[mstatus][MIE] <= 0;

            //  mmu_da  D-TLB miss Trap
	    end else if (satp_mmu && !mmu_pc && !mmu_da && !mmu_cache_refill
		&& (op == 7'b0000011 || op == 7'b0100011 || op == 7'b0101111)  // load/store/atom
	        && !(op == 7'b0101111 && w_func5 == 5'b00011 && (!reserve_valid || reserve_addr != pda)) // exclude failed sc.w/sc.d to run into mmu
		&& !tlb_d_hit) begin  
		mmu_da <= 1; // MMU_DA ON
	        saved_user_pc <= pc-4; // save pc l/s
		//pc <= 0; // D-TLB refill Handler
		pc <= 60; // D-TLB refill Handler
	 	bubble <= 1'b1; // bubble
		for (i=0;i<=9;i=i+1) begin sre[i]<= re[i]; end // save re
		re[9] <= ls_va; //save va to x1
		Csrs[mstatus][MPIE] <= Csrs[mstatus][MIE]; // disable interrupt during shadow mmu walking
		Csrs[mstatus][MIE] <= 0;
		
            //  mmu_cache I-Cache Miss Trap
	    end else if (!mmu_pc && !mmu_da && !mmu_cache_refill 
		&& (tlb_i_hit || !satp_mmu) // Allow if hit or bare mode
	        && !cache_hit) begin
		mmu_cache_refill <= 1;
		re[9] <= ppc;
		//pc <= 60; // jump to Cache_Refill Handler
		pc <= 100; // jump to Cache_Refill Handler
		bubble <= 1;
	        saved_user_pc <= pc-4; // save pc 
		for (i=0;i<=9;i=i+1) begin sre[i]<= re[i]; end // save re
		Csrs[mstatus][MPIE] <= Csrs[mstatus][MIE]; // disable interrupt during shadow mmu walking
		Csrs[mstatus][MIE] <= 0;

            // uni-return from shadow (mret hiject)
	    end else if ((mmu_pc || mmu_da || mmu_cache_refill) && ir == 32'b00110000001000000000000001110011) begin // hiject mret 
		pc <= saved_user_pc; // recover from shadow when see Mret
		bubble <= 1; // bubble
		for (i=0;i<=9;i=i+1) begin re[i]<= sre[i]; end // recover usr re
		mmu_pc <= 0;  // Off
		mmu_da <= 0; // MMU_DA OFF
		mmu_cache_refill <= 0; // OFF
		Csrs[mstatus][MIE] <= Csrs[mstatus][MPIE]; // set back interrupt status



        //    // Interrupt
	//    //if (interrupt_vector == 1 && mstatus_MIE == 1) begin //mstatus[3] MIE
	//    end else if (interrupt_vector == 1 && Csrs[mstatus][MIE]==1) begin //mstatus[3] MIE
	//        Csrs[mepc] <= pc; // save pc

	//	Csrs[mcause] <= 64'h800000000000000B; // MSB 1 for interrupts 0 for exceptions, Cause 11 for Machine External Interrupt
	//	Csrs[mstatus][MPIE] <= Csrs[mstatus][MIE];
	//	Csrs[mstatus][MIE] <= 0;

	//	pc <= Csrs[mtvec]; // jump to mtvec addrss (default 0, need C or Assembly code of handler)
	//	bubble <= 1'b1; // bubble wrong fetched instruciton by IF
	//        Csrs[mstatus][MIE] <= 0;
	//	interrupt_ack <= 1; // reply to outside

            // Interrupt PLIC full (Platform-Level-Interrupt-Control)  MMIO
	    //if (interrupt_vector == 1 && mstatus_MIE == 1) begin //mstatus[3] MIE      // sstatus[SIE]?
	    //end else if ((Csrs[mip][MTIP] || Csrs[mip][MEIP] || Csrs[mip][MSIP]) && Csrs[mstatus][MIE]==1) begin //mstatus[3] MIE
	    //end else if ((time_interrupt || meip_interrupt || msip_interrupt) && Csrs[mstatus][MIE]==1) begin //mstatus[3] MIE
	    end else if ((meip_interrupt || msip_interrupt) && Csrs[mstatus][MIE]==1) begin //mstatus[3] MIE
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
		//pc <= 0;
                //pc <= (Csrs[mtvec][BASE+61:BASE] << 2); 
		bubble <= 1'b1; // bubble wrong fetched instruciton by IF

		reserve_valid <= 0;// Interrupt clear lr.w/lr.d
		is_ppc <= 0; // Interrupt jump to new va(if mmu enabled)
		//interrupt_ack <= 1; // reply to outside
		//
		//
		// 0x0C00_0000 base  
		// 0x0C00_000? priority (base + 4 * id)
		// 0x0C00_2000 pending bits
		// 0x0C20_0000 enable bits
		// 0x0C20_2000 threshold
		// 0x0C20_2004 claim/complete
		// id: UART1 KEYBOARD SPI GPIO...

            // Upper are hijects of executing ir for handler special state
	    // IR
	    end else begin 
	        //bus_read_enable <= 0;
	        //bus_write_enable <= 0; 
	        //bus_write_data <= 0;
	        //bus_address <= `Ram_base;
	        //is_ppc <= 0;
		if (is_ppc && pc[11:0]==12'hFFC) is_ppc <= 0; //page_cross 4096 Bytes
                casez(ir) // Pseudo: li j jr ret call // I: addi sb sh sw sd lb lw ld lbu lhu lwu lui jal jalr auipc beq slt mret 
	            // U-type
	            32'b???????_?????_?????_???_?????_0110111: re[w_rd] <= w_imm_u; // Lui
	            32'b???????_?????_?????_???_?????_0010111: re[w_rd] <= w_imm_u + (pc - 4); // Auipc

		//    32'b???????_?????_?????_000_?????_0000011: begin  // Lb  3 cycles but wait to 5
		//	if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; //end
		//	                    if (got_pda) bus_address <= pa; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//        if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[7:0]); load_step <= 0; //end end //bus_read_enable <= 0; end end // bus ok and execute
		//	                    if (got_pda) got_pda <= 0; end end
		//    32'b???????_?????_?????_100_?????_0000011: begin  // Lbu  3 cycles
		//        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; //end
		//	                    if (got_pda) bus_address <= pa; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[7:0]); load_step <= 0; //end end //bus_read_enable <= 0; end end // bus ok and execute
		//	                    if (got_pda) got_pda <= 0; end end
		//    32'b???????_?????_?????_001_?????_0000011: begin  // Lh 3 cycles
		//        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; //end
		//	                    if (got_pda) bus_address <= pa; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[15:0]); load_step <= 0; //end end //bus_read_enable <= 0; end end // bus ok and execute
		//	                    if (got_pda) got_pda <= 0; end end
		//    32'b???????_?????_?????_101_?????_0000011: begin   // Lhu 3 cycles
		//        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; //end
		//	                    if (got_pda) bus_address <= pa; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[15:0]); load_step <= 0; //end end //bus_read_enable <= 0; end end // bus ok and execute
		//	                    if (got_pda) got_pda <= 0; end end
		//    32'b???????_?????_?????_010_?????_0000011: begin  // Lw_mmu 3 cycles
		//        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; //end
		//	                    if (got_pda) bus_address <= pa; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0; //end end //bus_read_enable <= 0; end end // bus ok and execute
		//	                    if (got_pda) got_pda <= 0; end end
		//    32'b???????_?????_?????_110_?????_0000011: begin  // Lwu_mmu 3 cycles
		//        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; //end
		//	                    if (got_pda) bus_address <= pa; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[31:0]); load_step <= 0; //end end //bus_read_enable <= 0; end end // bus ok and execute
		//	                    if (got_pda) got_pda <= 0; end end
		//    32'b???????_?????_?????_011_?????_0000011: begin   // Ld 5 cycles
		//        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; //end
		//	                    if (got_pda) bus_address <= pa; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0; //end end //bus_read_enable <= 0; end end // bus ok and execute
		//	                    if (got_pda) got_pda <= 0; end end
                    // Load after TLB
		    32'b???????_?????_?????_000_?????_0000011: begin  // Lb  3 cycles but wait to 5
			if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		        if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[7:0]); load_step <= 0; end end
		    32'b???????_?????_?????_100_?????_0000011: begin  // Lbu  3 cycles
		        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[7:0]); load_step <= 0; end end 
		    32'b???????_?????_?????_001_?????_0000011: begin  // Lh 3 cycles
		        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[15:0]); load_step <= 0; end end
		    32'b???????_?????_?????_101_?????_0000011: begin   // Lhu 3 cycles
		        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[15:0]); load_step <= 0; end end
		    32'b???????_?????_?????_010_?????_0000011: begin  // Lw_mmu 3 cycles
		        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0; end end
		    32'b???????_?????_?????_110_?????_0000011: begin  // Lwu_mmu 3 cycles
		        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[31:0]); load_step <= 0; end end
		    32'b???????_?????_?????_011_?????_0000011: begin   // Ld 5 cycles
		        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0; end end
                    // Store
	            //32'b???????_?????_?????_000_?????_0100011: begin bus_address <= rs1 + w_imm_s;bus_write_data<=rs2[7:0]; bus_write_enable<=1;bus_ls_type<=w_func3;end//Sb bus1 cycles
	            //32'b???????_?????_?????_001_?????_0100011: begin bus_address <= rs1 + w_imm_s;bus_write_data<=rs2[15:0];bus_write_enable<=1;bus_ls_type<=w_func3;end//Sh bus1
	            //32'b???????_?????_?????_010_?????_0100011: begin bus_address <= rs1 + w_imm_s;bus_write_data<=rs2[31:0];bus_write_enable<=1;bus_ls_type<=w_func3;end//Sw bus1
	            //32'b???????_?????_?????_011_?????_0100011: begin bus_address <= rs1 + w_imm_s;bus_write_data<=rs2;bus_write_enable<=1;pc<=pc;bubble<=1;bus_ls_type<=w_func3;end//Sdbus2
	            //32'b???????_?????_?????_000_?????_0100011: begin 
		    //    if (store_step == 0) begin bus_address <= rs1 + w_imm_s; bus_write_data<=rs2[7:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //end
		    //                        if (got_pda) bus_address <= pa; end
		    //    if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		    //    if (store_step == 1 && bus_write_done == 1) begin store_step <= 0;
		    //                        if (got_pda) got_pda <= 0; end 
		    //    end //Sb bus1 cycles
	            //32'b???????_?????_?????_001_?????_0100011: begin
		    //    if (store_step == 0) begin bus_address <= rs1 + w_imm_s; bus_write_data<=rs2[15:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //end
		    //                        if (got_pda) bus_address <= pa; end
		    //    if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		    //    if (store_step == 1 && bus_write_done == 1) begin store_step <= 0;
		    //                        if (got_pda) got_pda <= 0; end 
		    //    end //Sh
	            //32'b???????_?????_?????_010_?????_0100011: begin
		    //    if (store_step == 0) begin bus_address <= rs1 + w_imm_s; bus_write_data<=rs2[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //end
		    //                        if (got_pda) bus_address <= pa; end
		    //    if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		    //    if (store_step == 1 && bus_write_done == 1) begin store_step <= 0;
		    //                        if (got_pda) got_pda <= 0; end 
		    //    end //Sw
	            //32'b???????_?????_?????_011_?????_0100011: begin 
		    //    if (store_step == 0) begin bus_address <= rs1 + w_imm_s; bus_write_data<=rs2;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //end
		    //                        if (got_pda) bus_address <= pa; end
		    //    if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		    //    if (store_step == 1 && bus_write_done == 1) begin store_step <= 0;
		    //                        if (got_pda) got_pda <= 0; end 
		    //    end //Sd
		    // Store after TLB
	            32'b???????_?????_?????_000_?????_0100011: begin 
		        if (store_step == 0) begin bus_address <= pda; bus_write_data<=rs2[7:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
			if (store_step == 1 && bus_write_done == 1) store_step <= 0; end // Sb
	            32'b???????_?????_?????_001_?????_0100011: begin
		        if (store_step == 0) begin bus_address <= pda; bus_write_data<=rs2[15:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
			if (store_step == 1 && bus_write_done == 1) store_step <= 0; end //Sh
	            32'b???????_?????_?????_010_?????_0100011: begin
		        if (store_step == 0) begin bus_address <= pda; bus_write_data<=rs2[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
			if (store_step == 1 && bus_write_done == 1) store_step <= 0; end //Sw
	            32'b???????_?????_?????_011_?????_0100011: begin 
		        if (store_step == 0) begin bus_address <= pda; bus_write_data<=rs2;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
			if (store_step == 1 && bus_write_done == 1) store_step <= 0; end //Sd
                    // Math-I
	            32'b???????_?????_?????_000_?????_0010011: re[w_rd] <= rs1 + w_imm_i;  // Addi
	            32'b???????_?????_?????_100_?????_0010011: re[w_rd] <= rs1 ^ w_imm_i ; // Xori
	            32'b???????_?????_?????_111_?????_0010011: re[w_rd] <= rs1 & w_imm_i ; // Andi
	            32'b???????_?????_?????_110_?????_0010011: re[w_rd] <= rs1 | w_imm_i ; // Ori
	            32'b???????_?????_?????_001_?????_0010011: re[w_rd] <= rs1 << w_shamt; // Slli
	            32'b000000?_?????_?????_101_?????_0010011: re[w_rd] <= rs1 >> w_shamt; // Srli // func7->6 // rv64 shame take w_f7[0]
	            32'b010000?_?????_?????_101_?????_0010011: re[w_rd] <= $signed(rs1) >>> w_shamt; // Srai
	            32'b???????_?????_?????_010_?????_0010011: re[w_rd] <= $signed(rs1) < w_imm_i ? 1:0; // Slti
	            32'b???????_?????_?????_011_?????_0010011: re[w_rd] <= (rs1 < w_imm_i) ?  1:0; // Sltiu
                    // Math-I (Word)
	            32'b???????_?????_?????_000_?????_0011011: re[w_rd] <= $signed(rs1[31:0] + w_imm_i[31:0]); // Addiw
	            32'b???????_?????_?????_001_?????_0011011: re[w_rd] <= $signed(rs1[31:0] << w_shamt[4:0]); // Slliw
	            32'b0000000_?????_?????_101_?????_0011011: re[w_rd] <= $signed(rs1[31:0] >> w_shamt[4:0]); // Srliw
	            32'b0100000_?????_?????_101_?????_0011011: re[w_rd] <= $signed(rs1[31:0]) >>> w_shamt[4:0]; // Sraiw
                    //// Math-R
	            32'b0000000_?????_?????_000_?????_0110011: re[w_rd] <= rs1 + rs2;  // Add
	            32'b0100000_?????_?????_000_?????_0110011: re[w_rd] <= rs1 - rs2;  // Sub;
	            32'b???????_?????_?????_100_?????_0110011: re[w_rd] <= rs1 ^ rs2; // Xor
	            32'b???????_?????_?????_111_?????_0110011: re[w_rd] <= rs1 & rs2; // And
	            32'b???????_?????_?????_110_?????_0110011: re[w_rd] <= rs1 | rs2; // Or
	            32'b???????_?????_?????_001_?????_0110011: re[w_rd] <= rs1 << rs2[5:0]; // Sll 6 length
                    32'b0000000_?????_?????_101_?????_0110011: re[w_rd] <= rs1 >> rs2[5:0]; // Srl 6 length
	            32'b0100000_?????_?????_101_?????_0110011: re[w_rd] <= $signed(rs1) >>> rs2[5:0]; // Sra 6 length
	            32'b???????_?????_?????_010_?????_0110011: re[w_rd] <= ($signed(rs1) < $signed(rs2)) ? 1: 0;  // Slt
	            32'b???????_?????_?????_011_?????_0110011: re[w_rd] <= rs1 < rs2 ? 1:0; // Sltu
                    //// Math-R (Word)
	            32'b0000000_?????_?????_000_?????_0111011: re[w_rd] <= $signed(rs1[31:0] + rs2[31:0]);  // Addw
	            32'b0100000_?????_?????_000_?????_0111011: re[w_rd] <= $signed(rs1[31:0] - rs2[31:0]);  // Subw
	            32'b???????_?????_?????_001_?????_0111011: re[w_rd] <= $signed(rs1[31:0] << rs2[4:0]);  // Sllw 5 length
                    32'b0000000_?????_?????_101_?????_0111011: re[w_rd] <= $signed(rs1[31:0] >> rs2[4:0]);  // Srlw 5 length
	            32'b0100000_?????_?????_101_?????_0111011: re[w_rd] <= $signed(rs1[31:0]) >>> rs2[4:0]; // Sraw 5 length
                    //// Jump
	            //32'b???????_?????_?????_???_?????_1101111: begin pc <= pc - 4 + w_imm_j; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1'b1; 
		    //                                           if (is_ppc && pc - 4 != pc - 4 + w_imm_j) is_ppc <= 0; end // Jal
	            //32'b???????_?????_?????_???_?????_1100111: begin pc <= (rs1 + w_imm_i) & 64'hFFFFFFFFFFFFFFFE; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1; 
		    //                                           if (is_ppc && pc - 4 != rs1 + w_imm_j) is_ppc <= 0; end // Jalr
                    //// Branch 
		    //32'b???????_?????_?????_000_?????_1100011: begin if (rs1 == rs2) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; 
		    //                                           if (is_ppc && pc - 4 != pc - 4 + w_imm_b) is_ppc <= 0; end end // Beq
		    //32'b???????_?????_?????_001_?????_1100011: begin if (rs1 != rs2) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; 
		    //                                           if (is_ppc && pc - 4 != pc - 4 + w_imm_b) is_ppc <= 0; end end // Bne
		    //32'b???????_?????_?????_100_?????_1100011: begin if ($signed(rs1) < $signed(rs2)) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; 
		    //                                           if (is_ppc && pc - 4 != pc - 4 + w_imm_b) is_ppc <= 0; end end // Blt
		    //32'b???????_?????_?????_101_?????_1100011: begin if ($signed(rs1) >= $signed(rs2)) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; 
		    //                                           if (is_ppc && pc - 4 != pc - 4 + w_imm_b) is_ppc <= 0; end end // Bge
		    //32'b???????_?????_?????_110_?????_1100011: begin if (rs1 < rs2) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; 
		    //                                           if (is_ppc && pc - 4 != pc - 4 + w_imm_b) is_ppc <= 0; end end // Bltu
		    //32'b???????_?????_?????_111_?????_1100011: begin if (rs1 >= rs2) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; 
		    //                                           if (is_ppc && pc - 4 != pc - 4 + w_imm_b) is_ppc <= 0; end end // Bgeu
                    // Jump
	            32'b???????_?????_?????_???_?????_1101111: begin pc <= pc - 4 + w_imm_j; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1'b1; end // Jal
	            32'b???????_?????_?????_???_?????_1100111: begin pc <= (re[w_rs1] + w_imm_i) & 64'hFFFFFFFFFFFFFFFE; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1; end // Jalr
                    // Branch 
		    32'b???????_?????_?????_000_?????_1100011: begin if (re[w_rs1] == re[w_rs2]) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Beq
		    32'b???????_?????_?????_001_?????_1100011: begin if (re[w_rs1] != re[w_rs2]) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bne
		    32'b???????_?????_?????_100_?????_1100011: begin if ($signed(re[w_rs1]) < $signed(re[w_rs2])) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Blt
		    32'b???????_?????_?????_101_?????_1100011: begin if ($signed(re[w_rs1]) >= $signed(re[w_rs2])) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bge
		    32'b???????_?????_?????_110_?????_1100011: begin if (re[w_rs1] < re[w_rs2]) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bltu
		    32'b???????_?????_?????_111_?????_1100011: begin if (re[w_rs1] >= re[w_rs2]) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bgeu
                    // M extension
		    //32'b0000001_?????_?????_000_?????_0110011: re[w_rd] <= $signed(rs1) * $signed(rs2);  // Mul
                    //32'b0000001_?????_?????_001_?????_0110011: re[w_rd] <= ($signed(rs1) * $signed(rs2))>>>64;//[127:64];  // Mulh 
                    ////32'b0000001_?????_?????_100_?????_0110011: re[w_rd] <= (rs2==0||(rs1==64'h8000_0000_0000_0000 && rs2 == -1)) ? -1 : $signed(rs1) / $signed(rs2);  // Div
                    //32'b0000001_?????_?????_101_?????_0110011: re[w_rd] <= (rs2==0) ? -1 : $unsigned(rs1) / $unsigned(rs2);  // Divu

		    // System-CSR 
	            //32'b???????_?????_?????_001_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); csr_write(w_csr,  rs1); end // Csrrw
	            //32'b???????_?????_?????_010_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_rs1 != 0 )  csr_write(w_csr, csr_read(w_csr) |  rs1); end // Csrrs
	            //32'b???????_?????_?????_011_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_rs1 != 0 )  csr_write(w_csr, csr_read(w_csr) & ~rs1); end // Csrrc
	            //32'b???????_?????_?????_101_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); csr_write(w_csr,  w_imm_z); end // Csrrwi
	            //32'b???????_?????_?????_110_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_imm_z != 0) csr_write(w_csr, csr_read(w_csr) |  w_imm_z); end // csrrsi
	            //32'b???????_?????_?????_111_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_imm_z != 0) csr_write(w_csr, csr_read(w_csr) & ~w_imm_z); end // Csrrci
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
		    32'b?????????????????_001_?????_0001111: begin bubble <= 1; end
		     // RV64IMAFD(G)C  RVA23U64
		     // M mul mulh mulhsu mulhu div divu rem remu mulw divw divuw remuw
		     // A lr.w sc.w lr.d sc.d
		     // -- ATOMIC instructions (A-extension) opcode: 0101111
		    //// lr.w
		    //32'b00010_??_?????_?????_010_?????_0101111: begin  // Lr.w_mmu 3 cycles
		    //    if (load_step == 0) begin bus_address <= rs1; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; //end
		    //                              reserve_addr <= rs1; reserve_valid <= 1;
		    //                        if (got_pda) bus_address <= pa; end
		    //    if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		    //    if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0; //end end //bus_read_enable <= 0; end end // bus ok and execute
		    //                        if (got_pda) got_pda <= 0; end end
		    //// sc.w 
	            //32'b00011_??_?????_?????_010_?????_0101111: begin
		    //    if (store_step == 0) begin 
		    //        if (!reserve_valid || reserve_addr != rs1) begin re[w_rd] <= 1; reserve_valid <= 0; if (got_pda) got_pda <= 0; end // finish 1 cycle without bubble & clear reserve
		    //        else begin bus_address <= rs1; bus_write_data<=rs2[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; 
		    //                        if (got_pda) bus_address <= pa;
		    //                        reserve_valid <= 0; end // consumed
		    //    end 
		    //    if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		    //    if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; re[w_rd] <= 0; // sc.w successed return 0 in rd
		    //                        if (got_pda) got_pda <= 0; end 
		    //end 
		    // Atomic after TLB
		    // lr.w
		    32'b00010_??_?????_?????_010_?????_0101111: begin  // Lr.w_mmu 3 cycles
		        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; reserve_addr <= pda; reserve_valid <= 1; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0; end end
		    // sc.w 
	            32'b00011_??_?????_?????_010_?????_0101111: begin
		        if (store_step == 0) begin 
			    if (!reserve_valid || reserve_addr != pda) begin re[w_rd] <= 1; reserve_valid <= 0; end // finish failed 1 cycle without bubble & clear reserve
			    else begin bus_address <= pda; bus_write_data<=rs2[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; reserve_valid <= 0; end end // consumed
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
			if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; re[w_rd] <= 0; end end // sc.w successed return 0 in rd
		     // amoswap amoadd amoxor amoand amoor
		     // amomin amomax amominu amomaxu
		     // -- ATOMIC end --
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
	re[0]<=0; 
	sre[0]<=0;
    end

endmodule

// Linux needs:
// Privilege RV
// mret/sret/ecall/ebreak
//PLIC
//CLINT timer
//UART 16550
//Map DRAM 0x80000000/0x40000000
//OpenSBI at 0x80000000 ?
//lr.w|d/sc.w|d Atom amo...
//sfence.vma TLE flush could be NOP
//sv39 mmu ! Accessed/Direct bit in PTE(Page Table Entry)
//exception handler: page faults/illegal ir/misaligned ls/timer interrutp/external interrupt/breakpoint/ecallUSM
//SBI interface: OpenSBI run first
//fence fence.i
//cache !  // SDRAM to cache(BRAM)
// Device Tree
  
  
//interrupt
//N+0 see interrupt and set isr pc
//N+1 bubble branch take over
//Lb
//N+2 execute load:step_0 setting read bubble1 load_step1
//N+3 bubble branch take over (BUT bus read data into bus_read_data)
//N+4 execute load:step_1 save bus_read_data into re
//Sb
//N+5 save re to bus_write_data
//mret
//N+6 mret (BUT URAT get data for print).   //
// -- 
//in cycle N0, IF fetching sb, EXE ir is lb, bubble is setting 1, pc is re-setting to pc, load_step is setting to 1;
//in N1, IF fetching lb, Bubble flushed ir sb, bubble <=0, Default pc is setting to lb+4(sb);
//in N2, IF fetching sb, EXE ir is lb, load_step is 1, bus_read_data is saving to re, load_step is setting to 0;
//in N3, IF fethcing mret, EXE ir is sb, re is saving to bus_write_data, bus_write_enable is setting to 1;
  


