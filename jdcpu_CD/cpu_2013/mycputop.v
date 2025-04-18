module mycputop
	(
		////////////////////	Clock Input	 	////////////////////	 
		clk27,						//	27 MHz
		RE_N,						//复位按钮
	
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
	);

////////////////////////	Clock Input	 	////////////////////////
input	clk27;				//	27 MHz
input   RE_N;
////////////////////////	Push Button		////////////////////////
input	[3:0]	KEY;					//	Pushbutton[3:0]
////////////////////////	 SWitch		////////////////////////
input   [9:0]	SW;						//	Toggle  SWitch[9:0]
////////////////////////	7-SEG Display	////////////////////////
output	[6:0]	HEX0;					//	Seven Segment Digit 0
output	[6:0]	HEX1;					//	Seven Segment Digit 1
output	[6:0]	HEX2;					//	Seven Segment Digit 2
output	[6:0]	HEX3;					//	Seven Segment Digit 3
////////////////////////////	LED		////////////////////////////
output	[7:0]	LEDG;					//	LED Green[7:0]
output	[9:0]	LEDR;					//	LED Red[9:0]
////////////////////	内部变量设计：//////////////////////
wire  [15:0]  mSEG7_DIG;  	// to 7-SEG data
wire  [15:0]  ouSEG7_DIG; 	//disply to 7-SEGdata
wire  [7:0]   mDATA;
wire   clk18;				//真正驱动时钟
wire   [6:0]   mCOUNT;		//缓冲区计数
reg   [23:0]  Cont;			//延时变量
reg       flge;				//标志
reg       writ;				//写信号
reg   [22:0]   Co;			//延时变量：
reg   [22:0]   coo;
reg   [22:0]   boo;
reg   [22:0]   goo;
reg   [22:0]   uoo;
reg   [22:0]   doo;
reg   [22:0]   uo;
reg   [22:0]   ddo;
reg   [22:0]   vo;
reg   [22:0]   bo;
reg   [22:0]   eo;
reg   [22:0]   fo;
reg   [22:0]   go;
reg       gkz;		//控制时间：
reg       ekz;
reg       fkz;
reg       bkz;
reg       kz;    
reg       vkz;
reg       upkz;
reg       dkz;
reg      bak;
reg      fw;
reg      rest;
reg      clar;
reg      bclar;

reg      mUP;		
reg      mDOWN;
//控制连接：
assign  LEDR[9:2]	=	 SW[0]  ? SW[9:2] : ouSEG7_DIG[15:8]; //red led
assign  LEDR[0]	 	=	 SW[0];	//edit control and break down
assign  LEDR[1]	 	=	 SW[1];	
assign	LEDG[7]		=	 SW[0]	?	~KEY[3]	:	( SW[1] ? ~KEY[3]:ouSEG7_DIG[7]);
assign	LEDG[5]		=	 SW[0]	?	~KEY[2]	:	( SW[1] ? ~KEY[2]:ouSEG7_DIG[5]);
assign	LEDG[3]		=	 SW[0]	?	~KEY[1]	:	( SW[1] ? ~KEY[1]:ouSEG7_DIG[3]);
assign	LEDG[1]		=	 SW[0]	?	~KEY[0]	:	( SW[1] ? ~KEY[0]:ouSEG7_DIG[1]);
assign	LEDG[6]     =    SW[0]	?   1'b0    :   ouSEG7_DIG[6];
assign	LEDG[4]     =    SW[0]	?   1'b0    :   ouSEG7_DIG[4];
assign	LEDG[2]     =    SW[0]	?   1'b0    :   ouSEG7_DIG[2];
assign	LEDG[0]     =    SW[0]	?   1'b0    :   ouSEG7_DIG[0];

assign	mSEG7_DIG[7:0]	=  SW[0] ? SW[9:2]		: ouSEG7_DIG[7:0];
assign	mSEG7_DIG[15]   =  SW[0] ? (SW[1]  ? 1'b0 : mDATA[7]): ouSEG7_DIG[15];
assign	mSEG7_DIG[14:8] =  SW[0] ? ( SW[1] ? mCOUNT[6:0] :	mDATA[6:0])	: ouSEG7_DIG[14:8];
//闪烁控制描述：
always@(posedge clk18)	
begin
Cont	<=	Cont+1'b1;
 if (mCOUNT!=0)         //不闪
	      begin
	        Cont[23]<=	1'b0;
	      end
  flge <= Cont[23];
end
//消除按钮抖动设计：
always@(posedge clk18)	
//去抖动
begin
    if (  SW[0]==1 && KEY[0]==0 && kz==0)  //键按下输入
       begin
           Co  <= Co+1'b1;        //按下计时        
           if (Co==10800 )  writ<=1;
           else  
              begin
                writ <= 0;
                if (Co[22]==1)
                   begin
                    kz<=1;      //取值完成标志
                    coo<=0;
                   end
              end 
      end 
    else
      begin
         Co<=0;
         writ <= 0;
         coo <= coo+1'b1;
         if (coo[22]==1) kz <= 0;
      end

    if ( SW[0]==1 && KEY[2]==0 && bkz==0)  //键按下后退
        begin
           bo<=	bo+1'b1;        //按下计时        
           if (bo==10800 )   bak<=1;
           else  
              begin
                bak <= 0;
                if ( bo[22]==1'b1 )
                   begin
                    bkz<=1;      //取值完成标志
                    boo<=0;
                   end
              end 
        end
    else
      begin
         bkz<=1;
         bo<=0;
         bak <= 0;  
         boo <= boo+1'b1;
         if ( boo[22]==1'b1) bkz <= 0;
      end

  if ( SW[0]==1 && KEY[1]==0 && gkz==0)  //键按下前进
        begin
           go<=	go+1'b1;        //按下计时        
           if (go==10800 )   fw<=1;
           else  
              begin
                fw <= 0;
                if ( go[22]==1'b1 )
                   begin
                    gkz<=1;      //取值完成标志
                    goo<=0;
                   end
              end 
        end
    else
      begin
         gkz<=1;
         go<=0;
         fw <= 0;  
         goo <= goo+1'b1;
         if ( goo[22]==1'b1) gkz <= 0;
      end
    if ( SW[0]==0 && KEY[2]==0 && upkz==0)  //键按下删除
        begin
           uo<=	uo+1'b1;        //按下计时        
           if (uo==10800 )   mUP<=1;
           else  
              begin
                mUP <= 0;
                if ( uo[22]==1'b1 )
                   begin
                    upkz<=1;      //取值完成标志
                    uoo<=0;
                   end
              end 
        end
    else
      begin
         upkz<=1;
         uo<=0;
         mUP <= 0;  
         uoo <= uoo+1'b1;
         if ( uoo[22]==1'b1) upkz <= 0;
      end

  if ( SW[0]==0 && KEY[1]==0 && dkz==0)  //键按下插入
        begin
           ddo<=	ddo+1'b1;        //按下计时        
           if (ddo==10800 )   mDOWN<=1;
           else  
              begin
                mDOWN <= 0;
                if ( ddo[22]==1'b1 )
                   begin
                    dkz<=1;      //取值完成标志
                    doo<=0;
                   end
              end 
        end
    else
      begin
         dkz<=1;
         ddo<=0;
         mDOWN <= 0;  
         doo <= doo+1'b1;
         if ( doo[22]==1'b1) dkz <= 0;
      end

    if ( SW[0]==0 && KEY[3]==0)  //键按下执行
        begin
           eo<=	eo+1'b1;        //按下计时        
           if ((eo==10800 ) && ekz==0) 
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
    if ( SW[0]==1 && RE_N==0)  //键按下复位
        begin
           vo<=	vo+1'b1;        //按下计时        
           if ((vo==10800 )&& vkz==0) 
              begin
                bclar<=0;
                if (vo==10801)
                vkz<=1; //取值标志
              end 
              else
                 bclar <= 1;
         end
    else
      begin
        vkz<=0;
        vo<=0;
       bclar  <= 1;  
      end

    if ( SW[0]==0 && RE_N==0)  //键按下复位
        begin
           fo<=	fo+1'b1;        //按下计时        
           if ((fo==10800 )&& fkz==0) 
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
//调用CPU与缓冲区连接模块和时钟：
bufuucpu  cpu0 (.brak( SW[0]),.clk(clk18),.clr(clar),.go(!rest),.wre(writ),
.forw(fw),.back(bak),.data( SW[9:2]),.ol(ouSEG7_DIG[7:0]),
.oh(ouSEG7_DIG[15:8]),.count(mCOUNT),.q(mDATA));
SEG7_LUT_4 			u0	(	HEX0,HEX1,HEX2,HEX3,mSEG7_DIG,flge,0 );
altpll0 altp0 (.inclk0(clk27),.c0(clk18));
endmodule
