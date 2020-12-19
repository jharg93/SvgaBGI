MaxStack	EQU	300

STRAIGHT	EQU	4
DIAGONAL	EQU	0

;; Mode types for mouse driver
MODE_P8		EQU	0
MODE_P15	EQU	1
MODE_P16	EQU	2
MODE_P24	EQU	3
MODE_PL4	EQU	4
MODE_PL8	EQU	5
MODE_TEXT	EQU	6
MODE_TWKTEXT	EQU	7

HAVE_VESA	EQU	00000001b
SLOW_LOGICAL	EQU	00000010b

;; _SetFlag	Sets a bit in a byte flag
_SetFlag	MACRO	__flag,__val
		or	byte ptr [__flag], __val
ENDM

;; _ClrFlag	Clears a bit in a byte flag
_ClrFlag	MACRO	__flag, __val
		and	byte ptr [__flag], not __val
ENDM

;; _TestFlag	Tests a bit in a byte flag
_TestFlag	MACRO	__flag,__val
		test	byte ptr [__flag], __val
ENDM

;; LoadDataSeg - Load a segment with the value of the data segment
;; DS = CS for BGI v2.0 code
LoadDataSeg	MACRO	__segment
	IF	BGIVERSION LT 3
		push	cs
		pop	__segment
	ELSE
		mov	__segment,cs:[alias]
	ENDIF
ENDM

;;======================================================================
;; 			Entry Header for BGI v3.0
;;======================================================================
BGI30Entry	MACRO				;; BGI v3.0 entry code
BgiEntry	proc	far
		push	ds
		mov	ds,cs:[alias]
		cld
		push	bp
		call	word ptr [DDOVEC+si]
		pop	bp
		pop	ds
		ret
BgiEntry	endp
verID		db	BGIVERSION
ALIAS		dw	0
ENDM

;;======================================================================
;; 			Entry Header for BGI v2.0
;;======================================================================
BGI20Entry	MACRO			;; BGI v2.0 entry code
BgiEntry	proc	far
		push	ds
		push	cs
		pop	ds
		cld
		push	bp
		call	word ptr [si+DDOVEC]
		pop	bp
		pop	ds
		ret
BgiEntry	endp
		db	'CB'
		db	0
verID		db	BGIVERSION
ENDM

;; Wait for Display Enable bit to clear
WaitForEnable	MACRO
		local	_waitDE
		mov	dx,03dah
_waitDE:	in	al,dx
		test	al,1
		jnz	_waitDE
ENDM

;; Wait for Vertical Retrace bit to clear
WaitForRetrace	MACRO
		local	_waitVRz
		local	_waitVRnz
		mov	dx,03dah
_waitVRnz:	in	al,dx
		test	al,8
		jnz	_waitVRnz
_waitVRz:	in	al,dx
		test	al,8
		jz	_waitVRz
ENDM

;; Enable HGXMOUSE mouse support
Enable_Mouse	MACRO	modetype
		mov	si, [xsiz]
		mov	di, [ysiz]
		inc	di
		mov	dx, [xbytes]
		mov	bl, modetype
		mov	ax, 4500h
		int	033h
ENDM

;; Disable mouse support
Disable_Mouse	MACRO
		mov	ax, 4501h
		int	033h
ENDM

;; Set card type macro
SetCardType	MACRO	__card
		mov	CurrVidModes, offset &__card&Modes
ENDM

;; Set chip/bankswitch macro
SetChipType	MACRO	__chip
		mov	BankAdr, offset $&__chip&
ENDM

;; Set display start macro
SetPageType	MACRO	__chip
		mov	PageAdr, offset $&__chip&_page
ENDM

;; Clears a mode from the mode table
ClearMode   MACRO   __clrmode, __modes, __idx
    IF BGIVERSION GE 1
        IFDIF <__idx>, <si>
            mov     word ptr [__modes + __idx*4], 0
            mov     word ptr [__modes + __idx*4 + 2], 0        
        ELSE
            shl     si, 2
            mov     word ptr [si + __modes], 0
            mov     word ptr [si + __modes + 2], 0
        ENDIF
    ENDIF
ENDM

;; Sets the bytes per line value for a mode
SetBytesPerLine	MACRO	__clrmode, __idx, __value
	IF BGIVERSION GE 1
	 IF COLORMODE EQ __clrmode
	  IFDIF	<__idx>, <si>
		mov	[BytesPerLine+__idx*2], __value
	  ELSE
		shl	si, 1
		mov	[BytesPerLine+si], __value
	  ENDIF
	 ENDIF
	ENDIF
ENDM

;; Loads the text video name (svga or vesa)
LoadModeName	MACRO
		local	@noHaveVesa
		mov		bx, ModeNameTable[si]
	IF	USEVESA	EQ	1
		_TestFlag	cardFlags, HAVE_VESA
		jz		@noHaveVesa
		mov		bx, ModeVNameTable[si]
@noHaveVesa:
	ENDIF
ENDM

;; Loads the video mode table (svga or vesa)
LoadVesaModeTable	MACRO
		local	@noHaveVesa
	IF	USEVESA	EQ	1
		_TestFlag	cardFlags, HAVE_VESA
		jz		@noHaveVesa
		mov		CurrVidModes,offset VesaModes
		mov		BankAdr,offset $vesa
		mov		PageAdr,offset $vesa_page
@noHaveVesa:
	ENDIF
ENDM

;; Adds the segment increment value to a segment
IncrSegment	MACRO	__segment
		LOCAL	@endIncr
	;; Add increment to segment
		mov	ax, __segment
		add	ax, SelectorInc
		mov	__segment, ax
@endIncr:
ENDM

TestXBank	MACRO	__reg, __addr
		local	@noCross
		cmp	__reg, __addr
		jnz	@noCross
		inc	dl
		call	newbank
		dec	dl
@noCross:
ENDM

;; Stack structure for PUSHA instruction
PushaStruc struc
  RealDI	DW	0
  RealSI	DW	0
  RealBP	DW	0
  RealXX	DW	0
  RealBX	DW	0
  RealDX	DW	0
  RealCX	DW	0
  RealAX	DW	0
PushaStruc ends

;; Structure for a DPMI simulate real mode interrupt call
SimIntStruc struc
  RealEDI	DD 0
  RealESI	DD 0
  RealEBP	DD 0
  RealESP	DD 0
  RealEBX	DD 0
  RealEDX	DD 0
  RealECX	DD 0
  RealEAX	DD 0
  RealFlags	DW 0
  RealES	DW 0
  RealDS	DW 0
  RealFS	DW 0
  RealGS	DW 0
  RealIP	DW 0
  RealCS	DW 0
  RealSP	DW 0
  RealSS	DW 0
SimIntStruc ends

;; BGI Device Information Table
Status	struc
stat		db	0		;; Status code
devtyp		db	0		;; Device type - always 0 for graphics adapters
xres		dw	?		;; Device x-resoultion
yres		dw	?		;; Device y-resolution
xefres		dw	?		;; Device effective x-resolution (usually the same as xres)
yefres		dw	?		;; Device effective y-resolution (usually the same as yres)
xinch		dw	9000		;; Device width in inches
yinch		dw	7000		;; Device height in inches
aspec		dw	?		;; Device aspect ratio
		db	08h		;; Text width in pixels
		db	TEXTBYTES	;; Text height in pixels
		db	90h		;; ??? I don't know what these are
		db	90h		;; ???
Status	ends

;; Include port macros
INCLUDE 	macros.inc
