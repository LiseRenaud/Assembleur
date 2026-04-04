.386
.model flat, stdcall
option casemap:none

include \masm32\include\kernel32.inc
include \masm32\include\user32.inc
include \masm32\include\msvcrt.inc

includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\msvcrt.lib


.DATA
fmtABC db "a=%d  b=%d  c=%d", 10, 0     ; Format printf : affiche les 3 compteurs + saut de ligne
chaine db "abacabc", 0                  ; Chaîne à analyser (ASCIIZ)
.DATA?

.CODE


CountABC PROC
    push ebp            ; sauvegarde ancien EBP
    mov  ebp, esp
    sub  esp, 12        ; 3 variables locales réservées : a, b, c

    ; Initialiser les compteurs à 0
    mov DWORD PTR [ebp-4], 0   ; nb_a
    mov DWORD PTR [ebp-8], 0   ; nb_b
    mov DWORD PTR [ebp-12], 0  ; nb_c

    mov esi, [ebp+8]           ; adresse de la chaîne (arg 1)

count_loop:
    mov al, [esi]       ; lecture caractère suivant
    cmp al, 0           ; caractère nul ?
    je  end_count       ; oui --> fin du comptage

    cmp al, 'a'         ; lettre = a ?
    je  inc_a           ; incrément compteur a

    cmp al, 'b'         ; lettre = b ?
    je  inc_b           ; incrément compteur b

    cmp al, 'c'         ; lettre = c ?
    je  inc_c           ; incrément compteur c

    jmp next_char       ; vers caractère suivant

; incréments de a, b, c
inc_a:
    inc DWORD PTR [ebp-4]
    jmp next_char

inc_b:
    inc DWORD PTR [ebp-8]
    jmp next_char

inc_c:
    inc DWORD PTR [ebp-12]
    jmp next_char

next_char:
    inc esi             ; caractère suivant
    jmp count_loop      ; boucle

end_count:
    ; Chargement des résultats dans eax, ebx, ecx
    mov eax, [ebp-4]      ; nb de 'a'
    mov ebx, [ebp-8]      ; nb de 'b'
    mov ecx, [ebp-12]     ; nb de 'c'

    mov esp, ebp        ; restauration pointeur de pile
    pop ebp
    ret 4                 ; nettoyage 1 paramètre : adresse de la chaîne
CountABC ENDP

start:
    push offset chaine  ; arg = adresse de chaine
    call CountABC       ; lancement comptage

    ; eax = nb de 'a'
    ; ebx = nb de 'b'
    ; ecx = nb de 'c'

    push ecx            ; 4e arg printf : nombre c
    push ebx            ; 3e arg printf : nombre b
    push eax            ; 2e arg printf : nombre a
    push offset fmtABC  ; 1e arg printf : "a=%d  b=%d  c=%d\n"
    call crt_printf     ; affichage

    push 0              ; code sortie 0
    call ExitProcess    ; fin
end start               ; début programme
