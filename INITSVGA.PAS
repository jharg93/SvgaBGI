{ Sample program that initializes the SuperVGA driver}
Program Test256;

Uses Graph,Crt,Dos;

{$i svga16.inc}
{$i svga256.inc}
{$i svga32k.inc}
{$i svga64k.inc}
{$i svgatc.inc}
{$i svgas3.inc}
{$i twk16.inc}
{$i twk256.inc}
{$i svgautil.inc}

(* Uncomment this if you link in the drivers *)
(*
procedure Svga16_driver; external;
{ $L svga16.obj }

procedure Svga256_driver; external;
{ $L svga256.obj }

procedure Twk256_driver; external;
{ $L twk256.obj }

procedure Twk16_driver; external;
{ $L twk16.obj }

procedure Svga32k_driver; external;
{ $L svga32k.obj }

procedure Svga64k_driver; external;
{ $L svga64k.obj }

procedure SvgaTC_driver; external;
{ $L svgatc.obj }

procedure SvgaS3_driver; external;
{ $L svgas3.obj }
*)

var
  GraphMode, GraphDriver, GrErr : integer;
  Ky : Char;
  Drv : Integer;

function WhitePixel : Word;
begin
  if (GetMaxColor > 256) then
    WhitePixel := 32767
  else
    WhitePixel := 15;
end;

{$F+}
function DetectVGA256 : Integer;
var Vid : Integer;

begin
  Writeln('Which video mode would you like to use?');
  Writeln('  0) 320x200x256');
  Writeln('  1) 640x400x256');
  Writeln('  2) 640x480x256');
  Writeln('  3) 800x600x256');
  Writeln('  4) 1024x768x256');
  Writeln('  5) 640x350x256');
  Writeln('  6) 1280x1024x256');
  Write('> ');
  Readln(Vid);
  DetectVGA256 := Vid;
end;

function DetectS3 : Integer;
var Vid : Integer;

begin
  Writeln('Which video mode would you like to use?');
  Writeln('  0) 640x480x256');
  Writeln('  1) 800x600x256');
  Writeln('  2) 1024x768x256');
  Writeln('  3) 800x600x16');
  Writeln('  4) 1024x768x16');
  Writeln('  5) 1280x960x16');
  Writeln('  6) 1280x1024x16');
  Writeln('  7) 640x480x32768');
  Write('> ');
  Readln(Vid);
  DetectS3 := Vid;
end;

function DetectVGATC : Integer;
var Vid : Integer;

begin
  Writeln('Which video mode would you like to use?');
  Writeln('  0) 320x200x24-bit');
  Writeln('  1) 640x350x24-bit');
  Writeln('  2) 640x400x24-bit');
  Writeln('  3) 640x480x24-bit');
  Writeln('  4) 800x600x24-bit');
  Writeln('  5) 1024x768x24-bit');
  Writeln('  6) 1280x1024x24-bit');
  Write('> ');
  Readln(Vid);
  DetectVGATC := Vid;
end;

function DetectVGA64k : Integer;
var Vid : Integer;

begin
  Writeln('Which video mode would you like to use?');
  Writeln('  0) 320x200x65536');
  Writeln('  1) 640x350x65536');
  Writeln('  2) 640x400x65536');
  Writeln('  3) 640x480x65536');
  Writeln('  4) 800x600x65536');
  Writeln('  5) 1024x768x65536');
  Writeln('  6) 1280x1024x65536');
  Write('> ');
  Readln(Vid);
  DetectVGA64k := Vid;
end;

function DetectVGA32k : Integer;
var Vid : Integer;

begin
  Writeln('Which video mode would you like to use?');
  Writeln('  0) 320x200x32768');
  Writeln('  1) 640x350x32768');
  Writeln('  2) 640x400x32768');
  Writeln('  3) 640x480x32768');
  Writeln('  4) 800x600x32768');
  Writeln('  5) 1024x768x32768');
  Writeln('  6) 1280x1024x32768');
  Write('> ');
  Readln(Vid);
  DetectVGA32k := Vid;
end;

function DetectVGA16 : Integer;
var Vid : Integer;

begin
  Writeln('Which video mode would you like to use? ');
  Writeln('  0) 320x200x16');
  Writeln('  1) 640x200x16');
  Writeln('  2) 640x350x16');
  Writeln('  3) 640x480x256');
  Writeln('  4) 800x600x16');
  Writeln('  5) 1024x768x16');
  Writeln('  6) 1280x1024x16');
  Writeln('>');
  Readln(Vid);
  DetectVGA16 := Vid;
end;

function DetectTwk256 : Integer;
var Vid : Integer;

begin
  Writeln('Which video mode would you like to use?');
  Writeln('  0) 320x400x256');
  Writeln('  1) 320x480x256');
  Writeln('  2) 360x480x256');
  Writeln('  3) 376x564x256');
  Writeln('  4) 400x564x256');
  Writeln('  5) 400x600x256');
  Writeln('  6) 320x240x256');
  Write('> ');
  Readln(Vid);
  DetectTwk256 := Vid;
end;

function DetectTwk16 : Integer;
var Vid : Integer;

begin
  Writeln('Which video mode would you like to use? ');
  Writeln('  0) 704x528x16');
  Writeln('  1) 720x540x16');
  Writeln('  2) 736x552x16');
  Writeln('  3) 752x564x256');
  Writeln('  4) 768x576x16');
  Writeln('  5) 784x588x16');
  Writeln('  6) 800x600x16');
  Writeln('>');
  Readln(Vid);
  DetectTwk16 := Vid;
end;
{$F-}
 
begin
  Writeln('Which driver would you like to use?');
  Writeln('  0) Svga16');
  Writeln('  1) Svga256');
  Writeln('  2) Svga32k');
  Writeln('  3) Svga64k');
  Writeln('  4) SvgaTC');
  Writeln('  5) SvgaS3');
  Writeln('  6) Tweak256');
  Writeln('  7) Tweak16');
  Write('>');
  Readln(Drv);
  if (Drv = 0) then
    GraphDriver := InstallUserDriver('SVGA16',@DetectVGA16)
  else if (Drv = 1) then
    GraphDriver := InstallUserDriver('SVGA256',@DetectVGA256)
  else if (Drv = 2) then
    GraphDriver := InstallUserDriver('Svga32k',@DetectVGA32k)
  else if (Drv = 3) then
    GraphDriver := InstallUserDriver('Svga64k',@DetectVGA64k)
  else if (Drv = 4) then
    GraphDriver := InstallUserDriver('SvgaTC',@DetectVGATC)
  else if (Drv = 5) then
    GraphDriver := InstallUserDriver('SvgaS3',@DetectS3)
  else if (Drv = 6) then
    GraphDriver := InstallUserDriver('Twk256',@DetectTwk256)
  else if (Drv = 7) then
    GraphDriver := InstallUserDriver('Twk16',@DetectTwk16);
  GraphDriver := Detect;
  InitGraph(GraphDriver,GraphMode,'');
  GrErr := GraphResult;             { preserve error return }
  if GrErr AND $80 = $80 then
     GrErr := GrErr OR $ff00;
  if GrErr <> grOK then             { error? }
  begin
    Writeln('Graphics error: ', GraphErrorMsg(GrErr));
    Halt(1);
  end;

  setcolor(RealDrawColor(WhitePixel));
  line(0,0,GetMaxX,GetMaxY);
  line(0,GetMaxY,GetMaxX,0);
  Ky := ReadKey;
  CloseGraph;
end.
