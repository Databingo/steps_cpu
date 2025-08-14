module cpu_on_board (
    (* chip_pin = "PIN_L1" *)  input wire CLOCK_50, // 50 MHz clock
    (* chip_pin = "PIN_R22" *) input wire KEY0,     // Active-low reset button
    (* chip_pin = "PIN_Y21, PIN_Y22, PIN_W21, PIN_W22, PIN_V21, PIN_V22, PIN_U21, PIN_U22" *) 
    output reg [7:0] LEDG, // 8 green LEDs
    (* chip_pin = "R20" *) output reg LEDR0 // 2 red LEDs  
    //(* chip_pin = "PIN_U22, PIN_U21, PIN_V22, PIN_V21, PIN_W22, PIN_W21, PIN_Y22, PIN_Y21" *) 
    //(* chip_pin = "PIN_R17, PIN_R18, PIN_U18, PIN_Y18, PIN_V19, PIN_T18, PIN_Y19, PIN_U19, PIN_R19, PIN_R20" *) output reg [9:0] LEDR // 10 red LEDs  
    //(* chip_pin = "R17, R18, U18, Y18, V19, T18, Y19, U19, R19, R20" *) output reg [9:0] LEDR // 10 red LEDs  
);

  
    (* ram_style = "block" *) reg [31:0] mem [0:2999]; // Unified Memory
    //initial $readmemh("mem.mif", mem);
    initial $readmemb("mem.mif", mem);

    reg [24:0] counter;
    reg [4:0] addr_pc;


    always @(posedge CLOCK_50 or negedge KEY0) begin
        if (!KEY0) begin
            counter <= 0;
	        LEDG <= 8'h00;
		LEDR0 <= 1'b0;
        end
        else begin
            if (counter == 25000000 - 1) begin
                counter <= 0;
	        //LEDG <= ~LEDG;
	        LEDR0 <= ~LEDR0; // heartbeat
	        LEDG <= mem[addr_pc][7:0];
		addr_pc <= addr_pc + 1;
            end else begin
                counter <= counter + 1;
            end
        end
    end




endmodule
