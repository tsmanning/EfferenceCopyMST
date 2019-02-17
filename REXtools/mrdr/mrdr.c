#include <ctype.h>
#include <string.h>

#if defined(_CONSOLE)
#include <io.h>
#else
#include <unistd.h>
#endif

#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "mex.h"
#include "matrix.h"
#include "rex.h"
#include "mrdr.h"

void mexFunction(int32_t nlhs, mxArray *plhs[], int32_t nrhs, const mxArray *prhs[])
{
	char errmsg[512];
	char arg[512];
	char files[20][512];
	int32_t argLen;
	int32_t status;
	int32_t nDims;
	int32_t Dims[2];
	int32_t nFiles;
	int32_t newTrials;
	int32_t rd;
	int32_t i;

	if(nrhs < 2) {
		mexErrMsgTxt("You must enter at least one file");
	}

	mrdr_absTime = 0;
    mrdr_startCode = 1001;
    mrdr_maxSampRate = 0;
    mrdr_preTime = 0;

	/* loop throught the right hand side and get the file names */
	nFiles = 0;
	for(i = 0; i < nrhs; ++i) {
		if(mxIsChar(prhs[i]) != 1) {
			sprintf(errmsg, "Input %d is not valid", i);
			mexErrMsgTxt(errmsg);
		}

		argLen = mxGetN(prhs[i]) + 1;
		status = mxGetString(prhs[i], arg, argLen);

		if(arg[0] == '-') {
			switch(arg[1]) {
			case 'a':
				mrdr_absTime = -1;
				break;
			case 'c':
				ucdFixBcodeEvents();
				break;
			case 'd':
				++i;
				argLen = mxGetN(prhs[i]) + 1;
				status = mxGetString(prhs[i], arg, argLen);
				strcpy(files[nFiles], arg);
				++nFiles;
				/*
				sprintf(errmsg, "file %d name is %s\n", nFiles, files[nFiles - 1]);
				mexWarnMsgTxt(errmsg);
				*/
				break;
			case 'f':
				++i;
				argLen = mxGetN(prhs[i]) + 1;
				status = mxGetString(prhs[i], arg, argLen);
				sscanf(arg, "%d", &mrdr_maxSampRate);
				break;
			case 'p':
				++i;
				argLen = mxGetN(prhs[i]) + 1;
				status = mxGetString(prhs[i], arg, argLen);
				sscanf(arg, "%d", &mrdr_preTime);
				break;
			case 's':
				++i;
				argLen = mxGetN(prhs[i]) + 1;
				status = mxGetString(prhs[i], arg, argLen);
				sscanf(arg, "%d", &mrdr_startCode);
				break;
			}
		}
	}

	/* get the data */
	/* split events and units */
	rexSplitEvents();
	/* 	mexWarnMsgTxt("splitting events and units\n"); */

	/* open all files and get the total number of trials */
	/* 	mexWarnMsgTxt("opening files to count trials\n"); */
	mrdr_numTrials = 0;
	for(i = 0; i < nFiles; ++i) {
		newTrials = rexFileOpen(files[i], mrdr_maxSampRate, mrdr_startCode, mrdr_preTime);

		/*
		sprintf(errmsg, "file %d newTrials = %d\n", i, newTrials);
		mexWarnMsgTxt(errmsg);
		*/

		if(newTrials == 0) {
			sprintf(errmsg, "Warning: No trials found in %s\n", files[i]);
			mexWarnMsgTxt(errmsg);
			memset(files[i], 0, 512);
		}
		rexFileClose();
		mrdr_numTrials += newTrials;
	}
	if(mrdr_numTrials == 0) {
		mexErrMsgTxt("Error: No trials found in any of the input files\n");
	}

	/*
	sprintf(errmsg, "mrdr_numTrials = %d\n", mrdr_numTrials);
	mexWarnMsgTxt(errmsg);
	*/

	/*  build the left had side */
	nDims = 2;
	Dims[0] = 1;
	Dims[1] = mrdr_numTrials;

	plhs[0] = mxCreateStructArray(nDims, Dims, mTrials_number_of_elts, mTrials_elts_names);
	if(plhs[0] == NULL) {
		mexErrMsgTxt("Could not create struct array: Probable cause - insufficient heap");
	}

	/* now open all files and load the data into the plhs structure array */
	/* 	mexWarnMsgTxt("opening files to read data\n"); */
	mrdr_numTrials = 0;
	for(i = 0; i < nFiles; ++i) {
		if(files[i] != (char *)NULL) {
			newTrials = rexFileOpen(files[i], mrdr_maxSampRate, mrdr_startCode, mrdr_preTime);

			/*
			sprintf(errmsg, "file %d newTrials = %d\n", i, newTrials);
			mexWarnMsgTxt(errmsg);
			*/

			readData(newTrials, mrdr_numTrials, plhs[0]);

			rexFileClose();
			mrdr_numTrials += newTrials;
		}
	}

	return;
}

void readData(int32_t nNewTrials, int32_t nPrevTrials, mxArray *plhs)
{
    mxArray *ptr;
	RexInfo *ri;
	int32_t trialNumber;
	int32_t plhsIndx;
	int32_t mu;
	int32_t i;
	int32_t j;
	char warn[100];

	for(i = 0; i < nNewTrials; ++i) {
		trialNumber = i + 1;
		plhsIndx = i + nPrevTrials;

		if((ri = rexGetTrial(trialNumber, 1)) != (RexInfo *)NULL) {
			float a2dRate;
			int32_t tStartTime;
			int32_t tEndTime;
			int32_t aStartTime;
			int32_t aEndTime;

			if(mrdr_absTime != 0) {
				tStartTime = ri->tStartTime;
				aStartTime = ri->aStartTime;
				aEndTime = ri->aEndTime;
				tEndTime = ri->tEndTime;
			}
			else {
				tStartTime = 0;
				aStartTime = ri->aStartTime - ri->tStartTime;
				aEndTime = ri->aEndTime - ri->tStartTime;
				tEndTime = ri->tEndTime - ri->tStartTime;
			}
			a2dRate = (float) ri->maxSampRate;

			/* load this trial into the left hand matrix */
			mxSetField(plhs, plhsIndx, "trialNumber", cvt_trialNumber(trialNumber));
			mxSetField(plhs, plhsIndx, "tStartTime", cvt_tStartTime(tStartTime));
			mxSetField(plhs, plhsIndx, "aStartTime", cvt_aStartTime(aStartTime));
			mxSetField(plhs, plhsIndx, "aEndTime", cvt_aEndTime(aEndTime));
			mxSetField(plhs, plhsIndx, "tEndTime", cvt_tEndTime(tEndTime));
			mxSetField(plhs, plhsIndx, "a2dRate", cvt_a2drate(a2dRate));
			if(ri->nSignals > 0) {
                ptr = cvt_signals(ri->nSignals, ri->nPoints, ri->signalList);
                
                if(ptr != (mxArray *)NULL) {
    				mxSetField(plhs, plhsIndx, "Signals", ptr);
                }
                else {
                    sprintf(warn, "No signals found in trial %d", trialNumber);
                    mexWarnMsgTxt(warn);
                }
			}
			if(ri->nEvents > 0) {
                ptr = cvt_events(ri->nEvents, ri->tStartTime - tStartTime, ri->events);
                
                if(ptr != (mxArray *)NULL) {
    				mxSetField(plhs, plhsIndx, "Events", ptr);
                }
                else {
                    sprintf(warn, "No events found in trial %d", trialNumber);
                    mexWarnMsgTxt(warn);
                }
			}
			if(ri->nUnits > 0) {
                ptr = cvt_units(ri->nUnits, ri->tStartTime - tStartTime, ri->unitCodes, ri->rexunits);
                
                if(ptr != (mxArray *)NULL) {
    				mxSetField(plhs, plhsIndx, "Units", ptr);
                }
                else {
                    sprintf(warn, "No units found in trial %d", trialNumber);
                    mexWarnMsgTxt(warn);
                }
			}
		}
	}
}

mxArray *cvt_trialNumber(int32_t trialNumber)
{
	int32_t *p;
	int32_t nDims = 2;
	int32_t Dims[] = { 1, 1 };
	mxArray *ptr;

	ptr = mxCreateNumericArray(nDims, Dims, mxINT32_CLASS, mxREAL);
	if(ptr == NULL) {
		mexErrMsgTxt("cvt_trialNumber(); Could not create numeric array: Probable cause - insufficient heap");
	}

	p = (int32_t *)mxGetData(ptr);

	*p = trialNumber;

	return(ptr);
}

mxArray *cvt_tStartTime(int32_t tStartTime)
{
	int32_t *p;
	int32_t nDims = 2;
	int32_t Dims[] = { 1, 1 };
	mxArray *ptr;

	ptr = mxCreateNumericArray(nDims, Dims, mxINT32_CLASS, mxREAL);
	if(ptr == NULL) {
		mexErrMsgTxt("cvt_tStartTime(); Could not create numeric array: Probable cause - insufficient heap");
	}

	p = (int32_t *)mxGetData(ptr);

	*p = tStartTime;

	return(ptr);
}

mxArray *cvt_aStartTime(int32_t aStartTime)
{
	int32_t *p;
	int32_t nDims = 2;
	int32_t Dims[] = { 1, 1 };
	mxArray *ptr;

	ptr = mxCreateNumericArray(nDims, Dims, mxINT32_CLASS, mxREAL);
	if(ptr == NULL) {
		mexErrMsgTxt("cvt_aStartTime(); Could not create numeric array: Probable cause - insufficient heap");
	}

	p = (int32_t *)mxGetData(ptr);

	*p = aStartTime;

	return(ptr);
}

mxArray *cvt_aEndTime(int32_t aEndTime)
{
	int32_t *p;
	int32_t nDims = 2;
	int32_t Dims[] = { 1, 1 };
	mxArray *ptr;

	ptr = mxCreateNumericArray(nDims, Dims, mxINT32_CLASS, mxREAL);
	if(ptr == NULL) {
		mexErrMsgTxt("cvt_aEndTime(); Could not create numeric array: Probable cause - insufficient heap");
	}

	p = (int32_t *)mxGetData(ptr);

	*p = aEndTime;

	return(ptr);
}

mxArray *cvt_tEndTime(int32_t tEndTime)
{
	int32_t *p;
	int32_t nDims = 2;
	int32_t Dims[] = { 1, 1 };
	mxArray *ptr;

	ptr = mxCreateNumericArray(nDims, Dims, mxINT32_CLASS, mxREAL);
	if(ptr == NULL) {
		mexErrMsgTxt("cvt_tEndTime(); Could not create numeric array: Probable cause - insufficient heap");
	}

	p = (int32_t *)mxGetData(ptr);

	*p = tEndTime;

	return(ptr);
}

mxArray *cvt_a2drate(float a2dRate)
{
	float *p;
	int32_t nDims = 2;
	int32_t Dims[] = { 1, 1 };
	mxArray *ptr;

	ptr = mxCreateNumericArray(nDims, Dims, mxSINGLE_CLASS, mxREAL);
	if(ptr == NULL) {
		mexErrMsgTxt("cvt_a2drate(); Could not create numeric array: Probable cause - insufficient heap");
	}

	p = (float *)mxGetData(ptr);

	*p = a2dRate;

	return(ptr);
}

mxArray *cvt_signals(int32_t nSignals, int32_t maxPoints, SignalList *signalList)
{
	SignalList *psl;
	float *signal;
	mxArray *ptr = (mxArray *)NULL;
	int32_t nDims = 2;
	int32_t Dims[2];
	int32_t si;
	int32_t i;

	Dims[0] = 1;
	Dims[1] = nSignals;

	if(maxPoints == 0) {
        return(ptr);
    }
    
    signal = mxMalloc(maxPoints * sizeof(float));
	if(signal == (float *)NULL) {
		mexErrMsgTxt("cvt_signals(); Could not create signal array: Probable cause - insufficient heap");
	}

	ptr = mxCreateStructArray(nDims, Dims, mSignal_number_of_elts, mSignal_elts_names);
	if(ptr == NULL) {
		mexErrMsgTxt("cvt_signals(); Could not create struct array: Probable cause - insufficient heap");
	}
	
	si = 0;
	for(psl = signalList; psl; psl = psl->next) {
		mxSetField(ptr, si, "Name", mxCreateString(psl->sigLabel));
		
		for(i = 0; i < psl->npts; ++i) {
			signal[i] = ((float)psl->signal[i] * psl->scale);
		}

		mxSetField(ptr, si, "Signal", cvt_float(psl->npts, signal));
		++si;
	}

	mxFree(signal);

	return(ptr);
}

mxArray *cvt_events(int32_t nEvents, int32_t tStartTime, EVENT *events)
{
	mxArray *ptr = (mxArray *)NULL;
	int32_t nDims = 2;
	int32_t Dims[2];
	int32_t numEvnt = 0;
	int32_t time;
	int32_t ei;
	int32_t n;

	/* eliminate negative events, as these refer to A-file */
	for(ei = 0; ei < nEvents; ++ei) {
		if(events[ei].e_code >= 0) ++numEvnt;
	}
    
    if(numEvnt == 0) {
        return(ptr);
    }

	Dims[0] = 1;		/* rows */
	Dims[1] = numEvnt;	/* colums */

	ptr = mxCreateStructArray(nDims, Dims, mEvent_number_of_elts, mEvent_elts_names);
	if(ptr == NULL) {
		mexErrMsgTxt("cvt_events(); Could not create struct array: Probable cause - insufficient heap");
	}
	
	n = 0;
	for(ei = 0; ei < nEvents; ++ei) {
		if(events[ei].e_code >= 0) {
			time = events[ei].e_key - tStartTime;
			mxSetField(ptr, n, "Code", cvt_short(1, &events[ei].e_code));
			mxSetField(ptr, n, "Time", cvt_long(1, &time));
			++n;
		}
	}

	return(ptr);
}

mxArray *cvt_units(int32_t nUnits, int32_t tStartTime, int16_t *unitCodes, RexUnits *rexunits)
{
	int32_t *times;
	int32_t maxTimes = 0;
	mxArray *ptr = (mxArray *)NULL;
	int32_t nDims = 2;
	int32_t Dims[2];
	int32_t ui;
	int32_t i;

	/* count the maximum number of times */
	for(ui = 0; ui < nUnits; ++ui) {
		if(rexunits->nTimes[ui] > maxTimes) maxTimes = rexunits->nTimes[ui];
	}
    if(maxTimes == 0) {
        return(ptr);
    }

	times = mxMalloc(maxTimes * sizeof(int32_t));
	if(times == (int32_t *)NULL) {
		mexErrMsgTxt("cvt_units(); Could not create time array Probable cause - insufficient heap");
	}

	Dims[0] = 1;		/* rows */
	Dims[1] = nUnits;	/* colums */

	ptr = mxCreateStructArray(nDims, Dims, mUnits_number_of_elts, mUnits_elts_names);
	if(ptr == NULL) {
		mexErrMsgTxt("cvt_units() Could not create struct array: Probable cause - insufficient heap");
	}
	
	for(ui = 0; ui < nUnits; ++ui) {
		for(i = 0; i < rexunits->nTimes[ui]; ++i) {
			times[i] = rexunits->unitTimes[ui][i] - tStartTime;
		}

		mxSetField(ptr, ui, "Code", cvt_short(1, &unitCodes[ui])); 
		mxSetField(ptr, ui, "Times", cvt_long(rexunits->nTimes[ui], times)); 
	}

	mxFree(times);

	return(ptr);
}

mxArray *cvt_short(int32_t npts, int16_t *d)
{
	mxArray *ptr;
	int32_t nDim = 2;
	int32_t Dims[2];
	int16_t *p;
	int16_t dummy = 0;

	if (npts < 1 || d == NULL) {
		npts = 1;
		d = &dummy;
	}

	Dims[0] = 1;
	Dims[1] = npts;

	ptr = mxCreateNumericArray(nDim, Dims, mxINT16_CLASS, mxREAL);
	if(ptr == NULL) {
		mexErrMsgTxt("cvt_short(); Could not create numeric array: Probable cause - insufficient heap");
	}

	p = (int16_t *)mxGetData(ptr);

	memcpy(p, d, (npts * sizeof(int16_t)));

	return(ptr);
}

mxArray *cvt_long(int32_t npts, int32_t *d)
{
	mxArray *ptr;
	int32_t nDim = 2;
	int32_t Dims[2];
	int32_t *p;
	int32_t dummy = 0;

	if (npts < 1 || d == NULL) {
		npts = 1;
		d = &dummy;
	}

	Dims[0] = 1;
	Dims[1] = npts;

	ptr = mxCreateNumericArray(nDim, Dims, mxINT32_CLASS, mxREAL);
	if(ptr == NULL) {
		mexErrMsgTxt("cvt_long(); Could not create numeric array: Probable cause - insufficient heap");
	}

	p = (int32_t *)mxGetData(ptr);

	memcpy(p, d, (npts * sizeof(int32_t)));

	return(ptr);
}

mxArray *cvt_float(int32_t npts, float *d)
{
	mxArray *ptr;
	int32_t nDim = 2;
	int32_t Dims[2];
	float *p;
	float dummy = 0;

	if (npts < 1 || d == NULL) {
		npts = 1;
		d = &dummy;
	}

	Dims[0] = 1;
	Dims[1] = npts;

	ptr = mxCreateNumericArray(nDim, Dims, mxSINGLE_CLASS, mxREAL);
	if(ptr == NULL) {
		mexErrMsgTxt("cvt_float(); Could not create numeric array: Probable cause - insufficient heap");
	}

	p = (float *)mxGetData(ptr);

	memcpy(p, d, (npts * sizeof(float)));

	return(ptr);
}
