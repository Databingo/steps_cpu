#include "st7789.h"
#include "ch375.h"
#include"chidouzi.h"

void main() {

	/* 设备初始化 */
	Lcd_ST7789_Init(0);
	CH375_Init();
	chidouzi_init();

	/* loop */
	while (1) {
		if (UsbUpdate() == (unsigned char)1) {
			if (Keyboard_UpArrow != (unsigned char)0) KEY_O = 1; else KEY_O = 0;
			if (Keyboard_DownArrow != (unsigned char)0) KEY_U = 1; else KEY_U = 0;
			if (Keyboard_LeftArrow != (unsigned char)0) KEY_L = 1; else KEY_L = 0;
			if (Keyboard_RightArrow != (unsigned char)0) KEY_R = 1; else KEY_R = 0;
			if (Keyboard_Space != (unsigned char)0) KEY_D = 1; else KEY_D = 0;
		}
		chidouzi_run();
	}
}
