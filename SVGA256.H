/************************************************/
/* 						*/
/*       SuperVGA 256 BGI driver defines	*/
/*		Copyright (c) 1991		*/
/*	    Jordan Hargraphix Software		*/
/*						*/
/************************************************/

#ifndef __SVGA256_H__
#define __SVGA256_H__

extern int far _Cdecl Svga256_fdriver[];

/* These are the currently supported modes */
#define	SVGA320x200x256		0	/* 320x200x256 Standard VGA */
#define	SVGA640x400x256		1	/* 640x400x256 Svga/VESA */
#define	SVGA640x480x256		2	/* 640x480x256 Svga/VESA */
#define	SVGA800x600x256		3	/* 800x600x256 Svga/VESA */
#define	SVGA1024x768x256	4	/* 1024x768x256 Svga/VESA */
#define	SVGA640x350x256		5	/* 640x350x256 Svga/VESA */
#define	SVGA1280x1024x256	6	/* 1280x1024x256 Svga/VESA */

#endif /* __SVGA256_H__ */
