// ===========================================================================
// File: board.v
// Fixed version with working LED blinking
// ===========================================================================

// --- MODULE 1: Fixed Clock Divider ---
module clock_divider(
    input wire clk_in,     // 50 MHz input clock
    input wire reset_n,    // Active-low reset
    output reg clk_out     // ~1 Hz output clock
);
    // Use 25-bit counter (needs to count to 25,000,000)
    reg [24:0] counter;
    localparam HALF_PERIOD = 25000000; // For 1 Hz clock (50MHz/50e6 = 1Hz)

    always @(posedge clk_in) begin
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


// --- MODULE 2: The Top-Level Board ---
module board (
    input wire CLOCK_50,   // 50 MHz clock
    input wire KEY0,       // Active-low reset (0 = reset)
    output wire [7:0] LEDG // 8 green LEDs
);
    wire clk_slow;         // Slow clock (1 Hz)
    
    // Instantiate clock divider with 25-bit counter
    clock_divider clk_inst (
        .clk_in(CLOCK_50),
        .reset_n(KEY0),
        .clk_out(clk_slow)
    );

    // --- ROM Memory Block ---
    (* ram_style = "block" *) reg [31:0] mem [0:15];
    initial $readmemh("mem.mif", mem);

    // --- Address Counter with Synchronous Reset ---
    reg [3:0] addr_counter;
    always @(posedge clk_slow) begin
        if (!KEY0) begin         // Active-low reset check
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
