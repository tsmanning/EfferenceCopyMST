#include "mex.h"
#include "string.h"

#include "ecfile.h"
#include "except.h"
#define MAXCHARS 80   /* max length of string contained in each field */

/*  [times, codes, count] = ecm('ecode-file'); */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
    char *input_buf, *output_buf;
    mwSize buflen;
    ECFile *ecfP = NULL;
    struct ecode_info eci;
    int count = 0;
	int dims[1];
	int *ptimes=NULL;
	int *pcodes=NULL;
	int *pcount=NULL;
    
    /* check for proper number of arguments */
    if(nrhs!=1) 
      mexErrMsgTxt("One input required.");
    else if(nlhs > 3) 
      mexErrMsgTxt("Too many output arguments.");

    /* input must be a string */
    if ( mxIsChar(prhs[0]) != 1)
      mexErrMsgTxt("Input must be a string.");

    /* input must be a row vector */
    if (mxGetM(prhs[0])!=1)
      mexErrMsgTxt("Input must be a row vector.");

    /* copy the string data from prhs[0] into a C string input_ buf.    */
    input_buf = mxArrayToString(prhs[0]);

    if(input_buf == NULL) 
      mexErrMsgTxt("Could not convert input to string.");

    ecfP = ecfile_new(input_buf);
    mxFree(input_buf);
    if (NULL != ecfP)
    {
    	/* Create output arrays if necessary */
    	if (nlhs>=2)
    	{
    		dims[0] = ecfP->ncodes;
    		plhs[1] = mxCreateNumericArray(1, dims, mxINT32_CLASS, mxREAL);
    		ptimes = (int *)mxGetData(plhs[1]);
    	}
    	if (nlhs == 3)
    	{
    		dims[0] = ecfP->ncodes;
    		plhs[2] = mxCreateNumericArray(1, dims, mxINT32_CLASS, mxREAL);
    		pcodes = (int *)mxGetData(plhs[2]);
    	}

    	while (!ecfP->next(ecfP, &eci))
    	{
    		if (ptimes) ptimes[count] = eci.time;
    		if (pcodes) pcodes[count] = (int)eci.ecode;
    		count++;
    	}
    }
    
    ecfP->done(ecfP);

    /* Set count */
	if (nlhs >= 1)
	{
	    dims[0] = 1;
	    plhs[0] = mxCreateNumericArray(1, dims, mxINT32_CLASS, mxREAL);
	    pcount = (int *)mxGetData(plhs[0]);
	    pcount[0] = count;
	}

    return;
}
    
