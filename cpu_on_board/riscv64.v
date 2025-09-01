module riscv64(
    input wire clk, 
    input wire reset,     // Active-low reset button
    input wire [31:0] instruction,
    output reg [31:0] pc = 44,
    output reg [31:0] ir,
    output reg [63:0] re [0:31],
    output wire  heartbeat,

    input wire [3:0] interrupt_vector,
    //output reg interrupt_done,

    output reg [63:0] bus_address,
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
    reg interrupt_pending = 0;
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
            pc <= 44; //
	    lb_step <= 0;
            // Interrupt reset
	    bus_read_enable <= 0;
	    bus_write_enable <= 0;
        end else begin
	    bus_write_enable <= 0; 
	    // PC default +4 (1.Could be overide 2.Take effect next cycle) 
            pc <= pc + 4;

            // Interrupt
	    if (interrupt_vector == 1 && interrupt_pending !=1) begin
		    ir <= 32'b0000000_00000_00000_000_00000_0000000;
		    mepc <= pc; // save pc
                    pc <= 0; // jump to ISR addr
		    bubble <= 1'b1; // bubble wrong fetche instruciton by IF
	            interrupt_pending <= 1;

            // Bubble
	    end else if (bubble) bubble <= 1'b0; // Flush this cycle & Clear bubble signal for the next cycle

	    // IR
	    else begin 
            casez(ir) 
		// Lui
		32'b???????_?????_?????_???_?????_0110111:  re[w_rd] <= w_imm_u;
		// Mret 
		32'b0000000_00000_00000_000_00000_0000000: begin 
		    pc <= mepc; 
		    bubble <= 1; 
		end 
                // Load
	        32'b1111111_11111_11111_111_11111_1111111: begin
	            bus_address <= 32'h8000_0000; // Art_base ;
	            bus_write_data <= 32'h41;
	            bus_write_enable <= 1;
	            interrupt_pending <= 0;
	        end
                // Store
            endcase
	    end
        end
    end

endmodule
