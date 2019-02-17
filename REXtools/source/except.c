#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#ifdef MATLAB_MEX_FILE
#include "mex.h"
#endif
#include "except.h"

#define ERRMAXSTK 32
static const char *errstk[ERRMAXSTK];
static int nstk=0;

void poptrace(void)
{
	if (nstk==0)  throw("poptrace(): attempt to pop empty exception stack");
	else
	{
		if (errstk[nstk-1])
		{
#ifdef MATLAB_MEX_FILE
			mxFree(errstk[nstk-1]);
#else
			free(errstk[nstk-1]);
#endif
			errstk[nstk-1] = NULL;
		}
		nstk--;
	}
}

void clrtrace(void)
{
	int i;
	for (i=0; i<nstk; i++)
	{
#ifdef MATLAB_MEX_FILE
		mxFree(errstk[i]);
#else
		free(errstk[i]);
#endif
		errstk[i] = NULL;
	}
	nstk=0;
}


void trace(const char *fmt, ...)
{
	char buffer[256];
	char *b;
	va_list al;
	int len;

	va_start(al, fmt);
	vsprintf(buffer, fmt, al);
	len = strlen(buffer);
#ifdef MATLAB_MEX_FILE
	if ((b=(char *) mxMalloc(len+1))==NULL)
#else
	if ((b=(char *) malloc(len+1))==NULL)
#endif
		throw("tracef(%s, ...): unable to malloc", fmt);
	strcpy(b, buffer);
	if (nstk==ERRMAXSTK-1) throw("exception stack full");
	errstk[nstk]=b;
	nstk++;
}

/* default exception catcher
 */
static void dcatch(const char *s)
{
#ifdef MATLAB_MEX_FILE
	mexErrMsgTxt(s);	/* this exits the mex file and frees all mem */
#else
	printf("%s\n", s);
#endif
}

#define MAXCATCH 16
static void (*catchf[MAXCATCH])(const char *) = { dcatch };
static int ncatch=1;

void throw(const char *fmt, ...)
{
	char buffer[256], *cp;
	const char *b;
	int i, len;
	va_list al;

	va_start(al, fmt);
	vsprintf(buffer, fmt, al);
	len = strlen(buffer);
#ifdef MATLAB_MEX_FILE
	if ((cp=(char *) mxMalloc(len+1))!=NULL) strcpy(cp, buffer), b=cp;
#else
	if ((cp=(char *) malloc(len+1))!=NULL) strcpy(cp, buffer), b=cp;
#endif
	else b = fmt;
#ifdef MATLAB_MEX_FILE
	for (i=0; i<nstk; i++) mexWarnMsgTxt(errstk[i]);
#else
	for (i=0; i<nstk; i++) printf("%s\n", errstk[i]);
#endif
	catchf[ncatch-1](b);
}

void catch(void (*f)(const char *))
{
	if (ncatch<MAXCATCH-1) catchf[ncatch]=f;
	else throw("Out of catch stack space");
	ncatch++;
}

void popcatch(void)
{
	if (ncatch>1) ncatch--;
}





