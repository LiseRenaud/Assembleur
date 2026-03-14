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
fmtRead  db "%d", 0
fmtPrint db "%d ", 0
msgAsk   db "Entrez un entier positif : ", 0

.DATA?
n   dd ?
i   dd ?

.CODE

start:

    ; demander un entier
    push offset msgAsk
    call crt_printf

    ; lire l'entier
    push offset n
    push offset fmtRead
    call crt_scanf

    ; i = 1
    mov DWORD PTR [i], 1

boucle:
    ; si i > n → fin
    mov eax, [i]
    cmp eax, [n]
    jg fin

    ; tester si n % i == 0
    mov eax, [n]
    cdq
    idiv DWORD PTR [i]     ; EAX = n / i, EDX = reste

    cmp edx, 0
    jne pas_diviseur

    ; afficher i
    mov eax, [i]
    push eax
    push offset fmtPrint
    call crt_printf

pas_diviseur:
    ; i++
    inc DWORD PTR [i]
    jmp boucle

fin:
    ; retour à la ligne
    push 10
    call crt_putchar

    push 0
    call ExitProcess
end start
