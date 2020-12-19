echo off
SET BGIVER=2
if "%1" == "" goto SelectType
if "%3" == "" goto setBGIVer
set BGIVER=
set BGIVER=%3
:setBGIVer
if %1 == t goto makeTweak
if %1 == s goto makeSuperVGA
goto SelectType

:makeSuperVGA
tasm /dBGIVERSION=%BGIVER% SVGA%2.asm,SVGA%2.obj ;
tlink /3 SVGA%2.obj
exe2bin SVGA%2.exe SVGA%2.bin
bgihdr SVGA%2 SVGA%2.bin SVGA%2.bgi SVGA%2.map
del SVGA%2.exe
del SVGA%2.obj
del SVGA%2.bin
del SVGA%2.map
goto Exit

:makeTweak
tasm /dBGIVERSION=%BGIVER% TWK%2.asm,TWK%2.obj ;
tlink /3 TWK%2.obj
exe2bin TWK%2.exe TWK%2.bin
bgihdr TWK%2 TWK%2.bin TWK%2.bgi TWK%2.map
del TWK%2.exe
del TWK%2.obj
del TWK%2.bin
del TWK%2.map
goto Exit

:SelectType
echo Usage: "makebgi [s|t] clr {version}"
echo Version defaults to BGI v2.0
echo For example: to make the Tweaked-16 color driver (v2.0) enter: "makebgi t 16"
echo              for BGI v3.0:  "makebgi t 16 3"

:Exit