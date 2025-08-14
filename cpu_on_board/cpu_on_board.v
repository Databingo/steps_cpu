module cpu_on_board (
    (* chip_pin = "PIN_L1" *)  input wire CLOCK_50, // 50 MHz clock
    (* chip_pin = "PIN_R22" *) input wire KEY0,     // Active-low reset button
    (* chip_pin = "PIN_U22, PIN_U21, PIN_V22, PIN_V21, PIN_W22, PIN_W21, PIN_Y22, PIN_Y21" *) output reg [7:0] LEDG // 8 green LEDs
    (* chip_pin = "PIN_U22, PIN_U21, PIN_V22, PIN_V21, PIN_W22, PIN_W21, PIN_Y22, PIN_Y21" *) output reg [7:0] LEDG // 8 red LEDs
    (* chip_pin = "PIN_R20, PIN_R19, PIN_U19, PIN_Y19, PIN_T18, PIN_V19, PIN_Y18, PIN_U18, PIN_R18, PIN_R17" *) output reg [9:0] LEDR // 10 red LEDs  

);
    (* ram_style = "block" *) reg [63:0] mem [0:2999]; // Unified Memory
    initial $readmemh("mem.mif", mem);

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
		LEDR <= mem[9:0];
            end else begin
                counter <= counter + 1;
            end
        end
    end




endmodule
