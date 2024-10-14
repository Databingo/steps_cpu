`timescale 1ns / 1ps   //仿真时间单位为 1 纳秒，时间精度是 1 皮秒
//1s  = 1000ms 毫秒
//1ms = 1000um 微秒
//1us = 1000ns 纳秒
//1ns = 1000ps 皮秒


parameter YMC = 60; // 一个脉冲是 60 纳秒时间单位，从上升沿到上升沿是一个周期，两个脉冲，120 纳秒
parameter TIME_WINDOW = 60*2 * 62 * 4 + 1 ; // 运行仿真 62*4(节拍+1延迟节拍) 个时钟周期


module s3tb();

// 信号声明
reg clk;
reg reset_n;
wire [31:0] oir;
wire [6:0] opc ;
wire [2:0] ojp;
wire [6:0] o_opcode;
wire [2:0] ofunc3;
wire [6:0] ofunc7;

wire oLui;
wire oAuipc; 

wire oLb;
wire oLbu;
wire oLh; 
wire oLhu;
wire oLw;
wire oLwu;
wire oLd;

wire oSb;
wire oSh;
wire oSw;
wire oSd;

wire oAdd;
wire oSub;
wire oSll;
wire oSlt;
wire oSltu;
wire oXor;
wire oSrl;
wire oSra;
wire oOr;
wire oAnd;

wire oAddi; 
wire oSlti; 
wire oSltiu;
wire oOri; 
wire oAndi;
wire oXori;
wire oSlli;
wire oSrli;
wire oSrai;

wire oAddiw;
wire oSlliw;
wire oSrliw;
wire oSraiw;

wire oAddw;
wire oSubw;
wire oSllw;
wire oSrlw;
wire oSraw;

wire oJal; 
wire oJalr;






// 实例化待测电路
s3 dut(
 .clock (clk),
 .reset_n (reset_n),
 .oir (oir),
 .opc (opc),
 .ojp (ojp),
 .o_opcode (o_opcode),
 .ofunc3 (ofunc3),
 .ofunc7 (ofunc7),

 .oLui (oLui),
 .oAuipc (oAuipc), 

 .oLb (oLb),
 .oLbu (oLbu),
 .oLh  (oLh),
 .oLhu (oLhu),
 .oLw (oLw),
 .oLwu (oLwu),
 .oLd (oLd),

.oSb (oSb), 
.oSh (oSh),
.oSw (oSw),
.oSd (oSd),

.oAdd(oAdd),
.oSub(oSub),
.oSll(oSll),
.oSlt(oSlt),
.oSltu(oSltu),
.oXor(oXor),
.oSrl(oSrl),
.oSra(oSra),
.oOr(oOr),
.oAnd(oAnd),


.oAddi(oAddi),  
.oSlti(oSlti), 
.oSltiu(oSltiu),
.oOri(oOri), 
.oAndi(oAndi),
.oXori(oXori),
.oSlli(oSlli),
.oSrli(oSrli),
.oSrai(oSrai),


.oAddiw(oAddiw),
.oSlliw(oSlliw),
.oSrliw(oSrliw),
.oSraiw(oSraiw),

.oAddw(oAddw),
.oSubw(oSubw),
.oSllw(oSllw),
.oSrlw(oSrlw),
.oSraw(oSraw),

.oJal(oJal),  
.oJalr(oJalr)










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
     $write("Tm %0t:oir=%b,opc=%0d,ojp=%d,o_op=%b,ofunc3=%b,ofunc7=%b,", $time, oir, opc, ojp, o_opcode, ofunc3, ofunc7);

   if (oLui == 1'b1) $write("oLui=%b,", oLui);
   if (oAuipc == 1'b1) $write("oAuipc=%b,", oAuipc);

   if (oLb == 1'b1) $write("oLb=%b,", oLb);
   if (oLbu == 1'b1) $write("oLbu=%b,", oLbu);
   if (oLh  == 1'b1) $write("oLh=%b,",  oLh,   );
   if (oLhu == 1'b1) $write("oLhu=%b,", oLhu,  );
   if (oLw  == 1'b1) $write("oLw=%b,",  oLw,   );
   if (oLwu == 1'b1) $write("oLwu=%b,", oLwu,  );
   if (oLd  == 1'b1) $write("oLd=%b,",  oLd,   );

   if (oSb  == 1'b1) $write("oSb=%b,",  oSb,   );
   if (oSh  == 1'b1) $write("oSh=%b,",  oSh,   );
   if (oSw  == 1'b1) $write("oSw=%b,",  oSw,   );
   if (oSd  == 1'b1) $write("oSd=%b,",  oSd,   );

   if (oAdd == 1'b1) $write("oAdd=%b,",  oAdd, );
   if (oSub == 1'b1) $write("oSub=%b,",  oSub, );
   if (oSll == 1'b1) $write("oSll=%b,",  oSll, );
   if (oSlt == 1'b1) $write("oSlt=%b,",  oSlt, );
   if (oSltu== 1'b1) $write("oSltu=%b,", oSltu,);
   if (oXor == 1'b1) $write("oXor=%b,",  oXor,);
   if (oSrl == 1'b1) $write("oSrl=%b,",  oSrl,);
   if (oSra == 1'b1) $write("oSra=%b,",  oSra,);
   if (oOr  == 1'b1) $write("oOr=%b,",   oOr,);
   if (oAnd == 1'b1) $write("oAnd=%b,",  oAnd,);


   if (oAddi == 1'b1) $write("oAddi=%b,",  oAddi ,);
   if (oSlti == 1'b1) $write("oSlti=%b,",  oSlti ,);
   if (oSltiu== 1'b1) $write("oSltiu=%b,",  oSltiu,);
   if (oOri  == 1'b1) $write("oOri=%b,",  oOri  ,);
   if (oAndi == 1'b1) $write("oAndi=%b,",  oAndi ,);
   if (oXori == 1'b1) $write("oXori=%b,",  oXori ,);
   if (oSlli == 1'b1) $write("oSlli=%b,",  oSlli ,);
   if (oSrli == 1'b1) $write("oSrli=%b,",  oSrli ,);
   if (oSrai == 1'b1) $write("oSrai=%b,",  oSrai ,);

   if (oAddiw == 1'b1) $write("oAddiw=%b,",  oAddiw ,);
   if (oSlliw == 1'b1) $write("oSlliw=%b,",  oSlliw ,);
   if (oSrliw == 1'b1) $write("oSrliw=%b,",  oSrliw ,);
   if (oSraiw == 1'b1) $write("oSraiw=%b,",  oSraiw ,);

   if (oAddw == 1'b1) $write("oAddw=%b,",  oAddw ,);
   if (oSubw == 1'b1) $write("oSubw=%b,",  oSubw ,);
   if (oSllw == 1'b1) $write("oSllw=%b,",  oSllw ,);
   if (oSrlw == 1'b1) $write("oSrlw=%b,",  oSrlw ,);
   if (oSraw == 1'b1) $write("oSraw=%b,",  oSraw ,);

       
   if (oJal  == 1'b1) $write("oJal=%b,",  oJal  ,);
   if (oJalr == 1'b1) $write("oJalr=%b,",  oJalr ,);
      
      











    $write("\n");

  


    end

endmodule ： s3tb
