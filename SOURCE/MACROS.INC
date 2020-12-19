ATTR_INDEX	EQU	03c0h
SC_INDEX	EQU	03c4h
GC_INDEX	EQU	03ceh
CRTC_INDEX	EQU	03d4h
MISC_OUTPUT	EQU	03c2h
MAP_MASK	EQU	2
READ_MAP	EQU	4

;; Outp(port,val) : Outputs a value to a port
outp		MACRO	__port, __val
	IFDIF	<__port>, <dx>
		lastPort = __port
		mov	dx,__port
	ENDIF
	IFDIF	<__val>,<al>
		mov	al,__val
	ENDIF
		out	dx,al
ENDM

outpwi		MACRO	__port, __val, __inx
	IFDIF	<__port>, <dx>
		lastPort = __port
		mov	dx,__port
	ENDIF
	IFDIF	<__inx>, <al>
		mov	al,__inx
	ENDIF
	IFDIF	<__val>, <ah>
		mov	ah,__val
	ENDIF
		out	dx,ax
ENDM

outpw		MACRO	__port, __val
	IFDIF	<__port>, <dx>
		lastPort = __port
		mov	dx, __port
	ENDIF
	IFDIF	<__val>,<ax>
		mov	ax, __val
	ENDIF
		out	dx, ax
ENDM

;; DX = Port
;; BH = Index
_wrinx		MACRO	__val
	IFIDN	<__val>, <al>
		.ERR
		%OUT	Can't have AL as argument to _wrinx
	ENDIF
		mov	al,bh			;; Port index
		out	dx,al
		inc	dx
		mov	al,__val
		out	dx,al
		dec	dx
ENDM

;; Wrinx(port,idx,val) : Writes a value to an indexed port
wrinx		MACRO	__port,__inx,__val
	IFDIF	<__port>, <dx>
		lastPort = __port
		mov	dx,__port
	ENDIF
	;;	mov	ax, ((__val AND 0FFh) SHL 8) OR __inx
	;;	out	dx,ax
	IFIDN	<__val>, <al>
		push	ax
	ENDIF
		mov	al,__inx
		out	dx,al
		inc	dx
	IFIDN	<__val>, <al>
		pop	ax
	ELSE
		mov	al,__val
	ENDIF
		out	dx,al
		dec	dx
ENDM

wrinx2m	MACRO	__port, __inx, __val
	wrinx	__port, __inx,   (__val shr 8) and 255
	wrinx	__port, __inx+1, (__val and 255)
ENDM

;; Inp(port) : Reads a value from a port
inp		MACRO	__port
	IFDIF	<__port>, <dx>
		lastPort = __port
		mov	dx,__port
	ENDIF
		in	al,dx
ENDM

_rdinx		MACRO
		mov	al,bh
		out	dx,al
		inc	dx
		in	al,dx
		dec	dx
ENDM

;; Rdinx(port,idx) : Reads a value from an indexed port
rdinx		MACRO	__port, __inx
	IFDIF	<__port>, <dx>
		lastPort = __port
		mov	dx,__port
	ENDIF
		mov	al,__inx
		out	dx,al
		inc	dx
		in	al,dx
		dec	dx
ENDM

clrinx		MACRO	__port, __inx, __val
		rdinx	__port, __inx
		and	al, (not __val) and 255
		wrinx	__port, __inx, al
ENDM

setinx		MACRO	__port,__inx,__nwv
		rdinx	__port,__inx
		or	al,__nwv
		wrinx	__port,__inx,al
ENDM

modinx		MACRO	__port,__inx,__mask,__nwv
	IFDIF	<__port>, <dx>
		lastPort = __port
		mov	dx,__port
	ENDIF
		push	ax
	;;	mov	ax, ((__nwv AND __mask) SHL 8) OR __inx)
		mov	ah, __nwv
		and	ah, __mask
		mov	al, __inx
		out	dx,al
		inc	dx
		in	al,dx
		and	al, (not __mask) and 255
		or	al,ah
		out	dx,al
		dec	dx
		pop	ax
ENDM

;; Test to see if an indexed port is active
TestInx2	MACRO	__port, __index, __mask
	IFDIF	<__port>,<dx>
		lastPort = __port
		mov	dx,__port
	ENDIF
		mov	bx, ((__index AND 0ffh) SHL 8) OR __mask
		call	TestIndex2
ENDM

;; Test to see if a register is active
tstreg		MACRO	__port,__mask
	IFDIF	<__port>,<dx>
		lastPort = __port
		mov	dx,__port
	ENDIF
		mov	bl,__mask
		call	TestPort
ENDM

