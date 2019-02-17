/*
 * edump.c
 *
 *  Created on: Jul 29, 2009
 *      Author: dan
 */

/*
 * ecull.c
 *
 * Originally the intent was to cull out BCODE-type codes from E-files,
 * hence this program was named "ecull". Well, I couldn't make that work
 * right (though the files were culled, they ended up producing empty
 * trials when run through mrdr in Matlab). So, I took another tack (found
 * a key bug in how ecodes were handled in this program as well) and instead
 * of removing those ecodes I "fixed" their times. Turns out that mrdr does
 * a big sort on all ecodes after reading the file, sorting on time. Since
 * we use the time as a 4-byte storage point,  not actual time, this sort was
 * leading to LONG LONG LONG processing times for those e-files and their
 * corresponding a-files in mrdr.
 *
 *  Created on: Nov 25, 2008
 *      Author: dan
 */

#ifdef _MSC_VER
#define _CRT_SECURE_NO_WARNINGS
#endif
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "ecfile.h"
#include "except.h"
#include "bcode_defs.h"
#include <sys/types.h>
#ifdef __gnu_linux__
#include <unistd.h>
#else
#include <windows.h>
#include "getopt.h"
#endif


int f_start_event_index = -1;
int f_end_event_index = -1;
int f_wordy = 0;
int f_filter = 0;
char f_filter_str[128];

static char *make_ecode_string(PEvent pevent, PECFS pecfs, char *str, int *ptypechar);

void usage()
{
	printf("usage: edump -i inputfileE [-s start_index -e end_index] [-w]\n       -w : wordy");
}

int main(int argc, char **argv)
{
	char filename[256] = {0};
	int negflag = 1;
	Event event;
	ECFS ecfs;
	int counter = 0;
	int ch;
	ECFile *ecfP = NULL;
	char tmpstr[256];

    /*
     * Process input args
     */

    while ((ch = getopt(argc, argv, "i:Ns:e:wF:")) != -1)
    {
    	switch (ch) {
		case 'i':
			if (strlen(optarg)>sizeof(filename))
			{
				printf("Input filename too long (must be <%d).\n", sizeof(filename));
				exit(1);
			}
			else
			{
				strcpy(filename, optarg);
			}
			break;
		case 'N':
			negflag = 0;
			break;
		case 's':
			f_start_event_index = atoi(optarg);
			break;
		case 'e':
			f_end_event_index = atoi(optarg);
			break;
		case 'w':
			f_wordy = 1;
			break;
		case 'F':
			f_filter = 1;
			strcpy(f_filter_str, optarg);
			break;
		case '?':
		default:
			usage();
		}
    }


    if (!strlen(filename))
    {
		printf("No input efile specified.\n");
		usage();
		exit(1);
	}

    /*
     * Open and read efile.
     */

    if (f_wordy) ecfile_verbose(1);
    ecfP = ecfile_new(filename, negflag);
	if (!ecfP)
	{
		printf("Cannot open efile %s\n", filename);
		exit(1);
	}

	counter=0;
   	while (!ecfP->next(ecfP, &event, &ecfs))
   	{
   		int itype;
   		if (counter >= f_start_event_index && (counter <= f_end_event_index || f_end_event_index < 0))
   		{
   			make_ecode_string(&event, &ecfs, tmpstr, &itype);
   			if (!f_filter || (f_filter && strchr(f_filter_str, itype)))
   			{
   				printf("%8d %s\n", counter, tmpstr);
   			}
   		}
   		counter++;
	}

    ecfile_destroy(ecfP);

    if (f_wordy) printf("Counted %d ecodes.\n", counter);
    return 0;
}

static char *make_ecode_string(PEvent pevent, PECFS pecfs, char *str, int *ptypechar)
{
	strcpy(str, "ZZZZZZZZZZZZZZ");

	switch (pecfs->type)
	{
	case BCODE_MARK:
		sprintf(str, "%8d M ===mark== %8d", (int)pevent->seqno, pecfs->time);
		*ptypechar = 'M';
		break;
	case BCODE_INT:
		sprintf(str, "%8d I   INT/%3d          %8d", (int)pevent->seqno, pecfs->chan, pecfs->I);
		*ptypechar = 'I';
		break;
	case BCODE_UINT:
		sprintf(str, "%8d U  UINT/%3d          %8u", (int)pevent->seqno, pecfs->chan, pecfs->U);
		*ptypechar = 'U';
		break;
	case BCODE_FLOAT:
		sprintf(str, "%8d F FLOAT/%3d          %8f", (int)pevent->seqno, pecfs->chan, pecfs->F);
		*ptypechar = 'F';
		break;
	case REXTYPE_AFILE:
		sprintf(str, "%8d A     AFILE %8d %8d", (int)pevent->seqno, pevent->time, pecfs->code);
		*ptypechar = 'A';
		break;
	case REXTYPE_ID:
		sprintf(str, "%8d i %9d %8d %x", (int)pevent->seqno, pecfs->id, (int)pevent->time, pecfs->code);
		*ptypechar = 'i';
		break;
	case REXTYPE_CANCEL:
		sprintf(str, "%8d C    CANCEL %8d", (int)pevent->seqno, pevent->time);
		*ptypechar = 'C';
		break;
	case REXTYPE_ECODE:
		sprintf(str, "%8d E %9d %8d", (int)pevent->seqno, (int)(pecfs->code), (int)pevent->time);
		*ptypechar = 'E';
		break;
	default:
		sprintf(str, "%8d ? %9d %8d %x", (int)pevent->seqno, (int)(pecfs->code), (int)pevent->time, pecfs->type);
		*ptypechar = '?';
		break;
	}
	return str;
}
