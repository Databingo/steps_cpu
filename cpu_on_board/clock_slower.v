module clock_slower(
    input wire clk_in,
    input wire reset_n,
    output reg clk_out
);
    reg [24:0] counter; 
    initial begin
        clk_out <= 0;
        counter <= 0;
    end
    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            clk_out <= 0;
            counter <= 0;
        end else begin
            //if (counter == 25000000 - 1) begin // 1hz
            if (counter == 2500000 - 1) begin // 10hz
                counter <= 0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule

