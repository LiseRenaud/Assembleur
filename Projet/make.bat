@echo off
c:\masm32\bin\ml /c /Zd /coff project.asm
c:\\masm32\bin\Link /SUBSYSTEM:CONSOLE project.obj
pause