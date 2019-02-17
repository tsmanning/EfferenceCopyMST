#include "mex.h"
#include "string.h"
#include "stdlib.h"


int double_cmp(const void* keyval, const void *datum);



/*
 * [i1] = ecindexmatch(input_values_array, values_to_get_indeices_for);
 * 
 * The size of i will be the same as that of values_to_get_indices_for
 * 
 */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
	int i;
	double *psorted;
	double *pseeking;
	
	if (nrhs != 2) 
	{
		mexErrMsgTxt("2 args required!");		
	}

    /* First input must be a real, column vector */
    if ( mxIsDouble(prhs[0]) != 1 || mxGetN(prhs[0]) != 1)
    {
    	mexErrMsgTxt("First input must be a double column vector.");
    }

    /* Second input must be a real clumn vector too. */
    if ( mxIsDouble(prhs[1]) != 1 || mxGetN(prhs[1]) != 1)
    {
    	mexErrMsgTxt("Second input must be a double column vector.");
    }

    /* Check for proper number of output arguments */    
    if (nlhs != 1) 
    {
    	mexErrMsgTxt("Need 2 outputs.");
    }

    /* Get pointer to data from first input. Check that it is sorted (ascending) already. */
    psorted = mxGetPr(prhs[0]);
    for (i=1; i<mxGetM(prhs[0]); i++)
    {
    	if (psorted[i] < psorted[i-1])
    	{
    		mexErrMsgTxt("Input values must be sorted ascending!");
    	}
    }

    /* Get pointer to data for second input. */
    pseeking = mxGetPr(prhs[1]);
    
    /* Create output vector and fill it. */
    mwSize dims[2];
    double *pfound=NULL;
    int *presult = NULL;
    dims[0] = mxGetM(prhs[1]);
    dims[1] = 1;
    plhs[0] = mxCreateNumericArray(2, dims, mxINT32_CLASS, mxREAL);
    presult = (int *)mxGetPr(plhs[0]);

    for (i=0; i<mxGetM(prhs[1]); i++)
    {
    	if (pfound = bsearch(pseeking+i, psorted, mxGetM(prhs[0]), sizeof(double), double_cmp))
    	{
    		presult[i] = (int)(pfound-psorted)+1;	/* The +1 is to convert to 1-based MATLAB indices. The subtraction is pointer magic. */
    	}
    	else
    	{
    		presult[i] = -1;
    	}
    }
	return;
}

int double_cmp(const void* keyval, const void *datum)
{
	double *pkey = (double *) keyval;
	double *pdat = (double *) datum;
	return (*pkey) - (*pdat);
}
