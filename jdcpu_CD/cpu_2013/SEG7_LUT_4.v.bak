module SEG7_LUT_4 (	oSEG0,oSEG1,oSEG2,oSEG3,iDIG,flash,flg );
input	[15:0]	iDIG;
input   [0:0]   flash;
input   [0:0]   flg;
output	[6:0]	oSEG0,oSEG1,oSEG2,oSEG3;

SEG7_LUT	u0	(	oSEG0,iDIG[3:0],flash		);
SEG7_LUT	u1	(	oSEG1,iDIG[7:4],flash		);
SEG7_LUT0	u2	(	oSEG2,iDIG[11:8],flash,flg	);
SEG7_LUT0	u3	(	oSEG3,iDIG[15:12],flash,flg	);

endmodule