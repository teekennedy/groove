#
# Makefile for gcc4ti
#

CC = tigcc
CFLAGS = -Os -Wall -W -Wwrite-strings -ffunction-sections -fdata-sections
VPATH = lib src
OBJECTS = src/main.c asmgraphics.o graphics.o error.o keybd.o songio.o sprite.o lib/extgraph.a


all : groove.89z
groove.89z : $(OBJECTS)
	tigcc --optimize-code --cut-ranges --reorder-sections --merge-constants -o "Groove" -n Groove $(CFLAGS) -WA,-g,-t --optimize-nops --optimize-returns --optimize-branches --optimize-moves --optimize-tests --optimize-calcs --remove-unused -DUSE_TI89 -DOPTIMIZE_CALC_CONSTS -DMIN_AMS=100 -DKERNEL_FORMAT_BSS -DKERNEL_FORMAT_DATA_VAR -DSAVE_SCREEN $(OBJECTS)
songio.o : songio.h
graphics.o : extgraph.h sprite.h graphics.h
asmgraphics.o : asmgraphics.s
	/usr/local/share/gcc4ti/bin/as $< -o $@
