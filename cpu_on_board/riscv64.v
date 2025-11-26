`include "header.vh"

module riscv64(
    input wire clk, 
    input wire reset,     // Active-low reset button
    input wire [31:0] instruction,
    //output reg [63:0] pc,
    output reg [39:0] pc,
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
    input  reg        bus_read_done,
    input  reg        bus_write_done,
    input  wire [63:0] bus_read_data   // from outside
);

// -- new --
    reg [63:0] re [0:31]; // General Registers 32s
    reg [63:0] sre [0:31]; // Shadow Registers 32s
    reg mmu_da=0;
    reg go_mmu_da=0;
    reg [63:0] saved_user_pc;
    reg [63:0] pa;
    reg [63:0] va;
    reg is_pda=0;
    integer i; 

    // MMU
    function [31:0] get_shadow_ir; // 0-5 mmu 
        input [63:0] spc;
        begin
    	case(spc)
	    // mmu_da
    	    0:  get_shadow_ir = 32'b00000000000000000010001010110111; // lui t0, 0x2
    	    4:  get_shadow_ir = 32'b00000000010000101000001010010011; // addi t0, t0, 0x4
    	    8:  get_shadow_ir = 32'b00000101111000000000001100010011; // addi t1, x0, 0x5e
    	    12: get_shadow_ir = 32'b00000000011000101011000000100011; // sd t1, 0(t0) print ^
    	    16: get_shadow_ir = 32'b00110000001000000000000001110011; // mret
            // mmu_pc
    	    20: get_shadow_ir = 32'b00000000000000000010001010110111; // lui t0, 0x2
    	    24: get_shadow_ir = 32'b00000000010000101000001010010011; // addi t0, t0, 0x4
    	    28: get_shadow_ir = 32'b00000010101000000000001100010011; // addi t1, x0, 42
    	    32: get_shadow_ir = 32'b00000000011000101011000000100011; // sd t1, 0(t0) print *
    	    36: get_shadow_ir = 32'b00110000001000000000000001110011; // mret
    	    default: get_shadow_ir = 32'h00000013; // NOP:addi x0, x0, 0
    	endcase
        end
    endfunction
    // vpc
    reg mmu_pc = 0;
    //reg new_vpc = 1;
    reg [39:0] vpc;
    reg is_ppc;

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
    wire [6:0] w_func7   = ir[31:25]; 
    wire [11:0] w_func12 = ir[31:20]; 
    // -- rs1 rs2 value --
    wire [63:0] rs1 = re[w_rs1];
    wire [63:0] rs2 = re[w_rs2];
    // -- op --
    wire [6:0] op = ir[6:0];



    reg [63:0] Csrs [0:20]; // 20 csr for now
    wire [11:0] w_csr = ir[31:20];   // CSR official address
//    wire [5:0] w_csr_id = (w_csr == 12'h180) ? 1 : // satp
//	                  (w_csr == 12'h300) ? 2 : // mstatus
//	                  (w_csr == 12'h305) ? 3 : // mtvec
//	                  (w_csr == 12'h340) ? 4 : // mscratch
//			   0;
    reg [5:0] w_csr_id;
    always @(*) begin
	case(w_csr)
            satp:w_csr_id = 1; 
            mstatus:w_csr_id = 2; 
            mtvec:w_csr_id = 3; 
            mscratch:w_csr_id = 4; 
	    default:w_csr_id = 0; 
	endcase
    end

    wire [63:0] csr_satp = Csrs[1];
    wire [3:0]  mmu_mode = csr_satp[63:60]; // 0:bare, 8:sv39, 9:sv48  satp.MODE!=0, privilegae is not M-mode, mstatus.MPRN is not set or in MPP's mode?
    wire [15:0] satp_asid = csr_satp[59:44]; // Address Space ID for TLB
    wire [43:0] satp_ppn  = csr_satp[43:0];  // Root Page Table PPN physical page number
    //wire [11:0] w_f12 = ir[31:20];   // ecall 0, ebreak 1
    // --Machine CSR --
    reg [63:0] csr_mstatus; localparam mstatus = 12'h300;  // 0x300 MRW Machine status reg   // 63_SD|37_MBE|36_SBE|35:34_SXL10|22_TSR|21_TW|20_TVW|17_MPRV|12:11_MPP10|7_MPIE|3_MIE|1_SIE|0_WPRI
    reg [63:0] csr_mtvec = 64'd0; integer mtvec = 12'h305; // 0x305 MRW Machine trap-handler base address *
    reg [63:0] csr_mscratch; localparam mscratch = 12'h340; // 
    reg [63:0] csr_mepc; localparam mepc = 12'h341;   
    reg [63:0] csr_mcause; localparam mcause = 12'h342;    // 0x342 MRW Machine trap casue *
    reg [63:0] csr_mie; localparam mie = 12'h304;    //
    reg [63:0] csr_mip; localparam mip = 12'h344;    //
    reg [63:0] csr_medeleg ; localparam medeleg = 12'h302;    //
    reg [63:0] csr_mideleg ; localparam mideleg = 12'h303;    //
    // Supervisor CSR
    reg [63:0] csr_sstatus; localparam sstatus =  12'h100; 
    reg [63:0] csr_sie ; localparam sie = 12'h104;   // Supervisor interrupt-enable register
    reg [63:0] csr_stvec ; localparam stvec =12'h105;
    //reg [63:0] csr_satp; 
    localparam satp = 12'h180; // Supervisor address translation and protection satp[63:60].MODE=0:off|8:SV39 satp[59:44].asid vpn2:9 vpn1:9 vpn0:9 satp[43:0]:rootpage physical addr
    reg [63:0] csr_sscratch ; localparam sscratch =12'h140;
    reg [63:0] csr_sepc ; localparam sepc =12'h141; //
    reg [63:0] csr_scause ; localparam scause = 12'h142;// 
    reg [63:0] csr_stval ; localparam stval = 12'h143;//
    reg [63:0] csr_sip ; localparam sip = 12'h144; // Supervisor interrupt pending
    //integer sedeleg = 12'h102;
    //integer sideleg = 12'h103;
    //integer scounteren = 12'h106;
    //integer scontext = 12'h5a8; 
    // -- CSR Bits --
    localparam MIE  = 3; // mstatus.MIE
    localparam MPIE  = 7; // mstatus.MPIE
    //wire mie_MEIE = csr[mie][11];
    //wire mip_MEIP = csr[mie][11];
    wire mstatus_MIE = csr_mstatus[MIE];


    // -- CSR Other Registers -- use BRAM in FPGA then SRAM in ASIC port?
    //reg [63:0] other_csr [0:4096]; // Maximal 12-bit length = 4096 
    // -- CSR Reader -- 
    //function [63:0] csr_read;
    //    input [11:0] csr_index;
    //    begin
    //        case (csr_index)
    //        12'h300: csr_read = csr_mstatus;
    //        12'h305: csr_read = csr_mtvec;
    //        12'h340: csr_read = csr_mscratch;
    //        12'h341: csr_read = csr_mepc;
    //        12'h342: csr_read = csr_mcause;

    //        12'h180: csr_read = csr_satp;

    //        default: csr_read = 64'd0;
    //        endcase
    //    end
    //endfunction
    //// -- CSR Writer -- 
    //task csr_write;
    //    input [11:0] csr_index;
    //    input [63:0] csr_wdata;
    //    begin
    //        case (csr_index)
    //        12'h300: csr_mstatus  = csr_wdata;
    //        12'h305: csr_mtvec    = csr_wdata;
    //        12'h340: csr_mscratch = csr_wdata;
    //        12'h341: csr_mepc     = csr_wdata;
    //        12'h342: csr_mcause   = csr_wdata;

    //        12'h180: csr_satp     = csr_wdata;

    //        default: ;
    //        endcase
    //    end
    //endtask
    // -- Innerl signal --
    reg bubble;
    reg [1:0] load_step;
    reg [1:0] store_step;

    // IF Instruction (Only drive IR)
    always @(posedge clk or negedge reset) begin
        if (!reset) begin 
            heartbeat <= 1'b0; 
            ir <= 32'h00000001; 
        end else begin
            heartbeat <= ~heartbeat; // heartbeat
            //ir <= instruction;
	    if (mmu_da || mmu_pc) ir <= get_shadow_ir(pc);
            else ir <= instruction;
        end
    end

    // EXE Instruction 
    always @(posedge clk or negedge reset) begin
        if (!reset) begin 
	    bubble <= 1'b0;
	    pc <= `Ram_base;
	    load_step <= 0;
	    store_step <= 0;
	    bus_read_enable <= 0;
	    bus_write_enable <= 0;
	    bus_write_data <= 0;
	    bus_address <= `Ram_base;
            // Interrupt re-enable
	    csr_mstatus[MIE] <= 1;
	    interrupt_ack <= 0;
	    mmu_da <= 0;
	    is_pda <= 0;
	    for (i=0;i<=31;i=i+1) begin sre[i]<= 64'b0; end
	    for (i=0;i<=20;i=i+1) begin Csrs[i]<= 64'b0; end
	    mmu_pc <= 0;
	    is_ppc <= 0; // current using address is physical addr

        end else begin
	    // Default PC+4    (1.Could be overide 2.Take effect next cycle) 
            pc <= pc + 4;
	    interrupt_ack <= 0;
	    bus_read_enable <= 0;
	    bus_write_enable <= 0; 
	    //is_ppc <= 0;
	    //is_pda <= 0;

	    //  mmu_pc
	    if (mmu_mode && !mmu_pc && !mmu_da && !is_ppc) begin  // OPEN
		mmu_pc <= 1; // MMU_PC ON 
	        pc <= 20; // handler
	 	bubble <= 1'b1; // bubble 
		for (i=0;i<=31;i=i+1) begin sre[i]<= re[i]; end // save re
		re[30]<= pc - 4; // pass vpc to x30
	    end else if (mmu_pc && ir == 32'b00110000001000000000000001110011) begin // end hiject mret  // CLOSE
		pc <= re[30]; // get ppc & recover from shadow when see Mret
	 	bubble <= 1'b1; // bubble
		for (i=0;i<=31;i=i+1) begin re[i]<= sre[i]; end // recover usr re
		is_ppc <= 1; // we are ppc
		mmu_pc <= 0; // MMU_PC OFF

            //  mmu_da OPEN_2
	    //end else if (mmu_da && !is_pda) begin 
	    //end else if (go_mmu_da) begin 
	    //end else if ((bus_read_enable || bus_write_enable) && !mmu_pc && !mmu_da && !is_pda) begin 
	    end else if (mmu_mode && op == 7'b0?00011 && !mmu_pc && !mmu_da && !is_pda) begin  // load/store
		//go_mmu_da <= 0;
		mmu_da <= 1; // MMU_DA ON
	        //saved_user_pc <= pc; // save pc l/s directly from OPEN_1
	        saved_user_pc <= pc-4; // save pc l/s
		pc <= 0; // handler
	 	bubble <= 1'b1; // bubble
		//is_pda <= 1; // now we in mmu_da consider handler assembler's address as physical address
		for (i=0;i<=31;i=i+1) begin sre[i]<= re[i]; end // save re
		//re[31]<= va; // pass va to x31
		//re[31]<= bus_address; // pass va to x31
		re[31]<= rs1 + w_imm_i; // pass va to x31
		// then inner assembly for mmu wroking to calculate pa via va load and bus, put pa to x31
	    end else if (mmu_da && ir == 32'b00110000001000000000000001110011) begin // hiject mret // CLOSE
		pa <= re[31]; // get pda
		pc <= saved_user_pc; // recover from shadow when see Mret
		bubble <= 1; // bubble
		for (i=0;i<=31;i=i+1) begin re[i]<= sre[i]; end // recover usr re
		is_pda <= 1; // we are pa
		mmu_da <= 0; // MMU_DA OFF
		
            // Bubble
	    end else if (bubble) begin bubble <= 1'b0; //is_ppc <= is_ppc; is_pda <= is_pda;//  bus_write_enable <=0; bus_read_enable <= 0; end // Flush this cycle & Clear bubble signal for the next cycle

            // Interrupt
	    //if (interrupt_vector == 1 && mstatus_MIE == 1) begin //mstatus[3] MIE
	    end else if (interrupt_vector == 1 && mstatus_MIE == 1) begin //mstatus[3] MIE
	        csr_mepc <= pc; // save pc

		csr_mcause <= 64'h800000000000000B; // MSB 1 for interrupts 0 for exceptions, Cause 11 for Machine External Interrupt
		csr_mstatus[MPIE] <= csr_mstatus[MIE];
		csr_mstatus[MIE] <= 0;

		pc <= csr_mtvec; // jump to mtvec addrss (default 0, need C or Assembly code of handler)
		bubble <= 1'b1; // bubble wrong fetched instruciton by IF
	        csr_mstatus[MIE] <= 0;
		interrupt_ack <= 1; // reply to outside

            // Upper are hijects of executing ir for handler special state
	    // IR
	    end else begin 
	        //bus_read_enable <= 0;
	        //bus_write_enable <= 0; 
	        //bus_write_data <= 0;
	        //bus_address <= `Ram_base;
	        is_ppc <= 0;
                casez(ir) // Pseudo: li j jr ret call // I: addi sb sh sw sd lb lw ld lbu lhu lwu lui jal jalr auipc beq slt mret 
	            // U-type
	            32'b???????_?????_?????_???_?????_0110111: re[w_rd] <= w_imm_u; // Lui
	            32'b???????_?????_?????_???_?????_0010111: re[w_rd] <= w_imm_u + (pc - 4); // Auipc

		    //32'b???????_?????_?????_000_?????_0000011: begin  // Lb  3 cycles but wait to 5
		    //    if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		    //    if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		    //    if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[7:0]); load_step <= 0; end end //bus_read_enable <= 0; end end // bus ok and execute
		    //32'b???????_?????_?????_000_?????_0000011: begin  // Lb  3 cycles but wait to 5
		    //    // start mmu-da only  MMU_DA ON
		    //    if (mmu_mode && !mmu_da && !mmu_pc && !is_pda) begin go_mmu_da<=1; mmu_da<=1; va <= rs1 + w_imm_i; pc <= pc -4; end // for enter | hiject Lb, pass lb pc, bus_address to mmu va
		    //else begin
		    //    if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		    //    if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		    //    if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[7:0]); load_step <= 0; end //end //bus_read_enable <= 0; end end // bus ok and execute
                    //    
		    //    // for post mmu_da only ( overwrite normal value of address)
		    //    if (mmu_mode && !mmu_da && is_pda && !mmu_pc && load_step==0 && bus_read_done==0) begin bus_address <= pa; end // for start pa_ed lb | overwrite bus_address; bind with step 0
		    //    if (mmu_mode && !mmu_da && is_pda && !mmu_pc && load_step==1 && bus_read_done==1) begin is_pda <= 0;end // for finish va-pa-lb reset is_pda to 0; bind with step 1,1
		    //    // XXXABCDXABCDEFGHXABCDEFGHXA***^*B^*****B^*****B^*****B^*****B^*****
		    //    end
		    //end
		    32'b???????_?????_?????_000_?????_0000011: begin  // Lb  3 cycles but wait to 5
		        // start mmu-da only  MMU_DA ON //for enter|hiject Lb, pass lb pc,bus_address to mmu va
			//if (mmu_mode && need_mmu_da_translate) begin mmu_da<=1; va<=rs1 + w_imm_i; pc<= pc-4;end else begin

		        //if (load_step == 0) begin if (is_pda) is_pda<=0; bus_address <= (is_pda) ? pa : rs1+w_imm_i; bus_read_enable<=1; pc<=pc-4; bubble<=1; load_step<=1; bus_ls_type<=w_func3; end
			if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; //end
			                    if (is_pda) bus_address <= pa; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		        if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[7:0]); load_step <= 0; //end //end //bus_read_enable <= 0; end end // bus ok and execute
			                    if (is_pda) is_pda <= 0; end 
                        
			// pa override 
			//if (load_step == 0 && is_pda) begin bus_address <= pa; is_pda <= 0; end
		        end
		    //end
		    32'b???????_?????_?????_100_?????_0000011: begin  // Lbu  3 cycles
		        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[7:0]); load_step <= 0; end end //bus_read_enable <= 0; end end // bus ok and execute
		    32'b???????_?????_?????_001_?????_0000011: begin  // Lh 3 cycles
		        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[15:0]); load_step <= 0; end end //bus_read_enable <= 0; end end // bus ok and execute
		    32'b???????_?????_?????_101_?????_0000011: begin   // Lhu 3 cycles
		        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[15:0]); load_step <= 0; end end //bus_read_enable <= 0; end end // bus ok and execute
		    32'b???????_?????_?????_010_?????_0000011: begin  // Lw_mmu 3 cycles
		        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0; end end //bus_read_enable <= 0; end end // bus ok and execute
		    32'b???????_?????_?????_110_?????_0000011: begin  // Lwu_mmu 3 cycles
		        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[31:0]); load_step <= 0; end end //bus_read_enable <= 0; end end // bus ok and execute
		    32'b???????_?????_?????_011_?????_0000011: begin   // Ld 5 cycles
		        if (load_step == 0) begin bus_address <= rs1 + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_ls_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
			if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= bus_read_data; load_step <= 0; end end //bus_read_enable <= 0; end end // bus ok and execute
                    // Store
	            //32'b???????_?????_?????_000_?????_0100011: begin bus_address <= rs1 + w_imm_s;bus_write_data<=rs2[7:0]; bus_write_enable<=1;bus_ls_type<=w_func3;end//Sb bus1 cycles
	            //32'b???????_?????_?????_001_?????_0100011: begin bus_address <= rs1 + w_imm_s;bus_write_data<=rs2[15:0];bus_write_enable<=1;bus_ls_type<=w_func3;end//Sh bus1
	            //32'b???????_?????_?????_010_?????_0100011: begin bus_address <= rs1 + w_imm_s;bus_write_data<=rs2[31:0];bus_write_enable<=1;bus_ls_type<=w_func3;end//Sw bus1
	            //32'b???????_?????_?????_011_?????_0100011: begin bus_address <= rs1 + w_imm_s;bus_write_data<=rs2;bus_write_enable<=1;pc<=pc;bubble<=1;bus_ls_type<=w_func3;end//Sdbus2
	            32'b???????_?????_?????_000_?????_0100011: begin 
		        if (store_step == 0) begin bus_address <= rs1 + w_imm_s; bus_write_data<=rs2[7:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; //end
			                    //if (is_pda) begin bus_address <= pa; is_pda <= 0; end end
			                    if (is_pda) bus_address <= pa; end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
			if (store_step == 1 && bus_write_done == 1) begin store_step <= 0;
			                    if (is_pda) is_pda <= 0; end 
		        end //Sb bus1 cycles
	            32'b???????_?????_?????_001_?????_0100011: begin
		        if (store_step == 0) begin bus_address <= rs1 + w_imm_s; bus_write_data<=rs2[15:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		        if (store_step == 1 && bus_write_done == 1) store_step <= 0;
		        end //Sh
	            32'b???????_?????_?????_010_?????_0100011: begin
		        if (store_step == 0) begin bus_address <= rs1 + w_imm_s; bus_write_data<=rs2[31:0];bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		        if (store_step == 1 && bus_write_done == 1) store_step <= 0;
		        end //Sw
	            32'b???????_?????_?????_011_?????_0100011: begin 
		        if (store_step == 0) begin bus_address <= rs1 + w_imm_s; bus_write_data<=rs2;bus_write_enable<=1;pc<=pc-4;bubble<=1;store_step<=1;bus_ls_type<=w_func3; end
		        if (store_step == 1 && bus_write_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working 1 bubble2 this3
		        if (store_step == 1 && bus_write_done == 1) store_step <= 0;
		        end //Sd
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
                    // Jump
	            32'b???????_?????_?????_???_?????_1101111: begin pc <= pc - 4 + w_imm_j; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1'b1; end // Jal
	            32'b???????_?????_?????_???_?????_1100111: begin pc <= (rs1 + w_imm_i) & 64'hFFFFFFFFFFFFFFFE; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1; end // Jalr
                    // Branch 
		    32'b???????_?????_?????_000_?????_1100011: begin if (rs1 == rs2) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Beq
		    32'b???????_?????_?????_001_?????_1100011: begin if (rs1 != rs2) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bne
		    32'b???????_?????_?????_100_?????_1100011: begin if ($signed(rs1) < $signed(rs2)) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Blt
		    32'b???????_?????_?????_101_?????_1100011: begin if ($signed(rs1) >= $signed(rs2)) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bge
		    32'b???????_?????_?????_110_?????_1100011: begin if (rs1 < rs2) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bltu
		    32'b???????_?????_?????_111_?????_1100011: begin if (rs1 >= rs2) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Bgeu
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

	            //32'b???????_?????_?????_010_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_rs1 != 0 )  csr_write(w_csr, csr_read(w_csr) |  rs1); end // Csrrs
	            //32'b???????_?????_?????_011_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_rs1 != 0 )  csr_write(w_csr, csr_read(w_csr) & ~rs1); end // Csrrc
	            //32'b???????_?????_?????_101_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); csr_write(w_csr,  w_imm_z); end // Csrrwi
	            //32'b???????_?????_?????_110_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_imm_z != 0) csr_write(w_csr, csr_read(w_csr) |  w_imm_z); end // csrrsi
	            //32'b???????_?????_?????_111_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_imm_z != 0) csr_write(w_csr, csr_read(w_csr) & ~w_imm_z); end // Csrrci
                    // System-Machine
	            //32'b0011000_00010_?????_000_?????_1110011: begin pc <= csr_read(mepc); bubble <= 1; csr_mstatus[MIE] <= csr_mstatus[MPIE]; csr_mstatus[MPIE] <= 1; end  // Mret
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
		        // Ecall
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
		     // Ebreak
		     // Fence
		     // Fence.i
		     // RV64IMAFD(G)C  RVA23U64
		     // M mul mulh mulhsu mulhu div divu rem remu mulw divw divuw remuw
		     // A lr.w sc.w lr.d sc.d
		     // amoswap amoadd amoxor amoand amoor
		     // amomin amomax amominu amomaxu
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

//PLIC
//CLINT
  
  
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
  
