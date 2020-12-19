/************************************************/
/* 						*/
/*          SuperVGA utility routines		*/
/*		Copyright (c) 1991		*/
/*	    Jordan Hargraphix Software		*/
/*						*/
/************************************************/

#include <dos.h>
#include <graphics.h>
#include "svgautil.h"
#include "svga16.h"
#include "svga256.h"
#include "svga32k.h"
#include "svga64k.h"
#include "svgatc.h"
#include "svgas3.h"
#include "twk16.h"
#include "twk256.h"

/************************************************************************/
/*									*/
/* 		    Enhanced color setting functions			*/
/*									*/
/* These functions are used to set the colors for the 32k/64k/TrueColor */
/* modes, as the BGI kernel can only handle 8-bit color values.		*/
/*									*/
/************************************************************************/

/********************************************************/
/* long RGB(char rVal, char gVal, char bVal);   	*/
/*					   		*/
/* Purpose: Returns the color value for a R,G,B triple  */
/*	based on the current graphics mode.		*/
/*							*/
/* Input:						*/
/*	char rVal - Red value   [0..255]		*/
/*	char gVal - Green value [0..255]		*/
/*	char bVal - Blue value  [0..255]		*/
/*							*/
/* Returns:						*/
/* 	long - Color value for this mode.		*/
/*							*/
/********************************************************/
long RGB(char rVal, char gVal, char bVal)
{
    __rColor xColor;

    switch(getmaxcolor()) {
      case 32767: 
	xColor.c15.rVal = (rVal >> 3) & 0x1F;
	xColor.c15.gVal = (gVal >> 3) & 0x1F;
	xColor.c15.bVal = (bVal >> 3) & 0x1F;
	break;
      case 65535: 
	xColor.c16.rVal = (rVal >> 3) & 0x1F;
	xColor.c16.gVal = (gVal >> 2) & 0x1F;
	xColor.c16.bVal = (bVal >> 3) & 0x1F;
	break;
    case 16777:
	xColor.c24.rVal = rVal;
	xColor.c24.gVal = gVal;
	xColor.c24.bVal = bVal;
	break;
    }
    return (xColor.cval);
}

/****************************************************************/
/* long RealDrawColor(long color);			  	*/
/* 							  	*/
/* Purpose: Sets the current drawing color for HC/TC modes.	*/
/*	Used for 'setcolor'					*/
/*								*/
/* Input:							*/
/*	long color - Color value				*/
/*								*/
/* Returns:							*/
/*	long - Color value					*/
/*								*/
/****************************************************************/
long RealDrawColor(long color)
{
    __rColor xColor;

    xColor.cval = color;
    /* Do color set hacks for hicolor/truecolor modes */
    switch(getmaxcolor()) {
      case 32767:
	setrgbpalette(1024,xColor.c15.rVal,xColor.c15.gVal,xColor.c15.bVal);
	break;
      case 65535:
	setrgbpalette(1024,xColor.c16.rVal,xColor.c16.gVal,xColor.c16.bVal);
	break;
      case 16777:
	setrgbpalette(1024,xColor.c24.rVal,xColor.c24.gVal,xColor.c24.bVal);
	break;
    };
    return color;
}

/****************************************************************/
/* long RealFillColor(long color);			  	*/
/* 							  	*/
/* Purpose: Sets the current fill color for HC/TC modes.	*/
/*	Used for 'setfillstyle' and 'setfillpattern'		*/
/*								*/
/* Input:							*/
/*	long color - Color value				*/
/*								*/
/* Returns:							*/
/*	long - Color value					*/
/*								*/
/****************************************************************/
long RealFillColor(long color)
{
    __rColor xColor;

    xColor.cval = color;
    /* Do color set hacks for hicolor/truecolor modes */
    switch(getmaxcolor()) {
      case 32767:
	setrgbpalette(1025,xColor.c15.rVal,xColor.c15.gVal,xColor.c15.bVal);
	break;
      case 65535:
	setrgbpalette(1025,xColor.c16.rVal,xColor.c16.gVal,xColor.c16.bVal);
	break;
      case 16777:
	setrgbpalette(1025,xColor.c24.rVal,xColor.c24.gVal,xColor.c24.bVal);
	break;
    };
    return color;
}

/****************************************************************/
/* long RealColor(long color);			  		*/
/* 							  	*/
/* Purpose: Sets the current color for HC/TC modes.		*/
/*	Used for 'putpixel' and 'floodfill'			*/
/*								*/
/* Input:							*/
/*	long color - Color value				*/
/*								*/
/* Returns:							*/
/*	long - Color value					*/
/*								*/
/****************************************************************/
long RealColor(long color)
{
    __rColor xColor;

    xColor.cval = color;
    /* Do color set hacks for hicolor/truecolor modes */
    switch(getmaxcolor()) {
      case 32767:
	setrgbpalette(1026,xColor.c15.rVal,xColor.c15.gVal,xColor.c15.bVal);
	break;
      case 65535:
	setrgbpalette(1026,xColor.c16.rVal,xColor.c16.gVal,xColor.c16.bVal);
	break;
      case 16777:
	setrgbpalette(1026,xColor.c24.rVal,xColor.c24.gVal,xColor.c24.bVal);
	break;
    };
    return color;
}

/* Getvgapalette16 gets the entire 16 color palette */
/* PalBuf contains RGB values for all 16 colors     */
/* R,G,B values range from 0 to 63	            */
/* Usage: 					    */ 
/*  DacPalette16 dac16;                             */
/*						    */
/*  getvgapalette(&dac16);			    */
void getvgapalette16(DacPalette16 *PalBuf)
{
  struct REGPACK reg;

  reg.r_ax = 0x1017;
  reg.r_bx = 0;
  reg.r_cx = 16;
  reg.r_es = FP_SEG(PalBuf);
  reg.r_dx = FP_OFF(PalBuf);
  intr(0x10,&reg);
}

/* Getvgapalette256 gets the entire 256 color palette */
/* PalBuf contains RGB values for all 256 colors      */
/* R,G,B values range from 0 to 63	              */
/* Usage:					      */
/*  DacPalette256 dac256;			      */
/*						      */
/* getvgapalette256(&dac256);			      */
void getvgapalette256(DacPalette256 *PalBuf)
{
  struct REGPACK reg;

  reg.r_ax = 0x1017;
  reg.r_bx = 0;
  reg.r_cx = 256;
  reg.r_es = FP_SEG(PalBuf);
  reg.r_dx = FP_OFF(PalBuf);
  intr(0x10,&reg);
}

/* Setvgapalette16 sets the entire 16 color palette */
/* PalBuf contains RGB values for all 16 colors     */
/* R,G,B values range from 0 to 63	            */
/* Usage: 					    */ 
/*  DacPalette16 dac16;                             */
/*						    */
/*  setvgapalette(&dac16);			    */
void setvgapalette16(DacPalette16 *PalBuf)
{
  struct REGPACK reg;

  reg.r_ax = 0x1012;
  reg.r_bx = 0;
  reg.r_cx = 16;
  reg.r_es = FP_SEG(PalBuf);
  reg.r_dx = FP_OFF(PalBuf);
  intr(0x10,&reg);
}

/* Setvgapalette256 sets the entire 256 color palette */
/* PalBuf contains RGB values for all 256 colors      */
/* R,G,B values range from 0 to 63	              */
/* Usage:					      */
/*  DacPalette256 dac256;			      */
/*						      */
/* setvgapalette256(&dac256);			      */
void setvgapalette256(DacPalette256 *PalBuf)
{
  struct REGPACK reg;

  reg.r_ax = 0x1012;
  reg.r_bx = 0;
  reg.r_cx = 256;
  reg.r_es = FP_SEG(PalBuf);
  reg.r_dx = FP_OFF(PalBuf);
  intr(0x10,&reg);
}
