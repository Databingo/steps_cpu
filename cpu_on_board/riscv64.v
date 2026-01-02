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
// -- new --
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

    // -- TLB -- 8 pages
    (* ram_style = "logic" *) reg [26:0] tlb_vpn [0:7]; // vpn number VA[38:12]  Sv39
    (* ram_style = "logic" *) reg [43:0] tlb_ppn [0:7]; // ppn number PA[55:12]
    (* ram_style = "logic" *) reg tlb_vld [0:7];

    // tlb i hit
    wire [26:0] pc_vpn = pc[38:12];
    reg [43:0] pc_ppn;
    reg tlb_i_hit;

    wire [7:0] tlb_i_match;
    assign tlb_i_match[0] = tlb_vld[0] && (tlb_vpn[0] == pc_vpn);
    assign tlb_i_match[1] = tlb_vld[1] && (tlb_vpn[1] == pc_vpn);
    assign tlb_i_match[2] = tlb_vld[2] && (tlb_vpn[2] == pc_vpn);
    assign tlb_i_match[3] = tlb_vld[3] && (tlb_vpn[3] == pc_vpn);
    assign tlb_i_match[4] = tlb_vld[4] && (tlb_vpn[4] == pc_vpn);
    assign tlb_i_match[5] = tlb_vld[5] && (tlb_vpn[5] == pc_vpn);
    assign tlb_i_match[6] = tlb_vld[6] && (tlb_vpn[6] == pc_vpn);
    assign tlb_i_match[7] = tlb_vld[7] && (tlb_vpn[7] == pc_vpn);
    // pc_ppn hit
    always @(*) begin
        tlb_i_hit = |tlb_i_match;
        pc_ppn =   ({44{tlb_i_match[0]}} & tlb_ppn[0]) |
                   ({44{tlb_i_match[1]}} & tlb_ppn[1]) |
                   ({44{tlb_i_match[2]}} & tlb_ppn[2]) |
                   ({44{tlb_i_match[3]}} & tlb_ppn[3]) |
                   ({44{tlb_i_match[4]}} & tlb_ppn[4]) |
                   ({44{tlb_i_match[5]}} & tlb_ppn[5]) |
                   ({44{tlb_i_match[6]}} & tlb_ppn[6]) |
                   ({44{tlb_i_match[7]}} & tlb_ppn[7]) ; end
    // --------
    // tlb d hit
    wire [63:0] ls_va_offset = (op == 7'b0000011) ? w_imm_i : (op == 7'b0100011) ?  w_imm_s : 64'h0; // load/store/atom
    wire [63:0] ls_va = rs1 + ls_va_offset;
    wire [63:0] pda;
    reg [43:0] data_ppn;
    reg tlb_d_hit;

    wire [7:0] tlb_d_match;
    assign tlb_d_match[0] = tlb_vld[0] && (tlb_vpn[0] == ls_va[38:12]);
    assign tlb_d_match[1] = tlb_vld[1] && (tlb_vpn[1] == ls_va[38:12]);
    assign tlb_d_match[2] = tlb_vld[2] && (tlb_vpn[2] == ls_va[38:12]);
    assign tlb_d_match[3] = tlb_vld[3] && (tlb_vpn[3] == ls_va[38:12]);
    assign tlb_d_match[4] = tlb_vld[4] && (tlb_vpn[4] == ls_va[38:12]);
    assign tlb_d_match[5] = tlb_vld[5] && (tlb_vpn[5] == ls_va[38:12]);
    assign tlb_d_match[6] = tlb_vld[6] && (tlb_vpn[6] == ls_va[38:12]);
    assign tlb_d_match[7] = tlb_vld[7] && (tlb_vpn[7] == ls_va[38:12]);
    // data_ppn hit
    always @(*) begin
        tlb_d_hit = |tlb_d_match;
        data_ppn = ({44{tlb_d_match[0]}} & tlb_ppn[0]) |
                   ({44{tlb_d_match[1]}} & tlb_ppn[1]) |
                   ({44{tlb_d_match[2]}} & tlb_ppn[2]) |
                   ({44{tlb_d_match[3]}} & tlb_ppn[3]) |
                   ({44{tlb_d_match[4]}} & tlb_ppn[4]) |
                   ({44{tlb_d_match[5]}} & tlb_ppn[5]) |
                   ({44{tlb_d_match[6]}} & tlb_ppn[6]) |
                   ({44{tlb_d_match[7]}} & tlb_ppn[7]) ;
    end
    // concat physical address
    wire need_trans = satp_mmu   && !mmu_pc && !mmu_da && !mmu_cache_refill;
    assign ppc = need_trans ? {8'h0, pc_ppn, pc[11:0]} : pc;
    assign pda = need_trans ? {8'h0, data_ppn, ls_va[11:0]} : ls_va;
        
    // TLB Refill
    reg [2:0] tlb_ptr = 0; // 8 entries TLB
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
	// read
	cache_line <= {Cache_L_High[ppc[12:4]], Cache_L_Low[ppc[12:4]]}; 
	cache_tag <= Cache_T[ppc[12:4]]; 
	ppc_pre <= ppc;
	// write
        if (mmu_cache_refill && bus_write_enable && bus_address == `CacheI_L) begin // for the last fill: sd ppa, Tlb
	    Cache_L_Low[ask_i_data[12:4]] <= bus_write_data; 
	end
        if (mmu_cache_refill && bus_write_enable && bus_address == `CacheI_H) begin // for the last fill: sd ppa, Tlb
	    Cache_L_High[ask_i_data[12:4]] <= bus_write_data; 
	    Cache_T[ask_i_data[12:4]] <= {1'b1, ask_i_data[63:13]}; 
	end
    end
    wire cache_i_hit = cache_tag[51] && (ppc_pre[63:13] == cache_tag[50:0]);
    wire [31:0] cache_i = cache_line[ppc_pre[3:2]*32 +: 32];

    //assign ir = cache_i;
    // -----

    assign ir = instruction;

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
		for (i=0;i<=9;i=i+1) begin sre[i]<= re[i]; end // save re
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
	    //  mmu_cache_i at EXE stage
//	    end else if (satp_mmu && !mmu_pc && !mmu_da && !mmu_cache_refill && tlb_i_hit && !cache_i_hit) begin //OPEN 
//       		mmu_cache_refill <= 1; // 
//       	        pc <= 72; //
//       	 	bubble <= 1'b1; // bubble 
//	        saved_user_pc <= pc - 4; // !!! save pc (EXE was flushed so record-redo it, previous pc)
//	        if (bubble) saved_user_pc <= pc -4  ; // ??!!! save pc (j/b EXE was flushed currectly)
//		for (i=0;i<10;i=i+1) begin sre[i]<= re[i]; end // save re
//		re[9] <= {ppc_pre[63:4], 4'b0};// save missed ppc_pre cache_line address for handler
//		ask_i_data <= {ppc_pre[63:4], 4'b0};// save missed ppc_pre cache_line address for hardware
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
	            32'b???????_?????_?????_011_?????_0010011: re[w_rd] <= ($unsigned(rs1) < w_imm_i) ?  1:0; // Sltiu
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
	            32'b???????_?????_?????_011_?????_0110011: re[w_rd] <= $unsigned(rs1) < $unsigned(rs2) ? 1:0; // Sltu
                    //// Math-R (Word)
	            32'b0000000_?????_?????_000_?????_0111011: re[w_rd] <= $signed(rs1[31:0] + rs2[31:0]);  // Addw
	            32'b0100000_?????_?????_000_?????_0111011: re[w_rd] <= $signed(rs1[31:0] - rs2[31:0]);  // Subw
	            32'b???????_?????_?????_001_?????_0111011: re[w_rd] <= $signed(rs1[31:0] << rs2[4:0]);  // Sllw 5 length
                    32'b0000000_?????_?????_101_?????_0111011: re[w_rd] <= $signed(rs1[31:0] >> rs2[4:0]);  // Srlw 5 length
	            32'b0100000_?????_?????_101_?????_0111011: re[w_rd] <= $signed(rs1[31:0]) >>> rs2[4:0]; // Sraw 5 length
                    // Jump
	            32'b???????_?????_?????_???_?????_1101111: begin pc <= pc - 4 + w_imm_j; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1'b1; end // Jal
	            32'b???????_?????_?????_???_?????_1100111: begin pc <= (re[w_rs1] + w_imm_i) & 64'hFFFFFFFFFFFFFFFE; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1; end // Jalr
                    // Branch 
		    32'b???????_?????_?????_000_?????_1100011: begin if (re[w_rs1] == re[w_rs2]) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Beq
		    32'b???????_?????_?????_001_?????_1100011: begin if (re[w_rs1] != re[w_rs2]) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bne
		    32'b???????_?????_?????_100_?????_1100011: begin if ($signed(re[w_rs1]) < $signed(re[w_rs2])) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Blt
		    32'b???????_?????_?????_101_?????_1100011: begin if ($signed(re[w_rs1]) >= $signed(re[w_rs2])) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bge
		    32'b???????_?????_?????_110_?????_1100011: begin if ($unsigned(re[w_rs1]) < $unsigned(re[w_rs2])) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bltu
		    32'b???????_?????_?????_111_?????_1100011: begin if ($unsigned(re[w_rs1]) >= $unsigned(re[w_rs2])) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bgeu
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
		//    // Wfi
		//    32'b00010000010100000000000001110011: begin end
		//    // Fence
		//    32'b?????????????????_000_?????_0001111: begin end
		//    // Fence.i
		//    32'b?????????????????_001_?????_0001111: begin end
		//    // Sfence.vma
		//    32'b0001001??????????_000_?????_1110011: begin end
		//    // RV64IMAFD(G)C  RVA23U64
		//    // Atomic after TLB // -- ATOMIC instructions (A-extension) opcode: 0101111
		//    // lr.w
		//    32'b00010_??_?????_?????_010_?????_0101111: begin  // Lr.w_mmu 3 cycles
		//        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; reserve_addr <= pda; reserve_valid <= 1; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0; end end
		//    // sc.w 
	        //    32'b00011_??_?????_?????_010_?????_0101111: begin
		//        if (store_step == 0) begin 
		//	    if (!reserve_valid || reserve_addr != pda) begin re[w_rd] <= 1; reserve_valid <= 0; end // finish failed 1 in rd cycle without bubble & clear reserve
		//	    else begin bus_address <= pda; bus_write_data<=rs2[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3;reserve_valid<=0;end end//consumed
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; re[w_rd] <= 0; end end // sc.w successed return 0 in rd
		//    // amoswap.w
	        //    32'b00001_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=rs2[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amoadd.w
	        //    32'b00000_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=$signed(bus_read_data[31:0])+$signed(rs2[31:0]);bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amoxor.w
	        //    32'b00100_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data[31:0]^rs2[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amoand.w
	        //    32'b01100_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data[31:0]&rs2[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amoor.w
	        //    32'b01000_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data[31:0]|rs2[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amomin.w
	        //    32'b10000_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //start store
		//	    if ($signed(rs2[31:0]) < $signed(bus_read_data[31:0])) bus_write_data <= rs2[31:0]; end
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amomax.w
	        //    32'b10100_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //start store
		//	    if ($signed(rs2[31:0]) > $signed(bus_read_data[31:0])) bus_write_data <= rs2[31:0]; end
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amominu.w
	        //    32'b11000_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data[31:0]; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //start store
		//	    if (rs2[31:0] < bus_read_data[31:0]) bus_write_data <= rs2[31:0]; end
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amomaxu.w
	        //    32'b11100_??_?????_?????_010_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data[31:0]; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //start store
		//	    if (rs2[31:0] > bus_read_data[31:0]) bus_write_data <= rs2[31:0]; end
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //

		//    // lr.d
		//    32'b00010_??_?????_?????_011_?????_0101111: begin  // Lr.w_mmu 3 cycles
		//        if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; reserve_addr <= pda; reserve_valid <= 1; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0; end end
		//    // sc.d 
	        //    32'b00011_??_?????_?????_011_?????_0101111: begin
		//        if (store_step == 0) begin 
		//	    if (!reserve_valid || reserve_addr != pda) begin re[w_rd] <= 1; reserve_valid <= 0; end // finish failed 1 in rd cycle without bubble & clear reserve
		//	    else begin bus_address <= pda; bus_write_data<=rs2;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3;reserve_valid<=0;end end//consumed
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; re[w_rd] <= 0; end end // sc.w successed return 0 in rd
		//    // amoswap.d
	        //    32'b00001_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<=bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=rs2;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amoadd.d
	        //    32'b00000_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data+rs2;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amoxor.d
	        //    32'b00100_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data^rs2;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amoand.d
	        //    32'b01100_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<=bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data&rs2;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amoor.d
	        //    32'b01000_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<=bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data|rs2;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end //start store
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amomin.d
	        //    32'b10000_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //start store
		//	    if ($signed(rs2) < $signed(bus_read_data)) bus_write_data <= rs2; end
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amomax.d
	        //    32'b10100_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //start store
		//	    if ($signed(rs2) > $signed(bus_read_data)) bus_write_data <= rs2; end
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amominu.d
	        //    32'b11000_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //start store
		//	    if (rs2 < bus_read_data) bus_write_data <= rs2; end
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		//    // amomaxu.d
	        //    32'b11100_??_?????_?????_011_?????_0101111: begin
		//	if (load_step == 0) begin bus_address <= pda; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		//        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		//	if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0;  // finish load
		//            bus_address <= pda; bus_write_data<=bus_read_data;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //start store
		//	    if (rs2 > bus_read_data) bus_write_data <= rs2; end
		//        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		//	if (store_step == 1 && bus_write_done == 1) begin store_step <= 0; end end //
		     // -- ATOMIC end --
                     // M extension // M mul mulh mulhsu mulhu div divu rem remu mulw divw divuw remuw
		     // 32'b0000001_?????_?????_000_?????_0110011: re[w_rd] <= $signed(rs1) * $signed(rs2);  // Mul
                     // 32'b0000001_?????_?????_001_?????_0110011: re[w_rd] <= ($signed(rs1) * $signed(rs2))>>>64;//[127:64];  // Mulh 
                     // 32'b0000001_?????_?????_100_?????_0110011: re[w_rd] <= (rs2==0||(rs1==64'h8000_0000_0000_0000 && rs2 == -1)) ? -1 : $signed(rs1) / $signed(rs2);  // Div
                     // 32'b0000001_?????_?????_101_?????_0110011: re[w_rd] <= (rs2==0) ? -1 : $unsigned(rs1) / $unsigned(rs2);  // Divu
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

