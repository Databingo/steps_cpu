`timescale 1ns / 1ps   //仿真时间单位为 1 纳秒，时间精度是 1 皮秒
//1s  = 1000ms 毫秒
//1ms = 1000um 微秒
//1us = 1000ns 纳秒
//1ns = 1000ps 皮秒


parameter YMC = 60; // 一个脉冲是 60 纳秒时间单位，从上升沿到上升沿是一个周期，两个脉冲，120 纳秒
parameter TIME_WINDOW = 60*2*128; // 运行仿真 128 个时钟周期


module s3tb();

// 信号声明
reg clk;
reg reset_n;
wire [31:0] o;
wire [6:0] opc ;
wire [2:0] ojp;
wire [6:0] o_opcode;
wire [2:0] oshow;
wire oLui;


// 实例化待测电路
s3 dut(
 .clock (clk),
 .reset_n (reset_n),
 .o (o),
 .opc (opc),
 .ojp (ojp),
 .o_opcode (o_opcode),
 .oshow (oshow),
 .oLui (oLui)

);


// Generate clock
initial begin
 clk = 1'b0;
 forever #YMC clk = ~clk;
end

// Generate reset
initial begin
 reset_n = 1'b1;
 #YMC
 reset_n = 1'b0;
 #YMC
 reset_n = 1'b1;
end

// Test
initial begin
 $dumpfile("3.vcd");
 $dumpvars(0, s3tb);
 #TIME_WINDOW $finish;
//$stop;
end

// 输出监控
always @(posedge clk) begin
     $monitor("At time %0t: o=%b, opc=%d, ojp=%d, o_opcode=%b, oshow=%b, oLui=%b", $time, o, opc, ojp, o_opcode, oshow, oLui);
    end

endmodule ： s3tb
