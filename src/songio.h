// Header File
// Created 12/16/2010; 11:27:27 AM

#ifndef SONGIO_HEADER
#define SONGIO_HEADER

#define member_size(type, member) sizeof(((type *)0)-> member)

short InitIO(void);
void CleanupIO(void);
short LoadHeaders(void);

typedef struct
{
	unsigned char FootRating;
	unsigned char Voltage, Stream, Chaos, Freeze, Air;
	unsigned long ChartOffset;
}DifficultyHeader;

typedef struct
{
	unsigned short BeatOffsetWhole;
	unsigned char BeatOffsetPart;
	unsigned short BPM;
}BPMList;

typedef struct
{
	const char *SongTitle;
	const char *SongArtist;
	unsigned short MinBPM, MaxBPM, ModeBPM;
	unsigned short DifficultyFlags;
	DifficultyHeader* DifficultyHeaders;
	unsigned short BPMListOffset;
}GrvHeader;

extern GrvHeader *SongHeaders;
extern unsigned short SongCount;

#endif
