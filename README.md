# SvgaBGI
SuperVGA BGI Drivers for Turbo C/Turbo Pascal/Borland C++
***************************************************************************
                        Copyright (c) 1990-1994
                      Jordan Hargraphix Software
                         All Rights Reserved

    PORTIONS COPYRIGHT JOHN BRIDGES, 1990- 1993 (Svga detect & bankswitch)
              CHRISTOPHER MORGAN, 1984 (Bresenham's algorithm)
              FINN THOEGERSEN, 1991-94 (Svga detect & bankswitch)
***************************************************************************

Here they are! The SuperVGA/Tweak BGI drivers you have all been waiting for! ;->

  These drivers support a wide range of VGA cards, and should work on
all major brands.

Card types supported: (SuperVGA drivers)
  Acumos, Ahead, Avance Logic 2101, ATI, Chips & Tech, Cirrus Logic, Compaq, 
Everex, Genoa, MXIC68000, NCR, Oak, Primus 2000, Paradise, Realtek, S3
Trident (both 8800 and 8900, 9000), Tseng (both ET3000 and ET4000) and Video7.
  These drivers will also work on video cards with VESA capability.
  The tweaked drivers will work on any register-compatible VGA card.

I have not tested these drivers on all these card types, so I can not guarantee
perfect operation with your card.  I have tested them extensively on Tseng ET4000,
S3 and Paradise cards, and have had no problems.  If you experience problems with 
the driver on your card, try loading a VESA driver first.

----------------------------------------------------------------------------
        BGIv3.0 drivers support protected mode under Borland Pascal 7.0.

        Registration fees cover both v2.0 and v3.0 source code.
        Any current Borland/Turbo Pascal or C/C++ compiler can use BGIv2.0
        in real mode.  Only Borland Pascal 7.0 and Turbo Pascal 7.0 currently
        support BGI v3.0; Borland Pascal 7.0 needs BGIv3.0 to work in 
        protected mode.  The BGIv3.0 drivers are in the \BGI30 directory.
----------------------------------------------------------------------------

Modes currently supported:
  SuperVGA 16-color
   0) Standard EGA/VGA 320x200x16
   1) Standard EGA/VGA 640x200x16
   2) Standard EGA/VGA 640x350x16
   3) Standard VGA 640x480x16
   4) SuperVGA/VESA 800x600x16
   5) SuperVGA/VESA 1024x768x16
   6) SuperVGA/VESA 1280x1024x16

  SuperVGA 256-color
   0) Standard VGA/MCGA 320x200x256
   1) 256k Svga/VESA 640x400x256
   2) 512k Svga/VESA 640x480x256
   3) 512k Svga/VESA 800x600x256
   4) 1024k Svga/VESA 1024x768x256
   5) 256k Svga 640x350x256
   6) 1280k+ VESA 1280x1024x256

 * SuperVGA 32768-color BGI driver for HiColor cards
   
  SuperVGA 32768-color
   0) 320x200x32768
   1) 640x350x32768
   2) 640x400x32768
   3) 640x480x32768
   4) 800x600x32768
   5) 1024x768x32768
   6) 1280x1024x32768

 * SuperVGA 65536-color BGI driver for HiColor cards

  SuperVGA 65536-color
   0) 320x200x65536
   1) 640x350x65536
   2) 640x400x65536
   3) 640x480x65536
   4) 800x600x65536
   5) 1024x768x65536
   6) 1280x1024x65536

 * NEW SuperVGA 24-bit color BGI driver for TrueColor cards

  SuperVGA 24-bit color
   0) 320x200x24-bit
   1) 640x350x24-bit
   2) 640x400x24-bit
   3) 640x480x24-bit
   4) 800x600x24-bit
   5) 1024x768x24-bit
   6) 1280x1024x24-bit

  * WARNING: The tweaked drivers do not use standard BIOS modes, instead
    they program the CRTC directly.  You must have a register-compatible
    VGA card to use these drivers. You must also be sure that your monitor
    can handle the sync rates (the sync COULD damage your monitor)

  Tweaked 16-color
   0) 704x528x16
   1) 720x540x16
   2) 736x552x16
   3) 752x564x16
   4) 768x576x16
   5) 784x588x16
   6) 800x600x16

  Tweaked 256-color
   0) 320x400x256
   1) 320x480x256
   2) 360x480x256
   3) 376x564x256
   4) 400x564x256
   5) 400x600x256
   6) 320x240x256
   7) 360x350x256

 * SuperVGA driver for S3 cards. (Orchid Farenheit 1280, Diamond Stealth)
   Uses extended features of the S3 chip to provide enhanced performance.

  S3 Accelerator 16/256/32768-color
   0) 640x480x256
   1) 800x600x256
   2) 1024x768x256
   3) 800x600x16
   4) 1024x768x16
   5) 1280x960x16
   6) 1280x1024x16
   7) 640x480x32768

 OTHER PRODUCTS:

  * HGXMOUSE TSR for supporting those tricky video modes your mouse driver
    doesn't know about.  My BGI drivers are fully integrated with the TSR,
    and will provide automatic mouse support in all modes if the TSR and
    mouse driver are loaded.

    Features:
      Support for the mouse cursor in 16, 256, 32k, 64k and true color
       SuperVGA modes, as well as tweaked 16 and 256 color modes.
      Support for a graphical text mode cursor (ala Norton)
      Support for the hardware cursor on systems that support it.
         (Cirrus 54xx, S3, Paradise)
      Easy to use API so you can use the mouse cursor in your own programs.
       (without needing to use my BGI drivers).
      Large cursor support (currently up to 32x32).
      Ability to set the cursor foreground and background colors
      Bitmap cursor support (multicolored cursors)

----------------------------------------------------------------------------
INSTALLATION:
  Using the driver in existing programs is easy. (If you have the source)

  Check the files INITSVGA.C and INITSVGA.PAS for examples of installation
into C and Pascal programs.

----------------------------------------------------------------------------
NOTE:

 * See the file FAQ.DOC for frequently asked questions.

 * The .CHR files needed by the VGADEMO program are version 1.00 (dated
   October 1987), so if the fonts do not work properly with the demo program,
   you are probably using the newer fonts (eg. 1.1 dated June 1989 do not work
   properly).  This is a fault of the BGI kernel that the demo program was
   compiled with (Turbo Pascal 5.5 doesn't recognize the newer version)

----------------------------------------------------------------------------
WARNING: The drivers do not test to see if the card installed is
actually a VGA card (If the Svga drivers do not detect a SuperVGA card, they 
treat the card as a standard VGA), so DO NOT use the drivers if you do not 
have a VGA card installed. (Svga16 will work on EGA cards)

-------------------------------------------------------------------------
REGISTRATION:
  I have decided to release these drivers free of charge, although donations 
would be greatly appreciated and certainly expedite the release of future 
versions. :->
  The drivers have not been crippled in any way, though beta releases of new
drivers may have some functions yet unimplemented.  

Registration fees:        ( Price includes both BGIv2.0 and BGIv3.0 drivers )

     ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
     ³  HGXMOUSE                          $40  ³
     ³                                         ³
     ³  SuperVGA BGI S3                   $30  ³
     ³  SuperVGA BGI 32768                $30  ³
     ³  SuperVGA BGI 65536                $30  ³
     ³  SuperVGA BGI 24-bit               $30  ³
     ³  SuperVGA BGI 256                  $30  ³
     ³  SuperVGA BGI 16                   $30  ³
     ³  Tweak 16                          $30  ³
     ³  Tweak 256                         $30  ³
     ³                                         ³
     ³  Any two:                          $40  ³
     ³  Any three:                        $50  ³
     ³  Any four:                         $60  ³
     ³  Any five:                         $70  ³
     ³  Any six:                          $80  ³
     ³  Any seven:                        $90  ³
     ³  All eight:                        $100 ³
     ³                                         ³
     ³  Order one or more BGI drivers and get  ³
     ³  HGXMOUSE for only an additional $25.   ³
     ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

