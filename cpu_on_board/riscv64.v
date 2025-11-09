`include "header.vh"

module riscv64(
    input wire clk, 
    input wire reset,     // Active-low reset button
    input wire [31:0] instruction,
    output reg [63:0] pc,
    output reg [31:0] ir,
    output reg [63:0] re [0:31], // General Registers 32s
    output wire  heartbeat,
    input  reg [3:0] interrupt_vector, // notice from outside
    output reg  interrupt_ack,         // reply to outside
    output reg [63:0] bus_address,     // 39 bit for real standard? 64 bit now
    output reg [63:0] bus_write_data,
    output reg        bus_write_enable,
    output reg        bus_read_enable,
    output reg [2:0]  bus_read_type, // lb lh lw ld lbu lhu lwu 
    input  reg        bus_read_done,
    input  wire [63:0] bus_read_data   // from outside
);

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



    wire [11:0] w_csr = ir[31:20];   // CSR address
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
    reg [63:0] csr_satp; localparam satp = 12'h180; // Supervisor address translation and protection satp[63:60].MODE=0:off|8:SV39 satp[59:44].asid vpn2:9 vpn1:9 vpn0:9 satp[43:0]:rootpage physical addr
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
    function [63:0] csr_read;
	input [11:0] csr_index;
	begin
	    case (csr_index)
            12'h300: csr_read = csr_mstatus;
            12'h305: csr_read = csr_mtvec;
            12'h340: csr_read = csr_mscratch;
            12'h341: csr_read = csr_mepc;
            12'h342: csr_read = csr_mcause;

            default: csr_read = 64'd0;
	    endcase
	end
    endfunction
    // -- CSR Writer -- 
    task csr_write;
	input [11:0] csr_index;
	input [63:0] csr_wdata;
	begin
	    case (csr_index)
            12'h300: csr_mstatus  = csr_wdata;
            12'h305: csr_mtvec    = csr_wdata;
            12'h340: csr_mscratch = csr_wdata;
            12'h341: csr_mepc     = csr_wdata;
            12'h342: csr_mcause   = csr_wdata;

            default: ;
	    endcase
	end
    endtask
    // -- Innerl signal --
    reg bubble;
    reg [1:0] load_step;
    reg [1:0] store_step;

    // IF ir (Only drive IR)
    always @(posedge clk or negedge reset) begin
        if (!reset) begin 
            heartbeat <= 1'b0; 
            ir <= 32'h00000001; 
        end else begin
            heartbeat <= ~heartbeat; // heartbeat
            ir <= instruction;
        end
    end

    // EXE
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

        end else begin
	    // Default PC+4    (1.Could be overide 2.Take effect next cycle) 
            pc <= pc + 4;
	    interrupt_ack <= 0;

            // Interrupt
	    if (interrupt_vector == 1 && mstatus_MIE == 1) begin //mstatus[3] MIE
	        csr_mepc <= pc; // save pc

		csr_mcause <= 64'h800000000000000B; // MSB 1 for interrupts 0 for exceptions, Cause 11 for Machine External Interrupt
		csr_mstatus[MPIE] <= csr_mstatus[MIE];
		csr_mstatus[MIE] <= 0;

		pc <= csr_mtvec; // jump to mtvec addrss (default 0, need C or Assembly code of handler)
		bubble <= 1'b1; // bubble wrong fetched instruciton by IF
	        csr_mstatus[MIE] <= 0;
		interrupt_ack <= 1; // reply to outside

            // Bubble
	    end else if (bubble) begin bubble <= 1'b0; bus_write_enable <=0; end // Flush this cycle & Clear bubble signal for the next cycle

	    // IR
	    else begin 
	        bus_read_enable <= 0;
	        bus_write_enable <= 0; 
	        //bus_write_data <= 0;
	        bus_address <= `Ram_base;
                casez(ir) // Pseudo: li j jr ret call // I: addi sb sh sw sd lb lw ld lbu lhu lwu lui jal jalr auipc beq slt mret 
	            // U-type
	            32'b???????_?????_?????_???_?????_0110111: re[w_rd] <= w_imm_u; // Lui
	            32'b???????_?????_?????_???_?????_0010111: re[w_rd] <= w_imm_u + (pc - 4); // Auipc
		//    32'b???????_?????_?????_000_?????_0000011: begin  // Lb  3 cycles
		//        if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
	        //        if (load_step == 1) begin case ((re[w_rs1] + w_imm_i) & 2'b11)
		//	        0: re[w_rd]<= $signed(bus_read_data[7:0]);   1: re[w_rd]<= $signed(bus_read_data[15:8]); 
		//	        2: re[w_rd]<= $signed(bus_read_data[23:16]); 3: re[w_rd]<= $signed(bus_read_data[31:24]); 
		//	        endcase load_step <= 0; end end
		//    32'b???????_?????_?????_001_?????_0000011: begin  // Lh 3 cycles
		//        if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
	        //        if (load_step == 1) begin case ((re[w_rs1] + w_imm_i) & 2'b11)
		//	        0: re[w_rd]<= $signed(bus_read_data[15:0]); 2: re[w_rd]<= $signed(bus_read_data[31:16]); 1,3:; 
		//	        endcase load_step <= 0; end end
		    //32'b???????_?????_?????_010_?????_0000011: begin  // Lw 3 cycles
		    //    if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
		    //    if (load_step == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0; end end
		    32'b???????_?????_?????_000_?????_0000011: begin  // Lb  3 cycles
		        if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_read_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		        if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[7:0]); load_step <= 0; bus_read_enable < = 0; end end // bus ok and execute
		    32'b???????_?????_?????_100_?????_0000011: begin  // Lbu  3 cycles
		        if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_read_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		        if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[7:0]); load_step <= 0; end end // bus ok and execute
		    32'b???????_?????_?????_001_?????_0000011: begin  // Lh 3 cycles
		        if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_read_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		        if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[15:0]); load_step <= 0; end end // bus ok and execute
		    32'b???????_?????_?????_101_?????_0000011: begin   // Lhu 3 cycles
		        if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_read_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		        if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[15:0]); load_step <= 0; end end // bus ok and execute
		    32'b???????_?????_?????_010_?????_0000011: begin  // Lw_mmu 3 cycles
		        if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_read_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		        if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0; end end // bus ok and execute
		    32'b???????_?????_?????_110_?????_0000011: begin  // Lwu_mmu 3 cycles
		        if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; bus_read_type <= w_func3; end
		        if (load_step == 1 && bus_read_done == 0) begin pc <= pc - 4; bubble <= 1; end // bus working
		        if (load_step == 1 && bus_read_done == 1) begin re[w_rd]<= $unsigned(bus_read_data[31:0]); load_step <= 0; end end // bus ok and execute
		    //32'b???????_?????_?????_011_?????_0000011: begin   // Ld 5 cycles
		    //    if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; 
		    //    end if (load_step == 1) begin re[w_rd]<= bus_read_data; bus_address <= re[w_rs1] + w_imm_i + 4;  bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 2; 
		    //    end if (load_step == 2) begin re[w_rd]<= {bus_read_data[31:0], re[w_rd][31:0]}; load_step <= 0; end end
		    //32'b???????_?????_?????_100_?????_0000011: begin   // Lbu 3 cycles
		    //    if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
	            //    if (load_step == 1) begin case ((re[w_rs1] + w_imm_i) & 2'b11)
		    //            0: re[w_rd]<= bus_read_data[7:0];   1: re[w_rd]<= bus_read_data[15:8]; 
		    //            2: re[w_rd]<= bus_read_data[23:16]; 3: re[w_rd]<= bus_read_data[31:24]; 
		    //            endcase load_step <= 0; end end
		    //32'b???????_?????_?????_101_?????_0000011: begin   // Lhu 3 cycles
		    //    if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
	            //    if (load_step == 1) begin case ((re[w_rs1] + w_imm_i) & 2'b11)
		    //            0: re[w_rd]<= bus_read_data[15:0]; 2: re[w_rd]<= bus_read_data[31:16]; 1,3: ;
		    //            endcase load_step <= 0; end end
		    //32'b???????_?????_?????_110_?????_0000011: begin   // Lwu 3 cycles
		    //    if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
		    //    if (load_step == 1) begin re[w_rd]<= bus_read_data[31:0]; load_step <= 0; end end
	            //32'b???????_?????_?????_000_?????_0100011: begin  // Sb 3 cycles
		    //    if (store_step == 0) begin bus_address <= re[w_rs1] + w_imm_s; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; store_step <= 1; end
                    //    if (store_step == 1) begin bus_address <= re[w_rs1] + w_imm_s; case ((re[w_rs1] + w_imm_s) & 2'b11)
		    //            0: bus_write_data <= {bus_read_data[31:8], re[w_rs2][7:0]}; 1: bus_write_data <= {bus_read_data[31:16], re[w_rs2][7:0], bus_read_data[7:0]};
		    //            2: bus_write_data <= {bus_read_data[31:24], re[w_rs2][7:0], bus_read_data[15:0]}; 3: bus_write_data <= {re[w_rs2][7:0], bus_read_data[23:0]};
		    //            endcase bus_write_enable <= 1; store_step <= 0;  end end
	            //32'b???????_?????_?????_001_?????_0100011: begin  // Sh 3 cycles
		    //    if (store_step == 0) begin bus_address <= re[w_rs1] + w_imm_s; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; store_step <= 1; end
                    //    if (store_step == 1) begin bus_address <= re[w_rs1] + w_imm_s; case ((re[w_rs1] + w_imm_s) & 2'b11)
		    //            0: bus_write_data <= {bus_read_data[31:16], re[w_rs2][15:0]}; 2: bus_write_data <= {re[w_rs2][15:0], bus_read_data[15:0]}; 1,3:;
		    //            endcase bus_write_enable <= 1; store_step <= 0;  end end
		    //// Sw 1 cycle
	            32'b???????_?????_?????_010_?????_0100011: begin bus_address <= re[w_rs1] + w_imm_s; bus_write_data <= re[w_rs2][31:0]; bus_write_enable <= 1; pc <= pc; bubble <= 1; end
	            //32'b???????_?????_?????_011_?????_0100011: begin  // Sd 3 cycles
		    //    if (store_step == 0) begin; bus_address <= re[w_rs1] + w_imm_s; bus_write_data <= re[w_rs2][31:0]; bus_write_enable <= 1; pc <= pc - 4; bubble <= 1; store_step <= 1; end 
		    //    if (store_step == 1) begin; bus_address <= re[w_rs1] + w_imm_s + 4; bus_write_data <= re[w_rs2][63:32]; bus_write_enable <= 1; store_step <= 0; end end
                    //// Math-I
	            32'b???????_?????_?????_000_?????_0010011: re[w_rd] <= re[w_rs1] + w_imm_i;  // Addi
	            32'b???????_?????_?????_100_?????_0010011: re[w_rd] <= re[w_rs1] ^ w_imm_i ; // Xori
	            32'b???????_?????_?????_111_?????_0010011: re[w_rd] <= re[w_rs1] & w_imm_i ; // Andi
	            32'b???????_?????_?????_110_?????_0010011: re[w_rd] <= re[w_rs1] | w_imm_i ; // Ori
	            32'b???????_?????_?????_001_?????_0010011: re[w_rd] <= re[w_rs1] << w_shamt; // Slli
	            32'b000000?_?????_?????_101_?????_0010011: re[w_rd] <= re[w_rs1] >> w_shamt; // Srli // func7->6 // rv64 shame take w_f7[0]
	            32'b010000?_?????_?????_101_?????_0010011: re[w_rd] <= $signed(re[w_rs1]) >>> w_shamt; // Srai
	            32'b???????_?????_?????_010_?????_0010011: re[w_rd] <= $signed(re[w_rs1]) < w_imm_i ? 1:0; // Slti
	            32'b???????_?????_?????_011_?????_0010011: re[w_rd] <= (re[w_rs1] < w_imm_i) ?  1:0; // Sltiu
                    // Math-I (Word)
	            32'b???????_?????_?????_000_?????_0011011: re[w_rd] <= $signed(re[w_rs1][31:0] + w_imm_i[31:0]); // Addiw
	            32'b???????_?????_?????_001_?????_0011011: re[w_rd] <= $signed(re[w_rs1][31:0] << w_shamt[4:0]); // Slliw
	            32'b0000000_?????_?????_101_?????_0011011: re[w_rd] <= $signed(re[w_rs1][31:0] >> w_shamt[4:0]); // Srliw
	            32'b0100000_?????_?????_101_?????_0011011: re[w_rd] <= $signed(re[w_rs1][31:0]) >>> w_shamt[4:0]; // Sraiw
                    //// Math-R
	            32'b0000000_?????_?????_000_?????_0110011: re[w_rd] <= re[w_rs1] + re[w_rs2];  // Add
	            32'b0100000_?????_?????_000_?????_0110011: re[w_rd] <= re[w_rs1] - re[w_rs2];  // Sub;
	            32'b???????_?????_?????_100_?????_0110011: re[w_rd] <= re[w_rs1] ^ re[w_rs2]; // Xor
	            32'b???????_?????_?????_111_?????_0110011: re[w_rd] <= re[w_rs1] & re[w_rs2]; // And
	            32'b???????_?????_?????_110_?????_0110011: re[w_rd] <= re[w_rs1] | re[w_rs2]; // Or
	            32'b???????_?????_?????_001_?????_0110011: re[w_rd] <= re[w_rs1] << re[w_rs2][5:0]; // Sll 6 length
                    32'b0000000_?????_?????_101_?????_0110011: re[w_rd] <= re[w_rs1] >> re[w_rs2][5:0]; // Srl 6 length
	            32'b0100000_?????_?????_101_?????_0110011: re[w_rd] <= $signed(re[w_rs1]) >>> re[w_rs2][5:0]; // Sra 6 length
	            32'b???????_?????_?????_010_?????_0110011: re[w_rd] <= ($signed(re[w_rs1]) < $signed(re[w_rs2])) ? 1: 0;  // Slt
	            32'b???????_?????_?????_011_?????_0110011: re[w_rd] <= re[w_rs1] < re[w_rs2] ? 1:0; // Sltu

                    //// Math-R (Word)
	            32'b0000000_?????_?????_000_?????_0111011: re[w_rd] <= $signed(re[w_rs1][31:0] + re[w_rs2][31:0]);  // Addw
	            32'b0100000_?????_?????_000_?????_0111011: re[w_rd] <= $signed(re[w_rs1][31:0] - re[w_rs2][31:0]);  // Subw
	            32'b???????_?????_?????_001_?????_0111011: re[w_rd] <= $signed(re[w_rs1][31:0] << re[w_rs2][4:0]);  // Sllw 5 length
                    32'b0000000_?????_?????_101_?????_0111011: re[w_rd] <= $signed(re[w_rs1][31:0] >> re[w_rs2][4:0]);  // Srlw 5 length
	            32'b0100000_?????_?????_101_?????_0111011: re[w_rd] <= $signed(re[w_rs1][31:0]) >>> re[w_rs2][4:0]; // Sraw 5 length
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
		    32'b0000001_?????_?????_000_?????_0110011: re[w_rd] <= $signed(re[w_rs1]) * $signed(re[w_rs2]);  // Mul
                    32'b0000001_?????_?????_001_?????_0110011: re[w_rd] <= ($signed(re[w_rs1]) * $signed(re[w_rs2]))>>>64;//[127:64];  // Mulh 
                    //32'b0000001_?????_?????_100_?????_0110011: re[w_rd] <= (re[w_rs2]==0||(re[w_rs1]==64'h8000_0000_0000_0000 && re[w_rs2] == -1)) ? -1 : $signed(re[w_rs1]) / $signed(re[w_rs2]);  // Div
                    32'b0000001_?????_?????_101_?????_0110011: re[w_rd] <= (re[w_rs2]==0) ? -1 : $unsigned(re[w_rs1]) / $unsigned(re[w_rs2]);  // Divu

		    // System-CSR 
	            32'b???????_?????_?????_001_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); csr_write(w_csr,  re[w_rs1]); end // Csrrw
	            32'b???????_?????_?????_010_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_rs1 != 0 )  csr_write(w_csr, csr_read(w_csr) |  re[w_rs1]); end // Csrrs
	            32'b???????_?????_?????_011_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_rs1 != 0 )  csr_write(w_csr, csr_read(w_csr) & ~re[w_rs1]); end // Csrrc
	            32'b???????_?????_?????_101_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); csr_write(w_csr,  w_imm_z); end // Csrrwi
	            32'b???????_?????_?????_110_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_imm_z != 0) csr_write(w_csr, csr_read(w_csr) |  w_imm_z); end // csrrsi
	            32'b???????_?????_?????_111_?????_1110011: begin if (w_rd != 0) re[w_rd] <= csr_read(w_csr); if (w_imm_z != 0) csr_write(w_csr, csr_read(w_csr) & ~w_imm_z); end // Csrrci
                    // System-Machine
	            32'b0011000_00010_?????_000_?????_1110011: begin pc <= csr_read(mepc); bubble <= 1; csr_mstatus[MIE] <= csr_mstatus[MPIE]; csr_mstatus[MPIE] <= 1; end  // Mret
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
