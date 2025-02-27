#include "st7789.h"
#include "printf.h"
#include "ch375.h"
#include "mouse.h"
#include "DispRam.h"
#include "PrintChar.h"

/* 初始值 */
#define MandelbrotStartX		LCD_WIDTH / 2 + 64		//起始坐标X
#define MandelbrotStartY		LCD_HIGH  / 2			//起始坐标Y
#define MandelbrotStartZoom		0.01					//聚焦值
#define MAXITER 50										//迭代次数

/* 浮点类型切换 */
#if 0
#define float double
#define MULT_CONST 2.0
#else
#define MULT_CONST 2.0f
#endif

/* 计算曼德博分形并写入显存 */
void CalculateMandelbrot(int64_t xoff, int64_t yoff, float mult, int32_t MAX_ITER) {
	int32_t i, j, iter_num;
	float x, y, xt, xpos, ypos;

	for (i = 0; i < LCD_HIGH; ++i) {
		for (j = 0; j < LCD_WIDTH; ++j) {
			float ResultX, ResultY;
			uint16_t Pixel;

			iter_num = 0;
			x = 0.0;
			y = 0.0;

			//计算曼德博罗
			xpos = (j - xoff) * mult;
			ypos = (i - yoff) * mult;

			while ((ResultX = x * x) + (ResultY = y * y) < MULT_CONST * MULT_CONST && iter_num < MAX_ITER) {
				xt = ResultX - ResultY + xpos;
				y = MULT_CONST * x * y + ypos;
				x = xt;
				++iter_num;
			}

			//生成像素数据
			if (iter_num <= (MAX_ITER >> 1)) {
				if (iter_num <= (MAX_ITER >> 2))
					Pixel = (0x1f * iter_num / (MAX_ITER >> 2));
				else
					Pixel = ((0x3f * (iter_num - (MAX_ITER >> 2)) / (MAX_ITER >> 2)) << 5) | 0x1f;
			}
			else
				Pixel = (0x1f * (MAX_ITER - iter_num) / (MAX_ITER >> 1)) << 11;

			//像素数据写入显存
			DispRam[j][i] = Pixel;

			//更新鼠标状态
			if (UsbUpdate() == (uint8_t)1)
				MovMouse(GetMouseX, GetMouseY);
		}
		//显示坐标及放大倍数
		if (i < ASCII_Font->FontHigh * 3) {
			Printf_Set(0, 0, 0xffff, TrnColor);
			printf("X: %lld\n", -(xoff - LCD_WIDTH / 2));
			printf("Y: %lld\n", yoff - LCD_HIGH / 2);
			printf("Zoom: %.3f\n", 1 / mult);
		}

		//当前行显存数据更新至Lcd
		DispRam_ToLcd(0, i, LCD_WIDTH, 1);
	}
}

/* 矩形框显存数据更新至LCD */
void DispRam_RectBoxToLcd(uint16_t x, uint16_t y, uint16_t width, uint16_t high) {
	uint16_t StartX = x;
	uint16_t StartY = y;
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
		for (x = StartX; x < EndX;) {
#if 0
			uint16_t Color = DispRam[x][y];
			Lcd_WriteIndex(0x2a);
			Lcd_WriteData_16Bit_V(x);
			Lcd_WriteIndex(0x2b);
			Lcd_WriteData_16Bit_V(y);
			Lcd_WriteIndex(0x2c);
			Lcd_WriteData_16Bit_V(Color);
#else
			Lcd_Draw_Pixel(x, y, DispRam[x][y]);
#endif
			if (y > StartY && y < EndY - (uint16_t)1) {
				if (x == EndX - (uint16_t)1)
					break;
				else
					x = EndX - (uint16_t)1;
			}
			else
				++x;
		}
	}
}

/* Lcd绘制矩形框 */
void Lcd_DrawRectBox(uint16_t x, uint16_t y, uint16_t width, uint16_t high, uint16_t Color) {
	uint16_t StartX = x;
	uint16_t StartY = y;
	uint16_t EndX = x + width;
	uint16_t EndY = y + high;

	if (x + width > LCD_WIDTH)
		EndX = LCD_WIDTH;
	else
		EndX = x + width;
	if (y + high > LCD_HIGH)
		EndY = LCD_HIGH;
	else
		EndY = y + high;
	for (; y < EndY; ++y) {
		for (x = StartX; x < EndX;) {
#if 0
			Lcd_WriteIndex(0x2a);
			Lcd_WriteData_16Bit_V(x);
			Lcd_WriteIndex(0x2b);
			Lcd_WriteData_16Bit_V(y);
			Lcd_WriteIndex(0x2c);
			Lcd_WriteData_16Bit_V(Color);
#else
			Lcd_Draw_Pixel(x, y, Color);
#endif
			if (y > StartY && y < EndY - (uint16_t)1) {
				if (x == EndX - (uint16_t)1)
					break;
				else
					x = EndX - (uint16_t)1;
			} else
				++x;
		}
	}
}

void main() {

	/* 设备初始化 */
	Lcd_ST7789_Init(0);
	CH375_Init();

	/* 界面初始化 */
	DispRam_FillRectangle(0, 0, LCD_WIDTH, LCD_HIGH, 0);
	MovMouse(GetMouseX, GetMouseY);
	DispRam_ToLcd(0, 0, LCD_WIDTH, LCD_HIGH);
	CalculateMandelbrot(MandelbrotStartX, MandelbrotStartY, MandelbrotStartZoom, MAXITER);

	/* loop */
	while (1) {
		if (UsbUpdate() == (unsigned char)1) {
			static uint8_t KeyStep = 0;
			static uint16_t RectBoxStartX, RectBoxStartY, RectBoxEndX, RectBoxEndY;

			MovMouse(GetMouseX, GetMouseY);
			if (KeyStep == (uint8_t)0) {
				if (GetMouseButtonL != (uint8_t)0) {
					KeyStep = 1;
					RectBoxEndX = RectBoxStartX = GetMouseX;
					RectBoxEndY = RectBoxStartY = GetMouseY;
				}
			} else {
				if (GetMouseButtonL == (uint8_t)0) {
					KeyStep = 0;
					if (RectBoxStartX < RectBoxEndX && RectBoxStartY < RectBoxEndY) {
						static int64_t MandelbrotX = MandelbrotStartX;
						static int64_t MandelbrotY = MandelbrotStartY;
						static float MandelbrotZoom = MandelbrotStartZoom;
						float Mult;

						DispRam_RectBoxToLcd(RectBoxStartX, RectBoxStartY, RectBoxEndX - RectBoxStartX, RectBoxEndY - RectBoxStartY);
						if (RectBoxEndX - RectBoxStartX < RectBoxEndY - RectBoxStartY)
							Mult = (float)LCD_HIGH / (RectBoxEndY - RectBoxStartY);
						else
							Mult = (float)LCD_WIDTH / (RectBoxEndX - RectBoxStartX);
						MandelbrotZoom /= Mult;
						MandelbrotX = (MandelbrotX - RectBoxStartX - ((RectBoxEndX - RectBoxStartX) / (uint16_t)2)) * Mult + LCD_WIDTH / 2;
						MandelbrotY = (MandelbrotY - RectBoxStartY - ((RectBoxEndY - RectBoxStartY) / (uint16_t)2)) * Mult + LCD_HIGH / 2;
						CalculateMandelbrot(MandelbrotX, MandelbrotY, MandelbrotZoom, MAXITER);
					}
				} else {
					if (RectBoxEndX != GetMouseX || RectBoxEndY != GetMouseY) {
						if (RectBoxStartX < RectBoxEndX && RectBoxStartY < RectBoxEndY)
							DispRam_RectBoxToLcd(RectBoxStartX, RectBoxStartY, RectBoxEndX - RectBoxStartX, RectBoxEndY - RectBoxStartY);
						if(RectBoxStartX < GetMouseX && RectBoxStartY < GetMouseY)
							Lcd_DrawRectBox(RectBoxStartX, RectBoxStartY, GetMouseX - RectBoxStartX, GetMouseY - RectBoxStartY, 0xffff);
						RectBoxEndX = GetMouseX;
						RectBoxEndY = GetMouseY;
					}
				}
			}
		}
	}
}
