// ===========================================================================
// File: board.v
// The absolute simplest test to verify memory initialization and reading.
// This design uses a simple counter to read addresses sequentially from a
// ROM and displays the contents directly on the LEDs.
// ===========================================================================

// --- MODULE 1: A Simple Clock Divider ---
// This creates a slower clock to make the LED changes visible.
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
// This connects the clock divider, a simple address counter,
// the memory, and the LEDs.
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
    // This will be synthesized into a Block RAM, initialized at compile time.
    // It is 32-bits wide and has 16 locations for this test.
    (* ram_style = "block" *) reg [31:0] mem [0:15];
    initial $readmemh("mem.mif", mem);

    // --- The Address Counter ---
    // This simple counter will act as our "Program Counter" for the test.
    // It will count from 0 to 15 and then repeat.
    reg [3:0] addr_counter;
    always @(posedge clk_slow or negedge KEY0) begin
        if (!reset_n) begin
            addr_counter <= 0;
        end else begin
            addr_counter <= addr_counter + 1;
        end
    end

    // --- The Memory Read ---
    // This is a simple combinational read. The data from memory
    // is instantly available based on the current address counter.
    wire [31:0] mem_data_out;
    assign mem_data_out = mem[addr_counter];
    
    // --- The LED Display ---
    // Directly connect the lower 8 bits of the data read from memory to the LEDs.
    assign LEDG = mem_data_out[7:0];

endmodule
