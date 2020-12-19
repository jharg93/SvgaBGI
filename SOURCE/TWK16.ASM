;; Tweaked 16 Colour BGI Driver Source
;;
;; Version:	$Revision:   1.14  $
;;
;; Copyright (c) 1991-94, Jordan Hargrave <jordan_hargrave@hotmail.com>
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
;;  $Log:   C:/svga/rcs/twk16.asv  $
;  
;     Rev 1.14   23 Aug 1994  0:05:42   JORDAN
;  
;     Rev 1.13   20 Jul 1994 22:09:20   JORDAN
;  Added support for HGXMOUSE driver.
;  
;     Rev 1.12   09 Jun 1994 23:48:30   JORDAN
;  
;     Rev 1.11   14 May 1994 19:36:06   JORDAN
;;
.186

	IFNDEF	BGIVERSION
BGIVERSION	EQU	2		;; BGI revision version
					;; 2 for most BC/TC and BP/TP
					;; 3 for BP7.0 protected mode
	ENDIF
MaxMode		EQU	7		; Maximum mode number supported+1
;; Change here for font used:
;;    8 = 8x8 font
;;   14 = 8x14 font
;;   16 = 8x16 font
TEXTBYTES	EQU	8

INCLUDE		common.inc		; Common defines
SC_INDEX	EQU	03c4h
GC_INDEX	EQU	03ceh
CRTC_INDEX	EQU	03d4h
MISC_OUTPUT	EQU	03c2h
MAP_MASK	EQU	2
READ_MAP	EQU	4

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

;--------------------------------------------------------------------
restregs:	push	dx			;; Restore default EGA/VGA regs
		mov	dx,GC_INDEX
		xor	ax,ax
		out	dx,ax			;; Reset Set/Reset reg
		inc	ax
		out	dx,ax			;; Reset Enable S/R reg.
		mov	al,3
		out	dx,ax			;; Data/Func def.
		mov	al,05h
		out	dx,ax			;; Default Mode value
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
		shr	bx,1
		shr	bx,1
		shr	bx,1
		mul	xbytes
		add	bx,ax
		ret

;--------------------------------------------------------------------
;;INSTALL - Installs the driver

install:	cmp	al,1
		jnz	notmodequery
		mov	cx,MaxMode
		ret
notmodequery:	cmp	cl,MaxMode-1
		jle	TopMode
		mov	cl,MaxMode-1
TopMode:	LoadDataSeg	es
		xor	ch,ch
		mov	si,cx
		shl	si,1
		test	al,al
		jz	notmodename
		mov	bx,ModeTable[si]
		ret
notmodename:	mov	curr_mode,cl
		push	es
		mov	ax,01130h	;; Load pointer to the ROM 
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
		pop	es
		mov	bx,[StatTable+si]	;; Get address of DIT
		mov	ax,[bx+yefres]
		mov	ysiz,ax
		mov	ax,[bx+xefres]
		inc	ax
		mov	xsiz,ax
		mov	cl,3
		shr	ax,cl
		mov	xbytes,ax		;; Calculate # of bytes/row
InstallOK:	ret

;---------------------------------------------------------------------
;;INIT - Changes into graphics mode
;; ES:BX=Device Information Table

init:		mov	bl,curr_mode
		xor	bh,bh
		shl	bx,1
		mov	si,TweakModes[bx]
		mov	ax,012h			;;Start with 16-color mode
		int	010h
is256:		push	es
		mov	ax,040h
		mov	es,ax
		mov	dx,word ptr es:[63h]
		add	dx,6
vrdly1:		in	al,dx
		test	al,8
		jnz	vrdly1
vrdly2:		in	al,dx
		test	al,8
		jz	vrdly2

		cli
		mov	cl,0e7h
		cmp	curr_mode,0
		jnz	setmiscoreg
		mov	cl,0e3h
setmiscoreg:	mov	dx,SC_INDEX
		mov	ax,0100h
		out	dx,ax
		mov	dx,MISC_OUTPUT
		mov	al,cl
		out	dx,al
		mov	dx,SC_INDEX
		mov	ax,0300h
		out	dx,ax
		mov	dx,word ptr es:[63h]
		mov	al,11h
		mov	ah,byte ptr [si+11h]
		and	ah,07fh
		out	dx,ax
		mov	cx,018h
		xor	bx,bx
crtcloop:	mov	al,bl
		mov	ah,byte ptr [bx+si]
		out	dx,ax
		inc	bx
		loop	crtcloop
		sti
		pop	es

	;; Enable HGXMOUSE driver
		Enable_Mouse	MODE_PL4
	IF	BGIVERSION GE 3
		mov	ax,SEGA000
		mov	VidMem,ax
	ENDIF
		ret

;---------------------------------------------------------------------
;;POST - Exit from graphics mode

post:		Disable_Mouse
		ret

;---------------------------------------------------------------------
;;CLEAR - Clears the screen

clear:		push	word ptr fillpatnum	;; Save old fillpattern
		mov	fillpatnum,0		;; Empty fill pattern
		xor	ax,ax			;; 0,0
		xor	bx,bx
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

vect:		push	dx
		push	ax
		mov	dx,GC_INDEX		;; Set up registers
		mov	ah,linecolour		;; Set/Reset register
		xor	al,al
		out	dx,ax
		mov	ax,0f01h		;; Enable Set/Reset register
		out	dx,ax
		cmp	writemode,1
		jnz	noxor
		mov	ax,01803h
		out	dx,ax			;; Data Rotate/Function (XOR_PUT)
noxor:		mov	al,08
		out	dx,ax
		pop	ax
		pop	dx
		cmp	ax,cx
		jle	vok
		xchg	ax,cx		;; Make sure x coord increases
		xchg	bx,dx

vok:		push	cx
		mov	ch,080h
		and	cl,7
		sar	ch,cl
		mov	fill_bits[2],ch		;; Right edge, solid

		mov	cl,al
		and	cl,7
		mov	ch,0ffh
		shr	ch,cl
		mov	fill_bits[1],ch		;; Left edge, solid
		mov	ch,080h
		shr	ch,cl
		mov	fill_bits,ch		;; Left edge, pixel
		pop	cx

		mov	bp,curr_linestyle	;; Current line bitpattern

		cmp	dx,bx			;; if (y1 == y2) horiz_line
		jnz	no_hline
		jmp	horiz_line
no_hline:	cmp	ax,cx			;; if (x1 == x2) vert_line
		jnz	no_vline

;;-----------------------------------------
;; Optimized vertical lines
vert_line:	cmp	dx,bx
		jge	vlstory
		xchg	bx,dx
vlstory:	sub	dx,bx
		mov	cx,dx
		inc	cx
		call	CalcAddr		;; Calculate address
		mov	dx,GC_INDEX+1
		mov	al,fill_bits		;; Left Edge, pixel
		out	dx,al
runloop:	ror	bp,1			;; Rotate line pattern
		jnc	novplot
		xchg	ah,es:[bx]		;; Store value
novplot:	add	bx,xbytes
		loop	runloop
		jmp	restregs

;;-----------------------------------------
;; Bresenham's algorithm
no_vline:	xor	si,si
		mov	di,xbytes	;; Y increment
		sub	cx,ax		;; Calculate delta-x
		sub	dx,bx		;; Check if Y2<Y1
		jge	story
		neg	di		;; If so, take absolute value and
		neg	dx		;; negate y-increment
story:		mov	deldxy,di	;; Change in x,y-diagonal
		cmp     cx,dx		;; Check if delta-x >= delta-y
		jge     stordelsxy
		mov	si,di
		xchg	cx,dx
stordelsxy:	mov	delsxy,si	;; Change in x,y-straight
		shl	dx,1
		mov	delse,dx	;; Change in errorterm-straight
		sub	dx,cx
		mov	si,dx		;; SI is errorterm
		sub	dx,cx
		mov	delde,dx	;; Change in errorterm-diagonal

		call	CalcAddr	;; Calculate offset of first pixel in line
		inc	cx

		mov	di,cx
		mov	ch,fill_bits		;; Left edge, pixel
		mov	dx,GC_INDEX+1
linloop:	mov	al,ch
		out	dx,al
		ror	bp,1			;; Rotate line bitpattern
		jnc	NoPlot
		xchg	al,es:[bx]		;; Store pixel

NoPlot:		push	di
		mov	di,si
		rol	di,2
		and	di,2
		mov	ax,ds:[di+deldxy]
		add	si,ds:[di+delde]
		shr	di,1
		neg	di
		and	di,ax
		pop	di
		jnz	astgt
		ror	ch,1
		adc	ax,0
astgt:		add	bx,ax
		dec	di
		jnz	linloop
		jmp	restregs

;;-----------------------------------------
;; Optimized horizontal lines
horiz_line:	push	ax
		shr	cx,1
		shr	cx,1
		shr	cx,1
		shr	ax,1
		shr	ax,1
		shr	ax,1
		sub	cx,ax
		pop	ax
		call	CalcAddr	;; Calculate address of 1st pixel
		mov	di,bx
hnoswitch:	mov	bx,bp			;; Current linestyle
		mov	dx,GC_INDEX+1
		mov	al,fill_bits[1]		;; Left Edge, solid
		jcxz	onebyte			;; Jump if line is contained in a single byte
		and	al,bh			;; Mask with linestyle
		out	dx,al
		xchg	ah,es:[di]		;; Store left pixel
		inc	di
		dec	cx
		jcxz	twobyte			;; Jump if line is contained in two bytes
		mov	al,bl			;; Set bitmask
		xchg	bh,bl
		out	dx,al
hloop:		xchg	al,es:[di]		;; Store middle pixels
		inc	di
		loop	hloop
twobyte:	mov	al,0ffh
onebyte:	and	al,bl
		and	al,fill_bits[2]		;; Right Edge
		out	dx,al			;; Set right bitmask
		xchg	al,es:[di]		;; Store right pixel
		jmp	restregs

;---------------------------------------------------------------------
;;PATBAR - Draws patterned bar from (X1,Y1)-(X2,Y2)
;; AX=Upper left X coordinate
;; BX=Upper left Y coordinate
;; CX=Lower right X coordinate
;; DX=Lower right Y coordinate

patbar:		push	es
		mov	es,VidMem
		cmp	ax,cx			;; Check if X2<X1
		jl	Xok
		xchg	ax,cx			;; Swap X1 & X2

Xok:		cmp	bx,dx			;; Check if Y2<Y1
		jl	Yok
		xchg	dx,bx			;; Swap Y1 & Y2

Yok:		sub	dx,bx			;; Calculate bar height
		mov	bp,dx

		push	cx			;; Calculate left and right edge
		mov	dx,0ff80h		;; bitmasks
		and	cx,7
		sar	dl,cl
		mov	cx,ax
		and	cx,7
		shr	dh,cl
		mov	word ptr fill_bits,dx
		pop	cx

		push	ax
		shr	ax,1
		shr	ax,1
		shr	ax,1
		shr	cx,1
		shr	cx,1
		shr	cx,1
		sub	cx,ax			;; Calculate bar width
		mov	bar_xsiz,cx

		mov	di,xbytes		;; Calculate next offset
		sub	di,cx
		mov	next_row,di

		mov	si,bx			;; Calculate pattern row
		pop	ax
		call	CalcAddr		;; Calculate initial offset
		mov	di,bx

		mov	dx,GC_INDEX
		mov	ax,0205h		;; Write mode 2
		out	dx,ax
		mov	al,8
		out	dx,al
		inc	dl

PatLoopY:	and	si,7
		mov	cx,bar_xsiz
		call	fstpatlin
		inc	si			;; Increment pattern row
		add	di,next_row		;; Calculate offset of next
		dec	bp			;; Decrease y counter
		jns	PatLoopY
		pop	es
		jmp	restregs

fstpatlin:	mov	ah,fillcolour
		mov	bx,word ptr fill_bits
		push	bx
		mov	bl,bh
		mov	bh,fillpatnum
		test	bh,bh
		jz	@fstp00
		dec	bh
		jnz	@fstp01
		mov	bh,0ffh
		jmp	@fstp00
@fstp01:	mov	bh,[si+curr_fillpat]	;; Get fill bitpattern
@fstp00:	jcxz	fstpat00		;; jump if only one byte wide
		call	fstpat01		;; Set left edge
		mov	bl,0ffh			;; Mask for middle bytes
		inc	di
		dec	cx
		jcxz	fstpat00		;; jump if only two bytes wide
		mov	al,bl			;; Set mask
		out	dx,al
		push	cx
		push	di
		xor	al,al
		repz	stosb			;; Zero out middle bytes (set all planes to black)
		pop	di
		pop	cx
		mov	al,bh			;; Set fill pattern bitmask
		out	dx,al
k_loop:		mov	al,ah
		xchg	al,es:[di]		;; Store middle value
		inc	di
		loop	k_loop
fstpat00:	pop	cx
		and	bl,cl
fstpat01:	mov	al,bh
		and	al,bl
		out	dx,al
		mov	al,ah
		xchg	al,es:[di]		;; Store color
		mov	al,bh
		not	al
		and	al,bl
		out	dx,al
		xor	al,al
		xchg	al,es:[di]		;; Zero out other planes
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
		mov	dx,03c8h
		out	dx,al
		inc	dx
		mov	al,bl
		out	dx,al
		mov	al,cl
		out	dx,al
		mov	al,ah
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
		mov	cl,3
		shl	ax,cl
		mov	si,ax
		add	si,offset fillpatterns	;; Get offset of pattern out
		jmp	short movepattern	;; of fill table

usrfillsty:	mov	si,bx			;; Get offset of user pattern
		push	es
		pop	ds

movepattern:	mov	di,offset curr_fillpat
		LoadDataSeg	es
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
		mov	cx,textysiz
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
		mov	cx,TEXTBYTES
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
		mov	si,bx
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
		mov	dx,GC_INDEX
		mov	ax,0205h
		out	dx,ax
		mov	ax,8008h
		shr	ah,cl
		out	dx,ax
		xchg	ch,es:[bx]		;; Store pixel
		pop	es
		pop	cx
		jmp	restregs

;---------------------------------------------------------------------
;;BITMAPUTIL - Returns pointer to bitmap routines
bitmaputil:	LoadDataSeg	es
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
		shr	si,1		;; Calculate address
		shr	si,1
		shr	si,1
		shr	di,1
		shr	di,1
		shr	di,1
		inc	di
		mov	bar_xsiz,di
		mul	xbytes
		add	si,ax		;; SI holds offset
		mov	bp,es:[bx+2]
		mov	di,bx
		add	di,4

		mov	dx,GC_INDEX
@SaveBit00:	mov	ax,0304h
Getnoswitch:	out	dx,ax			;; Set Read Plane
		push	si
		mov	bx,bar_xsiz
@SaveBit01:	push	ax
		push	es
		mov	es,VidMem
		cmp	si,0ffffh		;; Check for last byte in row 511 in 1024x768 mode
		jz	PartWord		;; so that a segment violation error isn't raised!
		mov	ah,es:[si+01]
PartWord:	mov	al,es:[si]
		pop	es
		inc	si
		rol	ax,cl			;; Rotate bits
		stosb				;; store value
		test	di,di
		jnz	NIseg			;; Test for >64k access
		mov	ax,es
		add	ax,1000h
		mov	es,ax
		cmp	ax,09000h
		ja	savebmapxit
NIseg:		pop	ax
		dec	bx
		jnz	@SaveBit01
		pop	si
		dec	ah			;; Decrease plane #
		jns	Getnoswitch
		add	si,xbytes
		dec	bp
		jns	@SaveBit00
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
;; AL=Logical restore operation

;; Values for Data Rotate/Function registers
;; COPY_PUT,XOR_PUT,OR_PUT,AND_PUT
;; NOT_PUT,XNOR_PUT,NOR_PUT,NAND_PUT

Chk64:		push	ax
		mov	ax,es
		add	ax,1000h
		mov	es,ax
		cmp	ax,09000h
		pop	ax
		ret

setmask:	push	ax		;; Sets bitmask
		mov	ah,bh
		mov	al,8
		out	dx,ax
		pop	ax
		mov	es,VidMem
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
		shr	bp,1
		shr	bp,1
		shr	bp,1

		shr	ax,1
		shr	ax,1
		shr	ax,1
		mov	fill_bits[3],al		;; # of source bytes
		mov	ax,bp

		shr	di,1
		shr	di,1
		shr	di,1
		sub	ax,di
		mov	fill_bits[4],al		;; # of destination bytes

		mov	ax,dx
		mul	xbytes
		add	di,ax

		mov	dx,GC_INDEX
		mov	ah,[Logical+si]		;; Value for Rotate/Func register
		mov	al,3
		out	dx,ax			;; Set Data Rotate/Function
		mov	ax,0805h		;; Set read & write mode
		out	dx,ax
		mov	ax,7			;; Set Color Compare register
		out	dx,ax			;; (reads will always return 0xFF)

		mov	si,bx
		mov	ax,es:[si+2]
		inc	ax
		mov	next_row,ax
		add	si,4
		mov	bl,fill_bits[3]		;; nSb
		xor	bh,bh
		mov	bp,bx

@Blt01:		mov	ax,802h
@Blt02:		push	di
		push	ax
		mov	dx,SC_INDEX
		out	dx,ax
		mov	dl,0ceh
		xor	ax,ax
		mov	bh,fill_bits[1]		;; Lmask
		push	bp
@Blt03:		shl	ax,cl
		mov	al,es:[si]		;; Read source byte
		inc	si
		jnz	@Blt04			;; Check for >64k access
		call	Chk64
		ja	putbmapxit
@Blt04:		xchg	cl,ch
		shl	ax,cl			;; Rotate data bits
		xchg	cl,ch
		cmp	fill_bits,4			;; NOT_PUT
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
		jns	@Blt03
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
		jnz	@Blt02
		add	di,xbytes
		dec	word ptr next_row
		jnz	@Blt01
PutImXit:	mov	dx,SC_INDEX
		mov	ax,0f02h
		out	dx,ax
		jmp	restregs
putbmapxit:	pop	bp
		pop	ax
		pop	di
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
		mov	cx,00fh
		ret

;; Get offset of colour table
clrtable:	LoadDataSeg	es
		mov	bx,offset colourtable
		ret

;---------------------------------------------------------------------
; Now for the miscellaneous routines

;; BITS_PER_PIX - Returns the pixel colour depth
bits_per_pix	proc	far
		mov	ax,4
		ret
bits_per_pix	endp

;; SETDRAWPAGE - Sets the page for drawing graphics
setdrawpage	proc	far
		ret
setdrawpage	endp

;; SETVISPAGE - Sets the visual graphics page
setvispage	proc	far
		ret
setvispage	endp

getdrawpage	proc
		xor	ax,ax
		xor	dx,dx
		ret
getdrawpage	endp

;; SETWRITEMODE - Sets the line drawing mode (either COPY_PUT or XOR_PUT)
setwritemode	proc	far
		and	ax,1
		push	ds
		LoadDataSeg	ds
		mov	writemode,ax
		pop	ds
		ret
setwritemode	endp

	IF	BGIVERSION GE 3
_TEXT	ENDS

_DATA	SEGMENT	PARA	PUBLIC	'DATA'

	assume ds:_DATA, cs:Nothing

InitTable	EQU	$
NRealSegs       db      4
RealSegOfs      dw      SegTable
NIntVects       db      1
IntVecOfs       dw      VectTable
NRealBlocks     db      0
RealBlockOfs    dw      0
DSinRealMem     db      1
RealModeDS      dw      0
CurOpMode       db      0

SegTable	EQU	$
SEG0040         dw      00040h
SEGA000         dw      0A000h
SEGC000		dw	0C000h
SEGF000         dw      0F000h

VectTable	EQU	$
ChrGen          dd      0000001fh

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
Stat0 Status<,,703,527,703,527,,,10000,,,,>		;;704x528x16
Mode0 db	22,"Tweaked VGA 704x528x16",0
Stat1 Status<,,719,539,719,539,,,10000,,,,>		;;720x540x16
Mode1 db	22,"Tweaked VGA 720x540x16",0
Stat2 Status<,,735,551,735,551,,,10000,,,,>		;;736x552x16
Mode2 db	22,"Tweaked VGA 736x552x16",0
Stat3 Status<,,751,563,751,563,,,10000,,,,>		;;752x564x16
Mode3 db	22,"Tweaked VGA 752x564x16",0
Stat4 Status<,,767,575,767,575,,,10000,,,,>		;;768x576x16
Mode4 db 	22,"Tweaked VGA 768x576x16",0
Stat5 Status<,,783,587,783,577,,,10000,,,,>		;;784x588x16
Mode5 db 	22,"Tweaked VGA 784x588x16",0
Stat6 Status<,,799,599,799,599,,,10000,,,,>		;;800x600x16
Mode6 db 	22,"Tweaked VGA 800x600x16",0

;; Table of structures
StatTable	dw	Stat0, Stat1, Stat2, Stat3, Stat4, Stat5, Stat6

;; Table of mode names
ModeTable	dw	Mode0, Mode1, Mode2, Mode3, Mode4, Mode5, Mode6

VidMem		dw	0A000h		;; Offset of video memory

TweakModes	dw	x704y528
		dw	x720y540
		dw	x736y552
		dw	x752y564
		dw	x768y576
		dw	x784y588
		dw	x800y600

x704y528	db	068h,057h,058h,08Bh	; CRTC Registers
		db	059h,086h,03EH,0F0h
		db	000h,060h,000h,000h
		db	000h,000h,002h,03Dh
		db	019h,08Bh,00Fh,02Ch
		db	000h,018h,038h,0E3h
		db	0FFh
x720y540	db	06Ah,059h,05Ah,08Dh	; CRTC Registers
		db	05Eh,08Bh,04AH,0F0h
		db	000h,060h,000h,000h
		db	000h,000h,002h,049h
		db	024h,086h,01Bh,02Dh
		db	000h,024h,044h,0E3h
		db	0FFh
x736y552	db	06Ch,05Bh,05Ch,08Fh	; CRTC Registers
		db	05Fh,08Ch,056H,0F0h
		db	000h,060h,000h,000h
		db	000h,000h,002h,055h
		db	02Bh,08Dh,027h,02Eh
		db	000h,030h,050h,0E3h
		db	0FFh
x752y564	db	 6Eh, 5Dh, 5Eh, 91h	; CRTC Registers
		db	 62h, 8Fh, 62H,0F0h
		db	  0h, 60h,  0h,  0h
		db	  0h,  0h,  2h, 61h
		db	 37h, 89h, 33h, 2Fh
		db	  0h, 3Ch, 5Ch,0E3h
		db	0FFh
x768y576	db	 70h, 5Fh, 60h, 93h	; CRTC Registers
		db	 66h, 93h, 6EH,0F0h
		db	  0h, 60h,  0h,  0h
		db	  0h,  0h,  2h, 6Dh
		db	 43h, 85h, 3Fh, 30h
		db	  0h, 48h, 68h,0E3h
		db	0FFh
x784y588	db	 72h, 61h, 62h, 95h	; CRTC Registers
		db	 69h, 96h, 7AH,0F0h
		db	  0h, 60h,  0h,  0h
		db	  0h,  0h,  2h, 79h
		db	 4Fh, 81h, 4Bh, 31h
		db	  0h, 54h, 74h,0E3h
		db	0FFh
x800y600	db	 74h, 63h, 64h, 97h	; CRTC Registers
		db	 68h, 95h, 86H,0F0h
		db	  0h, 60h,  0h,  0h
		db	  0h,  0h,  2h, 85h
		db	 5Bh, 8Dh, 57h, 32h
		db	  0h, 60h, 80h,0E3h
		db	0FFh

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
writemode	dw	?		;; Current write mode
Logical		DB	00h,018h,010h,08h
		DB	00h,018h,010h,08h
linecolour	db	?		;; Current line drawing colour
curr_linestyle	dw	0ffffh		;; Current line style
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

	IF	BGIVERSION GE 3
_DATA	ENDS
	ENDIF

end

