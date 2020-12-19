;; SvgaBank - SuperVGA detection, bankswitching and paging code
;;   Portions Copyright Finn Thoegerson (VGADOC3.ZIP)
;;
;;  Version:	$Revision:   1.12  $
;;
;;  Revision history:
;;  -----------------
;;  $Log:   C:/svga/rcs/svgabank.inv  $
;;
;;   Rev 1.12   14 Nov 1994 23:53:02   JORDAN
;;Fixed Cirrus54 paging
;; 
;;    Rev 1.11   23 Aug 1994  0:05:54   JORDAN
;;   
;;    Rev 1.10   20 Jul 1994 22:09:50   JORDAN
;; Fixed Chips&Tech detect
;; Started fixing bugs (VESA) for protected mode.
;; 
;;    Rev 1.9   09 Jun 1994 23:48:52   JORDAN
;;   
;;    Rev 1.8   14 May 1994 19:36:22   JORDAN
;;
;;    Rev 1.7   09 Apr 1994 12:28:14   JORDAN
;; Added new chipset support from VGADOC03.ZIP (HMC, UMC, Weitek)
;; Fixed Cirrus Logic detection/bankswitch bugs
;;

;; Front end bank switching procedure
newbank		proc
		push	ax
		push	dx

	IF 	BGIVERSION GE 1
	;; Set bank in mouse driver
		mov	ax, 04503h
		int	033h
	ENDIF

		mov	ah, dl
		mov	al, dl
		mov	[curbk], ah
		cli
	;; On entry, AH/AL = bank number
		call	word ptr BankAdr
		sti
		pop	dx
		pop	ax
		ret
newbank		endp

PageShift	MACRO	__port, __idx, __flag
		local		@1
		rdinx		__port, __idx
		and		al, __flag
		jz		@1
		shr		bl,1
@1:
ENDM

;; wrinx(__port, __inx, bank * 17);
RWBankIndex	MACRO 	__port, __inx
		and	ah,0fh
		mov	al,ah
		shl	ah,4
		or	ah,al
		mov	al,__inx
		mov	dx,__port
		out	dx,ax
ENDM

;; outp(__port,bank);
;; outp(__port+1,bank)
RWBankPort	MACRO	__port
		mov	dx,__port
		out	dx,al
		inc	dx
		out	dx,al
ENDM

;; wrinx(__port,__inx,bank);
;; wrinx(__port,__inx+1,bank);
RWBankPortIdx	MACRO	__port, __inx
		mov	dx,__port
		mov	al,__inx
		out	dx,ax
		inc	al
		out	dx,ax
ENDM

;; outp(__port, bank * 17);
RWBank		MACRO 	__port
		and	ah,0fh
		mov	al,ah
		shl	ah,4
		or	al,ah
		mov	dx,__port
		out	dx,al
ENDM

;;=================================================================
;; Default Set Display start function
;;
;; BX:AX = Display start address
;;=================================================================
SetDisplayStart	proc	near
		push	ax
		push	bx
		mov	bh, al
		mov	bl, 0dh
		mov	ch, ah
		mov	cl, 0ch
		outpw	CRTC_INDEX, bx
		outpw	dx, cx
		pop	bx
		pop	ax
$null_page:	ret
SetDisplayStart	endp

;;=================================================================
;; Acumos bank switching code
;;=================================================================
$acumos:	shl	ah,4
		modinx	GC_INDEX, 09h, 0F0h, ah
		ret

;;=================================================================
;; Ahead A bank switching code
;;=================================================================
$aheada:	push	cx
		mov	ch,ah
		inp	03cch
		mov	dl,0c2h
		and	al,11011111b
		shr	ch,1
		jnc	@@SkpA
		or	al,00100000b
@@SkpA:		out	dx,al
		mov	dx,GC_INDEX
		mov	al,0dh
		mov	ah,ch
		out	dx,ax
		pop	cx
		ret

;; Ahead B bank switching code
;;  wrinx(GC_INDEX, 0dh, bank *17);
;; ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿
;; ³     write     ³     read      ³
;; ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
$aheadb:	RWBankIndex	GC_INDEX, 0dh
		ret

;; Ahead B set extended display start address
;; ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿
;; ³                       ³ start ³
;; ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÙ
$aheadb_page:	
	IF	COLORMODE EQ 256
		PageShift	GC_INDEX, 0Ch, 020h
	ENDIF
		modinx		GC_INDEX, 01ch, 3, bl
		ret

;;=================================================================
;; AL2101, Primus 2000, Realtek bankswitch
;; outp(03d6h, bank);
;; outp(03d7h, bank);
;;=================================================================
$p2000:
$realtek:
$al2101:	RWBankPort	03d6h
		ret

;; AL2101 set extended display start address
$al2101_page:	PageShift	GC_INDEX, 0Ch, 010h
		modinx		CRTC_INDEX, 020h, 7, bl
		ret

;; Primus 2000 set extended display start address
$p2000_page:	mov	dx,GC_INDEX
		mov	al,021h
		out	dx,al
		inc	dx
		in	al,dx
		and	al,0f8h
		and	bl,7
		or	al,bl
		out	dx,al
		ret

;;=================================================================
;; ATI rev 1 bankswitch	
;;=================================================================
$ati1:		shl		ah,1
		modinx		svga_IOAdr, 0b2h, 01eh, ah
		ret

;; ATI Ultra bankswitch
$atiGUP:	push		ax
		shr		ah,4
		modinx		svga_IOAdr, 0AEh, 3, ah
		pop		ax
;; ATI rev 2 bankswitch
$ati2:		mov		ah,022h
		mul		ah
		or		ah,al
		modinx		svga_IOAdr, 0b2h, 0ffh, ah
		ret

;; ATI rev 1 set extended display start address
$ati1_page:	shl		bl, 6
		modinx		svga_IOAdr, 0b0h, 040h, bl
		ret

$ati2_page:	PageShift	svga_IOAdr, 0b0h, 020h
		mov		bh, bl
		shl		bl, 6
		modinx		dx, 0b0h, 040h, bl
		mov		bl, bh
		shl		bl, 3
		modinx		dx, 0a3h, 010h, bl
		modinx		dx, 0ADh, 04h, bh
		ret

;;=================================================================
;; Chips & Technologies 451 bankswitch
;;  wrinx(svga_IOAdr, 0Bh, bank);
;;=================================================================
$chips451:	mov	al,0bh
		mov	dx,svga_IOAdr
		out	dx,ax
		ret

;; C&T 452/453 bankswitch
$chips453:	shl	ah,2
$chips452:	
	IF	COLORMODE EQ 16
		shl	ah,4
	ELSE
		shl	ah,2
	ENDIF
		mov	dx,svga_IOAdr
		mov	al,010h
		out	dx,ax
		ret

;; C&T set extended display start address
$chips_page:	wrinx		svga_IOAdr, 0Ch, bl
		ret

;;=================================================================
;; Cirrus 54xx bankswitch
;;=================================================================
$cirrus54:	shl	ah,2
		rdinx	GC_INDEX, 0Bh
		and	al,32
		jnz	@cir54bk
		shl	ah,2
@cir54bk:	;;outp	dx, 09h
		;;outp	GC_INDEX+1,ah
		;;wrinx	dx, 09h, al
		mov	dx,GC_INDEX
		mov	al,09h
		out	dx,ax
		ret

if 0
$cirrus54_init:	wrinx		SC_INDEX, 06h, 12h
		rdinx		CRTC_INDEX, 01bh
		or		al, 02h
		wrinx		dx, 01bh, al
		ret
endif

;; Cirrus set extended display start address
$cirrus54_page:	push	bx
		mov	bh,bl
		and	bh, 6
		shl	bh, 1
		and	bl, 1
		or	bl, bh
	;; Set bits 16-18 of display start address
		modinx	CRTC_INDEX, 01bh, 0dh, bl
		pop	bx
		and	bl, 8h
		shl	bl, 4
	;; Set bit 19 of display start address
		modinx	dx, 01dh, 080h, bl
		ret

;;=================================================================
;; Cirrus 64xx bankswitch
;;=================================================================
$cirrus64:	shl	ah,4
		RWBankPortIdx	GC_INDEX,0Eh
		ret

$cirrus64_page:	wrinx	GC_INDEX, 07Ch, bl
		ret

;;=================================================================
;; Compaq bankswitch
;;=================================================================
$compaq:	push		ax
		wrinx		GC_INDEX, 0Fh, 5
		shl		ah, 4
		wrinx		dx, 045h, ah
		rdinx		dx, 040h
		and		al,1
		jz		@cpq
		add		ah, 8
@cpq:		wrinx		dx, 046h, ah
		ret

$compaq_page:	shl		bl, 2
		modinx		GC_INDEX, 042h, 0Ch, bl
		ret

;;=================================================================
;; Everex bankswitch
;;=================================================================
$everex:	push	bx
		mov	bx,ax
		inp	03cch
		and	al,0dfh
		test	bl,2
		jz	$everex_temp
		add	bl,032
$everex_temp:	outp	03c2h, al
		shl	bl,7
		modinx	SC_INDEX,8,080h,bl
		pop	bx
		ret

if 0
$everex:	push	cx
		mov	cl,al
		mov	dx,SC_INDEX
		mov	al,8
		out	dx,al
		inc	dl
		in	al,dx
		dec	dl
		shl	al,1
		shr	cl,1
		rcr	al,1
		mov	ah,al
		mov	al,8
		out	dx,ax
		mov	dl,0cch
		in	al,dx
		mov	dl,0c2h
		and	al,0dfh
		shr	cl,1
		jc	$evx_tmp
		or	al,020h
$evx_tmp:	out	dx,al
		pop	cx
		ret
endif

;;=================================================================
;; Genoa 5x00/6x00 bankswitch
;;=================================================================
$genoa:		shl	ah,3
		or	ah,al
		or	ah,040h
		mov	al,6
		outpw	SC_INDEX, ax
		ret

;;=================================================================
;; HMC bankswitch
;;=================================================================
$hmc:
	IF	COLORMODE EQ 256
		shl		al,4
		modinx		SC_INDEX, 0EEh, 70h, al
	ENDIF
		ret

;; HMC set extended display start address
$hmc_page:	PageShift	SC_INDEX, 0E7h, 1
		modinx		dx, 0EDh, 1, bl
		ret

;;=================================================================
;; Bankswitch for IITAGX chip
;;=================================================================
$iitagx:	inp		svga_IOAdr
		and		al,4
		jnz		@iit2
		mov		dx, [svga_IOAdr]
		add		dx, 8
		outp		dx, ah
		ret
@iit2:		wrinx		SC_INDEX, 0Bh, 0
		rdinx		SC_INDEX, 0Bh
		or		al,al
		jnz		@iit3
@iit3:		xor		ah,2
		modinx		SC_INDEX, 0Eh, 0Fh, ah
		ret

$iitagx_page:	inp		svga_IOAdr
		and		al, 4
		jnz		@iit1
		shl		bl, 5
		modinx		CRTC_INDEX, 01Eh, 020h, bl
@iit1:		ret

;;=================================================================
;; MXIC 68000 bankswitch
;;=================================================================
$mxic:		RWBankIndex	SC_INDEX, 0c5h
		ret

;; MXIC set extended display start address
$mxic_page:	modinx		SC_INDEX, 0F1h, 3, bl
		ret

;;=================================================================
;; NCR bankswitch
;;=================================================================
$ncr:		shl		ah,2
	IF	COLORMODE EQ 16
		shl		ah,2
	ENDIF
		mov		al,018h
		mov		dx,SC_INDEX
		out		dx,ax
		mov		al,01ch
		out		dx,ax
		ret

;; NCR set extended display start address
$ncr_page:	modinx		CRTC_INDEX, 031h, 0fh, bl
		ret

;;=================================================================
;; Oak Technologies 067/077 bankswitch
;; wrinx(03deh, 011h, bank*17);
;;=================================================================
$oak77:		RWBankIndex	03deh, 011h
		ret

;;=================================================================
;; Oak 087 bankswitch
;;  wrinx(03DEh, 023h, bank);
;;  wrinx(03DEh, 024h, bank);
;;=================================================================
$oak87:		RWBankPortIdx	03deh, 023h
		ret

;;=================================================================
;; Paradise bankswitch
;;  wrinx(GC_INDEX, 09h, bank << 4);
;;  wrinx(GC_INDEX, 0Ah, bank << 4);
;;=================================================================
$paradise:	shl		ah,4
		RWBankPortIdx	GC_INDEX,09h
		ret

;; Paradise set extended display start address
$paradise_page:	mov	dx,GC_INDEX
		mov	al,0dh
		out	dx,al
		inc	dx
		in	al,dx
		and	al,0e7h
		and	bl,3
		shl	bl,3
		or	al,bl
		out	dx,al
		ret

;;=================================================================
;; S3 chipset bankswitch
;;=================================================================
$s3:		push	cx
		mov	dx,CRTC_INDEX
	IF	COLORMODE EQ 16
		shl	al,2
	ENDIF
		mov	ch,al
		and	al,0fh
		mov	cl,al
		mov	ax,4838h
		out	dx,ax
		mov	al,31h
		out	dx,al
		inc	dl
		in	al,dx
		or	al,01001b
		out	dx,al
		dec	dl
		mov	al,035h
		out	dx,al
		inc	dl
		in	al,dx
		and	al,0f0h
		or	al,cl
		out	dx,al
		dec	dl
;; foo goes here
		mov	ax,38h
		out	dx,ax
		pop	cx
		ret

;; S3 set extended display start address
$s3_page:	wrinx		CRTC_INDEX, 038h, 048h
		wrinx		dx, 039h, 0A5h
		mov		bh, bl
		shl		bh, 4
		modinx		dx, 031h, 030h, bh
		shr		bl, 2
		modinx		dx, 051h, 1, bl
		wrinx		dx, 039h, 05Ah
		wrinx		dx, 038h, 0h
		ret

;;=================================================================
;; Trident 8800/8900/9000 bankswitch
;;=================================================================
$trident:	xor	ah,2
		wrinx	SC_INDEX,11,0
		rdinx	dx,11
		modinx	dx,14,0fh,ah
		ret

;; Trident 8800 set extended display start address
$tri88_page:	mov	dx,CRTC_INDEX
		mov	al,01eh
		out	dx,al
		inc	dx
		in	al,dx
		and	al,0dfh
		and	bl,1
		mov	cl,5
		shl	bl,cl
		or	al,bl
		or	al,080h
		out	dx,al
		ret

;; Trident 8900 set extended display start address
$tri89_page:	push	bx
		mov	dx,CRTC_INDEX
		mov	al,01eh
		out	dx,al
		inc	dx
		in	al,dx
		and	al,05fh
		and	bl,1
		mov	cl,5
		shl	bl,cl
		or	al,bl
		or	al,080h
		out	dx,al
		mov	dx,SC_INDEX
		mov	al,0bh
		out	dx,al
		inc	dl
		xor	al,al
		out	dx,al
		dec	dl
		mov	al,0eh
		out	dx,al
		inc	dl
		in	al,dx
		and	al,0feh
		pop	bx
		shr	bl,1
		and	bl,1
		or	al,bl
		out	dx,al
		ret

;;=================================================================
;; Tseng ET3000 bankswitch
;;=================================================================
$tseng3:	shl	al,4
		or	al,ah
		add	ax,64
		outp	03cdh, al
		ret

;; Tseng ET3000 set extended display start address
$tseng3_page:	
	IF	COLORMODE EQ 256
		shr		bl,1
	ELSE
		PageShift	SC_INDEX, 7, 040h
	ENDIF
		shl		bl, 1
		modinx		CRTC_INDEX, 023h, 2, bl
		ret

;;=================================================================
;; Tseng ET4000/W32 bankswitch
;;=================================================================
$tseng4_w32:	push		ax		;; Write upper bank bits
		shr		ah,4
		RWBank		03cbh
		pop		ax
;; Tseng ET4000 bankswitch
;; outp(03cdh, bank*17);
$weitek:
$tseng4:	RWBank		03cdh		;; Write lower bank bits
		ret

;; Tseng ET4000 set extended display start address
$tseng4_page:	modinx		CRTC_INDEX, 033h, 3, bl
		ret

$tsengW32_page:	modinx		CRTC_INDEX, 033h, 0Fh, bl
		ret

;;=================================================================
;; Video7 bankswitch
;;=================================================================
$video7:	push	bx
		mov	bx,ax
		inp	03cch
		and	al,0dfh
		test	bl,2
		jz	$video7_temp
		add	al,32
$video7_temp:	mov	dx,03c2h
		out	dx,al
		modinx	SC_INDEX,0f9h,1,bl
		mov	ax,bx
		shr	ax,1
		shr	ax,1
		add	bx,ax
		modinx	SC_INDEX,0f6h,080h,bl
		pop	bx
		ret

;; Video7 set extended display start address
$video7_page:	mov	dx,SC_INDEX
		mov	al,0f6h
		out	dx,al
		inc	dx
		in	al,dx
		and	al,0cfh
		and	bl,3
		mov	cl,4
		shl	bl,cl
		or	al,bl
		out	dx,al
		ret

;;=================================================================
;; Bank switch for UMC
;; wrinx(seq_index, 6, bank*17);
;;=================================================================
$umc:		RWBankIndex	SC_INDEX, 6
		ret

$weitek_page:	shl		bl,3
		modinx		GC_INDEX, 0Dh, 018h, bl
		ret

;;=================================================================
;; VESA bankswitch
;;=================================================================
$vesa:		push	bx
		mul	Vesa_granlrty
		push	ax
		mov	dx,ax
		xor	bx,bx
		mov	ax,04f05h
		int	010h
		mov	bx,1
		pop	dx
		mov	ax,04f05h
		int	010h
		pop	bx
		ret

;; BX:AX = Display start address
$vesa_page:	;;int	3
		mov	cx, ax
		mov	dx, bx		;; DX:AX = start address
		div	xbytes
		mov	cx, dx
	IF COLORMODE EQ 16
		shl	cx, 3
	ENDIF
		mov	dx, ax
		mov	ax, 4f07h
		xor	bx, bx
		int	010h
		ret

;; Do VESA interrupt - Real mode or DPMI
doVesaInt	proc	near
	IF	BGIVERSION GE 3
		cmp	CurOpMode,0
		jnz	@vesaDPMI
	ENDIF
		push	ds
		pop	es
		int	010h
		cmp	ax,004fh
		jz	@vesaFail
		stc
@vesaFail:	ret

	IF	BGIVERSION GE 3
	;; Do the DPMI real mode thing
@vesaDPMI:	push	ds
		pop	es
		push	di
		push	es
		mov	word ptr SimInt.RealEAX,ax
		mov	word ptr SimInt.RealECX,cx
		mov	word ptr SimInt.RealEDI,di
		mov	ax,RealModeDS
		mov	SimInt.RealES,ax
		mov	SimInt.RealDS,ax
		mov	SimInt.RealSS,0
		mov	SimInt.RealSP,0
		mov	word ptr SimInt.RealESP,0
		mov	word ptr SimInt.RealESP+2,0
		lea	di,SimInt
		mov	ax,0300h
		push	bx
		mov	bl,10h
		xor	bh,bh
		xor	cx,cx
		int	031h
		pop	bx
		pop	es
		pop	di
		jc	@vesaDPMIFail
		mov	ax,word ptr SimInt.RealEAX
		cmp	ax,0004fh
		jz	@vesaDPMIFail
		stc
@vesaDPMIFail:	ret
	ENDIF
doVesaInt	endp

;;=================================================================
;; Whichvga - detects type of SVGA card installed and sets up the
;;  appropriate mode entry table, bankswitch and extended display
;;  start routines
;;=================================================================
dtctTable	label 	word
		dw	$vesa_Dtct
		dw	$weitek_Dtct
		dw	$chips_Dtct
		dw	$paradise_Dtct
		dw	$compaq_Dtct
		dw	$video7_Dtct
		dw	$genoa_Dtct
		dw	$everex_Dtct
		dw	$cirrus54_Dtct
		dw	$cirrus64_Dtct
		dw	$cirrus_Dtct
		dw	$trident_Dtct
		dw	$ati_Dtct
		dw	$ahead_Dtct
		dw	$ncr_Dtct
		dw	$s3_Dtct
		dw	$avance_Dtct
		dw	$mxic_Dtct
		dw	$acumos_Dtct
		dw	$realtek_Dtct
		dw	$p2000_Dtct
		dw	$oak_Dtct
		dw	$umc_Dtct
		dw	$hmc_Dtct
		dw	$tseng_Dtct
		dw	-1

;;===================================================================
;; whichvga - Detect which Svga card is installed
;;===================================================================
whichvga	proc		near
		SetCardType	Default
		SetChipType	null
		SetPageType	null
		lea		si, dtctTable

	;; Load address of detect function
@dtctSvgaLp:	cmp		word ptr cs:[si], -1	;; check for end of table
		jz		@endDtct

	;; Call detect function
		call		word ptr cs:[si]
		add		si,2
	;; Check if bankswitch proc was updated
		cmp		word ptr [BankAdr], offset $null
		jz		@dtctSvgaLp
$null:
@endDtct:	ret
whichvga	endp

;;===================================================================
;; Detect VESA
;;===================================================================
$vesa_Dtct	proc		near
		push		si
		mov		ax,04f00h
		mov		di,offset Xvals
		call		doVesaInt
		jc		@notVesa
		cmp		word ptr ds:[di],'EV'
		jne		@notVesa
		cmp		word ptr ds:[di+02],'AS'
		jne		@notVesa
	;; Found a VESA card
		;;SetCardType	Vesa
		;;SetChipType	vesa
		;;SetPageType	vesa

	IF	BGIVERSION GE 1
		mov		bx,ds:[di+10h]		;; segment
		mov		di,ds:[di+0eh]		;; offset
	IF	BGIVERSION GE 3
		cmp		CurOpMode,0
		jz		@noVesaDPMI
		push		bx
		mov		ax,2
		int		031h			;; Convert segment to selector
		pop		bx
		jc		@notVESA
@vesaSelector:	mov		bx,ax
	ENDIF
@noVesaDPMI:	mov		es,bx
		xor		si,si			;; DS:VesaModes[si]

	;; Clear the unsupported modes from the VesaModes list
@vloopi:	mov		bx,di			;; ES:BX = mode table
@vloopj:	mov		ax,es:[bx]		;; Get Vesa mode from table
		cmp		ax,-1			;; end of mode list
		jz		@eloopj
		cmp		ax,word ptr VesaModes[si+2]	;; compare if mode is in VesaModes
		jz		@eloopi
		add		bx,2
		jmp		short @vloopj
@eloopj:	mov		word ptr VesaModes[si],0	;; Clear Vesa mode
		mov		word ptr VesaModes[si+2],0
@eloopi:	add		si,4
		cmp		si,VESAMODESIZE
		jl		@vloopi
	;; Only supported VESA modes should be in the VesaMode entry table
		or		byte ptr [cardFlags], HAVE_VESA
	ENDIF
@notVesa:	pop		si
		ret
$vesa_Dtct	endp

;;===================================================================
;; Detect Chips&Tech
;;===================================================================
$chips_Dtct	proc		near
		mov		ax, 05f00h
		int		010h
		cmp		al, 05fh
		jne		notchipstech
	;; Found a Chips&Technologies card
		mov		word ptr [svga_IOAdr], 03d6h
		SetCardType	Chips
		SetPageType	chips
	;; Set default to C&T 451 chipset
		SetChipType	chips451
		shr		bl,2
		cmp		bl,1
		jz		@chips452
		cmp		bl,3
		jnz		not_chips453
	;; Found a C&T 453 chip
		SetChipType	chips453
		ret
	;; Found a C&T 452 chip
@chips452:	SetChipType	chips452
not_chips453:
notchipstech:	ret
$chips_Dtct	endp

;;===================================================================
;; Detect Paradise
;;===================================================================
$paradise_Dtct	proc		near
		rdinx		GC_INDEX, 0fh
		mov		[svga_Oldreg], al
	;; Lock registers
		modinx		dx, 0fh, 017h, 0
		testinx2	dx, 9, 07fh
		jz		notParadise
	;; Unlock registers
		wrinx		dx, 0fh, 05
		testinx2	dx, 9, 07fh
		jnz		notParadise
	;; Found a Paradise card
		SetCardType	Paradise
		SetChipType	paradise
		SetPageType	paradise
	;; Restore register value
notParadise:	wrinx		dx, 0fh, [svga_Oldreg]
		ret
$paradise_Dtct	endp

;;===================================================================
;; Detect Compaq
;;===================================================================
$compaq_Dtct	proc		near
		rdinx		GC_INDEX, 0Fh
		mov		[svga_OldReg], al
	;; Disable extensions
		wrinx		dx, 0Fh, 0
		testinx2	dx, 045h, 0FFh
		jz		@notCompaq
	;; Enable extensions
		wrinx		dx, 0Fh, 5
		testinx2	dx, 045h, 0ffh
		jnz		@notCompaq
	;; Found a Compaq card
		SetCardType	Compaq
		SetChipType	compaq
		SetPageType	compaq
	;; Restore register value
@notCompaq:	wrinx		dx, 0Fh, [svga_Oldreg]
		ret
$compaq_Dtct	endp

;;===================================================================
;; Detect Video7
;;===================================================================
$video7_Dtct	proc		near
		mov		ax, 06f00h
		int		010h
		cmp		bx, 05637h
		jnz		notvideo7
	;; Found a Video7 card
		SetCardType	Video7
		SetChipType	video7
		SetPageType	video7
notvideo7:	ret
$video7_Dtct	endp

;;===================================================================
;; Detect Genoa
;;===================================================================
$genoa_Dtct	proc		near
	IF	BGIVERSION GE 3
		mov		ax,SEGC000
	ELSE
		mov		ax,0c000h
	ENDIF
		mov		es,ax
		mov		bx,es:[037h]
		cmp		word ptr es:[bx+2h],6699h
		jnz		notgenoa
		cmp		byte ptr es:[bx],077h
		jnz		notgenoa
	;; Found a Genoa card
		SetCardType	Genoa
		SetChipType	genoa
		cmp		byte ptr es:[bx+1],033h
		jl		gen5
		SetChipType	tseng3
gen5:
notgenoa:	ret
$genoa_Dtct	endp

;;===================================================================
;; Detect Everex
;;===================================================================
$everex_Dtct	proc	near
		xor		bx,bx
		mov		ax,07000h
		int		010h
		cmp		al,070h
		jnz		noteverex
	;; Found an Everex card
		and		dx,0fff0h
		SetCardType	Everex
		cmp		dx,06780h
		jz		evxtri
		cmp		dx,02360h
		jz		evxtri
		cmp		dx,06200h
		jz		evxtri
		cmp		dx,06730h
		jz		evxtri
		cmp		dx,06330h
		jz		evxtsg
	;; Everex using the Everex chipset
		SetChipType	everex
		ret
	;; Everex using the Tseng ET4000 chipset
evxtsg:		SetChipType	tseng4
		SetPageType	tseng4
		ret
	;; Everex using the Trident 8800 chipset
evxtri:		SetCardType	Trident88
		SetChipType	trident
		SetPageType	tri88
noteverex:	ret
$everex_Dtct	endp

;;===================================================================
;; Detect Trident
;;===================================================================
$trident_Dtct	proc	near
		push		cx
	;; Force old definitions
		wrinx		SC_INDEX,0bh,0
	;; Read Chip ID register
		inp		SC_INDEX+1
		mov		cl,al				;; Subvers
		rdinx		SC_INDEX,0Eh
		mov		ch,al				;; old
		outp		SC_INDEX+1,0
		inp		dx
		mov		ah,al				;; val
		mov		al,ch
		out		dx,al
		and		ah,0fh
		cmp		ah,2
		jnz		@notTrident
	;; Found a Trident card
		xor		ch,2
		outp		03c5h, ch

		cmp		cl,2
		jnz		@notIITAGX
		tstreg		2168h,0fh
		jnz		@notIITAGX
	;; Found a IITAGX board
		SetCardType	IITAGx
		SetChipType	iitagx
		SetPageType	iitagx
		pop		cx
		ret

	;; Regular 8800/8900
@notIITAGX:	SetChipType	trident
		and		cl,0fh
		cmp		cl,2
		jz		isTri88
	;; Found a Trident 8900+
		SetCardType	Trident89
		SetPageType	tri89
		pop		cx
		ret
	;; Found a Trident 8800
isTri88:	SetCardType	Trident88
		SetPageType	tri88
@notTrident:	pop		cx
		ret
$trident_Dtct	endp

;;===================================================================
;; Detect ATI
;;===================================================================
$ati_Dtct	proc	near
	IF	BGIVERSION GE 3
		mov		ax,SEGC000
	ELSE
		mov		ax,0c000h
	ENDIF
		mov		es,ax
		cmp		word ptr es:[40h],'13'
		jnz		notATI
		mov		ax,es:[010h]
		mov		[svga_IOAdr],ax
	;; Default to ATI type 2 chipset
		SetCardType	ATI
		SetChipType	ati2
		SetPageType	ati2
		cmp		byte ptr es:[43h], 31h
		jz		@ati1
		cmp		byte ptr es:[43h], 061h
		jz		@atiGUP
		cmp		byte ptr es:[43h], 063h
		jz		@atiGUP			;; Ultra Pro II
		jmp		short @endATI
	;; Found ATI rev 1 chipset
@ati1:		SetChipType	ati1
		SetPageType	ati1
		jmp		short @endATI
	;; Found a Graphics Ultra Pro
@atiGUP:	SetCardType	ATIGUP
		SetChipType	atiGUP
@endATI:
notATI:		ret
$ati_Dtct	endp

;;===================================================================
;; Detect Ahead A/B
;;===================================================================
$ahead_Dtct	proc	near
		rdinx		GC_INDEX,0fh
		mov		[svga_Oldreg],al
	;; Disable extended registers
		wrinx		dx, 0fh, 0
		testinx2	dx, 0dh, 0ffh
		jz		notahead
	;; Enable extended registers
		wrinx		dx, 0fh, 020h
		testinx2	dx, 0dh, 0ffh
		jnz		notahead
	;; Found an Ahead chipset
		SetCardType	Ahead
	;; Default to Ahead A chipset
		SetChipType	aheada
		rdinx		dx, 0fh
		and		al, 0fh
		or		al, al
		jz		endahead
	;; Found an Ahead B chipset
		SetChipType	aheadb
		SetPageType	aheadb
endahead:	
notahead:	wrinx		dx, 0fh, [svga_Oldreg]
		ret
$ahead_Dtct	endp

;;===================================================================
;; Detect NCR
;;===================================================================
$ncr_Dtct	proc		near
		testinx2 	SC_INDEX, 5, 5
		jnz		@notNCR
	;; disable extended registers
		wrinx		dx, 5, 0
		testinx2	dx, 010h, 0ffh
		jz		@notNCR
	;; enable extended registers
		wrinx		dx, 5, 1
		testinx2	dx, 010h, 0ffh
		jnz		@notNCR
	;; Found the NCR chipset
		SetCardType	NCR
		SetChipType	ncr
		SetPageType	ncr
@notNCR:	ret
$ncr_Dtct	endp

;;===================================================================
;; Detect S3
;;===================================================================
$s3_Dtct	proc		near
	;; Lock extended registers
		wrinx		CRTC_INDEX, 038h, 0
		testinx2	dx, 035h, 0fh
		jz		nots3
	;; Unlock extended registers
		wrinx		dx, 038h, 048h
		testinx2	dx, 035h, 0fh
		jnz		nots3
	;; Found a S3 card
		SetCardType	S3
		SetChipType	s3
		SetPageType	s3
	IF	BGIVERSION GE 1
	;; Fix bytes per line for 800x600x256 mode
		SetBytesPerLine	256, 3, 1024
		or		byte ptr [cardFlags], SLOW_LOGICAL
	ENDIF
nots3:		ret
$s3_Dtct	endp

;;===================================================================
;; Detect Avance Logic AL2101
;;===================================================================
$avance_Dtct	proc	near
	;; Check Start Pixel Low register
		tstreg		08286h,0ffh
		jnz		notal2101
	;; Check for Emulation register
		testinx2	CRTC_INDEX,01fh,03bh
		jnz		notal2101
	;; Test for Fill Color register
		testinx2	GC_INDEX,0dh,0dh
		jnz		notal2101
	;; Found an AL2101 card
		SetCardType	AL2101
		SetChipType	al2101
		SetPageType	al2101
notal2101:	ret
$avance_Dtct	endp

;;===================================================================
;; Detect MX68010
;;===================================================================
$mxic_Dtct	proc		near
	;; Save register
		rdinx		SC_INDEX, 0a7h
		mov		[svga_Oldreg], al
	;; Disable extended registers
		wrinx		dx, 0a7h, 0
		testinx2	dx, 0c5h, 0ffh
		jz		notmxic
	;; Enable extended registers
		wrinx		dx, 0a7h, 087h
		jnz		notmxic
	;; Found an MXIC 68000 card
		SetCardType	MXIC
		SetChipType	mxic
		SetPageType	mxic
	;; Restore register value
notmxic:	wrinx		dx, 0a7h, [svga_Oldreg]
		ret
$mxic_Dtct	endp

;;===================================================================
;; Detect Cirrus 54xx
;;===================================================================
$cirrus54_Dtct	proc		near
		rdinx		SC_INDEX, 6
		mov		[svga_Oldreg], al
	;; Disable extended registers
		wrinx		dx, 06, 0h
		rdinx		dx, 6
		cmp		al, 0Fh
		jnz		@notCirrus54
	;; Enable extended registers
		wrinx		dx, 06h, 12h
		rdinx		dx, 06h
		cmp		al, 012h
		jnz		@notCirrus54
		testinx2	dx, 01Eh, 03Fh
		jnz		@notCirrus54
	;; Found a Cirrus 54xx card
		SetCardType	Cirrus54
		SetChipType	cirrus54
		SetPageType	cirrus54
	IF	BGIVERSION GE 1
;;		SetBytesPerLine	16, 6, 2048/8
		SetBytesPerLine 16777, 3, 2048
	ENDIF
		ret
	;; Restore register value
@notCirrus54:	wrinx		dx, 6, [svga_Oldreg]
		ret
$cirrus54_Dtct	endp

;;===================================================================
;; Detect Cirrus 64xx
;;===================================================================
$cirrus64_Dtct	proc		near
		rdinx		GC_INDEX,0Ah
		mov		[svga_Oldreg], al
	;; Lock extended registers
		wrinx		dx, 0Ah, 0CEh
		rdinx		dx, 0Ah
		or		al,al
		jnz		@notCirrus64
	;; Unlock registers
		wrinx		dx, 0Ah, 0ECh
		rdinx		dx, 0Ah
		cmp		al,1
		jnz		@notCirrus64
	;; Found a Cirrus 64xx card
		SetCardType	Cirrus64
		SetChipType	cirrus64
		SetPageType	cirrus64
	;; Restore register value
@notCirrus64:	wrinx		dx, 0Ah, [svga_Oldreg]
		ret
$cirrus64_Dtct	endp

;;===================================================================
;; Detect Cirrus 5x0/6x0
;;===================================================================
$cirrus_Dtct	proc		near
		push		cx
		rdinx		SC_INDEX, 06h
		mov		cl, al
		rdinx		CRTC_INDEX, 0Ch
		mov		[svga_Oldreg], al
		outp		CRTC_INDEX+1, 0
	;; Read subversion register
		rdinx		CRTC_INDEX, 01Fh
		mov		ch, al
		rol		al,4
		wrinx		SC_INDEX, 6, al
		inp		SC_INDEX+1
		or		al,al
		jnz		@notCirrus

		outp		03C5h, ch
		inp		03C5h
		cmp		al, 1
		jnz		@notCirrus

	;; Found a Cirrus card
		SetCardType	Cirrus
	;; Restore register value
@notCirrus:	wrinx		CRTC_INDEX, 0Ch, [svga_Oldreg]
		wrinx		SC_INDEX, 06h, cl
		pop		cx
		ret
$cirrus_Dtct	endp

;;===================================================================
;; Detect Acumos
;;===================================================================
$acumos_Dtct	proc		near
		rdinx		SC_INDEX, 6
		mov		[svga_Oldreg], al
	;; Enable extended registers
		wrinx		dx,6,12h
		testinx2	GC_INDEX, 9, 30h
		jnz		notacumos
	;; Found an Acumos card
		SetCardType	Acumos
		SetChipType	acumos
	;; Restore register value
notacumos:	wrinx		SC_INDEX,6,[svga_Oldreg]
		ret
$acumos_Dtct	endp

;;===================================================================
;; Detect HMC
;;===================================================================
$hmc_Dtct	proc		near
		testinx2	SC_INDEX, 0E7h, 0FFh
		jnz		@notHMC
		testinx2	dx, 0EEh, 0FFh
		jnz		@notHMC
	;; Found a HMC card
		SetCardType	HMC
		SetChipType	hmc
		SetPageType	hmc
@notHMC:	ret
$hmc_Dtct	endp

;;===================================================================
;; Detect UMC
;;===================================================================
$umc_Dtct	proc		near
	;; Save register value
		inp		03bfh
		mov		[svga_Oldreg], al
	;; Disable extensions
		outp		dx, 03h
		testinx2	SC_INDEX, 6, 0FFh
		jz		@notUMC
	;; Enable extensions
		outp		03bfh, 0ACh
		testinx2	SC_INDEX, 6, 0FFh
		jnz		@notUMC
	;; Found a UMC card
		SetCardType	UMC
		SetChipType	umc
	;; Restore register value
@notUMC:	outp		03bfh, [svga_Oldreg]
		ret
$umc_Dtct	endp

;;===================================================================
;; Detect Tseng
;;===================================================================
$tseng_Dtct	proc		near
		outp		03bfh, 3
		outp		CRTC_INDEX+4, 0a0h
		tstreg		03cdh,03fh
		jnz		@notTseng
	;; Found a Tseng - default to ET3000
		SetCardType	Tseng30
		SetChipType	tseng3
		SetPageType	tseng3
	;; Test for ET3000/ET4000
		testinx2	CRTC_INDEX, 033h, 0Fh
		jnz		@endTseng
	;; Test for ET4000/ET4000W32
		tstreg		03CBh, 033h
		jnz		@notW32
	;; Found an ET4000/W32
		SetCardType	TsengW32
		SetChipType	tseng4_w32
		SetPageType	tsengW32
		jmp		short @endTseng
	;; Found a Tseng ET4000 chipset
@notW32:	SetCardType	Tseng40
		SetChipType	tseng4
		SetPageType	tseng4
@endTseng:
@notTseng:	ret
$tseng_Dtct	endp

;;===================================================================
;; Detect Realtek RT3106
;;===================================================================
$realtek_Dtct	proc		near
 	;; Test scratch register
		testinx2	CRTC_INDEX, 01fh, 03h
		jnz		notrealtek
	;; Test bank switch register
		tstreg		03d6h,0fh
		jnz		notrealtek
	;; Test bank switch register
		tstreg		03d7h,0fh
		jnz		notrealtek
	;; Found a Realtek card
		SetCardType	RealTek
		SetChipType	realtek
notrealtek:	ret
$realtek_Dtct	endp

;;===================================================================
;; Detect P2000
;;===================================================================
$p2000_Dtct	proc		near
		testinx2	GC_INDEX,03dh,03fh
		jnz		notp2000
		tstreg		03d6h,01fh
		jnz		notp2000
		tstreg		03d7h,01fh
		jnz		notp2000
	;; Found a Primus 2000
		SetCardType	P2000
		SetChipType	p2000
		SetPageType	p2000
notP2000:	ret
$p2000_Dtct	endp

;;===================================================================
;; Detect Weitek
;;===================================================================
$weitek_Dtct	proc		near
	;; Save register value
		rdinx		SC_INDEX,011h
		mov		[svga_Oldreg],al
	;; Lock registers
		outp		SC_INDEX+1,[svga_Oldreg]
		outp		dx,[svga_Oldreg]
		inp		dx
		or		al,020h
		outp		dx,al
		testinx2	SC_INDEX,012h,0FFh
		jz		@notWeitek
	;; Unlock registers
		rdinx		dx,011h
		outp		SC_INDEX+1,[svga_Oldreg]
		outp		dx,[svga_Oldreg]
		inp		dx
		and		al,0DFh
		outp		dx,al
		testinx2	SC_INDEX,012h,0FFh
		jnz		@notWeitek
		tstreg		03CDh,0FFh
		jnz		@notWeitek
	;; Found a Weitek chipset
		SetCardType	Weitek
		SetChipType	weitek
		SetPageType	weitek
	;; Restore register value
@notWeitek:	wrinx		SC_INDEX,011h,[svga_Oldreg]
		ret
$weitek_Dtct	endp

;;===================================================================
;; Detect Oak
;;===================================================================
$oak_Dtct	proc		near
		testinx2	03deh, 0dh, 038h
		jnz		@notOak
		testinx2	dx, 023h, 01fh
		jnz		@notOak87
	;; Found an Oak 083/087 card
		SetCardType	Oak77
		SetChipType	oak87
		ret
	;; Found an Oak 067/077 card
@notOak87:	SetCardType	Oak77
		SetChipType	oak77
@notOak77:
@notOak:	ret
$oak_Dtct	endp

;; RETURNS: zf=0: failed to detect port (jnz to exit)
;;          zf=1: detected port		(jz  to code)
TestPort	proc	near
		push	cx
		in	al,dx
		mov	cl,al		;; old = inp(port);
		mov	bh,bl
		not	bh
		and	al,bh
		out	dx,al		;; outp(port,old & ~mask);
		in	al,dx
		and	al,bl		;; new1 = inp(port) & mask
		jnz	@@NoPort
		mov	al,cl
		or	al,bl
		out	dx,al		;; outp(port,old | mask);
		in	al,dx
		and	al,bl		;; new2 = inp(port) & mask;
		cmp	al,bl		;; result=(0==new1 && new2==mask);
@@NoPort:	mov	al,cl
		out	dx,al		;; outp(port,old);
		pop	cx
		ret
TestPort	endp

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
