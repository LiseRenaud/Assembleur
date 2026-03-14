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
chaine db "bonjour le monde", 0
fmt    db "%s", 10, 0


.DATA?
; variables non-initialisees (bss)


.CODE
UpperCase PROC
    mov esi, eax        ; ESI = adresse de la chaîne

convert_loop:
    mov al, [esi]       ; lire le caractère
    cmp al, 0           ; fin de chaîne ?
    je end_convert

    cmp al, 'a'         ; si < 'a'
    jb skip
    cmp al, 'z'         ; si > 'z'
    ja skip

    sub al, 32          ; conversion en majuscule
    mov [esi], al       ; écrire le caractère modifié

skip:
    inc esi             ; caractère suivant
    jmp convert_loop

end_convert:
    ret
UpperCase ENDP

start:
    lea eax, chaine
    call UpperCase

    push offset chaine
    push offset fmt
    call crt_printf

    push 0
    call ExitProcess
end start