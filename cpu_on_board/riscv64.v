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
    output reg [63:0] bus_write_data,
    output reg        bus_write_enable,
    output reg        bus_read_enable,

    input  wire [63:0] bus_read_data   // from outside
);
    // -- CSR Registers --
    reg [63:0] csr [0:4096]; // Maximal 12-bit length = 4096
    //integer mstatus = 12'h300;      // 0x300 MRW Machine status reg   // 63_SD|37_MBE|36_SBE|35:34_SXL10|22_TSR|21_TW|20_TVW|17_MPRV|12:11_MPP10|7_MPIE|3_MIE|1_SIE|0_WPRI
    integer mie = 12'h304;          // 0x304 MRW Machine interrupt-enable register *
    integer mip = 12'h344;          // 0x344 MRW Machine interrupt pending *
    integer mtvec = 12'h305;        // 0x305 MRW Machine trap-handler base address *
    integer mcause = 12'h342;       // 0x342 MRW Machine trap casue *
    integer mepc = 12'h341;         // 0x341 MRW Machine exception program counter *

    // -- CSR Bits --
    //wire mstatus_MIE = csr[mstatus][3]; // Machine Interrupt Enable
    wire mstatus_MIE = mstatus[3]; // Machine Interrupt Enable
    //wire mstatus_MPIE = csr[mstatus][7]; // 
    //wire mie_MEIE = csr[mie][11];
    //wire mip_MEIP = csr[mie][11];
    //reg [31:0] mepc; // Machine Exception Program Counter
    reg [63:0] mstatus; // Machine Exception Program Counter
 
    // -- Immediate decoders  -- 
    wire signed [63:0] w_imm_u = {{32{ir[31]}}, ir[31:12], 12'b0};
    wire [4:0] w_rd  = ir[11:7];

    // -- Innerl signal --
    reg interrupt_pending;  
    reg bubble;
    reg lb_step;
    reg sb_step;

    // IF
    always @(posedge clk or negedge reset) begin
        if (!reset) begin 
            heartbeat <= 1'b0; 
            ir <= 32'h00000001; 
	    csr[mstatus][3] <= 1'b1;
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
            sb_step <= 0;
	    bus_read_enable <= 0;
	    bus_write_enable <= 0;
	    bus_write_data <= 0;
	    bus_address <= `Ram_base;
            // Interrupt reset
	    //interrupt_pending <= 0;
	    interrupt_ack <= 0;

        end else begin
	    // Default PC+4    (1.Could be overide 2.Take effect next cycle) 
            pc <= pc + 4;
	    interrupt_ack <= 0;

            // Interrupt
	    //if (interrupt_vector == 1 && interrupt_pending !=1) begin
	    if (interrupt_vector == 1 && mstatus_MIE == 1) begin
	        //mepc <= pc; // save pc
	        csr[mepc] <= pc; // save pc
		csr[mcause] <= 64'h800000000000000B; // MSB 1 for Interrupts 0 for exceptions, Casue = 11 (Machine External Interrupt)
		//csr[mstatus][7] <= csr[mstatus][3]; // mstatus.MPIC = mstatus.MIE
		//csr[mstatus][3] <= 1'b0; //mstatus.MIE = 0
		mstatus[7] <= mstatus[3]; // mstatus.MPIC = mstatus.MIE
		mstatus[3] <= 1'b0; //mstatus.MIE = 0
		//pc <= {csr[mtvec][63:2], 2'b00} // jump to dispatch handler(which save contect to stack & read mcause to choose ISR)
                pc <= 0; // jump to ISR addr


		bubble <= 1'b1; // bubble wrong fetched instruciton by IF
	        //interrupt_pending <= 1;
		interrupt_ack <= 1; // reply to outside

            // Bubble
	    end else if (bubble) bubble <= 1'b0; // Flush this cycle & Clear bubble signal for the next cycle

	    // IR
	    else begin 
	        bus_read_enable <= 0;
	        bus_write_enable <= 0; 
	        bus_write_data <= 0;
	        bus_address <= `Ram_base;
                casez(ir) 
	            32'b???????_?????_?????_???_?????_0110111:  re[w_rd] <= w_imm_u; // Lui
	            32'b0000000_00000_00000_000_00000_0000000: begin // Mret 
	                //pc <= mepc; bubble <= 1; interrupt_pending <= 0; end 
		        //csr[mstatus][3] <= csr[mstatus][7]; // mstatus.MIE = mstatus.MPIC 
		        //csr[mstatus][7] <= 1'b1; //mstatus.MIE = 1
		        //mstatus[3] <= mstatus[7]; // mstatus.MIE = mstatus.MPIC 
		        //mstatus[7] <= 1'b1; //mstatus.MIE = 1
			//pc <= csr[mepc];
			bubble <= 1; 
		        end
	            32'b1111111_11111_11111_111_11111_1111111: begin // Load  3 cycles to finish re<=data
	                if (lb_step == 0) begin
	                    bus_address <= `Key_base; // cycle 1 setting read enable
	                    bus_read_enable <= 1;
	                    pc <= pc - 4;
	                    bubble <= 1; //!! take over cycle 2, meanwhile bus read 
	                    lb_step <= 1;
	                end
	                if (lb_step == 1) begin  
	                    re[5]<= bus_read_data; // cycle 3 save to cpu's register
	                    lb_step <= 0;
	                end
	            end
	            32'b1111111_11111_11111_111_11110_1111111: begin // Store 1 cycles to finish settting data<=re (next cycle bus write to data)
		        if (sb_step == 0) begin 
		            bus_address <= `Art_base;
	                    bus_write_data <= re[5];
	                    bus_write_enable <= 1;
			end
	            end
                endcase
	    end
        end
    end

endmodule

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
