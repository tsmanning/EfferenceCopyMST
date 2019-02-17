/*
 * ecmatch.c
 *
 *  Created on: July 30, 2009
 *      Author: dan
 */

#include "mex.h"
#include "string.h"
#include "stdlib.h"
#include "regex.h"

/*
 * [matches] = ecmatch(str, strind, regex, submatch)
 */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
    char *pcInputStr = NULL;
    int *piInputStrind = NULL;
    int nInputStrind = 0;
    char *pcRegex = NULL;
    regex_t rgx;
    regmatch_t *rgxMatchP = NULL;
    int iSubMatch = 0;
    int nmatches, ind, restatus, imatch;
    const char *field_names[] = {"str", "strind"};
    mwSize dims[2];


    /*
	 * Check input/output args.
	 * First arg is a string, row vector.
	 * Second arg is an int32 array.
	 * Third arg is a string, which must compile to a regex
	 * Fourth arg is optional, and if present it is an integer representing a submatch. Default is 0.
	 *
	 * There is one output arg - it will be a cell array.
	 */

    if (nlhs != 1)
    {
    	mexErrMsgTxt("Must have one arg on l.h.s.");
    }

    if (nrhs < 3)
	{
		mexErrMsgTxt("Not enough args!");
	}

    if ( mxIsChar(prhs[0]) != 1)
    {
    	mexErrMsgTxt("First arg must be a char array!");
    }

    if ( mxIsInt32(prhs[1]) != 1)
    {
    	mexErrMsgTxt("Second arg must be an INT32 array!");
    }

    if (mxGetM(prhs[1]) > 1 && mxGetN(prhs[1])>1)
    {
    	mexErrMsgTxt("Second arg must be a one-dimensional INT32 array!");
    }

    /*
     * Check that the letters and numbers are same length. Numbers should be 1xn - same as output from ecencode.
     */

    pcInputStr = mxArrayToString(prhs[0]);
	piInputStrind = (int *)mxGetData(prhs[1]);
	nInputStrind = mxGetNumberOfElements(prhs[1]);
    if (nInputStrind != strlen(pcInputStr))
    {
    	mexErrMsgTxt("Length of str (first arg) != #cols in indices array (second arg)");
    }

    /*
     * Next arg prhs[2] is the regex.
     */
    if ( mxIsChar(prhs[2]) != 1)
    {
    	mexErrMsgTxt("Third arg (regex) must be a char array!");
    }
    pcRegex = mxArrayToString(prhs[2]);
    if (strlen(pcRegex) == 0)
    {
    	mexErrMsgTxt("Regex has length 0!");
    }

    if (regcomp(&rgx, pcRegex, REG_EXTENDED))
    {
    	mexErrMsgTxt("Cannot compile regex.");
    }
    mexPrintf("Regex has %d submatches.\n", rgx.re_nsub);
    rgxMatchP = (regmatch_t *)mxCalloc(rgx.re_nsub+1, sizeof(regmatch_t));

    /*
     * prhs[3] is optional. If present it is the submatch that will be returned.
     * Jump through some hoops to allow for int and floating point values.....
     * Once we determine the value, it must be <= rgx.nsub
     */

    if (nrhs >= 4)
    {
    	if (mxIsInt32(prhs[3]) == 1)
    	{
    		int *pitmp = (int *)mxGetData(prhs[3]);
    		iSubMatch = *pitmp;
    	}
    	else if (mxIsDouble(prhs[3]) == 1)
   		{
    		double *pdtmp = (double *)mxGetData(prhs[3]);
    		iSubMatch = (int)(*pdtmp);
   		}
    	else
    	{
    		mexErrMsgTxt("Submatch arg (arg 4) must be INT32 or double.");
    	}
    }

    if (iSubMatch > rgx.re_nsub)
    {
    	char msgtmp[256];
    	sprintf(msgtmp, "Submatch requested (%d) is invalid. Regex provided (\"%s\") has only %d submatches!", iSubMatch, pcRegex, rgx.re_nsub);
    	mexErrMsgTxt(msgtmp);
    }


    /*
     * If we've made it this far then we can proceed. We have to take two passes through
     * the matches; once to determine how many there are, and a second time to actually
     * extract them and generate the output cell array.
     */

    mexPrintf("ecmatch: first pass\n");
    restatus = regexec(&rgx, &pcInputStr[0], rgx.re_nsub+1, rgxMatchP, 0);
    nmatches = 0;
    ind = 0;
    while (0 == restatus)
    {
    	nmatches+=1;
    	mexPrintf("Match %d: %d - %d \n", nmatches, ind + rgxMatchP[0].rm_so, ind + rgxMatchP[0].rm_eo);
    	ind += rgxMatchP[0].rm_eo;
        restatus = regexec(&rgx, pcInputStr + ind, rgx.re_nsub+1, rgxMatchP, REG_NOTBOL);
    }

    mexPrintf("ecmatch: found %d matches.\n", nmatches);


    /*
     * Create a cell array with
     */

    dims[0] = 1;
    dims[1] = nmatches;
    plhs[0] = mxCreateStructArray(2, dims, sizeof(field_names)/sizeof(*field_names), field_names);

    restatus = regexec(&rgx, &pcInputStr[0], rgx.re_nsub+1, rgxMatchP, 0);
    imatch = 0;
    ind = 0;
    while (0 == restatus)
    {
    	mxArray *pStrind;
    	int *piStrind;
    	char *ptmpstr;

    	/*
    	 * Check that the requested submatch was, in fact, matched. If it was, then create
    	 * the index array and the string and stuff them into the struct array.
    	 */
    	if (rgxMatchP[iSubMatch].rm_so < 0 || rgxMatchP[iSubMatch].rm_eo < 0)
    	{
    		char matchtmp[256];
    		char errtmp[1024];
    		if (rgxMatchP[0].rm_eo - rgxMatchP[0].rm_so > 255)
    		{
    			strcpy(matchtmp, "match_too_long");
    		}
    		else
    		{
    			strncat(matchtmp, pcInputStr + ind + rgxMatchP[0].rm_so, rgxMatchP[0].rm_eo-rgxMatchP[0].rm_so);
    		}
    		sprintf(errtmp, "Submatch %d was not matched (match %d: \"%s\"", iSubMatch, imatch, matchtmp);
    		mexErrMsgTxt(errtmp);
    	}

    	dims[0] = 1;
    	dims[1] = rgxMatchP[0].rm_eo-rgxMatchP[0].rm_so;
    	pStrind = mxCreateNumericArray(2, dims, mxINT32_CLASS, mxREAL);
    	piStrind = (int *)mxGetPr(pStrind);
    	for (j = 0; j<rgxMatchP[iSubMatch].rm_eo-rgxMatchP[iSubMatch].rm_so; j++)
    	{
    		piStrind[j] = piInputStrind[ind + rgxMatchP[iSubMatch].re_so + j];
    	}
    	mxSetFieldByNumber(plhs[0], imatch, 1, piStrind);

    	ptmpstr = mxMalloc(rgxMatchP[iSubMatch].rm_eo-rgxMatchP[iSubMatch].rm_so+1);
    	strncat(ptmpstr, piInputStrind + ind + rgxMatchP[iSubMatch].re_so, rgxMatchP[iSubMatch].rm_eo-rgxMatchP[iSubMatch].rm_so);
    	mxSetFieldByNumber(plhs[0], imatch, 0, mxCreateString(ptmpstr));

    	ind += rgxMatchP[0].rm_eo;
        restatus = regexec(&rgx, pcInputStr + ind, rgx.re_nsub+1, rgxMatchP, REG_NOTBOL);
        imatch += 1;
    }


    for (i=0; i<nmatches; i++) {

    	mxArray *field_value;
	/* Use mxSetFieldByNumber instead of mxSetField for efficiency
	   mxSetField(plhs[0],i,"name",mxCreateString(friends[i].name); */
	mxSetFieldByNumber(plhs[0],i,name_field,mxCreateString(friends[i].name));
	field_value = mxCreateDoubleMatrix(1,1,mxREAL);
	*mxGetPr(field_value) = friends[i].phone;
	/* Use mxSetFieldByNumber instead of mxSetField for efficiency
	   mxSetField(plhs[0],i,"name",mxCreateString(friends[i].name); */
	mxSetFieldByNumber(plhs[0],i,phone_field,field_value);
    }
}


    mexPrintf("ecmatch: all done\n");

    mxFree(pcInputStr);
    mxFree(pcRegex);
    mxFree(rgxMatchP);
	return;
}


