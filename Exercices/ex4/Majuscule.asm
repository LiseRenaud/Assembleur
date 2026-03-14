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
fmtStr db "%s", 10, 0
fmtInt db "Longueur = %d", 10, 0


.DATA?
; variables non-initialisees (bss)


.CODE
UpperCase PROC
    push ebp
    mov  ebp, esp

    mov  esi, [ebp+8]      ; adresse de la chaîne

convert_loop:
    mov  al, [esi]
    cmp  al, 0
    je   end_convert

    cmp  al, 'a'
    jb   skip
    cmp  al, 'z'
    ja   skip

    sub  al, 32
    mov  [esi], al

skip:
    inc  esi
    jmp  convert_loop

end_convert:
    pop  ebp
    ret  4                 ; 1 argument = 4 octets
UpperCase ENDP

CountChars PROC
    push ebp
    mov  ebp, esp

    mov  esi, [ebp+8]   ; adresse de la chaîne
    xor  ecx, ecx       ; compteur = 0

count_loop:
    mov  al, [esi]
    cmp  al, 0
    je   end_count

    inc  ecx            ; compteur++
    inc  esi            ; caractère suivant
    jmp  count_loop

end_count:
    mov  eax, ecx       ; résultat dans EAX

    pop  ebp
    ret  4              ; 1 argument = 4 octets
CountChars ENDP

MetEnMajuscules PROC
    push ebp
    mov  ebp, esp

    mov  eax, [ebp+8]      ; récupérer l'adresse
    push eax               ; la repasser à UpperCase
    call UpperCase

    pop  ebp
    ret  4                 ; nettoyer l’argument
MetEnMajuscules ENDP

CompterSousProgramme PROC
    push ebp
    mov  ebp, esp

    mov  eax, [ebp+8]   ; récupérer l'adresse
    push eax            ; la repasser à CountChars
    call CountChars     ; résultat dans EAX

    pop  ebp
    ret  4
CompterSousProgramme ENDP

start:
    ; mettre en majuscules
    push offset chaine
    call MetEnMajuscules

    ; compter les caractères
    push offset chaine
    call CompterSousProgramme   ; résultat dans EAX

    ; afficher le résultat
    push eax
    push offset fmtInt
    call crt_printf

    ; afficher la chaîne modifiée
    push offset chaine
    push offset fmtStr
    call crt_printf

    push 0
    call ExitProcess
end start

