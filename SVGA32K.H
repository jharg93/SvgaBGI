/************************************************/
/* 						*/
/*      SuperVGA 32768 BGI driver defines	*/
/*		Copyright (c) 1991		*/
/*	    Jordan Hargraphix Software		*/
/*						*/
/************************************************/

#ifndef __SVGA32K_H__
#define __SVGA32K_H__

extern int far _Cdecl Svga32k_fdriver[];

/* These are the currently supported modes */
#define	SVGA320x200x32768	0	/* 320x200x32768 HiColor VGA */
#define	SVGA640x350x32768	1	/* 640x350x32768 HiColor VGA */
#define	SVGA640x400x32768	2	/* 640x400x32768 HiColor VGA */
#define	SVGA640x480x32768	3	/* 640x480x32768 HiColor VGA */
#define	SVGA800x600x32768	4	/* 800x600x32768 HiColor VGA */
#define	SVGA1024x768x32768	5	/* 1024x768x32768 HiColor VGA */
#define	SVGA1280x1024x32768	6	/* 1280x1024x32768 HiColor VGA */

#endif /* __SVGA32K_H__ */
