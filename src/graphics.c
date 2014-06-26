// graphics.c
// Created 12/1/2010; 12:56:48 PM

#include "../lib/extgraph.h"
#include "sprite.h"
#include "graphics.h"
#include "error.h"
#include <alloc.h>
#include <graph.h>

//initialize graphics
//returns FALSE if GrayOn() fails
short InitGraphics(void)
{
	WheelBuffer = NULL;
	return GrayOn();
}

//draws a string on both planes. Made because ExtGraph's version was causing an illegal instruction.
void GrvGrayDrawStr(short x, short y, const char *str, short attr)
{
	GraySetAMSPlane(LIGHT_PLANE);
	DrawStr(x, y, str, attr);
	GraySetAMSPlane(DARK_PLANE);
	DrawStr(x, y, str, attr);
}

//display title screen
void DisplayTitle(void)
{
	short i;
	GrayFillScreen_R(0xFFFFFFFF, 0xFFFFFFFF);
	for (i = 0; i < 9; i++)
	{
		Sprite16_AND_R((i << 4) + 8, 5, 54, &(TitleScreenLight[i * 54]), GrayGetPlane(LIGHT_PLANE));
		Sprite16_AND_R((i << 4) + 8, 5, 54, &(TitleScreenDark[i * 54]), GrayGetPlane(DARK_PLANE));
	}
	FontSetSys(F_8x10);
	GrvGrayDrawStr(60, 62, "Start", A_XOR);
	GrvGrayDrawStr(52, 74, "Options", A_XOR);
	GrvGrayDrawStr(64, 86, "Exit", A_XOR);
}
//probably a good idea to give the user some feedback as to which option they're on.
void DrawMenuSelectArrows(short selection)
{
	Sprite16_OR_R(34, 59, 16, TitleScreenLight, GrayGetPlane(DARK_PLANE));
	Sprite16_OR_R(110, 59, 16, TitleScreenLight, GrayGetPlane(DARK_PLANE));
	
	Sprite16_OR_R(34, 71, 16, TitleScreenLight, GrayGetPlane(DARK_PLANE));
	Sprite16_OR_R(110, 71, 16, TitleScreenLight, GrayGetPlane(DARK_PLANE));
	
	Sprite16_OR_R(34, 83, 16, TitleScreenLight, GrayGetPlane(DARK_PLANE));
	Sprite16_OR_R(110, 83, 16, TitleScreenLight, GrayGetPlane(DARK_PLANE));
	
	switch (selection)
	{
		case MENU_START:
			Sprite16_XOR_R(34, 59, 16, &ArrowsDark[48], GrayGetPlane(DARK_PLANE));
			Sprite16_XOR_R(110, 59, 16, ArrowsDark, GrayGetPlane(DARK_PLANE));
			break;
		case MENU_OPTIONS:
			Sprite16_XOR_R(34, 71, 16, &ArrowsDark[48], GrayGetPlane(DARK_PLANE));
			Sprite16_XOR_R(110, 71, 16, ArrowsDark, GrayGetPlane(DARK_PLANE));
			break;
		case MENU_EXIT:
			Sprite16_XOR_R(34, 83, 16, &ArrowsDark[48], GrayGetPlane(DARK_PLANE));
			Sprite16_XOR_R(110, 83, 16, ArrowsDark, GrayGetPlane(DARK_PLANE));
			break;
	}
}

//redundant function to preserve modularity
void GrvClearScreen(void)
{
	GrayClearScreen_R();
}

void CleanupGraphics(void)
{
	if (WheelBuffer)
		free(WheelBuffer);
	if (GrayCheckRunning())
		GrayOff();
}

void DrawSongWheel(short wheelIndex, short yOffset)
{
    short drawCount = 0;

    for (;drawCount < 7; drawCount++)
    {
        short y = drawCount * 14 + yOffset;
        // song_wheel_lookup_table wraps over itself to save space
        short x = (y > 49) ? song_wheel_lookup_table[99 - y] : song_wheel_lookup_table[y];

        // the code for DrawWheelSlot causes linker error "unresolved reference
        // to `L3'" While I try to track down the source of that bug, SpriteX8
        // comes in as a temporary replacment
        //DrawWheelSlot(x, y, WheelBuffer + ((wheelIndex + drawCount) % 9) * WHEEL_SLOT_SIZE, GrayGetPlane(DARK_PLANE), GrayGetPlane(LIGHT_PLANE));
        SpriteX8_OR_R(x, y, 15, WheelBuffer + ((wheelIndex + drawCount) % 9) * WHEEL_SLOT_SIZE, 5, GrayGetPlane(DARK_PLANE));
        SpriteX8_OR_R(x, y, 15, WheelBuffer + ((wheelIndex + drawCount) % 9) * WHEEL_SLOT_SIZE, 5, GrayGetPlane(LIGHT_PLANE));
    }
}

//development function to display all characters for font to sprite conversion
//saved for reference
/*
void DisplayCharSet (void)
{
	FontSetSys(F_4x6);
	GrvClearScreen();
	unsigned char c;
	for (c = 0; c < 255; c++)
	{
		GrvGrayDrawStr((c % 20) * 8, c / 20 * 6, (const char *)(&c), A_NORMAL);
	}
}
*/
