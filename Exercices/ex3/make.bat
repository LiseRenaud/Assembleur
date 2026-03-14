@echo off
c:\masm32\bin\ml /c /Zd /coff Majuscule.asm
c:\\masm32\bin\Link /SUBSYSTEM:CONSOLE Majuscule.obj
pause