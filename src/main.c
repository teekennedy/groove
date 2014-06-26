// main.c
// Created 12/1/2010; 11:44:24 AM

#include <alloc.h>
#include "graphics.h"
#include "keybd.h"
#include "error.h"
#include "songio.h"

short InitHardware(void)
{
	InitKeyboard();
	if (!InitGraphics())
	{
		ThrowError("Grayscale failed.");
		return 0;
	}
	return 1;
}

void CleanupHardware(void)
{
	CleanupGraphics();
	CleanupKeyboard();
	CleanupIO();
}

char TitleScreen(void)
{
	char MenuSelection = 0;
	DisplayTitle();
	DrawMenuSelectArrows(MenuSelection);
	
	KeyWait(GRV_KEY_ANY);
	while (!(keypad & GRV_KEY_CONFIRM))
	{
		if (keypad & GRV_KEY_UP)
			MenuSelection--;
		else if (keypad & GRV_KEY_DOWN)
			MenuSelection++;
		else if (keypad & GRV_KEY_ESCAPE)
			return MENU_EXIT;
		
		if (MenuSelection < MENU_START)
			MenuSelection = MENU_EXIT;
		else if (MenuSelection > MENU_EXIT)
			MenuSelection = MENU_START;
		
		DrawMenuSelectArrows(MenuSelection);
		KeyWait(GRV_KEY_ANY);
	}
	return MenuSelection;
}

char SongSelect(void)
{
	// length * width * # of slots
    //  14   *  10   *     9   = 1260
    // however we have one last row of border (+10)
	if ((WheelBuffer = calloc(127, 10)) == NULL)
	{
		return FALSE;
	}
    // DrawWheelBufferBorders();
    GrvClearScreen();
    DrawSongWheel(0, 0);

    free(WheelBuffer);
    return TRUE;
}

void __main(void)
{
	if (!InitHardware())
		goto ENDPRGM;
	switch (TitleScreen())
	{
		case MENU_START:
			if (!InitIO())
			{
				ThrowError("Song folder 'groove' does not exist!");
				goto ENDPRGM;
			}
			if (!LoadHeaders())
			{
				ThrowError("Not enough memory to load all songs!");
				goto ENDPRGM;
			}
            if (!SongSelect())
            {
                ThrowError("Not enough memory to load graphics!");
                goto ENDPRGM;
            }
			KeyWait(GRV_KEY_CONFIRM);
			break;
		case MENU_OPTIONS:
			break;
		case MENU_EXIT:
			break;
	}
ENDPRGM:
	CleanupHardware();
}
