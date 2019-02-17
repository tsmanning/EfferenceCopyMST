#include "mex.h"
#include "string.h"
#include "stdlib.h"


typedef struct charind_struct 
{
	char c;
	int i;
} CHARIND;

int charind_cmp(const void* keyval, const void *datum);
int charind_cmpi(const void* keyval, const void *datum);



/*
 * [p1 p2] = ecfilter(input_str, filter_chars);
 * 
 * Input string is a 1xN char array. This function finds all occurrences of each char in filter_chars
 * in input_str and puts them in p1. strlen(p1) <= strlen(input_str). Any chars in input_str which are not
 * in filter_str are not put into p1. p2 is an INT32 array of the indices, in the original input_str, of
 * each char in p1. The indices are in MATLAB-ese (1-based, not 0-based). 
 */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
	CHARIND *pichar = NULL;
	CHARIND *presult = NULL;
	CHARIND *ptemp;
	int nresult;
	int i;
	char *pfilter;
	char *pstring;
	
	if (nrhs != 2) 
	{
		mexErrMsgTxt("2 args required!");		
	}

    /* First input must be a string, row vector */
    if ( mxIsChar(prhs[0]) != 1 || mxGetM(prhs[0]) != 1)
    {
    	mexErrMsgTxt("First input must be a char string (row vector).");
    }

    /* Second input must be a string, row vector */
    if ( mxIsChar(prhs[1]) != 1 || mxGetM(prhs[1]) != 1)
    {
    	mexErrMsgTxt("Second input must be a char string (row vector).");
    }

    /* Check for proper number of output arguments */    
    if (nlhs != 2) 
    {
    	mexErrMsgTxt("Need 2 outputs.");
    }

    /* Build array of ICHAR from the filter codes. */
    
    
    /* Make two temp strings. These strings are properly terminated. */
    pstring = mxArrayToString(prhs[0]);
    pfilter = mxArrayToString(prhs[1]);

    /* Build array of CHARIND for sorting. Note: I'm assuming that the input string prhs[0] is the long one, 
     * and the filter string prhs[1] is short. 
     */
    pichar = mxCalloc(mxGetN(prhs[0]), sizeof(ICHAR));
    presult = mxCalloc(mxGetN(prhs[0]), sizeof(ICHAR *));
    nresult = 0;
    for (i=0; i<mxGetN(prhs[0]); i++)
    {
    	pcharind[i].c = pstring[i];
    	pcharind[i].i = i;
    }
    qsort(pcharind, mxGetN(prhs[0]), sizeof(CHARIND), charind_cmp);

    /* Loop through filter string, finding items in the input string and filling the list with them. */
    for (i=0; i<strlen(pfilter); i++)
    {
    	CHARIND dummy;
    	CHARIND *pfirst, *plast;
    	dummy.c = pfilter[i];
    	dummy.i = 0;
    	ptemp = bsearch(&dummy, pcharind, mxGetN(prhs[0]), sizeof(CHARIND), charind_cmp);
    	if (ptemp)
    	{
    		/* There may be more than one element of pcharind which matches, and we are not guaranteed to have 
    		 * the first one!
    		 */
    		while (ptemp > pcharind && ptemp->c == (ptemp-1)->c) ptemp--;
    		
    		/* ptemp is now the first one with the search value. */
    		while (ptemp->c == pfilter[i] && ptemp < pcharind+mxGetN(prhs[0]))
    		{
    			presult[nresult++] = *ptemp;
    			ptemp++;
    		}
    	}
    }
    
    /* Finally, sort presult on the index, not the char */
    qsort(presult, nresult, sizeof(CHARIND), charind_cmpi);

    /* Now set the output values. */
    mwSize dims[2];
    mxChar *pc;
    int *pi;
    dims[0] = 1;
    dims[1] = nresult;
    plhs[0] = mxCreateCharArray(2, dims);
    pc = mxGetChars(plhs[0]);
    plhs[1] = mxCreateNumericArray(2, dims, mxINT32_CLASS, mxREAL);
    pi = (int *)mxGetData(plhs[1]);
    for (i=0; i<nresult; i++)
    {
    	pc[i] = presult[i].c;
    	pi[i] = presult[i].i+1;
    }

    mxFree(pcharind);
    mxFree(presult);
	return;
}

int charind_cmp(const void* keyval, const void *datum)
{
	CHARIND *pkey = (CHARIND *) keyval;
	CHARIND *pdat = (CHARIND *) datum;
	return pkey->c - pdat->c;
}

int charind_cmpi(const void* keyval, const void *datum)
{
	CHARIND *pkey = (CHARIND *) keyval;
	CHARIND *pdat = (CHARIND *) datum;
	return pkey->i - pdat->i;
}
