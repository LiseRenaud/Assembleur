@echo off
c:\masm32\bin\ml /c /Zd /coff factoriel.asm
c:\\masm32\bin\Link /SUBSYSTEM:CONSOLE factoriel.obj
pause