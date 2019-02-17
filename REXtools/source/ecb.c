#include "mex.h"
#include "string.h"

#include "ecfile.h"
#include "except.h"
#define MAXCHARS 80   /* max length of string contained in each field */

/* 
 * BCODE bit flags
 */

#define REX_CANCEL_MASK	0x4000
#define REX_INIT_MASK	0x2000
#define REX_ECODE_MASK	0x1fff
#define	BCODE_FLAG		0x1000
#define BCODE_FLOAT		(BCODE_FLAG | 0x800)
#define BCODE_INT		(BCODE_FLAG | 0x400)
#define BCODE_UINT		(BCODE_FLAG | 0x200)
#define BCODE_MARK		(BCODE_FLAG | 0x100)
#define BCODE_CHANNEL_MASK	0x00ff


/* Total hack job - hard code these. */

char *letters="ITUMEKWJLRBCYZX12345abcdefghijklmnop";
int codes[] = {
	     1501,
	        1502,
	        1503,
	        1505,
	        1506,
	        1508,
	        1509,
	        1510,
	        1512,
	        1513,
	        1514,
	        1515,
	        1516,
	        1517,
	        8192,
	           1,
	           2,
	           3,
	           4,
	           5,
	         100,
	         101,
	         102,
	         103,
	         104,
	         105,
	         106,
	         107,
	         108,
	         109,
	         110,
	         111,
	         112,
	         113,
	         114,
	         115
};


/*  [s] = ecb('ecode-file'); 
 * 
 * Result [s] is a nx5 real matrix, where n is the number of ecodes in the original file. The columns are as follows:
 * The 5 columns represent the 
 * 1. raw ecodes
 * 2. time
 * 3. channel #
 * 4. value
 * 5. channel index 
 * 
 * */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
    char *input_buf, *output_buf;
    mwSize buflen;
    ECFile *ecfP = NULL;
    struct ecode_info eci;
    int count = 0;
	int bcode_time = -1;
	char *str1;
	int *pichannels=NULL;
	char *pletters;
	int n3=0;				/* hack = COUNT THE CHANNEL 3'S */
	const char **Cstr1 = (const char **)&str1;


	if (nrhs != 3) 
	{
		mexErrMsgTxt("3 args required!");		
	}

    /* First input must be a string, row vector */
    if ( mxIsChar(prhs[0]) != 1 || mxGetM(prhs[0]) != 1)
    {
    	mexErrMsgTxt("First input must be a char string (row vector).");
    }

    /* Second input must be an INT32 array. */
    if ( mxIsInt32(prhs[1]) != 1 || mxGetM(prhs[1]) != 1)
    {
    	mexErrMsgTxt("Second input must be an INT32 array (row vector).");
    }
    else
    {
    	int ii;
    	pichannels = (int *)mxGetData(prhs[1]);
    }
    
    /* Third input must be a string, row vector */
    if ( mxIsChar(prhs[2]) != 1 || mxGetM(prhs[2]) != 1)
    {
    	mexErrMsgTxt("Third input must be a char string (row vector).");
    }
    else
    {
    	pletters = mxArrayToString(prhs[2]);
    }

    /* Check for proper number of output arguments */    
    if (nlhs != 2) 
    {
    	mexErrMsgTxt("Need 2 outputs.");
    }
    
    /* TODO: this is a mess! */
#if 0
    if(nlhs > 1){
        mexErrMsgTxt("Too many output arguments.");
    }
    if(nrhs!=1) 
      mexErrMsgTxt("One input required.");
    else if(nlhs > 3) 
      mexErrMsgTxt("Too many output arguments.");

    /* input must be a string */
    if ( mxIsChar(prhs[0]) != 1)
      mexErrMsgTxt("Input must be a string.");


    
    /* End input/output args checking */
#endif

    /* input must be a row vector */
    if (mxGetM(prhs[0])!=1)
      mexErrMsgTxt("Input must be a row vector.");

    /* copy the string data from prhs[0] into a C string input_ buf.    */
    input_buf = mxArrayToString(prhs[0]);

    if(input_buf == NULL) 
      mexErrMsgTxt("Could not convert input to string. The input should be a filename.");
    
    
    

    /* Open and scan file. This will give us the number of ecodes */
    ecfP = ecfile_new(input_buf);
    mxFree(input_buf);
    if (NULL != ecfP)
    {
    	double *praw;
        int raw_ind;
        int time_ind;
        int chan_ind;
        int val_ind;
    	int i;
    	
        /* Create a n x 4 matrix. 
         * The 'n' is the length of the file, or the number of ecodes. 
         * The 4 columns represent the 
         * 1. raw ecodes
         * 2. time
         * 3. channel #
         * 4. value
         * 
         */ 

    	plhs[0] = mxCreateDoubleMatrix(ecfP->ncodes, 4, mxREAL);
    	praw = mxGetPr(plhs[0]);
    	
    	/* Create string of same length */
    	str1 = (char *)mxMalloc(ecfP->ncodes + 1);
    	str1[ecfP->ncodes] = 0;	/*  null terminate this string just in case. */ 

    	count = 0;

        while (!ecfP->next(ecfP, &eci))
    	{
            raw_ind = count;
            time_ind = count + ecfP->ncodes;
            chan_ind = count + 2*ecfP->ncodes;
            val_ind = count + 3*ecfP->ncodes;

            praw[raw_ind] = eci.ecode;
    		
    		/* Test ecode to see just what it is. */
    		if (eci.ecode == BCODE_MARK)
    		{
    			bcode_time = eci.time;

    			/* A BCODE_MARK is placed at the start of 1 or more BCODE_* values. As such it doesn't 
    			 * have a channel number. I'll arbitrarily stick it in channel 0. 
    			 */

    			praw[time_ind] = bcode_time;
    			praw[chan_ind] = 0;
    			praw[val_ind] = 0;
    		}
    		else if ((eci.ecode & BCODE_INT)==BCODE_INT)
    		{
    			if (bcode_time < 0) 
    			{
    				mexPrintf("ecode count %d\n", count);
    				mexErrMsgTxt("Error in efile: BCODE_INT without preceding BCODE_MARK.");
    			}
    			else
    			{
    				praw[time_ind] = bcode_time;
    				praw[chan_ind] = (eci.ecode & BCODE_CHANNEL_MASK);
    				praw[val_ind] = (double)*((int *)(&eci.time));
    			}
    		}
    		else if ((eci.ecode & BCODE_UINT)==BCODE_UINT)
    		{
    			if (bcode_time < 0) 
    			{
    				mexPrintf("ecode count %d\n", count);
    				mexErrMsgTxt("Error in efile: BCODE_UINT without preceding BCODE_MARK.");
    			}
    			else
    			{
    				praw[time_ind] = bcode_time;
    				praw[chan_ind] = (eci.ecode & BCODE_CHANNEL_MASK);
    				praw[val_ind] = (double)*((unsigned int *)(&eci.time));
    			}
    		}
    		else if ((eci.ecode & BCODE_FLOAT)==BCODE_FLOAT)
    		{
    			if (bcode_time < 0) 
    			{
    				mexPrintf("ecode count %d\n", count);
    				mexErrMsgTxt("Error in efile: BCODE_FLOAT without preceding BCODE_MARK.");
    			}
    			else
    			{
    				praw[time_ind] = bcode_time;
    				praw[chan_ind] = (eci.ecode & BCODE_CHANNEL_MASK);
    				praw[val_ind] = (double)*((float *)(&eci.time));
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

    			if (eci.time != bcode_time)
    			{
    				bcode_time = -1;
    			}

    			/* Check for init code */
    			if (eci.ecode & REX_INIT_MASK)
    			{
    				praw[time_ind] = eci.time;
    				praw[chan_ind] = REX_INIT_MASK;
    				praw[val_ind] = (eci.ecode & REX_ECODE_MASK);	/* This is the paradigm id */
    			}
    			else if (eci.ecode & REX_CANCEL_MASK)
    			{
    				praw[time_ind] = eci.time;
    				praw[chan_ind] = eci.ecode;
    				praw[val_ind] = 0;
    			}
    			else
    			{
        			/* 
        			 * Check that the ecode isn't in 0<=code<=255 , which is the range used for channel numbers.
        			 * If it is, then arbitrarily or with 0x10000 to move it out of the range of all ecodes.  
        			 */
        			int temp_ecode = eci.ecode & REX_ECODE_MASK;
        			if (temp_ecode >=0 && temp_ecode<= 255) 
        			{
        				temp_ecode |= 0x10000;
        				mexWarnMsgTxt("Ecode found in bcode channel range(0-255). This range moved to 65536-65791.");
        			}

        			praw[time_ind] = eci.time;
        			praw[chan_ind] = temp_ecode;
        			praw[val_ind] = 0;
    			}
    		}

    		/* Map to chars - do this stupid first */
            {
            	int i, j;
            	for (i=0; i<mxGetN(prhs[1]); i++) 
            	{
            		if ((int)praw[chan_ind] == pichannels[i]) break;
            	}
            	if (i<mxGetN(prhs[1]))
            	{
            		str1[count] = pletters[i];
            	}
            	else
            	{
            		str1[count] = ' ';
            	}      	
            }
    		
			count = count + 1;
    	}
        ecfP->done(ecfP);

        /* Convert str1 to an array */
        plhs[1] = mxCreateCharMatrixFromStrings(1, Cstr1);

        
    }
    else
    {
    	mexErrMsgTxt("ecfile_new returned NULL!");
    }

    return;
}
    
