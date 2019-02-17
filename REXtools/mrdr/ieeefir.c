/* ieeefir.c
 *	subroutines to perform IEEE Finite-Impulse-Response filtering
 * HISTORY:
 *	24feb93	LMO	Created for use in rex standard library
 * $Log: ieeefir.c,v $
 * Revision 1.1.1.1  2015/11/09 19:27:39  devel
 * Initial add of download from http://datashare.nei.nih.gov/LsrDirectoryServlet, dated 5-8-2015.
 *
 * Revision 1.1.1.1  2004/11/19 17:16:37  jwm
 * Imported using TkCVS
 *
 * Revision 1.3  1994/03/21  20:21:16  lmo
 * fix_edge bug at right edge was kludged.
 *
 * Revision 1.2  1993/02/25  22:53:50  lmo
 * *** empty log message ***
 *
 * Revision 1.1  1993/02/24  16:07:19  lmo
 * Initial revision
 *
 */

#define SHURE		/* use Shure's reflection algorithm for fixing edges */

#include <stdio.h>
#include <math.h>
#include "mex.h"
#include "ieeefir.h"
/*
 * math stuff
 */
#ifndef M_PI
#define M_PI		3.14159265358979323846
#endif
#define twopi	(2 * M_PI)

/* DO_IEEE_FIR
 *	perform IEEE FIR filtering.
 * INPUT:
 *	raw	-- start of input signal, with real start of buffer at raw[-ieeeFirOff]
 *	out	-- start of ouput signal, with real start of buffer at filt[-ieeeFirOff]
 *	nraw	-- number of data points
 *	flt	-- pointer to filter array
 */
void do_ieee_fir(float * raw, float * out, int nraw, IeeeFir *flt)
{
	float *pl;
	
	pl = &out[nraw];
	if (flt->dneg) {
		diff(raw, &raw[nraw], out, &pl, flt);
	}
	else {
		filter(raw, &raw[nraw], out, &pl, flt);
	}
}

/*
 * FILTER
 *	N point Finite Impulse Filter
 *
 * INPUT:
 *	x = pointer to buffer of type float
 *	xl = pointer to one past data
 *	xout = pointer to buffer to hold output
 *	pxoutl = pointer to pointer to one beyond output.
 *		*PXOUTL MUST BE SET BY USER TO POINT TO MAX AVAILABLE SPACE,
 *		i.e., *pxoutl = &xout[MAXSIZE]
 *	filt = pointer to filter structure
 *		This filter is in the order put out by the FIR program,
 *		so that f[0] = the most distant negative time,
 *		and f[n] = time zero
 * OUTPUT:
 *	xout[] is filled with the calculated data
 *		at the beginning and end, where the filter output
 *		is undefined, the raw data is used.
 *	pxoutl is set to point to last calculated data
 *
 * REV
 *	30jul87	LMO	correct count for even low-pass filters
 *	29jul92	LMO	fix buffer ends
 */
void filter(float *x, float *xl, float *xout, float **pxoutl, IeeeFir *filt)
{
	register int i;
	register double *h;
	static double z;
	float w;
	int num, odd;

	num = filt->dnum;
	odd = (filt->dlen & 01 ? 1 : 0);

	if ((xl - x) > (*pxoutl - xout)) xl = x + (*pxoutl - xout); /* get last x */

	fix_edges(x, xl, num);

	/*
	 * compute by convolving with filter
	 */
	for (; x < xl ; x++, xout++) {
		/* at each point compute sum */
		h = &filt->dptr[num-1];
		if (odd) {
			z = *h-- * x[0];
			for (i = 1; i < num; i++, h--)
				z += *h * (x[i] + x[-i]);
		}
		else {
			z = 0;
			for (i = 0; i < num; h--) {
				w = x[-i];
				w += x[++i];
				z += *h * w;
			}
		}
		*xout = z;
	}

	*pxoutl = xout;
}

/*
 * DIFF
 *	2N + 1 point differentiator
 *
 * INPUT:
 *	x = pointer to buffer of type float
 *	xl = pointer to one past data
 *	xdot = pointer to buffer to hold output
 *	pxdotl = pointer to pointer to one beyond output.
 *		*PXDOTL MUST BE SET BY USER TO POINT TO MAX AVAILABLE SPACE,
 *		i.e., *pxdotl = &xdot[MAXSIZE]
 *	filter = pointer to filter structure
 *		This filter is in the order put out by the FIR program,
 *		so that f[0] = the most distant negative time,
 *		and f[n] = time zero
 * OUTPUT:
 *	xdot[] is filled with the calculated derivative
 *	pxdotl is set to point to last calculated derivative
 *
 * REV:
 *	30jul87	LMO	eliminate 0 pass in differentiator loop
 */
void diff(float *x, float *xl, float *xdot, float **pxdotl, IeeeFir *filter)
{
	register int i;
	register double *h;
	static double z;
	int num;

	num = filter->dnum;

	if ((xl - x) > (*pxdotl - xdot)) xl = x + (*pxdotl - xdot); /* get last x */


	fix_edges(x, xl, num);

	/*
	 * compute derivative by convolving with filter
	 */
	for (; x < xl ; x++, xdot++) {
		/* at each point compute sum */
		for (z = 0, i = 1, h = &filter->dptr[num-1]; i <= num; i++, h--) {
				z += *h * (x[i] - x[-i]);
		}
		*xdot = z;
	}

	*pxdotl = xdot;	/* set up pointer to last */
}

/* FIX_EDGES
 * To avoid edge effects, use Shure's method of reflecting
 * data back at edges before fir filtering
 */
void fix_edges(float *x, float *xl, int num)
{
	int i;
	double z;

	if (num > ieeeFirOff) num = ieeeFirOff;

#ifdef SHURE
	for (i = 1, z = 2 * x[0]; i < num; i++) x[-i] = z - x[i];
	--xl;	/* back up one for bug in offsets */
	for (i = 0, z = 2 * xl[-1]; i < num; i++) xl[i] = z - xl[-i-2];

#else
	for (i = 1; i < num; i++) x[-i] = x[0];		/* fix beginning */
	for (i = 0; i < num; i++) xl[i] = xl[-1];	/* fix ending */
#endif

}
