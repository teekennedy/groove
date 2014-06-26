// SongIO.c
// Created 12/15/2010; 1:04:27 AM

#include <vat.h>
#include <estack.h>
#include <alloc.h>
#include <string.h>
#include "songio.h"

#define SONGFOLDER SYMSTR("groove")
#define FILETYPE "GRV"

GrvHeader *SongHeaders;
unsigned short SongCount = 0;

short SongFolderExists(void)
{
	if (SymFindHome(SONGFOLDER).folder == H_NULL)
		return FALSE;
	return TRUE;
}

//good for a quick estimate, but will be wrong
//if user puts anything other than song files
//into SONGFOLDER. Assumes SongFolderExists.
short CountSongs(void)
{
	return FolderCount(DerefSym(SymFindHome(SONGFOLDER)));
}

//checks for valid file by checking for
//the filetype "GRV"
short isValidFile(HANDLE h)
{
	//All GRV files end with "\0
	if (strcmp(HToESI(h) - 4, FILETYPE) == 0 )
	{
		return TRUE;
	}
	return FALSE;
}

//assumes SongFolderExists
short CountValidSongs(void)
{
	if (SongCount)
		return SongCount;
	
	SYM_ENTRY *GrvSym;
	
	GrvSym = SymFindFirst(SONGFOLDER, FO_SINGLE_FOLDER);
	
	while (GrvSym)
	{
		if (isValidFile(GrvSym -> handle))
			SongCount++;
		GrvSym = SymFindNext();
	}
	return SongCount;
}

//Loads SongHeaders with information needed for songselect menu
//assumes SongFolderExists.
//returns false if memory allocation fails.
short LoadHeaders(void)
{
	short GrvFileIndex = 0;
	short SongHeadersIndex = 0;
	unsigned short *shortPointer = NULL;
	GrvHeader *CurrSongHeader = NULL;
	
	SYM_ENTRY *GrvSym;
	MULTI_EXPR *GrvFile;
	
	SongHeaders = malloc(SongCount * sizeof(GrvHeader));
	if (!SongHeaders)
	{
		return FALSE;
	}
	
	GrvSym = SymFindFirst(SONGFOLDER, FO_SINGLE_FOLDER);
	
	while (GrvSym)
	{
		GrvFile = HeapDeref(GrvSym -> handle);
		if (isValidFile(GrvSym -> handle))
		{
			
			GrvFileIndex = 0;
			CurrSongHeader = &SongHeaders[SongHeadersIndex];
			CurrSongHeader-> SongTitle = &GrvFile-> Expr[GrvFileIndex];
			while (GrvFile-> Expr[GrvFileIndex])
				GrvFileIndex++;
			GrvFileIndex++;
			CurrSongHeader-> SongArtist = &GrvFile-> Expr[GrvFileIndex];
			while (GrvFile-> Expr[GrvFileIndex])
				GrvFileIndex++;
			GrvFileIndex++;
			if (GrvFileIndex % 2)
				GrvFileIndex++;
			
			shortPointer = (unsigned short*)&GrvFile-> Expr[GrvFileIndex];
			CurrSongHeader-> MinBPM = *shortPointer;
			GrvFileIndex += 2;

			shortPointer = (unsigned short*)&GrvFile-> Expr[GrvFileIndex];
			CurrSongHeader-> MaxBPM = *shortPointer;
			GrvFileIndex += 2;

			shortPointer = (unsigned short*)&GrvFile-> Expr[GrvFileIndex];
			CurrSongHeader-> ModeBPM = *shortPointer;
			GrvFileIndex += 2;
			shortPointer = (unsigned short*)&GrvFile-> Expr[GrvFileIndex];
			CurrSongHeader-> DifficultyFlags = *shortPointer;
			GrvFileIndex += 2;
			CurrSongHeader-> DifficultyHeaders = (DifficultyHeader*)&GrvFile-> Expr[GrvFileIndex];
			
			//determine number of difficulties by counting bits set
			//uses Brian Kernighan's method -- thanks!
			unsigned char DiffFlagsForCount = CurrSongHeader-> DifficultyFlags & 0xF800;
			unsigned char DiffCount;
			for (DiffCount = 0; DiffFlagsForCount; DiffCount++)
			{
				DiffFlagsForCount &= DiffFlagsForCount - 1;
			}
			
			GrvFileIndex += DiffCount * sizeof(DifficultyHeader);
			
			CurrSongHeader-> BPMListOffset = GrvFileIndex;
			SongHeadersIndex++;
		}
		GrvSym = SymFindNext();
	}
	return TRUE;
}

short InitIO(void)
{
	if (SongFolderExists())
	{
		if (!FolderOp(SONGFOLDER, FOP_LOCK))
			return FALSE;
		CountValidSongs();
		return TRUE;
	}
	return FALSE;
}

void CleanupIO(void)
{
	FolderOp(SONGFOLDER, FOP_UNLOCK);
	if (SongHeaders)
		free(SongHeaders);
}
