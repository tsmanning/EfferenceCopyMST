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
    char *input_buf, *output_buf;
    mwSize buflen;
    ECFile *ecfP = NULL;
    struct ecode_info eci;
    int count = 0;
	int bcode_time = -1;
	
    const char *field_names[] = {"channel", "time", "value"};
    mwSize dims[2]; 
    mwSize dim1[1] = {1};
    
    /* Check for proper number of input and  output arguments */    
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
        /* Create a 1-by-n array of structs. */ 
    	dims[0] = 1;
    	dims[1] = ecfP->ncodes;
        plhs[0] = mxCreateStructArray(2, dims, 3, field_names);

        count = 0;
    	while (!ecfP->next(ecfP, &eci))
    	{
    		mxArray *channel_value;
    		mxArray *time_value;
    		mxArray *field_value;

    		/* Test ecode to see just what it is. */
    		if (eci.ecode == BCODE_MARK)
    		{
    			bcode_time = eci.time;
    			
    			channel_value = mxCreateNumericArray(1, dim1, mxINT32_CLASS, mxREAL);
    			*((int *)mxGetData(channel_value)) = (int)eci.ecode;
    			
    			time_value = mxCreateNumericArray(1, dim1, mxINT32_CLASS, mxREAL);
    			*((int *)mxGetData(time_value)) = eci.time;

    			field_value = mxCreateNumericArray(1, dim1, mxDOUBLE_CLASS, mxREAL);
    			*((double *)mxGetData(field_value)) = 0;

        		mxSetFieldByNumber(plhs[0], count, 0, channel_value);
        		mxSetFieldByNumber(plhs[0], count, 1, time_value);
        		mxSetFieldByNumber(plhs[0], count, 2, field_value);
    		}
    		else if ((eci.ecode & BCODE_INT)==BCODE_INT)
    		{
    			if (bcode_time < 0) mexErrMsgTxt("Error in efile: BCODE_INT without preceding BCODE_MARK.");
    			
    			channel_value = mxCreateNumericArray(1, dim1, mxINT32_CLASS, mxREAL);
    			*((int *)mxGetData(channel_value)) = (int)(eci.ecode & BCODE_CHANNEL_MASK);
    			
    			time_value = mxCreateNumericArray(1, dim1, mxINT32_CLASS, mxREAL);
    			*((int *)mxGetData(time_value)) = bcode_time;

    			field_value = mxCreateNumericArray(1, dim1, mxDOUBLE_CLASS, mxREAL);
    			*((double *)mxGetData(field_value)) = (double)eci.time;

        		mxSetFieldByNumber(plhs[0], count, 0, channel_value);
        		mxSetFieldByNumber(plhs[0], count, 1, time_value);
        		mxSetFieldByNumber(plhs[0], count, 2, field_value);
    		}
    		else if ((eci.ecode & BCODE_UINT)==BCODE_UINT)
    		{
    			if (bcode_time < 0) mexErrMsgTxt("Error in efile: BCODE_UINT without preceding BCODE_MARK.");
    			
    			channel_value = mxCreateNumericArray(1, dim1, mxINT32_CLASS, mxREAL);
    			*((int *)mxGetData(channel_value)) = (int)(eci.ecode & BCODE_CHANNEL_MASK);
    			
    			time_value = mxCreateNumericArray(1, dim1, mxINT32_CLASS, mxREAL);
    			*((int *)mxGetData(time_value)) = bcode_time;

    			field_value = mxCreateNumericArray(1, dim1, mxDOUBLE_CLASS, mxREAL);
    			*((double *)mxGetData(field_value)) = (unsigned int)eci.time;

        		mxSetFieldByNumber(plhs[0], count, 0, channel_value);
        		mxSetFieldByNumber(plhs[0], count, 1, time_value);
        		mxSetFieldByNumber(plhs[0], count, 2, field_value);
    		}
    		else if ((eci.ecode & BCODE_FLOAT)==BCODE_FLOAT)
    		{
    			if (bcode_time < 0) mexErrMsgTxt("Error in efile: BCODE_FLOAT without preceding BCODE_MARK.");
    			
    			channel_value = mxCreateNumericArray(1, dim1, mxINT32_CLASS, mxREAL);
    			*((int *)mxGetData(channel_value)) = eci.ecode & BCODE_CHANNEL_MASK;
    			
    			time_value = mxCreateNumericArray(1, dim1, mxINT32_CLASS, mxREAL);
    			*((int *)mxGetData(time_value)) = bcode_time;

    			field_value = mxCreateNumericArray(1, dim1, mxDOUBLE_CLASS, mxREAL);
    			*((double *)mxGetData(field_value)) = (double)(*(float *)(&eci.time));

        		mxSetFieldByNumber(plhs[0], count, 0, channel_value);
        		mxSetFieldByNumber(plhs[0], count, 1, time_value);
        		mxSetFieldByNumber(plhs[0], count, 2, field_value);
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
        			channel_value = mxCreateNumericArray(1, dim1, mxINT32_CLASS, mxREAL);
        			*((int *)mxGetData(channel_value)) = REX_INIT_MASK;
        			
        			time_value = mxCreateNumericArray(1, dim1, mxINT32_CLASS, mxREAL);
        			*((int *)mxGetData(time_value)) = eci.time;

        			field_value = mxCreateNumericArray(1, dim1, mxDOUBLE_CLASS, mxREAL);
        			*((double *)mxGetData(field_value)) = (double)(eci.ecode & REX_ECODE_MASK);

            		mxSetFieldByNumber(plhs[0], count, 0, channel_value);
            		mxSetFieldByNumber(plhs[0], count, 1, time_value);
            		mxSetFieldByNumber(plhs[0], count, 2, field_value);
    			}
    			else if (eci.ecode & REX_CANCEL_MASK)
    			{
        			channel_value = mxCreateNumericArray(1, dim1, mxINT32_CLASS, mxREAL);
        			*((int *)mxGetData(channel_value)) = eci.ecode;
        			
        			time_value = mxCreateNumericArray(1, dim1, mxINT32_CLASS, mxREAL);
        			*((long int *)mxGetData(time_value)) = eci.time;

        			field_value = mxCreateNumericArray(1, dim1, mxDOUBLE_CLASS, mxREAL);
        			*((double *)mxGetData(field_value)) = 0;

            		mxSetFieldByNumber(plhs[0], count, 0, channel_value);
            		mxSetFieldByNumber(plhs[0], count, 1, time_value);
            		mxSetFieldByNumber(plhs[0], count, 2, field_value);
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

        			channel_value = mxCreateNumericArray(1, dim1, mxINT16_CLASS, mxREAL);
        			*((int *)mxGetData(channel_value)) = temp_ecode;

        			time_value = mxCreateNumericArray(1, dim1, mxINT32_CLASS, mxREAL);
        			*((long int *)mxGetData(time_value)) = eci.time;

        			field_value = mxCreateNumericArray(1, dim1, mxDOUBLE_CLASS, mxREAL);
        			*((double *)mxGetData(field_value)) = 0;

            		mxSetFieldByNumber(plhs[0], count, 0, channel_value);
            		mxSetFieldByNumber(plhs[0], count, 1, time_value);
            		mxSetFieldByNumber(plhs[0], count, 2, field_value);
    			}
    		}
			count = count + 1;
    	}
        ecfP->done(ecfP);
    }
    else
    {
    	mexErrMsgTxt("ecfile_new returned NULL!");
    }
    

    return;
}
    
