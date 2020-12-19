;; Tweaked Text Colour BGI Driver Source
;;
;; Version:	$Revision:   1.2  $
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
;;  $Log:   C:/svga/rcs/twktext.asv  $
;  
;     Rev 1.2   23 Aug 1994  0:05:46   JORDAN
;  
;     Rev 1.1   26 Jul 1994 22:47:54   JORDAN
;  Line/Patbar/GetPixel working
;  (line is slow..)
;  
;     Rev 1.14   20 Jul 1994 22:09:28   JORDAN
;  Added support for HGXMOUSE driver.
;  
;     Rev 1.13   09 Jun 1994 23:48:36   JORDAN
;  
;     Rev 1.12   14 May 1994 19:36:08   JORDAN
;;
.186

	IFNDEF	BGIVERSION
BGIVERSION	EQU	2		;; BGI revision version
					;; 2 for most BC/TC and BP/TP
					;; 3 for BP7.0 protected mode
	ENDIF
MaxMode		EQU	1		; Maximum mode supported
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

fontHeight	EQU	32
fontChars	EQU	512
fontSize	EQU	fontHeight * fontChars
screenWidth	EQU	40
screenHeight	EQU	350/fontHeight

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

INCLUDE		macros.inc

;; Restregs - restore default register values
restregs:	mov	dx,GC_INDEX
		mov	ax,3
		out	dx,ax
		ret

;--------------------------------------------------------------------
;;INSTALL - Installs the driver

install:	cmp	al,1
		jnz	notmodequery
		mov	cx,MaxMode		;; Return # of modes
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
		mov	bx,[si+ModeNameTable]	;; Return mode name
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

		mov	ax, screenHeight*fontHeight
		mov	xbytes,ax
InstallOk:	ret

;---------------------------------------------------------------------
;;INIT - Changes into graphics mode
;; ES:BX=Device Information Table

init:		
	;; Set 350 line mode
		mov	ax, 1201h
		mov	bx, 0030h
		int	010h

	;; Set 40x25 mode
		mov	ax, 01h
		int	010h

	;; Set lines per char
		mov	ax, 01110h
		mov	bh, fontHeight
		xor	bl, bl
		mov	cx, 512
		xor	dx, dx
		mov	si, cs
		mov	es, si
		xor	bp, bp
		int	010h

	;; Set palette color for color 7
		mov	ax, 1000h
		mov	bx, 03f07h
		int	010h

	;; Set character generators A=1 and B=5
		outpw	03C4h, 02003h

	;; Fill screen with 512 unique characters
	;; Characters are organized like this:
	;;	0 n   2n   3n   ...
	;;	1 n+1 2n+1 3n+1 ...
	;;	2 n+2 2n+2 3n+2 ...
	;;	...................

		mov	es, [VidMem]
		xor	di, di
		mov	cx, screenWidth
		xor	ax, ax			;; count
		mov	dx, 0700h		;; color
@charHLoop:	push	cx
		push	di
		mov	cx, screenHeight
@charVLoop:	cmp	ax, 256
		jnz	@notUpchar
		or	dx, 800h		;; Mask for 2nd charset
@notUpchar:	push	ax
		or	ax, dx
		mov	word ptr es:[di], ax
		pop	ax
	;; Increase Y coordinate
		add	di, screenWidth*2
		inc	ax
		loop	@charVLoop
		pop	di
		pop	cx
	;; Increase X coordinate
		add	di, 2
		loop	@charHLoop

	;;---------------------------------------------------
	;; Enable bitplane 2 (character definition map)
	plane = 2
		outpw	03C4h, <(((1 SHL plane) SHL 8) OR 2)>
	;; Sequential addressing
		outpw	03c4h, 0704h
	;; Disable odd-even addressing
		outpw	03ceh, 05h
	;; Memory map = A000-AFFF
		outpw	03ceh, 0406h
	;; Select map 2 for CPU reads
		outpw	03ceh, <((plane SHL 8) OR 4)>
	;; Color-don't care register
		outpw	03ceh, 0ff07h

	;; Clear font memory
		call	clear

	;; Enable mouse
		Enable_Mouse	MODE_TWKTEXT
		ret

;---------------------------------------------------------------------
;;POST - Exit from graphics mode

post:		Disable_Mouse

	;; Set 50 lines mode
		mov	ax, 1202h
		mov	bx, 0030h
		int	010h

		ret

;---------------------------------------------------------------------
;;CLEAR - Clears the screen

	;; Clear font memory
clear:		mov	es, [FontMem]
		mov	cx, fontSize
		xor	al, al
		xor	di, di
		repz	stosb
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
;;  Bresenhams ine drawing algorithm from Bluebook of Assembly Routines for 
;;  the IBM PC & XT, with minor modifications :jph

vect:		mov	si, 1			;; X increment
		mov	di, 1			;; Y increment

		cmp	ax, cx
		jle	vok
		xchg	ax, cx
		xchg	bx, dx

vok:		sub	cx,ax		;; Check if X2<X1
		jge	storx
		neg	si		;; If so, take absolute value and
		neg	cx		;; negate x-increment

storx:		mov	deldx,si
		sub	dx,bx		;; Check if Y2<Y1
		jge	story
		neg	di		;; If so, take absolute value and
		neg	dx		;; negate y-increment

story:		mov	deldy,di	;; Diagonal increment
		cmp     cx,dx
		jge     stordelsxy
		mov	word ptr [delsx], 0	;; Straight increment - Y major
		mov	word ptr [delsy], di
		xchg	cx,dx
		jmp	short sortdelsx
stordelsxy:	mov	word ptr [delsx], si	;; Straight increment - X major
		mov	word ptr [delsy], 0
sortdelsx:	shl	dx,1
		mov	delse,dx	;; Errorterm increment if next pixel 
					;; is a straight move along line
		sub	dx,cx
		mov	di,dx		;; Errorterm
		sub	dx,cx
		mov	delde,dx	;; Errorterm increment if next pixel 
					;; is a diagonal move along line

	;; AX = X
	;; BX = Y
	;; CX = count
	;; DI = errorterm

		inc	cx
		mov	bp, curr_linestyle
linloop:	ror	bp, 1
		jnc	NoPlot

	;; Plot pixel
		push	ax
		push	bx
		call	putpixel
		pop	bx
		pop	ax

	;; Use straight or diagonal increment based on sign of errorterm
	;; Check upper bit to see if errorterm is negative.  If negative, 
	;; use straight increment, else increment along the diagonal
NoPlot:		mov	si, di
		rol	si, 2
		and	si, 2
		add	di, ds:[si+delde]	;; increment errorterm
		add	ax, ds:[si+deldx]
		add	bx, ds:[si+deldy]

	;; Decrease major axis count
		loop	linloop
		ret

;---------------------------------------------------------------------
;;PATBAR - Draws patterned bar from (X1,Y1)-(X2,Y2)
;; AX=Upper left X coordinate
;; BX=Upper left Y coordinate
;; CX=Lower right X coordinate
;; DX=Lower right Y coordinate

patbar:		push	es
		mov	es, [FontMem]
		cmp	ax,cx			;; Check if X2<X1
		jl	Xok
		xchg	ax,cx			;; Swap X1 & X2

Xok:		cmp	bx,dx			;; Check if Y2<Y1
		jl	Yok
		xchg	dx,bx			;; Swap Y1 & Y2

Yok:		sub	dx,bx			;; Calculate bar height
		mov	bp, dx
		mov	si, bx

	;; Calculate left & right masks
		push	cx
		mov	dx, 0ff80h
		and	cx, 7
		sar	dl, cl			;; right mask
		mov	cx, ax
		and	cx, 7
		shr	dh, cl			;; left mask
		mov	word ptr [fill_bits], dx
		pop	cx

	;; Calculate bar width
		push	ax
		shr	ax, 3
		shr	cx, 3
		sub	cx, ax
		mov	[bar_xsiz], cx
		pop	ax

	;; Calculate address
		mov	cx, ax
		shr	ax, 3
		mul	[xbytes]
		add	bx, ax
		mov	di, bx

	;; CX = X
	;; BX = offset
PatLoopY:	and	si,7
		mov	cx, [bar_xsiz]
		push	di
		call	fstpatlin
		pop	di
		inc	di			;; Increase Y by one
		inc	si
		dec	bp
		jns	PatLoopY
		pop	es
		ret

;; Draw a patterned scanline
	;; BH = Left mask, BL = Right mask
fstpatlin:	mov	bx, word ptr [fill_bits]
		push	bx

	;; BH = Left mask, BL = Left mask
		mov	bl, bh
		mov	bh, [fillpatnum]
		test	bh, bh
		jz	@fstp00

	;; BH = fillpatnum-1, BL = Left mask
		dec	bh
		jnz	@fstp01

	;; BH = 0ffh, BL = Left mask
		mov	bh, 0ffh
		jmp	short @fstp00

	;; BH = pattern, BL = Left mask
@fstp01:	mov	bh, curr_fillpat[si]

	;; Jump if only one byte wide
@fstp00:	jcxz	fstpat00
		call	fstpat01		;; Set left edge
		mov	bl, 0ffh		;; Mask for middle bytes
		add	di, [xbytes]

	;; Jump if only 2 bytes wide
		dec	cx
		jcxz	fstpat00
k_loop:		mov	es:[di], bh
		add	di, [xbytes]
		loop	k_loop
fstpat00:	pop	cx
		and	bl, cl
fstpat01:	mov	al, bh			;; AL = pattern
		and	al, bl
		not	bl
		and	es:[di], bl
		or	es:[di], al
		ret

;---------------------------------------------------------------------
;;PALETTE - Palette manipulation
;; Upper two bits of AX:
;;  00b - BX contains colour, AX is index		[Not Imp]
;;  01b - Not used
;;  10b - BX=Red, CX=Green, DX=Blue, AX is index
;;  11b - BX=background colour				[Not Imp]

palette:	xchg	bl,bh
		shl	ah,1		;; Test first bit
		jc	p_up
p_up:		shl	ah,1		;; Test second bit
		jnc	p_rgb
		ret
p_rgb:		mov	ah,dl		;; AX = BBBBBBBBIIIIIIII
					;; CX = 00000000GGGGGGGG
					;; BX = 00000000RRRRRRRR
		mov	dx,03c8h	;; VGA DAC port
		out	dx,al
		inc	dx
		mov	al,bl		;; Out Red
		out	dx,al
		mov	al,cl		;; Out Green
		out	dx,al
		mov	al,ah		;; Out Blue
		out	dx,al
		WaitForRetrace
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
		sub	al,2			;; Decrease fill number by 2
		js	fillstyxit		;; (Empty & Solid)
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
		mov	cx,8
patpr:		lodsb				;; Store fill pattern
		mov	ah,al
		xor	al,al
		push	cx
		mov	cx,8
patrot:		shr	ah,1
		rcl	al,1
		loop	patrot
		pop	cx
		stosb
		loop	patpr
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
		mov	textinc,bx		;; Calculate x-increment
		shl	bx,3			;; for font generation
		mov	textxsiz,bx
		mov	textysiz,cx
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
		call	getpixel
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
		call	getpixel
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
		call	getpixel
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
		mov	ax,-1
		jmp	short @ScnLin03
@ScnLinExit:	sub	ax,ax
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

FloodFill:	ret

		mov	word ptr FillD,-1
		mov	BrdrClr,cl
		mov	si,ax			;; SeedX
		mov	di,bx			;; SeedY
		call	getpixel		;; TstPix
		cmp	dl,BrdrClr
		jne	@FldFill_00
		jmp	short @FldFill_Exit
@FldFill_00:	push	di			;; SeedY
		push	si			;; SeedX
		call	ScanLeft
		add	sp,4
		mov	si,ax			;; SeedX
		mov	Xvals,ax
		mov	Yvals,di		;; SeedY
		mov	StkPtr,1
		push	di			;; SeedY
		push	si			;; SeedX
		call	ScanRight
		add	sp,4
		mov	CurrXR,ax
		jmp	short @FldFill_03
@FldFill_01:	mov	bx,StkPtr
		test	bx,bx
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
;;
;; Code from John Bridges' VGAKIT

getpixel:	ret

		mov	cx,ax
		xchg	ax,bx
		shr	bx,1
		shr	bx,1
		mul	xbytes		;; Calculate offset of pixel
		add	bx,ax
		add	bx,PageOfs
		and	cl,3
		mov	ah,cl
		mov	al,READ_MAP
		mov	dx,GC_INDEX
		out	dx,ax
		mov	es,VidMem
		xor	dx,dx
		mov	dl,es:[bx]	;; Read pixel colour
		ret

;---------------------------------------------------------------------
;;PUTPIXEL - Writes a pixel to the screen
;; AX=X coordinate of the seed point
;; BX=Y coordinate of the seed point
;; DL=colour of the seed point
;;
;; Code from John Bridges' VGAKIT

putpixel:	push	cx
		mov	cx, ax
		shr	ax, 3
		mul	[xbytes]
		add	bx, ax

		mov	es, [FontMem]
		and	cl, 7
		mov	ch, 080h
		shr	ch, cl

		or	es:[bx], ch
		pop	cx
		ret

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

savebitmap:	ret

		mov	ax,es:[bx]	;; Width of image-1
		inc	ax
		mov	bar_xsiz,ax

		mov	ax,dx		;; Calculate offset of first row
		mov	di,cx
		shr	di,1
		shr	di,1
		mul	xbytes
		add	di,ax
		add	di,PageOfs
		and	cl,3
		mov	ah,cl
		mov	si,es:[bx+2]	;; Height of image-1
		add	bx,4

		mov	dx,GC_INDEX
GetLoopY:	mov	cx,bar_xsiz
		push	ax
		push	di
GetLoopX:	mov	al,READ_MAP
		out	dx,ax
		push	es
		mov	es,VidMem
		mov	al,es:[di]	;; Get pixel from screen
		pop	es
		mov	es:[bx],al	;; Store pixel in buffer

		add	bx,1		;; Check for >64k access
		jnz	NIseg
		push	ax
		mov	ax,es
		add	ax,01000h
		mov	es,ax
		cmp	ax,09000h	;; Check for end of memory
		pop	ax
		ja	GetExit
NIseg:		inc	ah
		cmp	ah,4
		jnz	noGetBk
		inc	di
		xor	ah,ah
noGetBk:	loop	GetLoopX
		pop	di
		add	di,xbytes	;; Increment offset to next row
		pop	ax
		dec	si		;; Decrease y counter
		jns	GetLoopY
GetExit:	ret

;---------------------------------------------------------------------
;;BITBLT from buffer to screen
;; ES:BX=memory buffer with stored image
;;  ES:[BX+0]=(Width of rectangle - 1)
;;  ES:[BX+2]=(Height of rectangle - 1)
;; CX=Upper left X coordinate
;; DX=Upper left Y coordinate
;; AL=Logical restore operation
;;   0 - COPY_PUT		4 - NOT_PUT		8 - TRANS_COPY_PUT
;;   1 - XOR_PUT		5 - XNOR_PUT
;;   2 - OR_PUT			6 - NOR_PUT
;;   3 - AND_PUT		7 - NAND_PUT

restorebitmap:	ret

		mov	bltmode,al
		xor	ah,ah
		mov	si,ax
		mov	ah,Logical[si]
		push	dx		;; Set pixel update fn
		mov	dx,GC_INDEX
		mov	al,3
		out	dx,ax
		pop	dx
		mov	si,es:[bx]	;; Width of image-1
		inc	si
		mov	bar_xsiz,si

		mov	ax,dx		;; Calculate offset of first row
		mov	di,cx
		shr	di,1
		shr	di,1
		mul	xbytes
		add	di,ax
		add	di,PageOfs
		and	cl,3
		mov	ah,011h
		rol	ah,cl
		mov	si,es:[bx+2]	;; Height of image-1
		add	bx,4

		mov	dx,SC_INDEX
PutLoopY:	mov	cx,bar_xsiz
		push	ax
		push	di
PutLoopX:	mov	al,MAP_MASK
		out	dx,ax
		mov	al,es:[bx]	;; Get pixel out of buffer
		push	es
		mov	es,VidMem
		cmp	bltmode,8	;; TRANS_COPY_PIX
		jnz	notTCP
		test	al,al		;; If color 0, don't plot
		jnz	doPUT
		jmp	short noPUT
notTCP:		cmp	bltmode,4	;; Check for NOR, NXOR, etc..
		jl	doPUT
		not	al
doPUT:		xchg	es:[di],al	;; Store it!
noPUT:		pop	es
		add	bx,1		;; Check for >64k access
		jnz	NOseg
		push	ax
		mov	ax,es
		add	ax,01000h
		mov	es,ax
		cmp	ax,09000h	;; Check for end of memory
		pop	ax
		ja	PutExit
NOseg:		rol	ah,1
		jnc	noPutBk
		inc	di
noPutBk:	loop	PutLoopX
		pop	di
		add	di,xbytes
		pop	ax
		dec	si		;; Decrease y counter
		jns	PutLoopY
PutExit:	jmp	restregs

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
		xor	bx,bx
		mov	cx,1
		ret

;; Get offset of colour table
clrtable:	LoadDataSeg	es
		mov	bx,offset colourtable
		ret

;---------------------------------------------------------------------
; Now for the miscellaneous routines

;; BITS_PER_PIX - Returns the pixel colour depth
bits_per_pix	proc	far
		mov	ax,8
		ret
bits_per_pix	endp

;; SETWRITEMODE - Sets the line drawing mode
setwritemode	proc	far
		and	ax,1
		push	ds
		LoadDataSeg	ds
		mov	writemode,ax
		pop	ds
		ret
setwritemode	endp

pageadr		proc
		push	dx
		mov	bx,ax
		mov	dx,CRTC_INDEX

		mov	al,0dh
		out	dx,al
		inc	dx
		mov	al,bl
		out	dx,al
		dec	dx

		mov	al,0ch
		out	dx,al
		inc	dx
		mov	al,bh
		out	dx,al
		pop	dx
		ret
pageadr		endp

;; SETVISPAGE - Sets the visible video page
setvispage	proc	far
		push	cx
		push	ds
		LoadDataSeg	ds
		call	getdrawpage
		call	pageadr
		pop	ds
		pop	cx
		ret
setvispage	endp

getdrawpage	proc
		mov	bl,curr_mode
		xor	bh,bh
		xor	ah,ah
		shl	bx,1
		mov	cx,ax
		xor	ax,ax
		jcxz	spage_it
spage1:		add	ax,word ptr [bx+PageSize]
		loop	spage1
spage_it:	ret
getdrawpage	endp

;; SETDRAWPAGE - Sets the drawing video page
setdrawpage	proc	far
		push	cx
		push	ds
		LoadDataSeg	ds
		call	getdrawpage
		mov	word ptr [PageOfs],ax
		pop	ds
		pop	cx
		ret
setdrawpage	endp

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
		dw	NotImpNear	;[1C] Load the full palette
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

		dw	8 dup(NotImpNear)	;Reserved for future use.

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

;------- For generic VGA
Stat0 Status<,,319,319,319,319,,,14000,,,>		;;320x320x2
Mode0		db	25,"Tweaked Text 320x320 mono", 0

;; Table of structures
StatTable	dw	Stat0

;; Table of mode names
ModeNameTable	dw	Mode0

VidMem		dw	0B800h		;; Offset of video memory
FontMem		dw	0A000h

colourtable	db	0h		;; Zero-length colour table

cp_x		dw	?		;; Current drawing position
cp_y		dw	?

curr_mode	db	?		;; Current video mode
xsiz		dw	?		;; Current mode width in pixels
xbytes		dw	?
ysiz		dw	?		;; Current mode height in pixels

bar_xsiz	dw	?		;; Patterned bar & BITBLT variables
next_row	dw	?

fill_bits	db	?,?,?,?,?
writemode	dw	?
bltmode		db	?
Logical		db	00h,018h,010h,008h
		db	00h,018h,010h,008h,00h

textxsiz	dw	8		;; Text parameters
textysiz	dw	TEXTBYTES
textinc		dw	1
textdir		db	0
textseg		dw	?		;; Far pointer to character table
textofs		dw	?

clip_x1		dw	?		;; Clipping rectangle borders
clip_y1		dw	?
clip_x2		dw	?
clip_y2		dw	?

BrdrClr		db	?			;; Floodfill variables
Xvals		dw	MAXSTACK dup(0)
Yvals		dw	MAXSTACK dup(0)
StkPtr		dw	?
PrevXR		dw	?
CurrXR		dw	?
FillD		dw	?

deldx		dw	?			;; Line drawing variables
delsx		dw	?
deldy		dw	?
delsy		dw	?
delde		dw	?
delse		dw	?

linecolour	db	?			;; Line parameters
curr_linestyle	dw	0ffffh
linestyles	dw	0ffffh			;; Solid Line
		dw	0cccch			;; Dotted Line
		dw	0fc78h			;; Center Line
		dw	0f8f8h			;; Dashed Line

fillpatnum	db	?			;; Fill parameters
fillcolour	db	?

fill_lmask	db	?
fill_rmask	db	?
fill_bit	db	?

curr_fillpat	db 	?,?,?,?,?,?,?,?
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

PageSize	dw	04000h,0,0,0,0,0,05000h
PageOfs		dw	?

	IF	BGIVERSION GE 3
_DATA	ENDS
	ENDIF

end

