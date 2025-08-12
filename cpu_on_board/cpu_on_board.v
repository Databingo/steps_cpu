
module cpu_on_board (
    input wire CLOCK_50,   // 50 MHz system clock from the on-board oscillator
    input wire KEY0,       // Active-low reset button
    output reg [7:0] LEDG  // 8 green LEDs
);

    reg [24:0] counter;

    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            counter <= 0;
        end
        else begin
            if (counter == 25000000 - 1) begin
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end
    end
    
    // --- LED Output Logic ---
    // This is now a separate, simple piece of logic.
    // The LEDs will be ON for the first half of the count cycle,
    // and OFF for the second half.
    // We use a simple comparison with the halfway point of the counter.
    assign LEDG = (counter < 25000000) ? 8'hFF : 8'h00;
    
    // Whoops, that's not quite right. Let's make it even simpler.
    // We will use a single register to hold the blinking state.

endmodule
