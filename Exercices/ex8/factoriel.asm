.386
.model flat, stdcall
option casemap:none

include \masm32\include\kernel32.inc
include \masm32\include\msvcrt.inc

includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\msvcrt.lib

.DATA
fmtRead  db "%d", 0
fmtPrint db "Factorielle = %d", 10, 0

.DATA?
n   dd ?

.CODE

Factorielle PROC
    push ebp
    mov  ebp, esp
    sub  esp, 4            ; 1 variable locale : sauvegarde de n

    mov  eax, [ebp+8]      ; n

    cmp  eax, 1
    jg   recurse           ; si n > 1 → appel récursif

    ; cas de base : n <= 1
    mov  eax, 1
    jmp  end_fact

recurse:
    mov  [ebp-4], eax      ; sauvegarder n dans la variable locale

    dec  eax               ; n-1
    push eax
    call Factorielle       ; eax = fact(n-1)

    mov  ecx, [ebp-4]      ; récupérer n
    imul eax, ecx          ; eax = n * fact(n-1)

end_fact:
    mov  esp, ebp
    pop  ebp
    ret  4
Factorielle ENDP


start:

    ; lire n
    push offset n
    push offset fmtRead
    call crt_scanf

    ; appeler Factorielle(n)
    push n
    call Factorielle

    ; afficher le résultat
    push eax
    push offset fmtPrint
    call crt_printf

    push 0
    call ExitProcess
end start
