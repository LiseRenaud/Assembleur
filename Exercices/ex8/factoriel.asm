.386
.model flat, stdcall
option casemap:none

include \masm32\include\kernel32.inc
include \masm32\include\msvcrt.inc

includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\msvcrt.lib

.DATA
fmtRead  db "%d", 0                     ; format scanf : lecture d'un entier
fmtPrint db "Factorielle = %d", 10, 0   ; format printf : affichage résultat + saut de ligne

.DATA?
n   dd ?    ; entier saisi par l'utilisateur

.CODE

Factorielle PROC
    push ebp            ; sauvegarde ancien ebp
    mov  ebp, esp
    sub  esp, 4            ; réservation 1 variable locale : sauvegarde de n

    mov  eax, [ebp+8]      ; eax = n (arg)

    cmp  eax, 1             ; comparaison n et 1
    jg   recurse            ; si n > 1 → appel récursif

    ; cas de base : n <= 1
    mov  eax, 1         ; valeur de retour = 1
    jmp  end_fact       ; saut de l'appel récursif

recurse:
    mov  [ebp-4], eax      ; sauvegarder n dans la variable locale

    dec  eax               ; eax = n-1
    push eax               ; arg n-1
    call Factorielle       ; appel récursif eax = fact(n-1)

    mov  ecx, [ebp-4]      ; récupérer n
    imul eax, ecx          ; eax = n * fact(n-1)

end_fact:
    mov  esp, ebp       ; restauration pointeur de pile
    pop  ebp
    ret  4              ; nettoyage d'un argument
Factorielle ENDP


start:

    ; lire n
    push offset n           ; 2e arg scanf : adresse variable n
    push offset fmtRead     ; 1e arg scanf : format "%d"
    call crt_scanf          ; lecture entier et stockage dans n

    ; appeler Factorielle(n)
    push n              ; arg valeur de n
    call Factorielle    ; calcul factorielle n

    ; afficher le résultat
    push eax                ; 2e arg printf : factorielle n
    push offset fmtPrint    ; 1e arg printf : "Factorielle = %d\n"
    call crt_printf         ; affichage

    push 0              ; code retour 0
    call ExitProcess    ; fin
end start               ; début programme
