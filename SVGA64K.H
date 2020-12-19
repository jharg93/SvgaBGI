/************************************************/
/* 						*/
/*      SuperVGA 65536 BGI driver defines	*/
/*		Copyright (c) 1993		*/
/*	    Jordan Hargraphix Software		*/
/*						*/
/************************************************/

#ifndef __SVGA64K_H__
#define __SVGA64K_H__

extern int far _Cdecl Svga64k_fdriver[];

/* These are the currently supported modes */
#define	SVGA320x200x65536	0	/* 320x200x65536 HiColor VGA */
#define	SVGA640x350x65536	1	/* 640x350x65536 HiColor VGA */
#define	SVGA640x400x65536	2	/* 640x400x65536 HiColor VGA */
#define	SVGA640x480x65536	3	/* 640x480x65536 HiColor VGA */
#define	SVGA800x600x65536	4	/* 800x600x65536 HiColor VGA */
#define	SVGA1024x768x65536	5	/* 1024x768x65536 HiColor VGA */
#define	SVGA1280x1024x65536	6	/* 1280x1024x65536 HiColor VGA */

#endif /* __SVGA64K_H__ */
