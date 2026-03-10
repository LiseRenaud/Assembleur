.386
.model flat,stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\gdi32.inc
include c:\masm32\include\gdiplus.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\msvcrt.inc

includelib c:\masm32\lib\gdi32.lib
includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\user32.lib
includelib c:\masm32\lib\msvcrt.lib

.DATA
; variables initialisees
titre     db    "Hello World : %d",10,0
Message     db     "Bonjour en Français",10,0
strCommand db "Pause",13,10,0

.DATA?
; variables non-initialisees (bss)

.CODE
start:
        push 0
        push offset titre
        push offset Message
        push 0
		call MessageBoxA
		
		invoke crt_system, offset strCommand
		mov eax, 0
	    invoke	ExitProcess,eax

end start

