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
titre     db    "Hello World",10,0              ; titre boite de dialogue
Message     db     "Bonjour en Français",10,0   ; texte affiché
strCommand db "Pause",13,10,0                   ; commande à exécuter : pause + CRLF + '\0'

.DATA?
; variables non-initialisees (bss)

.CODE
start:
        push 0              ; uType : MB_OK (bouton OK uniquement, icône par défaut)
        push offset titre   ; titre fenêtre
        push offset Message ; corps texte
        push 0              ; pas de fenêtre parente
		call MessageBoxA    ; affiche boîte de dialogue en attendant le OK
		
		invoke crt_system, offset strCommand    ; pause dans le shell
		mov eax, 0                              ; code retour 0
	    invoke	ExitProcess,eax                 ; fin de processus

end start   ; début du programme

