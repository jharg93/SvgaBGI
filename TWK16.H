/************************************************/
/* 						*/
/*        Tweaked 16 BGI driver defines		*/
/*		Copyright (c) 1991		*/
/*	    Jordan Hargraphix Software		*/
/*						*/
/************************************************/

#ifndef __TWK16_H__
#define __TWK16_H__

extern int far Twk16_fdriver[];

/* These are the currently supported modes */
#define TWK704x528x16	0	/* 704x528x16 Tweaked VGA */
#define TWK720x540x16	1	/* 720x540x16 Tweaked VGA */
#define TWK736x552x16	2	/* 736x552x16 Tweaked VGA */
#define TWK752x564x16	3	/* 752x564x16 Tweaked VGA */
#define TWK784x588x16	4	/* 784x588x16 Tweaked VGA */
#define TWK800x600x16	5	/* 800x600x16 Tweaked VGA */

#endif /* __TWK16_H__ */
