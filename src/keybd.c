// keybd.c
// Created 12/3/2010; 1:18:47 AM

#include <kbd.h>
#include <intr.h>
#include <peekpoke.h>

INT_HANDLER oldInt1, oldInt5;
volatile unsigned short keypad;

//low-level keyboard read, getting all useful buttons.
void KeyRead(void)
{
	//get all 4 arrow keys and 2nd key
	keypad = _rowread(~0x1) & 0x1F;
	//get Enter key
	keypad |= (_rowread(~0x2) & 0x1) << 4;
	//get Esc key
	keypad |= (_rowread(~0x40) & 0x1) << 5;
}

void KeyWait(unsigned short waitkey)
{
	while(keypad)
	{
		KeyRead();
		//halts processor until further interrupt
		pokeIO(0x600005, 0b10111);
	}
	while(!(keypad & waitkey))
	{
		KeyRead();
		pokeIO(0x600005, 0b10111);
	}
}

void InitKeyboard(void)
{
	oldInt1 = GetIntVec(AUTO_INT_1);
	oldInt5 = GetIntVec(AUTO_INT_5);
	SetIntVec(AUTO_INT_1, DUMMY_HANDLER);
	SetIntVec(AUTO_INT_5, DUMMY_HANDLER);
	//get inital key readings
	//user is often still holding Enter at this point
	KeyRead();
}

void CleanupKeyboard(void)
{
	SetIntVec(AUTO_INT_1, oldInt1);
	SetIntVec(AUTO_INT_5, oldInt5);
	GKeyFlush();
}

