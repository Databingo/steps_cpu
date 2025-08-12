// ===========================================================================
// File: board.v
// The absolute simplest test to verify memory initialization and reading.
// This version uses a robust clocking and reset scheme.
// ===========================================================================

// --- MODULE 1: A Robust Clock Divider ---
module clock_divider(
    input wire clk_in,
    input wire reset_n,
    output reg clk_out
);
    reg [23:0] counter;
    localparam HALF_PERIOD = 25000000; // For a ~1 Hz clock

    always @(posedge clk_in) begin
        if (!reset_n) begin
            counter <= 0;
            clk_out <= 1'b0;
        end else begin
            if (counter == HALF_PERIOD - 1) begin
                counter <= 0;
                clk_out <= ~clk_out; // Toggle the clock
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule


// --- MODULE 2: The Top-Level Board ---
module Board (
    input wire CLOCK_50,
    input wire KEY0,       // Active-low reset
    output wire [7:0] LEDG // 8 green LEDs
);
    
    wire clk_slow;
    clock_divider clk_inst (
        .clk_in(CLOCK_50),
        .reset_n(KEY0),
        .clk_out(clk_slow)
    );

    // --- The Memory Block (ROM) ---
    (* ram_style = "block" *) reg [31:0] mem [0:15];
    initial $readmemh("mem.mif", mem);

    // --- The Address Counter with SYNCHRONOUS RESET ---
    reg [3:0] addr_counter;
    always @(posedge clk_slow) begin
        if (!KEY0) begin // Check reset on the clock edge
            addr_counter <= 0;
        end else begin
            addr_counter <= addr_counter + 1;
        end
    end

    // --- The Memory Read ---
    wire [31:0] mem_data_out;
    assign mem_data_out = mem[addr_counter];
    
    // --- The LED Display ---
    assign LEDG = mem_data_out[7:0];

endmodule
