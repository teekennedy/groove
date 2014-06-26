// graphics.h
// Created 12/1/2010; 1:01:27 PM

#ifndef GRAPHICS_HEADER
#define GRAPHICS_HEADER

#define WHEEL_SLOT_SIZE 10 * 14
enum {MENU_START, MENU_OPTIONS, MENU_EXIT};

short InitGraphics(void);
void DisplayTitle(void);
void DrawMenuSelectArrows(short);
void DisplayCharSet(void);
void GrvClearScreen(void);
void CleanupGraphics(void);
short InitSongSelect (void);
void DrawSongWheel(short wheelIndex, short yOffset);

//functions and variables specific to asmgraphics.s
void __attribute__((__regparm__(3))) FastStringXY(register short x asm("%d0"), register short y asm("%d1"),register const unsigned char* s asm("%a0"));
extern unsigned char *WheelBuffer;
void DrawWheelBufferBorders();
void __attribute__((__regparm__(5))) DrawWheelSlot(register unsigned short x asm("%d0"), register unsigned short y asm("%d1"),register unsigned char* WheelSlot asm("%a0"), register void *DarkPlane asm("%a1"), register void *LightPlane asm("%a2"));

#endif
