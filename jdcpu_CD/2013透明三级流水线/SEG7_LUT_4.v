module SEG7_LUT_4 (	oSEG0,oSEG1,oSEG2,oSEG3,iDIG,flash);
input	[15:0]	iDIG;
input   [0:0]   flash;
output	[6:0]	oSEG0,oSEG1,oSEG2,oSEG3;

SEG7_LUT	u0	(	oSEG0,iDIG[3:0],flash	);
SEG7_LUT	u1	(	oSEG1,iDIG[7:4],flash	);
SEG7_LUT	u2	(	oSEG2,iDIG[11:8],flash	);
SEG7_LUT	u3	(	oSEG3,iDIG[15:12],flash	);

endmodule