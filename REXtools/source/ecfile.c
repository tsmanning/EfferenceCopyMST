#ifdef _MSC_VER
// Stop compiler warnings about old-skool string stuff. 
#define _CRT_SECURE_NO_WARNINGS
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ecfile.h"
#include "bcode_defs.h"


#ifdef MATLAB_MEX_FILE
#include "mex.h"
#endif

struct ecfile_priv
{
	FILE *fptr;
	unsigned short lastseqno;
	int swap;
	char header[512];
	int flag;
};

typedef union
{
	char c[4];
	short s;
	unsigned short us;
	long l;
} UType;

static int f_counter=0;				/* running counter of ecodes read */
static int f_bcode_time = -1;
static int f_ecode_time = -1;
static char f_str[1024];			/* convenience for writing errmsg strings. Don't overwrite the end, please. */
static int f_verbose = 0;

static PEvent make_event(ECFile *this, PEvent pevent, unsigned short seqno, short ecode, int time);
static char *get_header(ECFile *this, char *h);
static int ecfile_next(ECFile *, PEvent, PECFS);
static void ecfile_rewind(ECFile *);
static void done(ECFile *);
static int make_ecfs(PEvent pev, PECFS pecfs);
static void swapshort(short *);
static void swaplong(int *);
static void errmsg(char *msg);
static void warnmsg(char *msg);

void ecfile_verbose(int i)
{
	f_verbose = i;
}

void ecfile_destroy(ECFile *ecfP)
{
	fclose(ecfP->priv->fptr);
#ifdef MATLAB_MEX_FILE
	mxFree(ecfP->priv);
	mxFree(ecfP);
#else
	free(ecfP->priv);
	free(ecfP);
#endif
}


ECFile *ecfile_new(const char *fname, int flag)
{
#ifdef MATLAB_MEX_FILE
	ECFile *this = (ECFile *) mxMalloc(sizeof(ECFile));
	struct ecfile_priv *p = (struct ecfile_priv *) mxMalloc(sizeof(struct ecfile_priv));
#else
	ECFile *this = (ECFile *) malloc(sizeof(ECFile));
	struct ecfile_priv *p = (struct ecfile_priv *) malloc(sizeof(struct ecfile_priv));
#endif

	int epos;
	int fpos;
	short *preclen;

	if (this==NULL || p==NULL)
	{
		errmsg("ecfile: Unable to malloc");
		return (ECFile *)NULL;
	}
	p->flag = flag;

	if (f_verbose) printf("Opening input file %s ...\n", fname);

	if ((p->fptr = fopen(fname, "rb"))==NULL)
	{
		sprintf(f_str, "ecfile: Unable to open input file %s", fname);
		errmsg(f_str);
		return (ECFile *)NULL;
	}

	if (f_verbose) printf("Read Efile header ...\n");
	if (f_verbose) printf("Before read, fpos is %ld\n", ftell(p->fptr));

	if (fread(p->header, 512, 1, p->fptr) != 1)
	{
		errmsg("ecfile: Unable to read file");
		return (ECFile *)NULL;
	}

	if (f_verbose) printf("After read, fpos is %ld\n", ftell(p->fptr));

	if (f_verbose) printf("Check header for endian-ness...\n");

	preclen = (short *)p->header;
	if (*preclen != 8)
	{
		if (*preclen!=0x0800)
		{
			errmsg("ecfile: Bad rex header");
			return (ECFile *)NULL;
		}
		p->swap = 1;
	}
	else p->swap = 0;

	if (f_verbose) printf("Swap needed? %s\n", (p->swap ? "YES" : "NO"));

	epos = ftell(p->fptr);
	fseek(p->fptr, 0, SEEK_END);
	fpos = ftell(p->fptr);
	fseek(p->fptr, epos, SEEK_SET);

	this->ncodes = (fpos-epos)/8;
	this->priv = p;
	this->next = ecfile_next;
	this->rewind = ecfile_rewind;
	this->get_header = get_header;
	this->make_event = make_event;
	f_counter = 0;

	if (f_verbose) printf("File size %d, expect (%d-%d)/8 = %d events...\n", epos, fpos, epos, this->ncodes);

	return this;
}

static char *get_header(ECFile *this, char *h)
{
	memcpy(h, this->priv->header, 512);
	return h;
}

static PEvent make_event(ECFile *this, PEvent pevent, unsigned short seqno, short ecode, int time)
{
	pevent->seqno = seqno;
	pevent->ecode = ecode;
	pevent->time = time;
	if (this->priv->swap)
	{
		swapshort(&pevent->seqno);
		swapshort(&pevent->ecode);
		swaplong(&pevent->time);
	}
	return pevent;
}

static void ecfile_rewind(ECFile *this)
{
	struct ecfile_priv *p = this->priv;
	fseek(p->fptr, 512L, SEEK_SET);
	return;
}

static int ecfile_next(ECFile *this, PEvent pev, PECFS pecfs)
{
	int status=0;
	struct ecfile_priv *p = this->priv;

	/* we ignore negative codes unless ECFILE_ALL_CODES flag is set*/
	while (1)
	{
		/* Read an event */
		if (fread(pev, sizeof(Event), 1, p->fptr) == 1)
		{
			f_counter++;

			/* swap if necessary */
			if (p->swap)
			{
				swapshort(&pev->seqno);
				swapshort(&pev->ecode);
				swaplong(&pev->time);
			}

			/*
			 * Check sequence number
			 */

			if (!this->priv->flag&ECFILE_IGNORE_SEQUENCE && pev->seqno!=0 && pev->seqno!=p->lastseqno+1)
			{
           		sprintf(f_str, "ecfile: expect sequence number (%d) got  (%d)", (int)p->lastseqno+1, (int)pev->seqno);
        		errmsg(f_str);
				status = -1;
				break;
			}
			p->lastseqno = pev->seqno;

			/*
			 * break if we are accepting all ecodes, or else if this particular ecode is
			 * positive.
			 * If ECFILE_ALL_CODES is set, then break out of the loop - we are accepting all events.
			 * If ECFILE_NO_BCODES is set, test if this is a bcode-type event. If it is, then continue
			 * to the next event, otherwise break.
			 * If no flags were set, then check for analog codes and skip them.
			 */

			if ((this->priv->flag & ECFILE_SKIP_ACODES) && pev->ecode < 0) continue;
			else if ((this->priv->flag & ECFILE_SKIP_BCODES) && pev->ecode > 0 &&
				( pev->ecode == BCODE_MARK ||
				 (pev->ecode & BCODE_INT) == BCODE_INT ||
				 (pev->ecode & BCODE_UINT) == BCODE_UINT ||
				 (pev->ecode & BCODE_FLOAT) == BCODE_FLOAT )) continue;
			else break;

		}
		else
		{
			status = 1;
			break;
		}
	}

	if (!status && pecfs)
	{
		make_ecfs(pev, pecfs);
	}

	return status;
}

static int make_ecfs(PEvent pev, PECFS pecfs)
{
	int status = 0;

	/* Peel off Afile codes - those with ecode < 0 */
	if (pev->ecode < 0)
	{
		pecfs->time =  pev->time;
		pecfs->code = pev->ecode;
		pecfs->chan = 0;
		pecfs->type = REXTYPE_AFILE;
		pecfs->U = 0;
		pecfs->I = 0;
		pecfs->F = 0;
#ifdef MATLAB_MEX_FILE
		pecfs->V = mxGetNaN();
#else
		pecfs->V = 0;
#endif
		pecfs->counter = f_counter;
		pecfs->id = (pev->ecode & REX_ECODE_MASK);	/* This is the paradigm id */
	}
	else if (pev->ecode == BCODE_MARK)
	{
		/* A BCODE_MARK is placed at the start of 1 or more BCODE_* values. As such it doesn't
		 * have a channel number. I'll arbitrarily stick it in channel 0.
		 */

		f_bcode_time = pev->time;
		pecfs->time = pev->time;
		pecfs->code = pev->ecode;
		pecfs->chan = 0;
		pecfs->type = BCODE_MARK;
		pecfs->U = 0;
		pecfs->I = 0;
		pecfs->F = 0;
#ifdef MATLAB_MEX_FILE
		pecfs->V = mxGetNaN();
#else
		pecfs->V = 0;
#endif
		pecfs->counter = f_counter;
		pecfs->id = 0;
	}
	else if ((pev->ecode & ~BCODE_CHANNEL_MASK)==BCODE_INT)
	{
		pecfs->time =  f_bcode_time;
		pecfs->code = pev->ecode;
		pecfs->chan = pev->ecode & BCODE_CHANNEL_MASK;
		pecfs->type = BCODE_INT;
		pecfs->U = 0;
		pecfs->I = *((int *)(&pev->time));
		pecfs->F = 0;
		pecfs->V = (double)pecfs->I;
		pecfs->counter = f_counter;
		pecfs->id = 0;

		if (f_bcode_time < 0)
		{
			/*
			 * if bcode_time is < 0, it means that the ecode prior to the current one (and perhaps more)
			 * was NOT a BCODE_MARK. That means REX has inserted an ecode into the stream in between our
			 * BCODE_MARK and its subsequent BCODE_INT/UINT/FLOAT(s). This is not ideal, because it introduces
			 * some uncertainty into our assignment of the time to the data value, and it also makes the
			 * resulting data arrays out of sequence time-wise.
			 *
			 * To address this problem, we maintain the value of bcode_time (which is the time value on the
			 * last BCODE_MARK encountered) and ecode_time (which is the time value on the last ordinary
			 * ecode encountered). Rather than REQUIRE that each BCODE_INT/UINT/FLOAT be immediately preceded
			 * by a MARK (or a stream of INT/UINT/FLOAT which was) - and allow no intervening ECODES, we simply
			 * apply the current MARK time (bcode_time) to the INT/UINT/FLOAT. The only case where this would be
			 * an error is at the beginning of the file -- that would mean a true bug in REX code (specifically
			 * the bcode_* functions). Otherwise we assume that our state was interrupted by REX (e.g. it inserts
			 * a spike ecode between our MARK and INT/UINT/FLOAT).
			 *
			 * There remains the question of what to do about the time sequence....
			 *
			 */

			sprintf(f_str, "Error in efile (event %d): BCODE_INT without preceding BCODE_MARK.", f_counter);
			warnmsg(f_str);
			status = -1;
		}
		else
		{
			if (f_bcode_time < (f_ecode_time-1))
			{
				sprintf(f_str, "Warning: Ecode (event %d) intervened at t=%d (bcode time precedes by %d)\n", f_counter, f_ecode_time, f_ecode_time-f_bcode_time);
				warnmsg(f_str);
			}
		}
	}
	else if ((pev->ecode & ~BCODE_CHANNEL_MASK)==BCODE_UINT)
	{
		pecfs->time =  f_bcode_time;
		pecfs->code = pev->ecode;
		pecfs->chan = pev->ecode & BCODE_CHANNEL_MASK;
		pecfs->type = BCODE_UINT;
		pecfs->U = *((unsigned int *)(&pev->time));
		pecfs->I = 0;
		pecfs->F = 0;
		pecfs->V = (double)pecfs->U;
		pecfs->counter = f_counter;
		pecfs->id = 0;

		if (f_bcode_time < 0)
		{
			sprintf(f_str, "Error in efile (event %d): BCODE_UINT without preceding BCODE_MARK.", f_counter);
			errmsg(f_str);
			status = -1;
		}
		else
		{
			if (f_bcode_time < (f_ecode_time-1))
			{
				sprintf(f_str, "Warning: Ecode (event %d) intervened at t=%d (bcode time precedes by %d)\n", f_counter, f_ecode_time, f_ecode_time-f_bcode_time);
				warnmsg(f_str);
			}
		}
	}
	else if ((pev->ecode & ~BCODE_CHANNEL_MASK)==BCODE_FLOAT)
	{
		pecfs->time =  f_bcode_time;
		pecfs->code = pev->ecode;
		pecfs->chan = pev->ecode & BCODE_CHANNEL_MASK;
		pecfs->type = BCODE_FLOAT;
		pecfs->U = 0;
		pecfs->I = 0;
		pecfs->F = *((float *)(&pev->time));
		pecfs->V = (double)pecfs->F;
		pecfs->counter = f_counter;
		pecfs->id = 0;

		if (f_bcode_time < 0)
		{
			sprintf(f_str, "Error in efile (event %d): BCODE_FLOAT without preceding BCODE_MARK.", f_counter);
			errmsg(f_str);
			status = -1;
		}
		else
		{
			if (f_bcode_time < (f_ecode_time-1))
			{
				sprintf(f_str, "Warning: Ecode intervened at t=%d (bcode time precedes by %d)\n", f_ecode_time, f_ecode_time-f_bcode_time);
				warnmsg(f_str);
			}
		}
	}
	else
	{
		/* This is a regular ecode, either placed by REX or with a regular ecode() call.
		 * That means  we should check if the time in this ecode differs from that stored
		 * in bcode_time. If so, set bcode_time to -1 to indicate there is no BCODE marker
		 * placed. Otherwise, leave bcode_time alone, as an ecode can be placed in between
		 * bcodes if they all are placed at the same time.
		 */

		f_ecode_time = pev->time;

		/* Check for init code */
		if (pev->ecode & REX_INIT_MASK)
		{
			pecfs->time =  pev->time;
			pecfs->code = pev->ecode;
			pecfs->chan = 0;
			pecfs->type = REXTYPE_ID;
			pecfs->U = 0;
			pecfs->I = 0;
			pecfs->F = 0;
			pecfs->V = (double)(pev->ecode & REX_ECODE_MASK);	/* mxGetNaN(); */
			pecfs->counter = f_counter;
			pecfs->id = (pev->ecode & REX_ECODE_MASK);	/* This is the paradigm id */
			sprintf(f_str, "Got ID %d", pecfs->id);
			warnmsg(f_str);
		}
		else if (pev->ecode & REX_CANCEL_MASK)
		{
			pecfs->time =  pev->time;
			pecfs->code = pev->ecode;
			pecfs->chan = 0;
			pecfs->type = REXTYPE_CANCEL;
			pecfs->U = 0;
			pecfs->I = 0;
			pecfs->F = 0;
#ifdef MATLAB_MEX_FILE
			pecfs->V = mxGetNaN();
#else
			pecfs->V = 0;
#endif
			pecfs->counter = f_counter;
			pecfs->id = 0;
		}
		else
		{
			/*
			 * Check that the ecode isn't in 0<=code<=255 , which is the range used for channel numbers.
			 * If it is, then arbitrarily or with 0x10000 to move it out of the range of all ecodes.
			 */
			int temp_ecode = pev->ecode & REX_ECODE_MASK;
			if (temp_ecode >=0 && temp_ecode<= 255)
			{
				temp_ecode |= 0x10000;
				sprintf(f_str, "Ecode (event %d, code %d) found in bcode channel range(0-255). Moved to channel %d.", f_counter, pev->ecode & REX_ECODE_MASK, temp_ecode);
				warnmsg(f_str);
			}
			pecfs->time =  pev->time;
			pecfs->code = pev->ecode;
			pecfs->chan = temp_ecode;
			pecfs->type = REXTYPE_ECODE;
			pecfs->U = 0;
			pecfs->I = 0;
			pecfs->F = 0;
			pecfs->V = (double)pev->ecode;
			pecfs->counter = f_counter;
			pecfs->id = 0;
		}
	}
	return status;
}

static void swapshort(short *s)
{
   char *alias = (char *) s, tmp;

   tmp = alias[0];
   alias[0] = alias[1];
   alias[1] = tmp;
}

static void swaplong(int *l)
{
   short *alias = (short *) l, tmp;

   tmp = alias[0];
   alias[0] = alias[1];
   alias[1] = tmp;
   swapshort(alias);
   swapshort(alias+1);
}

static void errmsg(char *msg)
{
#ifdef MATLAB_MEX_FILE
	mexPrintf("%s\n", msg);
#else
	printf("%s\n", msg);
#endif
}

static void warnmsg(char *msg)
{
	if (f_verbose)
	{
#ifdef MATLAB_MEX_FILE
		mexPrintf("%s\n", msg);
#else
		printf("%s\n", msg);
#endif
	}
}
