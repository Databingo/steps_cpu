// ===========================================================================
// File: board.v
// The absolute simplest test to read from initialized memory and display on LEDs.
// ===========================================================================

module board (
    input wire CLOCK_50,   // 50 MHz system clock
    input wire KEY0,       // Active-low reset button
    output wire [7:0] LEDG // 8 green LEDs
);

    // --- The Memory Block (ROM) ---
    // This will be synthesized into a Block RAM.
    // It is 32-bits wide and has 16 locations for this test.
    (* ram_style = "block" *) reg [31:0] mem [0:15];

    // Initialize the memory from your .mif file at compilation time.
    initial $readmemh("mem.mif", mem);

    // --- The Address Counter ---
    // This simple counter will cycle through addresses 0 to 15.
    // It runs at the full 50 MHz clock speed.
    reg [3:0] addr_counter;

    always @(posedge CLOCK_50) begin
        if (!KEY0) begin          // If the reset button is pressed...
            addr_counter <= 0;    // ...reset the counter to 0.
        end else begin
            addr_counter <= addr_counter + 1; // ...otherwise, count up.
        end
    end

    // --- The Memory Read and LED Display ---
    // This one line does everything:
    // 1. Reads from the 'mem' array at the current 'addr_counter' value.
    // 2. Assigns the lower 8 bits of the data it reads directly to the LED output pins.
    assign LEDG = mem[addr_counter][7:0];

endmodule
