// satp: Room address
// vpn2: Shelf number in Room
// vpn1: Book number in Shelf
// vpn0: Page number in Book
// each table contain 512 entries(PTEs) per 8 bytes(64 bits). 8*512=4096 4KB per Page
// satp Mode63:60 1 sv39||43:0 RootPageTable's physical page number X
// VA 25|9vpn2|9vpn1|9vpn0|12offset
// RootPageTable address = X*4KB
`timescale 1ns / 1ps


module mmu(
    input wire clk,
    input wire rst,
    input wire [63:0] satp,
    input wire [63:0] va,
    //input wire start, 



    output reg mmu_walking, // bus_read_enable || bus_write_enable, mmu using SDRAM
    output reg [63:0] pa,
    //output reg done
      
output reg [21:0] mmu_sdram_addr,
output reg [1:0] mmu_sdram_byte_en,
output reg mmu_sdram_read_en,
output reg [15:0] mmu_sdram_rddata,
output reg mmu_sdram_req_wait
      
);

wire [8:0] vpn [0:2];
assign vpn[2] = va[38:30]; // offset in page
assign vpn[1] = va[29:21];
assign vpn[0] = va[20:12];

reg [1:0] level;
reg [43:0] active_ppn;
reg state; // 0=IDLE; 1=WALKING

assign mmu_sdram_byte_en = 2'b11;



always @(posedge clk or negedge rst) begin
    if (!rst) begin
	pa <= 0;
        mmu_walking <= 0;
	state <= 0;
	level <= 2;
	active_ppn <= 0;
    end
    else begin
	if (mmu_walking) begin
	    case(state) begin
		0: begin
                   pa <= va +1;
		   active_ppn <= satp[43:0]; // load Root Table
		   level <= 2; // vpn2
		   state <=1;
	        end
		1: begin
		   addr <= {active_ppn, 12'b0} + (vpn[level] << 3); // addr = (PPN * 4096) + (vpn[level] * 8)
		   data <= sdram[addr];
		   if data[3;1] !=0 || level == 0) begin
		       pa <= {data[53:10], va[11:0]};
		       state <= 0; // done
		       mmu_walking <= 0;
		   end else begin
		       active_ppn <= data[53:10];
		       level <= level-1;
		   end
		end
	    endcase
	end
    end
end









`ifdef TEST
    initial begin
	force clk=0;
	forever begin
	    #10 force clk=1;
	    #10 force clk=0;
	end
    end

    integer i;
    initial begin
        force rst=0;
        force va=0;
        #30 force rst=1;
        for (i=0;i<20;i=i+1) begin
    	    force va = (i+1)*64'h1000;
    	    @(posedge clk); #1;
    	    $display(" %4t | %h | %h", $time, va, pa);
        end
        $finish;
    end
`endif
endmodule
