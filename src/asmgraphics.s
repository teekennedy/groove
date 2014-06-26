|asmgraphics

|SetupCharSet and FastStringXY were taken from TICT's ebook reader, and modified slightly.
|FastStringXY was modified to work with an 80 pixel wide screen buffer.
|The font is now stored as sprite data within the program rather than 
|pointed to at runtime, thus removing the need for SetupCharSet and
|allowing for custom fonts.
|TODO: Give TICT Proper credit like they ask for!

.data
	.xdef FontSprite
	.even
WheelBuffer:
	.long 0
	.xdef WheelBuffer

.data
    .global FastStringXY
FastStringXY:
    movem.l  %d3/%a2-%a4,-(%sp)

| d0 = x (NTS: do not clobber !).
| d1 = y (NTS: used only once at the beginning, d1 quickly becomes scratch
| register).
| d2 = scratch register (byteoffset, character).
| a0 = string.
    add.w    %d1,%d1
    move.w   %d1,%d2
    lsl.w    #2,%d2
    add.w    %d2,%d1
    move.l   WheelBuffer(%pc),%a1
    adda.w   %d2,%a1
| a1 = WheelBuffer + 10*y.

    move.l   (FontSprite),%a2
| a2 = start of font data (sprites).
    
_beginning_of_loop_FSXY_:
| Get next character.
    moveq    #0,%d2
    move.b   (%a0)+,%d2
    jbeq     _finished_FSXY_

    add.w    %d2,%d2
    move.w   %d2,%d1
    add.w    %d2,%d2
    add.w    %d1,%d2
    lea      1(%a2,%d2.w),%a4
| a4 = address of sprite data.

    move.w   %d0,%d1
    lsr.w    #4,%d1
    add.w    %d1,%d1
    lea      0(%a1,%d1.w),%a3
| a3 = address where the upper line of the sprite will be drawn (preliminary).
    
    cmpi.w   #6*0x67,%d2 | 6 * 'g'...
| Short branches are faster if not taken.
    jbeq     _have_small_g_letter_FSXY_

_draw_sprite_FSXY_:
    move.w   %d0,%d1
    andi.w   #0xF,%d1
    
    moveq    #8,%d2
    sub.w    %d1,%d2
    moveq    #5-1,%d1
    tst.w    %d2
    bge.s    _one_word_FSXY_

    neg.w    %d2

| NOTE: We are using XOR here, so this function can also be used
| for the 'white on black' strings
_loop_one_long_FSXY_:
    moveq    #0,%d3
    move.b   (%a4)+,%d3
    swap     %d3
    lsr.l    %d2,%d3
    eor.l    %d3,(%a3)
    lea      10(%a3),%a3
    
    dbf      %d1,_loop_one_long_FSXY_

    bra.s    _next_letter_FSXY_

_loop_one_word_FSXY_:
    lea      10(%a3),%a3

_one_word_FSXY_:
    clr.w    %d3
    move.b   (%a4)+,%d3
    lsl.w    %d2,%d3
    eor.w    %d3,(%a3)
    
    dbf      %d1,_loop_one_word_FSXY_

_next_letter_FSXY_:
    moveq    #0,%d1
    move.b   -6(%a4),%d1
    add.w    %d1,%d0
    jbra     _beginning_of_loop_FSXY_
    
_finished_FSXY_:
    movem.l  (%sp)+,%d3/%a2-%a4
    rts
    
_have_small_g_letter_FSXY_:
    lea      10(%a3),%a3
    jbra     _draw_sprite_FSXY_

    .global DrawWheelBufferBorders
DrawWheelBufferBorders:
| Do we really need to save ALL used registers?
    movem.l  %d0/%a0, -(%sp)
    move.l   WheelBuffer(%pc), %a0
    moveq    #125, %d0
0:
    move.b   #0x80, (%a0)
    lea      10(%a0), %a0
    dbf      %d0, 0b

    move.l   WheelBuffer(%pc), %a0
    moveq    #9, %d0
1:
    eori.w   #0xFFFF,     (%a0)+
    move.l   #0xFFFFFFFF, (%a0)+
    move.l   #0xFFFFFFFF, (%a0)+
    lea      130(%a0), %a0
    dbf      %d0, 1b
    
    movem.l   (%sp)+, %d0/%a0
    rts

    |.global DrawWheelSlot
|DrawWheelSlot:
| d0 = x
| d1 = y
| a0 = sprite
| a1, a2 = DARK_PLANE, LIGHT_PLANE respectively
    | movem.l  %d2-%d3, -(%sp)
    | add.w    %d1, %d1
    | move.w   %d1, %d2
    | lsl.w    #4, %d1
    | sub.w    %d2, %d1
    | subi.w   #28, %d1          | y = 30 * y - 28
    | 
    | move.w   %d0, %d2
    | lsr.w    #3, %d2
    | add.w    %d2, %d1          | %d1 = byteoffset into graphics plane
    | adda.w   %d1, %a1
    | adda.w   %d1, %a2
    | 
    | moveq    #8, %d2
    | divu.w   %d2, %d0
    | swap     %d0
    | andi.w   #7, %d0           | %d0 now rotation offset
| 
    | moveq    #13, %d1
    | 
| 0:
    | lea.l    28(%a1), %a1
    | lea.l    28(%a2), %a2
    | moveq    #4,  %d2
| 1:
    | clr.l    %d3
    | move.w   (%a0)+, %d3
    | swap     %d3
    | lsl      %d0, %d3
    | eor.l    %d3, (%a1)
    | eor.l    %d3, (%a2)
    | addq     #2, %a1
    | addq     #2, %a2
    | dbf      %d2, 1b
| 
    | dbf      %d1, 0f
| 
    | movem.l   (%sp)+, %d2-%d3
    | rts
