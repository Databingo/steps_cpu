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
    output reg [1:0]  bus_bytes,       // 0 sw, 1 sb, 2 sh, 3 sd, 3 sd??
    output reg [63:0] bus_write_data,
    output reg        bus_write_enable,
    output reg        bus_read_enable,
    input  wire [63:0] bus_read_data   // from outside
);
    // -- CSR Index--
    localparam mstatus = 12'h300;   // 0x300 MRW Machine status reg   // 63_SD|37_MBE|36_SBE|35:34_SXL10|22_TSR|21_TW|20_TVW|17_MPRV|12:11_MPP10|7_MPIE|3_MIE|1_SIE|0_WPRI
    integer mie = 12'h304;          // 0x304 MRW Machine interrupt-enable register *
    integer mip = 12'h344;          // 0x344 MRW Machine interrupt pending *
    integer mtvec = 12'h305;        // 0x305 MRW Machine trap-handler base address *
    localparam mcause = 12'h342;    // 0x342 MRW Machine trap casue *
    localparam mepc = 12'h341;   
    // -- CSR Bits --
    localparam MIE  = 3; // mstatus.MIE
    localparam MPIE  = 7; // mstatus.MPIE
    //wire mie_MEIE = csr[mie][11];
    //wire mip_MEIP = csr[mie][11];
    wire mstatus_MIE = csr_mstatus[MIE];

    // -- Immediate decoders  -- 
    wire signed [63:0] w_imm_u = {{32{ir[31]}}, ir[31:12], 12'b0};  // U-type immediate Lui Auipc
    wire signed [63:0] w_imm_i = {{52{ir[31]}}, ir[31:20]};   // I-type immediate Lb Lh Lw Lbu Lhu Lwu Ld Jalr Addi Slti Sltiu Xori Ori Andi Addiw 
    wire signed [63:0] w_imm_s = {{52{ir[31]}}, ir[31:25], ir[11:7]};  // S-type immediate Sb Sh Sw Sd
    wire signed [63:0] w_imm_j = {{43{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0}; // UJ-type immediate Jal  // read immediate & padding last 0, total 20 + 1 = 21 bits
    wire signed [63:0] w_imm_b = {{51{ir[31]}}, ir[7],  ir[30:25], ir[11:8], 1'b0}; // B-type immediate Beq Bne Blt Bge Bltu Bgeu // read immediate & padding last 0, total 12 + 1 = 13 bits
    wire [5:0] w_shamt = ir[25:20]; // If 6 bits the highest is always 0??
    // -- Instruction Decoding --
    wire [4:0] w_rd  = ir[11:7];
    wire [4:0] w_rs1 = ir[19:15];
    wire [4:0] w_rs2 = ir[24:20];
    // -- CSR Registers --
    reg [63:0] csr_mepc;
    reg [63:0] csr_mstatus;
    reg [63:0] csr_mcasue;
    reg [63:0] csr_mtvec = 64'd0;
    // -- CSR Other Registers -- use BRAM in FPGA then SRAM in ASIC port?
    //reg [63:0] other_csr [0:4096]; // Maximal 12-bit length = 4096 
    // -- CSR Reader -- 
    function [63:0] csr_read;
	input [11:0] csr_index;
	begin
	    case (csr_index)
            12'h341: csr_read = csr_mepc;
            12'h300: csr_read = csr_mstatus;
            default: csr_read = 64'd0;
	    endcase
	end
    endfunction
    // -- CSR Bit-- 
    //function csr_bit;
    //    input [11:0] csr_index;
    //    input integer bit_position;
    //    reg [63:0] csr_value;
    //    begin
    //        csr_value = csr_read(csr_index);
    //        csr_bit = csr_value[bit_position];
    //    end
    //endfunction
    // -- CSR Writer -- 
    function csr_write;
	input [11:0] csr_index;
	input [63:0] csr_wdata;
	begin
	    case (csr_index)
            12'h341: csr_mepc = csr_wdata;
            12'h300: csr_mstatus = csr_wdata;
            default: ;
	    endcase
	end
    endfunction
    // -- Innerl signal --
    reg bubble;
    reg load_step;
    reg store_step;
    reg [1:0] bus_byte_position;
    assign w_bus_address = re[w_rs1] + w_imm_i; 


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
	    bus_bytes <= 0;
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

		csr_mcasue <= 64'h800000000000000B; // MSB 1 for interrupts 0 for exceptions, Cause 11 for Machine External Interrupt
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
	        bus_write_data <= 0;
	        bus_address <= `Ram_base;
	        bus_bytes <= 0;
                casez(ir) // Pseudo: li j jr ret call // I: lui ld sd addi jal jalr mret auipc beq slt
	            // U-type
	            32'b???????_?????_?????_???_?????_0110111: re[w_rd] <= w_imm_u; // Lui
	            32'b???????_?????_?????_???_?????_0010111: re[w_rd] <= w_imm_u + (pc - 4); // Auipc

                    // Load
		    ///32'b???????_?????_?????_011_?????_0000011: begin if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
	            ///                                                 if (load_step == 1) begin re[w_rd]<= bus_read_data; load_step <= 0; end end  // Ld
		    32'b???????_?????_?????_011_?????_0000011: begin 
		        if (load_step == 0) begin 
			    bus_address <= re[w_rs1] + w_imm_i; 
			    bus_read_enable <= 1; 
			    pc <= pc - 4; 
			    bubble <= 1; 
			    load_step <= 1; 
			end if (load_step == 1) begin 
			    re[w_rd]<= bus_read_data; 
			    bus_address <= re[w_rs1] + w_imm_i + 4;  // hight 32 bit data in next line
			    bus_read_enable <= 1; 
			    pc <= pc - 4; 
			    bubble <= 1; 
			    load_step <= 2; 
			end if (load_step == 2) begin 
			    re[w_rd]<= {bus_read_data[31:0], re[w_rd][31:0]}; 
			    load_step <= 0; 
			end 
		    end  // Ld
		    //32'b???????_?????_?????_000_?????_0000011: begin if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
	            //                                                 if (load_step == 1) begin re[w_rd]<= $signed(bus_read_data[7:0]); load_step <= 0; end end  // Lb
		    32'b???????_?????_?????_000_?????_0000011: begin 
		        if (load_step == 0) begin 
			    bus_address <= re[w_rs1] + w_imm_i; 
			    bus_read_enable <= 1; 
			    pc <= pc - 4; 
			    bubble <= 1; 
			    load_step <= 1; 
			    //bus_byte_position <= re[w_rs1][1:0] + w_imm_i[1:0];  // byte_start_position in 32 bit data
			    bus_byte_position <= (re[w_rs1] + w_imm_i) | 64'b11;  // byte_start_position in 32 bit data
			    //bus_byte_position <= w_bus_address[1:0];  // byte_start_position in 32 bit data
			end
	                if (load_step == 1) begin 
			    //re[w_rd]<= $signed(bus_read_data[bus_byte_position*8+7:bus_byte_position*8]); 
			    if (bus_byte_position == 0) re[w_rd]<= $signed(bus_read_data[7:0]); 
			    if (bus_byte_position == 1) re[w_rd]<= $signed(bus_read_data[15:8]); 
			    if (bus_byte_position == 2) re[w_rd]<= $signed(bus_read_data[23:16]); 
			    if (bus_byte_position == 3) re[w_rd]<= $signed(bus_read_data[31:24]); 
			    load_step <= 0; 
			    bus_byte_position <= 0;
			end 
		    end  // Lb


		    32'b???????_?????_?????_100_?????_0000011: begin if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
	                                                             if (load_step == 1) begin re[w_rd]<= bus_read_data[7:0]; load_step <= 0; end end  // Lbu

		    32'b???????_?????_?????_001_?????_0000011: begin if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
	                                                             if (load_step == 1) begin re[w_rd]<= $signed(bus_read_data[15:0]); load_step <= 0; end end  // Lh
		    32'b???????_?????_?????_101_?????_0000011: begin if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
	                                                             if (load_step == 1) begin re[w_rd]<= bus_read_data[15:0]; load_step <= 0; end end  // Lhu

		    32'b???????_?????_?????_010_?????_0000011: begin if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
	                                                             if (load_step == 1) begin re[w_rd]<= $signed(bus_read_data[31:0]); load_step <= 0; end end  // Lw
		    32'b???????_?????_?????_110_?????_0000011: begin if (load_step == 0) begin bus_address <= re[w_rs1] + w_imm_i; bus_read_enable <= 1; pc <= pc - 4; bubble <= 1; load_step <= 1; end
	                                                             if (load_step == 1) begin re[w_rd]<= bus_read_data[31:0]; load_step <= 0; end end  // Lwu

                    // Store
	            //32'b???????_?????_?????_011_?????_0100011: begin bus_address <= re[w_rs1] + w_imm_s; bus_write_data <= re[w_rs2]; bus_write_enable <= 1; end // Sd //! 32-32 multip cycles
	            32'b???????_?????_?????_011_?????_0100011: begin 
		        if (store_step == 0) begin;
		            bus_address <= re[w_rs1] + w_imm_s; 
		            bus_write_data <= re[w_rs2][31:0]; 
		            bus_write_enable <= 1; 
			    pc <= pc - 4;
			    bubble <= 1;
                            store_step <= 1;
		        end 
		        if (store_step == 1) begin;
		            bus_address <= re[w_rs1] + w_imm_s + 4; 
		            bus_write_data <= re[w_rs2][63:32]; 
		            bus_write_enable <= 1; 
                            store_step <= 0;
		        end 
		    end // Sd 

	            //32'b???????_?????_?????_000_?????_0100011: begin bus_address <= re[w_rs1] + w_imm_s; bus_write_data <= re[w_rs2][7:0]; bus_write_enable <= 1; end // Sb
	            32'b???????_?????_?????_000_?????_0100011: begin 
		        if (store_step == 0) begin 
		            bus_address <= re[w_rs1] + w_imm_i; 
		            bus_read_enable <= 1; 
		            pc <= pc - 4; 
		            bubble <= 1; 
		            store_step <= 1; 
			    bus_byte_position <= w_bus_address[1:0];  // byte_start_position in 32 bit data
		        end
                        if (store_step == 1) begin 
	                    bus_address <= re[w_rs1] + w_imm_s; 
			    bus_write_data <= (re[w_rd][7:0]<<bus_byte_position*8) | (bus_read_data[31:0] & ~(32'b11111111<<bus_byte_position*8) );
			    bus_write_enable <= 1;
		            store_step <= 0;  
			    bus_byte_position <= 0;
			end 
		    end // Sb


	            32'b???????_?????_?????_001_?????_0100011: begin bus_address <= re[w_rs1] + w_imm_s; bus_write_data <= re[w_rs2][15:0]; bus_write_enable <= 1;bus_bytes <= 2'b11; end // Sh
	            32'b???????_?????_?????_010_?????_0100011: begin bus_address <= re[w_rs1] + w_imm_s; bus_write_data <= re[w_rs2][31:0]; bus_write_enable <= 1; end // Sw
                    // Math-I
	            32'b???????_?????_?????_000_?????_0010011: re[w_rd] <= re[w_rs1] + w_imm_i;  // Addi
	            //32'b???????_?????_?????_010_?????_0010011: re[w_rd] <= $signed(re[w_rs1]) < w_imm_i ? 1:0; // Slti
	            //32'b???????_?????_?????_011_?????_0010011: re[w_rd] <= (re[w_rs1] < w_imm_i) ?  1:0; // Sltiu
	            //32'b???????_?????_?????_110_?????_0010011: re[w_rd] <= re[w_rs1] | w_imm_i ; // Ori
	            //32'b???????_?????_?????_111_?????_0010011: re[w_rd] <= re[w_rs1] & w_imm_i ; // Andi
	            //32'b???????_?????_?????_100_?????_0010011: re[w_rd] <= re[w_rs1] ^ w_imm_i ; // Xori
	            32'b???????_?????_?????_001_?????_0010011: re[w_rd] <= re[w_rs1] << w_shamt; // Slli
	            //32'b000000?_?????_?????_101_?????_0010011: re[w_rd] <= re[w_rs1] >> w_shamt; // Srli // func7->6 // rv64 shame take w_f7[0]
	            //32'b010000?_?????_?????_101_?????_0010011: re[w_rd] <= $signed(re[w_rs1]) >>> w_shamt; // Srai
                    // Math-I (Word)
	            //32'b???????_?????_?????_000_?????_0011011: re[w_rd] <= {{32{sum_imm_32[31]}}, sum_imm_32}; // Addiw
	            //32'b???????_?????_?????_001_?????_0011011: re[w_rd] <= {{32{slliw_s1[31]}}, slliw_s1}; // Slliw
	            //32'b0000000_?????_?????_101_?????_0011011: re[w_rd] <= {{32{srliw_s1[31]}}, srliw_s1}; // Srliw
	            //32'b0100000_?????_?????_101_?????_0011011: re[w_rd] <= {{32{sraiw_s1[31]}}, sraiw_s1}; // Sraiw
                    //// Math-R
	            32'b0000000_?????_?????_000_?????_0110011: re[w_rd] <= re[w_rs1] + re[w_rs2];  // Add
	            32'b0100000_?????_?????_000_?????_0110011: re[w_rd] <= re[w_rs1] - re[w_rs2];  // Sub;
	            32'b???????_?????_?????_010_?????_0110011: re[w_rd] <= ($signed(re[w_rs1]) < $signed(re[w_rs2])) ? 1: 0;  // Slt
	            //32'b???????_?????_?????_011_?????_0110011: re[w_rd] <= re[w_rs1] < re[w_rs2] ? 1:0; // Sltu
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
                    // Jump
	            32'b???????_?????_?????_???_?????_1101111: begin pc <= pc - 4 + w_imm_j; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1'b1; end // Jal
	            32'b???????_?????_?????_???_?????_1100111: begin pc <= (re[w_rs1] + w_imm_i) & 64'hFFFFFFFFFFFFFFFE; if (w_rd != 5'b0) re[w_rd] <= pc; bubble <= 1; end // Jalr
                    // Branch 
		    32'b???????_?????_?????_000_?????_1100011: begin if (re[w_rs1] == re[w_rs2]) begin pc <= pc - 4 + w_imm_b; bubble <= 1'b1; end end // Beq
		    //32'b???????_?????_?????_001_?????_1100011: begin if (re[w_rs1] != re[w_rs2]) begin pc <= pc + sign_extended_bimm; bubble <= 1'b1; end end // Bne
		    //32'b???????_?????_?????_100_?????_1100011: begin if ($signed(re[w_rs1]) < $signed(re[w_rs2])) begin pc <= pc + sign_extended_bimm; bubble <= 1'b1; end end // Blt
		    //32'b???????_?????_?????_101_?????_1100011: begin if ($signed(re[w_rs1]) >= $signed(re[w_rs2])) begin pc <= pc + sign_extended_bimm; bubble <= 1'b1; end end // Bge
		    //32'b???????_?????_?????_110_?????_1100011: begin if (re[w_rs1] < re[w_rs2]) begin pc <= pc + sign_extended_bimm; bubble <= 1'b1; end end // Bltu
		    //32'b???????_?????_?????_111_?????_1100011: begin if (re[w_rs1] >= re[w_rs2]) begin pc <= pc + sign_extended_bimm; bubble <= 1'b1; end end // Bgeu
		    // System-CSR 
                    // System-Machine
	            32'b0011000_00010_?????_000_?????_1110011: begin pc <= csr_read(mepc); bubble <= 1; csr_mstatus[MIE] <= csr_mstatus[MPIE]; csr_mstatus[MPIE] <= 1; end  // Mret
		    // Ecall
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
