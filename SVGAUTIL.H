/************************************************/
/* 						*/
/*     BGI common defines/utility functions	*/
/*		Copyright (c) 1994		*/
/*	    Jordan Hargraphix Software		*/
/*						*/
/************************************************/
#ifndef __SVGAUTIL_H__
#define __SVGAUTIL_H__

typedef unsigned char DacPalette16[16][3];
typedef unsigned char DacPalette256[256][3];

#define	XNOR_PUT	5
#define NOR_PUT		6
#define NAND_PUT	7
#define TRANS_COPY_PUT	8	/* Doesn't work with 16-color drivers */

#pragma pack(1)
typedef struct __bpp24 {
  unsigned char bVal;
  unsigned char gVal;
  unsigned char rVal;
} __bpp24;

typedef struct __bpp16 {
  unsigned int bVal : 5;
  unsigned int gVal : 6;
  unsigned int rVal : 5;
} __bpp16;

typedef struct __bpp15 {
  unsigned int bVal : 5;
  unsigned int gVal : 5;
  unsigned int rVal : 5;
} __bpp15;

typedef union {
  struct __bpp24 c24;
  struct __bpp16 c16;
  struct __bpp15 c15;
  unsigned long  cval;
} __rColor;
#pragma pack()

#ifdef __cplusplus
extern "C" {
#endif

/* Define enhanced color setting functions */
long RGB(char,char,char);
long RealDrawColor(long);
long RealFillColor(long);
long RealColor(long);

/* Define palette functions */
void getvgapalette16(DacPalette16 *);
void getvgapalette256(DacPalette256 *);

#ifdef __cplusplus
};
#endif

#endif /* __SVGAUTIL_H__ */
