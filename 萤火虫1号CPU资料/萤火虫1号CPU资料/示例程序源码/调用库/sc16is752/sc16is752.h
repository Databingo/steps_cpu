/**********************************************/
/*
/*		sc16is752驱动		2022.12 龙少
/*
/**********************************************/

#include "cpuio.h"

/* SC16IS752接口IO定义(I2C/SPI引脚接GND选择SPI模式) */
#define SC16IS752_CS	M_CS5
#define SC16IS752_SI	M_IO1_D3
#define SC16IS752_SO    IO0_DI2
#define SC16IS752_CLK	M_IO0_DO5
#define SC16IS752_IRQ	IO0_DI3

/* IO控制宏 */
#define SC16IS752_CS_LOW		(IO0 = IO0_INIT_VALUE | SC16IS752_CS)
#define SC16IS752_CS_CLK_LOW	(IO0 = (IO0_INIT_VALUE | SC16IS752_CS) & ~SC16IS752_CLK)
#define SC16IS752_CS_CLK_HIGH	(IO0 = IO0_INIT_VALUE)

/* 写8位数据至SC16IS752 */
#define SC16IS752_SPI_TX(data) \
    IO1 = (unsigned char)(data) >> 4; \
    SC16IS752_CS_CLK_LOW; \
    SC16IS752_CS_LOW; \
    IO1 = (unsigned char)(data) >> 3; \
    SC16IS752_CS_CLK_LOW; \
    SC16IS752_CS_LOW; \
    IO1 = (unsigned char)(data) >> 2; \
    SC16IS752_CS_CLK_LOW; \
    SC16IS752_CS_LOW; \
    IO1 = (unsigned char)(data) >> 1; \
    SC16IS752_CS_CLK_LOW; \
    SC16IS752_CS_LOW; \
    IO1 = (unsigned char)(data); \
    SC16IS752_CS_CLK_LOW; \
    SC16IS752_CS_LOW; \
    IO1 = (unsigned char)(data) << 1; \
    SC16IS752_CS_CLK_LOW; \
    SC16IS752_CS_LOW; \
    IO1 = (unsigned char)(data) << 2; \
    SC16IS752_CS_CLK_LOW; \
    SC16IS752_CS_LOW; \
    IO1 = (unsigned char)(data) << 3; \
    SC16IS752_CS_CLK_LOW; \
    SC16IS752_CS_LOW;

/* 从SC16IS752读取8位数据 */
#define SC16IS752_SPI_RX(data) \
    SC16IS752_CS_CLK_LOW; \
    SC16IS752_CS_LOW; \
	(data) = SC16IS752_SO; \
    SC16IS752_CS_CLK_LOW; \
    SC16IS752_CS_LOW; \
	(data) = ((unsigned char)(data) << 1) | SC16IS752_SO; \
    SC16IS752_CS_CLK_LOW; \
    SC16IS752_CS_LOW; \
	(data) = ((unsigned char)(data) << 1) | SC16IS752_SO; \
    SC16IS752_CS_CLK_LOW; \
    SC16IS752_CS_LOW; \
	(data) = ((unsigned char)(data) << 1) | SC16IS752_SO; \
    SC16IS752_CS_CLK_LOW; \
    SC16IS752_CS_LOW; \
	(data) = ((unsigned char)(data) << 1) | SC16IS752_SO; \
    SC16IS752_CS_CLK_LOW; \
    SC16IS752_CS_LOW; \
	(data) = ((unsigned char)(data) << 1) | SC16IS752_SO; \
    SC16IS752_CS_CLK_LOW; \
    SC16IS752_CS_LOW; \
	(data) = ((unsigned char)(data) << 1) | SC16IS752_SO; \
    SC16IS752_CS_CLK_LOW; \
    SC16IS752_CS_LOW; \
	(data) = ((unsigned char)(data) << 1) | SC16IS752_SO;


/* SC16IS752时钟速度,单位Hz */
#define SC16IS752_ClockSpeed	1843200

/* 通道 */
#define SC16IS752_Channel_A 0x00
#define SC16IS752_Channel_B 0x01

/* 寄存器地址(通用寄存器) */
#define SC16IS752_RHR       0x00
#define SC16IS752_THR       0x00
#define SC16IS752_IER       0x01
#define SC16IS752_FCR       0x02
#define SC16IS752_IIR       0x02
#define SC16IS752_LCR       0x03
#define SC16IS752_MCR       0x04
#define SC16IS752_LSR       0x05
#define SC16IS752_MSR       0x06
#define SC16IS752_SPR       0x07
#define SC16IS752_TCR       0x06
#define SC16IS752_TLR       0x07
#define SC16IS752_TXLVL     0x08
#define SC16IS752_RXLVL     0x09
#define SC16IS752_IODir     0x0A
#define SC16IS752_IOState   0x0B
#define SC16IS752_IOIntEna  0x0C
#define SC16IS752_IOControl 0x0E
#define SC16IS752_EFCR      0x0F

/* 寄存器地址(特殊寄存器) */
#define SC16IS752_DLL       0x00
#define SC16IS752_DLH       0x01

/* 寄存器地址(增强型寄存器) */
#define SC16IS752_EFR       0x02
#define SC16IS752_Xon1      0x04
#define SC16IS752_Xon2      0x05
#define SC16IS752_Xoff1     0x06
#define SC16IS752_Xoff2     0x07


extern void SC16IS752_Open(unsigned char Channel, unsigned char BitLen, unsigned long BitRate, unsigned char CheckBit, unsigned char StopBit);
extern void SC16IS752_Close(unsigned char Channel);
extern void SC16IS752_WriteReg(unsigned char Channel, unsigned char RegAddr, unsigned char Data);
extern unsigned char SC16IS752_ReadReg(unsigned char Channel, unsigned char RegAddr);
extern void SC16IS752_TX(unsigned char Channel, unsigned long DataLen, void* DataBuf);
extern unsigned char SC16IS752_RX(unsigned char Channel, void* DataBuf);
