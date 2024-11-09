`timescale 1ns / 1ps   //仿真时间单位为 1 纳秒，时间精度是 1 皮秒
//1s  = 1000ms 毫秒
//1ms = 1000um 微秒
//1us = 1000ns 纳秒
//1ns = 1000ps 皮秒


parameter ZQ = 60; // 时钟是 120 纳秒时间单位
parameter TIME_WINDOW = 60*2*64; // 运行仿真 64 个时钟周期


module s2tb();

// 信号声明
reg clk;
reg reset_n;
wire [31:0] o;
wire [6:0] opc ;
wire [2:0] ojp;


// 实例化待测电路
s2 dut(
 .clock (clk),
 .reset_n (reset_n),
 .o (o),
 .opc (opc),
 .ojp (ojp)

);


// Generate clock
initial begin
 clk = 1'b0;
 forever #ZQ clk = ~clk;
end

// Generate reset
initial begin
 reset_n = 1'b1;
 #ZQ
 reset_n = 1'b0;
 #ZQ
 reset_n = 1'b1;
end

// Test
initial begin
 $dumpfile("2.vcd");
 $dumpvars(0, s2tb);
 #TIME_WINDOW $finish;
//$stop;
end

// 输出监控
always @(posedge clk) begin
     $monitor("At time %0t: o=%b, opc=%d, ojp=%b", $time, o, opc, ojp);
    end

endmodule ： s2tb
