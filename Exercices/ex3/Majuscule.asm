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
    push ebp                ; sauvegarde ancien EBP
    mov  ebp, esp

    mov  esi, [ebp+8]       ; adresse de la chaîne

convert_loop:
    mov  al, [esi]          ; lecture caractère suivant
    cmp  al, 0              ; caractère nul (fin de chaine) ?
    je   end_convert        ; oui --> fin de conversion

    cmp  al, 'a'            ; caractère avant 'a' en ascii ?
    jb   skip               ; pas une minuscule, on passe
    cmp  al, 'z'            ; caractère après 'z' en ascii ?
    ja   skip               ; pas une minuscule, on passe

    sub  al, 32             ; conversion (écart de 32 en ascii)
    mov  [esi], al          ; écriture du caractère converti à la même position en mémoire

skip:
    inc  esi                ; avance au caractère suivant
    jmp  convert_loop       ; boucle

end_convert:
    pop  ebp                ; restauration EBP
    ret  4                  ; suppression d'1 argument = 4 octets
UpperCase ENDP


MetEnMajuscules PROC
; fonction enveloppe d'UpperCase
    push ebp                ; sauvegarde ancien EBP
    mov  ebp, esp

    mov  eax, [ebp+8]       ; adresse chaine
    push eax                ; adresse comme argument à UpperCase
    call UpperCase          ; appel UpperCase (nettoyage auto de l'arg)

    pop  ebp                ; restauration EBP
    ret  4                  ; nettoyage d'un argument
MetEnMajuscules ENDP


start:
    push offset chaine      ; arg adresse texte
    call MetEnMajuscules    ; conversion

    push offset chaine      ; 2e argument de printf = chaine
    push offset fmt         ; 1e argument de printf = format "%s\n"
    call crt_printf         ; affichage

    push 0                  ; code retour 0
    call ExitProcess        ; fin processus
end start                   ; début du programme
