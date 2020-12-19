/************************************************/
/* 						*/
/*      SuperVGA TrueColor BGI driver defines	*/
/*		Copyright (c) 1994		*/
/*	    Jordan Hargraphix Software		*/
/*						*/
/************************************************/

#ifndef __SVGATC_H__
#define __SVGATC_H__

extern int far _Cdecl SvgaTC_fdriver[];

/* These are the currently supported modes */
#define	SVGA320x200x24bit	0	/* 320x200x24bit TrueColor VGA */
#define	SVGA640x350x24bit	1	/* 640x350x24bit TrueColor VGA */
#define	SVGA640x400x24bit	2	/* 640x400x24bit TrueColor VGA */
#define	SVGA640x480x24bit	3	/* 640x480x24bit TrueColor VGA */
#define	SVGA800x600x24bit	4	/* 800x600x24bit TrueColor VGA */
#define	SVGA1024x768x24bit	5	/* 1024x768x24bit TrueColor VGA */
#define	SVGA1280x1024x24bit	6	/* 1280x1024x24bit TrueColor VGA */

#endif /* __SVGATC_H__ */
