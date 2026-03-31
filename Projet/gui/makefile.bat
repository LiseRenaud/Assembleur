@echo off

set MASM=C:\masm32

%MASM%\bin\ml /c /coff gui.asm

%MASM%\bin\link gui.obj ^
/SUBSYSTEM:WINDOWS ^
/LIBPATH:%MASM%\lib ^
kernel32.lib user32.lib

pause