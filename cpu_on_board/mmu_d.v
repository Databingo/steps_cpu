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
    output reg [63:0] pa
);
always @(posedge clk or negedge rst) begin
    if (!rst) 
	pa <= 0;
    else begin
	pa <= va +1;
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
