.386
.model flat, stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\msvcrt.inc
includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\msvcrt.lib

; ---------------------------------------------------------------------------
; Constantes locales
; ---------------------------------------------------------------------------
BUF_SIZE        equ 520     ; 2 * MAX_PATH, marge pour path + "\*.*"
WIN32_FIND_DATA_SIZE equ 592 ; sizeof(WIN32_FIND_DATA) en x86

.data
    fmt_entry   db "%s", 13, 10, 0
    str_star    db "\*.*", 0
    str_slash   db "\", 0
    str_dot     db ".", 0
    str_dotdot  db "..", 0
    str_cwd_err db "Erreur: impossible d'obtenir le repertoire courant.", 13, 10, 0

.code

; ===========================================================================
; my_strcpy(dst, src)
;   Copie la chaîne src dans dst (inclut le '\0' terminal).
;   Convention cdecl : appelant nettoie la pile.
; ===========================================================================
my_strcpy:
    push ebp
    mov  ebp, esp
    push esi
    push edi

    mov  edi, [ebp + 8]     ; dst
    mov  esi, [ebp + 12]    ; src

@@strcpy_loop:
    mov  al, [esi]
    mov  [edi], al
    cmp  al, 0
    je   @@strcpy_done
    inc  esi
    inc  edi
    jmp  @@strcpy_loop

@@strcpy_done:
    pop  edi
    pop  esi
    pop  ebp
    ret

; ===========================================================================
; my_strcat(dst, src)
;   Concatène src à la fin de dst.
; ===========================================================================
my_strcat:
    push ebp
    mov  ebp, esp
    push esi
    push edi

    mov  edi, [ebp + 8]     ; dst
    mov  esi, [ebp + 12]    ; src

    ; Avancer edi jusqu'au '\0' de dst
@@strcat_find_end:
    cmp  byte ptr [edi], 0
    je   @@strcat_append
    inc  edi
    jmp  @@strcat_find_end

@@strcat_append:
    mov  al, [esi]
    mov  [edi], al
    cmp  al, 0
    je   @@strcat_done
    inc  esi
    inc  edi
    jmp  @@strcat_append

@@strcat_done:
    pop  edi
    pop  esi
    pop  ebp
    ret

; ===========================================================================
; is_dots(name)  →  eax = 1 si "." ou "..", 0 sinon
; ===========================================================================
is_dots:
    push ebp
    mov  ebp, esp
    push esi

    mov  esi, [ebp + 8]     ; name

    cmp  byte ptr [esi], '.'
    jne  @@not_dot

    ; premier car = '.'
    cmp  byte ptr [esi + 1], 0
    je   @@is_dot           ; juste "."

    cmp  byte ptr [esi + 1], '.'
    jne  @@not_dot

    cmp  byte ptr [esi + 2], 0
    je   @@is_dot           ; juste ".."

@@not_dot:
    mov  eax, 0
    jmp  @@dots_done

@@is_dot:
    mov  eax, 1

@@dots_done:
    pop  esi
    pop  ebp
    ret

; ===========================================================================
; explore(path_ptr)
;
;   Liste récursivement tous les fichiers et dossiers sous path_ptr.
;
;   Stack frame locale  (tous les buffers sont sur la pile pour que chaque
;   niveau récursif ait ses propres copies) :
;
;       [ebp -   4]          hFind           (HANDLE, 4 octets)
;       [ebp -   4 - WIN32_FIND_DATA_SIZE]
;                            findData        (WIN32_FIND_DATA)
;       [ebp -   4 - WIN32_FIND_DATA_SIZE - BUF_SIZE]
;                            searchBuf       (chemin + "\*.*\0")
;       [ebp -   4 - WIN32_FIND_DATA_SIZE - 2*BUF_SIZE]
;                            childBuf        (chemin + "\" + name)
;
;   Taille totale réservée = 4 + 592 + 520 + 520 = 1636 octets
; ===========================================================================

; Offsets des variables locales par rapport à ebp
LOCAL_HFIND       equ -4
LOCAL_FINDDATA    equ -(4 + WIN32_FIND_DATA_SIZE)
LOCAL_SEARCHBUF   equ -(4 + WIN32_FIND_DATA_SIZE + BUF_SIZE)
LOCAL_CHILDBUF    equ -(4 + WIN32_FIND_DATA_SIZE + 2*BUF_SIZE)
LOCAL_TOTAL       equ   4 + WIN32_FIND_DATA_SIZE + 2*BUF_SIZE

; Offset du champ cFileName dans WIN32_FIND_DATA
; dwFileAttributes(4) + ftCreationTime(8) + ftLastAccessTime(8)
; + ftLastWriteTime(8) + nFileSizeHigh(4) + nFileSizeLow(4)
; + dwReserved0(4) + dwReserved1(4) = 44 octets avant cFileName
CFILENAME_OFFSET  equ 44

explore:
    push ebp
    mov  ebp, esp

    ; Réserver l'espace pour toutes les variables locales
    sub  esp, LOCAL_TOTAL

    push ebx
    push esi
    push edi

    ; -----------------------------------------------------------------------
    ; Construire searchBuf = path + "\*.*"
    ; -----------------------------------------------------------------------
    lea  eax, [ebp + LOCAL_SEARCHBUF]
    push [ebp + 8]              ; src  = path_ptr
    push eax                    ; dst  = searchBuf
    call my_strcpy
    add  esp, 8

    lea  eax, [ebp + LOCAL_SEARCHBUF]
    push offset str_star        ; src  = "\*.*"
    push eax                    ; dst  = searchBuf
    call my_strcat
    add  esp, 8

    ; -----------------------------------------------------------------------
    ; FindFirstFileA(searchBuf, &findData)
    ; -----------------------------------------------------------------------
    lea  eax, [ebp + LOCAL_FINDDATA]
    push eax
    lea  eax, [ebp + LOCAL_SEARCHBUF]
    push eax
    call FindFirstFileA         ; stdcall, pas besoin de nettoyer
    mov  [ebp + LOCAL_HFIND], eax

    cmp  eax, INVALID_HANDLE_VALUE
    je   @@explore_end

    ; -----------------------------------------------------------------------
    ; Boucle principale : traiter chaque entrée
    ; -----------------------------------------------------------------------
@@explore_loop:

    ; --- Pointeur sur cFileName ---
    lea  esi, [ebp + LOCAL_FINDDATA + CFILENAME_OFFSET]

    ; --- Ignorer "." et ".." ---
    push esi
    call is_dots
    add  esp, 4
    cmp  eax, 1
    je   @@explore_next

    ; --- Construire childBuf = path + "\" + cFileName ---
    lea  eax, [ebp + LOCAL_CHILDBUF]
    push [ebp + 8]              ; src  = path_ptr
    push eax                    ; dst  = childBuf
    call my_strcpy
    add  esp, 8

    lea  eax, [ebp + LOCAL_CHILDBUF]
    push offset str_slash       ; src  = "\"
    push eax                    ; dst  = childBuf
    call my_strcat
    add  esp, 8

    lea  eax, [ebp + LOCAL_CHILDBUF]
    push esi                    ; src  = cFileName
    push eax                    ; dst  = childBuf
    call my_strcat
    add  esp, 8

    ; --- Afficher le chemin complet ---
    lea  eax, [ebp + LOCAL_CHILDBUF]
    push eax
    push offset fmt_entry
    call crt_printf
    add  esp, 8

    ; --- Si c'est un dossier → récursion ---
    mov  eax, [ebp + LOCAL_FINDDATA]    ; dwFileAttributes
    and  eax, FILE_ATTRIBUTE_DIRECTORY
    cmp  eax, 0
    je   @@explore_next

    lea  eax, [ebp + LOCAL_CHILDBUF]
    push eax
    call explore
    add  esp, 4

@@explore_next:
    ; FindNextFileA(hFind, &findData)
    lea  eax, [ebp + LOCAL_FINDDATA]
    push eax
    push [ebp + LOCAL_HFIND]
    call FindNextFileA
    cmp  eax, 0
    jne  @@explore_loop

    ; --- Fermer le handle ---
    push [ebp + LOCAL_HFIND]
    call FindClose

@@explore_end:
    pop  edi
    pop  esi
    pop  ebx

    mov  esp, ebp
    pop  ebp
    ret

; ===========================================================================
; parse_cmdline(out_buf, buf_size)
;
;   Analyse la ligne de commande Windows et extrait le premier argument
;   après le nom du programme.  Gère les guillemets autour du programme.
;   Si aucun argument, écrit "" dans out_buf (chaîne vide → sera remplacée
;   par le répertoire courant dans start).
; ===========================================================================
parse_cmdline:
    push ebp
    mov  ebp, esp
    push esi
    push edi

    mov  edi, [ebp + 8]     ; out_buf
    ; Initialiser out_buf à chaîne vide
    mov  byte ptr [edi], 0

    call GetCommandLineA
    mov  esi, eax           ; esi pointe sur la ligne de commande complète

    ; --- Sauter le nom du programme ---
    ; Deux cas : "prog.exe" arg   ou   prog.exe arg
    cmp  byte ptr [esi], '"'
    jne  @@skip_no_quote

    ; Sauter jusqu'au guillemet fermant
    inc  esi
@@skip_quoted:
    mov  al, [esi]
    cmp  al, 0
    je   @@no_arg
    inc  esi
    cmp  al, '"'
    jne  @@skip_quoted
    jmp  @@skip_spaces

@@skip_no_quote:
    ; Sauter jusqu'au premier espace ou fin
@@skip_token:
    mov  al, [esi]
    cmp  al, 0
    je   @@no_arg
    cmp  al, ' '
    je   @@skip_spaces
    inc  esi
    jmp  @@skip_token

@@skip_spaces:
    mov  al, [esi]
    cmp  al, ' '
    jne  @@copy_arg
    inc  esi
    jmp  @@skip_spaces

@@copy_arg:
    ; Copier l'argument dans out_buf (sans guillemets éventuels)
    cmp  byte ptr [esi], '"'
    jne  @@copy_loop
    inc  esi                ; sauter le guillemet ouvrant

@@copy_loop:
    mov  al, [esi]
    cmp  al, 0
    je   @@copy_done
    cmp  al, '"'
    je   @@copy_done
    cmp  al, ' '
    je   @@copy_done
    mov  [edi], al
    inc  esi
    inc  edi
    jmp  @@copy_loop

@@copy_done:
    mov  byte ptr [edi], 0
    jmp  @@parse_done

@@no_arg:
    mov  byte ptr [edi], 0  ; out_buf reste vide

@@parse_done:
    pop  edi
    pop  esi
    pop  ebp
    ret

; ===========================================================================
; Point d'entrée
; ===========================================================================
.data
    path_buf db 260 dup(0)

.code
start:
    ; --- Récupérer l'argument de la ligne de commande ---
    push 260
    push offset path_buf
    call parse_cmdline
    add  esp, 8

    ; --- Si path_buf est vide, utiliser le répertoire courant ---
    cmp  byte ptr [path_buf], 0
    jne  @@has_path

    push offset path_buf    ; lpBuffer  (2e param → poussé en premier)
    push 260                ; nBufferLength (1er param → poussé en dernier)
    call GetCurrentDirectoryA
    cmp  eax, 0
    jne  @@has_path

    ; Erreur GetCurrentDirectory
    push offset str_cwd_err
    push offset fmt_entry
    call crt_printf
    add  esp, 8
    push 1
    call ExitProcess

@@has_path:
    ; --- Lancer l'exploration récursive ---
    push offset path_buf
    call explore
    add  esp, 4

    push 0
    call ExitProcess

end start