;; S3 86C911 16/256/32768 Colour BGI Driver Source
;;
;; Version:	$Revision:   1.16  $
;;
;; Copyright (c) 1992-1994, Jordan Hargrave <jordan_hargrave@hotmail.com>
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
;;  $Log:   C:/svga/rcs/svgas3.asv  $
;  
;     Rev 1.16   18 Aug 1994  1:19:00   JORDAN
;  Mods for outp/outpw
;  Changed save/restore bitmap to use insw/outsw
;  
;     Rev 1.15   09 Jun 1994 23:48:10   JORDAN
;  
;     Rev 1.14   14 May 1994 19:35:58   JORDAN
;;
.286

	IFNDEF	BGIVERSION
BGIVERSION	EQU	2		;; BGI revision version
					;; 2 for most BC/TC and BP/TP
					;; 3 for BP7.0 protected mode
	ENDIF
MaxMode		EQU	8		; Maximum mode number supported
BYTES_PER_PIX	EQU	1
;; Change here for font used:
;;    8 = 8x8 font
;;   14 = 8x14 font
;;   16 = 8x16 font
TEXTBYTES	EQU	8

cmode16         EQU     0
cmode256        EQU     1
cmode32k        EQU     2
cmode64k        EQU     3
cmodeTC         EQU     4

INCLUDE		common.inc		; Common defines
INCLUDE		s3code.inc

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

include MACROS.INC

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
notmodename:	mov	[curr_mode],cl
		push	es
		push	si
		call	whichvga	;; Detect which VGA is installed
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
		pop	si
		pop	es
		mov	bx,[StatTable+si]	;; Get address of DIT
		mov	ax,[bx+yefres]
		mov	[ysiz],ax
		mov	ax,[bx+xefres]
		mov	[xsiz],ax

        ;; Get color mode type for this mode
                shr     si, 1
                mov     al, ColorModeTable[si]
                mov     color_mode, al

		push	es
		push	bx
		call	GetInitMode		;; Test if mode supported
		pop	bx
		pop	es
		jnc	InstallOk
		mov	byte ptr [bx],-10	;; Invalid Mode
InstallOk:	ret

;---------------------------------------------------------------------
GetInitMode:	mov	cl,[curr_mode]
		xor	ch,ch
		mov	si,cx
		shl	si,2
		add	si,CurrVidModes
		mov	ax,[si]			;; Retrieve graphics mode
		mov	bx,[si+02]		;; number from table
		or	ax,bx
		jz	ModeNotOk
ModeOk:		clc
		ret

ModeNotOk:	call	post
		stc
		ret

;---------------------------------------------------------------------
;;INIT - Changes into graphics mode
;; ES:BX=Device Information Table

init:		call	GetInitMode
		jc	InitXit
		int	010h
		mov	xbytes,1024
		LoadDataSeg	es

	;; Setup default palette
		mov	cx,768
		lea	si,vgadac
		mov	dx,03c8h
		repz	outsb
InitXit:	ret

;---------------------------------------------------------------------
;;POST - Exit from graphics mode

post:		ret

;---------------------------------------------------------------------
;;CLEAR - Clears the screen

clear:		push	word ptr fillpatnum	;; Save old fillpattern
		mov	fillpatnum,0		;; Empty fill pattern
		xor	ax,ax			;; 0,0
		xor	bx,bx
		mov	cx,[xsiz]			;; Maxx, Maxy
		mov	dx,[ysiz]
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
;; Fallthrough

;---------------------------------------------------------------------
;;VECT - Draws line from X1,Y1 to X2,Y2
;; AX=Start X coordinate
;; BX=Start Y coordinate
;; CX=End X coordinate
;; DX=End Y coordinate
;;
;;  Bresenhams line drawing algorithm from Bluebook of Assembly Routines for 
;;  the IBM PC & XT, with minor modifications :jph

vect:		cmp	ax,cx
		jle	Xpos
		xchg	ax,cx
		xchg	bx,dx
Xpos:		sub	cx,ax			;; abs(x2-x1)

	;; Set X & Y positive, X major axis
		mov	si,Xpositive+YPositive+XMajor
		sub	dx,bx		        ;; abs(y2-y1)
		jge	story
		neg	dx		        ;; negate y-increment
		and	si,not Ypositive	;; Y negative

story:		cmp     cx,dx
		jge     stordelsxy
		xchg	cx,dx
	;; Y axis is major axis
		and	si,NOT XMajor
		or	si,YMajor

;; CX = MAX(abs(x2-x1),abs(y2-y1))
;; DX = MIN(abs(x2-x1),abs(y2-y1))

stordelsxy:	shl	dx,1
		mov	delse,dx	;; 2*MIN desty_axstp

		sub	dx,cx
		mov	di,dx		;; 2*MIN-MAX err_term
		sub	dx,cx
		mov	delde,dx	;; 2*(MIN-MAX) destx_diastp

	;; Save start X & Y coordinate
		add	ax, [PageOfs]
		mov	[lin_x],ax
		mov	[lin_y],bx

		Wait_Till_Fifo	SixEmpty
		outpw	MULTIFUNC_CNTL, Pel_Cntl+DE_CPU

	;; Set background mix
		outpw	BKGD_MIX, 03

	;; Set foreground mix
		mov	dx,FRGD_MIX		;; Foreground mix
		push	si
		mov	si,writemode
		mov	al,Logical[si]
		pop	si
		xor	ah,ah
		out	dx,ax

	;; Output major axis
		outpw	MAJ_AXIS_PCNT, cx

	;; Output diagonal errorterm increment
		outpw	DESTX_DIASTP, [delde]

	;; Output straight errorterm increment
		outpw	DESTY_AXSTP, [delse]

vectn16:	push	cx
		mov	bx,linecolour
		call	vectput
		pop	cx

        ;; Do 32k mode
                cmp     [color_mode], cmode32k
		jnz	vectxit
		add	[lin_x],1024
		mov	bx,linecolour
		xchg	bh,bl

vectput:	Wait_Till_Fifo	FourEmpty

	;; Set foreground color
		outpw	FRGD_COLOR, bx

	;; Set current X
		outpw	CUR_X, [lin_x]

	;; Set current Y
		outpw	CUR_Y, [lin_y]

	;; Set errorterm
		outpw	ERR_TERM, di

	;; Do command
		or	si,CmdLine+DrawTo+WriteOp+MultiPel+BusSize+WaitCpu
		outpw	CMD, si
		xor	ax,ax

	;; line_length = (line_length+16) >> 3;
		add	cx,16
		shr	cx,3

		mov	dx, PIX_TRANS
		mov	ax, [curr_linestyle]
	;; Line loop - output current linestyle
dlin3:		outpw	dx, ax
		loop	dlin3
vectxit:	ret

;---------------------------------------------------------------------
;;PATBAR - Draws patterned bar from (X1,Y1)-(X2,Y2)
;; AX=Upper left X coordinate
;; BX=Upper left Y coordinate
;; CX=Lower right X coordinate
;; DX=Lower right Y coordinate

patbar:		cmp	ax,cx			;; Check if X2<X1
		jl	Xok
		xchg	ax,cx			;; Swap X1 & X2

Xok:		cmp	bx,dx			;; Check if Y2<Y1
		jl	Yok
		xchg	dx,bx			;; Swap Y1 & Y2

Yok:		sub	dx,bx			;; Calculate bar height
		sub	cx,ax			;; Calculate bar width

		mov	bar_width,cx
		mov	bar_height,dx

		add	ax, [PageOfs]
		mov	[lin_x],ax
		mov	[lin_y],bx
		mov	cx,ax
		and	cx,7
		mov	fill_bit,cl

		mov	ax,[fillcolour]
pbn16:		mov	[fcolour],ax
		cmp	fillpatnum,0		;; Empty fill
		jnz	NotEmpty
		mov	[fcolour],0
		jmp	SolidFill
NotEmpty:	cmp	fillpatnum,1		;; Solid fill
		jnz	PatFill
		jmp	SolidFill

;; Patterned fill
PatFill:	Wait_Till_Fifo	SixEmpty

		outpw	MULTIFUNC_CNTL, Pel_Cntl+DE_CPU

	;; Set bar height
		xor	ax, ax
		outpw	dx, ax

	;; Set bar width
		outpw	CURWIDTH, [bar_width]

	;; Set foreground mix
		outpw	FRGD_MIX, 027h

	;; Set background mix
		outpw	BKGD_MIX, 07h

	;; Set background color
		xor	ax, ax
		outpw	BKGD_COLOR, ax

		mov	bx,[lin_y]
		mov	si,[bar_height]

patloop0:	Wait_Till_Fifo	FiveEmpty

	;; Set foreground color
		outpw	FRGD_COLOR, [fcolour]

	;; Set current X
		outpw	CUR_X, [lin_x]

	;; Set current Y
		outpw	CUR_Y, bx

	;; Do command
		OutCMD	CmdRect+ByteSwap+BusSize+WaitCpu+DrawTo+Xpositive+Ypositive+XMajor+WriteOp+MultiPel

		push	bx
		and	bx,7
		mov	al,byte ptr curr_fillpat[bx]
		rol	al,cl
		mov	ch,al
		mov	ah,al
		outpw	COLOR_CMP, ax
		pop	bx

		cmp	[color_mode], cmode32k
                jnz     patfn16
		Wait_Till_Fifo	SixEmpty

	;; Set second color
		mov	ax, [fcolour]
		xchg	ah,al
		outpw	FRGD_COLOR, ax

	;; Set current X
		mov	ax,[lin_x]
		add	ax,1024
		outpw	CUR_X, ax

	;; Set current Y
		outpw	CUR_Y, bx
		mov	dx,CUR_Y

	;; Do command
		OutCMD	CmdRect+ByteSwap+BusSize+WaitCpu+DrawTo+Xpositive+Ypositive+XMajor+WriteOp+MultiPel

		mov	al,ch
		mov	ah,al
		outpw	COLOR_CMP, ax

patfn16:	inc	bx
		dec	si
		jns	patloop0
patbar0:	ret

;; Optimized solid fill
SolidFill:	Wait_Till_Fifo FiveEmpty 

	;; Set foreground mix
		outpw	FRGD_MIX, 027h

		outpw	MULTIFUNC_CNTL, Pel_Cntl+DE_Ones

	;; Set bar height
		outpw	dx, [bar_height]

        ;; Set bar width
		outpw	CURWIDTH, [bar_width]

		mov	di,[lin_x]
		mov	cx,[fcolour]
		call	sldfill
    
        ;; Do 32k mode
		cmp	[color_mode], cmode32k
		jnz     sldfxit
		add	di,1024		;; for 16-bit-per pixel mode
		xchg	ch,cl

sldfill:	Wait_Till_Fifo	FourEmpty
	;; Set foreground color
		outpw	FRGD_COLOR, cx

	;; Set current X
		outpw	CUR_X, di

	;; Set current Y
		outpw	CUR_Y, [lin_y]

	;; Do command
		OutCMD	CmdRect+YPositive+XPositive+DrawTo+MultiPel+WriteOp
sldfxit:	ret

;---------------------------------------------------------------------
;;PALETTE - Palette manipulation
;; Upper two bits of AX:
;;  00b - BX contains colour, AX is index		[Not Imp]
;;  01b - Not used
;;  10b - BX=Red, CX=Green, DX=Blue, AX is index
;;  11b - BX=background colour				[Not Imp]

palette:	mov	di,ax
		and	di,03fffh
		shl	ah,1			;; Test first bit
		jc	p_up
		ret
p_up:		shl	ah,1			;; Test second bit
		jnc	p_rgb
		ret

;; Set DAC RGB palette entry
p_rgb:		xor	ah,ah
		cmp	[color_mode], cmode32k
                jnz     spal
		mov	al,dl
		and	al,01fh
		shl	cx,5
		or	ax,cx
		shl	bx,2
		or	ah,bl
		cmp	di,1024
		jnz	setfillRGB
		mov	linecolour,ax
		ret

setfillRGB:	cmp	di,1025
		jnz	setbrdrRGB
		mov	fillcolour,ax
		ret

setbrdrRGB:	mov	rcurrcolour,ax
		ret

spal:		mov	ah,dl		;; AX = BBBBBBBBIIIIIIII
					;; CX = 00000000GGGGGGGG
					;; BX = 00000000RRRRRRRR
		mov	dx,03c8h	;; VGA DAC port
		out	dx,al
		inc	dx
		outp	dx, bl		;; Out Red
		outp	dx, cl		;; Out Green
		outp	dx, ah		;; Out Blue
		WaitForRetrace
		ret

;---------------------------------------------------------------------
;;COLOUR - Set draw and fill colours
;; AL=new draw colour
;; AH=new fill colour

colour:		cmp	[color_mode], cmode32k
		jz	clrt
		mov	byte ptr linecolour,al
		mov	byte ptr fillcolour,ah
clrt:		ret

;---------------------------------------------------------------------
;;FILLSTYLE - Set the fill pattern
;; AL=fill pattern number
;; ES:BX=user-defined fill pattern (if AL = 0xFF)

fillstyle:	xor	ah,ah
		mov	fillpatnum,ax
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

movepattern:	lea	di, curr_fillpat
movepat:	LoadDataSeg	es
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
		push	word ptr fillcolour
		mov	fillpatnum,1		;; Set fillpattern to SOLID
		mov	ax,linecolour		;; Set fillcolour to linecolour
		mov	fillcolour,ax
txtn16:		mov	si,bx
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
		pop	word ptr fillcolour
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
		cmp	dx,rcurrcolour
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
		cmp	dx,rcurrcolour
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
		cmp	dx,rcurrcolour
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
		cmp	dx,rcurrcolour
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
		cmp	[color_mode], cmode32k
		jz	filln16
		xor	ch,ch
		mov	[rcurrcolour], cx
filln16:	mov	si,ax			;; SeedX
		mov	di,bx			;; SeedY
		call	getpixel		;; TstPix
		cmp	dx,[rcurrcolour]
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

getpixel:	add     ax, [PageOfs]
                mov	[lin_x],ax

		Wait_Till_Fifo	SixEmpty

		outpw	MULTIFUNC_CNTL, Pel_Cntl+DE_Ones

	;; Set bar height = 1
		xor	ax, ax
		outpw	dx, ax

	;; Set bar width = 1
		outpw	CURWIDTH, ax

	;; Set current X
		outpw	CUR_X, [lin_x]

	;; Set current Y
		outpw	CUR_Y, bx

	;; Do command
		OutCMD	CmdRect+DrawTo+Xpositive+Ypositive+XMajor+ReadOp+BusSize+ByteSwap+WaitCpu

		Wait_For_Data
		mov	dx,PIX_TRANS
		in	ax,dx

		and	ax,0ffh

        ;; Do 32k mode
		cmp     [color_mode], cmode32k
		jnz	gpno16
		push	ax
		Wait_Till_Fifo	ThreeEmpty

	;; Set current X
		mov	ax,[lin_x]
		add	ax,1024
		outpw	CUR_X, ax

	;; Set current Y
		outpw	CUR_Y, bx

	;; Do command
		OutCMD	CmdRect+DrawTo+Xpositive+Ypositive+Xmajor+ReadOp+WaitCpu+BusSize+ByteSwap

		Wait_For_Data
		mov	dx,PIX_TRANS
		in	ax,dx
		mov	bh,al
		pop	ax
		mov	ah,bh

gpno16:		cmp     [color_mode], cmode16
                jnz     prc
	;; Shift pixel for 16-color modes
		shr	ax,4
prc:		mov	dx,ax
		ret	
		
;---------------------------------------------------------------------
;;PUTPIXEL - Writes a pixel to the screen
;; AX=X coordinate of the seed point
;; BX=Y coordinate of the seed point
;; DL=colour of the seed point
;;
;; Code from John Bridges' VGAKIT

putpixel:	xor	dh,dh
		cmp	[color_mode], cmode32k
		jnz	pp16m
		mov	dx,[rcurrcolour]
pp16m:		mov	[fcolour],dx

		add	ax, [PageOfs]
		mov	[lin_x],ax		;; X coord

		Wait_Till_Fifo	EightEmpty

	;; Set foreground mix
		outpw	FRGD_MIX, 027h

		outpw	MULTIFUNC_CNTL, Pel_Cntl+DE_Ones

	;; Set bar height = 1
		xor	ax,ax
		outpw	dx, ax

	;; Set bar width = 1
		outpw	CURWIDTH, ax

		mov	cx,[fcolour]
		call	pput

        ;; Do 32k mode
		cmp	[color_mode], cmode32k
                jnz     ppxit
		add	[lin_x],1024
		xchg	ch,cl
pput:
	;; Set foreground color
		outpw	FRGD_COLOR, cx

	;; Set current X
		outpw	CUR_X, [lin_x]

	;; Set current Y
		outpw	CUR_Y, bx

	;; Do command
		OutCMD	CmdRect+DrawTo+Xpositive+Ypositive+XMajor+WriteOp
ppxit:		ret

;---------------------------------------------------------------------
;;BITMAPUTIL - Returns pointer to bitmap routines
bitmaputil:	LoadDataSeg	es
		lea		bx, BitmapTable
		ret

;---------------------------------------------------------------------
;;BITBLT from screen to buffer
;; ES:BX=memory buffer to store image in
;;   ES:[BX+0]=(Width of rectangle - 1)
;;   ES:[BX+2]=(Height of rectangle - 1)
;; CX=Upper left X coordinate
;; DX=Upper left Y coordinate

savebitmap:	add	cx,[PageOfs]
		mov	[lin_x],cx
		mov	[lin_y],dx

		Wait_Till_Fifo	SevenEmpty

		outpw	MULTIFUNC_CNTL, Pel_Cntl+DE_Ones

	;; Set bar height
		mov	cx, es:[bx+2]
		outpw	dx, cx

	;; Set bar width
		outpw	CURWIDTH, es:[bx]

		inc	cx
                cmp     [color_mode], cmode16
                jnz     GetImg00

	;; size = (width+4)*(height+1) >> 2;
		add	ax,4
		mul	cx
		shr	ax,2
		jmp	short imr0
	;; size = ((width+2)>>1)*(height+1)
GetImg00:	add	ax,2
		shr	ax,1
		mul	cx
imr0:		mov	cx,ax

		cmp	[color_mode], cmode32k
		jnz	notp16pl2

		push	ax
		mov	si,[lin_x]
		mov	di,bx
		add	di,4
		call	GetImg16
		pop	cx
		mov	si,[lin_x]
		add	si,1024
		mov	di,bx
		add	di,5
		call	GetImg16
		jmp	notp16pl1

GetImg16:	Wait_Till_Fifo	ThreeEmpty

	;; Set current X
		outpw	CUR_X, si

	;; Set current Y
		outpw	CUR_Y, [lin_y]

	;; Do command
		OutCMD	CmdRect+DrawTo+Xpositive+YPositive+XMajor+ReadOp+BusSize+ByteSwap+WaitCpu

		Wait_For_Data
		mov	dx,PIX_TRANS
	;; Read pixel
bp16ilp1:	in	ax,dx
		mov	es:[di],al
		mov	es:[di+2],ah
		add	di,4
		loop	bp16ilp1
		ret

notp16pl2:	Wait_Till_Fifo	ThreeEmpty
	;; Set current X
		outpw	CUR_X, [lin_x]

	;; Set current Y
		outpw	CUR_Y, [lin_y]

	;; Do command
		OutCMD	CmdRect+DrawTo+Xpositive+YPositive+XMajor+ReadOp+BusSize+ByteSwap+WaitCpu

	;; Wait until data is ready
		Wait_For_Data

	;; Read pixels
		mov	di, bx
		add	di, 4
		mov	dx,PIX_TRANS
		repz	insw
notp16pl1:	ret

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

restorebitmap:	add	cx, [PageOfs]
		mov	[lin_x],cx
		mov	[lin_y],dx
		xor	si,si
		test	al,al
		jz	@copyPut
		cmp	al,1
		jz	@xorPut
		cmp	al,2
		jz	@orPut
		cmp	al,3
		jz	@andPut
		cmp	al,4
		jz	@notPut
		cmp	al,5
		jz	@xnorPut
		cmp	al,6
		jz	@norPut
		cmp	al,7
		jz	@nandPut
	;; Fallthrough
@copyPut:	mov	si,3
@notPut:	add	si,44h
		jmp	short @endPutType
@xnorPut:	mov	si,1
@xorPut:	add	si,45h
		jmp	short @endPutType
@orPut:		mov	si,2
@norPut:	add	si,49h
		jmp	short @endPutType
@nandPut:	mov	si,2
@andPut:	add	si,4Ch
	;; Fallthrough

@endPutType:	Wait_Till_Fifo	FiveEmpty

		outpw	MULTIFUNC_CNTL, Pel_Cntl+DE_Ones

	;; Set bar height
		mov	cx, es:[bx+2]
		outpw	dx, cx

	;; Set bar width
		outpw	CURWIDTH, es:[bx]

	;; Set foreground mix
		outpw	FRGD_MIX, si

		inc	cx
		inc	ax
                cmp     [color_mode], cmode16
                jnz     PutImg00
	;; count = ((width+3)/4*height)
		add	ax,4
		shr	ax,2
		mul	cx
		jmp	short imwa0

	;; count = ((width+1)/2*height)
PutImg00:	add	ax,2
		shr	ax,1
		mul	cx
imwa0:		mov	cx,ax
		cmp	[color_mode], cmode32k
		jnz	PutImg02

		push	ax
		mov	di,[lin_x]
		mov	si,bx
		add	si,4
		call	PutImg16
		pop	cx

		mov	di,[lin_x]
		add	di,1024
		mov	si,bx
		add	si,5

;; Putimage for 32k mode
PutImg16:
	;; Set current X
		outpw	CUR_X, di

	;; Set current Y
		outpw	CUR_Y, [lin_y]

	;; Do command
		OutCMD	CmdRect+DrawTo+WriteOp+XPositive+YPositive+XMajor+BusSize+ByteSwap+WaitCpu
		mov	dx,PIX_TRANS
	;; Store pixel
PutLp0:		mov	al,es:[si]
		mov	ah,es:[si+2]
		add	si,4
		out	dx,ax
		loop	PutLp0
		ret

;; PutImage for 16/256 mode
PutImg02:	mov	si,bx
		add	si,4

	;; Set current X
		outpw	CUR_X, [lin_x]

	;; Set current Y
		outpw	CUR_Y, [lin_y]

	;; Do command
		OutCMD	CmdRect+DrawTo+XPositive+YPositive+XMajor+WriteOp+BusSize+ByteSwap+WaitCpu
		mov	dx,PIX_TRANS

	;; Output pixel data
		push	ds
		mov	ax, es
		mov	ds, ax
		repz	outsw
		pop	ds
		ret

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
		cmp	[color_mode], cmode32k
                jnz	cq16
		mov	cx,32767 ;; is a 32768-color mode
		ret
cq16:		cmp     [color_mode], cmode16
		jnz	cq256
		mov	cx,15	;; is a 16-color mode
		ret
cq256:		mov	cx,255	;; is a 256-color mode
		ret

;; Get offset of colour table
clrtable:	LoadDataSeg	es
		lea		bx, colourtable
		ret

;---------------------------------------------------------------------
; Now for the miscellaneous routines

;; SETPIXCOL - Sets pixel color for ellipse drawing
setpixcol	proc	far
		push	ds
		LoadDataSeg	ds
		cmp	[color_mode], cmode32k
		jnz	spcxit
		mov	ax,[linecolour]
		mov	[rcurrcolour],ax
spcxit:		pop	ds
		ret
setpixcol	endp

;; BITS_PER_PIX - Returns the pixel colour depth
bits_per_pix	proc	far
		push	ds
		LoadDataSeg	ds
		xor	ax,ax
                cmp     [color_mode], cmode256
                jz      bpp8
                cmp     [color_mode], cmode16
                jz      bpp4
		mov	ax,7		;; 15 bpp
bpp8:		add	ax,4		;; 8 bpp
bpp4:		add	ax,4		;; 4 bpp
		pop	ds
		ret
bits_per_pix	endp

;; SETVISPAGE - Sets the visible video page
setvispage	proc	far
		push	cx
		push	ds
		LoadDataSeg	ds

		xor	cx,cx
                xor     bx, bx
		mov	bl, [curr_mode]

        ;; Page 0
		test	al,al
		jz	page_it
		shl	bx,1
		mov	cx,word ptr [PageSize+bx]

page_it:	;; CX - lower 16 bits
		wrinx	CRTC_INDEX, 0ch, ch
		wrinx	CRTC_INDEX, 0dh, cl
		pop	ds
		pop	cx
		ret
setvispage	endp

;; SETDRAWPAGE - Sets the drawing video page
setdrawpage	proc	far
		push	ds
		LoadDataSeg	ds
		xor	cx,cx

        ;; Page 0
		test	al,al
		jz	spage_it

        ;; Can't page 1280xXXX modes
                cmp     xsiz, 1023
                jge     spage_it
		mov	cx,1024

spage_it:	mov	[PageOfs],cx
		pop	ds
		ret
setdrawpage	endp

;; SETWRITEMODE - Sets the line drawing mode
setwritemode	proc	far
		push	ds
		LoadDataSeg	ds
		and	ax,7
		mov	[writemode], ax
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

;; WHICHVGA - SuperVGA detection routine
;;  Detects type of SVGA card installed and sets up the appropriate 
;;  bank switching routine and mode numbers.

whichvga proc	near
	;; Disable extensions
		wrinx		CRTC_INDEX, 038h, 0
		testinx2	CRTC_INDEX, 035h, 0Fh
		jz		@notS3

	;; Enable extensions
		wrinx		CRTC_INDEX, 038h, 048h
		testinx2	CRTC_INDEX, 035h, 0Fh
		jnz		@notS3

	;; Found a S3 card
		mov	CurrVidModes,offset S3modes

        ;; Detect if 1280x960 mode is supported
                rdinx   CRTC_INDEX, 030h
                cmp     al, 081h
                jz      @notS3
        ;; Newer S3 cards don't support this mode(?)
                ClearMode   0, S3Modes, 5
@notS3:		ret
whichvga 	endp

;; DX = Port
;; BH = Index
;; BL = Mask
TestIndex2	proc	near
		push	cx
	;; old = Rdinx(port, index);
		_rdinx
		mov	cl,al

	;; Wrinx(port, index, old & ~mask);
		mov	ch,bl
		not	ch
		and	ch,al		;; old & ~mask
		_wrinx	ch

	;; new1 = rdinx(port, reg) and mask
		_rdinx
		and	al,bl
	;; if (new1 != 0) return false;
		jnz	@@noIndex

	;; Wrinx(port,reg, old | mask);
		mov	ch,cl
		or	ch,bl
		_wrinx	ch

	;; new2 = rdinx(port, reg) and mask
		_rdinx
		and	al,bl

		cmp	al,bl
@@noIndex:	pushf
		_wrinx  cl
		popf
		pop	cx
		ret
TestIndex2	endp

	IF	BGIVERSION GE 3
_TEXT	ENDS

_DATA	SEGMENT	PARA	PUBLIC	'DATA'

	assume ds:_DATA, cs:Nothing

InitTable	EQU	$
NRealSegs       db      1
RealSegOfs      dw      SegTable
NIntVects       db      0
IntVecOfs       dw      0
NRealBlocks     db      0
RealBlockOfs    dw      0
DSinRealMem     db      1
RealModeDS      dw      0
CurOpMode       db      0

SegTable	EQU	$
SEGC000		dw	0C000h

	ENDIF

INCLUDE		vgadac.inc

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
BitmapTable	dw	setpixcol	;GotoGraphic
		dw	NotImpFar	;ExitGraphic
		dw	putpixel	;PutPixel
		dw	getpixel	;Getpixel
		dw	bits_per_pix	;Getpixbyte
		dw	setdrawpage	;Set_draw_page
		dw	setvispage	;Set_visual_page
		dw	setwritemode	;Set_write_mode

Stat1 Status<,,639,479,639,479,,,10000,,,,>		;;640x480x256
Mode1		db	14,"S3 640x480x256",0
Stat2 Status<,,799,599,799,599,,,10000,,,,>		;;800x600x256
Mode2		db	14,"S3 800x600x256",0
Stat3 Status<,,1023,767,1023,767,,,10000,,,,>		;;1024x768x256
Mode3		db	15,"S3 1024x768x256",0
Stat4 Status<,,799,599,799,599,,,10000,,,,>		;;800x600x16
Mode4		db	13,"S3 800x600x16",0
Stat5 Status<,,1023,767,1023,767,,,10000,,,,>		;;1024x768x16
Mode5		db	14,"S3 1024x768x16",0
Stat6 Status<,,1279,959,1279,959,,,10000,,,,>		;;1280x960x16
Mode6		db	14,"S3 1280x960x16",0
Stat7 Status<,,1279,1023,1279,1023,,,10666,,,,>		;;1280x1024x16
Mode7		db	15,"S3 1280x1024x16",0
Stat8 Status<,,639,479,639,479,,,10000,,,,>		;;640x480x32k
Mode8		db	16,"S3 640x480x32768",0

;; Table of structures
StatTable	dw	Stat1, Stat2, Stat3, Stat4, Stat5, Stat6, Stat7, Stat8

;; Table of mode names
ModeNameTable	dw	Mode1, Mode2, Mode3, Mode4, Mode5, Mode6, Mode7, Stat8

;; Colour table - contains default colors
colourtable	db	0h

cp_x		dw	?		;; Current drawing position
cp_y		dw	?

color_mode      db      ?
curr_mode	db	?		;; Current video mode
xbytes		dw	?
xsiz		dw	?		;; Current mode width in pixels
ysiz		dw	?		;; Current mode height in pixels

bar_width	dw	?		;; Patterned bar & BITBLT variables
next_row	dw	?
bar_height	dw	?
lin_x		dw	?
lin_y		dw	?

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

deldxy		dw	?			;; Line drawing variables
delsxy		dw	?
delde		dw	?
delse		dw	?

rcurrcolour	dw	?

linecolour	dw	?			;; Line parameters
curr_linestyle	dw	0ffffh
linestyles	dw	0ffffh			;; Solid Line
		dw	0cccch			;; Dotted Line
		dw	0fc78h			;; Center Line
		dw	0f8f8h			;; Dashed Line

fillpatnum	dw	?			;; Fill parameters
fillcolour	dw	?
fcolour		dw	?
fill_bit	db	?
writemode	dw	?		;; Write mode for line drawing
bltmode		db	?		;; Write mode for bitblt operations
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

curbk		db	?		;; Current bank number

Logical		db	027h,025h,02Bh,02ch
		db	024h,026h,029h,02eh,027h

;; color mode info per mode
ColorModeTable  db      cmode256, cmode256, cmode256
                db      cmode16, cmode16, cmode16, cmode16
                db      cmode32k

;; Paging information
PageSize	dw	1024, 1024, 1024		;; 256 color
		dw	1024 SHR 1, 1024 SHR 1, 0, 0	;; 16 color
		dw	1024 SHL 1			;; 32k color
PageOfs		dw	0

CurrVidModes	dw	DefaultModes		;; Pointer to video mode table

DefaultModes	dw	0,0			;; Default - Non SuperVga modes
		dw	0,0
		dw	0,0
		dw	0,0
		dw	0,0
		dw	0,0
		dw	0,0
		dw	0,0
S3modes		dw	04f02h,0201h			;; S3 modes
		dw	04f02h,0203h
		dw	04f02h,0205h
		dw	04f02h,0202h
		dw	04f02h,0204h
		dw	04f02h,0206h
		dw	04f02h,0208h
		dw	04f02h,0301h

	IF	BGIVERSION GE 3
_DATA	ENDS
	ENDIF

end

