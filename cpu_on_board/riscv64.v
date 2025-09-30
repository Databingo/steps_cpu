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

    output reg [63:0] bus_address,     // 39 bit for real standard?
    output reg [63:0] bus_address_cache,     // 39 bit for real standard?
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
    // -- Instruction Decoding --
    wire [4:0] w_rd  = ir[11:7];
    wire [4:0] w_rs1 = ir[19:15];
    wire [4:0] w_rs2 = ir[24:20];
	

    // -- CSR Registers --
    reg [63:0] csr_mepc;
    reg [63:0] csr_mstatus;
    reg [63:0] csr_mcasue;
    reg [63:0] csr_mtvec = 64'd0;
    // -- CSR Other Registers -- use BRAM in FPGA then SRAM in ASIC
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
    function csr_bit;
	input [11:0] csr_index;
	input integer bit_position;
        reg [63:0] csr_value;
	begin
	    csr_value = csr_read(csr_index);
	    csr_bit = csr_value[bit_position];
	end
    endfunction
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
    reg lb_step;
    reg sd_step;

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
	    lb_step <= 0;
            sd_step <= 0;
	    bus_read_enable <= 0;
	    bus_write_enable <= 0;
	    bus_write_data <= 0;
	    bus_address <= `Ram_base;
	    bus_address_cache <= `Ram_base>>2;
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
	    end else if (bubble) bubble <= 1'b0; // Flush this cycle & Clear bubble signal for the next cycle

	    // IR
	    else begin 
	        bus_read_enable <= 0;
	        bus_write_enable <= 0; 
	        bus_write_data <= 0;
	        bus_address <= `Ram_base;
	        bus_address_cache <= `Ram_base>>2;
                casez(ir) 
		    // Pseudo: li call j ret
		    // I: lui ld sd addi jal jalr mret auipc beq slt
	            32'b???????_?????_?????_???_?????_0110111: re[w_rd] <= w_imm_u; // Lui
	            32'b???????_?????_?????_???_?????_0010111: re[w_rd] <= pc - 4  +  w_imm_u; // Auipc
		    32'b???????_?????_?????_000_?????_1100011: begin // Beq
		        if (re[w_rs1] == re[w_rs2]) begin 
			    pc <= pc - 4 + w_imm_b; 
			    bubble <= 1'b1; 
			end 
		    end 
	            32'b???????_?????_?????_010_?????_0110011: re[w_rd] <= ($signed(re[w_rs1]) < $signed(re[w_rs2])) ? 1: 0;  // Slt
	            32'b0011000_00010_?????_000_?????_1110011: begin   // Mret
	                pc <= csr_read(mepc); 
			bubble <= 1; 
		        csr_mstatus[MIE] <= csr_mstatus[MPIE];
		        csr_mstatus[MPIE] <= 1;
		    end 
		    32'b???????_?????_?????_011_?????_0000011: begin  // Ld
	                if (lb_step == 0) begin
	                    bus_address <= re[w_rs1] + w_imm_i ;
	                    bus_address_cache <= (re[w_rs1] + w_imm_i)>>2 ;
	                    bus_read_enable <= 1;
	                    pc <= pc - 4; // Core of pipeline: pc-4 due to at executing SB cycle, the pc is already pc+4, have to -4 to keep pc as SB; And IF get ir of pc+4 tenaciously need a bubble flush
	                    bubble <= 1; //!! take over cycle 2, meanwhile bus read 
	                    lb_step <= 1;
	                end // bubble cycle happenly for bus to read data according to bus_address
	                if (lb_step == 1) begin  
	                    re[w_rd]<= bus_read_data; // cycle 3 save to cpu's register
	                    lb_step <= 0;
	                end
		    end 
	            32'b???????_?????_?????_011_?????_0100011: begin // Sd
		        if (sd_step == 0) begin 
		            //bus_address <= `Art_base;
	                    bus_address <= re[w_rs1] + w_imm_s;
	                    bus_address_cache <= (re[w_rs1] + w_imm_s)>>2;
	                    bus_write_data <= re[w_rs2];
	                    bus_write_enable <= 1;
			    //--wait bus write-- now pc value is already sb+4 and IF is getting sb+4 and change pc setting from pc+4(sb+4+4) to pc so next cycle bubble ir (sb+4), getting sb+4, the next.
	                    pc <= pc;
	                    bubble <= 1;
			end
	            end
	            32'b???????_?????_?????_000_?????_0010011: re[w_rd] <= re[w_rs1] + w_imm_i;  // Addi
	            32'b???????_?????_?????_???_?????_1101111: begin  // Jal
                    //at N-1, IF is fetching jar, EXE is setting pc to jar+4, so at the END of N-1 cycle, pc is jar+4
                    //at N,   IF is fetching jar+4, EXE default setting pc to jar+4+4, which we IR override pc to be jar+4-4+w_imm_j now
                    //at N+1, IF is fetching jar+w_imm_j, EXE bubble, but default still setting pc to be jar+w_imm_j+4
                    //at N+2, jump into jar+w_imm_j
		        pc <= pc - 4 + w_imm_j;  // Jump 
		        if (w_rd != 5'b0) re[w_rd] <= pc;  // Link (if for keep x0 remain 0)
		        bubble <= 1'b1; 
		    end 
	            32'b???????_?????_?????_???_?????_1100111: begin // Jalr
		        if (w_rd != 5'b0) re[w_rd] <= pc; // present pc value is jarl+4
			pc <= (re[w_rs1] + w_imm_i) & 64'hFFFFFFFFFFFFFFFE; // Align with at least 2-bytes compressed instruction.Alert "Misaligned Addr"?
			bubble <= 1'b1; 
		    end 
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
//N+2 execute load:step_0 setting read bubble1 lb_step1
//N+3 bubble branch take over (BUT bus read data into bus_read_data)
//N+4 execute load:step_1 save bus_read_data into re
//Sb
//N+5 save re to bus_write_data
//mret
//N+6 mret (BUT URAT get data for print).   //
// -- 
//in cycle N0, IF fetching sb, EXE ir is lb, bubble is setting 1, pc is re-setting to pc, lb_step is setting to 1;
//in N1, IF fetching lb, Bubble flushed ir sb, bubble <=0, Default pc is setting to lb+4(sb);
//in N2, IF fetching sb, EXE ir is lb, lb_step is 1, bus_read_data is saving to re, lb_step is setting to 0;
//in N3, IF fethcing mret, EXE ir is sb, re is saving to bus_write_data, bus_write_enable is setting to 1;
