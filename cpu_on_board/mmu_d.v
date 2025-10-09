    // MMU-D SV39
    wire [63:0] va 
    reg  [63:0] pa;
    reg tlb_hit;
    reg valid;
    reg sfentce;
    reg priv_s;

    parameter PAGE_OFFSET_BITS = 12;
    parameter VPN_BITS = 20;
    parameter TLB_ENTRIES = 8; //small tlb
    wire [VPN_BITS-1:0] vpn = va[31:12];
    wire [PAGE_OFFSET_BITS-1:0] offset = va[11:0];
    // VPN
    wire [8:0] vpn2 = va[38:30]
    // TLB
    reg [VPN_BITS-1:0] tlb_vpn [0:TLB_ENTRIES-1]
    reg [19:0] tlb_ppn [0:TLB_ENTRIES-1]
    reg  tlb_valid [0:TLB_ENTRIES-1]
    reg  tlb_u [0:TLB_ENTRIES-1] // user/supervisor bit



    integer i;
    reg [2:0] tlb_replace_index;

    always @(posedge CLOCK_50) begin
	if (!reset) begin
	    valid <=0; tlb_hit<=0,tlb_replace_index<=0;
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
			pa <= {tlb_ppn[i], offset}
			valid <= 1;
			tlb_hit <=1;
	                mmu <= 1
		    end
	        end
	    end
	    if (!tlb_hit) begin
	    end
        end
    end
