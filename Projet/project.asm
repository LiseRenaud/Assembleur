.386
.model flat, stdcall
option casemap:none

include \masm32\include\kernel32.inc
include \masm32\include\msvcrt.inc

includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\msvcrt.lib

.DATA
fmtRead  db "%d", 0

.DATA?
n   dd ?

.CODE

Factorielle PROC
    
Factorielle ENDP


start:

    ; lire n
    push offset n
    push offset fmtRead
    call crt_scanf

    ; 
    push n
    call Factorielle

    ; afficher le résultat
    push eax
    push offset fmtPrint
    call crt_printf

    push 0
    call ExitProcess
end start
