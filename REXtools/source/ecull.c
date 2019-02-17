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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "ecfile.h"
#include "except.h"
#include "bcode_defs.h"
#include <sys/types.h>
#include <unistd.h>

FILE *outfile_new(char *infile, int clobber);

char f_header[512];
int f_verbose = 0;

void usage()
{
	printf("usage: ecull -i Efile\n");
}

int main(int argc, char **argv)
{
	int32_t code;
	int32_t umin, umax;
	int32_t i, j;
    ECFile *ecfP = NULL;		/* ecode file object - see ecfile.h */
    Event event;				/* ecode struct as read from file - see ecfile.h */
    ECFS ecfs;
    int ioutput=0;
    FILE *foutput = NULL;
    int flag = 0;	/* if set by -N and -B */
    int last_mark;
    int written=0;
    int ch;				/* for getopt */
    char filename[256] = {0};

    /*
     * Process input args
     */

    while ((ch = getopt(argc, argv, "i:ABSov")) != -1)
    {
    	switch (ch) {
    	case 'A':
    		flag |= ECFILE_SKIP_ACODES;
    		break;
    	case 'B':
    		flag |= ECFILE_SKIP_BCODES;
    		break;
    	case 'S':
    		flag |= ECFILE_IGNORE_SEQUENCE;
    		break;
    	case 'o':
    		ioutput = 1;
    		break;
		case 'i':
			if (strlen(optarg)>sizeof(filename))
			{
				printf("Input filename too long (must be <%lu).\n", sizeof(filename));
				exit(1);
			}
			else
			{
				strcpy(filename, optarg);
			}
			break;
		case 'v':
			ecfile_verbose(1);
			f_verbose = 1;
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

    ecfP = ecfile_new(filename, flag);
	if (!ecfP)
	{
		printf("Cannot open efile %s\n", filename);
		exit(1);
	}
    else
    {
    	if (ioutput)
    	{
			foutput = outfile_new(filename, 0);
			if (!foutput)
			{
				printf("Cannot open output file\n");
				ecfile_destroy(ecfP);
				return -1;
			}
			else
			{
				/* output file is already opened... */
				fwrite(ecfP->get_header(ecfP, f_header), 512, 1, foutput);
			}
    	}
    }




	int Acodes = 0;	// analog marker
	int Ecodes = 0;	// just an ecode
	int Icodes = 0;	// bcode_int
	int Bcodes = 0;	// bcode MARK
	int Ucodes = 0;	// bcode_uint
	int Fcodes = 0;	// bcode_float
	int Ccodes = 0;	// cancel
	int INITcodes = 0;	// init
	int UNKNOWNcodes=0;
	int TOTALcodes=0;
	int iwrite=0;
	int nwritten = 0;
   	while (!ecfP->next(ecfP, &event, &ecfs))
   	{
   		TOTALcodes++;
   		iwrite = 0;

   		// tallies
   		if (event.ecode & REX_AFILE_MASK)
   		{
   			Acodes++;
   			iwrite = 1;
   		}
   		else if (event.ecode & REX_CANCEL_MASK)
   		{
   			Ccodes++;
   			iwrite = 1;
   		}
   		else if (event.ecode & REX_INIT_MASK)
   		{
   			INITcodes++;
   			iwrite = 1;
   		}
   		else if (event.ecode == BCODE_MARK)
   		{
   			Bcodes++;
   		}
   		else if ((event.ecode & BCODE_INT)==BCODE_INT)
   		{
   			Icodes++;
   		}
   		else if ((event.ecode & BCODE_UINT)==BCODE_UINT)
   		{
   			Ucodes++;
   		}
   		else if ((event.ecode & BCODE_FLOAT)==BCODE_FLOAT)
   		{
   			Fcodes++;
   		}
   		else if ((event.ecode & REX_ECODE_MASK)==event.ecode)
   		{
   			Ecodes++;
   			iwrite = 1;
   		}
   		else
   		{
   			UNKNOWNcodes++;
   		}

   		if (ioutput && iwrite)
   		{
   			fwrite(&event, sizeof(Event), 1, foutput);
   			nwritten++;
   		}
   	}
   	ecfile_destroy(ecfP);

	printf("Total codes: %d\n\tUNKNOWN: %d\n\tINIT: %d\n\tCANCEL: %d\n\tEcodes: %d\n\tAcodes: %d\n\tBcodes: %d\n\t\tIcodes: %d\n\t\tUcodes: %d\n\t\tFcodes: %d\n",
			TOTALcodes, UNKNOWNcodes, INITcodes, Ccodes, Ecodes, Acodes, Bcodes, Icodes, Ucodes, Fcodes);

	printf("Check total: %s\n", (TOTALcodes == (Acodes+Ccodes+INITcodes+Bcodes+Icodes+Ucodes+Fcodes+Ecodes+UNKNOWNcodes) ? "OK" : "NOT OK!"));

   	if (ioutput)
   	{
   		fclose(foutput);
   		printf("Wrote %d codes.\n", nwritten);
   	}
   	return 0;
}

#if 0
		code = event.ecode;





		if (event.ecode & ~REX_ECODE_MASK)
		{
			/*
			printf("rex ecode %d\n", code);
			*/
		}
		else
   		{
			/*
			 * All ecodes are passed. If any BCODE-type ecode comes past catch it and
			 * fix up its time. Note that this destroys any data stored here!
			 * Don't ever overwrite an actual data file with this!!!
			 */
			if (event.ecode == BCODE_MARK)
			{
				last_mark = event.time;
			}
			else if (((event.ecode & BCODE_INT)==BCODE_INT) ||
					((event.ecode & BCODE_UINT)==BCODE_UINT) ||
					((event.ecode & BCODE_FLOAT)==BCODE_FLOAT))
			{
				if (last_mark == 0) printf("WARNING last_mark=0\n");
				event.time = last_mark;

				/* Look at channel number */
				if (tcode && tchan && (int)(event.ecode & 0xff) == tchan) event.ecode = tcode;
			}
   		}

		fwrite(&event, sizeof(Event), 1, foutput);
		written++;
	}

	fclose(foutput);
    ecfile_destroy(ecfP);
    printf("Wrote %d ecodes.\n", written);
    return 0;
}
#endif

FILE *outfile_new(char *infile, int clobber)
{
	FILE *fp = NULL;
	char *p = strrchr(infile, '/');
	char filename[256];
	if (!p) p=infile;
	else p++;

	// If input filename is a "standard" efile with an "E" at the end, then replace the "E" with a "C".
	// Otherwise append ".ecull".
	if (infile[strlen(infile)-1] == 'E')
	{
		strcpy(filename, p);
		filename[strlen(filename)-1] = 'C';
	}
	else
	{
		strcat(strcpy(filename, p), ".ecull");
	}
	printf("Output filename %s\n", filename);

	/*
	 * If clobber is nonzero, then just open the output file and overwrite it.
	 * If clobber is zero, then we must be a little more careful.
	 */
	if (clobber)
	{
		fp = fopen(filename, "wb");
	}
	else
	{
		if (fp = fopen(filename, "rb"))
		{
			fclose(fp);
			printf("Output file %s exists. Please remove first.\n", filename);
			fp = NULL;
		}
		else
		{
			fp = fopen(filename, "wb");
		}
	}
	return fp;
}
