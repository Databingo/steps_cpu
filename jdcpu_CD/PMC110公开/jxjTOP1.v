module jxjTOP1
	(
		////////////////////	Clock Input	 	////////////////////	 
		clk18,						//	18 MHz
		RE_N,
	
		////////////////////	Push Button		////////////////////
		KEY,							//	Pushbutton[4:0]
		////////////////////	DPDT SWitch		////////////////////
		SW,								//	Toggle  SWitch[9:0]
		////////////////////	7-SEG Dispaly	////////////////////
		HEX0,							//	Seven Segment Digit 0
		HEX1,							//	Seven Segment Digit 1
		HEX2,							//	Seven Segment Digit 2
		HEX3,							//	Seven Segment Digit 3
		////////////////////////	LED		////////////////////////
		LEDG,							//	LED Green[7:0]
		LEDR							//	LED Red[9:0]
		////////////////////////	UART	////////////////////////
		
		////////////////////	USB JTAG link	////////////////////
	);

////////////////////////	Clock Input	 	////////////////////////
input	clk18;				//	18 MHz
input   RE_N;
////////////////////////	Push Button		////////////////////////
input	[3:0]	KEY;					//	Pushbutton[3:0]
////////////////////////	DPDT  SWitch		////////////////////////
input   [9:0]	SW;						//	Toggle  SWitch[9:0]
////////////////////////	7-SEG Dispaly	////////////////////////
output	[6:0]	HEX0;					//	Seven Segment Digit 0
output	[6:0]	HEX1;					//	Seven Segment Digit 1
output	[6:0]	HEX2;					//	Seven Segment Digit 2
output	[6:0]	HEX3;					//	Seven Segment Digit 3
////////////////////////////	LED		////////////////////////////
output	[7:0]	LEDG;					//	LED Green[7:0]
output	[9:0]	LEDR;					//	LED Red[9:0]
////////////////////	USB JTAG link	////////////////////////////
wire  [31:0]  mSEG7_DIG;
wire  [31:0]  ouSEG7_DIG;
wire  [6:0]   mCOUNT;
wire  [7:0]   mDATA;
//wire  [7:0]   mDAT;
reg   [23:0]  Cont;
reg   [0:0]   flge;
reg   [0:0]   writ;
reg   [19:0]   Co;
reg   [19:0]   bo;
reg   [19:0]   eo;
reg   [19:0]   fo;
reg   [0:0]   ekz;
reg   [0:0]   fkz;
reg   [0:0]   bkz;
reg   [0:0]   kz;     //控制时间
reg   [0:0]  bak;
reg   [0:0]  rest;
reg   [0:0]  clar;
assign  LEDR[9:2]		=	   SW[9:2];
assign  LEDR[0]		    =	   SW[0];
//assign  writ    =   SW[0] ?   ~KEY[0]:1'b0;
//assign  bak     =   SW[0] ?   ~KEY[1]:1'b0;
//assign  rest    =  ~SW[0] ?   ~KEY[2]:1'b0;
//assign  rest    =  ~SW[0] ?    KEY[3]:1'b1;
assign	mSEG7_DIG[7:0]		=	 SW[0]	?	 SW[9:2]	: ouSEG7_DIG[7:0];
assign	LEDG[7]		=	 SW[0]	?	~KEY[3]	:	ouSEG7_DIG[7]	;
assign	LEDG[5]		=	 SW[0]	?	~KEY[2]	:	ouSEG7_DIG[5]	;
assign	LEDG[3]		=	 SW[0]	?	~KEY[1]	:	ouSEG7_DIG[3]	;
assign	LEDG[1]		=	 SW[0]	?	~KEY[0]	:	ouSEG7_DIG[1]	;
assign	LEDG[6]     =    SW[0]	?   1'b0    :   ouSEG7_DIG[6];
assign	LEDG[4]     =    SW[0]	?   1'b0    :   ouSEG7_DIG[4];
assign	LEDG[2]     =    SW[0]	?   1'b0    :   ouSEG7_DIG[2];
assign	LEDG[0]     =    SW[0]	?   1'b0    :   ouSEG7_DIG[0];
assign	mSEG7_DIG[15]   =  SW[1]  ?  1'b0 :  mDATA[7];
assign	mSEG7_DIG[14:8] =  SW[1]  ?  mCOUNT[6:0] : mDATA[6:0];

always@(posedge clk18)	
begin
	Cont	<=	Cont+1'b1;
	begin	
    	if (mCOUNT!=0)         //不闪
	      begin
	        Cont[23]	<=	1'b0;
	        flge <=1'b0;
	      end
        else
          flge <=1'b1;
    end
end
always@(posedge clk18)	

//去抖动
begin
    if ( SW[0]==1 && KEY[0]==0)  //键按下
       begin
          Co  <= Co+1'b1;        //按下计时        
           if ((Co==10800 || Co==10801 ) && kz==0) 
              begin
                writ<=1;
                if (Co==10801)
                    kz<=1;      //取值完成标志
              end 
            else
                writ <= 0;
        end 
    else
      begin
         kz<=0;
         Co<=0;
         writ <= 0;  
      end
   if ( SW[0]==1 && KEY[1]==0)  //键按下
        begin
           bo<=	bo+1'b1;        //按下计时        
           if ((bo==10800 || bo==10801) && bkz==0) 
              begin
                bak<=1;
                if (bo==10801)
                   bkz<=1; //取值标志
              end 
              else
                 bak <= 0;
         end
    else
      begin
        bkz<=0;
        bo<=0;
        bak  <= 0;  
      end
  if ( SW[0]==0 && KEY[3]==0)  //键按下
        begin
           eo<=	eo+1'b1;        //按下计时        
           if ((eo==10800 || eo==10801 || eo==10802) && ekz==0) 
              begin
                rest<=1;
                if (eo==10802)
                    ekz<=1; //取值标志
              end 
              else
                 rest <= 0;
         end
    else
      begin
        ekz<=0;
        eo<=0;
        rest  <= 0;  
      end
  if (RE_N==0)  //键按下
        begin
           fo<=	fo+1'b1;        //按下计时        
           if ((fo==10800 || fo==10801 )&& fkz==0) 
              begin
                clar<=0;
                if (fo==10801)
                fkz<=1; //取值标志
              end 
              else
                 clar <= 1;
         end
    else
      begin
        fkz<=0;
        fo<=0;
       clar  <= 1;  
      end

end

myfirst  js0 (.brak( SW[0]),.clk(clk18),.clr(clar),.reset(rest),.inpu(writ),
.sub(bak),.data(SW[9:2]),.out(ouSEG7_DIG[7:0]),.q(mDATA[7:0]),.count(mCOUNT[6:0]));

SEG7_LUT_4 			u0	(	HEX0,HEX1,HEX2,HEX3,mSEG7_DIG,Cont[23],flge );


endmodule