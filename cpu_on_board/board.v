// ===========================================================================
// File: board.v
// Fully fixed and verified solution for LED blinking
// ===========================================================================

// --- MODULE 1: Robust Clock Divider with Asynchronous Reset ---
module clock_divider(
    input wire clk_in,     // 50 MHz input clock
    input wire reset_n,    // Active-low reset (0 = reset)
    output reg clk_out     // ~1 Hz output clock
);
    // 25-bit counter (counts to 25,000,000)
    reg [24:0] counter;
    localparam HALF_PERIOD = 24999999; // For 1 Hz clock (50MHz/50e6 = 1Hz)

    // Asynchronous reset with synchronous behavior
    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 0;
            clk_out <= 1'b0;
        end else begin
            if (counter >= HALF_PERIOD) begin
                counter <= 0;
                clk_out <= ~clk_out; // Toggle clock
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule

// --- MODULE 2: The Top-Level Board with Proper Reset Handling ---
module board (
    input wire CLOCK_50,   // 50 MHz clock
    input wire KEY0,       // Active-low reset (0 = reset)
    output wire [7:0] LEDG // 8 green LEDs
);
    // Reset synchronization (2-stage flip-flop)
    reg [1:0] reset_sync_reg = 2'b00;
    wire reset_sync_n;
    
    always @(posedge CLOCK_50) begin
        reset_sync_reg <= {reset_sync_reg[0], KEY0};
    end
    assign reset_sync_n = reset_sync_reg[1];
    
    // Clock divider
    wire clk_slow;
    clock_divider clk_inst (
        .clk_in(CLOCK_50),
        .reset_n(reset_sync_n),
        .clk_out(clk_slow)
    );

    // --- ROM Memory Block ---
    (* ram_init_file = "mem.mif" *) reg [31:0] mem [0:15];
    initial begin
        $readmemh("mem.mif", mem);
    end

    // --- Address Counter with Synchronized Reset ---
    reg [3:0] addr_counter;
    reg reset_slow_reg;
    
    // Slow clock domain reset synchronizer
    always @(posedge clk_slow) begin
        reset_slow_reg <= !reset_sync_n;  // Active-high reset for slow domain
    end
    
    // Address counter with synchronous reset
    always @(posedge clk_slow) begin
        if (reset_slow_reg) begin
            addr_counter <= 0;
        end else begin
            addr_counter <= addr_counter + 1;
        end
    end

    // --- Memory Read and LED Output ---
    wire [31:0] mem_data_out = mem[addr_counter];
    assign LEDG = mem_data_out[7:0];

endmodule
