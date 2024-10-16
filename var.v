// 分步设计制作CPU 2024.10.04 解释权陈钢Email:databingo@foxmail.com
// 寄存器编号
parameter x0 = 0;
parameter x1 = 1;
parameter x2 = 2;
parameter x3 = 3;
parameter x4 = 4;
parameter x5 = 5;
parameter x6 = 6;
parameter x7 = 7;
parameter x8 = 8;
parameter x9 = 9;
parameter x10 = 10;
parameter x11 = 11;
parameter x12 = 12;
parameter x13 = 13;
parameter x14 = 14;
parameter x15 = 15;
parameter x16 = 16;
parameter x17 = 17;
parameter x18 = 18;
parameter x19 = 19;
parameter x20 = 20;
parameter x21 = 21;
parameter x22 = 22;
parameter x23 = 23;
parameter x24 = 24;
parameter x25 = 25;
parameter x26 = 26;
parameter x27 = 27;
parameter x28 = 28;
parameter x29 = 29;
parameter x30 = 30;
parameter x31 = 31;
 
// 控制线
reg Lui;
reg Auipc; 
reg Lb;
reg Lbu;
reg Lh; 
reg Lhu;
reg Lw;
reg Lwu;
reg Ld;

reg Sb;
reg Sh;
reg Sw;
reg Sd;

reg Add;
reg Sub;
reg Sll;
reg Slt;
reg Sltu;
reg Xor ;
reg Srl;
reg Sra;
reg Or;
reg And;

reg Addi; 
reg Slti;
reg Sltiu;
reg Ori; 
reg Andi;
reg Xori;
reg Slli;
reg Srli;
reg Srai;

reg Addiw;
reg Slliw;
reg Srliw;
reg Sraiw;

reg Addw;
reg Subw;
reg Sllw;
reg Srlw;
reg Sraw;

reg Jal;   
reg Jalr;

reg Beq;
reg Bne;
reg Blt;
reg Bge;
reg Bltu;
reg Bgeu;

reg Fence;
reg Fencei;    

reg Ecall; 
reg Ebreak;
reg Csrrw;
reg Csrrs;
reg Csrrc;
reg Csrrwi;
reg Csrrsi;
reg Csrrci;

