;; S3 port numbers
FRGD_MIX		EQU	0bae8h
FRGD_COLOR		EQU	0a6e8h
MULTIFUNC_CNTL		EQU	0bee8h
CUR_Y			EQU	082e8h
CUR_X			EQU	086e8h
MAJ_AXIS		EQU	096e8h
DIAGX_STEP		EQU	08ee8h
DIAGY_STEP		EQU	08ae8h
ERR_TERM		EQU	092e8h
CMD			EQU	09ae8h
CMD_REG			EQU	09ae8h
GP_STAT			EQU	09ae8h
CURWIDTH		EQU	096e8h
CURHEIGHT		EQU	0bee0h
WRT_MASK		EQU	0aae8h
BKGD_COLOR		EQU	0a2e8h
BKGD_MIX		EQU	0b6e8h
DESTY_AXSTP		EQU	08ae8h
DESTX_DIASTP		EQU	08ee8h
ERR_TERM		EQU	092e8h
MAJ_AXIS_PCNT		EQU	096e8h
PIX_TRANS		EQU	0e2e8h
COLOR_CMP		EQU	0b2e8h

DataReady		EQU	0100h
OneEmpty		EQU	080h
TwoEmpty		EQU	040h
ThreeEmpty		EQU	020h
FourEmpty		EQU	010h
FiveEmpty		EQU	008h
SixEmpty		EQU	004h
SevenEmpty		EQU	002h
EightEmpty		EQU	001h
CmdRect			EQU	04000h
CmdLine			EQU	02000h
ByteSwap		EQU	01000h
BusSize			EQU	0200h
Xmajor			EQU	0h
YMajor			EQU	40h
XPositive		EQU	20h
YPositive		EQU	80h
XNegative		EQU	0h
YNegative		EQU	0h
LPelOff			EQU	4
LPelOn			EQU	0
MultiPel		EQU	2
SinglePel		EQU	0
WriteOp			EQU	1
ReadOp			EQU	0
DrawTo			EQU	10h
Pel_Cntl		EQU	0a000h
DE_Ones			EQU	0
DE_PelPos		EQU	040h
DE_CPU			EQU	080h
DE_DISPLAY		EQU	0c0h
WaitCpu			EQU	0100h

Wait_Till_Fifo MACRO	__nempty
	LOCAL	LL1
	mov	dx,GP_STAT
LL1:	in	ax,dx
	test	ax,__nempty
	jne	LL1
ENDM

Wait_For_Data	MACRO
	LOCAL	LL1
	mov	dx,GP_STAT
LL1:	in	ax,dx
	test	ax,DataReady
	je	LL1
ENDM
	
OutCMD	MACRO	__val
	IFNB	<__val>
	mov	ax,__val
	ENDIF
	mov	dx,CMD_REG
	out	dx,ax
	ENDM
