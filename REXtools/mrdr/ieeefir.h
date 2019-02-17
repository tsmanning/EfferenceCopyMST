/* IEEEFIR.H
 *	Header for Differentiators and other FIR filters
 *	In IEEE FIR format
 *
 * History:
 * $Log: ieeefir.h,v $
 * Revision 1.1.1.1  2015/11/09 19:27:39  devel
 * Initial add of download from http://datashare.nei.nih.gov/LsrDirectoryServlet, dated 5-8-2015.
 *
 * Revision 1.1.1.1  2004/11/19 17:16:37  jwm
 * Imported using TkCVS
 *
 * Revision 1.4  1999/09/28 18:34:24  lmo
 * *** empty log message ***
 *
 * Revision 1.3  1993/04/03  22:16:26  lmo
 * samp header
 *
 * Revision 1.2  1993/02/25  22:54:24  lmo
 * *** empty log message ***
 *
 * Revision 1.1  1993/02/24  16:07:48  lmo
 * Initial revision
 *
 * Revision 1.1  1993/02/24  15:43:39  lmo
 * Initial revision
 *
 * Revision 2.0  1992/07/22  18:53:51  lmo
 * SunView Final Version
 *
 * Revision 1.1  1991/02/26  15:39:47  lmo
 * Initial revision
 *
 */
#ifndef __IEEEFIR_H__
#define  __IEEEFIR_H__

#define PRIVATE	static

#define ieeeFirMax	167		/* biggest IEEE filter */
#define ieeeFirOff	(ieeeFirMax/2)

#define TEMPSIZE	256	/* MUST BE A POWER OF 2! this determines
						 * the size of data buffer converted in one
						 * step taken by fftconv()
						 * Cannot be smaller than filter size
						 */

/*
 *	Standard filter format is dptr[0] is furthest back in time!
 */
typedef struct {
	char *dname;	/* file name for FIR values */
	double dscale;	/* scale factor */
	int dnum;	/* number of points in half a filter, stored in dptr[] */
	int dlen;	/* length of whole filter */
	int dneg;	/* dneg == 1 ? antisymmetric : symmetric */
	double *dptr;	/* pointer to raw FIR values */
} IeeeFir;

/*
 * PUBLIC FUNCTION PROTOTYPES
 */
void do_ieee_fir(float * raw, float * filt, int nraw, IeeeFir *filter);
void filter(float *x, float *xl, float *xout, float **pxoutl, IeeeFir *filt);
void diff(float *x, float *xl, float *xdot, float **pxdotl, IeeeFir *filter);
void fix_edges(float *x, float *xl, int num);

#endif /* __IEEEFIR_H__ */
