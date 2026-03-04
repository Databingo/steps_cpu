/**********************************************/
/*
/*		sc16is752驱动		2022.12 龙少
/*
/**********************************************/

#include "sc16is752.h"

/************************************/
/*	Channel = 0 : 通道A				*/
/*	Channel = 1 : 通道B				*/
/*	BitLen = 5 : 位长度为5			*/
/*	BitLen = 6 : 位长度为6			*/
/*	BitLen = 7 : 位长度为7			*/
/*	BitLen = 8 : 位长度为8			*/
/*	BitRate = 波特率(bps)			*/
/*	CheckBit = 0 : 无校验			*/
/*	CheckBit = 1 : 奇校验			*/
/*	CheckBit = 3 : 偶校验			*/
/*	CheckBit = 5 : 强制为1			*/
/*	CheckBit = 7 : 强制为0			*/
/*	StopBit = 0 : 停止位为1位		*/
/*	StopBit = 1 : 停止位最大为2位	*/
/************************************/

/* 打开SC16IS752(参数设置上表所示) */
void SC16IS752_Open(unsigned char Channel, unsigned char BitLen, unsigned long BitRate, unsigned char CheckBit, unsigned char StopBit) {
	unsigned long Div = SC16IS752_ClockSpeed / (BitRate << 4);

	SC16IS752_WriteReg(Channel, SC16IS752_LCR, 0x80);
	SC16IS752_WriteReg(Channel, SC16IS752_DLL, ((unsigned char*)&Div)[0]);
	SC16IS752_WriteReg(Channel, SC16IS752_DLH, ((unsigned char*)&Div)[1]);
	SC16IS752_WriteReg(Channel, SC16IS752_LCR, 0xbf);
	SC16IS752_WriteReg(Channel, SC16IS752_EFR, 0x10);
	SC16IS752_WriteReg(Channel, SC16IS752_LCR, ((CheckBit & (unsigned char)0x07) << 3) | ((StopBit & (unsigned char)0x01) << 2) | ((BitLen - (unsigned char)5) & (unsigned char)0x03));
	SC16IS752_WriteReg(Channel, SC16IS752_IER, 0x01);
	SC16IS752_WriteReg(Channel, SC16IS752_FCR, 0xf1);
	SC16IS752_WriteReg(Channel, SC16IS752_SPR, 0x41);
	SC16IS752_WriteReg(Channel, SC16IS752_IODir, 0xff);
	SC16IS752_WriteReg(Channel, SC16IS752_IOState, 0x00);
}

/* 关闭SC16IS752(Channel选择通道) */
void SC16IS752_Close(unsigned char Channel) {
	SC16IS752_WriteReg(Channel, SC16IS752_LCR, 0x80);
	SC16IS752_WriteReg(Channel, SC16IS752_DLL, 0);
	SC16IS752_WriteReg(Channel, SC16IS752_DLH, 0);
}

/* 写寄存器数据, RegAddr寄存器地址, Channel选择通道, Data写入数据 */
void SC16IS752_WriteReg(unsigned char Channel, unsigned char RegAddr, unsigned char Data) {
	unsigned char cmd;

	cmd = ((RegAddr << 3) & (unsigned char)0x78) | ((Channel << 1) & (unsigned char)0x02);

	SC16IS752_CS_LOW;
	SC16IS752_SPI_TX(cmd);
	SC16IS752_SPI_TX(Data);
	SC16IS752_CS_CLK_HIGH;
}

/* 读寄存器数据, RegAddr寄存器地址, Channel选择通道, 返回值为寄存器数据*/
unsigned char SC16IS752_ReadReg(unsigned char Channel, unsigned char RegAddr) {
	unsigned char cmd;
	unsigned char Data;

	cmd = ((RegAddr << 3) & (unsigned char)0x78) | ((Channel << 1) & (unsigned char)0x02) | (unsigned char)0x80;

	SC16IS752_CS_LOW;
	SC16IS752_SPI_TX(cmd);
	SC16IS752_SPI_RX(Data);
	SC16IS752_CS_CLK_HIGH;
	return Data;
}

#if 0
/* 发送数据(每次最大发送64字节,需要查询FIFO是否有空闲字节, Channel选择通道, DataLen为发送数据大小, DataBuf为数据缓冲区) */
void SC16IS752_TX(unsigned char Channel, unsigned long DataLen, void* DataBuf) {
	unsigned char* p = DataBuf;

	for (; DataLen != 0; --DataLen)
		SC16IS752_WriteReg(Channel, SC16IS752_THR, *p++);
}
#else
/* 发送数据(Channel选择通道, DataLen为发送数据大小, DataBuf为数据缓冲区) */
void SC16IS752_TX(unsigned char Channel, unsigned long DataLen, void* DataBuf) {
	unsigned char FIFO_Size = 0;
	unsigned char* p = DataBuf;

	for (; DataLen != 0; --DataLen) {
		while (FIFO_Size == (unsigned char)0)
			FIFO_Size = SC16IS752_ReadReg(Channel, SC16IS752_TXLVL);
		--FIFO_Size;
		SC16IS752_WriteReg(Channel, SC16IS752_THR, *p++);
	}
}
#endif

/* 接收数据(每次最大接收64字节,需要不断调用该函数以查询是否接收到数据,有数据则返回数据长度,否则返回0, Channel选择通道, DataBuf为数据缓冲区) */
unsigned char SC16IS752_RX(unsigned char Channel, void* DataBuf) {
	unsigned char* p = DataBuf;
	unsigned char Count = 0;
	unsigned char Len;

	if (SC16IS752_IRQ == (unsigned char)0 && (SC16IS752_ReadReg(Channel, SC16IS752_IIR) & (unsigned char)0x01) == (unsigned char)0x00) {
		Len = SC16IS752_ReadReg(Channel, SC16IS752_RXLVL);
		for (; Count < Len; ++Count)
			*p++ = SC16IS752_ReadReg(Channel, SC16IS752_RHR);
	}
	return Count;
}
