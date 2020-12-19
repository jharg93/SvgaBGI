;; SuperVGA True Color Colour BGI Driver Source
;;
;; Version:	$Revision:   2.15  $
;;
;; Copyright 1993-1994, Jordan Hargrave <jordan_hargrave@hotmail.com>
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
;;  $Log:   C:/svga/rcs/svgatc.asv  $
;  
;     Rev 2.15   30 Aug 1994  3:21:40   JORDAN
;  
;     Rev 2.11   23 Aug 1994  0:05:38   JORDAN
;  
;     Rev 2.10   20 Jul 1994 22:09:06   JORDAN
;  Added support for HGXMOUSE driver.
;  Started fixing bugs for protected mode
;  
;     Rev 2.9   09 Jun 1994 23:46:22   JORDAN
;  First release stage.
;  Added TestXBank to test for bank crossing in a single pel.
;  
;     Rev 2.7   14 May 1994 19:36:02   JORDAN
;;
.386					;; Need a 386 for this driver

	IFNDEF	BGIVERSION
BGIVERSION	EQU	2		;; BGI revision version
					;; 2 for most BC/TC and BP/TP
					;; 3 for BP7.0 protected mode
	ENDIF
COLORMODE	EQU	16777		;;216
USEVESA		EQU	0		;; Use VESA if it's detected
MOUSE_SOURCE	EQU	0		; 0 = regular driver
					; 1 = driver with mouse handler
MaxMode		EQU	7		; Maximum mode number supported
BYTES_PER_PIX	EQU	3
;; Change here for font used:
;;    8 = 8x8 font
;;   14 = 8x14 font
;;   16 = 8x16 font
TEXTBYTES	EQU	8
MULTITEXT	EQU	0

INCLUDE		common.inc		; Common defines

	IF BGIVERSION LT 3

_TEXT	SEGMENT	PARA	PUBLIC	USE16	'CODE'

	assume	cs:_TEXT,ds:_TEXT,ss:_TEXT

;;This is the standard BGI header info

;; BGI v2.0 entry code
	BGI20Entry

	ELSE

_TEXT	SEGMENT	PARA	PUBLIC	USE16	'CODE'

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
;;INSTALL - Installs the driver

install:	cmp	al,1
		jnz	notmodequery
		mov	cx,MaxMode		;; Return # of modes
		ret
notmodequery:	cmp	cl,MaxMode-1
		jle	TopMode
		mov	cl,MaxMode-1
TopMode:	LoadDataSeg	es		;; Macro
		movzx	si, cl
		shl	si,1
		test	al,al
		jz	notmodename

	;; Load mode text name
		LoadModeName
		ret
notmodename:	mov	curr_mode,cl
		push	es
		push	si
		call	whichvga	;; Detect which VGA is installed
		mov	ax,CurrVidModes
		mov	OrigVidModes,ax
		LoadVesaModeTable
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
	IF	BGIVERSION GE 3
		mov	es,SEGC000		;; Evil hack... Couldn't get DPMI
						;; to make the actual segment readable
	ENDIF
@textDone:	mov	textofs,bp
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
		movzx	si, al
		shl	si,1
		mov	ax,BytesPerLine[si]
		mov	xbytes,ax

		push	es
		push	bx
		call	GetInitMode		;; Test if mode supported
		pop	bx
		pop	es
		jnc	InstallOk
		mov	byte ptr [bx],-10	;; Invalid Mode
InstallOk:	ret

;---------------------------------------------------------------------
GetInitMode:	mov	cl,curr_mode
		movzx	si, cl
		shl	si,2
		add	si,CurrVidModes
		mov	ax,[si]			;; Retrieve graphics mode
		mov	bx,[si+02]		;; number from table
		or	ax,bx
		jz	ModeNotOk
ModeOk:		cmp	CurrVidModes,offset VesaModes
		jz	initvesa
		clc
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

;---------------------------------------------------------------------
;;INIT - Changes into graphics mode
;; ES:BX=Device Information Table

init:		call	GetInitMode
		jc	InitXit

	;; Test for nonstandard init
		cmp	ax, 0C0DEh
		jnz	@normalInit
	;; Call init routine
		call	bx
		jmp	short @didInit

	;; Do standard int 010h call
@normalInit:	int	010h
@didInit:	mov	byte ptr curbk,-1
		Enable_Mouse	MODE_P24, 3
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

post:		Disable_Mouse
		ret

;---------------------------------------------------------------------
;;CLEAR - Clears the screen

clear:		push	word ptr fillpatnum	;; Save old fillpattern
		xor	ax,ax			;; 0,0
		xor	bx,bx
		mov	fillpatnum,al		;; Empty fill pattern
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

vect:		push	gs
		mov	gs,VidMem

		sub	cx,ax		;; Check if X2<X1
		mov	si,3		;; X increment
		jge	storx
		neg	si		;; If so, take absolute value and
		neg	cx		;; negate x-increment

storx:		mov	deldxy,si
		sub	dx,bx		;; Check if Y2<Y1
		mov	di,xbytes	;; Y increment
		jge	story
		neg	di		;; If so, take absolute value and
		neg	dx		;; negate y-increment

story:		add	deldxy,di
		cmp     cx,dx
		jge     stordelsxy
		mov	si,di
		xchg	cx,dx

stordelsxy:	shl	dx,1
		mov	delsxy,si
		mov	delse,dx

	;; Calculate errorterm
		sub	dx,cx
		movzx	eax, ax			;; EAX = x coord
		mov	di, dx
		lea	eax, [eax+eax*2]	;; EAX = EAX*3
		sub	dx,cx
		xchg	ax, bx			;; Swap y coord & (x*3)
		inc	cx
		mov	delde,dx

	;; Calculate offset of first pixel in line
	;; Offset = (y*xbytes) + (x*3);
		mul	xbytes
		add	bx, ax
		adc	dl,0

		add	bx,word ptr [PageOfs]		;; For active page
		adc	dx,word ptr [PageOfs+2]

		xchg	bx, di
		mov	PrevFunc,offset NoLinChg
		mov	si,[curr_linestyle]	;; Current line bitpattern
linloop:	ror	si,1			;; Rotate Line bitpattern
		jnc	NoPlot
		cmp	dl,curbk
		jnz	LinChg

	;; EAX = 00000000RRRRRRRRGGGGGGGGBBBBBBBB
NoLinChg:	mov	eax, dword ptr [drawcolour]
                call    word ptr [WriteModeFunc]
NoPlot:		mov	bp,bx			;; Use straight or diagonal increment based on sign of errorterm
		rol	bp,2
		and	bp,2
		add	bx,ds:[bp+delde]
		mov	ax,ds:[bp+deldxy]
		mov	bp,dx
		cwd
		add	di,ax
		adc	dx,bp
                loop    linloop
		pop	gs
		ret

LinChg:		call	newbank
		jmp	word ptr [PrevFunc]

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
		sub	cx,ax			;; Calculate bar width

		mov	si,bx			;; Calculate pattern row
		inc	cx
		mov	bp,dx			;; Calculate initial offset
		mov	bar_xsiz,cx

	;; Calculate offset of next row
		movzx	ecx, cx
		movzx	edi, ax
		lea	ecx, [ecx+ecx*2]
		neg	cx
		add	cx, [xbytes]
		mov	[next_row], cx

		lea	edi, [edi+edi*2]	;; edi  = x*3;
		mov	cx,ax
		mov	ax, bx			;;  ax  = y
		and	cx,7
		mov	fill_bit,cl

	;; Offset = (x*3)+(y*bytesperline)
		mul	xbytes			;;  ax *= bytesperline
		add	di,ax			;;  di += ax;
		adc	dl,0

		add	bx,word ptr [PageOfs]		;; For active page
		adc	dx,word ptr [PageOfs+2]

	;;============================================
	;; Y loop
PatLoopY:	and		si,7
		mov		bh, [curr_fillpat+si]	;; Get next fill pattern
		push		esi
		mov		esi, dword ptr [fillcolour]
		mov		al, fillpatnum
		cmp		al, 1			;; Is this empty or solid fill?
		ja		isPatterned
		mov		bh, 0ffh		;; Pattern is solid
		test		al, al
		jnz		isSolid
		xor		esi,esi			;; Zero out color
isSolid:
isPatterned:	mov		cl,fill_bit
		rol		bh,cl			;; Rotate fill pattern

	;; Check for bank crossing within line
		movzx		ecx, [bar_xsiz]
		lea		eax, [ecx+ecx*2]
		add		ax, di
		jc		slowPatFill

;; Fast patterned color fill
fastPatStart:	mov		PrevFunc, offset @patSplit00

fastPatFill:	cmp		dl, curbk
		jnz		BarChg
@patSplit00:	xor		eax,eax
		rol		bh, 1
		sbb		eax, 0			;; EAX = -1 if bit set, else 0
		and		eax, esi		;; AND mask with color
		mov		es:[di], ax
		shr		eax, 8
		mov		es:[di+02], ah
		add		di, 3
		adc		dl, 0
		loop		@patSplit00
		jmp		short donePatFill

;; Slower patterned fill
slowPatStart:	mov		PrevFunc, offset @patSplit01

slowPatFill:	cmp		dl, curbk
		jnz		BarChg
@patSplit01:	xor		eax,eax
		rol		bh, 1
		sbb		eax, 0		;; EAX = -1 if bit set, else 0
		and		eax, esi		;; AND mask with color
		mov		es:[di], al		;; B
                TestXBank	di, 0ffffh
        	mov		es:[di+01], ah		;; G
                TestXBank	di, 0fffeh
        	shr		eax, 8
		mov		es:[di+02], ah		;; R
		add		di, 3
		adc		dl, 0
		loop		slowPatFill

donePatFill:	pop		esi
		inc		si			;; Increment pattern row
		add		di, [next_row]
		adc		dl, 0
		dec		bp			;; Decrease y counter
		jns		PatLoopY
		pop		es
		ret

BarChg:		call		newbank
		jmp		word ptr PrevFunc

;---------------------------------------------------------------------
;;PALETTE - Palette manipulation
;; Upper two bits of AX:
;;  00b - BX contains colour, AX is index		[Not imp]
;;  01b - Not used
;;  10b - BX=Red, CX=Green, DX=Blue, AX is index
;;  11b - BX=background colour				[Not imp]

palette:	mov	di,ax
		and	di,03fffh
		shl	ah,1			;; Test first bit
		jc	p_up
		ret
p_up:		shl	ah,1			;; Test second bit
		jnc	p_rgb
		ret

;; Set DAC RGB palette entry	RRRRRRRR-GGGGGGGG-BBBBBBBB 24-bit color
p_rgb:		xor	ax,ax
		mov	dh,cl
		xor	bh,bh
		shl	ebx, 16
		mov	bx, dx
	;; EDX = 00000000RRRRRRRRGGGGGGGGBBBBBBBB
		cmp	di,1024
		jnz	setfillRGB
		mov	dword ptr drawcolour,ebx		;; RealDrawColor
		ret
setfillRGB:	cmp	di,1025
		jnz	setbrdrRGB
		mov	dword ptr fillcolour,ebx		;; RealFillColor
		ret
setbrdrRGB:	mov	dword ptr currcolour,ebx		;; RealColor
		ret

;---------------------------------------------------------------------
;;COLOUR - Set draw and fill colours
;; AL=new draw colour
;; AH=new fill colour

colour:		ret

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
		shl	ax,3
		mov	si,ax
		add	si,offset fillpatterns	;; Get offset of pattern out
		jmp	short movepattern	;; of fill table

usrfillsty:	mov	si,bx			;; Get offset of user pattern
		push	es
		pop	ds

movepattern:	lea	di, curr_fillpat
movepat:	LoadDataSeg	es
		mov	cx,2
		repz	movsd			;; Store fill pattern
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
;; Draws a single character in the current textsize and drawcolour
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
		mov	eax,dword ptr drawcolour		;; Set fillcolour to drawcolour
		mov	dword ptr fillcolour,eax
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
		push	di
		call	getpixel
		pop	di
		cmp	edx,dword ptr [currcolour]
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
		push	di
		call	getpixel
		pop	di
		cmp	edx,dword ptr [currcolour]
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
		push	di
		call	getpixel
		pop	di
		cmp	edx,dword ptr [currcolour]
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
@ScnLin02:	push	word ptr [bp+8]			; y
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
		push	di
		call	getpixel
		pop	di
		cmp	edx,dword ptr [currcolour]
		je	@ScnUpDn03
		push	word ptr [bp-6]			;CurrY
		push	word ptr [bp+4]			;Xc
		call	ScanLeft
		add	sp,4
		mov	[bp-2],ax		;CurrXL
		jmp	short @ScnUpDn04
@ScnUpDn03:	push	word ptr [bp-6]			;CurrY
		push	CurrXR
		push	word ptr [bp+4]			;Xc
		call	ScanRightS
		add	sp,6
		mov	[bp-2],ax		;CurrXL
		test	ax,ax
		jl	@ScnUpDn01
@ScnUpDn04:	push	word ptr [bp-6]			;CurrY
		push	word ptr [bp-2]			;CurrXL
		call	FillHoriz
		add	sp,4
		mov	ax,[bp-4]		;PrevXL
		cmp	[bp-2],ax		;CurrXL
		jge	@ScnUpDn10
		mov	si,[bp-2]		;CurrXL
		push	word ptr [bp+6]			;Yc
		push	si
		call	ScanLeft
		add	sp,4
		mov	di,ax
		cmp	di,si
		jge	@ScnUpDn08
		jmp	short @ScnUpDn06
@ScnUpDn05:	mov	si,di
		push	word ptr [bp+6]			;Yc
		push	si
		call	ScanLeft
		add	sp,4
		mov	di,ax
@ScnUpDn06:	cmp	di,si
		jge	@ScnUpDn07
		mov	si,di
		push	word ptr [bp-6]			;CurrY
		push	si
		call	ScanLeft
		add	sp,4
		mov	di,ax
		cmp	di,si
		jl	@ScnUpDn05
@ScnUpDn07:	push	word ptr [bp+8]			;Dir
		push	word ptr [bp-6]			;CurrY
		mov	ax,[bp-2]		;CurrXL
		dec	ax
		push	ax
		push	si
		call	ScanLine
		add	sp,8
		test	ax,ax
		jne	@ScnUpDn09
@ScnUpDn08:	push	word ptr [bp-18]
		push	word ptr [bp+6]			;Yc
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
		push	word ptr [bp+6]			;Yc
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
		push	word ptr [bp-16]
		push	si
		call	ScanRight
		add	sp,4
		mov	di,ax
		cmp	di,si
		jg	@ScnUpDn15
@ScnUpDn14:	push	word ptr [bp-8]			;FillD
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
		push	word ptr [bp+6]	;Yc
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
		push	word ptr [bp+6]			;Yc
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
		push	word ptr [bp-18]
		push	ax
		push	word ptr [bp+4]			;Xc
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
		mov	si,ax			;; SeedX
		mov	di,bx			;; SeedY
		push	di
		call	getpixel		;; TstPix
		pop	di
		cmp	edx,dword ptr [currcolour]
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
;; Returns:
;;	EDX = pixel color (00000000RRRRRRRRGGGGGGGGBBBBBBBB)
;;
;; Code from John Bridges' VGAKIT

getpixel	proc		near
		mov		es, VidMem

	;; Offset = (x*3)+(y*bytesperline)
		movzx		edi, ax
		lea		edi, [edi+edi*2]	;; edi = x*3
		mov		ax, bx			;;  ax = y
		mul		xbytes			;;  ax *= bytesperline
		add		di,ax			;;  di += ax
		adc		dl,0

		add		di,word ptr [PageOfs]		;; For active page
		adc		dx,word ptr [PageOfs+2]

		cmp		dl,curbk	;; Check if pixel is in current bank
		jz		@gpixSplit00
		call		newbank
@gpixSplit00:	xor		eax, eax
		mov		al, es:[di]		;; B
		TestXBank	di, 0ffffh
		mov		ah, es:[di+1]		;; G
		TestXBank	di, 0fffeh
		rol		eax,16
		mov		al,es:[di+2]		;; R
		rol		eax, 16
		mov		edx, eax
		ret
getpixel	endp

;---------------------------------------------------------------------
;;PUTPIXEL - Writes a pixel to the screen
;; AX=X coordinate of the seed point
;; BX=Y coordinate of the seed point
;; DL=colour of the seed point
;;
;; Color for pixel plot is stored in currcolour for 24 bit color
;;
;; Code from John Bridges' VGAKIT

putpixel	proc		near
		mov		es, VidMem

	;; Offset = (x*3)+(y*bytesperline)
		movzx		edi, ax
		lea		edi, [edi+edi*2]	;; edi = x*3
		mov		ax, bx			;;  ax = y
		mul		xbytes			;;  ax *= bytesperline
		add		di,ax			;;  di += ax
		adc		dl,0

		add		di,word ptr [PageOfs]		;; For active page
		adc		dx,word ptr [PageOfs+2]

		cmp		dl,curbk	;; Check if pixel is in current bank
		jz		@ppixSplit00
		call		newbank
@ppixSplit00:	mov		eax, dword ptr [currcolour]
		mov		es:[di], al	;; B
		TestXBank	di, 0ffffh
		mov		es:[di+1], ah	;; G
		TestXBank	di, 0fffeh
		shr		eax, 8
		mov		es:[di+2], ah	;; R
		ret
putpixel	endp

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

savebitmap:	push		gs
		mov		gs, [VidMem]
		mov		ax,es:[bx]	;; Width of image-1
		inc		ax
		mov		[bar_xsiz],ax
		movzx		eax, ax
		lea		eax, [eax+eax*2]
		neg		ax
		add		ax, [xbytes]
		mov		[next_row], ax

	;; Offset = (x*3)+(y*bytesperline)
		movzx		edi, cx
		lea		edi, [edi+edi*2]	;; edi = x*3
		mov		ax, dx			;;  ax = y
		mul		xbytes			;;  ax *= bytesperline
		add		di,ax			;;  di += ax
		adc		dl,0

		add		bx,word ptr [PageOfs]		;; For active page
		adc		dx,word ptr [PageOfs+2]

		mov		si,es:[bx+2]	;; Height of image-1
	;; Make sure image data starts on a dword-aligned boundary
		add		bx,7
		and		bx, NOT 3

GetLoopY:	mov		cx,[bar_xsiz]
GetLoopX:	cmp		dl,curbk
		jz		Getnoswitch
		call		newbank
Getnoswitch:	xor		eax, eax
		mov		al, gs:[di]		;; B
		TestXBank	di, 0ffffh
		mov		ah, gs:[di+1]		;; G
		TestXBank	di, 0fffeh
		rol		eax,16
		mov		al,gs:[di+2]		;; R
		rol		eax, 16
		mov		es:[bx],eax	;; Store pixel in buffer
		add		bx, 04
		jnz		NIseg

		;; Increment segment
		IncrSegment	es

NIseg:		add	di,3
		adc	dl,0
		loop	GetLoopX

	;; Increment to next row
		add	di, [next_row]
		adc	dl, 0
		dec	si		;; Decrease y counter
		jns	GetLoopY
GetExit:	pop	gs
		ret

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


restorebitmap:	push		gs
		mov		gs, VidMem
		movzx		si, al
		cmp		si, 8
		jle		@bltOk
		mov		si, 8
@bltOk:		shl		si, 1
		mov		ax, bltFuncs[si]
		mov		[BltModeFunc], ax

		mov		si,es:[bx]	;; Width of image-1
		inc		si
		mov		[bar_xsiz],si
		movzx		esi, si
		lea		esi, [esi+esi*2]
		neg		si
		add		si, [xbytes]
		mov		[next_row], si

	;; Offset = (x*3)+(y*bytesperline)
		movzx		edi, cx
		lea		edi, [edi+edi*2]	;; edi = x*3
		mov		ax, dx			;;  ax = y
		mul		xbytes			;;  ax *= bytesperline
		add		di,ax			;;  di += ax
		adc		dl,0

		add		bx,word ptr [PageOfs]		;; For active page
		adc		dx,word ptr [PageOfs+2]

		mov		si,es:[bx+2]	;; Height of image-1
	;; Make sure image data starts on a dword-aligned boundary
		add		bx,7
		and		bx,NOT 3

PutLoopY:	mov		cx,[bar_xsiz]
PutLoopX:	cmp		dl,curbk
		jz		Putnoswitch
		call		newbank
Putnoswitch:	mov		eax, es:[bx]
		call		word ptr [BltModeFunc]		;; Plot pixel
		add		bx, 4
		jnz		NOseg

		;; Increment segment
		IncrSegment	es

NOseg:		add		di, 3
		adc		dl, 0
		loop		PutLoopX

		add		di, [next_row]
		adc		dl, 0
		dec		si
		jns		PutLoopY
PutExit:	pop		gs
		ret

;; Transparent put
@transPut:	test	eax, eax
		jnz	@copyPut
		ret

;; Copy/Xor put
@notPut:	not		eax
@copyPut:	mov		gs:[di], al	;; B
		TestXBank	di, 0ffffh
		mov		gs:[di+1], ah	;; G
		TestXBank	di, 0fffeh
		shr		eax, 8
		mov		gs:[di+2], ah	;; R
		ret

;; Xor/Xnor put
@xnorPut:	not		eax
@xorPut:	xor		gs:[di], al	;; B
		TestXBank	di, 0ffffh
		xor		gs:[di+1], ah	;; G
		TestXBank	di, 0fffeh
		shr		eax, 8
		xor		gs:[di+2], ah	;; R
		ret

;; Or/Nor put
@norPut:	not		eax
@orPut:		or		gs:[di], al	;; B
		TestXBank	di, 0ffffh
		or		gs:[di+1], ah	;; G
		TestXBank	di, 0fffeh
		shr		eax, 8
		or		gs:[di+2], ah	;; R
		ret

;; And/Nand put
@nandPut:	not		eax
@andPut:	and		gs:[di], al	;; B
		TestXBank	di, 0ffffh
		and		gs:[di+1], ah	;; G
		TestXBank	di, 0fffeh
		shr		eax, 8
		and		gs:[di+2], ah	;; R
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
		mov	cx,COLORMODE		;; Bleh
		ret

;; Get offset of colour table
clrtable:	LoadDataSeg	es
		mov	bx,offset colourtable
		ret

;---------------------------------------------------------------------
; Now for the miscellaneous routines

;; SETPIXCOL - Sets pixel color for ellipse drawing
setpixcol	proc	far
		push	ds
		LoadDataSeg	ds
		mov	eax,dword ptr drawcolour
		mov	dword ptr currcolour,eax
		pop	ds
		ret
setpixcol	endp

;; BITS_PER_PIX - Returns the pixel colour depth
bits_per_pix	proc	far
		mov	ax, 24
		ret
bits_per_pix	endp

;; SETVISPAGE - Sets the visable video page
setvispage	proc	far
		push	cx
		push	ds
		LoadDataSeg	ds

		mov	bl,curr_mode
		xor	bh,bh
		xor	ah,ah
		shl	bx,2
		mov	cx,ax
		xor	ax,ax
		xor	dx,dx
		jcxz	page_it
page1:		add	dx,word ptr [PageSize+bx]
		adc	ax,word ptr [PageSize+bx+2]
		loop	page1
page_it:	;; AX - upper bits
		;; DX - lower bits

		push	ax
		mov	bx,dx
		mov	dx,CRTC_INDEX
		mov	al,0dh
		mov	ah,bl
		out	dx,ax
		mov	al,0ch
		mov	ah,bh
		out	dx,ax
		pop	bx

		call	word ptr pageadr
		pop	ds
		pop	cx
		ret
setvispage	endp

getdrawpage	proc
		mov	bl,curr_mode
		xor	bh,bh
		xor	ah,ah
		shl	bx,2
		mov	cx,ax
		xor	ax,ax
		xor	dx,dx
		jcxz	spage_it
spage1:		add	ax,word ptr [bx+PageSize]
		adc	dx,word ptr [bx+PageSize+2]
		loop	spage1
spage_it:	shl	ax,1
		rcl	dx,1
		shl	ax,1
		rcl	dx,1
		ret
getdrawpage	endp

;; SETDRAWPAGE - Sets the drawing video page
setdrawpage	proc		far
		push		cx
		push		ds
		LoadDataSeg	ds
		call		getdrawpage
		mov		word ptr [PageOfs],ax
		mov		word ptr [PageOfs+2],dx
		pop		ds
		pop		cx
		ret
setdrawpage	endp

;; SETWRITEMODE - Sets the line drawing mode
setwritemode	proc		far
		push		ds
		LoadDataSeg	ds
		mov		si, ax
		shl		si, 1
		mov		ax, bltFuncs[si]
		mov		[WriteModeFunc], ax
		pop		ds
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

IF MOUSE_SOURCE EQ 1
INCLUDE		mouse2.inc
ENDIF

	IF	BGIVERSION GE 3
_TEXT	ENDS

_DATA	SEGMENT	PARA	PUBLIC	USE16	'DATA'

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

Stat0 Status<,,319,199,319,199,,,8600,,,,>		;;320x200x16m
Mode0		db	22,"SuperVGA 320x200x24bit",0
Mode0v		db	18,"VESA 320x200x24bit",0
Stat1 Status<,,639,349,639,349,,,9500,,,,>		;;640x350x16m
Mode1		db	22,"SuperVGA 640x350x24bit",0
Stat2 Status<,,639,399,639,399,,,9500,,,,>		;;640x400x16m
Mode2		db	22,"SuperVGA 640x400x24bit",0
Stat3 Status<,,639,479,639,479,,,11100,,,,>		;;640x480x16m
Mode3		db	22,"SuperVGA 640x480x24bit",0
Mode3v		db	18,"VESA 640x480x24bit",0
Stat4 Status<,,799,599,799,599,,,10000,,,,>		;;800x600x16m
Mode4		db	22,"SuperVGA 800x600x24bit",0
Mode4v		db	18,"VESA 800x600x24bit",0
Stat5 Status<,,1023,767,1023,767,,,10000,,,,>		;;1024x768x16m
Mode5		db	23,"SuperVGA 1024x768x24bit",0
Mode5v		db	19,"VESA 1024x768x24bit",0
Stat6 Status<,,1279,1023,1279,1023,,,10000,,,,>		;;1280x1024x16m
Mode6		db	24,"SuperVGA 1280x1024x24bit",0
Mode6v		db	20,"VESA 1280x1024x24bit",0

;; Table of structures
StatTable	dw	Stat0, Stat1, Stat2, Stat3, Stat4, Stat5, Stat6

;; Table of mode names
ModeNameTable	dw	Mode0, Mode1, Mode2, Mode3, Mode4, Mode5, Mode6
ModeVNameTable	dw	Mode0v,Mode1, Mode2, Mode3v,Mode4v,Mode5v,Mode6v

VidMem		dw	0A000h		;; Offset of video memory
SelectorInc	dw	1000h		;; Selector/segment increment

bltFuncs	dw	@copyPut, @xorPut, @orPut, @andPut
		dw	@notPut,  @xnorPut, @norPut, @nandPut
		dw	@transPut

colourtable	db	0h		;; Zero-length colour table

cp_x		dw	?		;; Current drawing position
cp_y		dw	?

curr_mode	db	?		;; Current video mode
xbytes		dw	?		;; Current mode width in bytes
xsiz		dw	?		;; Current mode width in pixels
ysiz		dw	?		;; Current mode height in pixels

bar_xsiz	dw	?		;; Patterned bar & BITBLT variables
next_row	dw	?

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

currcolour	label	word
		dd	?
drawcolour	label	word
		dd	?
fillcolour	label	word
		dd	?

svga_Oldreg	label	byte
Xvals		dw	MAXSTACK dup(0)		;; Floodfill variables
Yvals		dw	MAXSTACK dup(0)
StkPtr		dw	?
PrevXR		dw	?
CurrXR		dw	?
FillD		dw	?

deldxy		dw	?			;; Line drawing variables
delsxy		dw	?
delde		dw	?
delse		dw	?

linecolour	db	?			;; Line parameters
curr_linestyle	dw	0ffffh
linestyles	dw	0ffffh			;; Solid Line
		dw	0cccch			;; Dotted Line
		dw	0fc78h			;; Center Line
		dw	0f8f8h			;; Dashed Line

fillpatnum	db	?			;; Fill parameters
fill_bit	db	?
bltmode		db	?
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
bankadr		dw	NotImpNear	;; Address of bank-switch routine.
pageadr		dw	NotImpNear	;; Address of paging routine
svga_IOAdr	dw	?

Logical		db	00h,018h,010h,008h
		db	00h,018h,010h,008h,00h

cardFlags	db	?
VESA_granlrty	db	0		;; VESA initialization variables

PageSize	dd	0,0,0,0,0,0,0
PageOfs		dd	?
PrevFunc	dw	?
WriteModeFunc   dw      ?                       ;; Writemode drawing routine
BltModeFunc	dw	?

CurrVidModes	dw	DefaultModes		;; Pointer to video mode table
OrigVidModes	dw	DefaultModes

BytesPerLine	dw	960
		dw	1920
		dw	1920
		dw	1920
		dw	3072			;;2400
		dw	3072
		dw	3840

AcumosModes		EQU	$
AheadModes		EQU	$
AL2101Modes		EQU	$
ATIModes		EQU	$
ChipsModes		EQU	$
CompaqModes		EQU	$
GenoaModes		EQU	$
MXICModes		EQU	$
NCRModes		EQU	$
Oak77Modes		EQU	$
P2000Modes		EQU	$
ParadiseModes		EQU	$
RealtekModes		EQU	$
Trident88Modes		EQU	$
Trident89Modes		EQU	$
Tseng30Modes		EQU	$
Video7Modes		EQU	$
WeitekModes		EQU	$
HMCModes		EQU	$
UMCModes		EQU	$
CirrusModes		EQU	$
Cirrus64Modes		EQU	$
IITAgxModes		EQU	$
TsengW32Modes		EQU	$
DefaultModes	dw	0,0			;; Default - Non SuperVGA modes
		dw	0,0
		dw	0,0
		dw	0,0
		dw	0,0
		dw	0,0
		dw	0,0
		dw	0,0
ATIGUPModes	dw	0,0
		dw	0,0
		dw	0,0
		dw	0,0
		dw	0,0
		dw	0,0
		dw	0,0
		dw	0,0
Cirrus54Modes	dw	070h,0			;; Cirrus GD 5422
		dw	0,0
		dw	0,0
		dw	071h,0
		dw	0,0
		dw	0,0
		dw	0,0
EverexModes	dw	0,0			;; Everex Viewpoint TC (629)
		dw	0,0
		dw	0,0
		dw	070h,077h
		dw	0,0
		dw	0,0
		dw	0,0
S3Modes		dw	0,0			;; S3 chipset
		dw	0,0
		dw	0,0
		dw	0,0
		dw	04f02h,0112h
		dw	0,0
		dw	0,0
		dw	0,0
Tseng40Modes	dw	0,0			;; Tseng 4000 TC modes
		dw	010f0h,02dffh
		dw	010f0h,02fffh
		dw	010f0h,02effh
		dw	0,0
		dw	0,0
		dw	0,0
VesaModes	dw	04f02h,010fh
		dw	0,0
		dw	0,0
		dw	04f02h,0112h
		dw	04f02h,0115h
		dw	04f02h,0118h
		dw	04f02h,011bh
VESAMODESIZE	EQU	$-VesaModes

	IF	BGIVERSION GE 3
_DATA	ENDS
	ELSE
_TEXT	ENDS
	ENDIF

end


