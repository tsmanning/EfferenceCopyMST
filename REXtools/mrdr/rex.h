/*
 *-----------------------------------------------------------------------*
 * NOTICE:  This code was developed by the US Government.  The original
 * versions, REX 1.0-3.12, were developed for the pdp11 architecture and
 * distributed without restrictions.  This version, REX 4.0, is a port of
 * the original version to the Intel 80x86 architecture.  This version is
 * distributed only under license agreement from the National Institutes 
 * of Health, Laboratory of Sensorimotor Research, Bldg 10 Rm 10C101, 
 * 9000 Rockville Pike, Bethesda, MD, 20892, (301) 496-9375.
 *-----------------------------------------------------------------------*
 */

/*
 * REX.H -- functions for REX A- and E-file data unpacking
 *
 * HISTORY
 *	24feb93	LMO	Create
 * $Log: rex.h,v $
 * Revision 1.2  2015/11/09 21:00:54  devel
 * Incorporate a fix for Britten Lab data, use -c arg.
 *
 * Revision 1.1.1.1  2015/11/09 19:27:39  devel
 * Initial add of download from http://datashare.nei.nih.gov/LsrDirectoryServlet, dated 5-8-2015.
 *
 * Revision 1.2  2006/06/06 18:57:18  jwm
 * Added support for 64 bit architectures
 *
 * Revision 1.1.1.1  2004/11/19 17:16:37  jwm
 * Imported using TkCVS
 *
 * Revision 1.8  1999/09/28 18:34:24  lmo
 * add comment to adRate
 *
 * Revision 1.7  1996/03/17 19:20:55  lmo
 * rexunit support
 *
 * Revision 1.6  1995/11/02  16:26:28  lmo
 * allow up to 32 unit codes
 *
 * Revision 1.5  1993/04/07  18:26:33  lmo
 * -112 codes
 *
 * Revision 1.4  1993/04/03  22:16:26  lmo
 * samp header
 *
 * Revision 1.3  1993/03/05  14:23:02  lmo
 * include continue flag in AIX structure
 *
 * Revision 1.2  1993/03/03  23:41:00  lmo
 * fix event error macro
 *
 * Revision 1.1  1993/02/25  22:54:24  lmo
 * Initial revision
 *
 */

#ifndef __REX_H__
#define __REX_H__

/*
 * include necessary rex headers
 */
/* #include "sys.h" */
#include "proc.h"
#include "buf.h"
#include "ecode.h"

#define PRIVATE	static

#define rexNchannels	3
#define rexMaxSignals	32
#define rexMaxUnits	199	/* units = 601 to 799 */

#ifndef INIT_MASK
#define INIT_MASK	020000
#define CANCEL_MASK	040000
#endif

#define TIMECHECK   1000	/* time in msec for check of drastic
				   reduction in event times */

/*
 * REX -110 and -111 channel masks for h- and v-buffers
 */
#define MASK_N		4
#define MASK_0		000000
#define MASK_1		010000
#define MASK_2		020000
#define MASK_3		040000
#define MASK_12		007777
#define MASK_ALL	(MASK_1 | MASK_2 | MASK_3)

/*
 * ucd BCODE mask and values.
 */

#define	BCODE_FLAG		0x1000
#define BCODE_FLOAT		(BCODE_FLAG | 0x800)
#define BCODE_INT		(BCODE_FLAG | 0x400)
#define BCODE_UINT		(BCODE_FLAG | 0x200)
#define BCODE_MARK		(BCODE_FLAG | 0x100)
#define BCODE_CHANNEL_MASK	0x00ff
#define BCODE_MASK (BCODE_FLOAT | BCODE_INT | BCODE_UINT | BCODE_MARK)

/*
 * macros
 */
#define rexSignalRound(z)	((int)((z) + 0.5))	/* rounding for Signal type */
#define rexSignalLoop(S)	for (S = signalList; S; S = S->next)

/*
 * Rex Tools Types
 */

typedef struct unitinfo {
	int32_t *nTimes;		/* number of times for each unit */
	int32_t **unitTimes;	/* time of occurrence for each spike */
}  RexUnits;

/*
 * trial list structure
 */
typedef struct {
	int32_t events;		/* index of start code event */
	int32_t firstEvent;	/* index of first event in trial */
	int32_t nEvents;		/* number of events in this trial */

	RexUnits rexunits;	/* rex units when split out */

	int32_t tStartTime;	/* time of first event in trial */
	int32_t tEndTime;		/* time of last event in trial */

	int32_t recNum;		/* corresponding analog records */
	int32_t aStartTime;	/* time of first point in signal */
	int32_t aEndTime;		/* time of last point in signal */
} Trial;

typedef int16_t RexSignal;

typedef struct siglist {
	RexSignal *signal;	/* pointer to Signal array */
	int32_t npts;		/* number of points in signal */
	int32_t count;		/* number of this signal */
	int32_t index;		/* signal array index for this signal */
	int32_t sigChan;		/* rex channel number */
	char *sigName;		/* name of signal channel */
	char *sigLabel;		/* label for signal */
	int32_t adRate;		/* a/d rate in Hz of this signal, even after interpolation */
	int32_t storeRate;		/* REX store rate in Hz */
	float fscale;		/* a/d fullscale */
	float scale;		/* takes a/d levels to fullscale */
	int32_t sigGain;		/* rex gain table index */
	struct siglist *next;	/* pointer to next element in list */
} SignalList;

typedef struct rexinfo {
	int32_t nSignals;		/* number of signals */
	SignalList *signalList;	/* pointer to list of signals */
	int32_t nPoints;		/* max number of points in signals */
	int32_t ad_res;		/* a/d resolution in bits */
	int32_t aStartTime;	/* time of first point in signal */
	int32_t aEndTime;		/* time of last point in signal */

	EVENT *events;		/* pointer to event array for this trial */
	int32_t nEvents;		/* number in event array for this trial*/

	RexUnits *rexunits;	/* rex unit structure for this trial if splitting events */
	int32_t nUnits;		/* number of different units between 601 and 699 */
	int16_t *unitCodes;		/* codes for each unit */

	int32_t tStartTime;	/* time of first point in trial */
	int32_t tEndTime;		/* time of last point in trial */

	int32_t numTrials;		/* number of trial periods */
	int32_t numRec;		/* number of analog records */
	char *ehdr;		/* E-file header */
	char *ahdr;		/* A-file header */
	int32_t maxSampRate;	/* maximum sample rate of any stored signal */
	int32_t startCode;		/* trial start code */
} RexInfo;

/*
 * analog record index structure
 */
typedef struct {
	int32_t key;	/* A-file offset */
	int32_t loEv;	/* event buffer pointer */
	int32_t nEv;	/* number of related events */
	int32_t strtTime;	/* time of record start */
	int32_t endTime;	/* approximate time of record end */
	int32_t cont;	/* continue flag */
	int32_t more;	/* more records coming */
	int32_t strt;	/* start record for this count */
} AIX;


typedef struct {
	char hi;
	char lo;
} * BYTEP;

typedef struct {
	int16_t hiword;
	int16_t loword;
} *WORDP;

/*
 * PUBLIC FUNCTION PROTOTYPES  * * * * * * * * * * * * * * * * * * * * * * * *
 */

/* rex signal functions */
void rexSplitEvents(void);
int32_t rexFileOpen(char *f, int32_t maxSampRate, int32_t startCode, int32_t preTime);
void rexFileClose(void);
void rexAtExit(void);
RexInfo *rexGetTrial(int32_t trialNumber, int32_t interpolateFlag);
RexInfo *rexGetEvents(int32_t trialNum);
RexInfo *rexGetAnalog(int32_t interpFlag);
RexInfo *rexGetSignals(int32_t recordNumber, int32_t interpolateFlag);
int32_t rexGetUnitCount(int32_t unitCode);
int32_t rexGetAnalogHeader(EVENT *ev, ANALOGHDR *ahdr);
void rexSetAWinCodes(int32_t openCd, int32_t closeCd, int32_t cancelCd);

/* printing functions */
char *rexToolsVersion(void);
char *rexTimeConv(int32_t time);
void rexTimePrint(int32_t time);
void rexHeaderPrint();
void rexTotalsPrint();
void rexEprint(EVENT *ev);
void rexAprint(EVENT *ev);
void rexInfoPrint(RexInfo *ri);
void rexSampHdrPrint();
#endif /* !__REX_H__ */
