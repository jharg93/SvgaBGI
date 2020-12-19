;; SuperVGA 16 Colour BGI Driver Source
;;
;; Version:	$Revision:   1.21  $
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
;;  $Log:   C:/svga/rcs/svga16.asv  $
;  
;     Rev 1.21   30 Aug 1994  1:44:42   JORDAN
;  vect speedups?
;  
;     Rev 1.20   23 Aug 1994  0:05:28   JORDAN
;  
;     Rev 1.19   20 Jul 1994 22:08:28   JORDAN
;  Added support for HGXMOUSE driver
;;  
;;    Rev 1.18   09 Jun 1994 23:46:52   JORDAN
;; Added IncrSegment macro to increment segment for getimage/putimage.
;; 
;;    Rev 1.17   07 Jun 1994 23:48:10   JORDAN
;; 
;;    Rev 1.16   14 May 1994 19:35:16   JORDAN
;; MULTITEXT version
;; 
;;    Rev 1.15   09 Apr 1994 12:20:42   JORDAN
;; Increased line drawing/bar filling speed slightly
;;
.186

	IFNDEF	BGIVERSION
BGIVERSION	EQU	2		;; BGI revision version
					;; 2 for most BC/TC and BP/TP
					;; 3 for BP7.0 protected mode
	ENDIF
COLORMODE	EQU	16		;; 16 color driver
USEVESA		EQU	1		;; Use VESA if it's detected
MaxMode		EQU	7		; Maximum mode number supported
;; Change here for font used:
;;    8 = 8x8 font
;;   14 = 8x14 font
;;   16 = 8x16 font
TEXTBYTES	EQU	8

INCLUDE		common.inc		; Common defines

	IF BGIVERSION LT 3

.model	SMALL
.CODE

	assume	cs:_TEXT,ds:_TEXT,ss:_TEXT

;; BGI v2.0 entry code
	BGI20Entry

	ELSE

_TEXT	SEGMENT	PARA	PUBLIC	'CODE'

	assume	cs:_TEXT, ds:_DATA

;; BGI v3.0 entry code
	BGI30Entry

	ENDIF

;; EMULATE - Far call to emulation routines in BGI kernel
;; This area is updated by GRAPH at loadtime
EMULATE:	ret
		dw	0,0

;; Dummy routines for unimplemented procedures
;; Near return
NotImpNear	proc	near
		ret
NotImpNear	endp

;; Far return
NotImpFar	proc	far
		ret
NotImpFar	endp


;;====================================================================
;;			Main code begins
;;====================================================================
;; Restore default EGA/VGA regs
restregs:	push	dx
	;; outpw SC_INDEX, 0f02h
		mov	dx,SC_INDEX
		mov	ax,0f02h
		out	dx,ax
	;; outpw GC_INDEX, 00h
		mov	dx,GC_INDEX
		xor	ax,ax
		out	dx,ax			;; Reset Set/Reset reg
	;; outpw GC_INDEX, 01h
		inc	ax
		out	dx,ax			;; Reset Enable S/R reg.
	;; outpw GC_INDEX, 03h
		mov	al,3
		out	dx,ax			;; Data/Func def.
	;; outpw GC_INDEX, 05h
		mov	al,05h
		out	dx,ax			;; Default Mode value
	;; outpw GC_INDEX, ff08h
		mov	ax,0ff08h
		out	dx,ax			;; Bit Mask
		pop	dx
		xor	ax,ax
		ret

;--------------------------------------------------------------------
; Calculate screen address
;; Input: 
;;	AX - X coordinate
;;	BX - Y coordinate
;; Output:
;;	BX - Offset
;;	DL - Bank #

CalcAddr:	mov	es,VidMem
		xchg	ax,bx
		shr	bx,3
		mul	xbytes
		add	bx,ax
		adc	dl,0
		add	bx,word ptr PageOfs
		adc	dx,word ptr [PageOfs+2]
		ret

;;====================================
;; Input:
;;   AX = X
;;   BX = Y
;;====================================
CalcAddr640:	mov	es,VidMem
		mov	dx, bx
		shl	bx, 4
		shl	dx, 6
		shr	ax, 3
		add	bx, dx
		add	bx, ax
		xor	dx, dx
		add	bx, word ptr [PageOfs]
		adc	dx, word ptr [PageOfs+2]
		ret

;--------------------------------------------------------------------
;;INSTALL - Installs the driver

install:	mov	ah, cl			;; Save upper bits of mode #
		and	cl, 7fh

		cmp	al,1
		jnz	notmodequery
		mov	cx,MaxMode
		ret
notmodequery:	cmp	cl,MaxMode-1
		jle	TopMode
		mov	cl,MaxMode-1
TopMode:	LoadDataSeg	es			;; Macro
		xor	ch,ch
		mov	si,cx
		shl	si,1
		test	al, al
		jz	notmodename

	;; Load mode text name
		LoadModeName
		ret
notmodename:	mov	curr_mode,cl
		push	es
		push	si
		push	ax
		call	whichvga	;; Detect which VGA is installed
		pop	ax

	;; Test if mode number > 128, if so don't initialize as a VESA mode
		test	ah, 080h
		jnz	@noVesaMode
		mov	ax,CurrVidModes
		mov	OrigVidModes,ax
		LoadVesaModeTable
@noVesaMode:	mov	ax,01130h	;; Load pointer to the ROM 
if TEXTBYTES EQ 14
		mov	bh,2		;; 8x14 font
ENDIF
if TEXTBYTES EQ 16
		mov	bh,6		;; 8x16 font
ENDIF
if TEXTBYTES EQ 8
		mov	bh,3		;; 8x8 font
ENDIF
		int	10h
		mov	textofs,bp
	IF	BGIVERSION GE 3
		mov	es,SEGC000		;; Evil hack... Couldn't get DPMI
						;; to make the actual segment readable
	ENDIF
		mov	textseg,es
		pop	si
		pop	es
		mov	bx,[StatTable+si]	;; Get address of DIT
		mov	ax,[bx+yefres]
		mov	ysiz,ax
		mov	ax,[bx+xefres]
		inc	ax
		mov	xsiz,ax

	;; Get xbytes from BytesPerLine table
		mov	al,curr_mode
		xor	ah,ah
		mov	si,ax
		shl	si,1
		mov	ax,BytesPerLine[si]
		mov	xbytes,ax

		push	bx
		push	es
		call	setPageSize
		call	GetInitMode
		pop	es
		pop	bx
		jnc	InstallOk
		mov	byte ptr [bx],-10	;; Invalid Mode
InstallOK:	ret

;---------------------------------------------------------------------
;; GetInitMode - returns mode numbers
;;  Return: AX,BX - mode values
;;	CF = 0 - Mode is supported
;;	CF = 1 - Mode is not supported
GetInitMode:	mov	cl,curr_mode
		xor	ch,ch
		mov	si,cx
		cmp	si,3
		jg	init1
		shl	si,1
		mov	ax,[Modes+si]
		clc
		ret

init1:		sub	si,4			;; Svga/VESA modes
		shl	si,2
		add	si,CurrVidModes
		mov	ax,[si]			;; Retrieve graphics mode
		mov	bx,[si+02]		;; number from table
		cmp	CurrVidModes, offset VesaModes
		jz	initvesa
		or	ax, bx
		jz	ModeNotOk
ModeOk:		clc
		ret

initvesa:	mov	Vesa_granlrty,1		;; VESA initialization
		mov	cx,bx			;; VESA mode number
		mov	ax,04f01h
		lea	di,Xvals
		call	doVesaInt
		jc	ModeNotOk

	;; Get Bytes per line value
		mov	ax, [Xvals+10h]
		mov	xbytes, ax

		mov	cx,[Xvals+4]
		cmp	cl,1			;; make sure 64k banksize
		jb	ModeNotOk
		mov	ax,64
		div	cl
		mov	Vesa_granlrty,al	;; Set window size
		mov	ax,04f02h
		clc
		ret

ModeNotOk:	call	post
		stc
		ret

;; Calculates the size of each video page for this mode
setPageSize:	mov	ax, xbytes
		mul	ysiz		;; DX:AX = bytesPerLine*yres

	;; Round to next 8k
		add	ax, 01fffh
		adc	dx, 0
		and	ax, 0e000h
		cmp	ax, 02000h
		jz	donePageSize

	;; Round to next 16k
		add	ax, 03fffh
		adc	dx, 0
		and	ax, 0c000h
		cmp	ax, 04000h
		jz	donePageSize

	;; Round to next 32k
		add	ax, 07fffh
		adc	dx, 0
		and	ax, 08000h
		cmp	ax, 08000h
		jz	donePageSize

	;; Round to next 64k
		add	ax, 0ffffh
		xor	ax, ax

donePageSize:	mov	word ptr PageSize[0], ax
		mov	word ptr PageSize[2], dx
		ret

;---------------------------------------------------------------------
;;INIT - Changes into graphics mode
;; ES:BX=Device Information Table

init:		call	GetInitMode
		jc	InitXit
		int	010h

		mov	byte ptr curbk,-1
		Enable_Mouse	MODE_PL4
	IF	BGIVERSION GE 3
		mov	ax,SEGA000
		mov	VidMem,ax
	;; Get selector increment
		mov	ax, 3
		int	031h
		mov	SelectorInc, bx
	ENDIF
InitXit:	ret

;---------------------------------------------------------------------
;;POST - Exit from graphics mode

post:		Disable_Mouse			;; Macro
		ret

;---------------------------------------------------------------------
;;CLEAR - Clears the screen

clear:		push	word ptr fillpatnum	;; Save old fillpattern
		xor	ax,ax
		xor	bx,bx			;; 0,0
		mov	word ptr fillpatnum,ax	;; Empty fill pattern, color
		mov	cx,xsiz			;; Maxx, Maxy
		dec	cx
		mov	dx,ysiz
		call	patbar
		pop	word ptr fillpatnum	;; Restore fillpattern
		ret

;---------------------------------------------------------------------
;;MOVE - Moves the current draw pointer to X,Y
;; AX=New X coordinate
;; BX=New Y coordinate

move:		mov	cp_x,ax
		mov	cp_y,bx
		ret

;---------------------------------------------------------------------
;;DRAW - Draws line from CP to X,Y
;; AX=End X coordinate
;; BX=End Y coordinate

draw:		mov	cx,cp_x
		mov	dx,cp_y
		mov	cp_x,ax		;; Update drawing pointer
		mov	cp_y,bx

;---------------------------------------------------------------------
;;VECT - Draws line from X1,Y1 to X2,Y2
;; AX=Start X coordinate
;; BX=Start Y coordinate
;; CX=End X coordinate
;; DX=End Y coordinate
;;
;;  Bresenhams line drawing algorithm from Bluebook of Assembly Routines for 
;;  the IBM PC & XT, with minor modifications :jph
;;  Other portions from Programmer's Guide to the EGA & VGA cards (2nd edition)

;;-----------------------------------------
;; Optimized vertical lines
vert_line:	cmp	dx,bx
		jge	vlstory
		xchg	bx,dx
vlstory:	sub	dx,bx
		mov	di,dx
		mov	cl,al			;; lower bits of X coordinate

		call	CalcAddr		;; Calculate address

		mov	ch,080h
		and	cl,07h
		shr	ch,cl			;; Bitmap position
		mov	cl,dl			;; save bank #
	;; Setup VGA registers
		mov	dx,GC_INDEX
		mov	ah,linecolour
		xor	al,al			;; set color mode
		out	dx,ax
		mov	ax,0f01h
		out	dx,ax			;; setup sequencer
		mov	al,08h
		mov	ah,ch
		out	dx,ax			;; setup write bitmap
		cmp	writemode,1
		jnz	@noVertXor
		mov	ax,01803h
		out	dx,ax
@noVertXor:	mov	bp, curr_linestyle
		mov	dl,cl
runloop:	cmp	dl,curbk		;; Check for bank switch
		jnz	VertLinChg
novrun:		ror	bp,1			;; Rotate line pattern
		jnc	novplot
		xchg	ah,es:[bx]		;; Store value
novplot:	add	bx,xbytes
		adc	dl,0
		dec	di
		jns	runloop
		jmp	restregs

VertLinChg:	call	newbank
		jmp	short novrun

;;-------------------------------------------------------
vect:		mov	bp, curr_linestyle
		mov	tmp_linestyle,bp
		cmp	ax,cx
		jz	vert_line
		jle	vok
		xchg	ax,cx
		xchg	bx,dx
vok:
	;;------------------------------------------
	;; Bresenham's line drawing
		xor	si,si			;; Default X increment
		mov	di,xbytes		;; Default Y increment
		sub	cx,ax			;; cx = deltax
		sub	dx,bx			;; dx = deltay
		jge	story
		neg	di
		neg	dx
story:		mov	deldxy,di		;; Diagonal X/Y increment
		cmp	cx,dx
		jge	stordelsxy
		mov	si,di
		xchg	cx,dx
stordelsxy:	mov	delsxy, si		;; Straight X/Y increment
		shl	dx,1
		mov	delse, dx		;; E.term increment: straight
		sub	dx,cx
		mov	si,dx			;; Errorterm
		sub	dx,cx
		mov	delde, dx		;; E.term increment: diagonal 

		mov	di,cx
		inc	di
		mov	cl,al

	;; Calculate video offset
		call	CalcAddr

		mov	ch,080h
		and	cl,07h
		shr	ch,cl			;; Bitmap
		mov	cl,dl			;; Bank #

	;; Setup VGA registers
		mov	dx,GC_INDEX
		mov	ah,linecolour
		xor	al,al			;; set color mode
		out	dx,ax
		mov	ax,0f01h
		out	dx,ax			;; setup sequencer
		mov	al,08h
		mov	ah,ch
		out	dx,ax			;; setup write bitmap
		cmp	writemode,1
		jnz	@noBresXor
		mov	ax,01803h
		out	dx,ax
@noBresXor:

	;; Main line drawing loop
linloop:	cmp	cl,curbk		;; Check for bankswitch
		jnz	LinChg
NoLinChg:	mov	bp, si			;; BP = 0 or 2 depending on 
		rol	bp, 2			;; sign of errorterm

	;; Rotate line bitmap
		ror	tmp_linestyle,1
		jnc	NoPlot
		xchg	al,es:[bx]		;; Store pixel

	;; Calculate delta based on sign of errorterm
NoPlot:		and	bp,2			;; (+ = diag, - = straight)
		mov	ax,ds:[bp+deldxy]	;; offset += delta
		add	si,ds:[bp+delde]	;; errorterm += delta
		shr	bp,1			;; bp = 0 or 1
		neg	bp			;; bp = 0 or 0xffff (-1)

		cwd
		add	bx, ax
		adc	cl, dl

	;; Don't update bitmap register if value is still the same
	;; (straight Y increment)
		test	bp, ax
		jz	angst
		dec	di
		jnz	linloop

	;; Restore register values
vectRestRegs:	outpw	GC_INDEX, 0
		outpw	dx, 01h
		outpw	dx, 03h
		outpw	dx, 0ff08h
		ret

angst:		ror	ch,1
		adc	bx,0
		adc	cl,0

	;; Update bitmap register
		mov	dx,GC_INDEX
		mov	al,08h
		mov	ah,ch
		out	dx,ax

		dec	di
		jnz	linloop
		jmp	short vectRestRegs

LinChg:		mov	dl,cl
		call	newbank
		jmp	short NoLinChg

;---------------------------------------------------------------------
;;PATBAR - Draws patterned bar from (X1,Y1)-(X2,Y2)
;; AX=Upper left X coordinate
;; BX=Upper left Y coordinate
;; CX=Lower right X coordinate
;; DX=Lower right Y coordinate

patbar:		push	es
		cmp	ax,cx			;; Check if X2<X1
		jl	Xok
		xchg	ax,cx			;; Swap X1 & X2

Xok:		cmp	bx,dx			;; Check if Y2<Y1
		jl	Yok
		xchg	dx,bx			;; Swap Y1 & Y2

Yok:		sub	dx,bx			;; Calculate bar height
		mov	bp,dx

		mov	di,cx
		mov	dx,0ff80h		;; Calculate left and right
		and	cx,7			;; edge bitmasks
		sar	dl,cl
		mov	cx,ax
		and	cx,7
		shr	dh,cl
		mov	word ptr fill_bits,dx

		mov	si,ax
		shr	si,3
		shr	di,3
		sub	di,si			;; Calculate bar width
		mov	bar_xsiz,di

		neg	di
		add	di,xbytes		;; Calculate next offset
		mov	next_row,di

		mov	si,bx			;; Calculate pattern row
		call	CalcAddr		;; Calculate initial offset
		mov	di,bx

		push	dx
		mov	dx,GC_INDEX
		mov	ax,0205h		;; Write mode 2
		out	dx,ax
		pop	dx
		mov	al,08h			;; Bitmap mask register

PatLoopY:	and	si,7
		cmp	dl,curbk			;; Check for bank switch
		jnz	PatChg
PatNoSwitch:	mov	cx,bar_xsiz			;; Check for bank crossing in mid-line
		mov	bx,cx
		add	bx,di
		jnc	patnextline			;; No overflow.. scanline fits within a single bank
		mov	cx,di
		neg	cx
		push	bx
		push	dx
		mov	bx,word ptr fill_bits		;; Set right edge to 0xFF (solid) of left-half of scanline
		mov	bl,0ffh
		dec	cx
		call	fstpatlin			;; Write first part of scanline
		mov	bx,word ptr fill_bits		;; Set left edge to 0xff (solid) of right-half of scanline
		mov	bh,0ffh
		pop	dx
		xor	di,di
		inc	dl
		call	newbank
		pop	cx
		jmp	short patbroken
patnextline:	mov	bx, word ptr [fill_bits]
patbroken:	push	dx
		call	fstpatlin		;; Write second part of scanline
		pop	dx
		inc	si			;; Increment pattern row
		add	di,next_row		;; Calculate offset of next
		adc	dl,0			;; line
		dec	bp			;; Decrease y counter
		jns	PatLoopY
		pop	es
		jmp	restregs

;; Faster bankswitch
PatChg:		call	newbank
		jmp	short PatNoSwitch

fstpatlin:	push	bx			;; Save pattern
		mov	dx, GC_INDEX
		mov	bl,bh
		mov	bh,fillpatnum
		test	bh,bh			;; Empty fill
		jz	@fstp00
		neg	bh
		cmp	bh, 0ffh		;; Solid fill
		jz	@fstp00
@fstp01:	mov	bh,[si+curr_fillpat]	;; Get fill bitpattern
@fstp00:	jcxz	fstpat00		;; jump if only one byte wide
		call	fstpat01		;; Set left edge
		mov	bl,0ffh			;; Mask for middle bytes
		inc	di
		dec	cx
		jcxz	fstpat00		;; jump if only two bytes wide
		cmp	bh,0ffh			;; solid fill or pattern
		jz	k_set
		mov	ah,bl			;; Set mask
		out	dx,ax
		push	cx
		push	di
		xor	al,al
		repz	stosb			;; Zero out middle bytes (set all planes to black)
		pop	di
		pop	cx
k_set:		mov	ah,bh			;; Set fill pattern bitmask
		mov	al,08h
		out	dx,ax
k_loop:		mov	ah,fillcolour
		xchg	ah,es:[di]		;; Store middle value
		inc	di
		loop	k_loop
fstpat00:	pop	cx
		and	bl,cl
fstpat01:	mov	ah,bh
		and	ah,bl
		out	dx,ax
		mov	ah,fillcolour
		xchg	ah,es:[di]		;; Store color
		cmp	bh,0ffh
		jnz	@fstpat02
		ret
@fstpat02:	mov	ah,bh
		not	ah
		and	ah,bl
		out	dx,ax
		xor	ah,ah
		xchg	ah,es:[di]		;; Zero out other planes
		ret

;---------------------------------------------------------------------
;;PALETTE - Palette manipulation
;; Upper two bits of AX:
;;  00b - BX contains colour, AX is index
;;  01b - Not supported
;;  10b - BX=Red, CX=Green, DX=Blue, AX is index
;;  11b - BX=background colour

palette:	xchg	bl,bh
		shl	ah,1		;; Test first bit
		jc	p_up

		mov	bl,al		;; Set color
		mov	ax,01000h
		int	10h
		ret

p_up:		shl	ah,1		;; Test second bit
		jnc	p_rgb
		xor	bl,bl		;; Set background color
		mov	ax,01000h
		int	010h
		ret

p_rgb:		mov	ah,dl		;; AX = BBBBBBBBIIIIIIII
					;; CX = 00000000GGGGGGGG
					;; BX = 00000000RRRRRRRR
		mov	dx,03c8h	;; VGA DAC port
		out	dx,al		;; Index
		inc	dx
		mov	al,bl		;; R
		out	dx,al
		mov	al,cl		;; G
		out	dx,al
		mov	al,ah		;; B
		out	dx,al
		WaitForRetrace
		ret

;---------------------------------------------------------------------
;;SETALLPALETTE - Load full palette
;; ES:BX Array of palette entries

setallpalette:	mov	dx,bx
		mov	ax,01002h
		int	010h
		ret

;---------------------------------------------------------------------
;;COLOUR - Set draw and fill colours
;; AL=new draw colour
;; AH=new fill colour

colour:		mov	linecolour,al
		mov	fillcolour,ah
		ret

;---------------------------------------------------------------------
;;FILLSTYLE - Set the fill pattern
;; AL=fill pattern number
;; ES:BX=user-defined fill pattern (if AL = 0xFF)

fillstyle:	mov	fillpatnum,al
		cmp	al,0ffh			;; Check if setting user style
		jz	usrfillsty
		sub	al,2
		js	fillstyxit
		cbw
		shl	ax,3
		mov	si,ax
		add	si,offset fillpatterns	;; Get offset of pattern out
		jmp	short movepattern	;; of fill table

usrfillsty:	mov	si,bx			;; Get offset of user pattern
		push	es
		pop	ds

movepattern:	mov	di,offset curr_fillpat
		LoadDataSeg	es		;; Macro
		mov	cx,4
		repz	movsw			;; Store fill pattern
fillstyxit:	ret

;---------------------------------------------------------------------
;;LINESTYLE - Set the line pattern
;; AL=line pattern number
;; BX=user-defined line pattern (if AL = 0x04)
;; CX=line width

linestyle:	cmp 	al,4			;; Check for user pattern
		jge	usrlinesty

		cbw
		shl	ax,1
		mov	si,ax
		mov	bx,[si+linestyles]	;; Get pattern out of table
usrlinesty:	mov	curr_linestyle,bx	;; Store line pattern
		ret

;---------------------------------------------------------------------
;;TEXTSTYLE - Set text direction and size
;; AL=font number
;; AH=font orientation
;; BX=desired character horiz size (in pixels)
;; CX=desired character vert size (in pixels)

textstyle:	mov	textdir,ah
		shr	bx,3
		mov	textinc,bx
		shl	bx,3
		mov	textxsiz,bx

		push	ax
		mov	ax, TEXTBYTES		;; Height in pixels
		mul	textinc
		mov	cx, ax
		pop	ax
		mov	textysiz, cx

ClipTxt:	ret

;---------------------------------------------------------------------
;; Draws a single character in the current textsize and linecolour
princ:		mov	bx,cp_x
		cmp	bx,clip_x1		;; Clip left
		jl	ClipTxt

		mov	dx,bx			;; Clip right
		add	dx,textxsiz
		dec	dx
		cmp	dx,clip_x2
		jg	ClipTxt

		mov	bx,cp_y
		cmp	bx,clip_y1		;; Clip top
		jl	ClipTxt

		mov	dx,bx			;; Clip bottom
		add	dx,textysiz
		dec	dx
		cmp	dx,clip_y2
		jg	ClipTxt

		push	es
		push	cx
		mov	si,textofs
		mov	es,textseg
		mov	cx, [fontheight]
		mul	cx
		add	si,ax
		mov	ax,cp_x

		cmp	textdir,0		;; Check font orientation
		jz	looprow
		xchg	ax,bx

looprow:	mov	dl,es:[si]		;; Get character bit pattern
		inc	si
		push	ax
		push	si
		push	cx
		cmp	textdir,0
		jz	noreverse
		mov	cx,8		;Reverses the lower 8 bits in DL
reversebit:	shr	dl,1
		rcl	dh,1
		loop	reversebit
		mov	dl,dh
noreverse:	mov	cx,ax

loopcol:	shl	dl,1
		jnc	plotc
		add	cx,textinc
		test	dl,dl
		jnz	loopcol
		jmp	short plotc2
plotc:		jz	endloopcol
plotc2:		cmp	ax,cx

		jnz	contplot
fixtxt:		add	cx,textinc
		mov	ax,cx
		jmp	short loopcol
contplot:	push	dx
		push	bx
		push	cx
		mov	dx,bx
		add	dx,textinc
		dec	dx
		dec	cx
		cmp	textdir,0
		jz	plotnow
		xchg	ax,bx
		xchg	cx,dx
plotnow:	call	patbar
		pop	cx
		pop	bx
		pop	dx
		jmp	short fixtxt
endloopcol:	pop	cx
		pop	si
		pop	ax
		add	bx,textinc
		loop	looprow
		pop	cx
		pop	es
		ret

;----------------------------------------------------------------------
;;TEXT - Outputs a string at CP
;; ES:BX=ASCII text of the string
;; CX=length of the string

text:		push	word ptr fillpatnum	;; Save fillpattern & colour
		mov	fillpatnum,1		;; Set fillpattern to SOLID
		mov	al,linecolour		;; Set fillcolour to linecolour
		mov	fillcolour,al
		mov	si,bx
		cmp	textdir,1
		jnz	HorizText
		mov	ax,cx
		dec	ax
		mul	textxsiz
		add	cp_y,ax
HorizText:	lods	byte ptr es:[si]
		xor	ah,ah
		push	si
		call	princ
		pop	si
		mov	dx,textxsiz
		cmp	textdir,1
		jnz	HorizInc
		sub	cp_y,dx
		jmp	short txtloop
HorizInc:	add	cp_x,dx
txtloop:	loop	HorizText
		pop	word ptr fillpatnum
		ret

;---------------------------------------------------------------------
;;TEXTSIZE - Returns height and width of a string in pixels
;; ES:BX=ASCII text of the string
;; CX=length of the string

textsize:	mov	ax,cx
		mul	textxsiz
		mov	bx,ax
		mov	cx,textysiz
		ret

;---------------------------------------------------------------------
;;SCANLEFT - Scans left until a boundary edge is reached

ScanLeft:	push	bp
		mov	bp,sp
		push	di
		push	si
		mov	si,[bp+4]		; x
		mov	di,[bp+6]		; y
		jmp	short @ScnLft01
@ScnLft00:	mov	ax,si			;; TstPix
		mov	bx,di
		call	getpixel		;; Slow!
		cmp	dl,BrdrClr
		je	@ScnLftExit
		dec	si			;; decrease x coord
@ScnLft01:	cmp	clip_x1,si		;; check clip area
		jle	@ScnLft00
@ScnLftExit:	inc	si
		mov	ax,si			;; return x
		pop	si
		pop	di
		pop	bp
		ret	

;---------------------------------------------------------------------------
;;SCANRIGHT - Scans right until a boundary is reached

ScanRight:	push	bp
		mov	bp,sp
		push	di
		push	si
		mov	si,[bp+4]		; x
		mov	di,[bp+6]		; y
		jmp	short @ScnRgt01
@ScnRgt00:	mov	ax,si			;; TstPix
		mov	bx,di
		call	getpixel		;; Slow!
		cmp	dl,BrdrClr
		je	@ScnRgtExit
		inc	si			;; increase x coord
@ScnRgt01:	cmp	clip_x2,si		;; check clip area
		jge	@ScnRgt00
@ScnRgtExit:	dec	si
		mov	ax,si			;; return x
		pop	si
		pop	di
		pop	bp
		ret	

;---------------------------------------------------------------------------
;;ScanRightS - Scans right until a boundary or non-edge colour is reached

ScanRightS:	push	bp
		mov	bp,sp
		push	di
		push	si
		mov	si,[bp+4]		; xl
		mov	di,[bp+6]		; xr
		jmp	short @ScnRgtS01
@ScnRgtS00:	inc	si			;; increase x coord
@ScnRgtS01:	cmp	si,di			;; check if xl > xr
		jg	@ScnRgtSExit
		mov	ax,si			;; TstPix
		mov	bx,[bp+8]
		call	getpixel		;; Slow!
		cmp	dl,BrdrClr
		je	@ScnRgtS00
		mov	ax,si			;; return x
		jmp	short @ScnRgtS02
@ScnRgtSExit:	mov	ax,-1			;; return -1
@ScnRgtS02:	pop	si
		pop	di
		pop	bp
		ret	

;---------------------------------------------------------------------------
;;FillHoriz - Fills a horizontal line

FillHoriz:	push	bp
		mov	bp,sp
		push	di
		push	si
		mov	si,[bp+4]		; x
		mov	di,[bp+6]		; y
		mov	ax,CurrXR
		mov	PrevXR,ax
		push	di
		push	si
		call	ScanRight
		add	sp,4
		mov	CurrXR,ax		; Xr
		mov	cx,si
		mov	dx,di			; Y
		mov	bx,di			; Y
		call	patbar
		pop	si
		pop	di
		pop	bp
		ret	

;---------------------------------------------------------------------------
;;ScanLine - Scans a line, adding entries to the fill stack

ScanLine:	push	bp
		mov	bp,sp
		push	di
		push	si
		mov	si,[bp+4]		; xl
		mov	di,[bp+6]		; xr
		jmp	short @ScnLin02
@ScnLin00:	mov	bx,StkPtr
		shl	bx,1
		mov	ax,si
		cmp	word ptr [bp+10],0	; dir
		jge	@ScnLin01
		not	ax
@ScnLin01:	mov	Xvals[bx],ax		;; Add left x coord to stack
		mov	ax,[bp+8]		; y
		mov	Yvals[bx],ax		;; Add y coord to stack
		inc	StkPtr			;; Increase stack pointer
		push	ax
		push	si
		call	ScanRight
		add	sp,4
		mov	si,ax
		inc	si
@ScnLin02:	push	[bp+8]			; y
		push	di
		push	si
		call	ScanRightS
		add	sp,6
		mov	si,ax
		test	si,si
		jl	@ScnLinExit
		cmp	StkPtr,MaxStack
		jne	@ScnLin00
		mov	ax,-1				;; Return -1
		jmp	short @ScnLin03
@ScnLinExit:	sub	ax,ax				;; Return 0
@ScnLin03:	pop	si
		pop	di
		pop	bp
		ret	

;---------------------------------------------------------------------------
;;ChkStk - Checks if a coord is in the fill stack

ChkStk:		push	bp
		mov	bp,sp
		push	di
		push	si
		mov	si,[bp+4]		; x
		sub	di,di
		cmp	[bp+8],di		; dir
		jge	@ChkStk00
		not	si
@ChkStk00:	mov	dx,[bp+6]		; y
		mov	cx,StkPtr
		jmp	short @ChkStk04
@ChkStk01:	mov	bx,di
		shl	bx,1
		mov	ax,Xvals[bx]		;; Remove duplicate entry
		mov	Xvals[bx-2],ax
		mov	ax,Yvals[bx]
		mov	Yvals[bx-2],ax
@ChkStk02:	inc	di
		cmp	di,cx
		jl	@ChkStk01
		dec	cx			; Decrease stack pointer
		mov	ax,1			; return 1
		jmp	short @ChkStk05
@ChkStk03:	inc	di
@ChkStk04:	cmp	cx,di
		jle	@ChkStkExit
		mov	bx,di
		shl	bx,1
		cmp	Xvals[bx],si		; Compare x with stack
		jne	@ChkStk03
		cmp	Yvals[bx],dx		; Compare y with stack
		jne	@ChkStk03
		jmp	short @ChkStk02
@ChkStkExit:	sub	ax,ax			; return 0
@ChkStk05:	mov	StkPtr,cx
		pop	si
		pop	di
		pop	bp
		ret	

;---------------------------------------------------------------------------
;;ScanUpDn - Scans up or down until a boundary is reached

ScanUpDn:	push	bp
		mov	bp,sp
		sub	sp,18
		push	di
		push	si
		mov	ax,[bp+8]		;Dir
		neg	ax
		mov	[bp-18],ax
@ScnUpDn00:	mov	ax,[bp+6]		;Yc
		add	ax,[bp+8]		;Dir
		mov	[bp-6],ax		;CurrY
		mov	ax,clip_y1
		cmp	[bp-6],ax		;CurrY
		jl	@ScnUpDn01
		mov	ax,clip_y2
		cmp	[bp-6],ax		;CurrY
		jle	@ScnUpDn02
@ScnUpDn01:	sub	ax,ax
		jmp	@ScnUpDnExit
@ScnUpDn02:	mov	ax,[bp+4]		;Xc
		mov	[bp-4],ax		;PrevXL
		mov	bx,[bp-6]		;; TstPix
		call	getpixel
		cmp	dl,BrdrClr
		je	@ScnUpDn03
		push	[bp-6]			;CurrY
		push	[bp+4]			;Xc
		call	ScanLeft
		add	sp,4
		mov	[bp-2],ax		;CurrXL
		jmp	short @ScnUpDn04
@ScnUpDn03:	push	[bp-6]			;CurrY
		push	CurrXR
		push	[bp+4]			;Xc
		call	ScanRightS
		add	sp,6
		mov	[bp-2],ax		;CurrXL
		test	ax,ax
		jl	@ScnUpDn01
@ScnUpDn04:	push	[bp-6]			;CurrY
		push	[bp-2]			;CurrXL
		call	FillHoriz
		add	sp,4
		mov	ax,[bp-4]		;PrevXL
		cmp	[bp-2],ax		;CurrXL
		jge	@ScnUpDn10
		mov	si,[bp-2]		;CurrXL
		push	[bp+6]			;Yc
		push	si
		call	ScanLeft
		add	sp,4
		mov	di,ax
		cmp	di,si
		jge	@ScnUpDn08
		jmp	short @ScnUpDn06
@ScnUpDn05:	mov	si,di
		push	[bp+6]			;Yc
		push	si
		call	ScanLeft
		add	sp,4
		mov	di,ax
@ScnUpDn06:	cmp	di,si
		jge	@ScnUpDn07
		mov	si,di
		push	[bp-6]			;CurrY
		push	si
		call	ScanLeft
		add	sp,4
		mov	di,ax
		cmp	di,si
		jl	@ScnUpDn05
@ScnUpDn07:	push	[bp+8]			;Dir
		push	[bp-6]			;CurrY
		mov	ax,[bp-2]		;CurrXL
		dec	ax
		push	ax
		push	si
		call	ScanLine
		add	sp,8
		test	ax,ax
		jne	@ScnUpDn09
@ScnUpDn08:	push	[bp-18]
		push	[bp+6]			;Yc
		mov	ax,[bp-4]		;PrevXL
		dec	ax
		push	ax
		push	si
		call	ScanLine
		add	sp,8
		test	ax,ax
		je	@ScnUpDn10
@ScnUpDn09:	mov	ax,-1
@ScnUpDnExit:	pop	si
		pop	di
		mov	sp,bp
		pop	bp
		ret	
@ScnUpDn10:	mov	ax,CurrXR
		cmp	PrevXR,ax
		jne	@ScnUpDn11
		jmp	@ScnUpDn17
@ScnUpDn11:	mov	ax,[bp+8]		;Dir
		mov	[bp-8],ax		;FillD
		mov	ax,CurrXR
		mov	[bp-4],ax		;PrevXL
		mov	ax,PrevXR
		mov	[bp-14],ax		;NewXL
		mov	ax,CurrXR
		cmp	PrevXR,ax
		jle	@ScnUpDn12
		mov	ax,[bp-14]		;NewXL
		xchg	ax,[bp-4]		;PrevXL
		mov	[bp-14],ax
		mov	ax,[bp-6]		;CurrY
		mov	[bp+6],ax		;Yc
		mov	ax,[bp-8]		;FillD
		neg	ax
		mov	[bp-8],ax		;FillD
@ScnUpDn12:	mov	si,[bp-4]		;PrevXL
		push	[bp+6]			;Yc
		push	si
		call	ScanRight
		add	sp,4
		mov	di,ax
		cmp	di,si
		jle	@ScnUpDn16
		jle	@ScnUpDn14
		mov	ax,[bp+6]		;Yc
		add	ax,[bp-8]		;FillD
		mov	[bp-16],ax
@ScnUpDn13:	mov	si,di
		push	[bp-16]
		push	si
		call	ScanRight
		add	sp,4
		mov	di,ax
		cmp	di,si
		jg	@ScnUpDn15
@ScnUpDn14:	push	[bp-8]			;FillD
		mov	ax,[bp+6]		;Yc
		add	ax,[bp-8]		;FillD
		push	ax
		push	si
		mov	ax,[bp-4]		;PrevXL
		inc	ax
		push	ax
		call	ScanLine
		add	sp,8
		test	ax,ax
		je	@ScnUpDn16
		jmp	@ScnUpDn09
@ScnUpDn15:	mov	si,di
		push	[bp+6]	;Yc
		push	si
		call	ScanRight
		add	sp,4
		mov	di,ax
		cmp	di,si
		jle	@ScnUpDn14
		jmp	short @ScnUpDn13
@ScnUpDn16:	mov	ax,[bp-8]		;FillD
		neg	ax
		push	ax
		push	[bp+6]			;Yc
		push	si
		mov	ax,[bp-14]		;NewXL
		inc	ax
		push	ax
		call	ScanLine
		add	sp,8
		test	ax,ax
		je	@ScnUpDn17
		jmp	@ScnUpDn09
@ScnUpDn17:	mov	ax,[bp-2]		;CurrXL
		mov	[bp+4],ax		;Xc
		mov	ax,[bp-6]		;CurrY
		mov	[bp+6],ax		;Yc
		push	[bp-18]
		push	ax
		push	[bp+4]			;Xc
		call	ChkStk
		add	sp,6
		test	ax,ax
		jne	@ScnUpDn18
		jmp	@ScnUpDn00
@ScnUpDn18:	jmp	@ScnUpDn01

;---------------------------------------------------------------------
;;FLOODFILL - Fills a bounded region with a pattern
;; AX=X coordinate of the seed point
;; BX=Y coordinate of the seed point
;; CL=Boundary colour for fill

FloodFill:	mov	word ptr FillD,-1
		mov	BrdrClr,cl
		mov	si,ax			;; SeedX
		mov	di,bx			;; SeedY
		call	getpixel		;; TstPix
		cmp	dl,BrdrClr
		jne	@FldFill_00
		jmp	@FldFill_Exit
@FldFill_00:	push	di			;; SeedY
		push	si			;; SeedX
		call	ScanLeft
		add	sp,4
		mov	si,ax			;; SeedX
		mov	Xvals,ax		;; Initialize stack
		mov	Yvals,di
		mov	StkPtr,1
		push	di			;; SeedY
		push	si			;; SeedX
		call	ScanRight
		add	sp,4
		mov	CurrXR,ax
		jmp	short @FldFill_03
@FldFill_01:	mov	bx,StkPtr
		test	bx,bx			;; Test for empty stack
		je	@FldFill_Exit
		dec	bx
		mov	StkPtr,bx
		shl	bx,1
		mov	si,Xvals[bx]
		mov	di,Yvals[bx]
		mov	ax,1
		test	si,si
		jge	@FldFill_02
		not	si
		neg	ax
@FldFill_02:	mov	FillD,ax
		push	di
		push	si
		call	FillHoriz
		add	sp,4
		mov	ax,FillD
		neg	ax
		push	ax
		push	di
		push	si
		call	ChkStk
		add	sp,6
		test	ax,ax
		jne	@FldFill_01
@FldFill_03:	push	FillD
		push	di
		push	si
		call	ScanUpDn
		add	sp,6
		test	ax,ax
		je	@FldFill_01
@FldFill_Exit:	ret

;---------------------------------------------------------------------
;;GETPIXEL - Reads a pixel from the screen
;; AX=X coordinate of the seed point
;; BX=Y coordinate of the seed point

getpixel:	push	cx
		push	es
		push	si
		mov	cx,ax
		and	cx,7
		mov	ch,080h			;; Calculate bit offset of pixel
		shr	ch,cl
		call	CalcAddr		;; Calculate address
		cmp	dl,curbk
		jz	gnonew
		call	newbank
gnonew:		mov	si,bx
		xor	bx,bx
		mov	dx,GC_INDEX
		mov	ax,0304h
gloop:		out	dx,ax			;; Set Read Map Mask
		mov	bh,es:[si]		;; load byte
		and	bh,ch			;; Mask byte
		neg	bh
		rol	bx,1
		dec	ah			;; Decrease plane #
		jge	gloop
		xor	dx,dx
		mov	dl,bl			;; Return color
		pop	si
		pop	es
		pop	cx
		jmp	restregs

;---------------------------------------------------------------------
;;PUTPIXEL - Writes a pixel to the screen
;; AX=X coordinate of the seed point
;; BX=Y coordinate of the seed point
;; DL=colour of the seed point

putpixel:	push	cx
		push	es
		mov	cx,ax
		and	cx,7
		mov	ch,dl			;; Save draw color
		call	CalcAddr		;; Calculate address
		cmp	dl,curbk
		jz	pnonew
		call	newbank
pnonew:		mov	dx, GC_INDEX
		mov	ax, 0205h
		out	dx, ax
		mov	ax,8008h
		shr	ah,cl
		out	dx,ax
		xchg	ch,es:[bx]		;; Store pixel
		pop	es
		pop	cx
		jmp	restregs

;---------------------------------------------------------------------
;;BITMAPUTIL - Returns pointer to bitmap routines
bitmaputil:	LoadDataSeg	es		;; Macro
		mov	bx,offset BitmapTable
		ret

;---------------------------------------------------------------------
;;BITBLT from screen to buffer
;; ES:BX=memory buffer to store image in
;;   ES:[BX+0]=(Width of rectangle - 1)
;;   ES:[BX+2]=(Height of rectangle - 1)
;; CX=Upper left X coordinate
;; DX=Upper left Y coordinate

savebitmap:	mov	di,es:[bx]
		mov	ax,dx		;; Y coord
		mov	si,cx		;; X coord
		and	cl,7		;; # of bits to rotate
		shr	si,3		;; Calculate address
		shr	di,3
		inc	di
		mov	bar_xsiz,di
		mul	xbytes
		add	si,ax		;; SI holds offset
		adc	dx,0		;; DL holds bank #
		add	si,word ptr PageOfs
		adc	dx,word ptr PageOfs[2]
		mov	bp,es:[bx+2]
		mov	di,bx
		add	di,4

@SaveBit00:	mov	ax,0304h
@SaveBit02:	push	dx
		mov	dx,GC_INDEX
		out	dx,ax			;; Set Read Plane
		pop	dx
		push	si
		mov	bx,bar_xsiz
@SaveBit01:	cmp	dl,curbk		;; Check for Bank Switch
		jz	GetNoSwitch
		call	newbank
GetNoSwitch:	push	ax
		push	es
		mov	es,VidMem
		cmp	si,0ffffh		;; Check for last byte in row 511 in 1024x768 mode
		jz	PartWord		;; so that a segment violation error isn't raised!
		mov	ah,es:[si+01]
PartWord:	mov	al,es:[si]
		pop	es
		add	si,1
		adc	dl,0
		rol	ax,cl			;; Rotate bits
		stosb				;; store value
		test	di,di
		jnz	NIseg			;; Test for >64k access

	;; Add increment to segment
		IncrSegment	es
	IF 	BGIVERSION GE 3
		cmp	curOpMode,0
		jnz	NIseg
	ENDIF
	;; Make sure segment doesn't run into video memory
		cmp	ax,09000h
		ja	savebmapxit

NIseg:		pop	ax
		dec	bx
		jnz	@SaveBit01		;; Loop X
		pop	si
		dec	ah			;; Decrease plane #
		jns	@SaveBit02
		add	si,xbytes
		adc	dl,0
		dec	bp
		jns	@SaveBit00		;; Loop Y
		jmp	restregs
savebmapxit:	pop	ax
		pop	si
		jmp	restregs

;---------------------------------------------------------------------
;;BITBLT from buffer to screen
;; ES:BX=memory buffer with stored image
;;  ES:[BX+0]=(Width of rectangle - 1)
;;  ES:[BX+2]=(Height of rectangle - 1)
;; CX=Upper left X coordinate
;; DX=Upper left Y coordinate
;; AL= Logical restore operation

setmask:	push	ax		;; Sets bitmask
		push	dx
		mov	dx,03ceh
		mov	ah,bh
		mov	al,8
		out	dx,ax
		pop	dx
		pop	ax
		mov	es,VidMem
		ret

Chk64:		push	ax
	;; Add increment to segment
		IncrSegment	es
	IF 	BGIVERSION GE 3
		cmp	curOpMode,0
		jnz	NOSeg
	ENDIF
NOSeg:		cmp	ax, 9000h
		pop	ax
		ret

restorebitmap:	xor	ah,ah
		and	al,7
@Blt00:		mov	fill_bits,al		;; holds logical operation
		mov	si,ax

		mov	di,cx
		mov	ax,es:[bx]
		add	cx,ax
		and	cx,7
		mov	ch,080h
		sar	ch,cl
		mov	fill_bits[2],ch		;; Right mask

		mov	cx,di
		and	cx,7
		mov	ch,0ffh
		shr	ch,cl
		mov	fill_bits[1],ch		;; Left mask

		mov	ch,8
		sub	ch,cl

		mov	bp,ax
		add	bp,di
		shr	bp,3

		shr	ax,3
		mov	fill_bits[3],al		;; # of source bytes
		mov	ax,bp

		shr	di,3
		sub	ax,di
		mov	fill_bits[4],al		;; # of destination bytes

		mov	ax,dx
		mul	xbytes
		add	di,ax
		adc	dx,0
		add	di,word ptr PageOfs
		adc	dx,word ptr PageOfs[2]

		push	dx
		mov	dx,GC_INDEX
		mov	ah,[Logical+si]		;; Value for Rotate/Func register
		mov	al,3
		out	dx,ax			;; Set Data Rotate/Function
		mov	ax, 0805h
		out	dx, ax			;; Set read & write mode
		mov	ax, 7
		out	dx, ax			;; Set Color Compare register
		pop	dx

		mov	si,bx
		mov	ax,es:[si+2]
		inc	ax
		mov	next_row,ax
		add	si,4
		mov	bl,fill_bits[3]		;; nSb
		xor	bh,bh
		mov	bp,bx
;; Loop Y
@Blt01:		mov	ax,802h
		cmp	dl,curbk		;; Check bank
		jz	@Blt02
		call	newbank
;; Loop Plane
@Blt02:		push	di
		push	ax
		push	dx
		mov	dx, SC_INDEX
		out	dx, ax
		pop	dx
		xor	ax,ax
		mov	bh,fill_bits[1]		;; Lmask
		push	bp
;; Loop X
@Blt03:		shl	ax,cl
		mov	al,es:[si]		;; Read source byte
		inc	si
		jnz	@Blt04			;; Check for >64k access
		call	Chk64
		ja	putbmapxit
@Blt04:		xchg	cl,ch
		shl	ax,cl				;; Rotate data bits
		xchg	cl,ch
		cmp	fill_bits,4			;; NOT_PUT...
		jl	@Blt05
		not	ah
@Blt05:		cmp	bl,fill_bits[4]			;;nDb
		jnz	@Blt06
		test	bp,bp
		jnz	@Blt06
		and	bh,fill_bits[2]			;; Rmask
@Blt06:		push	es
		call	setmask
		and	es:[di],ah			;; Store data
		pop	es
		mov	bh,0ffh
		inc	di
		dec	bp
		jns	@Blt03				;; Loop X

		pop	bp
		cmp	bl,fill_bits[4]			;; nDb
		jz	@Blt07
		and	bh,fill_bits[2]			;; Rmask
		push	es
		call	setmask
		cmp	fill_bits,4	;; Check for NOT_PUT in last byte
		jl	@Blt08
		not	al
@Blt08:		and	es:[di],al			;; Store last pixel(s)
		pop	es
@Blt07:		pop	ax
		pop	di
		shr	ah,1
		jnz	@Blt02				;; Loop Plane

		add	di,xbytes
		adc	dx,0
		dec	word ptr next_row		;; Loop Y

		jz	PutImXit
		jmp	@Blt01
PutImXit:	jmp	restregs
putbmapxit:	pop	bp
		pop	ax
		pop	di
		pop	dx
		jmp	restregs

;---------------------------------------------------------------------
;; SETCLIP - Sets the clipping rectangle
;; AX=Upper left X coordinate
;; BX=Upper left Y coordinate
;; CX=Lower right X coordinate
;; DX=Lower right Y coordinate

setclip:	mov	clip_x1,ax
		mov	clip_y1,bx
		mov	clip_x2,cx
		mov	clip_y2,dx
		ret

;---------------------------------------------------------------------
;; COLOURQUERY - colour & palette info

;; Get length of colour table & number of colours available
colourquery:	test	al,al
		jnz	clrtable
		mov	bx,010h
		mov	cx,COLORMODE - 1
		ret

;; Get offset of colour table
clrtable:	LoadDataSeg	es		;; Macro
		mov	bx,offset colourtable
		ret

;---------------------------------------------------------------------
; Now for the miscellaneous routines

;; BITS_PER_PIX - Returns the pixel colour depth
bits_per_pix	proc	far
		mov	ax,4
		ret
bits_per_pix	endp

;; getdrawpage - returns 32-bit page offset: 
;;  AX - lower 16 bits
;;  DX - upper 16 bits
getdrawpage	proc
		xor	ah,ah
		mov	cx,ax
		xor	ax,ax
		xor	dx,dx
		jcxz	spage_it
spage1:		add	ax,word ptr PageSize[0]
		adc	dx,word ptr PageSize[2]
		loop	spage1
spage_it:	ret
getdrawpage	endp

;; SETVISPAGE - Sets the visible video page
setvispage	proc	far
		push	cx
		push	ds
		LoadDataSeg	ds		;; Macro

		call	getdrawpage	;; AX = lower 16 bits, DX = upper bits
		mov	bx, dx

	;; Wait for Display Enable
		cli
		push	ax
		WaitForEnable
		pop	ax

	;; Call SuperVGA paging function (BX = page bits)
		call	SetDisplayStart
		call	word ptr [PageAdr]

	;; Wait for vertical retrace
		WaitForRetrace
		sti

		pop	ds
		pop	cx
		ret
setvispage	endp

;; SETDRAWPAGE - Sets the drawing video page
setdrawpage	proc	far
		push	cx
		push	ds
		LoadDataSeg	ds		;; Macro
		call	getdrawpage	;; AX = lower 16; DX = upper
		mov	word ptr [PageOfs],ax
		mov	word ptr [PageOfs+2],dx
		pop	ds
		pop	cx
		ret
setdrawpage	endp

;; SETWRITEMODE - Sets the line drawing mode (either COPY_PUT or XOR_PUT)
setwritemode	proc	far
		and	ax,1
		push	ds
		LoadDataSeg	ds			;; Macro
		mov	writemode,al
		pop	ds
		ret
setwritemode	endp

;;
;;	Copyright 1988,89,90 John Bridges
;;	Free for use in commercial, shareware or freeware applications
;;
;;	SVGAMODE.ASM
;;
;;  Modified by jph

INCLUDE svgabank.inc

	IF	BGIVERSION GE 3
_TEXT	ENDS

_DATA	SEGMENT	PARA	PUBLIC	'DATA'

	assume ds:_DATA, cs:Nothing

InitTable	EQU	$
NRealSegs       db      2
RealSegOfs      dw      SegTable
NIntVects       db      0
IntVecOfs       dw      0
NRealBlocks     db      0
RealBlockOfs    dw      0
DSinRealMem     db      1
RealModeDS      dw      0
CurOpMode       db      0

SegTable	EQU	$
SEGA000         dw      0A000h
SEGC000		dw	0C000h

SimInt		SimIntStruc<>

	ENDIF

;;Indexed call table of BGI routines
DDOVEC		dw	install		;[00] Install the driver
		dw	init		;[02] Initialize the driver
		dw	clear		;[04] Clear the graphics device
		dw	post		;[06] Exit from graphics mode
		dw	move		;[08] Move current pointer
		dw	draw		;[0A] Draw line from CP to X,Y
		dw	vect		;[0C] Draw line from X1,Y1 to X2,Y2
		dw	EMULATE		;[0E] Reserved
		dw	EMULATE		;[10] Filled 3d bar	{emulated}
		dw	patbar		;[12] Patterned bar
		dw	EMULATE		;[14] Arc 		{emulated}
		dw	EMULATE		;[16] Pieslice 		{emulated}
		dw	EMULATE		;[18] Filled ellipse 	{emulated}
		dw	palette		;[1A] Load a palette entry
		dw	setallpalette	;[1C] Load the full palette
		dw	colour		;[1E] Set current line/fill colour
		dw	fillstyle	;[20] Set fill pattern
		dw	linestyle	;[22] Set line style
		dw	textstyle	;[24] Default font control
		dw	text		;[26] Default font output at CP
		dw	textsize	;[28] Default font size query
		dw	EMULATE		;[2A] Reserved
		dw	floodfill	;[2C] Fill a bounded region
		dw	getpixel	;[2E] Get pixel colour at (X,Y)
		dw	putpixel	;[30] Set pixel colour at (X,Y)
		dw	bitmaputil	;[32] Pointer to bitmap routines
		dw	savebitmap	;[34] BITBLT from screen to buffer
		dw	restorebitmap	;[36] BITBLT from buffer to screen
		dw	setclip		;[38] Set clipping rectangle
		dw	colourquery	;[3A] Colour table query

		dw	16 dup(NotImpNear)	;Reserved for future use.

;---------------------------------------------------------------------
;; Indexed call table of functions used by emulated circle/ellipse routines
BitmapTable	dw	NotImpFar	;GotoGraphic
		dw	NotImpFar	;ExitGraphic
		dw	putpixel	;PutPixel
		dw	getpixel	;Getpixel
		dw	bits_per_pix	;Getpixbyte
		dw	setdrawpage	;Set_draw_page
		dw	setvispage	;Set_visual_page
		dw	setwritemode	;Set_write_mode

;;---------------------------------------------------------------------------
;; Video Mode structures
;------- For EGA/VGA
Stat0 Status<,,319,199,319,199,,,8600,,,,>		;;320x200x16
Mode0		db	18,"EGA/VGA 320x200x16",0
Stat1 Status<,,639,199,639,199,,,4500,,,,>		;;640x200x16
Mode1		db	18,"EGA/VGA 640x200x16",0
Stat2 Status<,,639,349,639,349,,,7750,,,,>		;;640x350x16
Mode2		db	18,"EGA/VGA 640x350x16",0
Stat3 Status<,,639,479,639,479,,,10000,,,,>		;;640x480x16
Mode3		db	14,"VGA 640x480x16",0

;------- For 256k SuperVGA
Stat4 Status<,,799,599,799,599,,,10000,,,,>		;;800x600x16
Mode4		db	19,"SuperVGA 800x600x16",0
	IF USEVESA EQ 1
Mode4v		db	15,"VESA 800x600x16",0
	ENDIF

;------- For 512k SuperVGA
Stat5 Status<,,1023,767,1023,767,,,10000,,,,>		;;1024x768x16
Mode5		db	20,"SuperVGA 1024x768x16",0
	IF USEVESA EQ 1
Mode5v		db	16,"VESA 1024x768x16",0
	ENDIF

;------- For 1024k SuperVGA
Stat6 Status<,,1279,1023,1279,1023,,,10000,,,,>		;;1280x1024x16
Mode6		db	21,"SuperVGA 1280x1024x16",0
	IF USEVESA EQ 1
Mode6v		db	17,"VESA 1280x1024x16",0
	ENDIF

;; Table of structures
StatTable	dw	Stat0, Stat1, Stat2, Stat3, Stat4, Stat5, Stat6

;; Table of mode names
ModeNameTable	dw	Mode0, Mode1, Mode2, Mode3, Mode4, Mode5, Mode6
	IF USEVESA EQ 1
ModeVNameTable	dw	Mode0, Mode1, Mode2, Mode3, Mode4v,Mode5v, Mode6v
	ENDIF

VidMem		dw	0A000h		;; Offset of video memory
SelectorInc	dw	1000h		;; Segment/selector increment

;; Colour table - contains default colors
colourtable	db	010h
		db	000h,001h,002h,003h,004h,005h
		db	014h,007h,038h,039h,03ah
		db	03Bh,03ch,03dh,03eh,03fh

cp_x		dw	?		;; Current drawing position
cp_y		dw	?

curr_mode	db	?		;; Current video mode
xbytes		dw	?		;; Current mode width in bytes
xsiz		dw	?		;; Current mode width in pixels
ysiz		dw	?		;; Current mode height in pixels

bar_xsiz	dw	?		;; Patterned bar & BITBLT variables
next_row	dw	?
fill_bits	db	?,?,?,?,?

fontheight	dw	TEXTBYTES
textxsiz	dw	8		;; Text parameters
textysiz	dw	TEXTBYTES
textinc		dw	1
textdir		db	0,0		;; Text orientation
textseg		dw	?		;; Far pointer to character table
textofs		dw	?

clip_x1		dw	?		;; Clipping rectangle borders
clip_y1		dw	?
clip_x2		dw	?
clip_y2		dw	?

BrdrClr		db	?			;; Floodfill variables
svga_Oldreg	label	byte
Xvals		dw	MaxStack dup(0)		;; X-coordinate stack
Yvals		dw	MaxStack dup(0)		;; Y-coordinate stack
StkPtr		dw	?			;; Fill stack pointer
PrevXR		dw	?			;; Previous scanline's right X coord
CurrXR		dw	?			;; Previous scanline's left X coord
FillD		dw	?			;; Current fill direction

;; Line drawing variables
deldxy		dw	?		;; Screen offset increment for stepped line    ‹‹ﬂﬂ
delsxy		dw	?		;; Screen offset increment for straight line   ‹‹‹‹
delde		dw	?		;; Error term increment for stepped line
delse		dw	?		;; Error term increment for straight line

;; Line parameters
writemode	db	?		;; Current write mode
linecolour	db	?		;; Current line drawing colour
curr_linestyle	dw	0ffffh		;; Current line style
tmp_linestyle	dw	?
linestyles	dw	0ffffh		;; Solid Line
		dw	0cccch		;; Dotted Line
		dw	0fc78h		;; Center Line
		dw	0f8f8h		;; Dashed Line

;; Fill parameters
fillpatnum	db	?			;; Current fill pattern number
fillcolour	db	?			;; Current fill color
curr_fillpat	db 	?,?,?,?,?,?,?,?		;; Current fill pattern
fillpatterns	db	0ffh,0ffh,000h,000h,0ffh,0ffh,000h,000h	;; Line Fill
		db	001h,002h,004h,008h,010h,020h,040h,080h	;; Lt Slash Fill
		db	0e0h,0c1h,083h,007h,00eh,01ch,038h,070h	;; Slash Fill
		db	0f0h,078h,03ch,01eh,00fh,087h,0c3h,0e1h	;; Backslash Fill
		db	0a5h,0d2h,069h,0b4h,05ah,02dh,096h,04bh	;; Lt Backslash Fill
		db	0ffh,088h,088h,088h,0ffh,088h,088h,088h	;; Hatch Fill
		db	081h,042h,024h,018h,018h,024h,042h,081h	;; XHatch fill
		db	0cch,033h,0cch,033h,0cch,033h,0cch,033h	;; Interleave Fill
		db	080h,000h,008h,000h,080h,000h,008h,000h	;; Wide Dot Fill
		db	088h,000h,022h,000h,088h,000h,022h,000h	;; Close Dot Fill

curbk		db	?		;; Current bank number
savebk		db	?		;; Save bank for putimage
tmpbk		db	?		;; Temp bank for putimage
bankadr		dw	NotImpNear	;; Address of bank-switch routine.
pageadr		dw	NotImpNear
svga_IOAdr	dw	?

;; Values for Data Rotate/Function registers for putimage
;; COPY_PUT,XOR_PUT,OR_PUT,AND_PUT
;; NOT_PUT,XNOR_PUT,NOR_PUT,NAND_PUT
Logical		DB	00h,018h,010h,008h
		DB	00h,018h,010h,008h

cardFlags	db	?
;; VESA initialization variables
VESA_granlrty	db	0		;; Window granularity

;; Indexed table of standard EGA/VGA modes
Modes		dw	0dh		;; Mode 0	(320x200x16)
		dw	0eh		;; Mode 1	(640x200x16)
		dw	010h		;; Mode 2	(640x350x16)
		dw	012h		;; Mode 3	(640x480x16)

;; Bytes per line values
BytesPerLine	dw	40
		dw	80
		dw	80
		dw	80
		dw	100
		dw	128
		dw	160
		dw	200

;; Size of video pages (in paragraphs)
PageSize	dd	?
PageOfs		dd	?

CurrVidModes	dw	DefaultModes		;; Card video mode table
OrigVidModes	dw	DefaultModes

DefaultModes	dw	0,0			;; Default - Non SuperVga modes
		dw	0,0
		dw	0,0
AcumosModes	dw	058h,0			;; Acumos modes
		dw	05dh,0
		dw	0,0
AheadModes	dw	071h,0			;; Ahead modes
		dw	074h,0
		dw	0,0
ATIGUPModes	EQU	$
AtiModes	dw	054h,0			;; ATI modes
		dw	055h,0
		dw	0,0
;; ATI 1024x768 mode is a special case... mode 0x55 is not supported on older
;; cards. The original 1024x768x16 mode (0x65) uses a strange addressing scheme
;; (not supported in this driver)
AL2101Modes	dw	02bh,0			;; AL2101 modes
		dw	030h,0
		dw	036h,0
CirrusModes	dw	064h,0			;; Cirrus 510/610
		dw	0,0
		dw	0,0
Cirrus54Modes	dw	058h,0			;; Cirrus GD 54xx
		dw	05dh,0
		dw	06ch,0
Cirrus64Modes	dw	064h,0			;; Cirrus GD 64xx
		dw	037h,0
		dw	0,0
ChipsModes	dw	070h,0			;; Chips & Tech modes
		dw	072h,0
		dw	0,0
CompaqModes	dw	059h,0			;; Compaq modes
		dw	0,0
		dw	0,0
EverexModes	dw	070h,02h		;; Everex modes
		dw	070h,20h
		dw	070h,21h
GenoaModes	dw	06Ah,00h		;; Genoa modes
		dw	05Fh,00h
		dw	0,0
HMCModes	dw	028h,0
		dw	029h,0
		dw	0,0
IITAGxModes	dw	05bh,0
		dw	05fh,0
		dw	0,0
MXICModes	dw	055h,0			;; MX 68010
		dw	056h,0
		dw	0,0
NCRModes	dw	058h,0			;; NCR 77C2X
		dw	05dh,0
		dw	067h,0
OakModes	dw	052h,0			;; OakTech modes
		dw	056h,0
		dw	0,0
Oak77Modes	dw	052h,0			;; Oak-077 modes
		dw	056h,0
		dw	058h,0
ParadiseModes	dw	058h,0			;; Paradise modes
		dw	05Dh,0
		dw	064h,0
P2000Modes	dw	02ah,0			;; Primus 2000
		dw	030h,0
		dw	036h,0
RealtekModes	dw	01fh,0			;; Realtek
		dw	021h,0
		dw	02ah,0
S3Modes		dw	04f02h,0102h		;; S3 modes
		dw	04f02h,0104h
		dw	04f02h,0106h
Trident89Modes	label	word
Trident88Modes	dw	05bh,0			;; Trident 8800/8900 modes
		dw	05fh,0
		dw	0,0
Tseng30Modes	dw	029h,0
		dw	037h,0
		dw	0,0
TsengW32Modes	label	word
Tseng40Modes	dw	029h,0			;; Tseng 3000/4000 modes
		dw	037h,0
		dw	03dh,0
UMCModes	dw	06ah,0
		dw	05fh,0
		dw	07ah,0
Video7Modes	dw	06f05h,062h		;; Video-7 modes
		dw	06f05h,065h
		dw	0,0
WeitekModes	dw	058h,0
		dw	05dh,0
		dw	0,0
VesaModes	dw	04f02h,0102h		;; Vesa modes
		dw	04f02h,0104h
		dw	04f02h,0106h
VESAMODESIZE	EQU	$-VesaModes

	IF	BGIVERSION GE 3
_DATA	ENDS
	ENDIF

end

