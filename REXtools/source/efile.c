#include "mex.h"
#include "string.h"

#include "ecfile.h"
#include "except.h"
#include "bcode_defs.h"

const char *fields[] =
{
		"time",
		"ecode",
		"channel",
		"type",
		"U",
		"I",
		"F",
		"V",
		"ID"
};

/* comparison function for sorting ECFS structs */
int cmpecfs(const void *p1, const void *p2);



/*  [count, id, Z] = ecm('ecode-file'); */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
    ECFile *ecfP = NULL;		/* ecode file object - see ecfile.h */
    Event event;
    ECFS ecfs;

	int needCount = 1;	/* Always put out count */
	int needID = 0;		/* If second output arg is given */
	int needZ = 0;		/* If third output arg is given */

	mxArray *pmxTimes = NULL;
	mxArray *pmxCodes = NULL;
	mxArray *pmxChan = NULL;
	mxArray *pmxType = NULL;
	mxArray *pmxU = NULL;
	mxArray *pmxI = NULL;
	mxArray *pmxF = NULL;
	mxArray *pmxV = NULL;

	ECFS *pecfs = NULL;
	int *ptimes = NULL;			/* convenience pointer to time array */
	short int *pcodes = NULL;	/* convenience pointer to codes array */
	int *pchan = NULL;			/* convenience pointer to channels array */
	short int *ptype = NULL;	/* convenience pointer to type array */
	unsigned int *pU = NULL;	/* convenience pointer to uint array */
	int *pI = NULL;				/* convenience pointer to int array */
	float *pF = NULL;			/* convenience pointer to float array */
	double *pV = NULL;			/* convenience pointer to double array */
	int *pcount = NULL;			/* convenience pointer to count output */
	int *pID = NULL;			/* convenience pointer to ID output */
	char *filename=NULL;		/* Input filename */
	int dims[1];				/* dimensions array for creating matlab arrays and matrices */
	int counter=0;				/* running counter of ecodes read */
	int bcode_time = -1;
	int ecode_time = -1;
	int i;

    /* check input arg */
    if(nrhs!=1)
    {
    	mexErrMsgTxt("One input required.");
    }
    else if ( mxIsChar(prhs[0]) != 1)
    {
        mexErrMsgTxt("Input must be a string.");
    }
    else if (mxGetM(prhs[0]) != 1)
    {
    	mexErrMsgTxt("Input string must be a row vector.");
    }

    /* Create the ecfile object. */
    filename = mxArrayToString(prhs[0]);
    if (!filename)
    {
    	mexErrMsgTxt("Cannot convert input filename to a string!");
    }
    ecfP = ecfile_new(filename, 0);
    mxFree(filename);
    if (NULL == ecfP)
    {
    	mexErrMsgTxt("Cannot open input file.");
    }

    /* Check output arg and create output arrays */
    if (nlhs != 1)
    {
    	mexErrMsgTxt("One output arg required.");
    }
    else
    {
    	mxArray *p = NULL;
    	dims[0] = 1;
    	plhs[0] = mxCreateStructArray(1, dims, sizeof(fields)/sizeof(char *), fields);

    	/* create time array. ptimes used later... */
    	dims[0] = ecfP->ncodes;
    	p = mxCreateNumericArray(1, dims, mxINT32_CLASS, mxREAL);
    	mxSetField(plhs[0], 0, fields[0], p);
    	ptimes = (int *)mxGetData(p);

    	/* create ecodes array */
    	dims[0] = ecfP->ncodes;
    	p = mxCreateNumericArray(1, dims, mxINT16_CLASS, mxREAL);
    	mxSetField(plhs[0], 0, fields[1], p);
    	pcodes = (short int *)mxGetData(p);

    	/* create channels array */
    	dims[0] = ecfP->ncodes;
    	p = mxCreateNumericArray(1, dims, mxINT32_CLASS, mxREAL);
    	mxSetField(plhs[0], 0, fields[2], p);
    	pchan = (int *)mxGetData(p);

    	/* create types array */
    	dims[0] = ecfP->ncodes;
    	p = mxCreateNumericArray(1, dims, mxINT16_CLASS, mxREAL);
    	mxSetField(plhs[0], 0, fields[3], p);
    	ptype = (short int *)mxGetData(p);

    	/* create UINT32 array. */
    	dims[0] = ecfP->ncodes;
    	p = mxCreateNumericArray(1, dims, mxUINT32_CLASS, mxREAL);
    	mxSetField(plhs[0], 0, fields[4], p);
    	pU = (unsigned int *)mxGetData(p);

    	/* create INT32 array. */
    	dims[0] = ecfP->ncodes;
    	p = mxCreateNumericArray(1, dims, mxINT32_CLASS, mxREAL);
    	mxSetField(plhs[0], 0, fields[5], p);
    	pI = (int *)mxGetData(p);

    	/* create SINGLE array. */
    	dims[0] = ecfP->ncodes;
    	p = mxCreateNumericArray(1, dims, mxSINGLE_CLASS, mxREAL);
    	mxSetField(plhs[0], 0, fields[6], p);
    	pF = (float *)mxGetData(p);

    	/* create DOUBLE array. */
    	dims[0] = ecfP->ncodes;
    	p = mxCreateNumericArray(1, dims, mxDOUBLE_CLASS, mxREAL);
    	mxSetField(plhs[0], 0, fields[7], p);
    	pV = (double *)mxGetData(p);

    	/* create space for id. */
    	dims[0] = 1;
    	p = mxCreateNumericArray(1, dims, mxINT32_CLASS, mxREAL);
    	mxSetField(plhs[0], 0, fields[8], p);
    	pID = (int *)mxGetData(p);
    	*pID = 0;

    	/* create array for unsorted codes */
    	pecfs = (ECFS *)mxCalloc(ecfP->ncodes, sizeof(ECFS));
    }

    counter = 0;
   	while (!ecfP->next(ecfP, &event, &ecfs))
   	{
   		pecfs[counter] = ecfs;

   		/*
   		 * There are extraneous paradigm ID codes in some data files. This code attempts to address the problem by
   		 * only assigning the FIRST ID value found (that one always seems to be correct).
   		 */
   		if (ecfs.type == REXTYPE_ID && (*pID)==0)
   		{
   			*pID = (event.ecode & REX_ECODE_MASK);	/* This is the paradigm id */
   		}
   		counter++;
   	}
    ecfile_destroy(ecfP);

    /*
     * Now sort by time and assign the return values
     */

    qsort(pecfs, counter, sizeof(ECFS), cmpecfs);
    for (i=0; i<counter; i++)
    {
    	ptimes[i] = pecfs[i].time;
    	pcodes[i] = pecfs[i].code;
    	pchan[i] = pecfs[i].chan;
    	ptype[i] = pecfs[i].type;
    	pI[i] = pecfs[i].I;
    	pU[i] = pecfs[i].U;
    	pF[i] = pecfs[i].F;
    	pV[i] = pecfs[i].V;
    }
    mxFree(pecfs);

    return;
}

int cmpecfs(const void *p1, const void *p2)
{
	ECFS *pecfs1 = (ECFS *)p1;
	ECFS *pecfs2 = (ECFS *)p2;
	if (pecfs1->time == pecfs2->time)
	{
		/*
		 * preserve order from efile
		 */
		return pecfs1->counter-pecfs2->counter;
	}
	return pecfs1->time - pecfs2->time;
}
