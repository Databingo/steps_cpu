module  contr (p,ADD,SUB,SDA,OUT,STR
,RES,PCE,INCPC,IRAMAL,IRAME,DRAML,DRAMAL,DRAME,DWRITE,AL,BL,ALUE,SU,IRL,DAL,DAE,OL);
input  [9:0] p;
input  ADD,SUB,SDA,OUT,STR;

output  RES,PCE,INCPC,IRAMAL,IRAME,DRAML,DRAMAL,DRAME,DWRITE,AL,BL,ALUE,SU,IRL,DAL,DAE,OL;
assign  RES = ADD & p[9] | SUB & p[9] | SDA & p[6] | OUT & p[8] | STR & p[8];
assign  PCE = p[0] | ADD & p[3] | SUB & p[3] | SDA & p[3] | OUT & p[3] | STR & p[3];
assign  INCPC = p[1] | ADD & p[6] | SUB & p[6] | SDA & p[4] | OUT & p[4] | STR & p[4];
assign  IRAMAL = p[0] | ADD & p[3] | SUB & p[3] | SDA & p[3] | OUT & p[3] | STR & p[3];
assign  IRAME = p[2] | ADD & p[5] | SUB & p[5] | SDA & p[5] | OUT & p[5] | STR & p[5];
assign  DRAML = STR & p[6];
assign  DRAMAL = ADD & p[5] | SUB & p[5] | OUT & p[5] | STR & p[5];
assign  DRAME = ADD & p[7] | SUB & p[7] | OUT & p[7];
assign  DWRITE = STR & p[7];
assign  AL = ADD & p[4] | SUB & p[4];
assign  BL = ADD & p[7] | SUB & p[7];
assign  ALUE = ADD & p[8] | SUB & p[8];
assign  SU = SUB & p[8];
assign  IRL = p[2];
assign  DAL = ADD & p[8] | SUB & p[8] | SDA & p[5];
assign  DAE = ADD & p[4] | SUB & p[4] | STR & p[6];
assign  OL = OUT & p[7];
endmodule
