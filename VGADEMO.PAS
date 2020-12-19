program BGIDemo;
{

  Turbo Pascal Borland Graphics Interface (BGI) demonstration
  program. This program shows how to use many features of
  the Graph unit.

  Copyright (c) 1985-89 by Borland International, Inc.

}

uses
  Crt, Dos, Graph;


const
  { The five fonts available }
  Fonts : array[0..4] of string[13] =
  ('DefaultFont', 'TriplexFont', 'SmallFont', 'SansSerifFont', 'GothicFont');

  { The five predefined line styles supported }
  LineStyles : array[0..4] of string[9] =
  ('SolidLn', 'DottedLn', 'CenterLn', 'DashedLn', 'UserBitLn');

  { The twelve predefined fill styles supported }
  FillStyles : array[0..11] of string[14] =
  ('EmptyFill', 'SolidFill', 'LineFill', 'LtSlashFill', 'SlashFill',
   'BkSlashFill', 'LtBkSlashFill', 'HatchFill', 'XHatchFill',
   'InterleaveFill', 'WideDotFill', 'CloseDotFill');

  { The two text directions available }
  TextDirect : array[0..1] of string[8] = ('HorizDir', 'VertDir');

  { The Horizontal text justifications available }
  HorizJust  : array[0..2] of string[10] = ('LeftText', 'CenterText', 'RightText');

  { The vertical text justifications available }
  VertJust   : array[0..2] of string[10] = ('BottomText', 'CenterText', 'TopText');

var
  GraphDriver : integer;  { The Graphics device driver }
  GraphMode   : integer;  { The Graphics mode value }
  MaxX, MaxY  : word;     { The maximum resolution of the screen }
  ErrorCode   : integer;  { Reports any graphics errors }
  MaxColor    : Longint;     { The maximum color value available }
  OldExitProc : Pointer;  { Saves exit procedure address }

function RealPixelColor(PixColor : LongInt) : LongInt;
var
  CurC : Integer;
begin
  RealPixelColor := PixColor;
end;

function RealDrawColor(Color : LongInt) : LongInt;
var
  MaxC : Longint;
begin
  MaxC := GetMaxColor;

  if (MaxC = 65535) then
    SetRgbPalette(1024,(Color SHR 11) AND 31,(Color SHR 5)AND 63,Color AND 31)
  else if (MaxC = 32767) then
    SetRgbPalette(1024,(Color SHR 10) AND 31,(Color SHR 5)AND 31,Color AND 31)
  else if (MaxC = 16777) then
  begin
    SetRgbPalette(1024,(Color SHR 16) AND 255,(Color SHR 8)AND 255,Color AND 255);
  end;
  RealDrawColor := Color;
end;

function RealFillColor(Color : LongInt) : LongInt;
var
  MaxC : Longint;
begin
  MaxC := GetMaxColor;

  if (MaxC = 65535) then
    SetRgbPalette(1025,(Color SHR 11) AND 31,(Color SHR 5)AND 63,Color AND 31)
  else if (MaxC = 32767) then
    SetRgbPalette(1025,(Color SHR 10) AND 31,(Color SHR 5)AND 31,Color AND 31)
  else if (MaxC = 16777) then
  begin
    SetRgbPalette(1025,(Color SHR 16) AND 255,(Color SHR 8)AND 255,Color AND 255);
    Color := 0;
  end;
  RealFillColor := Color;
end;

function RealColor(Color : LongInt) : LongInt;
var
  MaxC : Longint;
begin
  MaxC := GetMaxColor;

  if (MaxC = 65535) then
    SetRgbPalette(1026,(Color SHR 11) AND 31,(Color SHR 5)AND 63,Color AND 31)
  else if (MaxC = 32767) then
    SetRgbPalette(1026,(Color SHR 10) AND 31,(Color SHR 5)AND 31,Color AND 31)
  else if (MaxC = 16777) then
  begin
    SetRgbPalette(1026,(Color SHR 16) AND 255,(Color SHR 8)AND 255,Color AND 255);
    Color := 0;
  end;
  RealColor := Color;
end;

function WhitePixel : LongInt;
var
  Clr : LongInt;
begin
  Clr := GetMaxColor;

  if (Clr = 65535) then      Clr := $FFFF
  else if (Clr = 32767) then Clr := $7FFF
  else if (Clr = 16777) then Clr := $ffffff
  else Clr := 15;
  WhitePixel := Clr;
end;

function BluePixel : LongInt;
var
  Clr : LongInt;
begin
  Clr := GetMaxColor;

  if (Clr = 65535) then      Clr := $1F
  else if (Clr = 32767) then Clr := $1F
  else if (Clr = 16777) then Clr := $ff
  else Clr := 1;
  BluePixel := Clr;
end;

function GreenPixel : LongInt;
var
  Clr : LongInt;
begin
  Clr := GetMaxColor;

  if (Clr = 65535) then      Clr := 63 SHL 5
  else if (Clr = 32767) then Clr := 31 SHL 5
  else if (Clr = 16777) then Clr := $ff00
  else Clr := 2;
  GreenPixel := Clr;
end;


{$F+}
procedure MyExitProc;
begin
  ExitProc := OldExitProc; { Restore exit procedure address }
  CloseGraph;              { Shut down the graphics system }
end; { MyExitProc }
{$F-}

{$F+}
function DetectVGA256 : integer;
{ Detects VGA or MCGA video cards }
var
  DetectedDriver : integer;
  SuggestedMode  : integer;
begin
  DetectGraph(DetectedDriver, SuggestedMode);
  if (DetectedDriver = VGA) or (DetectedDriver = MCGA) then
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
    Readln(SuggestedMode);
    DetectVGA256 := SuggestedMode;
  end
  else
    DetectVGA256 := grError; { Couldn't detect hardware }
end; { DetectVGA256 }
{$F-}

{$F+}
function DetectVGA32k : integer;
{ Detects VGA or MCGA video cards }
var
  DetectedDriver : integer;
  SuggestedMode  : integer;
begin
  DetectGraph(DetectedDriver, SuggestedMode);
  if (DetectedDriver = VGA) or (DetectedDriver = MCGA) then
  begin
    Writeln('Which video mode would you like to use?');
    Writeln('  0) 320x200x32k');
    Writeln('  1) 640x350x32k');
    Writeln('  2) 640x400x32k');
    Writeln('  3) 640x480x32k');
    Writeln('  4) 800x600x32k');
    Writeln('  5) 1024x768x32k');
    Writeln('  6) 1280x1024x32k');
    Write('> ');
    Readln(SuggestedMode);
    DetectVGA32k := SuggestedMode;
  end
  else
    DetectVGA32k := grError; { Couldn't detect hardware }
end; { DetectVGA32k }
{$F-}

{$F+}
function DetectVGA64k : integer;
{ Detects VGA or MCGA video cards }
var
  DetectedDriver : integer;
  SuggestedMode  : integer;
begin
  DetectGraph(DetectedDriver, SuggestedMode);
  if (DetectedDriver = VGA) or (DetectedDriver = MCGA) then
  begin
    Writeln('Which video mode would you like to use?');
    Writeln('  0) 320x200x64k');
    Writeln('  1) 640x350x64k');
    Writeln('  2) 640x400x64k');
    Writeln('  3) 640x480x64k');
    Writeln('  4) 800x600x64k');
    Writeln('  5) 1024x768x64k');
    Writeln('  6) 1280x1024x64k');
    Write('> ');
    Readln(SuggestedMode);
    DetectVGA64k := SuggestedMode;
  end
  else
    DetectVGA64k := grError; { Couldn't detect hardware }
end; { DetectVGA32k }
{$F-}

{$F+}
function DetectVGA24bit : integer;
{ Detects VGA or MCGA video cards }
var
  DetectedDriver : integer;
  SuggestedMode  : integer;
begin
  DetectGraph(DetectedDriver, SuggestedMode);
  if (DetectedDriver = VGA) or (DetectedDriver = MCGA) then
  begin
    Writeln('Which video mode would you like to use?');
    Writeln('  0) 320x200x24bit');
    Writeln('  1) 640x350x24bit');
    Writeln('  2) 640x400x24bit');
    Writeln('  3) 640x480x24bit');
    Writeln('  4) 800x600x24bit');
    Writeln('  5) 1024x768x24bit');
    Writeln('  6) 1280x1024x24bit');
    Write('> ');
    Readln(SuggestedMode);
    DetectVGA24bit := SuggestedMode;
  end
  else
    DetectVGA24bit := grError; { Couldn't detect hardware }
end; { DetectVGA32k }
{$F-}


{$F+}
function DetectTwk256 : integer;
{ Detects VGA or MCGA video cards }
var
  DetectedDriver : integer;
  SuggestedMode  : integer;
begin
  DetectGraph(DetectedDriver, SuggestedMode);
  if (DetectedDriver = VGA) or (DetectedDriver = MCGA) then
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
    Readln(SuggestedMode);
    DetectTwk256 := SuggestedMode;
  end
  else
    DetectTwk256 := grError; { Couldn't detect hardware }
end; { DetectVGA256 }
{$F-}

{$F+}
function DetectVGA16 : integer;
{ Detects VGA or MCGA video cards }
var
  DetectedDriver : integer;
  SuggestedMode  : integer;
begin
  DetectGraph(DetectedDriver, SuggestedMode);
  if (DetectedDriver = EGA) or (DetectedDriver = VGA) then
  begin
    Writeln('Which video mode would you like to use?');
    Writeln('  0) 320x200x16');
    Writeln('  1) 640x200x16');
    Writeln('  2) 640x350x16');
    Writeln('  3) 640x480x16');
    Writeln('  4) 800x600x16');
    Writeln('  5) 1024x768x16');
    Writeln('  6) 1280x1024x16');
    Write('> ');
    Readln(SuggestedMode);
    DetectVGA16 := SuggestedMode;
  end
  else
    DetectVGA16 := grError; { Couldn't detect hardware }
end; { DetectVGA256 }
{$F-}

{$F+}
function DetectTwk16 : integer;
{ Detects VGA or MCGA video cards }
var
  DetectedDriver : integer;
  SuggestedMode  : integer;
begin
  DetectGraph(DetectedDriver, SuggestedMode);
  if (DetectedDriver = VGA) then
  begin
    Writeln('Which video mode would you like to use?');
    Writeln('  0) 704x528x16');
    Writeln('  1) 720x540x16');
    Writeln('  2) 736x552x16');
    Writeln('  3) 752x564x16');
    Writeln('  4) 768x576x16');
    Writeln('  5) 784x588x16');
    Writeln('  6) 800x600x16');
    Write('> ');
    Readln(SuggestedMode);
    DetectTwk16 := SuggestedMode;
  end
  else
    DetectTwk16 := grError; { Couldn't detect hardware }
end; { DetectVGA256 }
{$F-}

{$F+}
function DetectText : integer;
begin
  DetectText := 0;
end;
{$F-}

{$F+}
function DetectS3 : integer;
{ Detects VGA or MCGA video cards }
var
  DetectedDriver : integer;
  SuggestedMode  : integer;
begin
  DetectGraph(DetectedDriver, SuggestedMode);
  if (DetectedDriver = VGA) then
  begin
    Writeln('Which video mode would you like to use?');
    Writeln('  0) 640x480x256');
    Writeln('  1) 800x600x256');
    Writeln('  2) 1024x768x256');
    Writeln('  3) 800x600x16');
    Writeln('  4) 1024x768x16');
    Writeln('  5) 1280x960x16');
    Writeln('  6) 1280x1024x16');
    Writeln('  7) 640x480x32k');
    Write('> ');
    Readln(SuggestedMode);
    DetectS3 := SuggestedMode;
  end
  else
    DetectS3 := grError; { Couldn't detect hardware }
end; { DetectVGA256 }
{$F-}

var
  AutoDetectPointer : pointer;

procedure Initialize;
{ Initialize graphics and report any errors that may occur }
var
  InGraphicsMode : boolean; { Flags initialization of graphics mode }
  PathToDriver   : string;  { Stores the DOS path to *.BGI & *.CHR }
  UseWhichDriver : integer;
begin
  { when using Crt and graphics, turn off Crt's memory-mapped writes }
  DirectVideo := False;
  OldExitProc := ExitProc;                { save previous exit proc }
  ExitProc := @MyExitProc;                { insert our exit proc in chain }
  PathToDriver := '';
  repeat
    Writeln('Which driver to use?');
    Writeln('  0) Svga16');
    Writeln('  1) Svga256');
    Writeln('  2) Svga32k');
    Writeln('  3) Svga64k');
    Writeln('  4) SvgaS3');
    Writeln('  5) SvgaTC');
    Writeln('  6) Tweak16');
    Writeln('  7) Tweak256');
    Writeln('  8) Tweak Text');
    Write('>');
    Readln(UseWhichDriver);
    if (UseWhichDriver = 0) then
    begin
      AutoDetectPointer := @DetectVGA16;
      GraphDriver := InstallUserDriver('Svga16',AutoDetectPointer);
    end
    else if (UseWhichDriver=1) then
    begin
      AutoDetectPointer := @DetectVGA256;   { Point to detection routine }
      GraphDriver := InstallUserDriver('SVGA256', AutoDetectPointer);
    end
    else if (UseWhichDriver=2) then
    begin
      AutoDetectPointer := @DetectVGA32k;
      GraphDriver := InstallUserDriver('Svga32k',AutoDetectPointer);
    end
    else if (UseWhichDriver=3) then
    begin
      AutoDetectPointer := @DetectVGA64k;
      GraphDriver := InstallUserDriver('Svga64k',AutoDetectPointer);
    end
    else if (UseWhichDriver=4) then
    begin
      AutoDetectPointer := @DetectS3;
      GraphDriver := InstallUserDriver('SvgaS3',AutoDetectPointer);
    end
    else if (UseWhichDriver=5) then
    begin
      AutoDetectPointer := @DetectVGA24bit;
      GraphDriver := InstallUserDriver('SvgaTC',AutoDetectPointer);
    end
    else if (UseWhichDriver=6) then
    begin
      AutoDetectPointer := @DetectTwk16;
      GraphDriver := InstallUserDriver('Twk16',AutoDetectPointer);
    end
    else if (UseWhichDriver=7) then
    begin
      AutoDetectPointer := @DetectTwk256;
      GraphDriver := InstallUserDriver('Twk256',AutoDetectPointer);
    end
    else if (UseWhichDriver=8) then
    begin
      AutoDetectPointer := @DetectText;
      GraphDriver := InstallUserDriver('Twktext',AutoDetectPointer);
    end;
    GraphDriver := Detect;
    InitGraph(GraphDriver, GraphMode, PathToDriver);
    ErrorCode := GraphResult;             { preserve error return }
    if ErrorCode AND $80 = $80 then
       ErrorCode := ErrorCode OR $ff00;
    if ErrorCode <> grOK then             { error? }
    begin
      Writeln('Graphics error: ', GraphErrorMsg(ErrorCode));
      if ErrorCode = grFileNotFound then  { Can't find driver file }
      begin
        Writeln('Enter full path to BGI driver or type <Ctrl-Break> to quit:');
        Readln(PathToDriver);
        Writeln;
      end
      else
        Halt(1);                          { Some other error: terminate }
    end;
  until ErrorCode = grOK;
  Randomize;                { init random number generator }
  MaxColor := GetMaxColor;  { Get the maximum allowable drawing color }
  MaxX := GetMaxX;          { Get screen resolution values }
  MaxY := GetMaxY;
end; { Initialize }

function Int2Str(L : LongInt) : string;
{ Converts an integer to a string for use with OutText, OutTextXY }
var
  S : string;
begin
  Str(L, S);
  Int2Str := S;
end; { Int2Str }

function RandColor : LongInt;
var
  redVal : longint;
{ Returns a Random non-zero color value that is within the legal
  color range for the selected device driver and graphics mode.
  MaxColor is set to GetMaxColor by Initialize }
begin
  if (GetMaxColor = 16777) then
  begin
      redVal := Random(255);
      RandColor := Random(65535)+(redVal SHL 16);
  end
  else
      RandColor := Random(MaxColor)+1;
end; { RandColor }

procedure DefaultColors;
{ Select the maximum color in the Palette for the drawing color }
begin
  SetColor(RealDrawColor(WhitePixel));
end; { DefaultColors }

procedure DrawBorder;
{ Draw a border around the current view port }
var
  ViewPort : ViewPortType;
begin
  DefaultColors;
  SetLineStyle(SolidLn, 0, NormWidth);
  GetViewSettings(ViewPort);
  with ViewPort do
    Rectangle(0, 0, x2-x1, y2-y1);
end; { DrawBorder }

procedure FullPort;
{ Set the view port to the entire screen }
begin
  SetViewPort(0, 0, MaxX, MaxY, ClipOn);
end; { FullPort }

procedure MainWindow(Header : string);
{ Make a default window and view port for demos }
begin
  DefaultColors;                           { Reset the colors }
  ClearDevice;                             { Clear the screen }
  SetTextStyle(DefaultFont, HorizDir, 1);  { Default text font }
  SetTextJustify(CenterText, TopText);     { Left justify text }
  FullPort;                                { Full screen view port }
  OutTextXY(MaxX div 2, 2, Header);        { Draw the header }
  { Draw main window }
  SetViewPort(0, TextHeight('M')+4, MaxX, MaxY-(TextHeight('M')+4), ClipOn);
  DrawBorder;                              { Put a border around it }
  { Move the edges in 1 pixel on all sides so border isn't in the view port }
  SetViewPort(1, TextHeight('M')+5, MaxX-1, MaxY-(TextHeight('M')+5), ClipOn);
end; { MainWindow }

procedure StatusLine(Msg : string);
{ Display a status line at the bottom of the screen }
begin
  FullPort;
  DefaultColors;
  SetTextStyle(DefaultFont, HorizDir, 1);
  SetTextJustify(CenterText, TopText);
  SetLineStyle(SolidLn, 0, NormWidth);
  SetFillStyle(EmptyFill, RealFillColor(0));
  Bar(0, MaxY-(TextHeight('M')+4), MaxX, MaxY);      { Erase old status line }
  Rectangle(0, MaxY-(TextHeight('M')+4), MaxX, MaxY);
  OutTextXY(MaxX div 2, MaxY-(TextHeight('M')+2), Msg);
  { Go back to the main window }
  SetViewPort(1, TextHeight('M')+5, MaxX-1, MaxY-(TextHeight('M')+5), ClipOn);
end; { StatusLine }

procedure WaitToGo;
{ Wait for the user to abort the program or continue }
const
  Esc = #27;
var
  Ch : char;
begin
  StatusLine('Esc aborts or press a key...');
  repeat until KeyPressed;
  Ch := ReadKey;
  if Ch = Esc then
    Halt(0)                           { terminate program }
  else
    ClearDevice;                      { clear screen, go on with demo }
end; { WaitToGo }

procedure GetDriverAndMode(var DriveStr, ModeStr : string);
{ Return strings describing the current device driver and graphics mode
  for display of status report }
begin
  DriveStr := GetDriverName;
  ModeStr := GetModeName(GetGraphMode);
end; { GetDriverAndMode }

procedure ReportStatus;
{ Display the status of all query functions after InitGraph }
const
  X = 10;
var
  ViewInfo   : ViewPortType;     { Parameters for inquiry procedures }
  LineInfo   : LineSettingsType;
  FillInfo   : FillSettingsType;
  TextInfo   : TextSettingsType;
  Palette    : PaletteType;
  DriverStr  : string;           { Driver and mode strings }
  ModeStr    : string;
  Y          : word;

procedure WriteOut(S : string);
{ Write out a string and increment to next line }
begin
  OutTextXY(X, Y, S);
  Inc(Y, TextHeight('M')+2);
end; { WriteOut }

begin { ReportStatus }
  GetDriverAndMode(DriverStr, ModeStr);   { Get current settings }
  GetViewSettings(ViewInfo);
  GetLineSettings(LineInfo);
  GetFillSettings(FillInfo);
  GetTextSettings(TextInfo);
  GetPalette(Palette);

  Y := 4;
  MainWindow('Status report after InitGraph');
  SetTextJustify(LeftText, TopText);
  WriteOut('Graphics device    : '+DriverStr);
  WriteOut('Graphics mode      : '+ModeStr);
  WriteOut('Screen resolution  : (0, 0, '+Int2Str(GetMaxX)+', '+Int2Str(GetMaxY)+')');
  with ViewInfo do
  begin
    WriteOut('Current view port  : ('+Int2Str(x1)+', '+Int2Str(y1)+', '+Int2Str(x2)+', '+Int2Str(y2)+')');
    if ClipOn then
      WriteOut('Clipping           : ON')
    else
      WriteOut('Clipping           : OFF');
  end;
  WriteOut('Current position   : ('+Int2Str(GetX)+', '+Int2Str(GetY)+')');
  WriteOut('Palette entries    : '+Int2Str(Palette.Size));
  WriteOut('GetMaxColor        : '+Int2Str(GetMaxColor));
  WriteOut('Current color      : '+Int2Str(GetColor));
  with LineInfo do
  begin
    WriteOut('Line style         : '+LineStyles[LineStyle]);
    WriteOut('Line thickness     : '+Int2Str(Thickness));
  end;
  with FillInfo do
  begin
    WriteOut('Current fill style : '+FillStyles[Pattern]);
    WriteOut('Current fill color : '+Int2Str(Color));
  end;
  with TextInfo do
  begin
    WriteOut('Current font       : '+Fonts[Font]);
    WriteOut('Text direction     : '+TextDirect[Direction]);
    WriteOut('Character size     : '+Int2Str(CharSize));
    WriteOut('Horizontal justify : '+HorizJust[Horiz]);
    WriteOut('Vertical justify   : '+VertJust[Vert]);
  end;
  WaitToGo;
end; { ReportStatus }

procedure FillEllipsePlay;
{ Random filled ellipse demonstration }
const
  MaxFillStyles = 12; { patterns 0..11 }
var
  MaxRadius : word;
  FillColor : LongInt;
begin
  MainWindow('FillEllipse demonstration');
  StatusLine('Esc aborts or press a key');
  MaxRadius := MaxY div 10;
  SetLineStyle(SolidLn, 0, NormWidth);
  repeat
    FillColor := RandColor;
    SetColor(RealDrawColor(FillColor));
    SetFillStyle(Random(MaxFillStyles), RealFillColor(FillColor));
    FillEllipse(Random(MaxX), Random(MaxY),
                Random(MaxRadius), Random(MaxRadius));
  until KeyPressed;
  WaitToGo;
end; { FillEllipsePlay }

procedure SectorPlay;
{ Draw random sectors on the screen }
const
  MaxFillStyles = 12; { patterns 0..11 }
var
  MaxRadius : word;
  FillColor : LongInt;
  EndAngle  : integer;
begin
  MainWindow('Sector demonstration');
  StatusLine('Esc aborts or press a key');
  MaxRadius := MaxY div 10;
  SetLineStyle(SolidLn, 0, NormWidth);
  repeat
    FillColor := RandColor;
    SetColor(RealDrawColor(FillColor));
    SetFillStyle(Random(MaxFillStyles), RealFillColor(FillColor));
    EndAngle := Random(360);
    Sector(Random(MaxX), Random(MaxY), Random(EndAngle), EndAngle,
           Random(MaxRadius), Random(MaxRadius));
  until KeyPressed;
  WaitToGo;
end; { SectorPlay }

procedure WriteModePlay;
{ Demonstrate the SetWriteMode procedure for XOR lines }
const
  DelayValue = 50;  { milliseconds to delay }
var
  ViewInfo      : ViewPortType;
  Color         : LongInt;
  Left, Top     : integer;
  Right, Bottom : integer;
  Step          : integer; { step for rectangle shrinking }
begin
  MainWindow('SetWriteMode demonstration');
  StatusLine('Esc aborts or press a key');
  GetViewSettings(ViewInfo);
  Left := 0;
  Top := 0;
  with ViewInfo do
  begin
    Right := x2-x1;
    Bottom := y2-y1;
  end;
  Step := Bottom div 50;
  SetColor(RealDrawColor(WhitePixel));
  Line(Left, Top, Right, Bottom);
  Line(Left, Bottom, Right, Top);
  SetWriteMode(XORPut);                    { Set XOR write mode }
  repeat
    Line(Left, Top, Right, Bottom);        { Draw XOR lines }
    Line(Left, Bottom, Right, Top);
    Rectangle(Left, Top, Right, Bottom);   { Draw XOR rectangle }
    Delay(DelayValue);                     { Wait }
    Line(Left, Top, Right, Bottom);        { Erase lines }
    Line(Left, Bottom, Right, Top);
    Rectangle(Left, Top, Right, Bottom);   { Erase rectangle }
    if (Left+Step < Right) and (Top+Step < Bottom) then
      begin
        Inc(Left, Step);                  { Shrink rectangle }
        Inc(Top, Step);
        Dec(Right, Step);
        Dec(Bottom, Step);
      end
    else
      begin
        Color := RandColor;                { New color }
        SetColor(RealDrawColor(Color));
        Left := 0;                         { Original large rectangle }
        Top := 0;
        with ViewInfo do
        begin
          Right := x2-x1;
          Bottom := y2-y1;
        end;
      end;
  until KeyPressed;
  SetWriteMode(CopyPut);                   { back to overwrite mode }
  WaitToGo;
end; { WriteModePlay }

procedure AspectRatioPlay;
{ Demonstrate  SetAspectRatio command }
var
  ViewInfo   : ViewPortType;
  CenterX    : integer;
  CenterY    : integer;
  Radius     : word;
  Xasp, Yasp : word;
  i          : integer;
  RadiusStep : word;
begin
  MainWindow('SetAspectRatio demonstration');
  GetViewSettings(ViewInfo);
  with ViewInfo do
  begin
    CenterX := (x2-x1) div 2;
    CenterY := (y2-y1) div 2;
    Radius := 3*((y2-y1) div 5);
  end;
  RadiusStep := (Radius div 30);
  Circle(CenterX, CenterY, Radius);
  GetAspectRatio(Xasp, Yasp);
  for i := 1 to 30 do
  begin
    SetAspectRatio(Xasp, Yasp+(I*GetMaxX));    { Increase Y aspect factor }
    Circle(CenterX, CenterY, Radius);
    Dec(Radius, RadiusStep);                   { Shrink radius }
  end;
  Inc(Radius, RadiusStep*30);
  for i := 1 to 30 do
  begin
    SetAspectRatio(Xasp+(I*GetMaxX), Yasp);    { Increase X aspect factor }
    if Radius > RadiusStep then
      Dec(Radius, RadiusStep);                 { Shrink radius }
    Circle(CenterX, CenterY, Radius);
  end;
  SetAspectRatio(Xasp, Yasp);                  { back to original aspect }
  WaitToGo;
end; { AspectRatioPlay }

procedure TextPlay;
{ Demonstrate text justifications and text sizing }
var
  Size : word;
  W, H, X, Y : word;
  ViewInfo : ViewPortType;
begin
  MainWindow('SetTextJustify / SetUserCharSize demo');
  GetViewSettings(ViewInfo);
  with ViewInfo do
  begin
    SetTextStyle(TriplexFont, VertDir, 4);
    Y := (y2-y1) - 2;
    SetTextJustify(CenterText, BottomText);
    OutTextXY(2*TextWidth('M'), Y, 'Vertical');
    SetTextStyle(TriplexFont, HorizDir, 4);
    SetTextJustify(LeftText, TopText);
    OutTextXY(2*TextWidth('M'), 2, 'Horizontal');
    SetTextJustify(CenterText, CenterText);
    X := (x2-x1) div 2;
    Y := TextHeight('H');
    for Size := 1 to 4 do
    begin
      SetTextStyle(TriplexFont, HorizDir, Size);
      H := TextHeight('M');
      W := TextWidth('M');
      Inc(Y, H);
      OutTextXY(X, Y, 'Size '+Int2Str(Size));
    end;
    Inc(Y, H div 2);
    SetTextJustify(CenterText, TopText);
    SetUserCharSize(5, 6, 3, 2);
    SetTextStyle(TriplexFont, HorizDir, UserCharSize);
    OutTextXY((x2-x1) div 2, Y, 'User defined size!');
  end;
  WaitToGo;
end; { TextPlay }

procedure TextDump;
{ Dump the complete character sets to the screen }
const
  CGASizes  : array[0..4] of word = (1, 3, 7, 3, 3);
  NormSizes : array[0..4] of word = (1, 4, 7, 4, 4);
var
  Font : word;
  ViewInfo : ViewPortType;
  Ch : char;
begin
  for Font := 0 to 4 do
  begin
    MainWindow(Fonts[Font]+' character set');
    GetViewSettings(ViewInfo);
    with ViewInfo do
    begin
      SetTextJustify(LeftText, TopText);
      MoveTo(2, 3);
      if Font = DefaultFont then
        begin
          SetTextStyle(Font, HorizDir, 1);
          Ch := #0;
          repeat
            OutText(Ch);
            if (GetX + TextWidth('M')) > (x2-x1) then
              MoveTo(2, GetY + TextHeight('M')+3);
            Ch := Succ(Ch);
          until (Ch >= #255);
        end
      else
        begin
          if MaxY < 200 then
            SetTextStyle(Font, HorizDir, CGASizes[Font])
          else
            SetTextStyle(Font, HorizDir, NormSizes[Font]);
          Ch := '!';
          repeat
            OutText(Ch);
            if (GetX + TextWidth('M')) > (x2-x1) then
              MoveTo(2, GetY + TextHeight('M')+3);
            Ch := Succ(Ch);
          until (Ord(Ch) = Ord('~')+1);
        end;
    end; { with }
    WaitToGo;
  end; { for loop }
end; { TextDump }

procedure LineToPlay;
{ Demonstrate MoveTo and LineTo commands }
const
  MaxPoints = 15;
var
  Points     : array[0..MaxPoints] of PointType;
  ViewInfo   : ViewPortType;
  I, J       : integer;
  CenterX    : integer;   { The center point of the circle }
  CenterY    : integer;
  Radius     : word;
  StepAngle  : word;
  Xasp, Yasp : word;
  Radians    : real;

function AdjAsp(Value : integer) : integer;
{ Adjust a value for the aspect ratio of the device }
begin
  AdjAsp := (LongInt(Value) * Xasp) div Yasp;
end; { AdjAsp }

begin
  MainWindow('MoveTo, LineTo demonstration');
  GetAspectRatio(Xasp, Yasp);
  GetViewSettings(ViewInfo);
  with ViewInfo do
  begin
    CenterX := (x2-x1) div 2;
    CenterY := (y2-y1) div 2;
    Radius := CenterY;
    while (CenterY+AdjAsp(Radius)) < (y2-y1)-20 do
      Inc(Radius);
  end;
  StepAngle := 360 div MaxPoints;
  for I := 0 to MaxPoints - 1 do
  begin
    Radians := (StepAngle * I) * Pi / 180;
    Points[I].X := CenterX + round(Cos(Radians) * Radius);
    Points[I].Y := CenterY - AdjAsp(round(Sin(Radians) * Radius));
  end;
  Circle(CenterX, CenterY, Radius);
  for I := 0 to MaxPoints - 1 do
  begin
    for J := I to MaxPoints - 1 do
    begin
      MoveTo(Points[I].X, Points[I].Y);
      LineTo(Points[J].X, Points[J].Y);
    end;
  end;
  WaitToGo;
end; { LineToPlay }

procedure LineRelPlay;
{ Demonstrate MoveRel and LineRel commands }
const
  MaxPoints = 12;
var
  Poly     : array[1..MaxPoints] of PointType; { Stores a polygon for filling }
  CurrPort : ViewPortType;

procedure DrawTesseract;
{ Draw a Tesseract on the screen with relative move and
  line drawing commands, also create a polygon for filling }
const
  CheckerBoard : FillPatternType = (0, $10, $28, $44, $28, $10, 0, 0);
var
  X, Y, W, H   : integer;

begin
  GetViewSettings(CurrPort);
  with CurrPort do
  begin
    W := (x2-x1) div 9;
    H := (y2-y1) div 8;
    X := ((x2-x1) div 2) - round(2.5 * W);
    Y := ((y2-y1) div 2) - (3 * H);

    { Border around viewport is outer part of polygon }
    Poly[1].X := 0;     Poly[1].Y := 0;
    Poly[2].X := x2-x1; Poly[2].Y := 0;
    Poly[3].X := x2-x1; Poly[3].Y := y2-y1;
    Poly[4].X := 0;     Poly[4].Y := y2-y1;
    Poly[5].X := 0;     Poly[5].Y := 0;
    MoveTo(X, Y);

    { Grab the whole in the polygon as we draw }
    MoveRel(0, H);      Poly[6].X := GetX;  Poly[6].Y := GetY;
    MoveRel(W, -H);     Poly[7].X := GetX;  Poly[7].Y := GetY;
    MoveRel(4*W, 0);    Poly[8].X := GetX;  Poly[8].Y := GetY;
    MoveRel(0, 5*H);    Poly[9].X := GetX;  Poly[9].Y := GetY;
    MoveRel(-W, H);     Poly[10].X := GetX; Poly[10].Y := GetY;
    MoveRel(-4*W, 0);   Poly[11].X := GetX; Poly[11].Y := GetY;
    MoveRel(0, -5*H);   Poly[12].X := GetX; Poly[12].Y := GetY;

    { Fill the polygon with a user defined fill pattern }
    SetFillPattern(CheckerBoard, RealFillColor(GreenPixel));
    FillPoly(12, Poly);

    MoveRel(W, -H);
    LineRel(0, 5*H);   LineRel(2*W, 0);    LineRel(0, -3*H);
    LineRel(W, -H);    LineRel(0, 5*H);    MoveRel(0, -5*H);
    LineRel(-2*W, 0);  LineRel(0, 3*H);    LineRel(-W, H);
    MoveRel(W, -H);    LineRel(W, 0);      MoveRel(0, -2*H);
    LineRel(-W, 0);

    { Flood fill the center }
    FloodFill((x2-x1) div 2, (y2-y1) div 2,RealColor(WhitePixel));
  end;
end; { DrawTesseract }

begin
  MainWindow('LineRel / MoveRel demonstration');
  GetViewSettings(CurrPort);
  with CurrPort do
    { Move the viewport out 1 pixel from each end }
    SetViewPort(x1-1, y1-1, x2+1, y2+1, ClipOn);
  DrawTesseract;
  WaitToGo;
end; { LineRelPlay }

procedure PiePlay;
{ Demonstrate  PieSlice and GetAspectRatio commands }
var
  ViewInfo   : ViewPortType;
  CenterX    : integer;
  CenterY    : integer;
  Radius     : word;
  Xasp, Yasp : word;
  X, Y       : integer;

function AdjAsp(Value : integer) : integer;
{ Adjust a value for the aspect ratio of the device }
begin
  AdjAsp := (LongInt(Value) * Xasp) div Yasp;
end; { AdjAsp }

procedure GetTextCoords(AngleInDegrees, Radius : word; var X, Y : integer);
{ Get the coordinates of text for pie slice labels }
var
  Radians : real;
begin
  Radians := AngleInDegrees * Pi / 180;
  X := round(Cos(Radians) * Radius);
  Y := round(Sin(Radians) * Radius);
end; { GetTextCoords }

begin
  MainWindow('PieSlice / GetAspectRatio demonstration');
  GetAspectRatio(Xasp, Yasp);
  GetViewSettings(ViewInfo);
  with ViewInfo do
  begin
    CenterX := (x2-x1) div 2;
    CenterY := ((y2-y1) div 2) + 20;
    Radius := (y2-y1) div 3;
    while AdjAsp(Radius) < round((y2-y1) / 3.6) do
      Inc(Radius);
  end;
  SetTextStyle(TriplexFont, HorizDir, 4);
  SetTextJustify(CenterText, TopText);
  OutTextXY(CenterX, 0, 'This is a pie chart!');

  SetTextStyle(TriplexFont, HorizDir, 3);

  SetFillStyle(SolidFill, RealFillColor(RandColor));
  PieSlice(CenterX+10, CenterY-AdjAsp(10), 0, 90, Radius);
  GetTextCoords(45, Radius, X, Y);
  SetTextJustify(LeftText, BottomText);
  OutTextXY(CenterX+10+X+TextWidth('H'), CenterY-AdjAsp(10+Y), '25 %');

  SetFillStyle(HatchFill, RealFillColor(RandColor));
  PieSlice(CenterX, CenterY, 225, 360, Radius);
  GetTextCoords(293, Radius, X, Y);
  SetTextJustify(LeftText, TopText);
  OutTextXY(CenterX+X+TextWidth('H'), CenterY-AdjAsp(Y), '37.5 %');

  SetFillStyle(InterleaveFill, RealFillColor(RandColor));
  PieSlice(CenterX-10, CenterY, 135, 225, Radius);
  GetTextCoords(180, Radius, X, Y);
  SetTextJustify(RightText, CenterText);
  OutTextXY(CenterX-10+X-TextWidth('H'), CenterY-AdjAsp(Y), '25 %');

  SetFillStyle(WideDotFill, RealFillColor(RandColor));
  PieSlice(CenterX, CenterY, 90, 135, Radius);
  GetTextCoords(112, Radius, X, Y);
  SetTextJustify(RightText, BottomText);
  OutTextXY(CenterX+X-TextWidth('H'), CenterY-AdjAsp(Y), '12.5 %');

  WaitToGo;
end; { PiePlay }

procedure Bar3DPlay;
{ Demonstrate Bar3D command }
const
  NumBars   = 7;  { The number of bars drawn }
  BarHeight : array[1..NumBars] of byte = (1, 3, 2, 5, 4, 2, 1);
  YTicks    = 5;  { The number of tick marks on the Y axis }
var
  ViewInfo : ViewPortType;
  H        : word;
  XStep    : real;
  YStep    : real;
  I, J     : integer;
  Depth    : word;
  Color    : LongInt;
begin
  MainWindow('Bar3D / Rectangle demonstration');
  H := 3*TextHeight('M');
  GetViewSettings(ViewInfo);
  SetTextJustify(CenterText, TopText);
  SetTextStyle(TriplexFont, HorizDir, 4);
  OutTextXY(MaxX div 2, 6, 'These are 3D bars !');
  SetTextStyle(DefaultFont, HorizDir, 1);
  with ViewInfo do
    SetViewPort(x1+50, y1+40, x2-50, y2-10, ClipOn);
  GetViewSettings(ViewInfo);
  with ViewInfo do
  begin
    Line(H, H, H, (y2-y1)-H);
    Line(H, (y2-y1)-H, (x2-x1)-H, (y2-y1)-H);
    YStep := ((y2-y1)-(2*H)) / YTicks;
    XStep := ((x2-x1)-(2*H)) / NumBars;
    J := (y2-y1)-H;
    SetTextJustify(CenterText, CenterText);

    { Draw the Y axis and ticks marks }
    for I := 0 to Yticks do
    begin
      Line(H div 2, J, H, J);
      OutTextXY(0, J, Int2Str(I));
      J := Round(J-Ystep);
    end;


    Depth := trunc(0.25 * XStep);    { Calculate depth of bar }

    { Draw X axis, bars, and tick marks }
    SetTextJustify(CenterText, TopText);
    J := H;
    for I := 1 to Succ(NumBars) do
    begin
      SetColor(RealDrawColor(WhitePixel));
      Line(J, (y2-y1)-H, J, (y2-y1-3)-(H div 2));
      OutTextXY(J, (y2-y1)-(H div 2), Int2Str(I-1));
      if I <> Succ(NumBars) then
      begin
        Color := RandColor;
        SetFillStyle(I, RealFillColor(Color));
        SetColor(RealDrawColor(Color));
        Bar3D(J, round((y2-y1-H)-(BarHeight[I] * Ystep)),
                 round(J+Xstep-Depth), round((y2-y1)-H-1), Depth, TopOn);
        J := Round(J+Xstep);
      end;
    end;

  end;
  WaitToGo;
end; { Bar3DPlay }

procedure SolidBarPlay;
{ Draw random solid bars on the screen }
var
  MaxWidth  : integer;
  MaxHeight : integer;
  ViewInfo  : ViewPortType;
  Color     : LongInt;
begin
  MainWindow('Random Solid Bars');
  StatusLine('Esc aborts or press a key');
  GetViewSettings(ViewInfo);
  with ViewInfo do
  begin
    MaxWidth := x2-x1;
    MaxHeight := y2-y1;
  end;
  repeat
    Color := RandColor;
    SetColor(RealDrawColor(Color));
    SetFillStyle(SolidFill, RealFillColor(Color));
    Bar3D(Random(MaxWidth), Random(MaxHeight),
          Random(MaxWidth), Random(MaxHeight), 0, TopOff);
  until KeyPressed;
  WaitToGo;
end; { SolidBarPlay }

procedure BarPlay;
{ Demonstrate Bar command }
const
  NumBars   = 5;
  BarHeight : array[1..NumBars] of byte = (1, 3, 5, 2, 4);
  Styles    : array[1..NumBars] of byte = (1, 3, 10, 5, 9);
var
  ViewInfo  : ViewPortType;
  BarNum    : word;
  H         : word;
  XStep     : real;
  YStep     : real;
  I, J      : integer;
  Color     : LongInt;
begin
  MainWindow('Bar / Rectangle demonstration');
  H := 3*TextHeight('M');
  GetViewSettings(ViewInfo);
  SetTextJustify(CenterText, TopText);
  SetTextStyle(TriplexFont, HorizDir, 4);
  OutTextXY(MaxX div 2, 6, 'These are 2D bars !');
  SetTextStyle(DefaultFont, HorizDir, 1);
  with ViewInfo do
    SetViewPort(x1+50, y1+30, x2-50, y2-10, ClipOn);
  GetViewSettings(ViewInfo);
  with ViewInfo do
  begin
    Line(H, H, H, (y2-y1)-H);
    Line(H, (y2-y1)-H, (x2-x1)-H, (y2-y1)-H);
    YStep := ((y2-y1)-(2*H)) / NumBars;
    XStep := ((x2-x1)-(2*H)) / NumBars;
    J := (y2-y1)-H;
    SetTextJustify(CenterText, CenterText);

    { Draw Y axis with tick marks }
    for I := 0 to NumBars do
    begin
      Line(H div 2, J, H, J);
      OutTextXY(0, J, Int2Str(i));
      J := Round(J-Ystep);
    end;

    { Draw X axis, bars, and tick marks }
    J := H;
    SetTextJustify(CenterText, TopText);
    for I := 1 to Succ(NumBars) do
    begin
      SetColor(RealDrawColor(WhitePixel));
      Line(J, (y2-y1)-H, J, (y2-y1-3)-(H div 2));
      OutTextXY(J, (y2-y1)-(H div 2), Int2Str(I));
      if I <> Succ(NumBars) then
      begin
        Color := RandColor;
        SetFillStyle(Styles[I], RealFillColor(Color));
        SetColor(RealDrawColor(Color));
        Bar(J, round((y2-y1-H)-(BarHeight[I] * Ystep)), round(J+Xstep), (y2-y1)-H-1);
        Rectangle(J, round((y2-y1-H)-(BarHeight[I] * Ystep)), round(J+Xstep), (y2-y1)-H-1);
      end;
      J := Round(J+Xstep);
    end;

  end;
  WaitToGo;
end; { BarPlay }

procedure CirclePlay;
{ Draw random circles on the screen }
var
  MaxRadius : word;
begin
  MainWindow('Circle demonstration');
  StatusLine('Esc aborts or press a key');
  MaxRadius := MaxY div 10;
  SetLineStyle(SolidLn, 0, NormWidth);
  repeat
    SetColor(RealDrawColor(RandColor));
    Circle(Random(MaxX), Random(MaxY), Random(MaxRadius));
  until KeyPressed;
  WaitToGo;
end; { CirclePlay }


procedure RandBarPlay;
{ Draw random bars on the screen }
var
  MaxWidth  : integer;
  MaxHeight : integer;
  ViewInfo  : ViewPortType;
  Color     : LongInt;
begin
  MainWindow('Random Bars');
  StatusLine('Esc aborts or press a key');
  GetViewSettings(ViewInfo);
  with ViewInfo do
  begin
    MaxWidth := x2-x1;
    MaxHeight := y2-y1;
  end;
  repeat
    Color := RandColor;
    SetColor(RealDrawColor(Color));
    SetFillStyle(Random(CloseDotFill)+1, RealFillColor(Color));
    Bar3D(Random(MaxWidth), Random(MaxHeight),
          Random(MaxWidth), Random(MaxHeight), 0, TopOff);
  until KeyPressed;
  WaitToGo;
end; { RandBarPlay }

procedure ArcPlay;
{ Draw random arcs on the screen }
var
  MaxRadius : word;
  EndAngle : word;
  ArcInfo : ArcCoordsType;
begin
  MainWindow('Arc / GetArcCoords demonstration');
  StatusLine('Esc aborts or press a key');
  MaxRadius := MaxY div 10;
  repeat
    SetColor(RealDrawColor(RandColor));
    EndAngle := Random(360);
    SetLineStyle(SolidLn, 0, NormWidth);
    Arc(Random(MaxX), Random(MaxY), Random(EndAngle), EndAngle, Random(MaxRadius));
    GetArcCoords(ArcInfo);
    with ArcInfo do
    begin
      Line(X, Y, XStart, YStart);
      Line(X, Y, Xend, Yend);
    end;
  until KeyPressed;
  WaitToGo;
end; { ArcPlay }

procedure PutPixelPlay;
{ Demonstrate the PutPixel and GetPixel commands }
const
  Seed   = 1962; { A seed for the random number generator }
  NumPts = 2000; { The number of pixels plotted }
  Esc    = #27;
var
  I : word;
  X, Y : word;
  Color : LongInt;
  XMax, YMax  : integer;
  ViewInfo    : ViewPortType;
begin
  MainWindow('PutPixel / GetPixel demonstration');
  StatusLine('Esc aborts or press a key...');

  GetViewSettings(ViewInfo);
  with ViewInfo do
  begin
    XMax := (x2-x1-1);
    YMax := (y2-y1-1);
  end;

  while not KeyPressed do
  begin
    { Plot random pixels }
    RandSeed := Seed;
    I := 0;
    while (not KeyPressed) and (I < NumPts) do
    begin
      Inc(I);
      PutPixel(Random(XMax)+1, Random(YMax)+1, RealColor(RandColor));
    end;

    { Erase pixels }
    RandSeed := Seed;
    I := 0;
    while (not KeyPressed) and (I < NumPts) do
    begin
      Inc(I);
      X := Random(XMax)+1;
      Y := Random(YMax)+1;
      Color := RealPixelColor(GetPixel(X,Y));
      inline($89/$56/<Color);  (* Used to load 15-bit color value *)
      if Color = RandColor then
        PutPixel(X, Y, RealColor(0))
    end;
  end;
  WaitToGo;
end; { PutPixelPlay }

procedure PutImagePlay;
{ Demonstrate the GetImage and PutImage commands }

const
  r  = 20;
  StartX = 100;
  StartY = 150;

var
  CurPort : ViewPortType;

procedure MoveSaucer(var X, Y : integer; Width, Height : integer);
var
  Step : integer;
begin
  Step := Random(2*r);
  if Odd(Step) then
    Step := -Step;
  X := X + Step;
  Step := Random(r);
  if Odd(Step) then
    Step := -Step;
  Y := Y + Step;

  { Make saucer bounce off viewport walls }
  with CurPort do
  begin
    if (x1 + X + Width - 1 > x2) then
      X := x2-x1 - Width + 1
    else
      if (X < 0) then
        X := 0;
    if (y1 + Y + Height - 1 > y2) then
      Y := y2-y1 - Height + 1
    else
      if (Y < 0) then
        Y := 0;
  end;
end; { MoveSaucer }

var
  Pausetime : word;
  Saucer    : pointer;
  X, Y      : integer;
  ulx, uly  : word;
  lrx, lry  : word;
  Size      : longint;
  I         : word;
begin
  ClearDevice;
  FullPort;

  { PaintScreen }
  ClearDevice;
  MainWindow('GetImage / PutImage Demonstration');
  StatusLine('Esc aborts or press a key...');
  GetViewSettings(CurPort);

  { DrawSaucer }
  Ellipse(StartX, StartY, 0, 360, r, (r div 3)+2);
  Ellipse(StartX, StartY-4, 190, 357, r, r div 3);
  Line(StartX+7, StartY-6, StartX+10, StartY-12);
  Circle(StartX+10, StartY-12, 2);
  Line(StartX-7, StartY-6, StartX-10, StartY-12);
  Circle(StartX-10, StartY-12, 2);
  SetFillStyle(SolidFill, RealFillColor(BluePixel));
  FloodFill(StartX+1, StartY+4, RealColor(WhitePixel));

  { ReadSaucerImage }
  ulx := StartX-(r+1);
  uly := StartY-14;
  lrx := StartX+(r+1);
  lry := StartY+(r div 3)+3;

  case GetMaxColor of
    16:  Size := ImageSize(ulx, uly, lrx, lry);
    256: Size := (lrx-uly)*(lry-uly)+4;
    65535,32768: Size := 2*(lrx-uly)*(lry-uly)+4;
    16777: Size := 4*(lrx-uly)*(lry-uly)+4;
  end;
  GetMem(Saucer, Size);
  GetImage(ulx, uly, lrx, lry, Saucer^);
  PutImage(ulx, uly, Saucer^, XORput);               { erase image }
  { Plot some "stars" }
  for I := 1 to 1000 do
    PutPixel(Random(MaxX), Random(MaxY), RealColor(RandColor));
  X := MaxX div 2;
  Y := MaxY div 2;
  PauseTime := 70;

  { Move the saucer around }
  repeat
    X := (X div 8)*8;
    PutImage(X, Y, Saucer^, XORput);                 { draw image }
    Delay(PauseTime);
    PutImage(X, Y, Saucer^, XORput);                 { erase image }
    MoveSaucer(X, Y, lrx - ulx + 1, lry - uly + 1);  { width/height }
  until KeyPressed;
  FreeMem(Saucer, size);
  WaitToGo;
end; { PutImagePlay }

procedure PolyPlay;
{ Draw random polygons with random fill styles on the screen }
const
  MaxPts = 5;
type
  PolygonType = array[1..MaxPts] of PointType;
var
  Poly : PolygonType;
  I : word;
  Color : LongInt;
begin
  MainWindow('FillPoly demonstration');
  StatusLine('Esc aborts or press a key...');
  repeat
    Color := RandColor;
    SetFillStyle(Random(11)+1, RealFillColor(Color));
    SetColor(RealDrawColor(Color));
    for I := 1 to MaxPts do
      with Poly[I] do
      begin
        X := Random(MaxX);
        Y := Random(MaxY);
      end;
    FillPoly(MaxPts, Poly);
  until KeyPressed;
  WaitToGo;
end; { PolyPlay }

procedure FillStylePlay;
{ Display all of the predefined fill styles available }
var
  Style    : word;
  Width    : word;
  Height   : word;
  X, Y     : word;
  I, J     : word;
  ViewInfo : ViewPortType;

procedure DrawBox(X, Y : word);
begin
  SetFillStyle(Style, RealFillColor(WhitePixel));
  with ViewInfo do
    Bar(X, Y, X+Width, Y+Height);
  Rectangle(X, Y, X+Width, Y+Height);
  OutTextXY(X+(Width div 2), Y+Height+4, Int2Str(Style));
  Inc(Style);
end; { DrawBox }

begin
  MainWindow('Pre-defined fill styles');
  GetViewSettings(ViewInfo);
  with ViewInfo do
  begin
    Width := 2 * ((x2+1) div 13);
    Height := 2 * ((y2-10) div 10);
  end;
  X := Width div 2;
  Y := Height div 2;
  Style := 0;
  for J := 1 to 3 do
  begin
    for I := 1 to 4 do
    begin
      DrawBox(X, Y);
      Inc(X, (Width div 2) * 3);
    end;
    X := Width div 2;
    Inc(Y, (Height div 2) * 3);
  end;
  SetTextJustify(LeftText, TopText);
  WaitToGo;
end; { FillStylePlay }

procedure FillPatternPlay;
{ Display some user defined fill patterns }
const
  Patterns : array[0..11] of FillPatternType = (
  ($AA, $55, $AA, $55, $AA, $55, $AA, $55),
  ($33, $33, $CC, $CC, $33, $33, $CC, $CC),
  ($F0, $F0, $F0, $F0, $F, $F, $F, $F),
  (0, $10, $28, $44, $28, $10, 0, 0),
  (0, $70, $20, $27, $25, $27, $4, $4),
  (0, 0, 0, $18, $18, 0, 0, 0),
  (0, 0, $3C, $3C, $3C, $3C, 0, 0),
  (0, $7E, $7E, $7E, $7E, $7E, $7E, 0),
  (0, 0, $22, $8, 0, $22, $1C, 0),
  ($FF, $7E, $3C, $18, $18, $3C, $7E, $FF),
  (0, $10, $10, $7C, $10, $10, 0, 0),
  (0, $42, $24, $18, $18, $24, $42, 0));
var
  Style    : word;
  Width    : word;
  Height   : word;
  X, Y     : word;
  I, J     : word;
  ViewInfo : ViewPortType;

procedure DrawBox(X, Y : word);
begin
  SetFillPattern(Patterns[Style], RealFillColor(WhitePixel));
  with ViewInfo do
    Bar(X, Y, X+Width, Y+Height);
  Rectangle(X, Y, X+Width, Y+Height);
  Inc(Style);
end; { DrawBox }

begin
  MainWindow('User defined fill styles');
  GetViewSettings(ViewInfo);
  with ViewInfo do
  begin
    Width := 2 * ((x2+1) div 13);
    Height := 2 * ((y2-10) div 10);
  end;
  X := Width div 2;
  Y := Height div 2;
  Style := 0;
  for J := 1 to 3 do
  begin
    for I := 1 to 4 do
    begin
      DrawBox(X, Y);
      Inc(X, (Width div 2) * 3);
    end;
    X := Width div 2;
    Inc(Y, (Height div 2) * 3);
  end;
  SetTextJustify(LeftText, TopText);
  WaitToGo;
end; { FillPatternPlay }

procedure ColorPlay;
{ Display all of the colors available for the current driver and mode }
var
  Color      : LongInt;
  Width, Wid : word;
  Height, Ht : word;
  Ofs        : word;
  Sx, Sy, Mx, My, X, Y : Word;
  I, J       : word;
  ViewInfo   : ViewPortType;

procedure DrawBox(X, Y : word; drawzr : boolean);
begin
  SetFillStyle(SolidFill, RealFillColor(Color));
  SetColor(RealDrawColor(Color));
  with ViewInfo do
    Bar(X, Y, X+Width, Y+Height);
  Rectangle(X, Y, X+Width, Y+Height);
  if Color = 0 then
  begin
    if drawzr then
    begin
      SetColor(RealDrawColor(WhitePixel));
      Rectangle(X, Y, X+Width, Y+Height);
    end;
  end;
  Color := Succ(Color);
end; { DrawBox }

function cRGB(R : longint; G : longint; B : longint) : LongInt;
begin
  if (GetMaxColor = 32767) then
    cRGB := (((R SHR 1) AND 31) shl 10)+(((G SHR 1) and 31) shl 5)+
            ((B SHR 1) and 31)
  else if (GetMaxColor = 65535) then
    cRGB := (((R SHR 1) AND 31) shl 11) OR (((G SHR 1) and 63) shl 5) OR
            ((B SHR 1) and 31)
  else
    cRGB := (R shl 18)+(G shl 10)+(B SHL 2);
end;

begin
  begin
    GetViewSettings(ViewInfo);
    Wid := ViewInfo.x2-ViewInfo.x1;
    Ht  := ViewInfo.y2-ViewInfo.y1;
    Mx := Wid div 2;
    My := Ht div 2;

    if (GetMaxColor = 255) then
    begin
      Width  := (Wid div 16)-1;
      Height := (Ht  div 16)-1;
      MainWindow('256 Color demonstration');

      X := (Mx - (Width+1)*8);
      Y := (My - (Height+1)*8);
      for I := 0 to 15 do
      begin
	for J := 0 to 15 do
	begin
	  Color := (I shl 4) + J;
          DrawBox(X,Y,true);
          Inc(X,Width+1);
        end;
        X := (Mx - (Width+1)*8);
        Inc(Y,Height+1);
      end;
    end
    else if (GetMaxColor = 15) then
    begin
      Height := (Ht div 16)-1;
      MainWindow('16 Color demonstration');

      X := 0;
      Y := 0;
      for I := 0 to 15 do
       begin
        Color := I;
        DrawBox(X,Y,true);
        Inc(Y,Height+1);
      end;
    end
    else
    begin
      if (GetMaxColor = 32767) then
        MainWindow('32768 Color demonstration')
      else if (GetMaxColor = 65535) then
        MainWindow('65536 Color demonstration')
      else if (GetMaxColor = 16777) then
        MainWindow('24 bit Color demonstration')
      else
        MainWindow('Color demonstration');

      Width  := (Wid shr 7)-1;
      Height := (Ht  shr 7)-1;
      Y := ((My - ((Height+1) shl 6)) shr 1);
      for I := 0 to 63 do
      begin
        X := (Mx - ((Width+1) shl 6)) shr 1;
        for J := 0 to 63 do
        begin
          color := cRGB(i,j,0);
          DrawBox(x,y,false);
          color := cRGB(i,0,j);
          DrawBox(x+Mx,y,false);
          color := cRGB(0,i,j);
          DrawBox(x,y+My,false);
          color := cRGB(i,j,(i+j) shr 1);
          DrawBox(x+Mx,y+My,false);
          Inc(X,Width+1);
        end;
        Inc(Y,Height+1);
      end;
{
      Height := (Height+1) shl 2;
      Width  := (Wid shr 8)-1;
      X := Mx - (Width shl 8);
      Y := Ht - (Height shl 2);

      for I := 0 to 255 do
      begin
        color := cRGB(i,0,0);
        DrawBox(x,y,false);
        color := cRGB(0,i,0);
        DrawBox(x,y+Height+1,false);
        color := cRGB(0,0,i);
        DrawBox(x,y+(Height+1) shl 1,false);
        Inc(X,Width+1);
      end; }
    end;
  end;
  WaitToGo;
end; { ColorPlay }

procedure PalettePlay;
{ Demonstrate the use of the SetRGBPalette command }
const
  XBars = 15;
  YBars = 10;
type
  RGBColor   = record
                 R, G, B : byte;
               end;
  VGAPalette = array[0..255] of RGBColor;

var
  I, J     : word;
  X, Y     : word;
  Color    : word;
  ViewInfo : ViewPortType;
  Width    : word;
  Height   : word;
  VGAPal   : VGAPalette;
  Rand     : integer;

procedure ReadDACBlock(Start, Count : integer; var Pal : VGAPalette);
var
  Regs : Registers;
begin
  with Regs do
  begin
    AH := $10;
    AL := $17;
    BX := Start;
    CX := Count;
    ES := Seg(Pal);
    DX := Ofs(Pal);
  end;
  Intr($10, Regs);
end;

procedure SetDACBlock(Start, Count : integer; var Pal : VGAPalette);
var
  Regs : Registers;
begin
  with Regs do
  begin
    AH := $10;
    AL := $12;
    BX := Start;
    CX := Count;
    ES := Seg(Pal);
    DX := Ofs(Pal);
  end;
  Intr($10, Regs);
end;

begin
  if (GetMaxColor <= 256) then
  begin
    ReadDACBlock(0, 256, VGAPal);
    MainWindow('SetRGBPalette demonstration');
    StatusLine('Press any key...');
    GetViewSettings(ViewInfo);
    with ViewInfo do
    begin
      Width := (x2-x1) div XBars;
      Height := (y2-y1) div YBars;
    end;
    X := 0; Y := 0;
    Color := 0;
    for J := 1 to YBars do
    begin
      for I := 1 to XBars do
      begin
        SetFillStyle(SolidFill, RealFillColor(Color));
        Bar(X, Y, X+Width, Y+Height);
        Inc(X, Width+1);
        Inc(Color);
        Color := Color mod 16;
      end;
      X := 0;
      Inc(Y, Height+1);
    end;
    repeat
      {SetPalette(Random(16), VGAPal[Random(256)]);}
      with VGAPal[Random(16)] do
        SetRGBPalette(Random(16), R, G, B);
    until KeyPressed;
    SetDACBlock(0, 256, VGAPal);
    WaitToGo;
  end;
end; { PalettePlay }

procedure PagingPlay;
{ Demonstrate setactivepage/setvisualpage }
var
  ViewInfo : ViewPortType;
  Ch       : Char;
begin
  SetActivePage(1);
  MainWindow('SetActivePage/SetVisualPage demo');
  StatusLine('Press any key for page 0...');
  SetVisualPage(1);
  SetActivePage(0);
  MainWindow('SetActivePage/SetVisualPage demo');
  GetViewSettings(ViewInfo);

  SetFillStyle(SolidFill, RealFillColor(GreenPixel));
  with ViewInfo do
  begin
    SetTextJustify(LeftText,CenterText);
    OutTextXY(10, (y2-y1) div 2, 'This is page 0');
    SetFillStyle(SolidFill, RealFillColor(GreenPixel));
    Bar(0,0,x2-x1,((y2-y1) div 2) - 10);
    OutTextXY(10,10, 'There should only be one green bar');
    OutTextXY(10,20, 'if paging is supported in this mode');

    SetActivePage(1);
    SetTextJustify(RightText, CenterText);
    OutTextXY((x2-x1)-10, (y2-y1) div 2, 'This is page 1');
        SetFillStyle(SolidFill, RealFillColor(GreenPixel));
    Bar(0,((y2-y1) div 2) + 10,x2-x1,y2-y1);
    SetActivePage(0);

    repeat until KeyPressed;
    Ch := ReadKey;
    SetVisualPage(0);
  end;
  WaitToGo;
end;

procedure CrtModePlay;
{ Demonstrate the use of RestoreCrtMode and SetGraphMode }
var
  ViewInfo : ViewPortType;
  Ch       : char;
begin
  MainWindow('SetGraphMode / RestoreCrtMode demo');
  GetViewSettings(ViewInfo);
  SetTextJustify(CenterText, CenterText);
  with ViewInfo do
  begin
    OutTextXY((x2-x1) div 2, (y2-y1) div 2, 'Now you are in graphics mode');
    StatusLine('Press any key for text mode...');
    repeat until KeyPressed;
    Ch := ReadKey;
    RestoreCrtmode;
    Writeln('Now you are in text mode.');
    Write('Press any key to go back to graphics...');
    repeat until KeyPressed;
    Ch := ReadKey;
    SetGraphMode(GetGraphMode);
    MainWindow('SetGraphMode / RestoreCrtMode demo');
    SetTextJustify(CenterText, CenterText);
    OutTextXY((x2-x1) div 2, (y2-y1) div 2, 'Back in graphics mode...');
  end;
  WaitToGo;
end; { CrtModePlay }

procedure LineStylePlay;
{ Demonstrate the predefined line styles available }
var
  Style    : word;
  Step     : word;
  X, Y     : word;
  ViewInfo : ViewPortType;

begin
  ClearDevice;
  DefaultColors;
  MainWindow('Pre-defined line styles');
  GetViewSettings(ViewInfo);
  with ViewInfo do
  begin
    X := 35;
    Y := 10;
    Step := (x2-x1) div 11;
    SetTextJustify(LeftText, TopText);
    OutTextXY(X, Y, 'NormWidth');
    SetTextJustify(CenterText, TopText);
    for Style := 0 to 3 do
    begin
      SetLineStyle(Style, 0, NormWidth);
      Line(X, Y+20, X, Y2-40);
      OutTextXY(X, Y2-30, Int2Str(Style));
      Inc(X, Step);
    end;
    Inc(X, 2*Step);
    SetTextJustify(LeftText, TopText);
    OutTextXY(X, Y, 'ThickWidth');
    SetTextJustify(CenterText, TopText);
    for Style := 0 to 3 do
    begin
      SetLineStyle(Style, 0, ThickWidth);
      Line(X, Y+20, X, Y2-40);
      OutTextXY(X, Y2-30, Int2Str(Style));
      Inc(X, Step);
    end;
  end;
  SetTextJustify(LeftText, TopText);
  WaitToGo;
end; { LineStylePlay }

procedure UserLineStylePlay;
{ Demonstrate user defined line styles }
var
  Style    : word;
  X, Y, I  : word;
  ViewInfo : ViewPortType;
begin
  MainWindow('User defined line styles');
  GetViewSettings(ViewInfo);
  with ViewInfo do
  begin
    X := 4;
    Y := 10;
    Style := 0;
    I := 0;
    while X < X2-4 do
    begin
      {$B+}
      Style := Style or (1 shl (I mod 16));
      {$B-}
      SetLineStyle(UserBitLn, Style, NormWidth);
      Line(X, Y, X, (y2-y1)-Y);
      Inc(X, 5);
      Inc(I);
      if Style = 65535 then
      begin
        I := 0;
        Style := 0;
      end;
    end;
  end;
  WaitToGo;
end; { UserLineStylePlay }


procedure SayGoodbye;
{ Say goodbye and then exit the program }
var
  ViewInfo : ViewPortType;
begin
  MainWindow('');
  GetViewSettings(ViewInfo);
  SetTextStyle(TriplexFont, HorizDir, 4);
  SetTextJustify(CenterText, CenterText);
  with ViewInfo do
    OutTextXY((x2-x1) div 2, (y2-y1) div 2, 'That''s all folks!');
  StatusLine('Press any key to quit...');
  repeat until KeyPressed;
end; { SayGoodbye }

begin { program body }
  ClrScr;
  writeln('VGA BGI Demo Program  Copyright(c) 1987,1989 Borland International, Inc.');
  writeln;
  Initialize;
  ReportStatus;
{  PagingPlay; }
  AspectRatioPlay;
  FillEllipsePlay;
  SectorPlay;
  WriteModePlay;
  ColorPlay;
  PalettePlay;
  PutPixelPlay;
  PutImagePlay;
  RandBarPlay;
  SolidBarPlay;
  BarPlay;
  Bar3DPlay;
  ArcPlay;
  CirclePlay;
  PiePlay;
  LineToPlay;
  LineRelPlay;
  LineStylePlay;
  UserLineStylePlay;
  TextDump;
  TextPlay;
  CrtModePlay;
  FillStylePlay;
  FillPatternPlay;
  PolyPlay;
  SayGoodbye;
  CloseGraph;
end.
