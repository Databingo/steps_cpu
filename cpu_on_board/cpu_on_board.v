
module cpu_on_board (
    //input wire CLOCK_50,   // 50 MHz system clock from the on-board oscillator
    //input wire KEY0,       // Active-low reset button
    //output reg [7:0] LEDG  // 8 green LEDs
    (* chip_pin = "PIN_L1" *) input wire CLOCK_50，
    (* chip_pin = "PIN_R22" *) input wire KEY0，
    (* chip_pin = "PIN_R22, PIN_U22, PIN_U21, PIN_V22, PIN_V21, PIN_W22, PIN_W21, PIN_Y22, PIN_Y21" *) output reg [7:0] LEDG
);

    reg [24:0] counter;

    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            counter <= 0;
	    LEDG <= 8'h00;
        end
        else begin
            if (counter == 25000000 - 1) begin
                counter <= 0;
		LEDG <= ~LEDG;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule
