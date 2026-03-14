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
fmtInt db "myst(%d) = %d", 10, 0

.DATA?

.CODE

myst PROC
    push ebp
    mov  ebp, esp
    sub  esp, 16          ; i, j, k, l (4 variables locales)

    ; j = 1
    mov DWORD PTR [ebp-8], 1

    ; k = 1
    mov DWORD PTR [ebp-12], 1

    ; i = 3
    mov DWORD PTR [ebp-4], 3

for_loop:
    ; if (i > n) break
    mov eax, [ebp-4]      ; i
    cmp eax, [ebp+8]      ; n
    jg end_for

    ; l = j + k
    mov eax, [ebp-8]      ; j
    add eax, [ebp-12]     ; + k
    mov [ebp-16], eax     ; l

    ; j = k
    mov eax, [ebp-12]
    mov [ebp-8], eax

    ; k = l
    mov eax, [ebp-16]
    mov [ebp-12], eax

    ; i++
    inc DWORD PTR [ebp-4]

    jmp for_loop

end_for:
    mov eax, [ebp-12]     ; return k

    mov esp, ebp
    pop ebp
    ret 4
myst ENDP

start:
    push 10               ; n = 10
    call myst             ; résultat dans EAX

    push eax              ; résultat
    push 10               ; n
    push offset fmtInt
    call crt_printf

    push 0
    call ExitProcess
end start
