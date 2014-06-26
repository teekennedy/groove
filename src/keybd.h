// keybd.h
// Created 12/3/2010; 1:47:39 AM

#ifndef KEYBD_HEADER
#define KEYBD_HEADER

extern volatile unsigned short keypad;
enum KEY_CODES {GRV_KEY_LEFT = 0x0002, GRV_KEY_DOWN = 0x0004,
		GRV_KEY_UP   = 0x0001, GRV_KEY_RIGHT  = 0x0008,
		GRV_KEY_CONFIRM  = 0x0010, GRV_KEY_ESCAPE  = 0x0020,
		GRV_KEY_ANY  = 0xFFFF};

void InitKeyboard(void);
void CleanupKeyboard(void);
void KeyRead(void);
void KeyWait(unsigned short waitkey);

#endif
