@echo off
c:\masm32\bin\ml /c /Zd /coff cli.asm
c:\\masm32\bin\Link /SUBSYSTEM:CONSOLE cli.obj
pause