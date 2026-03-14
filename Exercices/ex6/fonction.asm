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
fmtABC db "a=%d  b=%d  c=%d", 10, 0
chaine db "abacabc", 0
.DATA?

.CODE


CountABC PROC
    push ebp
    mov  ebp, esp
    sub  esp, 12              ; 3 variables locales : a, b, c

    ; Initialiser les compteurs à 0
    mov DWORD PTR [ebp-4], 0   ; nb_a
    mov DWORD PTR [ebp-8], 0   ; nb_b
    mov DWORD PTR [ebp-12], 0  ; nb_c

    mov esi, [ebp+8]           ; adresse de la chaîne

count_loop:
    mov al, [esi]
    cmp al, 0
    je  end_count

    cmp al, 'a'
    je  inc_a

    cmp al, 'b'
    je  inc_b

    cmp al, 'c'
    je  inc_c

    jmp next_char

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
    inc esi
    jmp count_loop

end_count:
    ; Charger les résultats dans eax, ebx, ecx
    mov eax, [ebp-4]      ; nb de 'a'
    mov ebx, [ebp-8]      ; nb de 'b'
    mov ecx, [ebp-12]     ; nb de 'c'

    mov esp, ebp
    pop ebp
    ret 4                 ; 1 paramètre : adresse de la chaîne
CountABC ENDP

start:
    push offset chaine
    call CountABC

    ; eax = nb de 'a'
    ; ebx = nb de 'b'
    ; ecx = nb de 'c'

    push ecx
    push ebx
    push eax
    push offset fmtABC
    call crt_printf

    push 0
    call ExitProcess
end start
