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
chaine db "bonjour le monde", 0     ; chaine à traiter
fmt    db "%s", 10, 0               ; format printf générique : chaine + saut de ligne
fmtStr db "%s", 10, 0               ; format printf pour afficher la chaine convertie
fmtInt db "Longueur = %d", 10, 0    ; format printf pour afficher la longueur de la chaine


.DATA?
; variables non-initialisees (bss)


.CODE
UpperCase PROC
    push ebp                sauvegarde ancien EBP
    mov  ebp, esp

    mov  esi, [ebp+8]       ; adresse de la chaîne

convert_loop:
    mov  al, [esi]          ; lecture caractère courant
    cmp  al, 0              ; caractère nul ?
    je   end_convert        ; oui --> fin de conversion

    cmp  al, 'a'            ; caractrère avant 'a' en ascii ?
    jb   skip               ; oui --> on passe
    cmp  al, 'z'            ; caractère après 'z' en ascii ?
    ja   skip               ; oui --> on passe

    sub  al, 32             ; conversion (+32 en ascii)
    mov  [esi], al          ; écriture du caractère au même emplacement mémoire

skip:
    inc  esi                ; avancer au caractère suivant
    jmp  convert_loop

end_convert:
    pop  ebp                ; restauration EBP
    ret  4                  ; nettoie 1 argument = 4 octets
UpperCase ENDP

CountChars PROC
    push ebp            ; sauvegarde EBP
    mov  ebp, esp

    mov  esi, [ebp+8]   ; adresse de la chaîne
    xor  ecx, ecx       ; compteur = 0

count_loop:
    mov  al, [esi]      ; lecture caractère suivant
    cmp  al, 0          ; caractère nul ?
    je   end_count      ; oui --> fin comptage

    inc  ecx            ; compteur++
    inc  esi            ; caractère suivant
    jmp  count_loop

end_count:
    mov  eax, ecx       ; résultat compteur dans EAX

    pop  ebp            ; restauration EBP
    ret  4              ; netoie 1 argument = 4 octets
CountChars ENDP

MetEnMajuscules PROC
    push ebp            ; sauvegarde ancien EBP
    mov  ebp, esp

    mov  eax, [ebp+8]   ; récupérer l'adresse de la chaine
    push eax            ; la repasser à UpperCase
    call UpperCase      ; appel

    pop  ebp            ; restauration EBP
    ret  4                 ; nettoyer l’argument
MetEnMajuscules ENDP

CompterSousProgramme PROC
    push ebp            ; sauvegarde ancien EBP
    mov  ebp, esp

    mov  eax, [ebp+8]   ; récupérer l'adresse de la chaine
    push eax            ; la repasser à CountChars
    call CountChars     ; résultat dans EAX

    pop  ebp            ; restauration EBP
    ret  4              ; nettoyage d'un argument
CompterSousProgramme ENDP

start:
    ; mettre en majuscules
    push offset chaine      ; argument chaine originale
    call MetEnMajuscules

    ; compter les caractères
    push offset chaine          ; argument chaine deja convertie
    call CompterSousProgramme   ; résultat dans EAX

    ; afficher le résultat
    push eax                    ; 2e arg longueur
    push offset fmtInt          ; 1e arg "Longueur = %d\n"
    call crt_printf             ; affichage

    ; afficher la chaîne modifiée
    push offset chaine          ; 2e arg chaine
    push offset fmtStr          ; 1e arg "%s\n"
    call crt_printf             ; affichage

    push 0              ; code retour 0
    call ExitProcess    ; exit
end start               ; début programme

