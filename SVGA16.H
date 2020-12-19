/************************************************/
/* 						*/
/*        SuperVGA 16 BGI driver defines	*/
/*		Copyright (c) 1991		*/
/*	    Jordan Hargraphix Software		*/
/*						*/
/************************************************/

#ifndef __SVGA16_H__
#define __SVGA16_H__

extern int far Svga16_fdriver[];

/* These are the currently supported modes */
#define SVGA320x200x16	0	/* 320x200x16 Standard EGA/VGA */
#define SVGA640x200x16	1	/* 640x200x16 Standard EGA/VGA */
#define SVGA640x350x16	2	/* 640x350x16 Standard EGA/VGA */
#define SVGA640x480x16	3	/* 640x480x16 Standard VGA */
#define SVGA800x600x16	4	/* 800x600x16 SuperVGA/VESA */
#define SVGA1024x768x16	5	/* 1024x768x16 SuperVGA/VESA */
#define SVGA1280x1024x16 6	/* 1280x1024x16 SuperVGA/VESA */

#endif /* __SVGA16_H__ */
