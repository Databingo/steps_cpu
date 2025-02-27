#include "st7789.h"
#include "printf.h"
#include "sc16is752.h"
#include "delay.h"

char Buf0[65];
char Buf1[65];
int BufCount0;
int BufCount1;

void main() {

	/* 初始化LCD */
	Lcd_ST7789_Init(0);

	/* 打开串口A通道和B通道 */
	SC16IS752_Open(SC16IS752_Channel_A, 8, 115200, 0, 0);
	SC16IS752_Open(SC16IS752_Channel_B, 8, 115200, 0, 0);

	Printf_Set(0, 0, 0xffff, 0);

	/************************************************************/
	/*					TX和RX短接即可自发自收					*/
	/************************************************************/

	while (1) {

		/* 通道A发送数据 */
		SC16IS752_TX(SC16IS752_Channel_A, sizeof("Hello!\n"), "Hello!\n");

		/* 通道B发送数据 */
		SC16IS752_TX(SC16IS752_Channel_B, sizeof("1234567890\n"), "1234567890\n");

		Delay(10000);

		/* 通道A接收数据 */
		BufCount0 = SC16IS752_RX(SC16IS752_Channel_A, Buf0);
		if (BufCount0 > 0) {
			if (printf_y > LCD_HIGH - 12) {
				Lcd_Clear(0);
				Printf_Set(0, 0, 0xffff, 0);
			}
			Buf0[BufCount0] = '\0';
			printf("%s", Buf0);
		}

		/* 通道B接收数据 */
		BufCount1 = SC16IS752_RX(SC16IS752_Channel_B, Buf1);
		if (BufCount1 > 0) {
			if (printf_y > LCD_HIGH - 12) {
				Lcd_Clear(0);
				Printf_Set(0, 0, 0xffff, 0);
			}
			Buf1[BufCount1] = '\0';
			printf("%s", Buf1);
		}
	}
}
