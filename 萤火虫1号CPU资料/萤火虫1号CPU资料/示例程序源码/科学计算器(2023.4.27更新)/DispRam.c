/**********************************************/
/*
/*		�Դ�		2022.10 - 2023.04 ����
/*
/**********************************************/

#include "DispRam.h"
#include "mouse.h"

/* �Դ� */
uint16_t DispRam[LCD_WIDTH][LCD_HIGH];

/* �Դ����ݸ�����LCD */
void DispRam_ToLcd(uint16_t x, uint16_t y, uint16_t width, uint16_t high) {
	uint16_t StartX = x;
	uint16_t EndX;
	uint16_t EndY;

	if (x + width > LCD_WIDTH)
		EndX = LCD_WIDTH;
	else
		EndX = x + width;
	if (y + high > LCD_HIGH)
		EndY = LCD_HIGH;
	else
		EndY = y + high;
	for (; y < EndY; ++y) {
		Lcd_SetRegion(StartX, EndX - 1, y, EndY - 1);
		Lcd_WriteIndex(0x2c);
		for (x = StartX; x < EndX; ++x) {
			if (x < GetMouseX || x >= GetMouseX + (uint16_t)MouseImageWidth || y < GetMouseY || y >= GetMouseY + (uint16_t)MouseImageHigh || \
				Image_Mouse[(y - GetMouseY) * (uint16_t)MouseImageWidth + (x - GetMouseX)] == (uint16_t)TrnColor) {
				uint16_t Color;

				Color = DispRam[x][y];
				Lcd_WriteData_16Bit_V(Color);
			} else {
				Lcd_SetRegion(x + 1, EndX - 1, y, EndY - 1);
				Lcd_WriteIndex(0x2c);
			}
		}
	}
}

/* ���Դ��ϻ��ƾ������ */
void DispRam_FillRectangle(uint16_t x, uint16_t y, uint16_t width, uint16_t high, uint16_t color) {
	uint16_t StartX = x;
	uint16_t EndX;
	uint16_t EndY;

	if (x + width > LCD_WIDTH)
		EndX = LCD_WIDTH;
	else
		EndX = x + width;
	if (y + high > LCD_HIGH)
		EndY = LCD_HIGH;
	else
		EndY = y + high;
	for (; y < EndY; ++y)
		for (x = StartX; x < EndX; ++x)
			DispRam[x][y] = color;
}

/* �Դ�װ��λͼ */
void DispRam_LoadImage(uint16_t x, uint16_t y, BitImage* image) {
	uint16_t StartX = x;
	uint16_t EndX;
	uint16_t EndY;
	uint16_t SkipX;
	uint16_t* PixelData = image->PixelData;

	if (x + image->Width > LCD_WIDTH) {
		SkipX = x + image->Width - LCD_WIDTH;
		EndX = LCD_WIDTH;
	}
	else {
		SkipX = 0;
		EndX = x + image->Width;
	}
	if (y + image->High > LCD_HIGH)
		EndY = LCD_HIGH;
	else
		EndY = y + image->High;
	for (; y < EndY; ++y) {
		for (x = StartX; x < EndX; ++x)
			DispRam[x][y] = *PixelData++;
		PixelData += SkipX;
	}
}
