// error.c
// Created 12/3/2010; 1:18:31 AM

#include "graphics.h"
#include "keybd.h"
#include <string.h>
#include <graph.h>

void ThrowError(const char* message)
{
	GrvClearScreen();
	FontSetSys(F_4x6);
	DrawStr(0,0, message, A_NORMAL);
	KeyWait(GRV_KEY_CONFIRM);
}

void ThrowErrorWithValue(const char* message, short value)
{
	char buffer[20];
	char *valueString = (char *)buffer;
	GrvClearScreen();
	FontSetSys(F_4x6);
	DrawStr(0,0, message, A_NORMAL);
	sprintf(valueString, "%X", value);
	DrawStr(0,7, valueString, A_NORMAL);
	KeyWait(GRV_KEY_CONFIRM);
}
