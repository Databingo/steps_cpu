`include "header.vh"

module riscv64(
    input wire clk, 
    input wire reset,     // Active-low reset button
    input wire [31:0] instruction,
    //output reg [31:0] pc = 44,
    output reg [63:0] pc,// = 32'h1000,
    output reg [31:0] ir,
    output reg [63:0] re [0:31],
    output wire  heartbeat,

    input  reg [3:0] interrupt_vector,
    output reg  interrupt_pending,
    output reg  interrupt_ack,

    output reg [63:0] bus_addr,

    output reg [63:0] bus_address,  // 48 bit for real standard?
    output reg [63:0] bus_write_data,
    output reg        bus_write_enable,
    output reg        bus_read_enable,
    input  wire [63:0] bus_read_data


);
    // -- CSR Registers --
    reg [63:0] csr [0:4096]; // Maximal 12-bit length = 4096
    integer mstatus = 12'h300;      // 0x300 MRW Machine status reg   // 63_SD|37_MBE|36_SBE|35:34_SXL10|22_TSR|21_TW|20_TVW|17_MPRV|12:11_MPP10|7_MPIE|3_MIE|1_SIE|0_WPRI
    integer mie = 12'h304;          // 0x304 MRW Machine interrupt-enable register *
    integer mip = 12'h344;          // 0x344 MRW Machine interrupt pending *
    integer mtvec = 12'h305;        // 0x305 MRW Machine trap-handler base address *
    integer mcause = 12'h342;       // 0x342 MRW Machine trap casue *
    // -- CSR Bits --
    wire mstatus_MIE = csr[mstatus][3];
    wire mie_MEIE = csr[mie][11];
    wire mip_MEIP = csr[mie][11];
 
    
    // -- Immediate decoders (Unchanged) -- 
    wire signed [63:0] w_imm_u = {{32{ir[31]}}, ir[31:12], 12'b0};
    wire [4:0] w_rd  = ir[11:7];
    // -- Bubble signal --
    reg bubble;
    reg lb_step;
    reg sb_step;
    reg [31:0] mepc; 



    // IF ir (Unchanged)
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
            sb_step <= 0;
	    bus_read_enable <= 0;
	    bus_write_enable <= 0;
	    bus_write_data <= 0;
	    bus_address <= `Ram_base;
            // Interrupt reset
	    interrupt_pending <= 0;
	    interrupt_ack <= 0;

        end else begin

	    // PC default +4    (1.Could be overide 2.Take effect next cycle) 
            pc <= pc + 4;
	    interrupt_ack <= 0;

            // Interrupt
	    if (interrupt_vector == 1 && interrupt_pending !=1) begin
	        mepc <= pc; // save pc
                pc <= 0; // jump to ISR addr
		bubble <= 1'b1; // bubble wrong fetched instruciton by IF
	        interrupt_pending <= 1;
		interrupt_ack <= 1;

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
	                pc <= mepc; bubble <= 1; interrupt_pending <= 0; end 
	            32'b1111111_11111_11111_111_11111_1111111: begin // Load  3 cycles to finish re<=data
	                if (lb_step == 0) begin
	                    bus_address <= `Key_base; // cycle 1 setting read enable
	                    bus_read_enable <= 1;
	                    pc <= pc;
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
