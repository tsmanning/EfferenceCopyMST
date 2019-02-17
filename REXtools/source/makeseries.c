/*
 * makeseries.c
 *
 *  Created on: Oct 17, 2008
 *      Author: dan
 */

#include "mex.h"
#include "string.h"
#include "stdlib.h"
#include "boost/regex.h"
#include "bcode_defs.h"


/*
 * [series] = makeseries(ecfile, str, strind, pattern)
 */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
	int nresult, nfill;
	int i, j, n;
	int *ptimes = NULL;			/* convenience pointer to time array */
	short int *pcodes = NULL;	/* convenience pointer to codes array */
	int *pchan = NULL;			/* convenience pointer to channels array */
	short int *ptype = NULL;	/* convenience pointer to type array */
	unsigned int *pU = NULL;	/* convenience pointer to uint array */
	int *pI = NULL;				/* convenience pointer to int array */
	float *pF = NULL;			/* convenience pointer to float array */
    mwSize dims[2];
    mxChar *pc;
    int *pi;
    double *pr;
    char *pcInputStr = NULL;
    char *pcRegex = NULL;
    int *piInputStrind= NULL;
    int nInputStrind = 0;
    int nInputValues = 0;
    regex_t rgx;
    regmatch_t *rgxMatchP = NULL;
    int *piBatchSize = NULL;
    double *pSubMatch = NULL;
    double *pSubMatchIndex = NULL;
    char *pcFieldName = NULL;
    int status;
    int ind;
    int nTS;	/* number of timeseries to create */

    /*
	 * Check input/output args.
	 * First and second inputs must be INT32 arrays, though we don't care if they're row or column vectors.
     * Third input must be a string, row vector.
     * There must be an equal number of codes and letters in the second and third inputs, respectively.
     * We require two output args.
	 */

    if (nrhs != 5)
	{
		mexErrMsgTxt("5 args required!");
	}

    if (mxIsStruct(prhs[0]) != 1)
    {
    	mexErrMsgTxt("Expecting struct as arg 1!");
    }
    else
    {
    	const mxArray* ps;


/*
 * This workaround required for linux/mac. Apparently when we pass a class
 * to a mex function the behavior is slightly different. On linux the class
 * is received here as its underlying struct. On the mac however, a struct
 * with a single field is received -- that field is the class' underlying
 * struct.
 *
 * I am not sure if these are the best macros to perform the workaround.
 * I'm working with Matlab R2007a on both platforms. I will not be surprised
 * if this changes with version changes.
 * 
 * UPDATE 8/20/2010
 * It appears that R2009a no longer has this problem. The #if 0 stuff below was the R2007a
 * method, but now R2009a doesn't seem to make a distinction.
 */
#if 0
#if __linux__
    	ps = prhs[0];
#elif __APPLE__
    	ps = mxGetFieldByNumber(prhs[0], 0, 0);
#endif
#endif
    	ps = prhs[0];
    	
    	n = mxGetNumberOfFields(ps);

    	/*
    	 * This enumerates the field names  of the first arg. This arg should be an ecfile,
    	 * and classes seem to be passed as their underlying struct.
    	mexPrintf("There are %d fields\n", n);
        for (i=0; i<n; i++)
        {
        	mexPrintf("Field %d : %s\n", i, mxGetFieldNameByNumber(ps, i));
        }
    	*/

        ptimes = (int *)mxGetData(mxGetFieldByNumber(ps, 0, 0));
    	pcodes = (short int *)mxGetData(mxGetFieldByNumber(ps, 0, 1));
    	pchan = (int *)mxGetData(mxGetFieldByNumber(ps, 0, 2));
    	ptype = (short int *)mxGetData(mxGetFieldByNumber(ps, 0, 3));
    	pU = (unsigned int *)mxGetData(mxGetFieldByNumber(ps, 0, 4));
    	pI = (int *)mxGetData(mxGetFieldByNumber(ps, 0, 5));
    	pF = (float *)mxGetData(mxGetFieldByNumber(ps, 0, 6));

    	n = mxGetM(mxGetFieldByNumber(ps, 0, 0));
/*
        Field 0 : time
        Field 1 : ecode
        Field 2 : channel
        Field 3 : type
        Field 4 : U
        Field 5 : I
        Field 6 : F
        Field 7 : ID
*/


    }

    if ( mxIsChar(prhs[1]) != 1)
    {
    	mexErrMsgTxt("Second arg must be a char array!");
    }

    if ( mxIsInt32(prhs[2]) != 1)
    {
    	mexErrMsgTxt("Third arg must be an INT32 array!");
    }

    /*
     * Check that the letters and numbers are same length. Numbers should be 1xn - same as output from ecencode.
     */

    pcInputStr = mxArrayToString(prhs[1]);
	piInputStrind = (int *)mxGetData(prhs[2]);
	nInputStrind = mxGetNumberOfElements(prhs[2]);
    if (nInputStrind != strlen(pcInputStr))
    {
    	mexErrMsgTxt("Length of str != #cols in ind");
    }

    /*
     * Next arg prhs[3] is the regex.
     */
    if ( mxIsChar(prhs[3]) != 1)
    {
    	mexErrMsgTxt("Fourth arg (regex) must be a char array!");
    }
    pcRegex = mxArrayToString(prhs[3]);
    if (strlen(pcRegex) == 0)
    {
    	mexErrMsgTxt("Regex has length 0!");
    }

    if (regcomp(&rgx, pcRegex, REG_EXTENDED))
    {
    	mexErrMsgTxt("Cannot compile regex.");
    }
    rgxMatchP = (regmatch_t *)mxCalloc(rgx.re_nsub+1, sizeof(regmatch_t));

    /*
     * prhs[4] is a struct array with three fields.
     * First field is numeric, valueis a submatch (can be repeated)
     * Second field is also numeric, indicating the index withing the submatch
     * that corresponds to the data channel (index starts at 0).
     * Third field is string, the name of the timeseries data value.
     */

    if (mxIsStruct(prhs[4]) != 1)
    {
    	mexErrMsgTxt("Expecting struct as arg 4!");
    }
    else
    {
    	if (mxGetNumberOfFields(prhs[4]) != 3)
    	{
    		mexErrMsgTxt("Arg4 struct should have 3 fields.");
    	}
    	else
    	{
    		nTS = mxGetNumberOfElements(prhs[4]);
    		/*
    		mexPrintf("struct has %d elements\n", mxGetNumberOfElements(prhs[4]));
    		*/

			for (i=0; i<nTS; i++)
			{
				pSubMatch = (double *)mxGetPr(mxGetFieldByNumber(prhs[4], i, 0));
				pSubMatchIndex = (double *)mxGetPr(mxGetFieldByNumber(prhs[4], i, 1));
				/*
				mexPrintf("\tField %d submatch %d index %d\n", i, (int)(pSubMatch[0]), (int)(pSubMatchIndex[0]));
				*/
			}
    	}
    }


    /*
     * If we've made it this far then we can proceed. We have to take two passes through
     * the matches; once to determine how long the series will be, and a second time
     * to actually populate the series.
     */

    status = regexec(&rgx, &pcInputStr[0], rgx.re_nsub+1, rgxMatchP, 0);
    n = 0;
    ind = 0;
    while (!status)
    {
    	n+=1;
    	/*mexPrintf("%d: %d - %d %c %c %c\n", n, ind + rgxMatch.rm_so, ind + rgxMatch.rm_eo, pcInputStr[ind + rgxMatch.rm_so], pcInputStr[ind + rgxMatch.rm_so + 1], pcInputStr[ind + rgxMatch.rm_so + 2]);*/
    	ind += rgxMatchP[0].rm_eo;
        status = regexec(&rgx, pcInputStr + ind, rgx.re_nsub+1, rgxMatchP, REG_NOTBOL);
    }

    /* Now allocate space for the timeseries. nTS is the number of timeseries, but we add
     * 1 to it for the time value.
     */

    dims[0] = n;
    dims[1] = nTS;
    plhs[0] = mxCreateNumericArray(2, dims, mxDOUBLE_CLASS, mxREAL);
    pr = (double *)mxGetData(plhs[0]);

    {
        double *p;
        int imatch;
        int ifield;
        double value;

        /*
         * run over the list of matches again, this time populating the array.
         * Remember: pr is the first element of the entire array. matlab stores columns,
         * so use pr, pr+n, pr+2n, etc.
         *
         * Each call to regexec finds a single match (if the return status is 0). Depending
         * on the regex used there can be any number of submatches. Note that the call to regexec
         * indicates that there can be rgx.re_nsub+1 submatches in rgxMatchP. The "+1" is there
         * because the ENTIRE match string is considered the first match... rgxMatchP[0]. Each
         * submatch (the stuff in parens() in the regex), if found, is stored in rgxMatchP[1]....
         * If a particular submatch is NOT found in the match string, then that submatch's
         * start and end (e.g. rgxMatchP[1].rm.so and rgxMatchP[1].rm_eo) are set to -1.
         */

        status = regexec(&rgx, &pcInputStr[0], rgx.re_nsub+1, rgxMatchP, 0);
        ind = 0;
        imatch = 0;
        while (!status)
        {
            /*
             * the match is in rgxMatch.
             * Only handling single match
             * TODO: allocate space for rgxMatch using result from compile?
             *
             * fill the columns with the stuff specified in the input args.
             * specifically,
             */

            for (ifield=0; ifield<nTS; ifield++)
            {
                unsigned int efile_ind;
                unsigned int char_ind;
                pSubMatch = (double *)mxGetPr(mxGetFieldByNumber(prhs[4], ifield, 0));
                pSubMatchIndex = (double *)mxGetPr(mxGetFieldByNumber(prhs[4], ifield, 1));

                /*
                 * TODO: assuming submatch 1!!!! See above for reference to this w/r/t
                 * allocating space for regmatch_t
                 *
                 * Nevermind all that.
                 * The rgxMatch tells us that the submatch starts at
                 * pcInputStr[ind + rgxMatch.rm_so] and runs up to (but not including)
                 * pcInputStr[int + rgxMatch.rm.eo].
                 *
                 * The sub match index is the particular char within the submatch that
                 * we want for this column/field, counting from zero.
                 *
                 * We have two indices to create. One, called 'char_ind', refers
                 * to the index into the character array. That char array was
                 * the subject of the regex search, and rgxMatch and pSubMatchIndex
                 * both are relevant to it. The value of char_ind below is the
                 * index of the specific char in the input string that corresponds
                 * to the data channel we're after.
                 *
                 * The second index is 'efile_ind'. Recall that the input char string
                 * comes with a partner, an index array. Those indices refer to positions
                 * in the efile arrays where the data corresponding to the char values
                 * resides. Remember that when the efile is encoded, not all ecodes and
                 * channels have to be used. Some channels may be left out, and so there
                 * isn't a direct correspondence between the char string created and the
                 * elements of the efile arrays. Each element of the index array holds
                 * the indices of the corresponding character's  data in the efile arrays.
                 *
                 * If pSubMatchIndex is <0 it means take the TIME value for the first element
                 * of that submatch.
                 *
                 */


                if (rgxMatchP[(int)pSubMatch[0]].rm_so < 0)
                {
                    char errmsg[1024];
                    char matchstr[1024];
                    if ((rgxMatchP[0].rm_eo - rgxMatchP[0].rm_so) > 1023) strcpy(matchstr, "match string too long to display");
                    else
                    {
                        strncpy(matchstr, pcInputStr + ind + rgxMatchP[0].rm_so, rgxMatchP[0].rm_eo-rgxMatchP[0].rm_so);
                        matchstr[rgxMatchP[0].rm_eo-rgxMatchP[0].rm_so] = 0;
                    }

                    sprintf(errmsg, "makeseries: Matched text \"%s\" at indices (%d,%d) using regex \"%s\". You are requesting submatch %d in your output column %d, but this submatch was not found.\n", matchstr, ind + rgxMatchP[0].rm_so, ind + rgxMatchP[0].rm_eo, pcRegex, (int)pSubMatch[0], ifield+1);
                    mexErrMsgTxt(errmsg);
                }

                if (pSubMatchIndex[0] == -1)
                {
                    char_ind = ind + rgxMatchP[(int)pSubMatch[0]].rm_so;
                    efile_ind = piInputStrind[char_ind];
                    value = (double)ptimes[efile_ind];
                }
                else if (pSubMatchIndex[0] == -2)
                {
                    char_ind = ind + rgxMatchP[(int)pSubMatch[0]].rm_so;
                    value = (int)pcInputStr[char_ind];
                }
                else
                {
                    char_ind = ind + rgxMatchP[(int)pSubMatch[0]].rm_so + pSubMatchIndex[0];
                    efile_ind = piInputStrind[char_ind];

                    if (rgxMatchP[(int)pSubMatch[0]].rm_so + pSubMatchIndex[0] >= rgxMatchP[(int)pSubMatch[0]].rm_eo)
                    {
                        value = mxGetNaN();
                    }
                    else
                    {
                        /*
                        mexPrintf("match %d field %d ind %d rm_so %d submatchindex %d \n",
                                imatch, ifield, ind, rgxMatch.rm_so, (int)pSubMatchIndex[0]);
                        mexPrintf("char_ind %d efile_ind %d\n", char_ind, efile_ind);
                        */

                        switch(ptype[efile_ind])
                        {
                        case BCODE_INT:
                            value = (double)pI[efile_ind];
                            break;
                        case BCODE_UINT:
                            value = (double)pU[efile_ind];
                            break;
                        case BCODE_FLOAT:
                            value = (double)pF[efile_ind];
                            break;
                        default:
                            value = mxGetNaN();
                            break;
                        }
                    }
                }
                /*
                 * the data array is n x nTS, and it starts at pr
                 * we are iterating on columns, and the index now is imatch
                 * we are also iterating on fields, and the index is ifield
                 *
                 * *(pr + n * ifield + imatch) = value
                 */

                *(pr + n * ifield + imatch) = value;
            }

            /*
             * iterate ind and get the next match
             */

            ind += rgxMatchP[0].rm_eo;
            imatch++;
            status = regexec(&rgx, pcInputStr + ind, rgx.re_nsub+1, rgxMatchP, REG_NOTBOL);
        }
    }
    mxFree(rgxMatchP);
	return;
}


