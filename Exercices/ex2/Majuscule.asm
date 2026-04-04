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
chaine db "bonjour le monde", 0 ; chaine a convertir en majuscules
fmt    db "%s", 10, 0           ; format : chaine puis saut de ligne


.DATA?
; variables non-initialisees (bss)


.CODE
UpperCase PROC
    mov esi, eax        ; ESI = adresse de la chaîne

convert_loop:
    mov al, [esi]       ; lire le caractère
    cmp al, 0           ; fin de chaîne ?
    je end_convert

    cmp al, 'a'         ; si < 'a' dans la table ascii
    jb skip             ; skip car pas minuscule
    cmp al, 'z'         ; si > 'z' dans la table ascii
    ja skip             ; skip car pas minuscule

    sub al, 32          ; conversion en majuscule
    mov [esi], al       ; écrire le caractère modifié

skip:
    inc esi             ; caractère suivant
    jmp convert_loop

end_convert:
    ret             ; retour à l'appelant
UpperCase ENDP

start:
    lea eax, chaine     ; eax adresse chaine a convertir
    call UpperCase      ; conversion

    push offset chaine  ; 2e arg de printf : chaine à afficher
    push offset fmt     ; 1e arg de printf : format "%s\n"
    call crt_printf     ; affichage

    push 0              ; code retour 0
    call ExitProcess    ; fin processus
end start               ; début du programme