/************************************************/
/* 						*/
/*        SuperVGA S3 BGI driver defines	*/
/*		Copyright (c) 1992		*/
/*	    Jordan Hargraphix Software		*/
/*						*/
/************************************************/

#ifndef __SVGAS3_H__
#define __SVGAS3_H__

extern int far _Cdecl SvgaS3_fdriver[];

/* These are the currently supported modes */
#define	SVGAS3_640x480x256	0	/* 640x480x256 S3 Svga */
#define	SVGAS3_800x600x256	1	/* 800x600x256 S3 Svga */
#define	SVGAS3_1024x768x256	2	/* 1024x768x256 S3 Svga */
#define	SVGAS3_800x600x16	3	/* 800x600x16 S3 Svga */
#define	SVGAS3_1024x768x16	4	/* 1024x768x16 S3 Svga */
#define	SVGAS3_1280x960x16	5	/* 1280x960x16 S3 Svga */
#define	SVGAS3_1280x1024x16	6	/* 1280x1024x16 S3 Svga */
#define	SVGAS3_640x480x32768	7	/* 640x480x32768 S3 HiColor Svga */

#endif /* __SVGAS3_H__ */
