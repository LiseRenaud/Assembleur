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
fmtInt db "myst(%d) = %d", 10, 0    ; ; Format printf : affiche "myst(n) = résultat" + saut de ligne

.DATA?

.CODE

myst PROC
    push ebp        ; sauvegarde ancien EBP
    mov  ebp, esp
    sub  esp, 16    ; i, j, k, l (4 variables locales réservées)

    ; initialisation des variables locales
    ; j = 1
    mov DWORD PTR [ebp-8], 1

    ; k = 1
    mov DWORD PTR [ebp-12], 1

    ; i = 3
    mov DWORD PTR [ebp-4], 3

for_loop:
    ; if (i > n) break
    mov eax, [ebp-4]        ; i
    cmp eax, [ebp+8]        ; comparaison i et n
    jg end_for              ; si i > n --> fin de boucle

    ; l = j + k
    mov eax, [ebp-8]      ; j
    add eax, [ebp-12]     ; j + k
    mov [ebp-16], eax     ; l = j + k

    ; j = k
    mov eax, [ebp-12]   ; k
    mov [ebp-8], eax    ; j = k

    ; k = l
    mov eax, [ebp-16]   ; l
    mov [ebp-12], eax   ; k = l

    ; i++
    inc DWORD PTR [ebp-4]

    jmp for_loop    ; retour au début de la boucle

end_for:
    mov eax, [ebp-12]     ; return k

    mov esp, ebp        ; restauration pointeur de pile
    pop ebp
    ret 4               ; nettoyage 1 argument
myst ENDP

start:
    push 10               ; n = 10
    call myst             ; résultat dans EAX

    push eax                ; 3e arg printf : résultat
    push 10                 ; 2e arg printf : n
    push offset fmtInt      ; 1e arg printf : "myst(%d) = %d\n"
    call crt_printf         ; affichage

    push 0                  ; code retour 0
    call ExitProcess        ; fin de processus
end start                   ; début du programme
