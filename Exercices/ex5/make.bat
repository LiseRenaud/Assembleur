@echo off
c:\masm32\bin\ml /c /Zd /coff fonction.asm
c:\\masm32\bin\Link /SUBSYSTEM:CONSOLE fonction.obj
pause