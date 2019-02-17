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

/*  [s] = ecf('ecode-file'); */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
	int dims[1];
	int *pcount;
    char *input_buf, *output_buf;
    mwSize buflen;
    PECFile pecf = NULL;
    Event event;
    ECFS ecfs;
    int count = 0;
	int bcode_time = -1;
  
    /* Check for proper number of input and  output arguments */    
    if(nlhs > 1){
        mexErrMsgTxt("Too many output arguments.");
    }
    if(nrhs!=1) 
      mexErrMsgTxt("One input required.");

    /* input must be a string */
    if ( mxIsChar(prhs[0]) != 1)
      mexErrMsgTxt("Input must be a string.");

    /* input must be a row vector */
    if (mxGetM(prhs[0])!=1)
      mexErrMsgTxt("Input must be a row vector.");

    /* copy the string data from prhs[0] into a C string input_ buf.    */
    input_buf = mxArrayToString(prhs[0]);

    if(input_buf == NULL) 
      mexErrMsgTxt("Could not convert input to string. The input should be a filename.");


    dims[0] = 1;
    plhs[0] = mxCreateNumericArray(1, dims, mxINT32_CLASS, mxREAL);
    pcount = (int *)mxGetData(plhs[0]);
    pcount[0] = -1;

    /* Open and scan file. This will give us the number of ecodes */
    pecf = ecfile_new(input_buf, 0);
    mxFree(input_buf);
    if (NULL != pecf)
    {
        pcount[0] = 0;
    	while (!pecf->next(pecf, &event, &ecfs))
    	{
			/* Check for init code */
			if (event.ecode & REX_INIT_MASK)
			{
				pcount[0] = (event.ecode & REX_ECODE_MASK);
				break;
    		}
    	}
        ecfile_destroy(pecf);
    }
    else
    {
    	mexErrMsgTxt("ecfile_new returned NULL!");
    }
    return;
}
    
