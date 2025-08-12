
// ===========================================================================
// File: board.v
// Simple LED blink pattern from memory
// ===========================================================================

// --- MODULE 1: Millisecond-Based Clock Divider ---
module clock_divider #(
    parameter CLK_FREQ_HZ = 50_000_000, // input clock frequency
    parameter BLINK_MS    = 200         // toggle period in milliseconds
)(
    input  wire clk_in,
    input  wire reset_n,  // active-low reset
    output reg  clk_out
);
    // Number of cycles for half-period
    localparam HALF_PERIOD = (CLK_FREQ_HZ / 1000) * (BLINK_MS / 2);
    reg [$clog2(HALF_PERIOD)-1:0] counter;

    always @(posedge clk_in) begin
        if (!reset_n) begin
            counter <= 0;
            clk_out <= 1'b0;
        end else begin
            if (counter == HALF_PERIOD - 1) begin
                counter <= 0;
                clk_out <= ~clk_out; // Toggle output clock
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule

// --- MODULE 2: Top-Level Board ---
module board (
    input  wire CLOCK_50,  // 50 MHz clock
    input  wire KEY0,      // Active-low reset
    output wire [7:0] LEDG // Green LEDs
);
    wire clk_slow;

    // Slow clock for LED updates
    clock_divider #(
        .CLK_FREQ_HZ(50_000_000),
        .BLINK_MS(200) // pattern change every 200 ms
    ) clk_inst (
        .clk_in(CLOCK_50),
        .reset_n(KEY0),
        .clk_out(clk_slow)
    );

    // Memory block with LED patterns
    (* ram_style = "block" *) reg [31:0] mem [0:15];
    initial $readmemh("mem.hex", mem); // Use .hex file format

    // Address counter
    reg [3:0] addr_counter;
    always @(posedge clk_slow) begin
        if (!KEY0)
            addr_counter <= 0;
        else
            addr_counter <= addr_counter + 1;
    end

    // Output from memory
    wire [31:0] mem_data_out;
    assign mem_data_out = mem[addr_counter];

    // Drive LEDs
    assign LEDG = mem_data_out[7:0];
endmodule
