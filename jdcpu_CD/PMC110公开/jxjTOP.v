module jxjTOP
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
wire  [15:0]  mSEG7_DIG;
wire  [15:0]  ouSEG7_DIG;
wire  [6:0]   mCOUNT;
wire  [7:0]   mDATA;
reg   [23:0]  Cont;
reg   [0:0]   flge;
reg   [0:0]   writ;
reg   [22:0]   Co;
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
reg   [0:0]   gkz;
reg   [0:0]   ekz;
reg   [0:0]   fkz;
reg   [0:0]   bkz;
reg   [0:0]   kz;     //����ʱ��
reg   [0:0]   vkz;
reg   [0:0]   upkz;
reg   [0:0]   dkz;
reg   [0:0]  bak;
reg   [0:0]  fw;
reg   [0:0]  rest;
reg   [0:0]  clar;
reg   [0:0]  bclar;

reg   [0:0]  mUP;
reg   [0:0]  mDOWN;

assign  LEDR[9:2]		=	   SW[9:2];
assign  LEDR[0]		    =	   SW[0];
assign	mSEG7_DIG[7:0]	=      SW[0] ? SW[9:2]	: ouSEG7_DIG[7:0];
assign	LEDG[7]		=	 SW[0]	?	~KEY[3]	:	( SW[1] ? ~KEY[3]:ouSEG7_DIG[7]);
assign	LEDG[5]		=	 SW[0]	?	~KEY[2]	:	( SW[1] ? ~KEY[2]:ouSEG7_DIG[5]);
assign	LEDG[3]		=	 SW[0]	?	~KEY[1]	:	( SW[1] ? ~KEY[1]:ouSEG7_DIG[3]);
assign	LEDG[1]		=	 SW[0]	?	~KEY[0]	:	( SW[1] ? ~KEY[0]:ouSEG7_DIG[1]);
assign	LEDG[6]     =    SW[0]	?   1'b0    :   ouSEG7_DIG[6];
assign	LEDG[4]     =    SW[0]	?   1'b0    :   ouSEG7_DIG[4];
assign	LEDG[2]     =    SW[0]	?   1'b0    :   ouSEG7_DIG[2];
assign	LEDG[0]     =    SW[0]	?   1'b0    :   ouSEG7_DIG[0];
assign	mSEG7_DIG[15]   =  SW[0]? ( SW[1]?1'b0:mDATA[7]):(~SW[1]?(SW[2]? mDATA[7]:1'b0):ouSEG7_DIG[15]);
assign	mSEG7_DIG[14:8] =  SW[0]? ( SW[1]? mCOUNT[6:0]:mDATA[6:0]): (~SW[1]?(SW[2]? mDATA[6:0]: mCOUNT[6:0]):ouSEG7_DIG[14:8]);

always@(posedge clk18)	
begin
	Cont	<=	Cont+1'b1;
	begin	
    	if (mCOUNT!=0)         //����
	      begin
	        Cont[23]<=	1'b0;
	        flge <=1'b0;
	      end
        else
          flge <=1'b1;
    end
end

always@(posedge clk18)	
//ȥ����
begin
 
    if (  SW[0]==1 && KEY[0]==0 && kz==0)  //����������
       begin
           Co  <= Co+1'b1;        //���¼�ʱ        
           if (Co==10800 || Co==10801 )  writ<=1;
           else  
              begin
                writ <= 0;
                if (Co[22]==1)
                   begin
                    kz<=1;      //ȡֵ��ɱ�־
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

    if ( SW[0]==1 && KEY[2]==0 && bkz==0)  //�����º���
        begin
           bo<=	bo+1'b1;        //���¼�ʱ        
           if (bo==10800 || bo==10801)   bak<=1;
           else  
              begin
                bak <= 0;
                if ( bo[22]==1'b1 )
                   begin
                    bkz<=1;      //ȡֵ��ɱ�־
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

  if ( SW[0]==1 && KEY[1]==0 && gkz==0)  //������ǰ��
        begin
           go<=	go+1'b1;        //���¼�ʱ        
           if (go==10800 || go==10801)   fw<=1;
           else  
              begin
                fw <= 0;
                if ( go[22]==1'b1 )
                   begin
                    gkz<=1;      //ȡֵ��ɱ�־
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
    if ( SW[0]==0 && KEY[2]==0 && upkz==0)  //������ɾ��
        begin
           uo<=	uo+1'b1;        //���¼�ʱ        
           if (uo==10800 || uo==10801)   mUP<=1;
           else  
              begin
                mUP <= 0;
                if ( uo[22]==1'b1 )
                   begin
                    upkz<=1;      //ȡֵ��ɱ�־
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

  if ( SW[0]==0 && KEY[1]==0 && dkz==0)  //�����²���
        begin
           ddo<=	ddo+1'b1;        //���¼�ʱ        
           if (ddo==10800 || ddo==10801)   mDOWN<=1;
           else  
              begin
                mDOWN <= 0;
                if ( ddo[22]==1'b1 )
                   begin
                    dkz<=1;      //ȡֵ��ɱ�־
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

    if ( SW[0]==0 && KEY[3]==0)  //������ִ��
        begin
           eo<=	eo+1'b1;        //���¼�ʱ        
           if ((eo==10800 || eo==10801 || eo==10802) && ekz==0) 
              begin
                rest<=1;
                if (eo==10802)
                    ekz<=1; //ȡֵ��־
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
    if ( SW[0]==1 && RE_N==0)  //�����¸�λ
        begin
           vo<=	vo+1'b1;        //���¼�ʱ        
           if ((vo==10800 || vo==10801 )&& vkz==0) 
              begin
                bclar<=0;
                if (vo==10801)
                vkz<=1; //ȡֵ��־
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


    if ( SW[0]==0 && RE_N==0)  //�����¸�λ
        begin
           fo<=	fo+1'b1;        //���¼�ʱ        
           if ((fo==10800 || fo==10801 )&& fkz==0) 
              begin
                clar<=0;
                if (fo==10801)
                fkz<=1; //ȡֵ��־
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

jsjv t0(.clock(clk18),.reset_n(clr),.dout(lj));
SEG7_LUT_4 			u0	(	HEX0,HEX1,HEX2,HEX3,lj );

//myfirst  js0 (.brak( SW[0]),.clk(clk18),.clr(clar),.bclr(bclar),.reset(rest),.inpu(writ),.forw(fw),.UP(mUP),.DOWN(mDOWN),
//.sub(bak),.data(SW[9:2]),.out(ouSEG7_DIG[7:0]),.ox(ouSEG7_DIG[15:8]),.q(mDATA[7:0]),.count(mCOUNT[6:0]));

//SEG7_LUT_4 			u0	(	HEX0,HEX1,HEX2,HEX3,mSEG7_DIG,Cont[23],0 );


endmodule