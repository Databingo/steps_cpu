`timescale 1ns / 1ps   //仿真时间单位为 1 纳秒，时间精度是 1 皮秒
//1s  = 1000ms 毫秒
//1ms = 1000um 微秒
//1us = 1000ns 纳秒
//1ns = 1000ps 皮秒


parameter YMC = 60; // 一个脉冲是 60 纳秒时间单位，从上升沿到上升沿是一个周期，两个脉冲，120 纳秒
//parameter TIME_WINDOW = 60*2 * 66 * 3 + 2 ; // 运行仿真 66*3(+2延迟节拍) 个时钟周期
parameter TIME_WINDOW = 60*2 * 66 * 4 + 2 ;


module s4tb();

// 信号声明
reg clk;
reg reset_n;
wire [31:0] oir;
wire [6:0] opc ;
wire [2:0] ojp;
wire [6:0] oop;
wire [2:0] of3;
wire [6:0] of7;
wire [11:0] oimm;
wire [19:0] oupimm; 
wire [63:0] ox0;
wire [63:0] ox1;
wire [63:0] ox2;
wire [63:0] ox3;
wire [63:0] ox4;
wire [63:0] ox5;
wire [63:0] ox6;
wire [63:0] ox7;
wire [63:0] ox8;
wire [63:0] ox9;
wire [63:0] ox10;
wire [63:0] ox11;
wire [63:0] ox12;
wire [63:0] ox13;
wire [63:0] ox14;
wire [63:0] ox15;
wire [63:0] ox16;
wire [63:0] ox17;
wire [63:0] ox18;
wire [63:0] ox19;
wire [63:0] ox20;
wire [63:0] ox21;
wire [63:0] ox22;
wire [63:0] ox23;
wire [63:0] ox24;
wire [63:0] ox25;
wire [63:0] ox26;
wire [63:0] ox27;
wire [63:0] ox28;
wire [63:0] ox29;
wire [63:0] ox30;
wire [63:0] ox31;



wire [63:0] osign_extended_bimm;

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

wire oBeq; 
wire oBne; 
wire oBlt; 
wire oBge; 
wire oBltu;
wire oBgeu;

wire oFence; 
wire oFencei;

wire oEcall; 
wire oEbreak;
wire oCsrrw; 
wire oCsrrs;
wire oCsrrc; 
wire oCsrrwi;
wire oCsrrsi;
wire oCsrrci;











// 实例化待测电路
s4 dut(
 .clock (clk),
 .reset_n (reset_n),
 .oir (oir),
 .opc (opc),
 .ojp (ojp),
 .oop (oop),
 .of3 (of3),
 .of7 (of7),
 .oimm (oimm),
 .oupimm (oupimm),

 .ox1 (ox1),
 .ox2 (ox2),
 .ox3 (ox3),
 .ox4 (ox4),
 .ox5 (ox5),
 .ox6 (ox6),
 .ox7 (ox7),
 .ox8 (ox8),
 .ox9 (ox9),
 .ox10(ox10),
 .ox11(ox11),
 .ox12(ox12),
 .ox13(ox13),
 .ox14(ox14),
 .ox15(ox15),
 .ox16(ox16),
 .ox17(ox17),
 .ox18(ox18),
 .ox19(ox19),
 .ox20(ox20),
 .ox21(ox21),
 .ox22(ox22),
 .ox23(ox23),
 .ox24(ox24),
 .ox25(ox25),
 .ox26(ox26),
 .ox27(ox27),
 .ox28(ox28),
 .ox29(ox29),
 .ox30(ox30),
 .ox31(ox31),

 .osign_extended_bimm (osign_extended_bimm),


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
.oJalr(oJalr),

.oBeq(oBeq), 
.oBne(oBne), 
.oBlt(oBlt), 
.oBge(oBge), 
.oBltu(oBltu),
.oBgeu(oBgeu),

.oFence(oFence),  
.oFencei(oFencei),

.oEcall (oEcall),
.oEbreak(oEbreak),
.oCsrrw (oCsrrw), 
.oCsrrs (oCsrrs),
.oCsrrc (oCsrrc), 
.oCsrrwi(oCsrrwi),
.oCsrrsi(oCsrrsi),
.oCsrrci(oCsrrci)



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
 $dumpfile("4.vcd");
 $dumpvars(0, s4tb);
 #TIME_WINDOW $finish;
 //#TIME_WINDOW $finish; // run forever
//$stop;
end

// 输出监控
always @(posedge clk) begin
     $write("Tm %0t:oir=%b,opc=%0b|%0d,ojp=%d,o_op=%b,of3=%b,of7=%b,", $time, oir, opc, opc, ojp, oop, of3, of7);

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
      
   if (oBeq  == 1'b1) $write("oBeq=%b,",  oBeq  ,);
   if (oBne  == 1'b1) $write("oBne=%b,",  oBne  ,);
   if (oBlt  == 1'b1) $write("oBlt=%b,",  oBlt  ,);
   if (oBge  == 1'b1) $write("oBge=%b,",  oBge  ,);
   if (oBltu == 1'b1) $write("oBltu=%b,",  oBltu ,);
   if (oBgeu == 1'b1) $write("oBgeu=%b,",  oBgeu ,);


   if (oFence  == 1'b1) $write("oFence=%b,",  oFence  ,);
   if (oFencei == 1'b1) $write("oFencei=%b,",  oFencei ,);


   if (oEcall  == 1'b1) $write("oEcall=%b,",  oEcall  ,);
   if (oEbreak == 1'b1) $write("oEbreak=%b,",  oEbreak ,);
   if (oCsrrw  == 1'b1) $write("oCsrrw=%b,",  oCsrrw  ,);
   if (oCsrrs  == 1'b1) $write("oCsrrs=%b,",  oCsrrs  ,);
   if (oCsrrc  == 1'b1) $write("oCsrrc=%b,",  oCsrrc  ,);
   if (oCsrrwi == 1'b1) $write("oCsrrwi=%b,",  oCsrrwi ,);
   if (oCsrrsi == 1'b1) $write("oCsrrsi=%b,",  oCsrrsi ,);
   if (oCsrrci == 1'b1) $write("oCsrrci=%b,",  oCsrrci ,);

   if (oimm !== 0 ) $write("oimm=%0b,",  oimm ,);

   if (ox0 !== 0 && ox0 !== 64'bz && ox0 !== 64'bx) $write("ox0=%0d,",  ox0 ,);
   if (ox1 !== 0 && ox1 !== 64'bz && ox1 !== 64'bx) $write("ox1=%0d,",  ox1 ,);
   if (ox2 !== 0 && ox2 !== 64'bz && ox2 !== 64'bx) $write("ox2=%0d,",  ox2 ,);
   if (ox3 !== 0 && ox3 !== 64'bz && ox3 !== 64'bx) $write("ox3=%0d,",  ox3 ,);
   if (ox4 !== 0 && ox4 !== 64'bz && ox4 !== 64'bx) $write("ox4=%0d,",  ox4 ,);
   if (ox5 !== 0 && ox5 !== 64'bz && ox5 !== 64'bx) $write("ox5=%0d,",  ox5 ,);
   if (ox6 !== 0 && ox6 !== 64'bz && ox6 !== 64'bx) $write("ox6=%0d,",  ox6 ,);
   if (ox7 !== 0 && ox7 !== 64'bz && ox7 !== 64'bx) $write("ox7=%0d,",  ox7 ,);
   if (ox8 !== 0 && ox8 !== 64'bz && ox8 !== 64'bx) $write("ox8=%0d,",  ox8 ,);
   if (ox9 !== 0 && ox9 !== 64'bz && ox9 !== 64'bx) $write("ox9=%0d,",  ox9 ,);
   if (ox10 !== 0 && ox10 !== 64'bz && ox10 !== 64'bx) $write("ox10=%0d,",  ox10 ,);
   if (ox11 !== 0 && ox11 !== 64'bz && ox11 !== 64'bx) $write("ox11=%0d,",  ox11 ,);
   if (ox12 !== 0 && ox12 !== 64'bz && ox12 !== 64'bx) $write("ox12=%0d,",  ox12 ,);
   if (ox13 !== 0 && ox13 !== 64'bz && ox13 !== 64'bx) $write("ox13=%0d,",  ox13 ,);
   if (ox14 !== 0 && ox14 !== 64'bz && ox14 !== 64'bx) $write("ox14=%0d,",  ox14 ,);
   if (ox15 !== 0 && ox15 !== 64'bz && ox15 !== 64'bx) $write("ox15=%0d,",  ox15 ,);
   if (ox16 !== 0 && ox16 !== 64'bz && ox16 !== 64'bx) $write("ox16=%0d,",  ox16 ,);
   if (ox17 !== 0 && ox17 !== 64'bz && ox17 !== 64'bx) $write("ox17=%0d,",  ox17 ,);
   if (ox18 !== 0 && ox18 !== 64'bz && ox18 !== 64'bx) $write("ox18=%0d,",  ox18 ,);
   if (ox19 !== 0 && ox19 !== 64'bz && ox19 !== 64'bx) $write("ox19=%0d,",  ox19 ,);
   if (ox20 !== 0 && ox20 !== 64'bz && ox20 !== 64'bx) $write("ox20=%0d,",  ox20 ,);
   if (ox21 !== 0 && ox21 !== 64'bz && ox21 !== 64'bx) $write("ox21=%0d,",  ox21 ,);
   if (ox22 !== 0 && ox22 !== 64'bz && ox22 !== 64'bx) $write("ox22=%0d,",  ox22 ,);
   if (ox23 !== 0 && ox23 !== 64'bz && ox23 !== 64'bx) $write("ox23=%0d,",  ox23 ,);
   if (ox24 !== 0 && ox24 !== 64'bz && ox24 !== 64'bx) $write("ox24=%0d,",  ox24 ,);
   if (ox25 !== 0 && ox25 !== 64'bz && ox25 !== 64'bx) $write("ox25=%0d,",  ox25 ,);
   if (ox26 !== 0 && ox26 !== 64'bz && ox26 !== 64'bx) $write("ox26=%0d,",  ox26 ,);
   if (ox27 !== 0 && ox27 !== 64'bz && ox27 !== 64'bx) $write("ox27=%0d,",  ox27 ,);
   if (ox28 !== 0 && ox28 !== 64'bz && ox28 !== 64'bx) $write("ox28=%0d,",  ox28 ,);
   if (ox29 !== 0 && ox29 !== 64'bz && ox29 !== 64'bx) $write("ox29=%0d,",  ox29 ,);

   if (ox30 !== 0 && ox30 !== 64'bz && ox30 !== 64'bx) $write("ox30=%0d,",  ox30 ,);
   if (ox30 !== 0 && ox30 !== 64'bz && ox30 !== 64'bx) $write("ox30=0b%0b,",  ox30 ,); 
   if (ox30 !== 0 && ox30 !== 64'bz && ox30 !== 64'bx) $write("ox30=0x%0h,",  ox30 ,); 

   if (ox31 !== 0 && ox31 !== 64'bz && ox31 !== 64'bx) $write("ox31=%0d,",  ox31 ,); 
   if (ox31 !== 0 && ox31 !== 64'bz && ox31 !== 64'bx) $write("ox31=0b%0b,",  ox31 ,); 
   if (ox31 !== 0 && ox31 !== 64'bz && ox31 !== 64'bx) $write("ox31=0x%0h,",  ox31 ,); 
   if (ox31 !== 0 && ox31 !== 64'bz && ox31 !== 64'bx && ox31[63] == 1'b1) $write("ox31=-%0d,",  ~ox31[63:0]+1'b1 ,); 
  // if (oupimm  !== 0 ) $write("oupimm=%0b,",  oupimm ,);
  // $write("osign_extended_bimm=%064b,",  osign_extended_bimm ,);








    $write("\n");

  


    end

endmodule ： s4tb
