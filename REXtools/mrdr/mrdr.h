/*
 *  NOTICE:  This code was developed by the Laboratory of
 *  Sensorimotor Research in the National Eye Institute,
 *  a branch of the U.S. Government.  This code is
 *  distributed without copyright restrictions.  No
 *  individual, company, organization, etc., may copyright
 *  this code.  If it is passed on to others, this notice
 *  must be included.
 *  
 *  Any Modifications to this code, especially bug fixes,
 *  should be reported to LOPTICAN@NIH.GOV.
 * 
 *  Lance M. Optican, Ph.D.
 *  Laboratory of Sensorimotor Research
 *  Bldg 49 Rm 2A50
 *  National Eye Institute, NIH
 *  9000 Rockville Pike, Bethesda, MD, 20892-4435
 *  (301) 496-9375.
 * 
 *  May 17, 1999
 *-----------------------------------------------------------------------*
 *
 *  REX2MATLAB.H
 *  This file contains header information for a C-program
 *	that converts REX A- and E-files into a format
 *	readable by MATLAB, using Matlab's MX library calls.
 *
 *	The MAT-file contains an array of structures (Trials).
 *	Each structure contains information about the trial,
 *	as well as arrays or cell arrays containing the data.
 *
 *	To include the names of all the structure elements for
 *	MX-programs, #define MATLAB_NAMES before the include
 *	for rex2matlab.h.  For example:
 *
 *		#define MATLAB_NAMES
 *		#include "rex2matlab.h"
 *		#include "mex.h"
 *
 * !!!	WARNING:  The structure elements are named for			!!!
 * !!!		matlab usage in mrdd3.c below in the MATLAB_NAMES	!!!
 * !!!		section.  ALWAYS CHANGE STRUCTURES			!!!
 * !!!		AND NAMES IN BOTH PLACES!!				!!!
 *
 * 10may1999	LMO & JWM	create
 * 12may1999	LMO		change from linked lists to arrays
 */

#ifndef _MRDR_H_
#define _MRDR_H_

#include <stdio.h>

int mEvent_number_of_elts = 2;
const char *mEvent_elts_names[] = {
	"Code",
	"Time"
};

int mUnits_number_of_elts = 2;
const char *mUnits_elts_names[] = {
	"Code",
	"Times"
};

int mSignal_number_of_elts = 2;
const char *mSignal_elts_names[] = {
	"Signal",
	"Name"
};

int mTrials_number_of_elts = 9;
const char *mTrials_elts_names[] = {
	"trialNumber",
	"tStartTime",
	"aStartTime",
	"aEndTime",
	"tEndTime",
	"a2dRate",
	"Signals",
	"Events",
	"Units",
};

static int32_t mrdr_startCode = 1001;
static int32_t mrdr_maxSampRate = 0;
static int32_t mrdr_preTime = 0;
static int32_t mrdr_absTime = 0;
static int32_t mrdr_numTrials = 0;

static void clearTrials(void);
void readData(int32_t nNewTrials, int32_t nPrevTrials, mxArray *plhs);
mxArray *cvt_trialNumber(int32_t trialNumber);
mxArray *cvt_tStartTime(int32_t tStartTime);
mxArray *cvt_aStartTime(int32_t aStartTime);
mxArray *cvt_aEndTime(int32_t aEndTime);
mxArray *cvt_tEndTime(int32_t tEndTime);
mxArray *cvt_a2drate(float a2drate);
mxArray *cvt_signals(int32_t nSignals, int32_t maxPoints, SignalList *signalList);
mxArray *cvt_events(int32_t nEvents, int32_t tStartTime, EVENT *events);
mxArray *cvt_units(int32_t nUnits, int32_t tStartTime, int16_t *unitCodes, RexUnits *rexunits);
mxArray *cvt_short(int32_t npts, int16_t *p);
mxArray *cvt_long(int32_t npts, int32_t *p);
mxArray *cvt_float(int32_t npts, float *p);

#endif /*_MRDR_H_*/

