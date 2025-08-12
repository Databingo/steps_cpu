// ===========================================================================
// File: fetch_test.v
// A simple test to verify memory initialization and reading.
// This version has the corrected reset signal name.
// ===========================================================================

// --- MODULE 1: A Simple Clock Divider ---
module clock_divider(
    input wire clk_in,
    input wire reset_n,
    output reg clk_out
);
    reg [23:0] counter = 0;
    localparam MAX_COUNT = 25000000 - 1; // For a ~1 Hz clock from 50 MHz input

    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 0;
            clk_out <= 1'b0;
        end else begin
            if (counter == MAX_COUNT) begin
                counter <= 0;
                clk_out <= ~clk_out;
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
        .reset_n(KEY0), // Correctly passing KEY0 to the divider's reset
        .clk_out(clk_slow)
    );

    // --- The Memory Block (ROM) ---
    (* ram_style = "block" *) reg [31:0] mem [0:15];
    initial $readmemh("mem.mif", mem);

    // --- The Address Counter ---
    reg [3:0] addr_counter;
    always @(posedge clk_slow or negedge KEY0) begin
        // --- THE FIX IS HERE ---
        // Changed `!reset_n` to `!KEY0` to match the module's input port name.
        if (!KEY0) begin
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
