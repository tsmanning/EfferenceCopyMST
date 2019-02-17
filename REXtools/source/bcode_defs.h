/*
 * bcode.h
 *
 *  Created on: Nov 11, 2008
 *      Author: dan
 */

#ifndef BCODE_H_
#define BCODE_H_


#define REX_AFILE_MASK	0x8000
#define REX_CANCEL_MASK	0x4000
#define REX_INIT_MASK	0x2000
#define REX_ECODE_MASK	0x1fff
#define BCODE_FLAG		0x1000
#define BCODE_FLOAT		(BCODE_FLAG | 0x800)
#define BCODE_INT		(BCODE_FLAG | 0x400)
#define BCODE_UINT		(BCODE_FLAG | 0x200)
#define BCODE_MARK		(BCODE_FLAG | 0x100)
#define BCODE_CHANNEL_MASK	0x00ff
#define REXTYPE_FLAG		0x2000
#define REXTYPE_ID			(REXTYPE_FLAG | 0x800)
#define REXTYPE_CANCEL		(REXTYPE_FLAG | 0x400)
#define REXTYPE_AFILE		(REXTYPE_FLAG | 0x200)
#define REXTYPE_ECODE		(REXTYPE_FLAG | 0x100)

#endif /* BCODE_H_ */
