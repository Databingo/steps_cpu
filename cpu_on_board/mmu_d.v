// satp: Room address
// vpn2: Shelf number in Room
// vpn1: Book number in Shelf
// vpn0: Page number in Book
// each table contain 512 entries(PTEs) per 8 bytes(64 bits). 8*512=4096 4KB per Page


module mmu_d (
    // MMU-D SV39
    input wire clk,
    input wire reset,
    input wire [63:0] va,
    input sfence,
    input priv_s,
    input wire [63:0] satp,
    output reg [63:0] pa,
    output reg valid,
    output reg tlb_hit
    );

    parameter PAGE_OFFSET_BITS = 12;
    parameter VPN_BITS = 20;
    parameter TLB_ENTRIES = 8; //small tlb
    wire [VPN_BITS-1:0] vpn = va[31:12];
    wire [PAGE_OFFSET_BITS-1:0] offset = va[11:0];
    // VPN
    wire [8:0] vpn2 = va[38:30];
    // TLB
    reg [VPN_BITS-1:0] tlb_vpn [0:TLB_ENTRIES-1];
    reg [19:0] tlb_ppn [0:TLB_ENTRIES-1];
    reg  tlb_valid [0:TLB_ENTRIES-1];
    reg  tlb_u [0:TLB_ENTRIES-1]; // user/supervisor bit

    integer i;
    reg [2:0] tlb_replace_index;
                
    always @(posedge clk or negedge reset) begin
	if (!reset) begin
	    valid <=0; tlb_hit<=0; tlb_replace_index<=0;
	    for (i=0;i<TLB_ENTRIES;i=i+1) tlb_valid[i]<=0;
	end else if (sfence) begin
	    for (i=0;i<TLB_ENTRIES;i=i+1) tlb_valid[i]<=0; // Flush all TLB entries
	end else begin
	    valid <=0;
	    tlb_hit<=0; // Search
	    for (i=0;i<TLB_ENTRIES;i=i+1) begin
		if (tlb_valid[i] && tlb_vpn[i]==vpn) begin
		    if (!priv_s && !tlb_u[i]) begin
			valid <=0;
		    end	else begin
			pa <= {tlb_ppn[i], offset};
			valid <= 1;
			tlb_hit <=1;
	                //mmu <= 1;
		    end
	        end
	    end
	    if (!tlb_hit) begin
	    end
        end
    end

endmodule



//---------------------------------------------
// Simple Bus-Connected MMU + TLB (SV39-style)
//---------------------------------------------
module mmu_tlb (
    input               clk,
    input               rstn,

    // from CPU
    input       [63:0]  va,           // virtual address
    input               valid_in,     // request valid
    input               priv_s,       // 1 = supervisor mode
    output reg  [63:0]  pa,           // physical address output
    output reg          valid_out,    // translation complete
    output reg          tlb_hit,

    // from CSR (satp)
    input       [63:0]  satp,         // root page table physical address (PPN)

    // SFENCE flush
    input               sfence_vma,

    // memory bus interface (to system RAM)
    output reg  [63:0]  bus_addr,
    output reg          bus_read,
    input       [63:0]  bus_rdata,
    input               bus_ready
);

    //--------------------------------------------
    // Parameters
    //--------------------------------------------
    parameter PAGE_OFFSET_BITS = 12;
    parameter VPN_BITS = 27;          // SV39 = 9 * 3 levels = 27
    parameter TLB_ENTRIES = 8;

    //--------------------------------------------
    // VA breakdown
    //--------------------------------------------
    wire [8:0] vpn2 = va[38:30];
    wire [8:0] vpn1 = va[29:21];
    wire [8:0] vpn0 = va[20:12];
    wire [11:0] offset = va[11:0];

    //--------------------------------------------
    // TLB
    //--------------------------------------------
    reg [26:0] tlb_vpn [0:TLB_ENTRIES-1];
    reg [43:0] tlb_ppn [0:TLB_ENTRIES-1];
    reg        tlb_valid [0:TLB_ENTRIES-1];
    integer i;
    reg [2:0] tlb_replace_index;

    //--------------------------------------------
    // FSM for page walk
    //--------------------------------------------
    reg [2:0] state;
    localparam IDLE = 0, READ_L2 = 1, READ_L1 = 2, READ_L0 = 3, DONE = 4;

    reg [63:0] pte;
    reg [63:0] root_ppn;
    reg [63:0] walk_addr;
    reg [43:0] found_ppn;

    //--------------------------------------------
    // Initialization
    //--------------------------------------------
    initial begin
        for (i = 0; i < TLB_ENTRIES; i = i + 1) tlb_valid[i] = 0;
        tlb_replace_index = 0;
    end

    //--------------------------------------------
    // MMU core logic
    //--------------------------------------------
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_out <= 0;
            tlb_hit <= 0;
            state <= IDLE;
        end else if (sfence_vma) begin
            for (i = 0; i < TLB_ENTRIES; i = i + 1)
                tlb_valid[i] <= 0; // flush
        end else begin
            valid_out <= 0;
            tlb_hit <= 0;
            bus_read <= 0;

            case (state)
                //----------------------------------------
                IDLE: begin
                    if (valid_in) begin
                        // First, search the TLB
                        for (i = 0; i < TLB_ENTRIES; i = i + 1) begin
                            if (tlb_valid[i] && tlb_vpn[i] == va[38:12]) begin
                                pa <= {tlb_ppn[i], offset};
                                valid_out <= 1;
                                tlb_hit <= 1;
                            end
                        end

                        // If not hit, begin walking
                        if (!tlb_hit) begin
                            root_ppn <= satp[43:0];
                            walk_addr <= {satp[43:0], 12'b0} + vpn2 * 8;
                            bus_addr <= {satp[43:0], 12'b0} + vpn2 * 8;
                            bus_read <= 1;
                            state <= READ_L2;
                        end
                    end
                end

                //----------------------------------------
                READ_L2: begin
                    if (bus_ready) begin
                        pte <= bus_rdata;
                        walk_addr <= {bus_rdata[53:10], 12'b0} + vpn1 * 8;
                        bus_addr <= {bus_rdata[53:10], 12'b0} + vpn1 * 8;
                        bus_read <= 1;
                        state <= READ_L1;
                    end
                end

                //----------------------------------------
                READ_L1: begin
                    if (bus_ready) begin
                        pte <= bus_rdata;
                        walk_addr <= {bus_rdata[53:10], 12'b0} + vpn0 * 8;
                        bus_addr <= {bus_rdata[53:10], 12'b0} + vpn0 * 8;
                        bus_read <= 1;
                        state <= READ_L0;
                    end
                end

                //----------------------------------------
                READ_L0: begin
                    if (bus_ready) begin
                        pte <= bus_rdata;
                        found_ppn <= bus_rdata[53:10];

                        // update TLB
                        tlb_vpn[tlb_replace_index] <= va[38:12];
                        tlb_ppn[tlb_replace_index] <= bus_rdata[53:10];
                        tlb_valid[tlb_replace_index] <= 1;
                        tlb_replace_index <= tlb_replace_index + 1;

                        pa <= {bus_rdata[53:10], offset};
                        valid_out <= 1;
                        state <= DONE;
                    end
                end

                //----------------------------------------
                DONE: begin
                    valid_out <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
