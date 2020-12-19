const
  XNOR_PUT		= 5;
  NOR_PUT		= 6;
  NAND_PUT		= 7;
  TRANS_COPY_PUT	= 8;	(* Doesn't work on 16-color systems *)

type DacPalette16  = array[0..15] of array[0..2] of Byte;
type DacPalette256 = array[0..255] of array[0..2] of Byte;

(* Setvgapalette sets the entire 16 color palette *)
(* PalBuf contains RGB values for all 16 colors   *)
(* R,G,B values range from 0 to 63	           *)
procedure SetVGAPalette16(PalBuf : DacPalette16);
var
  Reg : Registers;

begin
  reg.ax := $1012;
  reg.bx := 0;
  reg.cx := 16;
  reg.es := Seg(PalBuf);
  reg.dx := Ofs(PalBuf);
  intr($10,reg);
end;

(* Setvgapalette sets the entire 256 color palette *)
(* PalBuf contains RGB values for all 256 colors   *)
(* R,G,B values range from 0 to 63	           *)
procedure SetVGAPalette256(PalBuf : DacPalette256);
var
  Reg : Registers;

begin
  reg.ax := $1012;
  reg.bx := 0;
  reg.cx := 256;
  reg.es := Seg(PalBuf);
  reg.dx := Ofs(PalBuf);
  intr($10,reg);
end;

function RGB(R,G,B : LongInt) : LongInt;
var
  MaxC : Longint;
begin
  MaxC := GetMaxColor;

  if (MaxC = 65535) then
    RGB := (((R SHR 3) AND $1F) SHL 11) OR (((G SHR 2) AND $3F) SHL 5) OR
	    ((B SHR 3) AND $1F)
  else if (MaxC = 32767) then
    RGB := (((R SHR 3) AND $1F) SHL 10) OR (((G SHR 3) AND $1F) SHL 5) OR 
	    ((B SHR 3) and $1F)
  else if (MaxC = 16777) then
    RGB := ((R AND $FF) SHL 16) OR ((G AND $FF) SHL 8) OR (B AND $FF);
end;

function RealDrawColor(Color : LongInt) : LongInt;
var
  MaxC : Longint;
begin
  MaxC := GetMaxColor;

  if (MaxC = 65535) then
    SetRgbPalette(1024,(Color SHR 11) AND $1F,(Color SHR 5)AND $3F,Color AND $1F)
  else if (MaxC = 32767) then
    SetRgbPalette(1024,(Color SHR 10) AND $1F,(Color SHR 5)AND $1F,Color AND $1F)
  else if (MaxC = 16777) then
    SetRgbPalette(1024,(Color SHR 16) AND 255,(Color SHR 8)AND 255,Color AND 255);
  RealDrawColor := Color;
end;

function RealFillColor(Color : LongInt) : LongInt;
var
  MaxC : Longint;
begin
  MaxC := GetMaxColor;

  if (MaxC = 65535) then
    SetRgbPalette(1025,(Color SHR 11) AND $1F,(Color SHR 5)AND $3F,Color AND $1F)
  else if (MaxC = 32767) then
    SetRgbPalette(1025,(Color SHR 10) AND $1F,(Color SHR 5)AND $1F,Color AND $1F)
  else if (MaxC = 16777) then
    SetRgbPalette(1025,(Color SHR 16) AND 255,(Color SHR 8)AND 255,Color AND 255);
  RealFillColor := Color;
end;

function RealColor(Color : LongInt) : LongInt;
var
  MaxC : Longint;
begin
  MaxC := GetMaxColor;

  if (MaxC = 65535) then
    SetRgbPalette(1026,(Color SHR 11) AND $1F,(Color SHR 5)AND $3F,Color AND $1F)
  else if (MaxC = 32767) then
    SetRgbPalette(1026,(Color SHR 10) AND $1F,(Color SHR 5)AND $1F,Color AND $1F)
  else if (MaxC = 16777) then
    SetRgbPalette(1026,(Color SHR 16) AND 255,(Color SHR 8)AND 255,Color AND 255);
  RealColor := Color;
end;
