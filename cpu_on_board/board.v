// ===========================================================================
// File: board.v
// Fixed version with working LED blinking
// ===========================================================================

// --- MODULE 1: Robust Clock Divider with Asynchronous Reset ---
module clock_divider(
    input wire clk_in,     // 50 MHz input clock
    input wire reset_n,    // Active-low reset (0 = reset)
    output reg clk_out     // ~1 Hz output clock
);
    // 25-bit counter (needs to count to 25,000,000)
    reg [24:0] counter;
    localparam HALF_PERIOD = 25000000; // For 1 Hz clock (50MHz/50e6 = 1Hz)

    // Asynchronous reset with synchronous behavior
    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 0;
            clk_out <= 1'b0;
        end else begin
            if (counter == HALF_PERIOD - 1) begin
                counter <= 0;
                clk_out <= ~clk_out; // Toggle clock
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule


// --- MODULE 2: The Top-Level Board with Reset Fix ---
module board (
    input wire CLOCK_50,   // 50 MHz clock
    input wire KEY0,       // Active-low reset (0 = reset)
    output wire [7:0] LEDG // 8 green LEDs
);
    wire clk_slow;         // Slow clock (1 Hz)
    wire reset_sync;       // Synchronized reset signal
    
    // Reset synchronizer to avoid metastability
    reg [1:0] reset_sync_reg;
    always @(posedge CLOCK_50) begin
        reset_sync_reg <= {reset_sync_reg[0], KEY0};
    end
    assign reset_sync = reset_sync_reg[1];
    
    // Instantiate clock divider with proper reset
    clock_divider clk_inst (
        .clk_in(CLOCK_50),
        .reset_n(reset_sync),
        .clk_out(clk_slow)
    );

    // --- ROM Memory Block ---
    (* ram_style = "block" *) reg [31:0] mem [0:15];
    initial $readmemh("mem.mif", mem);

    // --- Address Counter with Synchronous Reset ---
    reg [3:0] addr_counter;
    always @(posedge clk_slow) begin
        if (!reset_sync) begin   // Use synchronized reset
            addr_counter <= 0;
        end else begin
            addr_counter <= addr_counter + 1;
        end
    end

    // --- Memory Read ---
    wire [31:0] mem_data_out;
    assign mem_data_out = mem[addr_counter];
    
    // --- LED Output ---
    assign LEDG = mem_data_out[7:0];

endmodule
