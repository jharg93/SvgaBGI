;; HGXMOUSE Enhanced Mouse TSR/Library
;;
;; Version:	$Revision:   1.31  $
;;
;; Copyright (c) 1991-1994, Jordan Hargrave <jordan_hargrave@hotmail.com>
;; All rights reserved
;;
;;  This is Copyrighted software.
;;  Permission is hereby granted to use this source code for
;;  private use only.  It may NOT be distributed without permission
;;  of the author.
;;
;;  If you have any comments about changes or improvements in this code,
;;  please let me know.
;;
;;  Revision history:
;;  -----------------
;;  $Log:   C:/svga/mousesrc/rcs/hgxmouse.asv  $
;;
;;   Rev 1.31   04 Sep 1994 15:16:18   JORDAN
;;Split TSR/LIB code.
;;
;;   Rev 1.30   29 Aug 1994 22:20:48   JORDAN
;;Mods for fixed SetPos in text mode.
;;
;;   Rev 1.29   26 Aug 1994 21:47:30   JORDAN
;;
;;   Rev 1.28   23 Aug 1994  4:05:04   JORDAN
;;New sacmap
;;
;;   Rev 1.27   23 Aug 1994  3:04:38   JORDAN
;;Fixed text mode initialization mode
;;
;;   Rev 1.26   21 Aug 1994  3:39:54   JORDAN
;;Added bitmap cursor support for s256, s32k, s64k, and sTC modes.
;;Need s16, t16 and t256 bitmap cursors.
;;  
;;     Rev 1.24   15 Aug 1994 22:50:34   JORDAN
;;  revised detect & install/uninstall code
;;  
;;     Rev 1.23   15 Aug 1994  2:10:50   JORDAN
;;  Working masks for text, twktext and 16 color modes now.
;;  256, t256, 32k, etc need left rotate fix now
;;  
;;     Rev 1.22   14 Aug 1994 22:56:42   JORDAN
;;  Almost fixed 16 color blitter
;;  
;;     Rev 1.21   13 Aug 1994 13:16:46   JORDAN
;;  increase Y & X res +1
;;  
;;     Rev 1.20   12 Aug 1994 23:16:42   JORDAN
;;  Hot spot start for 16, text, twktext modes
;;  
;;     Rev 1.19   11 Aug 1994  1:14:20   JORDAN
;;  Top mask for text mode.
;;  top & bottom mask for s256, s32k, s64k, stc, t256 modes
;;  
;;     Rev 1.18   10 Aug 1994 21:50:28   JORDAN
;;  Hotspot offset working for s256, sTC, s32k, s64k, t256 modes
;;  Doesn't work for hardware....
;;  (horizontal)
;;  
;;     Rev 1.17   08 Aug 1994  2:19:50   JORDAN
;;  Right edge mask for 16 color and text mode fixed
;;  
;;     Rev 1.16   08 Aug 1994  1:40:04   JORDAN
;;  Fixed right edge mask bug for Quicken
;;  
;;     Rev 1.15   07 Aug 1994 19:43:28   JORDAN
;;  Right edge mask working for text mode cursor
;;  
;;     Rev 1.14   06 Aug 1994 21:29:00   JORDAN
;;  Optimized numVertByte calculation for text mode
;;  
;;     Rev 1.13   06 Aug 1994  1:31:02   JORDAN
;;  
;;     Rev 1.12   05 Aug 1994  3:30:10   JORDAN
;;  Cursor VLimit works for any character height
;;  
;;     Rev 1.11   05 Aug 1994  3:04:16   JORDAN
;;  
;;     Rev 1.10   04 Aug 1994  0:11:40   JORDAN
;;  more working text cursor.. numVert needs fixing
;;  
;;     Rev 1.9   03 Aug 1994 21:36:12   JORDAN
;;  
;;     Rev 1.8   30 Jul 1994 14:11:48   JORDAN
;;  
;;     Rev 1.7   30 Jul 1994 14:01:00   JORDAN
;;  Text mode cursor start (one char)
;;
.186

;;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;;				Begin macros
;;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

;;HGXMOUSE_TSR	EQU	01

DebugBkpt	MACRO
		int 	3
ENDM

;;-----------------------------------------------------------
;; 			Include DOS macros
;;-----------------------------------------------------------
include DOSMACRO.INC
include MACROS.INC
include	hgxmacro.inc

;; Macro for setting card (video modes) type
SetCardType	MACRO	__card
ENDM

;; Macro for setting chip type
SetChipType	MACRO	__chip
		mov	chipType, offset chip_&__chip&
		mov	BankAdr, offset $&__chip&
ENDM

;; Macro for setting paging routine
SetPageType	MACRO	__chip
ENDM

;; Macro for calling old interrupt 33
CallOldIntr33	MACRO	__segname
		pushf
	IFB	<__segname>
		call		dword ptr [OldIntr33]
	ELSE
		call		dword ptr cs:[OldIntr33]
	ENDIF
ENDM

_ByteSwap	MACRO	__val
		dw	(__val SHR 8) OR (__val and 0FFh) SHL 8)
ENDM

_WordSwap	MACRO	__val
		dd	(__val SHR 16) OR ((__val and 0ffffh) SHL 16)
ENDM

;; Test for bank crossing for 24-bit mode
TestXBank	MACRO	__reg, __addr
		local	@noCross
		cmp	__reg, __addr
		jnz	@noCross
		inc	dl
		call	newbank
		dec	dl
@noCross:
ENDM

;; Wait for Display Enable bit to clear
WaitForEnable	MACRO
		push	dx
		local	_waitDE
		mov	dx,03dah
_waitDE:	in	al,dx
		test	al,1
		jnz	_waitDE
		pop	dx
ENDM

;; Wait for Vertical Retrace bit to clear
WaitForRetrace	MACRO
		local	_waitVRz
		local	_waitVRnz
		push	dx
		mov	dx,03dah
_waitVRnz:	in	al,dx
		test	al,8
		jnz	_waitVRnz
_waitVRz:	in	al,dx
		test	al,8
		jz	_waitVRz
		pop	dx
ENDM

WaitDuringRetrace	MACRO
		local	_waitVRz
		local	_waitVRnz
		local	_waitDE
		local	_waitDEz
		push	dx
		mov	dx, 03dah
_waitVRnz:	in	al, dx
		test	al, 8
		jz	_waitVRnz
_waitVRz:	in	al, dx
		test	al, 8
		jnz	_waitVRz
_waitDE:	in	al, dx
		test	al, 1
		jnz	_waitDE
_waitDEz:	in	al, dx
		test	al, 1
		jz	_waitDEz
		pop	dx
ENDM

HgxMessage	struc
  msgLen	dw	?
  msgNum	dw	?
  msgTxt	db	?
HgxMessage	ends

;; Stack structure for PUSHA instruction
PushaStruc	struc
  RealDI	DW	0
  RealSI	DW	0
  RealBP	DW	0
  RealXX	DW	0
  RealBX	DW	0
  RealDX	DW	0
  RealCX	DW	0
  RealAX	DW	0
PushaStruc	ends

;;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;;			Begin resident data
;;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

BeginCode	HgxText

Signature	db	'HGXMOUSE',0
sigSize		EQU	$-Signature

vesa_granlrty	db	1
svga_IOAdr	dw	?
bankadr		dw	?
pageadr		dw	?
curbk		db	?
parad_CursorReg	dw	31h

@psp		dw	?		;; PSP segment

;;-----------------------------------------------------------
;; Mouse support variables
;;-----------------------------------------------------------
	PUBLIC	endresidentcode
	PUBLIC	chiptype
	PUBLIC	@psp
	PUBLIC	MouseFlags
	PUBLIC	OldIntr33
	PUBLIC	NewIntr33
	PUBLIC	whichvga

MouseFlags	db	0		;; Mouse flags
mbank		db	?		;; Current mouse bank
MPageOfs	dd	?
OldMPageOfs	dd	?

cursorFGColor	dd	0fh		;; Cursor foreground color
cursorBGColor	dd	00h		;; Cursor background color
cursorBytes	dw	2		;; Cursor width in bytes
cursorWidth	dw	16		;; Cursor width in pixels
cursorHeight	dw	16		;; Height of cursor in pixels
cursorSize	dw	64		;; # of bytes in cursor
cursorStyle	db	0		;; Standard or bitmap cursor

curr_mode	db	?
bytes_per_pix	dw	1
init_mode	db	6
save_mode	db	?

is32x32		db	?		;; HW cursor is 32x32
is64x64		db	?		;; HW cursor is 64x64

;; Resolution of the screen in pixels
MsXres		dw	?
MsYres		dw	?
BytesPerLine	dw	?

;; Pointers to the character bitmap
MsTmpBase	dw	?
MsCursorBase	dw	?

;; Screen offset
VidMem		dw	0A000h
TextMem		dw	0B800h
VisCount	db	-1

;; Hot spot drawing variables
MsHotX		dw	8
MsHotY		dw	8
xHotOffset	dw	0
yHotOffset	dw	0

;; Miscellaneous vertical/horizontal counters used
;; in drawing the cursor
numHorizBytes	dw	?
numVertBytes	dw	?
MsCount		dw	?
MsByteCount	dw	?
MsXCount	dw	?
MsYCount	dw	?

MsNextRow	dw	0
MsPage		dw	0

;; Current drawing position
lastMx		dw	?
lastMy		dw	?
Mx		dw	0
My		dw	0

;; Real mouse position
realMx		dw	?
realMy		dw	?

TwkRead		db	?
TwkWrite	db	?
RotateCount	db	?
fontHeight	dw	16

;; Check limits
limitLX		dw	?
limitRX		dw	?
limitLY		dw	?
limitRY		dw	?

;; Check exclusion area
ExcludeLX	dw	?
ExcludeRX	dw	?
ExcludeLY	dw	?
ExcludeRY	dw	?

;; Cursor color/function table
modeInfo	struc
  hwcursor	dw	?		;; Chipset type
  modetype	dw	?		;; Mode type
  putfunc	dw	?		;; Put cursor function
  resfunc	dw	?		;; Restore background function
  clrfunc	dw	?		;; Set cursor color function
  bitsfunc	dw	?		;; Set cursor bitmap function
  onofffunc	dw	?		;; Turn cursor on/off function
  initfunc	dw	?		;; Initialization function
  fgcolor	dd	?		;; Cursor default foreground color
  bgcolor	dd	?		;; Cursor default background color
modeInfo	ends

CHIP_ANY	EQU	offset $null
MODE_ANY	EQU	0ffffh
MODE_P8		EQU	0
MODE_P15	EQU	1
MODE_P16	EQU	2
MODE_P24	EQU	3
MODE_PL4	EQU	4
MODE_PL8	EQU	5
MODE_TEXT	EQU	6
MODE_TWKTEXT	EQU	7

;; Bytes per pixel for each mode type
modeBPP		db	1, 2, 2, 3, 0, 1, 0, 0

;;=====================================================================
;; Cursor table list
;;  Each entry in this list denotes a particular video mode type.
;;  Hardware & card specific cursor modes appear first, then the
;;  generic card modes.
;;=====================================================================

CursorTable:
if 0
;; Hardware cursors
 if 0
;; hmm.. cirrus 320x200x256 hardware cursor does STRANGE things..
modeInfo<$cirrus54, MODE_P8, $cir54_setPos, @nullProc, \
	 $cir54_setClr, $cir54_setBits, $cir54_onoff, @nullProc, \
	 0ffffffh, 0h>
 endif
;; Cirrus 32k color
modeInfo<$cirrus54, MODE_P15, $cir54_setPos, @nullProc, \
	 $cir54_setClr, $cir54_setBits, $cir54_onoff, @nullProc, \
	 0ffffffh, 0h>
;; Cirrus 64k color
modeInfo<$cirrus54, MODE_P16, $cir54_setPos, @nullProc, \
	 $cir54_setClr, $cir54_setBits, $cir54_onoff, @nullProc, \
	 0ffffffh, 0h>
 if 0
;; Cirrus 24 bit cursor is goofy as well
modeInfo<$cirrus54, MODE_P24, $cir54_setPos, @nullProc, \
	 $cir54_setClr, $cir542_setBits, $cir54_onoff, @nullProc, \
	 0ffffffh, 0h>
 endif
;; S3 256 color
modeInfo<$s3, MODE_P8, $s3_setPos, @nullProc, \
	 $s3_setClr, $s3_setBits, $s3_onoff, @nullProc, \
	 0000000fh, 0000000h>
;; S3 32k color
modeInfo<$s3, MODE_P15, $s3_setPos, @nullProc, \
	 $s3_setClr, $s3_setBits, $s3_onoff, @nullProc, \
	 00ffffffh, 0000000h>
;; Paradise 256 color (need colorinfo)
modeInfo<$paradise, MODE_P8, $parad_setPos, @nullProc, \
	 @nullProc, $parad_setBits, $parad_onoff, @nullProc, \
	 0ffffffh, 0h>
endif

;; Normal cursors
;; Svga 16 color
modeInfo<CHIP_ANY,  MODE_PL4, putCursor_s16,  resCursor_s16, \
	@nullProc, crsr16_setBits, @nullProc, @nullProc, 0fh, 0h>
;; Svga 256 color
modeInfo<CHIP_ANY,  MODE_P8,  putCursor_s256, resCursor_s256, \
	@nullProc, @nullProc, @nullProc, @nullProc, 0fh, 0h>
;; Svga 32k color
modeInfo<CHIP_ANY,  MODE_P15, putCursor_s32k, resCursor_s32k, \
	@nullProc, @nullProc, @nullProc, @nullProc, 07fffh, 0h>
;; Svga 64k color
modeInfo<CHIP_ANY,  MODE_P16, putCursor_s32k, resCursor_s32k, \
	@nullProc, @nullProc, @nullProc, @nullProc, 0ffffh, 0h>
;; Svga 24 bit color
modeInfo<CHIP_ANY,  MODE_P24, putCursor_sTC,  resCursor_sTC, \
	@nullProc, @nullProc, @nullProc, @nullProc, 0ffffffh, 0h>
;; Tweaked 256 color
modeInfo<CHIP_ANY,  MODE_PL8, putCursor_t256, resCursor_t256, \
	@nullProc, @nullProc, @nullProc, @nullProc, 0fh, 0h>
;; Tweaked text
modeInfo<CHIP_ANY, MODE_TWKTEXT, putCursor_tText, resCursor_tText, \
	@nullProc, crsr16_setBits, @nullProc, @nullProc, 0fh, 0h>
;; Regular text mode
modeInfo<CHIP_ANY, MODE_TEXT, putCursor_Text, resCursor_Text, \
	@nullProc, crsr16_setBits, @nullProc, cursorText_init, 0fh, 0h>
;; End of mode chain
	dw	-1

;; Function jump table
PutCursorFunc		dw	?
ResCursorFunc		dw	?
SetCursorClrFunc	dw	?
SetCursorBitsFunc	dw	?
CursorOnOffFunc		dw	?
SetupFunc		dw	?

OldIntr33	dd	?		;; Previous int 0x33 handler
ChainedIntr33	dd	?		;; Chained handler address
ChainedMask	dw	?		;; Mask for chained handler

;; Default 16x16 mouse pointer
if 0
DefMousePtr:	dw not 0180h
		dw not 03c0h
		dw not 03c0h
		dw not 03c0h
		dw not 07e0h
		dw not 0ff0h
		dw not 07ffeh
		dw not 0fe7fh
		dw not 0fe7fh
		dw not 07ffeh
		dw not 0ff0h
		dw not 07e0h
		dw not 03c0h
		dw not 03c0h
		dw not 03c0h
		dw not 0180h
PtrSize		EQU	$-DefMousePtr
		dw 	0h
		dw 	0180h
		dw 	0180h
		dw 	0180h
		dw 	03c0h
		dw 	03c0h
		dw 	0e70h
		dw 	07c3eh
		dw 	07c3eh
		dw 	0e70h
		dw 	03c0h
		dw 	03c0h
		dw 	0180h
		dw 	0180h
		dw 	0180h
		dw	0h
else
DefMousePtr	dw	0011111111111111b	;; AND mask
		dw	0001111111111111b
		dw	0000111111111111b
		dw	0000011111111111b
		dw	0000001111111111b
		dw	0000000111111111b
		dw	0000000011111111b
		dw	0000000001111111b
		dw	0000000000111111b
		dw	0000000000011111b
		dw	0000000000001111b
		dw	0000000011111111b
		dw	0001000011111111b
		dw	0111100001111111b
		dw	1111100001111111b
		dw	1111110001111111b
PtrSize		EQU	$-DefMousePtr
		dw	0000000000000000b	;; XOR mask
		dw	0100000000000000b
		dw	0110000000000000b
		dw	0111000000000000b
		dw	0111100000000000b
		dw	0111110000000000b
		dw	0111111000000000b
		dw	0111111100000000b
		dw	0111111110000000b
		dw	0111111111000000b
		dw	0111111000000000b
		dw	0100011000000000b
		dw	0000011000000000b
		dw	0000001100000000b
		dw	0000001100000000b
		dw	0000000000000000b
endif

if 0
;; Large (32x16) mouse cursor
.386
DefMousePtrBig:	_WordSwap	00001111111111111111111111111111b	;; Default big mouse pointer
		_WordSwap	00000011111111111111111111111111b	;; AND mask
		_WordSwap	00000000111111111111111111111111b
		_WordSwap	00000000001111111111111111111111b
		_WordSwap	00000000000011111111111111111111b
		_WordSwap	00000000000000111111111111111111b
		_WordSwap	00000000000000001111111111111111b
		_WordSwap	00000000000000000011111111111111b
		_WordSwap	00000000000000000000111111111111b
		_WordSwap	00000000000000000000001111111111b
		_WordSwap	00000000000000000000000011111111b
		_WordSwap	00000000000000001111111111111111b
		_WordSwap	00000011000000001111111111111111b
		_WordSwap	00111111110000000011111111111111b
		_WordSwap	11111111110000000011111111111111b
		_WordSwap	11111111111100000011111111111111b
BigPtrSize	EQU	$-DefMousePtrBig
		_WordSwap	00000000000000000000000000000000b	;; XOR mask
		_WordSwap	00110000000000000000000000000000b
		_WordSwap	00111100000000000000000000000000b
		_WordSwap	00111111000000000000000000000000b
		_WordSwap	00111111110000000000000000000000b
		_WordSwap	00111111111100000000000000000000b
		_WordSwap	00111111111111000000000000000000b
		_WordSwap	00111111111111110000000000000000b
		_WordSwap	00111111111111111100000000000000b
		_WordSwap	00111111111111111111000000000000b
		_WordSwap	00111111111111000000000000000000b
		_WordSwap	00110000001111000000000000000000b
		_WordSwap	00000000001111000000000000000000b
		_WordSwap	00000000000011110000000000000000b
		_WordSwap	00000000000011110000000000000000b
		_WordSwap	00000000000000000000000000000000b
endif
.186

;; Sacrifice chars for text mode cursor
SacMap		db	0d7h, 0d8h, 0d0h
		db	0d2h, 0cfh, 0d6h
		db	0d3h, 0c6h, 0c7h

	;; Area of current pointer data (CURSORMAX x CURSORMAX)
transColor	dd	-1

;; CurrMousePtr and TmpMousePtr should get moved into video memory??
CurrMouseSeg	dw	?
CurrMousePtr	label	byte
		dw	CURSORMAX*CURSORMAX*4 dup(?)

	;; Save area for background (32x32)
xvals		label	byte
TmpMousePtr	label	byte
		dw	CURSORMAX*CURSORMAX*4 dup(?)
PlotMask	db	(2+(CURSORMAX SHR 3)) dup(?)

;; Normal mouse functions
MouseFuncs	dw	MsReset,MsShowCursor,MsHideCursor,MsGetPos ;; 00-03
		dw	MsSetPos,MsGetButton,MsGetButton,MsSetHLim ;; 04-07
		dw	MsSetVLim,MsSetGraphPtr,MsOld,MsOld	   ;; 08-0B
		dw	MsSetHandler,MsOld, MsOld,MsOld		   ;; 0C-0F
		dw	MsSetExclude,MsOld,MsSetLargePtr,MsOld	   ;; 10-13
		dw	MsOld,MsOld,MsOld,MsOld			   ;; 14-17
		dw	MsOld,MsOld,MsOld,MsOld			   ;; 18-1B
		dw	MsOld,MsSetPage,MsGetPage,MsOld		   ;; 1C-1F
		dw	MsOld,MsReset,MsOld,MsOld		   ;; 20-23
		dw	MsOld					   ;; 24
MouseFuncSize	EQU	($-MouseFuncs) / 2

;; Extended driver functions
ExtMouseFuncs	dw	HgxInit, HgxDeinit, @nullProc, HgxBank	;; 00-03
		dw	HgxCursorFG, HgxCursorBG, HgxVersion	;; 04-07
		dw	HgxSetSacmap, HgxBmpCursor		;; 07-08
ExtFuncSize	EQU	($-ExtMouseFuncs) / 2

;;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;;			Begin resident code
;;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

;; Include SVGA detection & bankswitch code
include svgabank.inc

;; Generic NOP procedure
@nullProc	proc		near
		ret
@nullProc	endp

;; Input: DI = X coordinate
;;	  AX = Y coordinate
;; Returns
;;	DX, CX = realMx
;;	AX = realMy
calcCursorHot	proc		near
		mov		[lastMx], di
		mov		[lastMy], ax

	;;------------------------------------------------------------
	;; Calculate horizontal hot offset and width
		xor		bx, bx

	;; xHotOffset = ((realMx = dx = (Mx-MsHotX)) < 0) ? realMx=0,-dx : 0;
		sub		di, [MsHotX]
		jge		@hot_xmin
		neg		di
		mov		bx, di
		xor		di, di
@hot_xmin:	mov		[xHotOffset], bx
		mov		bx, [cursorWidth]
		mov		cx, di			;; New X
		mov		dx, di
		add		dx, bx
		cmp		dx, [MsXRes]
		jl		@hot_xmax
		mov		dx, [MsXRes]
@hot_xmax:	sub		dx, di
		cmp		dx, bx
		jle		@hotx
	;; XCount = min(MsXRes - realMx, cursorWidth-1);
		lea		dx, [bx-1]
@hotx:		sub		dx, [xHotOffset]
		dec		dx
		mov		[MsXCount], dx
		shr		dx, 3
		inc		dx
		mov		[MsCount], dx

	;;------------------------------------------------------------
	;; Calculate vertical hotspot and height
		xor		bx, bx

	;; yHotOffset = ((realMy = dy = (My-MsHotY)) < 0) ? realMy=0,-dy : 0;
		sub		ax, [MsHotY]
		jge		@hot_ymin
		neg		ax
		mov		bx, ax
		xor		ax, ax
@hot_ymin:	mov		[yHotOffset], bx
		mov		bx, [cursorHeight]
		mov		dx, ax			;; New Y
		mov		di, ax
		add		di, bx
		cmp		di, [MsYRes]
		jl		@hot_ymax
		mov		di, [MsYRes]
@hot_ymax:	sub		di, ax
		cmp		di, bx
		jle		@hoty
		lea		di, [bx-1]
@hoty:		sub		di, [yHotOffset]
		dec		di
		mov		[MsYCount], di

	;;------------------------------------------------------------
	;; Set current save and bitmap offset
		lea		si, TmpMousePtr
		xor		bp, bp

	;;------------------------------------------------------------
	;; Calculate start line in bitmap
		push		dx
		mov		ax, [yHotOffset]
		mul		[cursorBytes]
		add		bp, ax
		mov		[MsCursorBase], bp
		pop		dx

		mov		di, cx		;; Restore X
		mov		ax, dx		;; Restore Y
		mov		[realMx], cx
		mov		[realMy], dx

		mov		es, [VidMem]
		ret
calcCursorHot	endp

;; Calculates number of horizontal bytes needed
calcHorizBytes	proc		near
	;;------------------------------------------------------------
	;; Calculate rotate count & right edge mask
		and		cx, 7
		mov		ch, 8
		sub		ch, cl
		mov		[RotateCount], ch

	;;------------------------------------------------------------
	;; Calculate number of horizontal bytes needed
	;; If current X isn't on a mod 8 boundary, then one extra byte
	;; is necessary
		mov		ax, [realMx]
		add		ax, [cursorWidth]
		cmp		ax, [MsXres]
		mov		ax, [MsCount]
		jge		@calc_numHB
		and		cl, 7
		jz		@calc_numHB
		inc		ax
@calc_numHB:	mov		[numHorizBytes], ax
		ret
calcHorizBytes	endp

;;=======================================================================
;; Get current AND, XOR masks & calculate # of pixels per word to plot
;; Output:
;;    BX = 16 bits of AND mask
;;    CX = 16 bits of XOR mask
;;    DH = # of bits of mask to plot
;;    [MsByteCount] = # of bits left to plot
;;
;; Used for 256, 32k, 64k and TrueColor modes
;;
;;=======================================================================
calcCursorWord	proc		near
		push		bp
		push		si
		push		di

		add		bp, [MsCursorBase]
		mov		cx, [xHotOffset]
@bltPacked_hot:	cmp		cx, 16
		jle		@bltPacked_not
		sub		cx, 16
		add		bp, 2
		jmp		short @bltPacked_hot

@bltPacked_not:	mov		bx,word ptr cs:[CurrMousePtr+bp]  	;; AND mask
		mov		si,word ptr cs:[CurrMousePtr+bp+2]

		add		bp, [cursorSize]
		mov		ax,word ptr cs:[CurrMousePtr+bp]		;; XOR mask
		mov		di,word ptr cs:[CurrMousePtr+bp+2]
		shl		bx, cl
		shl		ax, cl

	;; Evil mask shifting code
		mov		ch, 16
		sub		ch, cl
		mov		cl, ch
		shr		si, cl
		or		bx, si
		shr		di, cl
		or		ax, di
		mov		cx, ax

		pop		di
		pop		si
		pop		bp
		mov		dh, byte ptr [MsByteCount]
		sub		byte ptr [MsByteCount], 16
		cmp		dh, 15
		jle		@partialWord
		mov		dh, 15
@partialWord:	ret
calcCursorWord	endp

;;=======================================================================
;; Calculates entire shifted scanline of cursor bitmap
;; Input :
;;  AL = 0x00 or 0xFF mask for TwkWrite
;;
;; Output:
;;  SI                = Start offset in PlotMask
;;  PlotMask[0]...[n] = plotmask bytes
;;
;; Used for 16, text and tweaked text modes
;;
;;=======================================================================
calcPlotMask	proc		near
		push		dx
		push		di

	;;------------------------------------------------------------
	;; Setup edge mask
		mov		byte ptr [TwkWrite], al

	;;------------------------------------------------------------
	;; Calculate plot mask
		xor		si, si
		xor		ch, ch
		mov		cl, [RotateCount]
		add		cx, [xHotOffset]
@bltPlanar_hot:	cmp		cx, 8
		jle		@bltPlanar_not
		sub		cx, 8
	;; Increase plot start offset
		inc		si
		jmp		short @bltPlanar_hot
@bltPlanar_not:

	;; Create looper
		xor		bx, bx
		xor		di, di

	;;------------------------------------------------------------
	;; Loop for width of cursor
		mov		dx, [cursorBytes]
		add		bp, [MsCursorBase]
		mov		ah, [TwkWrite]
@blt16_zr:	shl		bx, 8
		mov		al, byte ptr cs:[CurrMousePtr+bp]

	;; Add byte to plotmask
		shl		ax, cl
		or		bx, ax
		mov		PlotMask[di], bh
		xor		ah, ah

		inc		di
		inc		bp
		dec		dx
		jnz		@blt16_zr

	;;------------------------------------------------------------
	;; Mask for last byte
		and		cl, 7
		xchg		ch, cl
		mov		cl, 8
		sub		cl, ch
	;; TwkWrite = 0x00 or 0xFF
		mov		ch, [TwkWrite]
		shr		ch, cl
	;; Mask last byte with TwkWrite shift
		or		bl, ch
		mov		PlotMask[di], bl

		pop		di
		pop		dx
		ret
calcPlotMask	endp

;;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;;
;;			Mouse cursor drawing functions
;;
;;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

;;***********************************************************************
;;
;; 			Svga TC mouse routines
;;
;;***********************************************************************
;;=======================================================================
;; Replace background
;;=======================================================================
ResCursor_sTC	proc		near
		push		es

	;; Save current bank from BGI driver
		mov		al, [curbk]
		mov		[mbank],al

	;; Calculate address of cursor
		mov		di, [lastMx]
		mov		ax, [lastMy]

	;;------------------------------------------------------------
	;; Calculate displayable rows/cols
		call		calcCursorHot

	;; offset = (y*bytesperline) + (x*3);
		mul		[BytesPerLine]
		mov		bp, di
		shl		di,1
		add		di,bp
		add		di,ax
		adc		dx,0
		add		di, word ptr [MPageOfs]
		adc		dx, word ptr [MPageOfs+2]

		cli
	;;-------------------------
	;; Y coordinate loop
@resTC_VLoop:	mov		bp, [MsXCount]
		push		di
		push		dx

	;;-------------------------
	;; X coordinate loop
@resTC_HLoop:	cmp		dl, [curbk]
		jnz		ResChgTC
@resTC_bank:	cmp		di, 0fffeh
		ja		@res_bk0
		movsw
		movsb
		jmp		short @res_bkend
@res_bk0:	cmp		di, 0ffffh
		jz		@res_bk1
		movsw
		inc		dl
		call		newbank
		movsb
		jmp		short @res_bkend
@res_bk1:	movsb
		inc		dl
		call		newbank
		movsw
@res_bkend:	dec		bp
		jns		@resTC_HLoop

		pop		dx
		pop		di
		add		di, [BytesPerLine]
		adc		dl, 0

	;;-------------------------
	;; Decrease y counter
		dec		[MsYCount]
		jns		@resTC_VLoop
		sti

	;; Restore bank for BGI driver
		mov		dl, [mbank]
		call		newbank
		pop		es
		ret
ResChgTC:	call		newbank
		jmp		short @resTC_bank
ResCursor_sTC	endp

;;=======================================================================
;; Draw mouse cursor
;;=======================================================================
PutChgTC:	call		newbank
		jmp		short @putTC_bank

PutCursor_sTC	proc		near
		push		es

	;;------------------------------------------------------------
	;; Save bank # for BGI driver
		mov		al, [curbk]
		mov		[mbank],al

		mov		di, [Mx]
		mov		ax, [My]

	;;------------------------------------------------------------
	;; Calculate displayable rows/cols
		call		calcCursorHot

	;;------------------------------------------------------------
	;; Calculate address
		mul		[BytesPerLine]
		mov		cx, di
		shl		di,1
		add		di,cx
		add		di,ax
		adc		dx,0
		add		di,word ptr [MPageOfs]
		adc		dx,word ptr [MPageOfs+2]

	;;------------------------------------------------------------
	;; Check cursor type
		cmp		[cursorStyle], STANDARD_CURSOR
		jz		@putTC_Start
		call		BmpCursor_sTC
		jmp		@putTC_End

@putTC_Start:	cli
	;;------------------------------------------------------------
	;; Y coordinate loop
@putTC_VLoop:	xor		bp,bp
		push		di
		push		dx
		mov		ax, [MsXCount]
		mov		[MsByteCount], ax

	;;------------------------------------------------------------
	;; Cursor word loop
@putTC_WLoop:	call		calcCursorWord

	;;------------------------------------------------------------
	;; Cursor bit loop
@putTC_HLoop:	cmp		dl, [curbk]
		jnz		PutChgTC

	;;------------------------------------------------------------
	;; Save background
@putTC_bank:	mov		al, es:[di]
		mov		[si], al
	;;------------------------------------------------------------
	;; Do AND/XOR
		test		bx,08000h
		jnz		@putTC_noAND_B
		xor		al,al
@putTC_noAND_B:	test		cx,08000h
		jz		@putTC_noXOR_B
		xor		al, byte ptr [cursorFGColor]
	;;------------------------------------------------------------
	;; Write pixel
@putTC_noXOR_B:	mov		es:[di], al
		TestXBank	di, 0ffffh
		mov		al, es:[di+1]
		mov		[si+1], al
	;;------------------------------------------------------------
	;; Do AND/XOR
		test		bx,08000h
		jnz		@putTC_noAND_G
		xor		al,al
@putTC_noAND_G:	test		cx,08000h
		jz		@putTC_noXOR_G
		xor		al, byte ptr [cursorFGColor+1]
	;;------------------------------------------------------------
	;; Write pixel
@putTC_noXOR_G:	mov		es:[di+1], al
		TestXBank	di, 0fffeh
		mov		al, es:[di+2]
		mov		[si+2], al
	;;------------------------------------------------------------
	;; Do AND/XOR
		shl		bx, 1
		jc		@putTC_noAND_R
		xor		al,al
@putTC_noAND_R:	shl		cx,1
		jnc		@putTC_noXOR_R
		xor		al, byte ptr [cursorFGColor+2]
	;;------------------------------------------------------------
	;; Write pixel
@putTC_noXOR_R:	mov		es:[di+2], al
		add		si, 3
		add		di, 3
		adc		dl,0

	;;------------------------------------------------------------
	;; Decrease cursor bit counter
		dec		dh
		js		@putTC_endHlp
		jmp		@putTC_HLoop

	;;------------------------------------------------------------
	;; Decrease cursor word counter
@putTC_endHlp:	add		bp,2
		cmp		bp, [MsCount]
		jge		@putTC_endWLp
		jmp		@putTC_WLoop

@putTC_endWLp:	mov		bp, [cursorBytes]
		add		[MsCursorBase], bp
		pop		dx
		pop		di
		add		di, [BytesPerLine]
		adc		dl, 0

	;;------------------------------------------------------------
	;; Decrease y counter
		dec		[MsYCount]
		js		@putTC_endVLp
		jmp		@putTC_VLoop

@putTC_endVLp:	sti

	;;------------------------------------------------------------
	;; Restore bank for BGI driver
@putTC_end:	mov		dl, [mbank]
		call		newbank
		pop		es
		ret
PutCursor_sTC	endp

;;=======================================================================
;; Draw bitmap mouse cursor
;;=======================================================================
plotTC_byte	proc		near
		mov		ah, byte ptr cs:[CurrMousePtr+bp]
		xor		bh, bh
		cmp		ah, byte ptr [transColor]
		jnz		@TCnotClearR
		inc		bh
@TCNotClearR:	mov		al, es:[di]
		mov		[si], al
		test		bh, bh
		jnz		@bmpTc_noR
		mov		es:[di], ah
@bmpTc_noR:	TestXBank	di, 0ffffh
		mov		al, es:[di+1]
		mov		[si+1], al
		test		bh, bh
		jnz		@bmpTC_noG
		mov		es:[di+1], ah
@bmpTc_noG:	TestXBank	di, 0fffeh
		mov		al, es:[di+2]
		mov		[si+2], al
		test		bh, bh
		jnz		@bmpTC_noB
		mov		es:[di+2], bl
@bmpTC_noB:	ret
plotTC_byte	endp

BmpCursor_sTC	proc		near
		cli
	;;------------------------------------------------------------
	;; Y coordinate loop
		push		dx

		mov		ax, [yHotOffset]
		shl		ax, 2
		mul		[cursorWidth]

		mov		dx, [xHotOffset]
		shl		dx, 2
		add		ax, dx
		mov		bp, ax
		pop		dx

		mov		cx, [MsYCount]
		inc		cx
@BmpTC_VLoop:	push		cx
		mov		cx, [MsXCount]
		inc		cx

		push		di
		push		dx
		push		bp
	;;------------------------------------------------------------
	;; X coordinate loop
@BmpTC_HLoop:	cmp		dl, [curbk]
		jnz		BmpChgTC

	;;------------------------------------------------------------
	;; Save background
@BmpTC_bank:	call		plotTC_byte
		add		bp, 4
		add		si,3
		add		di,3
		adc		dl, 0
		loop		@bmpTC_HLoop

	;; Increase bitmap pointer
		pop		bp
		mov		ax, [cursorWidth]
		shl		ax, 2
		add		bp, ax

	;; Increase video offset
		pop		dx
		pop		di
		add		di, [BytesPerLine]
		adc		dx, 0
		pop		cx
		loop		@BmpTC_Vloop
		sti
		ret

BmpChgTC:	call	newbank
		jmp	short @BmpTC_bank
BmpCursor_sTC	endp

;;***********************************************************************
;;
;; 			Svga 32k/64k mouse routines
;;
;;***********************************************************************
calcAddr32k:	shl		di, 1
calcAddr256:	mul		[BytesPerLine]
		add		di, ax
		adc		dx, 0
		add		di, word ptr [MPageOfs]
		adc		dx, word ptr [MPageOfs+2]
		ret

;;=======================================================================
;; Replace background
;;=======================================================================
ResCursor_s32k	proc		near
		push		es

	;;------------------------------------------------------------
	;; Save current bank from BGI driver
		mov		al, [curbk]
		mov		[mbank],al

		mov		di, [lastMx]
		mov		ax, [lastMy]

	;;------------------------------------------------------------
	;; Calculate displayable rows/cols
		call		calcCursorHot

	;;------------------------------------------------------------
	;; Calculate address of cursor
		call		calcAddr32k

		mov		ax, [MsXCount]
		inc		ax
		shl		ax, 1
		neg		ax
		add		ax, [BytesPerLine]
		mov		[MsNextRow], ax

		cli
	;;------------------------------------------------------------
	;; Y coordinate loop
@res32k_VLoop:	mov		bp, [MsXCount]

	;;------------------------------------------------------------
	;; X coordinate loop
@res32k_HLoop:	cmp		dl, [curbk]
		jnz		ResChg32k
@res32k_bank:	lodsw
		mov		es:[di], ax
		add		di, 2
		adc		dl, 0

	;;------------------------------------------------------------
	;; Decrease x counter
		dec		bp
		jns		@res32k_HLoop

		add		di, [MsNextRow]
		adc		dl, 0

	;;------------------------------------------------------------
	;; Decrease y counter
		dec		[MsYCount]
		jns		@res32k_VLoop
		sti

	;;------------------------------------------------------------
	;; Restore bank for BGI driver
		mov		dl, [mbank]
		call		newbank
		pop		es
		ret
ResChg32k:	call		newbank
		jmp		short @res32k_bank
ResCursor_s32k	endp

;;=======================================================================
;; Draw mouse cursor
;;=======================================================================
PutCursor_s32k	proc		near
		push		es

	;;------------------------------------------------------------
	;; Save bank # for BGI driver
		mov		al, [curbk]
		mov		[mbank],al

		mov		di, [Mx]
		mov		ax, [My]

	;;------------------------------------------------------------
	;; Calculate displayable rows/cols
		call		calcCursorHot

	;;------------------------------------------------------------
	;; Calculate address of cursor
		call		calcAddr32k

		mov		ax, [MsXCount]
		inc		ax
		shl		ax, 1
		neg		ax
		add		ax, [BytesPerLine]
		mov		[MsNextRow], ax

	;;------------------------------------------------------------
	;; Check cursor type
		cmp		[cursorStyle], STANDARD_CURSOR
		jz		@put32k_Start
		call		BmpCursor_s32k
		jmp		@put32k_End

@put32k_start:	cli
	;;------------------------------------------------------------
	;; Y coordinate loop
@put32k_VLoop:	xor		bp,bp
		mov		ax, [MsXCount]
		mov		[MsByteCount], ax

	;;------------------------------------------------------------
	;; Cursor word loop
@put32k_WLoop:	call		calcCursorWord

	;;------------------------------------------------------------
	;; Cursor bit loop
@put32k_HLoop:	cmp		dl, [curbk]
		jnz		PutChg32k

	;;------------------------------------------------------------
	;; Save background
@put32k_bank:	mov		ax, es:[di]
		mov		[si], ax
	;;------------------------------------------------------------
	;; Do AND/XOR
		shl		bx, 1
		jc		@put32k_noAND
		xor		ax,ax
@put32k_noAND:	shl		cx,1
		jnc		@put32k_noXOR
		xor		ax, word ptr [cursorFGColor]
	;;------------------------------------------------------------
	;; Write pixel
@put32k_noXOR:	mov		es:[di], ax
		add		si, 2
		add		di, 2
		adc		dl,0
	;;------------------------------------------------------------
	;; Decrease cursor bit counter
		dec		dh
		jns		@put32k_HLoop

	;;------------------------------------------------------------
	;; Decrease cursor word counter
		add		bp,2
		cmp		bp, [MsCount]
		jl		@put32k_WLoop

		mov		bp, [cursorBytes]
		add		[MsCursorBase], bp
		add		di, [MsNextRow]
		adc		dl, 0

	;;------------------------------------------------------------
	;; Decrease y counter
		dec		[MsYCount]
		jns		@put32k_VLoop
		sti

	;;------------------------------------------------------------
	;; Restore bank for BGI driver
@put32k_End:	mov		dl, [mbank]
		call		newbank
		pop		es
		ret
PutChg32k:	call		newbank
		jmp		short @put32k_bank
PutCursor_s32k	endp

BmpCursor_s32k	proc		near
		cli
	;;------------------------------------------------------------
	;; Y coordinate loop
		push		dx
		mov		ax, [yHotOffset]
		shl		ax, 1
		mul		[cursorWidth]
		mov		dx, [xHotOffset]
		shl		dx, 1
		add		ax, dx
		mov		bp, ax
		pop		dx

		mov		cx, [MsYCount]
		inc		cx
@Bmp32k_VLoop:	push		cx
		mov		cx, [MsXCount]
		inc		cx

	;; Store transparent color
		mov		bx, word ptr [transColor]
		push		bp
	;;------------------------------------------------------------
	;; X coordinate loop
@Bmp32k_HLoop:	cmp		dl, [curbk]
		jnz		BmpChg32k

	;;------------------------------------------------------------
	;; Save background
@Bmp32k_bank:	mov		ax, es:[di]
		mov		[si], ax

		mov		ax, word ptr cs:[CurrMousePtr+bp]
	;;------------------------------------------------------------
	;; Check for transparent byte
		cmp		ax, bx
		jz		@bmp32kNoPlot
		mov		es:[di], ax
@bmp32kNoPlot:	add		bp, 2
		add		si, 2
		add		di,2
		adc		dl, 0
		loop		@bmp32k_HLoop
		pop		bp
		mov		ax, [cursorWidth]
		shl		ax, 1
		add		bp, ax
		pop		cx

		add		di, [MsNextRow]
		adc		dl, 0
		loop		@Bmp32k_Vloop
		sti
		ret
BmpChg32k:	call	newbank
		jmp	short @Bmp32k_bank
BmpCursor_s32k	endp

;;***********************************************************************
;;
;; 			Svga 256 mouse routines
;;
;;***********************************************************************
;;=======================================================================
;; Replace background
;;=======================================================================
ResCursor_s256	proc		near
		push		es

	;;------------------------------------------------------------
	;; Save current bank from BGI driver
		mov		al, [curbk]
		mov		[mbank],al

		mov		di, [lastMx]
		mov		ax, [lastMy]

	;;------------------------------------------------------------
	;; Calculate displayable rows/cols
		call		calcCursorHot

	;;------------------------------------------------------------
	;; Calculate address of cursor
		call		calcAddr256

	;;------------------------------------------------------------
	;; Calculate offset of next row
		mov		ax, [MsXCount]
		inc		ax
		neg		ax
		add		ax, [BytesPerLine]
		mov		[MsNextRow], ax

		cli
	;;------------------------------------------------------------
	;; Y coordinate loop
@res256_VLoop:	mov		bp, [MsXCount]

	;;------------------------------------------------------------
	;; X coordinate loop
@res256_HLoop:	cmp		dl, [curbk]
		jnz		ResChg256
@res256_bank:	lodsb
		mov		es:[di], al
		add		di, 1
		adc		dl, 0
		dec		bp
		jns		@res256_HLoop

		add		di, [MsNextRow]
		adc		dl, 0

	;;------------------------------------------------------------
	;; Decrease y counter
		dec		[MsYCount]
		jns		@res256_VLoop
		sti

	;;------------------------------------------------------------
	;; Restore bank for BGI driver
		mov		dl, [mbank]
		call		newbank
		pop		es
		ret
ResChg256:	call	newbank
		jmp	short @res256_bank
ResCursor_s256	endp

;;=======================================================================
;; Draw mouse cursor
;;=======================================================================
PutCursor_s256	proc		near
		push		es

	;;------------------------------------------------------------
	;; Save bank # for BGI driver
		mov		al, [curbk]
		mov		[mbank],al

		mov		di, [Mx]
		mov		ax, [My]

	;;------------------------------------------------------------
	;; Calculate displayable rows/cols
		call		calcCursorHot

	;;------------------------------------------------------------
	;; Calculate address
		call		calcAddr256

	;;------------------------------------------------------------
	;; Calculate offset of next row
		mov		ax, [MsXCount]
		inc		ax
		neg		ax
		add		ax, [BytesPerLine]
		mov		[MsNextRow], ax

	;;------------------------------------------------------------
	;; Check cursor type
		cmp		[cursorStyle], STANDARD_CURSOR
		jz		@put256_Start
		call		BmpCursor_s256
		jmp		@put256_End

@put256_Start:	cli
	;;------------------------------------------------------------
	;; Y coordinate loop
@put256_VLoop:	xor		bp,bp
		mov		ax, [MsXCount]
		mov		[MsByteCount], ax

	;;------------------------------------------------------------
	;; Cursor word loop
@put256_WLoop:	call		calcCursorWord

	;;------------------------------------------------------------
	;; Cursor bit loop
@put256_HLoop:	cmp		dl, [curbk]
		jnz		PutChg256

	;;------------------------------------------------------------
	;; Save background
@put256_bank:	mov		al, es:[di]
		mov		[si], al
	;;------------------------------------------------------------
	;; Do AND/XOR
		shl		bx, 1
		jc		@put256_noAND
		xor		al,al
@put256_noAND:	shl		cx,1
		jnc		@put256_noXOR
		xor		al, byte ptr [cursorFGColor]
	;;------------------------------------------------------------
	;; Write pixel
@put256_noXOR:	mov		es:[di], al
		add		si, 1
		add		di, 1
		adc		dl,0

	;;------------------------------------------------------------
	;; Decrease cursor bit counter
		dec		dh
		jns		@put256_HLoop

	;;------------------------------------------------------------
	;; Decrease cursor word counter
		add		bp,2
		cmp		bp, [MsCount]
		jl		@put256_WLoop

		mov		bp, [cursorBytes]
		add		[MsCursorBase], bp
		add		di, [MsNextRow]
		adc		dl, 0

	;;------------------------------------------------------------
	;; Decrease y counter
		dec		[MsYCount]
		jns		@put256_VLoop
		sti

	;;------------------------------------------------------------
	;; Restore bank for BGI driver
@put256_End:	mov		dl, [mbank]
		call		newbank
		pop		es
		ret
PutChg256:	call	newbank
		jmp	short @put256_bank
PutCursor_s256	endp

;;=======================================================================
;; Draw bitmap cursor
;;=======================================================================
BmpCursor_s256	proc		near
		cli
	;;------------------------------------------------------------
	;; Y coordinate loop
		push		dx
		mov		ax, [yHotOffset]
		mul		[cursorWidth]
		add		ax, [xHotOffset]
		mov		bp, ax
		pop		dx

		mov		cx, [MsYCount]
		inc		cx
@Bmp256_VLoop:	push		cx
		mov		cx, [MsXCount]
		inc		cx

	;; Store transparent color
		mov		bl, byte ptr [transColor]
		push		bp
	;;------------------------------------------------------------
	;; X coordinate loop
@Bmp256_HLoop:	cmp		dl, [curbk]
		jnz		BmpChg256

	;;------------------------------------------------------------
	;; Save background
@Bmp256_bank:	mov		al, es:[di]
		mov		[si], al

		mov		al, byte ptr cs:[CurrMousePtr+bp]
	;;------------------------------------------------------------
	;; Check for transparent byte
		cmp		al, bl
		jz		@bmp256NoPlot
		mov		es:[di], al
@bmp256NoPlot:	inc		bp
		inc		si
		add		di,1
		adc		dl, 0
		loop		@bmp256_HLoop
		pop		bp
		add		bp, [cursorWidth]
		pop		cx

		add		di, [MsNextRow]
		adc		dl, 0
		loop		@Bmp256_Vloop
		sti
		ret
BmpChg256:	call	newbank
		jmp	short @Bmp256_bank
BmpCursor_s256	endp

;;***********************************************************************
;;
;; 			Tweak 256 mouse routines
;;
;;***********************************************************************
;;=======================================================================
;; Replace background
;;=======================================================================
ResCursor_t256	proc		near
		push		es
		mov		di, [lastMx]
		mov		ax, [lastMy]

	;;------------------------------------------------------------
	;; Calculate displayable rows/cols
		call		calcCursorHot

	;;------------------------------------------------------------
	;; Calculate address
		shr		di,2
		mul		[BytesPerLine]
		add		di,ax
		add		di, word ptr [MPageOfs]

		and		cl,3
		mov		ch,011h
		rol		ch,cl
		mov		[TwkWrite],ch		;; Write Plane

		cli
	;;------------------------------------------------------------
	;; Y coordinate loop
@resT256_VLoop:	mov		bp, [MsXCount]
		mov		dl, [TwkWrite]
		push		di

	;;------------------------------------------------------------
	;; X coordinate loop
@resT256_HLoop:	call		SetWrite
		movsb
		rol		dl, 1
		adc		di, -1

	;;------------------------------------------------------------
	;; Decrease X counter
		dec		bp
		jns		@resT256_HLoop
		pop		di
		add		di, [BytesPerLine]

	;;------------------------------------------------------------
	;; Decrease Y counter
		dec		[MsYCount]
		jns		@resT256_VLoop
		sti
		pop		es
		ret
ResCursor_t256	endp

SetRead:	mov	al,READ_MAP
		mov	ah,dh
		push	dx
		outpw	GC_INDEX, ax
		pop	dx
		ret

SetWrite:	push	ax
		mov	al,MAP_MASK
		mov	ah,dl
		push	dx
		outpw	SC_INDEX, ax
		pop	dx
		pop	ax
		ret

;;=======================================================================
;; Draw mouse cursor
;;=======================================================================
PutCursor_t256	proc		near
		push		es

		mov		di, [Mx]
		mov		ax, [My]

	;;------------------------------------------------------------
	;; Calculate displayable rows/cols
		call		calcCursorHot

	;;------------------------------------------------------------
	;; Calculate address
		shr		di,2
		mul		[BytesPerLine]
		add		di,ax
		add		di,word ptr [MPageOfs]

		and		cl,3
		mov		[TwkRead],cl	;; Set read plane bitmap
		mov		ch,011h
		rol		ch,cl
		mov		[TwkWrite],ch	;; Set write plane bitmap

	;;------------------------------------------------------------
	;; Check cursor type
		cmp		[cursorStyle], STANDARD_CURSOR
		jz		@putT256_Start
		call		BmpCursor_t256
		jmp		@putT256_End

@putT256_Start:	cli
	;;------------------------------------------------------------
	;; Y coordinate loop
@putT256_VLoop:	mov		dl, [TwkWrite]
		mov		dh, [TwkRead]
		xor		bp, bp
		push		di
		mov		ax, [MsXCount]
		mov		[MsByteCount], ax

	;;------------------------------------------------------------
	;; Cursor word loop
@putT256_WLoop:	push		dx
		call		calcCursorWord
		mov		byte ptr [mbank], dh
		pop		dx

	;;------------------------------------------------------------
	;; Cursor bit loop
@putT256_HLoop:	
	;;------------------------------------------------------------
	;; Save background
		call		SetRead
		mov		al, es:[di]
		mov		[si], al
		inc		si
	;;------------------------------------------------------------
	;; Do AND/XOR
		shl		bx, 1
		jc		@putT256_noAND
		xor		al, al
@putT256_noAND:	shl		cx,1
		jnc		@putT256_noXOR
		xor		al, byte ptr [cursorFGColor]
	;;------------------------------------------------------------
	;; Write pixel
@putT256_noXOR:	call		SetWrite
		stosb

	;;------------------------------------------------------------
	;; Rotate plane bitmaps
		rol		dl, 1		;; Write plane
		adc		di, -1
		inc		dh		;; Read plane
		and		dh, 3

	;;------------------------------------------------------------
	;; Decrease cursor bit counter
		dec		byte ptr [mbank]
		jns		@putT256_HLoop

	;;------------------------------------------------------------
	;; Decrease cursor word counter
		add		bp,2
		cmp		bp, [MsCount]
		jl		@putT256_WLoop

		mov		bp, [cursorBytes]
		add		[MsCursorBase], bp
		pop		di
		add		di, [BytesPerLine]

	;;------------------------------------------------------------
	;; Decrease y counter
		dec		[MsYCount]
		js		PutLoopEnd
		jmp		@putT256_VLoop
PutLoopEnd:	sti
@putT256_End:	pop		es
		ret
PutCursor_t256	endp

;;=======================================================================
;; Draw bitmap mouse cursor
;;=======================================================================
BmpCursor_t256	proc		near
		cli

	;;------------------------------------------------------------
	;; Y coordinate loop
		mov		ax, [yHotOffset]
		mul		[cursorWidth]
		add		ax, [xHotOffset]
		mov		bp, ax

		mov		bl, byte ptr [transColor]
		mov		cx, [MsYCount]
		inc		cx
@BmpT256_VLoop:	mov		dl, [TwkWrite]
		mov		dh, [TwkRead]
		push		di

		push		cx
		mov		cx, [MsXCount]
		inc		cx
		push		bp

	;;------------------------------------------------------------
	;; Cursor X loop
@BmpT256_HLoop:	
	;;------------------------------------------------------------
	;; Save background
		call		SetRead
		mov		al, es:[di]
		mov		[si], al
		inc		si

		call		SetWrite

		mov		al, byte ptr cs:[CurrMousePtr+bp]
	;;------------------------------------------------------------
	;; Write pixel
		cmp		al, bl
		jz		@bmp256_noplot
		mov		es:[di], al
	;;------------------------------------------------------------
	;; Rotate plane bitmaps
@bmp256_noplot:	rol		dl, 1		;; Write plane
		adc		di, 0
		inc		dh		;; Read plane
		and		dh, 3
		inc		bp

	;;------------------------------------------------------------
	;; Decrease cursor bit counter
		loop		@BmpT256_HLoop

	;;------------------------------------------------------------
	;; Decrease cursor word counter
		pop		bp
		add		bp, [cursorWidth]

		pop		cx
		pop		di
		add		di, [BytesPerLine]

	;;------------------------------------------------------------
	;; Decrease y counter
		loop		@BmpT256_VLoop
BmpLoopEnd:	sti
		ret
BmpCursor_t256	endp

;;***********************************************************************
;;
;; 			Standard text
;;
;;***********************************************************************
;; Input:  DX = old value
;; Output: DX = scaled value
;; Convert world resolution to virtual resolution
scaleYPos	proc		near
	;; Make X coordinate start on mod 8 boundary for text mode... (quicken?)
	;;	and		cx, NOT 7
	;; newy = (oldy << 3)/fontHeight;
		push		ax
		mov		ax, dx
		xor		dx, dx
		shl		ax, 3
		div		[fontHeight]
		mov		dx, ax
		pop		ax
		ret
scaleYPos	endp

;; Convert virtual resolution to world resolution
calcYPos	proc		near
	;; newy = (oldy*fontHeight) >> 3;
		push		dx
		mul		[fontHeight]
		shr		ax, 3
		pop		dx
		ret
calcYPos	endp

;; Initialize resolution - Get height of current character set
cursorText_init	proc		near
		push		es
		mov		ax, 040h
		mov		es, ax

	;;------------------------------------------------------------
	;; Get height of character matrix
		xor		ah, ah
		mov		al, es:[0085h]
		mov		[fontHeight], ax

	;;------------------------------------------------------------
	;; Get max Y resolution of mode
		mov		al, es:[0084h]
		inc		ax
		mul		[fontHeight]
		mov		[MsYRes], ax

	;;------------------------------------------------------------
	;; Get bytes per line of mode
		mov		ax, es:[004ah]
		shl		ax, 1
		mov		[BytesPerLine], ax
		shl		ax, 2
		mov		[MsXRes], ax

		pop		es
		ret
cursorText_init	endp

;;=======================================================================
;; Replace background
;;=======================================================================
ResCursor_Text	proc		near
		push		es

		mov		di, [lastMx]
		mov		ax, [lastMy]

	;;------------------------------------------------------------
	;; Calculate displayable rows/cols
		call		calcCursorHot
		mov		es, [TextMem]

	;;------------------------------------------------------------
	;; Calculate address of cursor
	;; offset = (y / fontHeight)*bytesPerLine + ((x >> 3)<<1);
		xor		dx,dx
		div		[fontHeight]
		mov		[MsByteCount], dx
		shr		di, 3
		shl		di, 1
		mul		[BytesPerLine]
		add		di, ax

		call		calcHorizBytes

	;;------------------------------------------------------------
	;; Get starting line of cursor within character block
	;; MsByteCount = (My % fontHeight);
		mov		dx, [MsByteCount]

	;;------------------------------------------------------------
	;; Calculate number of vertical blocks needed based on the 
	;; current character cell height
@rtext_ymin:	xor		cx,cx
		mov		ax, [MsYCount]
@resTxt_calcVB:	inc		cx
		sub		ax, [fontHeight]
		jg		@resTxt_calcVB

		neg		ax
		cmp		dx, ax
		jle		@resTxt_numVB
		inc		cx
@resTxt_numVB:	mov		[numVertBytes], cx

	;;------------------------------------------------------------
	;; Restore saved character
		xor		si, si
		mov		cx, [numVertBytes]
	;; Restore Y loop
		cli
@res_sacYLoop:	push		di
		push		si
		push		cx
		mov		cx, [numHorizBytes]
	;; Restore X loop
@res_sacXLoop:	mov		al, byte ptr cs:TmpMousePtr[si]
		mov		ah, byte ptr cs:SacMap[si]
		cmp		es:[di], ah
		jnz		@noTextRestore
		mov		es:[di], al
@noTextRestore:	inc		si
		add		di,2
		loop		@res_sacXLoop
		pop		cx
		pop		si
		pop		di
		add		di, [BytesPerLine]
		add		si, 3
		loop		@res_sacYLoop
		sti

		pop		es
		ret
ResCursor_Text	endp

;;========================================================================
;; Copy character map from A to B
;;  Input: SI = source character
;;	   DI = destination character
;;========================================================================
copyCharmap	proc		near
	;; Calculate offset of source character (32 bytes/char)
		shl		si, 5
	;; Calculate offset of desination character (32 bytes/char)
		shl		di, 5
	;; Copy character data
		push		ds
		mov		ds, [VidMem]
	;; Character definitions are 32 pixels high
		mov		cx, 16
		repz		movsw
		pop		ds
		ret
copyCharmap	endp

;;=======================================================================
;; Blit a scanline of mask data into font memory
@Txt_AndWrite:	and		es:[di], al
		ret
@Txt_XorWrite:	xor		es:[di], al
		ret
;;=======================================================================
cursorText_Blt	proc		near
		push		cx
		push		si

	;;------------------------------------------------------------
	;; Calculate plot mask
		push		si
		call		calcPlotMask
		mov		bx, si
		pop		si

	;;------------------------------------------------------------
	;; Blit mask to screen
		mov		cx, [numHorizBytes]
@bltTxt_wrLoop:	mov		di, [MsByteCount]

	;;------------------------------------------------------------
	;; Calculate starting offset in font memory
	;; Offset = sacmap[si]*32 (bytes per character)
		xor		ah, ah
		mov		al, cs:SacMap[si]
		shl		ax, 5
		add		di, ax

	;;------------------------------------------------------------
	;; Copy bitmap to font memory
		mov		al, PlotMask[bx]
		call		dx
		inc		bx
		inc		si
		loop		@bltTxt_wrloop

		pop		si
		pop		cx
		ret
cursorText_Blt	endp

;;=======================================================================
;; Draw mouse cursor
;;=======================================================================
PutCursor_Text	proc		near
		push		es

		mov		di, [Mx]
		mov		ax, [My]

	;;------------------------------------------------------------
	;; Calculate displayable rows/cols
		call		calcCursorHot
		mov		es, [TextMem]

	;;------------------------------------------------------------
	;; Calculate text address of cursor
		xor		dx,dx
		div		[fontHeight]
		mov		[MsByteCount], dx
		shr		di, 3
		shl		di, 1
		mul		[BytesPerLine]
		add		di, ax

		call		calcHorizBytes

	;;------------------------------------------------------------
	;; Get starting line of cursor within character block
	;; MsByteCount = (My % fontHeight);
		mov		dx, [MsByteCount]

	;;------------------------------------------------------------
	;; Calculate number of vertical blocks needed based on the 
	;; current character cell height
@ptext_ymin:	xor		cx,cx
		mov		ax, [MsYCount]
@putTxt_calcVB:	inc		cx
		sub		ax, [fontHeight]
		jg		@putTxt_calcVB

		neg		ax
		cmp		dx, ax
		jle		@putTxt_numVB
		inc		cx
@putTxt_numVB:	mov		[numVertBytes], cx

	;;------------------------------------------------------------
	;; numHorizBytes contains the number of horizontal character
	;; blocks the cursor takes up.
	;; 2 or 3 blocks for 8x8, 8x14 and 8x16 characters
	;;
	;; numVertBytes contains the number of vertical character
	;; blocks the cursor takes up.
	;; (8x16 = 1 or 2 for a 16x16 cursor)
	;; (8x14 = 1 or 2 for a 16x16 cursor)
	;; (8x8  = 2 or 3 for a 16x16 cursor)

	;;------------------------------------------------------------
	;; Save characters under the cursor
		cli
		xor		si, si
		mov		cx, [numVertBytes]
@put_sacYLoop:	push		di
		push		si
		push		cx
		mov		cx, [numHorizBytes]
@put_sacXLoop:	mov		al, cs:SacMap[si]
		xchg		es:[di], al
		mov		byte ptr cs:TmpMousePtr[si], al
		inc		si
		add		di,2
		loop		@put_sacXLoop
		pop		cx
		pop		si
		pop		di
		add		di, [BytesPerLine]
		add		si, 3
		loop		@put_sacYLoop

	;;------------------------------------------------------------
	;; Enable plane 2 (character definitions)
		outpw		03c4h, 0100h
		outpw		dx     0402h	;
		outpw		dx,    0704h	; (0404h)
		outpw		dx,    0300h
		outpw		03ceh, 0204h	;
		outpw		dx,    0005h	;
		outpw		dx,    0006h	; (0406h)

	;;------------------------------------------------------------
	;; Copy character mask from character under cursor
	;; to sacrifice character
		mov		es, [VidMem]
		xor		si, si
		xor		ah, ah
		xor		bh, bh
		mov		cx, [numVertBytes]
	;;------------------------------------------------------------
	;; Y char save
@copyCharY:	push		cx
		push		si
		mov		cx, [numHorizBytes]
	;;------------------------------------------------------------
	;; X char save
@copyCharX:	mov		al, byte ptr cs:TmpMousePtr[si]
		mov		bl, byte ptr cs:SacMap[si]
		push		cx
		push		si
		mov		si, ax
		mov		di, bx
	;;------------------------------------------------------------
	;; Copy character bitmap
		call		copyCharMap

	;;------------------------------------------------------------
	;; X loop
		pop		si
		pop		cx
		inc		si
		loop		@copyCharX

	;;------------------------------------------------------------
	;; Y loop
		pop		si
		pop		cx
		add		si, 3
		loop		@copyCharY

	;; Vertical loop... one per character
		mov		si, 16
		sub		si, [yHotOffset]
		mov		word ptr [MsYCount], si
		xor		si, si
		mov		cx, [numVertBytes]
@putTxt_YLoop:	push		cx
		mov		cx, [fontHeight]
		sub		cx, [MsByteCount]
		cmp		cx, [MsYCount]
		jle		ytOk
		mov		cx, [MsYCount]
ytOk:		sub		[MsYCount], cx
@putTxt_VLoop:

	;;------------------------------------------------------------
	;; Do AND mask
		xor		bp, bp
		mov		al, -1
		lea		dx, @Txt_AndWrite
		call		cursorText_Blt

	;;------------------------------------------------------------
	;; Do XOR mask
		mov		bp, [cursorSize]
		xor		al, al
		lea		dx, @Txt_XorWrite
		call		cursorText_Blt

		add		word ptr [MsCursorBase], 2
		inc		word ptr [MsByteCount]

	;;------------------------------------------------------------
	;; Decrease Y counter for this character
		loop		@putTxt_vLoop
		add		si, 3

		xor		ax, ax
		mov		[MsByteCount], ax
		pop		cx
		loop		@putTxt_YLoop

	;;------------------------------------------------------------
	;; Enable plane 0 & 1 (characters & attributes)
		outpw		03c4h, 0100h
		outpw		dx,    0302h	;
		outpw		dx,    0304h	; (0204h)
		outpw		dx,    0300h
		outpw		03ceh, 0004h
		outpw		dx,    1005h	;
		outpw		dx,    0E06h	;
		sti

		pop		es
		ret
PutCursor_Text	endp

;;***********************************************************************
;;
;; 			Tweaked text
;;
;;***********************************************************************
;;=======================================================================
;; Replace background
;;=======================================================================
ResCursor_tText	proc		near
		push		es

		mov		di, [lastMx]
		mov		ax, [lastMy]

	;;------------------------------------------------------------
	;; Calculate displayable rows/cols
		call		calcCursorHot
		xchg		ax, di

	;;------------------------------------------------------------
	;; Calculate address of cursor
		mov		cx, ax
		shr		ax, 3
		mul		[BytesPerLine]
		add		di,ax

		call		calcHorizBytes

		cli
	;; Y coordinate loop
@resTT_VLoop:	mov		cx, [numHorizBytes]
		push		di
	;; X coordinate loop
@resTT_HLoop:	lodsb
		mov		es:[di], al
		add		di, [BytesPerLine]
		loop		@resTT_HLoop
		pop		di
		inc		di
	;; Decrease y counter
		dec		[MsYCount]
		jns		@resTT_VLoop
		sti

		pop		es
		ret
ResCursor_tText	endp

;;---------------------------------------------------------
;; Writes a line of the cursor mask to the screen (AND/XOR)
cursorTText_Blt	proc		near
		push		di
		push		si

	;;------------------------------------------------------------
	;; Calculate plot mask
		call		calcPlotMask

	;;------------------------------------------------------------
	;; Blit mask to screen
		mov		cx, [numHorizBytes]
@bltTTxt_wrLp:	mov		al, PlotMask[si]

	;;------------------------------------------------------------
	;; Copy bitmap to font memory
		call		dx
		add		di, [BytesPerLine]
		inc		si
		loop		@bltTTxt_wrLp

		pop		si
		pop		di
		ret
cursorTText_Blt	endp

;;=======================================================================
;; Draw mouse cursor
;;=======================================================================
PutCursor_tText	proc		near
		push		es

		mov		di, [Mx]
		mov		ax, [My]

	;;------------------------------------------------------------
	;; Calculate displayable rows/cols
		call		calcCursorHot
		xchg		ax, di

	;;------------------------------------------------------------
	;; Calculate address of cursor
		mov		cx, ax
		shr		ax, 3
		mul		[BytesPerLine]
		add		di, ax

		call		calcHorizBytes

	;;------------------------------------------------------------
	;; Y coordinate loop
@putTT_VLoop:	mov		cx, [numHorizBytes]
		push		di

	;;------------------------------------------------------------
	;; Save background X coordinate loop
@putTT_HLoop:	mov		al, es:[di]
		mov		byte ptr [si], al
		inc		si
		add		di, [BytesPerLine]
		loop		@putTT_HLoop
		pop		di

	;;------------------------------------------------------------
	;; Do AND mask
		xor		bp, bp
		mov		al, -1
		lea		dx, @Txt_AndWrite
		call		cursorTText_Blt

	;;------------------------------------------------------------
	;; Do XOR mask
		mov		bp, [cursorSize]
		xor		al, al
		lea		dx, @Txt_XorWrite
		call		cursorTText_Blt

		inc		di
		mov		bp, [cursorBytes]
		add		[MsCursorBase], bp

	;;------------------------------------------------------------
	;; Decrease Y counter
		dec		word ptr [MsYCount]
		jns		@putTT_VLoop

		pop		es
		ret
PutCursor_tText	endp

;;***********************************************************************
;;
;; 			SVGA 16 mouse routines
;;
;;***********************************************************************
;; Swap bytes in cursor mask
crsr16_setBits	proc		near
		lea		si, CurrMousePtr
		mov		cx, [cursorSize]
@c16_loop:	mov		ax, ds:[si]
		xchg		ah, al
		mov		ds:[si], ax
		add		si, 2
		loop		@c16_loop
		ret
crsr16_setBits	endp

;;------------------------------------------
;; Write a line of the cursor mask to screen (AND/XOR)
;; Calculate line of plot mask like this:
;; 00000000 00000000 11111111 11111111 22222222 22222222
;; 01234567 89ABCDEF 01234567 89ABCDEF 01234567 89ABCDEF
;; ....XXXX XXXXXXXX XXXX.... ........ .XXX....
;; XXXXXXXX XXXXXXXX ........ .....XXX
cursor16_Blt	proc		near
		push		di
		push		dx
		push		si

		call		calcPlotMask

	;;------------------------------------------------------------
	;; Blit mask to screen
		mov		cx, [numHorizBytes]
@blt16_wrLoop:	mov		al, PlotMask[si]
		cmp		dl, curbk
		jz		@blt16_bank
		call		newbank
@blt16_bank:	xchg		es:[di], al
		add		di, 1
		adc		dl, 0
		inc		si
		loop		@blt16_wrloop

		pop		si
		pop		dx
		pop		di
		ret
cursor16_Blt	endp

;;------------------------------------------
;; Restore register values
restregs	proc		near
		outpw		SC_INDEX, 0f02h
		outpw		GC_INDEX, 0
		outpw		dx,       1
		outpw		dx,       3
		outpw		dx,       05h
		outpw		dx,       0ff08h
		ret
restregs	endp

;;=======================================================================
;; Replace background
;;=======================================================================
ResCursor_s16	proc		near
		push		es

	;;------------------------------------------------------------
	;; Save current bank from BGI driver
		mov		al, [curbk]
		mov		[mbank],al

		mov		ax, [lastMy]
		mov		di, [lastMx]

	;;------------------------------------------------------------
	;; Calculate displayable rows/cols
		call		calcCursorHot

	;;------------------------------------------------------------
	;; Calculate starting address of cursor
		shr		di, 3
		mul		[BytesPerLine]
		add		di, ax
		adc		dx, 0

		call		calcHorizBytes

	;;------------------------------------------------------------
	;; Vertical loop
@res16_VLoop:	mov		ax, 0802h
		push		dx
		push		di

	;;------------------------------------------------------------
	;; Bank loop
@res16_BkLoop:	mov		bx, dx
		outpw		SC_INDEX, ax
		mov		dx, bx

	;;------------------------------------------------------------
	;; Horizontal loop
		push		dx
		push		di
		mov		cx, [numHorizBytes]
@resS16_HRLoop:	cmp		dl, [curbk]
		jz		@resS16_readbk
		call		newbank
@resS16_readbk:	mov		bh, byte ptr cs:[si]
		xchg		byte ptr es:[di], bh
		add		di, 1
		adc		dl, 0
		inc		si
		loop		@resS16_HRLoop
		pop		di
		pop		dx

		shr		ah,1 
		jnz		@res16_BkLoop

		pop		di
		pop		dx
		add		di, [BytesPerLine]
		adc		dl, 0
		dec		[MsYCount]
		jns		@res16_VLoop

		call		restregs

	;;------------------------------------------------------------
	;; Restore bank for BGI driver
		mov		dl, [mbank]
		call		newbank
		pop		es
		ret
ResCursor_s16	endp

;;------------------------------------------
;; Reads a scanline into the save buffer
@putS16_HRLoop	proc		near
		cmp		dl, [curbk]
		jz		@putS16_readbk
		call		newbank
@putS16_readbk:	mov		bh, es:[di]
		mov		byte ptr cs:TmpMousePtr[si], bh
		add		di, 1
		adc		dl, 0
		inc		si
		loop		@putS16_HRLoop
		ret
@putS16_HRLoop	endp

;;=======================================================================
;; Draw mouse cursor
;;=======================================================================
PutCursor_s16	proc		near
		push		es

	;;------------------------------------------------------------
	;; Save bank # for BGI driver
		mov		al, [curbk]
		mov		[mbank],al

		mov		di, [Mx]
		mov		ax, [My]

	;;------------------------------------------------------------
	;; Calculate displayable rows/cols
		call		calcCursorHot

	;;------------------------------------------------------------
	;; Calculate starting address of cursor
		shr		di, 3
		mul		[BytesPerLine]
		add		di, ax
		adc		dx, 0

		call		calcHorizBytes

		mov		word ptr [MsTmpBase], 0
@putS16_VLoop:	push		di
		push		dx
		push		si
		mov		si, [MsTmpBase]
		mov		ax, 0304h
@putS16_BkLoop:	push		dx
		push		di

	;;------------------------------------------------------------
	;; Set read plane
		mov		bx, dx
		outpw		GC_INDEX, ax
		mov		dx, bx

	;;------------------------------------------------------------
	;; Save horizontal line
		mov		cx, [numHorizBytes]
		call		@putS16_HRLoop
		pop		di
		pop		dx

	;;------------------------------------------------------------
	;; Loop through read banks
		dec		ah
		jns		@putS16_BkLoop

	;;------------------------------------------------------------
	;; Save temp position
		mov		[MsTmpBase], si
		pop		si
		pop		dx
		pop		di

	;;------------------------------------------------------------
	;; Do AND mask
		push		dx
		outpw		GC_INDEX, 0803h
		pop		dx
		xor		bp, bp
		mov		al, -1
		call		cursor16_Blt

	;;------------------------------------------------------------
	;; Do XOR mask
		push		dx
		outpw		GC_INDEX, 01803h
		pop		dx
		mov		bp, [cursorSize]
		xor		al, al
		call		cursor16_Blt

		add		di, [BytesPerLine]
		adc		dl, 0
		mov		bp, [cursorBytes]
		add		[MsCursorBase], bp

		dec		word ptr [MsYCount]
		jns		@putS16_VLoop

		call		restregs

	;;------------------------------------------------------------
	;; Restore bank for BGI driver
		mov		dl, [mbank]
		call		newbank
		pop		es
		ret
PutCursor_s16	endp

;;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;;
;;		Hardware cursor support
;;
;; xx_setPos	: Sets the current mouse position
;;    CX - X coordinate
;;    DX - Y coordinate
;;
;; xx_onoff	: Turns the cursor on and off
;;
;; xx_setClr	: cursorFGColor, cursorBGColor
;;
;; xx_setMap	: Sets the current mouse bitmap
;;    ES:BX  = map
;;
;;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

;;***********************************************************************
;;		ATI Graphics Ultra hardware cursor support
;;***********************************************************************
if 0
$gup_setPos	proc		near
		push		bx
		mov		bx, dx
		mov		ax, cx
		and		ax, 7
		outpw		012eeh, ax
		mov		ax, bx
		and		ax, 7
		outpw		016eeh, ax
		mov		ax, cx
		and		al, f8h
		mul		[bytes_per_pix]		;; 256, 32k, 64k, 16m
;; ax = x & 0xFFF8, bx = y, cx = x
		xchg		ax, bx
;; ax = y, bx = x & 0fff8
		and		al, 0f8h
		mul		[BytesPerLine]
		add		bx, ax
		adc		dx, 0
		shr		dx, 1		;; loc = ((y&fff8)*bytes+x) >> 2;
		rcr		bx, 1
		shr		dx, 1
		rcr		bx, 1
		push		dx
		outpw		02aEEh,bx
		pop		bx
		outpw		02eeeh, bx
		pop		bx
		ret
$gup_setPos	endp
endif

;;***********************************************************************
;;
;;			S3 hardware cursor support
;;
;;***********************************************************************
;;========================================================================
;; turn cursor on/off
;; Input:
;;	BX = 0 : Turn off
;;	BX = 1 : Turn on
;;========================================================================
$s3_onoff	proc		near
	;;----------------------------
	;; Unlock registers
		cli
		wrinx		CRTC_INDEX, 039h, 0a0h

	;;----------------------------
	;; Enable/disable HW cursor
		add		bl, 2
		modinx		dx, 045h, 3, bl

	;;----------------------------
	;; Lock registers
		wrinx		dx, 039h, 0
		sti
		ret
$s3_onoff	endp

;;========================================================================
;; Set cursor pattern
;;
;; Format: 1 word of AND mask, 1 word of XOR mask, repeated 256 times
;;	   1024 bytes total
;;
;;========================================================================
S3_OFFSET	EQU		1020
S3_CURSORMAX	EQU		64
$s3_setBits	proc		near

	;;----------------------------
	;; Set last bank
		mov		al, [curbk]
		mov		[mbank], al

	;;----------------------------
	;; Copy cursor data to memory
		mov		es, [VidMem]
		lea		si, CurrMousePtr

	;; Calculate offset of cursor data
		mov		ax, S3_OFFSET
		mov		dx, 1024
		mul		dx
		mov		di, ax
		call		newbank

		xor		cx, cx
	;;----------------------------
	;; Y loop
@s3_sy:		xor		bx, bx

	;;----------------------------
	;; X loop
@s3_sx:		xor		ax, ax			;; XOR (0000)
		mov		dx, ax			;; AND (FFFF)
		not		ax
		cmp		bx, [cursorBytes]
		jge		@s3_sbit
		cmp		cx, [cursorHeight]
		jge		@s3_sbit

	;;----------------------------
	;; Get AND mask
		push		si
		add		si, [cursorSize]
		mov		dx, [si]
		pop		si

	;;----------------------------
	;; Get XOR mask
		lodsw
@s3_sbit:	xchg		ah, dl			;; Swap bytes
		xchg		dh, al

	;;----------------------------
	;; Store masks
		mov		es:[di], dx		;; AND
		add		di, 2
		stosw					;; XOR

	;;----------------------------
	;; Increase X
		add		bx, 2
		cmp		bx, (S3_CURSORMAX SHR 3)	;; (64 / 8 bytes)
		jl		@s3_sx

	;;----------------------------
	;; Increase Y
		inc		cx
		cmp		cx, S3_CURSORMAX
		jl		@s3_sy

	;;----------------------------
	;; Restore bank
		mov		dl, [mbank]
		call		newbank

		mov		cx, S3_OFFSET

	;;----------------------------
	;; Unlock registers
		cli
                wrinx           CRTC_INDEX, 039h, 0A0h

	;;----------------------------
        ;; Cursor location low
                wrinx           dx, 04dh, cl

	;;----------------------------
        ;; Cursor Location high
                wrinx           dx, 04ch, ch

		cmp		[curr_mode], MODE_P15
		jnz		@s3_not32k

	;;----------------------------
	;; Set horizontal stretch X2
		modinx		dx, 045h, 04h, 04h

@s3_not32k:	cmp		[curr_mode], MODE_P24
		jnz		@s3_notTC

	;;----------------------------
	;; Set horizontal stretch X3
		modinx		dx, 045h, 08h, 08h

@s3_notTC:
	;;----------------------------
	;; Lock registers
                wrinx           dx, 039h, 0h
		sti

		ret
$s3_setBits	endp

;;========================================================================
;; Set cursor position
;;========================================================================
$s3_setPos	proc		near
		mov		cx, [Mx]
		mov		bx, [My]

	;;----------------------------
	;; Unlock registers
		cli
		wrinx		CRTC_INDEX, 039h, 0A0h

		xor		di, di
	;;----------------------------
	;; Set X coordinate
		sub		cx, [MsHotX]
		jge		@s3_leftx
		neg		cx

		mov		di, cx
	;;----------------------------
	;; Set X = 0
		xor		cx, cx
@s3_leftx:	cmp		[curr_mode], MODE_P15
		jnz		@s3_noShift32k
		shl		cx, 1
@s3_noShift32k:	wrinx		dx, 047h, cl
		wrinx		dx, 046h, ch

	;;----------------------------
	;; Set XOrigin
		mov		ax, di
		wrinx		dx, 04eh, al

		xor		di, di
	;;----------------------------
	;; Set Y coordinate
		sub		bx, [MsHotY]
		jge		@s3_lefty
		neg		bx

		mov		di, bx
	;;----------------------------
	;; Set Y = 0
		xor		bx, bx
@s3_lefty:	wrinx		dx, 049h, bl
		wrinx		dx, 048h, bh

	;;----------------------------
	;; Set YOrigin
		mov		ax, di
		wrinx		dx, 04fh, al

	;;----------------------------
	;; Lock registers
		wrinx		dx, 039h, 0
		sti

		ret
$s3_setPos	endp

;;========================================================================
;; Set cursor color
;;========================================================================
$s3_setClr	proc		near

		cli
	;;----------------------------
	;; Unlock registers
		wrinx		CRTC_INDEX, 039h, 0A0h

	;;----------------------------
	;; Unlock registers
		wrinx		dx, 038h, 048h

		cmp		[curr_mode], MODE_P8
		jz		@s3_setClr256

	;;----------------------------
	;; Set cursor stack FG color
		rdinx		dx, 045h
		mov		al, byte ptr [cursorFGColor+2]
		wrinx		dx, 04Ah, al		;; R
		mov		ax, word ptr [cursorFGColor]
		xchg		al, ah
		wrinx		dx, 04Ah, al		;; G
		wrinx		dx, 04Ah, ah		;; B

	;;----------------------------
	;; Set cursor stack BG color
		rdinx		dx, 045h
		mov		al, byte ptr [cursorBGColor+2]
		wrinx		dx, 04Bh, al		;; R
		mov		ax, word ptr [cursorBGColor]
		xchg		al, ah
		wrinx		dx, 04Bh, al		;; G
		wrinx		dx, 04Bh, ah		;; B
		jmp		short @s3_doneSet

	;;----------------------------
	;; Set cursor FG color
@s3_setClr256:	mov		al, byte ptr [cursorFGColor]
		wrinx		dx, 0Eh, al

	;;----------------------------
	;; Set cursor BG color
		mov		al, byte ptr [cursorBGColor]
		wrinx		dx, 0Fh, al

	;;----------------------------
	;; Lock registers
@s3_doneSet:	wrinx		dx, 039h, 0

	;;----------------------------
	;; Lock registers
		wrinx		dx, 038h, 0
		sti
		ret
$s3_setClr	endp

;;***********************************************************************
;;
;;		Paradise hardware cursor support
;;
;;***********************************************************************
$parad_setPos	proc		near
		push		bx

		mov		ax, [Mx]
		mov		bx, [My]
		mul		[bytes_per_pix]
		mov		cx, ax

	;;----------------------------
	;; Set Cursor mode
		outp		023c0h, 2

		mov		di, 06000h
		cmp		[parad_CursorReg], 033h
		jnz		@paradNotC33
		mov		di, 0d000h

	;;----------------------------
	;; Set X pos
@paradNotC33:	mov		ax, di
		add		ax, cx
		outpw		023C2h, ax
	;;----------------------------
	;; Set Y Pos
		mov		ax, di
		add		ax, 1000h
		add		ax, bx
		outpw		023C2h, ax

	;;----------------------------
	;; Set hotspot
		mov		cx, [MsHotY]
		mov		ch, cl
		shl		ch, 2
		mov		bx, [MsHotX]
		or		ch, 0c0h
		or		bh, ch
		outpw		023C2h, bx

		pop		bx
		ret
$parad_setPos	endp

;;========================================================================
;; Set cursor pattern
;;
;; Format: 8 bits of AND, 8 bits of XOR, for 32x32 or 64x64 cursor
;;========================================================================
;;========================================================================
;; turn cursor on/off
;; Input:
;;	BX = 0 : Turn off
;;	BX = 1 : Turn on
;;========================================================================
$parad_onoff	proc		near
		and		bx, 1
		shl		bx, 11
		outp		023C0h, 2
		outpw		023C2h, bx
		ret
$parad_onoff	endp

PARAD_OFFSET	EQU		100
PARAD_CURSORMAX	EQU		32
$parad_setBits	proc		near
	;; Set last bank
		mov		al, [curbk]
		mov		[mbank], al
		mov		dl, 15
		call		newbank

	;; Copy cursor data to memory
		mov		es, [VidMem]
		lea		si, CurrMousePtr

	;; Calculate offset of cursor data
		mov		ax, PARAD_OFFSET
		mul		[BytesPerLine]
		mov		di, ax
		call		newbank

		xor		cx, cx
	;;----------------------------
	;; Y loop
@parad_sy:	xor		bx, bx

	;;----------------------------
	;; X loop
@parad_sx:	xor		ax, ax
		mov		dx, ax
		not		ax
		cmp		bx, [cursorBytes]
		jge		@parad_sbit
		cmp		cx, [cursorHeight]
		jge		@parad_sbit
	;; Get AND mask
		push		si
		add		si, [cursorSize]
		mov		dx, [si]
		pop		si
	;; Get XOR mask
		lodsw
@parad_sbit:
	;; Store masks
		mov		es:[di],ah
		mov		es:[di+1],dh
		mov		es:[di+2],al
		mov		es:[di+3],dl
		add		di, 4

	;;----------------------------
	;; Increase X
		add		bx, 2
		cmp		bx, (PARAD_CURSORMAX SHR 3)	;; (32 / 8 bytes)
		jl		@parad_sx

	;;----------------------------
	;; Increase Y
		inc		cx
		cmp		cx, PARAD_CURSORMAX
		jl		@parad_sy

	;;----------------------------
	;; Set start offset
		mov		ax, (PARAD_OFFSET SHR 2)
		mul		[BytesPerLine]
		mov		bx, ax			;; Lower
		mov		cx, dx			;; Upper
		mov		ch, bh
		rol		cx, 4
		and		cx, 0fffh
		and		bx, 0fffh
		or		bx, 1000h
		or		cx, 2000h
		outpw		023C2h, bx
		outpw		023C2h, cx

	;; Restore bank
		mov		dl, [mbank]
		call		newbank
		ret
$parad_setBits	endp

;;***********************************************************************
;;
;;		Cirrus 54xx hardware cursor support
;;
;;***********************************************************************
;;========================================================================
;; turn cursor on/off
;; Input:
;;	BX = 0 : Turn off
;;	BX = 1 : Turn on
;;========================================================================
$cir54_onoff	proc		near
		and		bx, 1
	;; Enable hardware cursor
	;; Enable access to RAMDAC extended colors
		modinx		SC_INDEX, 012h, 011b, bl
		ret
$cir54_onoff	endp

;;========================================================================
;; Set cursor position
;;========================================================================
$cir54_setPos	proc		near
		mov		cx, [Mx]
		mov		bx, [My]

	;; Cirrus doesn't have a hotspot register??
		sub		cx, [MsHotX]
		sub		bx, [MsHotY]

		shl		cx, 5		;; HW cursor X position
		shl		bx, 5		;; HW cursor Y position
		or		cl, 010h
		or		bl, 011h
		outpw		SC_INDEX, cx
		outpw		dx,       bx
		ret
$cir54_setPos	endp

;;========================================================================
;; Set cursor color
;;========================================================================
$cir54_setClr	proc		near
		modinx		SC_INDEX, 012h, 2, 2

	;; Set cursor FG color
		outp		03c8h, 0ffh
		mov		al, byte ptr [cursorFGColor+2]
		outp		03c9h, al			;; R
		mov		ax, word ptr [cursorFGColor]
		xchg		al, ah
		outp		dx, al				;; G
		outp		dx, ah				;; B

	;; Set cursor BG color
		outp		03c8h, 00h
		mov		al, byte ptr [cursorBGColor+2]
		outp		03c9h, al			;; R
		mov		ax, word ptr [cursorBGColor]
		xchg		al, ah
		outp		dx, al				;; G
		outp		dx, ah				;; B

		modinx		SC_INDEX, 012h, 02h, 0
		ret
$cir54_setClr	endp

;;========================================================================
;; Set cursor pattern (256, 32k and 64k modes)
;;
;; Format: 128 bytes of XOR mask, 128 bytes of NAND mask (32x32 cursor)
;;	   512 bytes of XOR mask, 512 bytes of NAND mask (64x64 cursor)
;;
;; Cursors are stored at end of video memory, starting at offset
;;   EOMem - 64*256  = EOMem - 16k	(32x32)
;;   EOMem - 16*1024 = EOMem - 16k	(64x64)
;;========================================================================
CIRRUS54_OFFSET	EQU		60
;; Set bitmask for Cirrus54 chipset
$cir54_setBits	proc		near
	;; Set last bank
		mov		al, [curbk]
		mov		[mbank], al
		mov		dl, 15
		call		newbank

	;; Copy cursor data to memory
		mov		es, [VidMem]
		lea		si, CurrMousePtr
		mov		di, -((64-CIRRUS54_OFFSET)*256)
		xor		cx, cx

	;;----------------------------
	;; Y loop
@cir54_sy:	xor		bx, bx

	;;----------------------------
	;; X loop
@cir54_sx:	xor		ax, ax
		mov		dx, ax
		cmp		bx, [cursorBytes]
		jge		@cir54_sbit
		cmp		cx, [cursorHeight]
		jge		@cir54_sbit
	;; Get AND mask
		push		si
		add		si, [cursorSize]
		mov		dx, [si]
		pop		si
	;; Get XOR mask
		lodsw
		not		ax			;; Invert AND mask
@cir54_sbit:	xchg		ah, dl			;; Swap AND/XOR
		xchg		dh, al
	;; Store masks
		mov		es:[di+128], dx		;; NAND
		stosw					;; XOR

	;;----------------------------
	;; Increase X
		add		bx, 2
		cmp		bx, (CURSORMAX SHR 3)	;; (32 / 8 bytes)
		jl		@cir54_sx

	;;----------------------------
	;; Increase Y
		inc		cx
		cmp		cx, CURSORMAX
		jl		@cir54_sy

	;;----------------------------
	;; Select 1 of 64 32x32 cursors	
		wrinx		SC_INDEX, 013h, CIRRUS54_OFFSET

	;; Restore bank
		mov		dl, [mbank]
		call		newbank
		ret
$cir54_setBits	endp

if 0
;; Set bitmask for Cirrus54 chipset (24-bit)
$cir542_setBits	proc		near
	;; Set last bank
		mov		al, [curbk]
		mov		[mbank], al
		mov		dl, 15
		call		newbank

	;; Copy cursor data to memory
		mov		es, [VidMem]
		lea		si, CurrMousePtr
		mov		di, -((64-CIRRUS54_OFFSET)*256)
		xor		cx, cx

	;;----------------------------
	;; Y loop
@cir542_sy:	xor		bx, bx

	;;----------------------------
	;; X loop
@cir542_sx:	xor		ax, ax
		mov		dx, ax
		cmp		bx, [cursorBytes]
		jge		@cir542_sbit
		cmp		cx, [cursorHeight]
		jge		@cir542_sbit
	;; Get AND mask
		push		si
		add		si, [cursorSize]
		mov		dx, [si]
		pop		si
	;; Get XOR mask
		lodsw
		not		ax			;; Invert AND mask
@cir542_sbit:	xchg		ah, dl			;; Swap AND/XOR
		xchg		dh, al
	;; Store masks
		xor		dx,dx
		mov		ax,0ffffh

		mov		es:[di+128], dx		;; NAND
		mov		es:[di+256], ax
		mov		es:[di+384], dx
		stosw					;; XOR

	;;----------------------------
	;; Increase X
		add		bx, 2
		cmp		bx, (CURSORMAX SHR 3)	;; ( 32 / 8 bytes)
		jl		@cir542_sx

	;;----------------------------
	;; Increase Y
		inc		cx
		cmp		cx, CURSORMAX
		jl		@cir542_sy

	;;----------------------------
	;; Select 1 of 64 32x32 cursors
		wrinx		SC_INDEX, 013h, CIRRUS54_OFFSET

	;; Restore bank
		mov		dl, [mbank]
		call		newbank
		ret
$cir542_setBits	endp
endif

;;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;;
;;			Standard mouse functions
;;
;;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

;;========================================================================
;; Mouse function 0 - Reset mouse
;;	SS:BP = address of SimInt structure with input/output register values
;;========================================================================
MsReset		proc		near
		push		ds
		push		es
		LoadDataSeg	ds

		mov		cx, [lastMx]
		mov		dx, [lastMy]
		call		$HideCursor

	;;------------------------------------------------------------
	;; Handle other run-time initialization info
		call		[SetupFunc]

	;;------------------------------------------------------------
	;; Poke video mode into BIOS area (fools mouse driver into pixel mode)
		mov		ax, 040h
		mov		es, ax
		mov		al, es:[049h]
		mov		[save_mode], al
		mov		al, [init_mode]
		mov		es:[049h], al

	;;------------------------------------------------------------
	;; Call old handler
		mov		ax, word ptr ss:[bp+RealAX]
		CallOldIntr33
	;; Store results of call
		mov		word ptr ss:[bp+RealAX], ax
		mov		word ptr ss:[bp+RealBX], bx

	;;------------------------------------------------------------
	;; Restore video mode into BIOS area
		mov		ax, 040h
		mov		es, ax
		mov		al, [save_mode]
		mov		es:[049h], al

	;;------------------------------------------------------------
	;; Set mouse range to size of screen
		xor		cx, cx
		mov		dx, [MsXres]
		dec		dx
		mov		[limitLX], cx
		mov		[limitRX], dx
		mov		ax, 07h
		CallOldIntr33
		xor		cx, cx
		mov		dx, [MsYres]
		dec		dx
		mov		[limitLY], cx
		mov		[limitRY], dx
		mov		ax, 08h
		CallOldIntr33

	;;------------------------------------------------------------
	;; Sets mouse position to screen center (init 0)
		mov		cx, [MsXres]
		dec		cx
		shr		cx, 1
		mov		[Mx], cx
		mov		[lastMx], cx

		mov		dx, [MsYres]
		dec		dx
		shr		dx, 1
		mov		[My], dx
		mov		[lastMy], dx

	;; Call through to old handler
		mov		ax,4
		CallOldIntr33

	;;------------------------------------------------------------
	;; Sets pointer page to 0 (init 1)
		xor		ax,ax
		mov		word ptr [MPageOfs],ax
		mov		word ptr [MPageOfs+2],ax

	;;------------------------------------------------------------
	;; Mouse pointer is hidden (init 2)
		mov		byte ptr [VisCount], -1

	;;------------------------------------------------------------
	;; Set graphics pointer shape to default (init 3)
		mov		ax, ds
		mov		es, ax
		mov		ax, 1010h
		lea		dx, DefMousePtr
		xor		bx, bx		;; Hot spot
		xor		cx, cx
		call		$MakePointer

	;;------------------------------------------------------------
	;; User handler is disabled (init 4)
		_ClrFlag	MouseFlags, CHAINED
		lea		dx, $MouseHandler
		mov		ax, cs
		mov		es, ax
		mov		ax, 0Ch
		mov		cx, 0111111b
		CallOldIntr33

	;;------------------------------------------------------------
	;; Enable light pen (init 5)

	;;------------------------------------------------------------
	;; Set horizontal+vertical mickeys ratio (init 6)
		mov		cx, HORIZ_SENSITIVITY
		mov		dx, VERT_SENSITIVITY
		mov		ax, 0fh
		CallOldIntr33

	;;------------------------------------------------------------
	;; Set double speed threshold (init 7)

	;;------------------------------------------------------------
	;; Set minimum/maximum exclude area for current screen (init 8)
		mov		ExcludeLX,-1
		mov		ExcludeLY,-1
		mov		ExcludeRX,-1
		mov		ExcludeRY,-1

		pop		es
		pop		ds
		ret
MsReset		endp

;;========================================================================
;; Mouse function 0XXh - Pass through call to old handler
;;	SS:BP = address of SimInt structure with input/output register values
;;========================================================================
MsOld		proc		near

	;;------------------------------------------------------------
	;; Call old handler
		mov		ax, word ptr ss:[bp+RealAX]
		CallOldIntr33	cs:

	;;------------------------------------------------------------
	;; Save results of call
		mov		word ptr ss:[bp+RealAX],ax
		mov		word ptr ss:[bp+RealBX],bx
		mov		word ptr ss:[bp+RealCX],cx
		mov		word ptr ss:[bp+RealDX],dx
		mov		word ptr ss:[bp+RealSI],si
		mov		word ptr ss:[bp+RealDI],di
		ret
MsOld		endp

;;========================================================================
;; Mouse function 01h - show cursor
;;	SS:BP = address of SimInt structure with input/output register values
;;========================================================================
MsShowCursor	proc		near
		push		ds
		LoadDataSeg	ds
		call		$ShowCursor
		mov		bx, 1
		call		[CursorOnOffFunc]
		pop		ds
		ret
MsShowCursor	endp

;;========================================================================
;; Mouse function 02h - hide cursor
;;	SS:BP = address of SimInt structure with input/output register values
;;========================================================================
MsHideCursor	proc		near
		push		ds
		LoadDataSeg	ds
		call		$HideCursor
		xor		bx, bx
		call		[CursorOnOffFunc]
		pop		ds
		ret
MsHideCursor	endp

;;========================================================================
;; Mouse function 03h - Get Pointer position
;; Input:
;;	SS:BP = address of SimInt structure with input/output register values
;; Output:
;;	BX = mouse button status
;;	CX = X coordinate
;;	DX = Y coordinate
;;
;;========================================================================
MsGetPos	proc		near
		push		ds
		LoadDataSeg	ds

	;;------------------------------------------------------------
	;; Call old handler
		mov		ax, 03h
		CallOldIntr33

	;;------------------------------------------------------------
	;; Save results of call
		mov		word ptr ss:[bp+RealBX],bx

	;;------------------------------------------------------------
	;; Calculate real position
		cmp		[curr_mode], MODE_TEXT
		jnz		@normalGetPos

		call		scaleYPos

@normalGetPos:	mov		word ptr ss:[bp+RealCX],cx
		mov		word ptr ss:[bp+RealDX],dx
		pop		ds
		ret
MsGetPos	endp

;;========================================================================
;; Mouse function 04h - Set pointer position
;;  Input:
;;	CX = X coordinate
;;	DX = Y coordinate
;;	SS:BP = address of SimInt structure with input/output register values
;;========================================================================
MsSetPos	proc		near
		push		ds
		LoadDataSeg	ds

        ;;------------------------------------------------------------
        ;; Calculate real position
                cmp             [curr_mode], MODE_TEXT
                jnz             @normalSetPos

                mov             ax, dx
                call            calcYPos
                mov             dx, ax

@normalSetPos:  mov             [Mx], cx
                mov             [My], dx

	;;------------------------------------------------------------
	;; Call old handler
		mov		ax, 4
		CallOldIntr33

	;;------------------------------------------------------------
	;; Hide/draw cursor
		call		$HideCursor
		call		$ShowCursor

		pop		ds
		ret
MsSetPos	endp

;;========================================================================
;; Mouse function 05h/06h - Get Button press/release information
;; Input:
;;	SS:BP = address of SimInt structure with input/output register values
;; Output:
;;	AX = mouse button status
;;	BX = press/release counter
;;	CX = X coordinate
;;	DX = Y coordinate
;;
;;========================================================================
MsGetButton	proc		near
		push		ds
		LoadDataSeg	ds

	;;------------------------------------------------------------
	;; Call old handler
		mov		ax, word ptr ss:[bp+RealAX]
		CallOldIntr33

	;;------------------------------------------------------------
	;; Save results of call
		mov		word ptr ss:[bp+RealAX],ax
		mov		word ptr ss:[bp+RealBX],bx

	;;------------------------------------------------------------
	;; Calculate real position
		cmp		[curr_mode], MODE_TEXT
		jnz		@normalButton

		call		scaleYPos

@normalButton:	mov		word ptr ss:[bp+RealCX],cx
		mov		word ptr ss:[bp+RealDX],dx
		pop		ds
		ret
MsGetButton	endp

;;========================================================================
;; Mouse function 07h - Set horizontal limits
;;  Input:
;;	CX = minimum X coordinate
;;	DX = maximum X coordinate
;;	SS:BP = address of SimInt structure with input/output register values
;;========================================================================
MsSetHLim	proc		near
		push		ds
		LoadDataSeg	ds

		cmp		[curr_mode], MODE_TEXT
		jnz		@normalHLim

        ;;------------------------------------------------------------
        ;; Some apps set right edge to Xres-1
		mov		ax, dx
		add		ax, 7
		cmp		ax, [MsXres]
		jge		@normalHLim

	;;------------------------------------------------------------
	;; Cursor can move extra 7 pixels
		mov		dx, ax

@normalHLim:	mov		[limitLX], cx
		mov		[limitRX], dx
	;;------------------------------------------------------------
	;; Call original handler
		mov		ax, 07h
		CallOldIntr33

		pop		ds
		ret
MsSetHLim	endp

;;========================================================================
;; Mouse function 08h - Set vertical limits
;;  Input:
;;	CX = minimum Y coordinate
;;	DX = maximum Y coordinate
;;	SS:BP = address of SimInt structure with input/output register values
;;========================================================================
MsSetVLim	proc		near
		push		ds
		LoadDataSeg	ds

		cmp		[curr_mode], MODE_TEXT
		jnz		@normalVLim

	;;------------------------------------------------------------
	;; Special SetVLim for text modes - take into account different
	;; font heights (defaults to 8 height) minimum
		mov		ax, cx
		call		calcYPos
		mov		cx, ax

	;;------------------------------------------------------------
	;; Cursor can move an extra fontheight pixels
		mov		ax, dx
		call		calcYPos
		add		ax, [fontHeight]
		dec		ax
		mov		dx, ax

@normalVLim:	mov		[limitLY], cx
		mov		[limitRY], dx

	;;------------------------------------------------------------
	;; Call original handler
		mov		ax, 08h
		CallOldIntr33

		pop		ds
		ret
MsSetVLim	endp

;;========================================================================
;; Mouse function 09h - Set graphics pointer
;;  Input:
;;	BX = hot spot offset
;;	CX = hot spot offset
;;	ES:DX = segment:offset of image data
;;	SS:BP = address of SimInt structure with input/output register values
;;========================================================================
MsSetGraphPtr	proc		near
		push		ds
		LoadDataSeg	ds

	;;------------------------------------------------------------
	;; Call old handler
		;;mov		ax, 09h
		;;CallOldIntr33

	;;------------------------------------------------------------
	;; Set 16x16 pointer data
		mov		ax,01010h
		call		$MakePointer

		pop		ds
		ret
MsSetGraphPtr	endp

;;========================================================================
;; Mouse function 0Ch - Set event handler
;;  Input:
;;	CX - Event mask
;;	ES:DX - Address of handler
;;========================================================================
MsSetHandler	proc		near
		push		ds
		LoadDataSeg	ds

	;;------------------------------------------------------------
	;; Set chained flag
		_SetFlag	MouseFlags, CHAINED
		mov		word ptr [ChainedMask], cx
		test		dx, dx
		jnz		@validHandler
		mov		ax, es
		test		ax, ax
		jnz		@validHandler

	;;------------------------------------------------------------
        ;; Address passed in was null... clear chained flag
                _ClrFlag        MouseFlags, CHAINED

@validHandler:	mov		word ptr [ChainedIntr33], dx
		mov		word ptr [ChainedIntr33+2], es

		pop		ds
		ret
MsSetHandler	endp

;;========================================================================
;; Mouse function 010h - Set Exclude area
;;  Input:
;;	CX - Left x coordinate
;;	DX - Top y coordinate
;;	SI - Right x coordinate
;;	DI - Bottom y coordinate
;;	SS:BP = address of SimInt structure with input/output register values
;;========================================================================
MsSetExclude	proc		near
		push		ds
		LoadDataSeg	ds
		mov		ExcludeLX,cx
		mov		ExcludeLY,dx
		mov		ExcludeRX,si
		mov		ExcludeRY,di
		pop		ds
		ret
MsSetExclude	endp

;;========================================================================
;; Mouse function 12h - Set large graphics pointer
;;  Input:
;;	BH = cursor width in words
;;	CH = rows in cursor
;;	BL = horizontal hot spot
;;	CL = veritcal hot spot
;;	ES:DX = segment:offset of image data
;;	SS:BP = address of SimInt structure with input/output register values
;;  Return:
;;	AX = 0FFFFh - Success
;;========================================================================
MsSetLargePtr	proc		near
		push		ds
		push		es
		LoadDataSeg	ds

	;;------------------------------------------------------------
	;; Calculate width/height
		mov		al, ch
		mov		ah, bh
		shl		ah, 4

	;;------------------------------------------------------------
	;; Clear hotspot
		xor		bh, bh
		xor		ch, ch

	;;------------------------------------------------------------
	;; Call old handler
		;;mov		ax, 012h
		;;CallOldIntr33

	;;------------------------------------------------------------
	;; Set 32x16 pointer data
		call		$MakePointer

	;;------------------------------------------------------------
	;; Mark successful
		mov		word ptr ss:[bp+RealAX], 0FFFFh
		pop		es
		pop		ds
		ret
MsSetLargePtr	endp

;;========================================================================
;; Mouse function 01Dh - Set pointer page
;;  Input:
;;	BX = page
;;	SS:BP = address of SimInt structure with input/output register values
;;========================================================================
MsSetPage	proc		near
		push		ds
		LoadDataSeg	ds

	;;------------------------------------------------------------
	;; Hide cursor
		mov		[MsPage], bx
		call		$HideCursor

	;;------------------------------------------------------------
	;; Get page offset
		mov		ax, [MsPage]
		;;call		getdrawpage		;; Get from BGI driver
		xor		ax,ax
		xor		dx,dx
		mov		word ptr [MPageOfs],ax
		mov		word ptr [MPageOfs+2],dx

		call		$ShowCursor
		pop		ds
		ret
MsSetPage	endp

;;========================================================================
;; Mouse function 01Eh - Get pointer page
;;  Input:
;;	SS:BP = address of SimInt structure with input/output register values
;;  Output: 
;;	BX = page
;;========================================================================
MsGetPage	proc		near
		push		ds
		LoadDataSeg	ds

	;;------------------------------------------------------------
	;; Get page info
		mov		ax, [MsPage]
		mov		word ptr ss:[bp+RealBX], ax

		pop		ds
		ret
MsGetPage	endp

TestExclude	proc	far
		mov	cx, [Mx]
		mov	dx, [My]
		sub	cx, [MsHotX]
		sub	dx, [MsHotY]

		cmp	cx, [ExcludeRX]
		ja	flex
		cmp	dx, [ExcludeRY]
		ja	flex

		add	dx, [cursorHeight]
		cmp	dx, [ExcludeLY]
		jb	flex

		add	cx, [cursorWidth]
		cmp	cx, [ExcludeLX]
		jb	flex

	;; Turn off cursor
		xor	bx, bx
		call	[CursorOnOffFunc]

	;; Cursor is in bounding box
		mov	byte ptr [VisCount], 0ffh
		stc
		ret

	;; Cursor isn't within bounding box
flex:		clc
		ret
TestExclude	endp

;;========================================================================
;; Mouse event callback function
;;  Input:
;;	AX - Event flags
;;	BX - Button state
;;	CX - X coordinate
;;	DX - Y coordinate
;;	SI - last raw vertical mickey count
;;	DI - last raw horizontal mickey count
;;	DS - Mouse driver data segment
;;========================================================================
$MouseHandler	proc		far
		push		ds
		LoadDataSeg	ds

	;;------------------------------------------------------------
	;; Call chained handler, if it exists
		_TestFlag	MouseFlags, CHAINED
		jz		NoChained
		test		ax, [ChainedMask]
		jz		NoChained

		pusha
		push		ds
		push		es

		cmp		[curr_mode], MODE_TEXT
		jnz		@handlerYC

	;;------------------------------------------------------------
	;; Calculate scaled y position
		call		scaleYPos

	;;------------------------------------------------------------
	;; Call chained handler
@handlerYC:	call		dword ptr [ChainedIntr33]
		pop		es
		pop		ds
		popa

	;;------------------------------------------------------------
	;; Make sure cursor is visible
		test		ax, 1
		jz		@drawEnd

NoChained:	push		cx
		push		dx

		cmp		byte ptr [VisCount], 0
		jl		@noDraw

	;;------------------------------------------------------------
	;; Restore/Draw cursor
		WaitForRetrace

		call		[ResCursorFunc]
		call		TestExclude
		jc		@noDraw

	;;------------------------------------------------------------
	;; Set new Mx & My
		pop		word ptr [My]
		pop		word ptr [Mx]
		call		[PutCursorFunc]
		pop		ds
		ret

	;;------------------------------------------------------------
	;; Set new Mx & My
@noDraw:	pop		word ptr [My]
		pop		word ptr [Mx]
@drawEnd:	pop		ds
		ret
$MouseHandler	endp

;;========================================================================
;; Change the mouse pointer
;; Input:
;;   DS    - Data segment
;;   ES:DX - offset of mouse pointer
;; cursorWidth  = (AH-1)
;; cursorHeight = AL
;; cursorBytes  = (AH>>3)
;; cursorSize   = cursorBytes*cursorHeight = AL*(AH>>3)
;;========================================================================
$MakePointer	proc		near
		push		es

	;;------------------------------------------------------------
	;; Hide cursor
		call		$HideCursor

	;;------------------------------------------------------------
	;; Set cursor hotspot
		mov		[MsHotX], bx
		mov		[MsHotY], cx

	;;------------------------------------------------------------
	;; Set cursor type
		mov		byte ptr [cursorStyle], STANDARD_CURSOR

	;;------------------------------------------------------------
	;; Set cursor size info
		xor		bh,bh
		mov		bl,al
		mov		[cursorHeight], bx
		mov		bl,ah
		mov		[cursorWidth], bx
		shr		ah, 3
		mov		bl,ah
		mov		[cursorBytes], bx
		mul		ah
		mov		[cursorSize], ax

	;;------------------------------------------------------------
	;; Set cursor data
		mov		si, dx
		lea		di, CurrMousePtr
		mov		cx, [cursorSize]
		push		ds
		mov		ax,es
		mov		ds,ax			;; DS:SI = src mouse data

		LoadDataSeg	es			;; ES:DI = dest mouse ptr
		rep		movsw
		pop		ds

	;;------------------------------------------------------------
	;; Set cursor mask
		call		[SetCursorBitsFunc]

	;;------------------------------------------------------------
	;; Display cursor
		call		$ShowCursor

		pop		es
		ret
$MakePointer	endp

;;========================================================================
;; Displays the mouse cursor
;;========================================================================
$ShowCursor	proc		near
		cmp		byte ptr [VisCount],0
		jz		@showExit
		cmp		byte ptr [VisCount],0ffh
		jnz		@showIncr

	;;------------------------------------------------------------
	;; Draw cursor
;;		WaitForRetrace

		pusha
		call		[PutCursorFunc]
		popa
@showIncr:	inc		byte ptr [VisCount]
@showExit:	ret
$ShowCursor	endp

;;========================================================================
;; Hides the mouse cursor
;;========================================================================
$HideCursor	proc		near
		dec		byte ptr [VisCount]
		cmp		byte ptr [VisCount], 0ffh
		jnz		@hideExit

	;;------------------------------------------------------------
	;; Restore cursor
		pusha
		call		[ResCursorFunc]
		popa
@hideExit:	ret
$HideCursor	endp

;;========================================================================
;; NewIntr33 - new interrupt 0x33 handler
;;========================================================================
NewIntr33	proc		far
	;;------------------------------------------------------------
	;; Test if mouse functions are enabled yet, call original handler
		cmp		ax, EXTENDED_INIT
		jl		@notExtended
		cmp		ax, EXTENDED_INIT+ExtFuncSize
		jg		@notExtended

	;;------------------------------------------------------------
	;; Call extended functions
if 1
		push		bp
		xor		ah, ah
		mov		bp, ax
		shl		bp, 1
		mov		ax, cs:ExtMouseFuncs[bp]
		pop		bp
		call		ax
else
		pusha
		lea		bp, ExtMouseFuncs
		call		doTableCall
		popa
endif
		mov		ax, 0045h
		iret

	;;------------------------------------------------------------
	;; Test if TSR is enabled
@notExtended:	_TestFlag	MouseFlags, SVGA_ENABLED, cs:
		jz		callOld

		;;call		_showCall

	;;------------------------------------------------------------
	;; If function isn't in table, call original handler
		cmp		ax,MouseFuncSize
		jg		callOld

if 1
	;;------------------------------------------------------------
	;; Push all registers
		pusha

	;;------------------------------------------------------------
	;; Get address of mouse function
		push		bp
		mov		bp, ax
		shl		bp, 1
		mov		ax, cs:MouseFuncs[bp]
		pop		bp

	;;------------------------------------------------------------
	;; Call mouse handling function
		mov		bp,sp
		call		ax

	;;------------------------------------------------------------
	;; Pop registers
		popa
else
		pusha
		lea		bp, MouseFuncs
		call		doTableCall
		popa
endif

	;;------------------------------------------------------------
	;; Interrupt return
		iret
callOld:	jmp		dword ptr cs:[OldIntr33]
NewIntr33	endp

if 0
;; Input: BP = offset of table, AX = index
doTableCall	proc		near
		shl		ax, 1
		add		bp, ax
		mov		ax, cs:[bp]

		mov		bp, sp
		call		ax
		ret
doTableCall	endp
endif

;;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;;
;;			Extended mouse functions
;;
;;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

;;========================================================================
;; HgxInit - Initialize enhanced mouse
;; 
;; Input : 
;;   AX = 0x4500
;;   SI = X resolution of mode (320, 640, etc)
;;   DI = Y resolution of mode (200, 480, etc)
;;   BL = Mode type
;;	MODE_P8		Svga 256
;;	MODE_P15	Svga 32k
;;	MODE_P16	Svga 64k
;;	MODE_P24	Svga 24-bit
;;	MODE_PL4	Tweaked 16/Svga 16
;;	MODE_PL8	Tweaked 256
;;	MODE_TEXT	Standard text
;;	MODE_TWKTEXT	Tweaked text
;;   DX = Bytes per scanline for the mode
;;
;; Output: N/A
;;
;;========================================================================
HgxInit		proc		near
		push		ds
		LoadDataSeg	ds

	;; Enable extended functions
		_SetFlag	Mouseflags, SVGA_ENABLED

	;; Set resolution & bytes per line
		mov		[BytesPerLine], dx
		mov		[MsXres], si
		mov		[MsYres], di

	;; Set bits per pixel for this mode type
		xor		bh, bh
		xor		ah, ah
		mov		al, modeBPP[bx]
		mov		[bytes_per_pix], ax

	;; Set mode type
		mov		[curr_mode], bl

	;; Set initialization mode
;;		mov		[init_mode], 3

	;; Get put/restore cursor functions
		lea		si, CursorTable
		lea		ax, @nullProc
		mov		[PutCursorFunc], ax
		mov		[ResCursorFunc], ax
		mov		[SetCursorClrFunc], ax
		mov		[SetCursorBitsFunc], ax
		mov		[CursorOnOffFunc], ax

	;; Check if this is the end of the table
@initLoop:	mov		ax, [si].hwcursor
		cmp		ax, -1
		jz		@initDone

	;; Check if this node is supported on any chip
		cmp		ax, CHIP_ANY
		jz		@chipMatch

	;; Check if this node is supported on this chip
		cmp		ax, [BankAdr]
		jz		@chipMatch
@initNext:	add		si, SIZE modeInfo
		jmp		@initLoop

	;; Check if this node is supported in any mode
@chipMatch:	mov		ax, [si].modetype
		cmp		ax, MODE_ANY
		jz		@modeMatch

	;; Check if this node is supported for this mode
		cmp		ax, bx
		jnz		@initNext

	;; Found a matching mode.. set cursor functions
@modeMatch:	mov		ax, [si].putfunc
		mov		[PutCursorFunc], ax
		mov		ax, [si].resfunc
		mov		[ResCursorFunc], ax
		mov		ax, [si].clrfunc
		mov		[SetCursorClrFunc], ax
		mov		ax, [si].bitsfunc
		mov		[SetCursorBitsFunc], ax
		mov		ax, [si].onofffunc
		mov		[CursorOnOffFunc], ax
		mov		ax, [si].initfunc
		mov		[SetupFunc], ax

	;; Get cursor FG & BG colors
		mov		ax, word ptr [si].bgcolor
		mov		word ptr [cursorBGColor], ax
		mov		ax, word ptr [si].bgcolor[2]
		mov		word ptr [cursorBGColor+2], ax
		mov		ax, word ptr [si].fgcolor
		mov		word ptr [cursorFGColor], ax
		mov		ax, word ptr [si].fgcolor[2]
		mov		word ptr [cursorFGColor+2], ax
		call		[SetCursorClrFunc]

	;; Reset visible flag
@initDone:	mov		byte ptr [VisCount], -1
		pop		ds
		ret
HgxInit		endp

;;========================================================================
;; HgxDeInit - Deinitialize driver to stop using enhancements
;;
;; Input: 
;;   AX = 0x4501
;;
;; Output: N/A
;;
;;========================================================================
HgxDeInit	proc		near
		push		ds
		LoadDataSeg	ds

	;;------------------------------------------------------------
	;; Clear extended functions flag
		_ClrFlag	MouseFlags, SVGA_ENABLED

	;;------------------------------------------------------------
	;; Reset mouse driver
		xor		ax,ax
		CallOldIntr33

		pop		ds
		ret
HgxDeInit	endp

;;========================================================================
;; HgxBank - Sets current SVGA bank for HGXMOUSE
;;
;; Input: 
;;   AX = 0x4503
;;   DL = Bank number
;;
;; Output: N/A
;;
;;========================================================================
HgxBank		proc		near
		mov		cs:[curbk], dl
		ret
HgxBank		endp

;;========================================================================
;; HgxVersion - Get version of installed HGXMOUSE
;;
;; Input :
;;   AX = 0x4504
;;
;; Output:
;;   BH = Major Version
;;   BL = Minor Version
;;   CX = Code segment of TSR
;;   DX = PSP segment of TSR
;;
;;========================================================================
HgxVersion	proc		near
		mov		bh, VERSION_MAJOR
		mov		bl, VERSION_MINOR
		mov		cx, cs
		mov		dx, cs:@psp
		ret
HgxVersion	endp

;;========================================================================
;; HgxCursorFG - Sets the cursor's foreground color
;;
;; Input:
;;   AX = 0x4505
;;   CL = R value
;;   BH = G value
;;   BL = B value
;;
;; Output: N/A
;;
;;========================================================================
HgxCursorFG	proc		near
		push		ds
		LoadDataSeg	ds

	;;------------------------------------------------------------
	;; Hide cursor
		call		$HideCursor

	;;------------------------------------------------------------
	;; Set foreground color
		mov		word ptr [cursorFGColor], bx
		xor		ch, ch
		mov		word ptr [cursorFGColor+2], cx
		call		[SetCursorClrFunc]

	;;------------------------------------------------------------
	;; Redisplay cursor
		call		$ShowCursor

		pop		ds
 		ret
HgxCursorFG	endp

;;========================================================================
;; HgxCursorBG - Sets the cursor's background color
;;
;; Input: 
;;   AX = 0x4506
;;   CL = R value
;;   BH = G value
;;   BL = B value
;;
;; Output: N/A
;;
;;========================================================================
HgxCursorBG	proc		near
		push		ds
		LoadDataSeg	ds

	;;------------------------------------------------------------
	;; Hide cursor
		call		$HideCursor

	;;------------------------------------------------------------
	;; Set background color
		mov		word ptr [cursorBGColor], bx
		xor		ch, ch
		mov		word ptr [cursorBGColor+2], cx
		call		[SetCursorClrFunc]

	;;------------------------------------------------------------
	;; Display cursor
		call		$ShowCursor

		pop		ds
 		ret
HgxCursorBG	endp

;;========================================================================
;; HgxSetSacmap - Sets the sacrifice character map for the text mode
;;		    cursor
;;
;; Input:
;;   AX = 0x4507
;;   ES:BX = sacrifice map
;;
;; Output: N/A
;;
;;========================================================================
HgxSetSacmap	proc		near
		push		ds
		mov		ax, es
		LoadDataSeg	es

	;; Copy sacrifice character map
		mov		si, bx
		lea		di, SacMap
		mov		ds, ax
		mov		cx, 9
		repz		movsb

		pop		ds
		ret
HgxSetSacmap	endp

;;========================================================================
;; HgxBmpCursor - Set bitmap data for the cursor
;;
;; Input: 
;;   AX = 0x4508
;;   BX = horizontal hot spot
;;   CX = vertical hot spot
;;   ES:DX = segment:offset of image data
;;	Format of image data
;;	  DX+0 transparent color
;;	  DX+4 width-1
;;	  DX+6 height-1
;;	  DX+8 image data
;;   SS:BP = address of SimInt structure with input/output register values
;;
;; Output:
;;========================================================================
HgxBmpCursor	proc		near
		push		ds
		LoadDataSeg	ds

		cmp		[curr_mode], MODE_PL4
		jz		@bmpNotSupt
		cmp		[curr_mode], MODE_TEXT
		jz		@bmpNotSupt
		cmp		[curr_mode], MODE_TWKTEXT
		jnz		@bmpIsSupt
@bmpNotSupt:	pop		ds
		ret

	;;------------------------------------------------------------
	;; Hide cursor
@bmpIsSupt:	call		$HideCursor

	;;------------------------------------------------------------
	;; Set hotspot
		mov		[MsHotX], bx
		mov		[MsHotY], cx

	;;------------------------------------------------------------
	;; Set transparency color
		mov		bx, dx
		mov		ax, es:[bx]
		mov		word ptr [transColor], ax
		mov		ax, es:[bx+2]
		mov		word ptr [transColor+2], ax

	;;------------------------------------------------------------
	;; Set cursor size info
		mov		ax, es:[bx+4]
		inc		ax
		mov		[cursorWidth], ax
		mov		[cursorBytes], ax

		mov		cx, es:[bx+6]
		inc		cx
		mov		[cursorHeight], cx
		mul		cx
		mov		[cursorSize], ax
		mov		cx, ax

	;;------------------------------------------------------------
	;; Get size of bitmap based on current mode
		cmp		[curr_mode], MODE_P15
		jz		@bmpCurP15
		cmp		[curr_mode], MODE_P16
		jz		@bmpCurP15
		cmp		[curr_mode], MODE_P24
		jz		@bmpCurP24
		jmp		short @bmpCurP8
@bmpCurP15:	shl		cx, 1
		jmp		short @bmpCurP8
@bmpCurP24:	shl		cx, 2
@bmpCurP8:	push		ds
		mov		ax, es
		mov		ds, ax
		LoadDataSeg	es
		lea		si, [bx+8]

	;;------------------------------------------------------------
	;; Set bitmap data
		lea		di, CurrMousePtr
		shr		cx, 1
		inc		cx
		repz		movsw
		pop		ds

	;;------------------------------------------------------------
	;; Set cursor style
		mov		byte ptr [cursorStyle], BITMAP_CURSOR

	;;------------------------------------------------------------
	;; Display cursor
		call		$ShowCursor

		pop		ds
		ret
HgxBmpCursor	endp

if 0
hgxMsg		HgxMessage<>
messageFile	db	'hgxmouse.msg', 0
messageFd	dw	?

readMessage	proc		near
		OpenFile	messageFile, _O_READ
		jnc		@openMsg
		CreateFile	messageFile, 0
		jnc		@openMsg
		jmp		@endMessage

	;; Message file was opened successfully
@openMsg:	mov		[messageFd], ax

@msgLoop:	ReadFile	messageFd, cs, hgxMsg, SIZE hgxMsg
readMessage	endp

msFuncDescr	dw	msfunc0
		dw	msfunc1
		dw	msfunc2
		dw	msfunc3
		dw	msfunc4
		dw	msfunc5
		dw	msfunc6
		dw	msfunc7
		dw	msfunc8
		dw	msfunc9
		dw	msfuncA
		dw	msfuncB
		dw	msfuncC
		dw	msfuncD
		dw	msfuncE
		dw	msfuncF
		dw	msfunc10
		dw	msfunc11
		dw	msfunc12
		dw	msfunc13
		dw	msfunc14
		dw	msfunc15
		dw	msfunc16
		dw	msfunc17
		dw	msfunc18
		dw	msfunc19
		dw	msfunc1A
		dw	msfunc1B
		dw	msfunc1C
		dw	msfunc1D
		dw	msfunc1E
		dw	msfunc1F
		dw	msfunc20
		dw	msfunc21
		dw	msfunc22
		dw	msfunc23
		dw	msfunc24

msfunc0	db	'0000 Reset',CR,LF,0
msfunc1	db	'0001 ShowCursor',CR,LF,0
msfunc2	db	'0002 HideCursor',CR,LF,0
msfunc3	db	'0003 GetPos',CR,LF,0
msfunc4	db	'0004 SetPos',CR,LF,0
msfunc5	db	'0005 GetPress',CR,LF,0
msfunc6	db	'0006 GetRelease',CR,LF,0
msfunc7	db	'0007 SetHLim',CR,LF,0
msfunc8	db	'0008 SetVLim',CR,LF,0
msfunc9	db	'0009 SetShape',CR,LF,0
msfuncA	db	'000A SetTextPtr',CR,LF,0
msfuncB	db	'000B ReadCounter',CR,LF,0
msfuncC	db	'000C SetHandler',CR,LF,0
msfuncD	db	'000D LightpenOn',CR,LF,0
msfuncE	db	'000E LightpenOff',CR,LF,0
msfuncF	db	'000F SetRatio',CR,LF,0
msfunc10 db	'0010 SetExclude',CR,LF,0
msfunc11 db	'0011',CR,LF,0
msfunc12 db	'0012',CR,LF,0
msfunc13 db	'0013 SetThreshold',CR,LF,0
msfunc14 db	'0014 SwapHandlers',CR,LF,0
msfunc15 db	'0015 GetSaveSize',CR,LF,0
msfunc16 db	'0016 SaveState',CR,LF,0
msfunc17 db	'0017 RestoreState',CR,LF,0
msfunc18 db	'0018 SetAltHandler',CR,LF,0
msfunc19 db	'0019 GetAltHandlerAddr',CR,LF,0
msfunc1A db	'001A SetSensitivity',CR,LF,0
msfunc1B db	'001B GetSensitivity',CR,LF,0
msfunc1C db	'001C SetIntrRate',CR,LF,0
msfunc1D db	'001D SetPointerPage',CR,LF,0
msfunc1E db	'001E GetPointerPage',CR,LF,0
msfunc1F db	'001F DisableDriver',CR,LF,0
msfunc20 db	'0020 EnableDriver',CR,LF,0
msfunc21 db	'0021 ResetDriver',CR,LF,0
msfunc22 db	'0022 SetLanguage',CR,LF,0
msfunc23 db	'0023 GetLanguage',CR,LF,0
msfunc24 db	'0024 GetMouseInfo',CR,LF,0
msfuncUnk db	'Unknown',CR,LF,0

endval	db	CR,LF,CR,LF,0
regval	db	'XX 0000  ',0

reportSize	dw	?
reportFD	dw	?
reportName	db	'hgxmouse.dmp',0

writeHex	proc		near
		xchg		ah, al
                mov             [di], ax
                add             di, 3
		mov		cx, 4
hexLoop:	rol		dx, 4
		mov		al, dl
		mov		ah, '0'
		and		al, 0fh
		cmp		al, 0ah
		jl		notAlphaHex
		mov		ah, 'A'
		sub		al, 0ah
notAlphaHex:	add		ah, al
		mov		cs:[di], ah
		inc		di
		loop		hexLoop
		ret
writeHex	endp

_showCall	proc		near
@doShowCall:	pusha
		mov	bp, sp

		push		es
		push		ds
		LoadDataSeg	ds
		LoadDataSeg	es

		mov	si, ax
		cmp	si, 024h
		jge	@overFun
		shl	si, 1
		mov	si, msFuncDescr[si]
		jmp	short @showOpen
@overFun:	lea	si, msfuncUnk

	;; Open report file
@showOpen:	OpenFile	reportName, _O_WRITE
		jnc		@openSuccess

	;; Create report file
		CreateFile	reportName, 0
		jnc		@openSuccess
		jmp		@endShowCall

	;; Open/Create was successful
@openSuccess:	mov		[reportFD], ax

	;; Get length of text
		xor		al, al
		mov		di, si
		mov		cx, 0ffffh
		repnz		scasb
		neg		cx
		dec		cx
		mov		[reportSize], cx

	;; Seek to end of file
		SeekFile	reportFD, 0, 0, _SEEK_END

	;; Write data to file
		WriteFile	reportFD, ds, si, reportSize

        ;; Write AX
                mov             ax,'AX'
		lea		di, regVal
		mov		dx, [bp+RealAX]
		call		writeHex
		WriteFile	reportFD, ds, regVal, 9

        ;; Write BX
                mov             ax,'BX'
		lea		di, regVal
		mov		dx, [bp+RealBX]
		call		writeHex
		WriteFile	reportFD, ds, regVal, 9

        ;; Write CX
                mov             ax,'CX'
		lea		di, regVal
		mov		dx, [bp+RealCX]
		call		writeHex
		WriteFile	reportFD, ds, regVal, 9

        ;; Write DX
                mov             ax,'DX'
		lea		di, regVal
		mov		dx, [bp+RealDX]
		call		writeHex
		WriteFile	reportFD, ds, regVal, 9

        ;; Write SI
                mov             ax, 'SI'
		lea		di, regVal
		mov		dx, [bp+RealSI]
		call		writeHex
		WriteFile	reportFD, ds, regVal, 9

        ;; Write DI
                mov             ax, 'DI'
		lea		di, regVal
		mov		dx, [bp+RealDI]
		call		writeHex
		WriteFile	reportFD, ds, regVal, 9

		WriteFile	reportFD, ds, endVal, 4

		CloseFile	reportFD

@endShowCall:	pop		ds
		pop		es
		popa
		ret
_showCall	endp
endif

	db	'ENDRESIDENT'
endResidentCode:

ifdef HGXMOUSE_TSR
;;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;;			Begin transient code
;;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
_main		proc		near
		mov		ax, cs
		mov		ds, ax
		mov		@psp, es

		Print		Copyright

	;;------------------------------------------------------------
	;; Detect card type
		call		whichvga

	;;------------------------------------------------------------
	;; Get command-line argument list
		call		_setargv
		call		_parseArgs
		_TestFlag	argFlag, OPT_USAGE
		jz		@notUsage
		jmp		_abort
@notUsage:	_TestFlag	argFlag, OPT_DETECT
		jz		@notDetect

	;;------------------------------------------------------------
	;; Print card type
		Print		chipTypeMsg
		PrintIndex	[chipType]
		Print		newline
		jmp		_abort

@notDetect:	_TestFlag	argFlag, OPT_UNINSTALL
		jz		@noUnit
		call		uninstall
		jmp		_abort

	;;------------------------------------------------------------
	;; Check if mouse driver is installed
@noUnit:	xor		ax, ax
		int		033h
		cmp		ax, 0ffffh
		jz		@mouseInstalled
		jmp		@noMouse

@mouseInstalled:
	;;------------------------------------------------------------
	;; Test to make sure the driver hasn't already been installed
		mov		ax, EXTENDED_VERSION
		int		033h
		cmp		ax, 045h
		jnz		@saveVect
		jmp		@alreadyLoaded

	;;------------------------------------------------------------
	;; Save old int 33 handler
@saveVect:	push		ds
		GetIntVect	033h
		mov		word ptr [OldIntr33], bx
		mov		word ptr [OldIntr33+2],es

	;;------------------------------------------------------------
	;; Check for signature string
		mov		di, bx
		sub		di, offset NewIntr33 - offset Signature
		mov		ax, cs
		mov		ds, ax
		lea		si, Signature
		mov		cx, sigSize
		cld
		repz		cmpsb
		pop		ds
		jcxz		@alreadyLoaded

	;;------------------------------------------------------------
	;; Hook vectors
		SetIntVect	033h, cs, NewIntr33

	;;------------------------------------------------------------
	;; Free environment
		mov		es, @psp
		mov		bx, es:[02ch]
		mov		es, bx
		mov		ah, 049h
		int		021h

	;;------------------------------------------------------------
	;; Display installed message
		push		ds
		mov		ax, cs
		mov		ds, ax
		Print		InstalledMsg
		pop		ds

	;;------------------------------------------------------------
	;; do TSR
		xor		al,al
		lea		dx, endResidentCode
		add		dx, PSPSize+15
		shr		dx, 4
		mov		ah, 031h
		int		021h
	;; Program has exited

	;;------------------------------------------------------------
	;; Program was already loaded
@alreadyLoaded:	Print		alreadyLoaded
		jmp		short _abort

	;;------------------------------------------------------------
	;; No mouse installed
@noMouse:	Print		mouseNotLoaded
		jmp		short _abort
_main		endp

;;========================================================================
;; Abort program
;;========================================================================
_abort		proc		near
		mov		ah, 04ch
		mov		al, 1
		int		021h
_abort		endp

;;=================================================================================
;; Uninstall driver
;;========================================================================
uninstall	proc		near
	;;------------------------------------------------------------
	;; Check if int 0x33 has been chained
		mov		ax, EXTENDED_VERSION
		int		033h
		cmp		ax, 045h
		jnz		@notLoaded

	;;------------------------------------------------------------
	;; DX = @psp, CX = code seg of HGXMOUSE
		mov		si, dx
		mov		di, cx

	;;------------------------------------------------------------
	;; Get current int 0x33 vector
		GetIntVect	033h
		mov		ax, es
		cmp		ax, di
		jnz		@cantUnload
;;		cmp		bx, offset NewIntr33
;;		jnz		@cantUnload

	;; Release memory
		mov		es, si
		mov		ah, 049h
		int		021h
		jc		@cantFreeMem

	;; Reset int 0x33 vector to original value
		mov		es, di
		SetIntVect	033h, es:OldIntr33
		Print		uninstalledMsg
		ret

@notLoaded:	Print		notLoadedMsg
		jmp		_abort

	;; Can't unload driver (another chained TSR)
@cantUnload:	Print		cantUnloadMsg
		jmp		_abort

	;; Can't release memory block
@cantFreemem:	Print		deallocError
		ret
uninstall	endp

;;========================================================================
;; Parse command line arguments
;;========================================================================
_parseArgs	proc		near
		push		es
		mov		cx, [argc]
		xor		bx, bx
		jcxz		@endParse
		mov		es, @psp
@parseLoop:	mov		si, argv[bx]
		cmp		byte ptr es:[si], '-'
		jz		@isOpt
		cmp		byte ptr es:[si], '/'
		jz		@isOpt
		add		bx, 02h
		loop		@parseLoop
@endParse:	pop		es
		ret

@isOpt:		mov		ax, es:[si+1]
		xchg		ah, al
		test		al, al
		jnz		@isInvalid

		cmp		ah, 'h'
		jz		@isHelp
		cmp		ah, '?'
		jz		@isHelp
		cmp		ah, 'u'
		jz		@isUninstall
		cmp		ah, 'd'
		jz		@isDetect
		cmp		ah, 'z'
		jz		@isDebug
		cmp		ah, 'n'
		jz		@isNoHWCursor
@isInvalid:	_SetFlag	argFlag, OPT_USAGE
		Print		InvalidSwitch
		lea		di, invalidMsg
		push		ds
		push		es
		mov		bx, ds
		mov		ax, es
		xchg		ax, bx
		mov		es, ax
		mov		ds, bx
@invalidLoop:	lodsb
		stosb
		test		al, al
		jnz		@invalidLoop
		mov		byte ptr ds:[di-1], '$'
		Print		invalidMsg
		Print		newline
		pop		es
		pop		ds
		jmp		@endParse

@isHelp:	_SetFlag	argFlag, OPT_USAGE
		Print		UsageMsg
		jmp		@endParse

@isUninstall:	_SetFlag	argFlag, OPT_UNINSTALL
		Print		UninstallMsg
		jmp		@endParse

@isDetect:	_SetFlag	argFlag, OPT_DETECT
		Print		DetectMsg
		jmp		@endParse
@isDebug:       _SetFlag        argFlag, OPT_DEBUG
                Print           DebugMsg
                jmp             @endParse
@isNoHwCursor:  _SetFlag        argFlag, OPT_NOHWCURSOR
                Print           HwCursorMsg
                jmp             @endParse
_parseArgs	endp

;;========================================================================
;; Get command-line arguments
;; Return: argv[] contains pointers to arguments...
;;	   DI, argc contain number of arguments
;;========================================================================
;; Test for end of argument marker... SPACE, TAB or ENTER
isTerminator	proc		near
		cmp		al, ' '
		jz		isTerm
		cmp		al, 09h
		jz		isTerm
		cmp		al, CR
		jz		isTerm
		clc
		ret
isTerm:		stc
		ret
isTerminator	endp

_setargv	proc		near
		push		es
		mov		es, @psp

		xor		cx,cx
		mov		cl, byte ptr es:[080h]	;; arg length
		inc		cx

		mov		si, 081h	;; argv buf
		xor		di, di		;; argc
		mov		bx, 1		;; new arg found

@argvLoop:	lods		byte ptr es:[si]
		ToLower		al
		mov		byte ptr es:[si-1], al
		call		isTerminator
		jnc		lowerIt
		jcxz		lowerIt
		mov		byte ptr es:[si-1], 0

	;; Set argument start marker
		mov		bx, 1
@notArg:	loop		@argvLoop
		jmp		short @endArgs

lowerIt:	test		bx, bx
		jz		@notArg

	;; Set start of argument
		lea		bx, [si-1]
		mov		argv[di], bx
		add		di, 02h
		xor		bx, bx
		loop		@argvLoop

@endArgs:	shr		di,1
		mov		argc, di
		pop		es
		ret
_setargv	endp

;;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;;			Begin transient data
;;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

CopyrightMsg	MACRO	VER_maj, VER_min
Copyright	db	CR, LF
		db	'HGXMOUSE - The MultiMode Mouse Driver  Version &VER_maj.&VER_min', CR, LF
		db	'Copyright (c) Jordan Hargraphix 1994.  All Rights Reserved', CR, LF, CR,LF, EOS
ENDM
CopyrightMsg	%VERSION_MAJOR, %VERSION_MINOR

;; Argc/Argv parameters
argc		dw	?
argv		dw	128 dup(?)
argFlag		db	?
invalidMsg	db	128 dup(?)

cardTypeMsg	db	'Card type: ', EOS
chipTypeMsg	db	'Chip type: ', EOS
newline		db	CR, LF, EOS

notLoadedMsg	db	'HGXMOUSE Mouse driver was not installed.',CR,LF,EOS
alreadyLoaded	db	'HGXMOUSE Mouse driver was already installed.',CR,LF,EOS
uninstalledMsg	db	'HGXMOUSE Mouse driver was uninstalled.',CR,LF,EOS
cantUnloadMsg	db	'HGXMOUSE Mouse driver could not be unloaded.',CR,LF,EOS
deallocError	db	'HGXMOUSE Memory for mouse driver could not be freed.',CR,LF,EOS
mouseNotLoaded	db	'Mouse driver is not installed.',CR,LF,EOS
UsageMsg	db	"Usage: hgxmouse [-?hdun]",CR,LF
		db	"   -?, -h : This help screen", CR, LF
		db	"   -d     : Detect card only, don't install", CR, LF
		db	"   -u     : Uninstall driver", CR, LF
		db	"   -n     : Don't use hardware cursor", CR, LF
		db	CR, LF, EOS
UninstallMsg	db	"Uninstalling HGXMOUSE.", CR, LF, CR, LF, EOS
DetectMsg	db	"Detecting chipset.", CR, LF, CR, LF, EOS
InvalidSwitch	db	"HGXMOUSE: Invalid switch - ", EOS
InstalledMsg	db	"HGXMOUSE TSR was successfully installed.", CR, LF, EOS
DebugMsg        db      "Using debug code", CR, LF, EOS
HwCursorMsg     db      "Hardware cursor disabled", CR, LF, EOS

endif		;; HGXMOUSE_TSR

;;ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
;;			Begin transient data
;;‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹

cardType	dw	?
chipType	dw	?
svga_OldReg	label	byte
		dw	?

;; Takes place of video mode list.. text name of chip/card type
chip_Null	db	'Unknown',EOS
chip_ATI1	db	'ATI rev 1',EOS
chip_ATI2	db	'ATI rev 2',EOS
chip_ATIGUP	db	'ATI Graphics Ultra', EOS
chip_AheadA	db	'Ahead A SuperVGA', EOS
chip_AheadB	db	'Ahead B SuperVGA', EOS
chip_Chips451	db	'Chips&Technologies 82c451 SuperVGA',EOS
chip_Chips452	db	'Chips&Technologies 82c452 SuperVGA',EOS
chip_Chips453	db	'Chips&Technologies 82c453 SuperVGA',EOS
chip_Everex	db	'Everex SuperVGA', EOS
chip_Genoa	db	'Genoa SuperVGA', EOS
chip_Oak87	db	'Oak 087 SuperVGA', EOS
chip_Oak77	db	'Oak 067/077 SuperVGA', EOS
chip_Paradise	db	'Paradise SuperVGA', EOS
chip_Trident	db	'Trident SuperVGA', EOS
chip_Trident88	db	'Trident 8800 SuperVGA', EOS
chip_Trident89	db	'Trident 8900/9000 SuperVGA', EOS
chip_IITAGx	db	'IITAGX', EOS
chip_Video7	db	'Video7 SuperVGA', EOS
chip_Tseng3 	db	'Tseng ET3000 SuperVGA', EOS
chip_Tseng4	db	'Tseng ET4000 SuperVGA', EOS
chip_Tseng4_W32	db	'Tseng ET4000/W32 SuperVGA', EOS
chip_NCR	db	'NCR SuperVGA', EOS
chip_S3		db	'S3 SuperVGA', EOS
chip_Acumos	db	'Acumos SuperVGA', EOS
chip_AL2101	db	'Avance Logic AL2101 SuperVGA', EOS
chip_MXIC	db	'MXIC SuperVGA', EOS
chip_RealTek	db	'RealTek SuperVGA', EOS
chip_Cirrus	db	'Cirrus', EOS
chip_Cirrus54	db	'Cirrus 54xx SuperVGA', EOS
chip_Cirrus64	db	'Cirrus 64xx SuperVGA', EOS
chip_Vesa	db	'VESA SuperVGA', EOS
chip_Compaq	db	'Compaq', EOS
chip_HMC	db	'HMC', EOS
chip_UMC	db	'UMC', EOS
chip_P2000	db	'Primus 2000 SuperVGA', EOS
chip_Weitek	db	'Weitek', EOS

EndCode		HgxText

end

