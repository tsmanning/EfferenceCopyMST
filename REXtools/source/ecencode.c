#include "mex.h"
#include "string.h"
#include "stdlib.h"


/* code/letter pair struct for sorting */

typedef struct ichar_struct 
{
	int i;
	char c;
} ICHAR;


/* Comparison function for qsort and bsearch. */

int ichar_cmp(const void* key, const void *dat)
{
	return ((ICHAR *)key)->i - ((ICHAR *)dat)->i;
};



/*
 * [str indices] = ecencode(input_array, filter_these_values, use_these_letters);
 */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
	ICHAR *pichar = NULL;
	ICHAR **ppresult = NULL;
	ICHAR *ptemp;
	int nresult, nfill;
	int i;
	int *piInputValues = NULL;
	int *piInputCodes = NULL;
	char *pcInputLetters = NULL;
	int nInputValues = 0;
	int nInputCodes = 0;
	int nInputLetters = 0;
    mwSize dims[2];
    mxChar *pc;
    int *pi;
	
	/* 
	 * Check input/output args.
	 * First and second inputs must be INT32 arrays, though we don't care if they're row or column vectors. 
     * Third input must be a string, row vector.
     * There must be an equal number of codes and letters in the second and third inputs, respectively. 
     * We require two output args. 
	 */

    if (nrhs != 3) 
	{
		mexErrMsgTxt("3 args required!");		
	}

    if ( mxIsInt32(prhs[0]) != 1 || (mxGetM(prhs[0]) != 1 && mxGetN(prhs[0]) != 1))
    {
    	mexErrMsgTxt("First arg must be an INT32 array!");
    }
    else
    {
    	piInputValues = (int *)mxGetData(prhs[0]);
    	if (mxGetM(prhs[0])==1) nInputValues = mxGetN(prhs[0]);
    	else nInputValues = mxGetM(prhs[0]);
    }

    if ( mxIsInt32(prhs[1]) != 1 || (mxGetM(prhs[1]) != 1 && mxGetN(prhs[1]) != 1))
    {
    	mexErrMsgTxt("Second arg must be an INT32 array!");
    }
    else
    {
    	piInputCodes = (int *)mxGetData(prhs[1]);
    	if (mxGetM(prhs[1])==1) nInputCodes = mxGetN(prhs[1]);
    	else nInputCodes = mxGetM(prhs[1]);
    }

    if ( mxIsChar(prhs[2]) != 1 || mxGetM(prhs[2]) != 1)
    {
    	mexErrMsgTxt("Third input must be a char string (row vector).");
    }
    else
    {
    	pcInputLetters = mxArrayToString(prhs[2]);
    	nInputLetters = mxGetN(prhs[2]);
    }

    if (nInputLetters != nInputCodes)
    {
    	mexErrMsgTxt("Number of input codes must be the same as the number of input letters!");
    }
    
    if (nlhs != 2) 
    {
    	mexErrMsgTxt("Two outputs required.");
    }
    
    
    
    /* 
     * Build array of ICHAR pairs (using input codes and letters) for sorting, and sort them. 
     * We sort on the code value, not the letter. 
     */ 

    pichar = (ICHAR *)mxCalloc(nInputCodes, sizeof(ICHAR));
    for (i=0; i<nInputCodes; i++)
    {
    	pichar[i].c = pcInputLetters[i];
    	pichar[i].i = piInputCodes[i];
    	/*mexPrintf("%d %c\n", piInputCodes[i], pcInputLetters[i]);*/
    }
    qsort(pichar, nInputCodes, sizeof(ICHAR), ichar_cmp);
    
    
    /* 
     * Now for take each input value and search for it in the sorted ICHAR array. If we find
     * something (non-NULL return from bsearch), the result points to the code/letter pair that it matches. 
     */

    ppresult = (ICHAR **)mxCalloc(nInputValues, sizeof(ICHAR *));
    nresult = 0;
    for (i=0; i<nInputValues; i++)
    {
    	ICHAR ic = { piInputValues[i], ' '};
    	ppresult[i] = (ICHAR *)bsearch(&ic, pichar, nInputCodes, sizeof(ICHAR), ichar_cmp);
    	if (NULL != ppresult[i]) 
    	{
    		/*mexPrintf("Index %d input %d: found char %c\n", i, piInputValues[i], ppresult[i]->c);*/
    		nresult++;
    	}
    	else
    	{
    		/*mexPrintf("Index %d input %d: fail\n", i, piInputValues[i]);*/
    	}
    }
    
    /* 
     * Now create outputs - both will be row vectors 
     */
    
    dims[0] = 1;
    dims[1] = nresult;
    plhs[0] = mxCreateCharArray(2, dims);
    pc = mxGetChars(plhs[0]);
    plhs[1] = mxCreateNumericArray(2, dims, mxINT32_CLASS, mxREAL);
    pi = (int *)mxGetData(plhs[1]);

    nfill = 0;
    for (i=0; i<nInputValues; i++)
    {
    	if (ppresult[i])
    	{
    		pc[nfill] = ppresult[i]->c;
    		pi[nfill] = i+1;
        	/*mexPrintf("%d: %d %c\n", nfill, pi[nfill], pc[nfill]);*/
    		nfill++;
    	}
    }
    mxFree(pichar);
    mxFree(ppresult);
    mxFree(pcInputLetters);
	return;
}

