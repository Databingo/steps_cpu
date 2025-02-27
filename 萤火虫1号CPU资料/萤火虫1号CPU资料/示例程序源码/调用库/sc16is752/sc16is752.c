/**********************************************/
/*
/*		sc16is752����		2022.12 ����
/*
/**********************************************/

#include "sc16is752.h"

/************************************/
/*	Channel = 0 : ͨ��A				*/
/*	Channel = 1 : ͨ��B				*/
/*	BitLen = 5 : λ����Ϊ5			*/
/*	BitLen = 6 : λ����Ϊ6			*/
/*	BitLen = 7 : λ����Ϊ7			*/
/*	BitLen = 8 : λ����Ϊ8			*/
/*	BitRate = ������(bps)			*/
/*	CheckBit = 0 : ��У��			*/
/*	CheckBit = 1 : ��У��			*/
/*	CheckBit = 3 : żУ��			*/
/*	CheckBit = 5 : ǿ��Ϊ1			*/
/*	CheckBit = 7 : ǿ��Ϊ0			*/
/*	StopBit = 0 : ֹͣλΪ1λ		*/
/*	StopBit = 1 : ֹͣλ���Ϊ2λ	*/
/************************************/

/* ��SC16IS752(���������ϱ���ʾ) */
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

/* �ر�SC16IS752(Channelѡ��ͨ��) */
void SC16IS752_Close(unsigned char Channel) {
	SC16IS752_WriteReg(Channel, SC16IS752_LCR, 0x80);
	SC16IS752_WriteReg(Channel, SC16IS752_DLL, 0);
	SC16IS752_WriteReg(Channel, SC16IS752_DLH, 0);
}

/* д�Ĵ�������, RegAddr�Ĵ�����ַ, Channelѡ��ͨ��, Dataд������ */
void SC16IS752_WriteReg(unsigned char Channel, unsigned char RegAddr, unsigned char Data) {
	unsigned char cmd;

	cmd = ((RegAddr << 3) & (unsigned char)0x78) | ((Channel << 1) & (unsigned char)0x02);

	SC16IS752_CS_LOW;
	SC16IS752_SPI_TX(cmd);
	SC16IS752_SPI_TX(Data);
	SC16IS752_CS_CLK_HIGH;
}

/* ���Ĵ�������, RegAddr�Ĵ�����ַ, Channelѡ��ͨ��, ����ֵΪ�Ĵ�������*/
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
/* ��������(ÿ�������64�ֽ�,��Ҫ��ѯFIFO�Ƿ��п����ֽ�, Channelѡ��ͨ��, DataLenΪ�������ݴ�С, DataBufΪ���ݻ�����) */
void SC16IS752_TX(unsigned char Channel, unsigned long DataLen, void* DataBuf) {
	unsigned char* p = DataBuf;

	for (; DataLen != 0; --DataLen)
		SC16IS752_WriteReg(Channel, SC16IS752_THR, *p++);
}
#else
/* ��������(Channelѡ��ͨ��, DataLenΪ�������ݴ�С, DataBufΪ���ݻ�����) */
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

/* ��������(ÿ��������64�ֽ�,��Ҫ���ϵ��øú����Բ�ѯ�Ƿ���յ�����,�������򷵻����ݳ���,���򷵻�0, Channelѡ��ͨ��, DataBufΪ���ݻ�����) */
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
