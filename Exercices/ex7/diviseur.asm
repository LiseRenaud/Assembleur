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
fmtRead  db "%d", 0     ; format scanf : lecture d'un entier
fmtPrint db "%d ", 0    ; format printf : affiche un entier suivi d'un espace
msgAsk   db "Entrez un entier positif : ", 0    ; message d'invite

.DATA?
n   dd ?    ; entier saisi
i   dd ?    ; compteur de boucle (diviseur candidat testé)

.CODE

start:

    ; demander un entier
    push offset msgAsk  ; message
    call crt_printf ; affichage du message

    ; lire l'entier
    push offset n           ; 2e arg scanf : adresse variable n
    push offset fmtRead     ; 1e arg scanf : format "%d"
    call crt_scanf          ; lecture de l'entier et stockage dans n

    ; i = 1
    mov DWORD PTR [i], 1    ; i = 1 (diviseurs à partir de 1)

boucle:
    ; si i > n → fin
    mov eax, [i]        ; eax = i candidat courant
    cmp eax, [n]        ; comparaison i et n
    jg fin              ; i > n --> tous les diviseurs sont testés

    ; tester si n % i == 0
    mov eax, [n]
    cdq     ; étend eax sur edx:eax
    idiv DWORD PTR [i]     ; division signée : EAX = n / i, EDX = reste

    cmp edx, 0              ; reste nul ?
    jne pas_diviseur        ; non --> i ne divise pas n, on passe

    ; afficher i
    mov eax, [i]            ; i diviseur confirmé
    push eax                ; 2e arg printf : valeur de i
    push offset fmtPrint    ; 1e arg printf : "%d"
    call crt_printf         ; affichage

pas_diviseur:
    ; i++
    inc DWORD PTR [i]   ; incrément
    jmp boucle          ; retour au début

fin:
    ; retour à la ligne
    push 10             ; argument saut de ligne
    call crt_putchar    ; affichage

    push 0              ; code retour 0
    call ExitProcess    ; fin
end start               ; début programme
