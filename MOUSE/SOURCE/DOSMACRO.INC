;; DOS Assembly Macros include file 
;;
;; Version: 	$Revision
;;
;; Copyright (c) 1994, Jordan Hargrave <jordan_hargrave@hotmail.com>
;; All Rights Reserved
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
;;  $Log:   C:/svga/mousesrc/rcs/dosmacro.inv  $
;;
;;   Rev 1.1   15 Aug 1994 23:03:24   JORDAN
;;   
;;    Rev 1.0   15 Aug 1994 22:59:36   JORDAN
;; Initial revision.
;;

;;===================================================================
;; Opens a file
;; int _open(char *filename, int mode);
;;
;; Input:
;;    __filename = ASCIIZ filename
;;    __mode     = R/W mode for opening file
;;===================================================================
_O_READ		EQU	0
_O_WRITE	EQU	1
_O_RDWR		EQU	2
OpenFile	MACRO	__filename, __mode
		push	dx
		push	ds
		mov	ax, cs
		mov	ds, ax
		mov	ah, 03Dh
		mov	al, __mode
		lea	dx, __filename
		int	021h
		pop	ds
		pop	dx
ENDM

;;===================================================================
;; int _creat(char *filename, int mode);
;; Creates a file
;;
;; Input:
;;    __filename = ASCIIZ filename
;;    __attrib   = Attribute of file
;;===================================================================
CreateFile	MACRO	__filename, __attrib
		push	dx
		push	ds
		mov	ax, cs
		mov	ds, ax
		mov	ah, 03Ch
		mov	cx, __attrib
		lea	dx, __filename
		int	021h
		pop	ds
		pop	dx
ENDM

;;===================================================================
;; int _close(int);
;; Closes a file
;;
;; Input:
;;    __fd = File descriptor
;;===================================================================
CloseFile	MACRO	__fd
		push	bx
		mov	ah, 03eh
		mov	bx, __fd
		int	021h
		pop	bx
ENDM

;;===================================================================
;; long _lseek(int, long, int);
;; Seeks in a file
;; 
;; Input:
;;    __fd     = File descriptor
;;    __hi     = Upper 16 bits of offset
;;    __lo     = Lower 16 bits of offset
;;    __origin = Start location of seek
;;===================================================================
_SEEK_SET	EQU	0
_SEEK_CUR	EQU	1
_SEEK_END	EQU	2
SeekFile	MACRO	__fd, __hi, __lo, __origin
		push	bx
		push	cx
		push	dx
		mov	ah, 042h
		mov	al, __origin
		mov	bx, __fd
		mov	cx, __hi
		mov	dx, __lo
		int	021h
		pop	dx
		pop	cx
		pop	bx
ENDM

;;===================================================================
;; int _read(int, char *, int);
;; reads to a file
;;
;; Input:
;;    __fd     = File descriptor
;;    __bseg   = segment of buffer
;;    __boff   = offset of buffer
;;    __nread = number of bytes to read
;;===================================================================
ReadFile	MACRO	__fd, __bseg, __boff, __nread
		push	bx
		push	cx
		push	dx
		push	ds
		mov	ax, __bseg
		mov	ds, ax
		mov	ah, 03Fh
		mov	bx, __fd
		mov	dx, __boff
		mov	cx, __nread
		int	021h
		pop	ds
		pop	dx
		pop	cx
		pop	bx
ENDM

;;===================================================================
;; int _write(int, char *, int);
;; Writes to a file
;;
;; Input:
;;    __fd     = File descriptor
;;    __bseg   = segment of buffer
;;    __boff   = offset of buffer
;;    __nwrite = number of bytes to write
;;===================================================================
WriteFile	MACRO	__fd, __bseg, __boff, __nwrite
		push	bx
		push	cx
		push	dx
		push	ds
		mov	ax, __bseg
		mov	ds, ax
		mov	ah, 040h
		mov	bx, __fd
		mov	dx, __boff
		mov	cx, __nwrite
		int	021h
		pop	ds
		pop	dx
		pop	cx
		pop	bx
ENDM

;;===================================================================
;; Prints a string
;; Input:
;;    __msg = Offset of the string
;;===================================================================
Print		MACRO	__msg
		lea	dx, __msg
		mov	ah, 9
		int	021h
ENDM

;;===================================================================
;; Print a string pointer
;; Input:
;;    __msgMem = Pointer to the string
;;===================================================================
PrintIndex	MACRO	__msgMem
		mov	dx, [__msgMem]
		mov	ah, 9
		int	021h
ENDM

;;===================================================================
;; Get interrupt vector
;; Input:
;;    __vectNum = vector number
;; Returns:
;;    ES:BX = offset of interrupt handler
;;===================================================================
GetIntVect	MACRO		__vectNum
		mov		ax, 3500h OR __vectNum
		int		021h
ENDM

;;===================================================================
;; Set interrupt vector
;; Input:
;;    __vectNum = vector number
;;    __seg = segment of handler, OR dword memory location
;;    __ofs = offset of handler , OR null
;;===================================================================
SetIntVect	MACRO		__vectNum, __seg, __ofs
		push		ds
	IFNB	<__ofs>
		mov		ax, __seg
		mov		ds, ax
		lea		dx, __ofs
	ELSE
		mov		dx, word ptr __seg
		mov		ds, word ptr __seg+2
	ENDIF
		mov		ax, 2500h OR __vectNum
		int		021h
		pop		ds
ENDM
