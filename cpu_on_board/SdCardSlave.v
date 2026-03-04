

module SdCardSlave (
	clk,
	reset,

	address,
	read,
	write,
	writedata,
	readdata,
	
	begintransfer,
	
	SD_CLK,
	SD_CMD,
	SD_DAT,
	SD_DAT3
);

	input				clk;
	input				reset;
	
	input				begintransfer;

	input		[2:0]	address;
	input				read;
	input				write;
	input		[31:0]	writedata;
	output		[31:0]	readdata;
		
	output				SD_CLK;					//	SD Card Clock
	inout				SD_CMD;					//	SD Card Command Signal
	inout				SD_DAT;					//	SD Card Data
	inout				SD_DAT3;				//	SD Card Data 3
/*	
	reg					SDDATwrite;
	reg					SDDAT;
	reg					SDCMDwrite;
	reg					SDCMD;
	reg					SDCLK;
	
	assign SD_CLK		= SDCLK;
	assign SD_DAT		= SDDATwrite? SDDAT : 1'bZ;
	assign SD_CMD		= SDCMDwrite? SDCMD : 1'bZ;
	assign SD_DAT3		= 1'b1;
	
	always @(posedge clk)
	begin
		if (reset)
		begin
			SDDATwrite = 0;
			SDDAT = 0;
			SDCMDwrite = 0;
			SDCMD = 0;
			SDCLK = 0;
		end
		else
		begin
			if (write)
			begin
				SDCLK = writedata[0];
				SDCMDwrite = writedata[1];
				SDCMD = writedata[2];
				SDDATwrite = writedata[3];
				SDDAT = writedata[4];
			end
			if (read)
				readdata = {25'b0, SD_DAT, SD_CMD, SDDAT, SDDATwrite, SDCMD, SDCMDwrite, SDCLK};
		end
	end
*/

	reg			[135:0]	Response;
	reg			[47:0]	Command;
	reg			[31:0]	Data;
	reg					CommandFinished;
	reg					ResponseFinished;
	reg					IdleFinished;
	reg			[1:0]	State;
	reg					DataState;
	reg			[7:0]	Counter;
	reg			[3:0]	IdleCounter;
	reg			[4:0]	DataBitCounter;
	reg			[6:0]	DataWordCounter;
	reg					RdFifoWrite;
	
	wire				RdFifoEmpty;
	wire				RdFifoFull;
	wire		[31:0]	RdFifoData;

	SdCardRdFifo rdfifo
	(
		.clock(clk),
		.data(Data),
		.rdreq(read && address==6 && !RdFifoEmpty && begintransfer),
		.wrreq(RdFifoWrite && !RdFifoFull),
		.empty(RdFifoEmpty),
		.full(RdFifoFull),
		.q(RdFifoData)
	);

	
	assign SD_CLK		= clk;
	assign SD_CMD		= State==1? Command[47] : 1'bZ;
	assign SD_DAT		= 1'bZ;
	assign SD_DAT3		= 1'b1;
	
	assign readdata		=	address==0? {26'b0, RdFifoFull, RdFifoEmpty, IdleFinished, ResponseFinished, CommandFinished, 1'b0} :
							address==1? Response[135:104] :
							address==2? Response[103:72] :
							address==3? Response[71:40] :
							address==4? Response[39:8] :
							address==5? {24'b0, Response[7:0]} :
							address==6? RdFifoData : 
							32'b0;

							
		
/*	always @(address or State or Response or ResponseFinished or CommandFinished or IdleFinished or RdFifoFull or RdFifoEmpty or RdFifoData)
	case (address)
		0: readdata = {26'b0, RdFifoFull, RdFifoEmpty, IdleFinished, ResponseFinished, CommandFinished, 1'b0};
		1: readdata = Response[135:104];
		2: readdata = Response[103:72];
		3: readdata = Response[71:40];
		4: readdata = Response[39:8];
		5: readdata = {24'b0, Response[7:0]};
		6: readdata = RdFifoData;
		default: readdata = 32'b0;
	endcase
*/	
	
	always @(posedge clk)
	begin
		if (reset)
		begin
			CommandFinished = 0;
			ResponseFinished = 0;
			IdleFinished = 0;
			Response = 0;
			Command = 0;
			State = 0;
			DataState = 0;
			Counter = 0;
			DataBitCounter = 0;
			DataWordCounter = 0;
			RdFifoWrite = 0;
		end
		else
		begin
			RdFifoWrite = 0;
			
			if (DataState == 0 && State == 0)
			begin
				if (IdleCounter == 8)
					IdleFinished = 1;
				else
				begin
					IdleCounter = IdleCounter + 1'b1;
					IdleFinished = 0;
				end
			end
			else
			begin
				IdleFinished = 0;
				IdleCounter = 0;
			end
			
			case (DataState)
				default:
					begin
						DataBitCounter = 0;
						DataWordCounter = 0;
						
						if (SD_DAT == 0)
							DataState = 1;
					end
					
				1:	begin
						Data = {Data[30:0], SD_DAT};
						
						if (DataBitCounter == 31)
						begin
							RdFifoWrite = 1;
							DataBitCounter = 0;
							
							if (DataWordCounter == 127)
								DataState = 0;
							else
								DataWordCounter = DataWordCounter + 1'b1;
						end
						else						
							DataBitCounter = DataBitCounter + 1'b1;
					end
			endcase
			
			case (State)
				default:
					begin
						if (SD_CMD == 0)
						begin
							State = 2;
							Counter = 1;
							Response = 0;
						end
						else
							Counter = 0;
					end
				1:	begin
						Command = {Command[46:0], 1'b1};
					
						if (Counter == 47)
						begin
							State = 0;
							CommandFinished = 1;
						end
						else
							Counter = Counter + 1'b1;
						
						
					end
				2:	begin
						Response = {Response[134:0], SD_CMD};
						
						if (Counter == 135)
						begin
							State = 0;
							ResponseFinished = 1;
						end
						else
							Counter = Counter + 1'b1;
					end
			endcase
			
			if (write)
			begin
				if (address == 0)
				begin
					if (writedata[0])
					begin
						State = 1;
						Counter = 0;
						IdleCounter = 0;
						CommandFinished = 0;
						ResponseFinished = 0;
						IdleFinished = 0;
					end
				end
				else if (address == 1)
					Command[31:0] = writedata;
				else if (address == 2)
					Command[47:32] = writedata[15:0];
			end
		end
	end
	
endmodule

