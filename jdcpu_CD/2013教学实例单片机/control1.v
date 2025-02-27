 
module  control1 (LDA,JMP,JZ,JN,CALL,RET,IN,IPTR,JEND,JK,INC,DEC,DATP
,p,ENDF,EMP,ZF,NF,RES,INE,PCL,PCE,INCPC,IRAML,IRAMAL,IRAME,IWRITE,DRAML,DRAMAL,DRAME,DWRITE,DAL,DAE,PTRL,INCP,DECP,PTRE,SPE,INCSP,DECSP);
input  [10:0] p;
input  LDA,JMP,JZ,JN,CALL,RET,IN,IPTR,JEND,JK,INC,DEC,DATP;
input  ENDF,EMP,ZF,NF;
output  RES,INE,PCL,PCE,INCPC,IRAML,IRAMAL,IRAME,IWRITE,DRAML,DRAMAL,DRAME,DWRITE,DAL,DAE,PTRL,INCP,DECP,PTRE,SPE,INCSP,DECSP;
assign  RES = LDA & p[8] | JMP & p[6] | JZ & p[6] | JN & p[6] | CALL & p[10] | RET & p[7] | IN & p[9] | IPTR & p[6] | JEND & p[6] | JK & p[6] | INC & p[4] | DEC & p[4] | DATP & p[4];
assign  INE = IN & p[6] | IPTR & p[4];
assign  PCL = JMP & p[5] | JZ & p[5] & ZF | JN & p[5] & NF | CALL & p[9] | RET & p[6] | JEND & p[5] & ENDF | JK & p[5] & EMP;
assign  PCE = LDA & p[3] | JMP & p[3] | JZ & p[3] | JN & p[3] | CALL & p[3] | CALL & p[7] | IN & p[3] | JEND & p[3] | JK & p[3];
assign  INCPC = LDA & p[4] | JZ & p[4] | JN & p[4] | CALL & p[4] | IN & p[4] | JEND & p[4] | JK & p[4];
assign  IRAML = IPTR & p[4];
assign  IRAMAL = LDA & p[3] | JMP & p[3] | JZ & p[3] | JN & p[3] | CALL & p[3] | IN & p[3] | IPTR & p[3] | JEND & p[3] | JK & p[3];
assign  IRAME = LDA & p[5] | JMP & p[5] | JZ & p[5] & ZF | JN & p[5] & NF | CALL & p[5] | IN & p[5] | JEND & p[5] & ENDF | JK & p[5] & EMP;
assign  IWRITE = IPTR & p[5];
assign  DRAML = CALL & p[7] | IN & p[6];
assign  DRAMAL = LDA & p[5] | CALL & p[6] | RET & p[4] | IN & p[5];
assign  DRAME = LDA & p[7] | RET & p[6];
assign  DWRITE = CALL & p[9] | IN & p[8];
assign  DAL = LDA & p[7] | CALL & p[5];
assign  DAE = CALL & p[9] | DATP & p[3];
assign  PTRL = DATP & p[3];
assign  INCP = INC & p[3];
assign  DECP = DEC & p[3];
assign  PTRE = IPTR & p[3];
assign  SPE = CALL & p[6] | RET & p[4];
assign  INCSP = RET & p[3];
assign  DECSP = CALL & p[7];
endmodule