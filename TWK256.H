/************************************************/
/* 						*/
/*        Tweaked 256 BGI driver defines	*/
/*		Copyright (c) 1991		*/
/*	    Jordan Hargraphix Software		*/
/*						*/
/************************************************/

#ifndef __TWK256_H__
#define __TWK256_H__

extern int far _Cdecl Twk256_fdriver[];

/* These are the currently supported modes */
#define	TWK320x400x256		0
#define	TWK320x480x256		1
#define	TWK360x480x256		2
#define	TWK376x564x256		3
#define	TWK400x564x256		4
#define	TWK400x600x256		5
#define	TWK320x240x256		6

#endif /* __TWK256_H__ */
