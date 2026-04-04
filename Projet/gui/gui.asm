.386
.model flat, stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\user32.inc

includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\user32.lib

BUF_SIZE equ 520                ; taille buffer de chemin
WIN32_FIND_DATA_SIZE equ 592    ; taille structure WIN32_FIND_DATA
CFILENAME_OFFSET equ 44         ; offset champ cFileName

.data
className db "MyDirApp",0   ; nom classe de fenêtre
windowName db "DIR GUI",0   ; titre fenêtre principale
emptyStr db 0               ; chaîne vide pour texte initial des contrôles

btnText db "Scanner",0      ; libelle bouton lancement scan
editClass db "EDIT",0       ; nom classe windows zones de texte
btnClass db "BUTTON",0      ; nom classe windows boutons

newline db 13,10,0      ; séquence CRLF (retour chariot, saut de ligne)
path_buf db 260 dup(0)  ; buffer global pour le chemin saisi

hInstance dd 0  ; handle de l'instance application 
hEdit dd 0      ; handle zone de texte sortie (résultats)
hInput dd 0     ; handle zone de texte entrée (chemin)

wc WNDCLASSEX <>    ; structure classe fenêtre
msg MSG <>          ; structure de message pour boucle messages

str_star db "\*.*",0    ; sufflixe de recherche : tous les fichiers d'un dossier
str_slash db "\",0      ; séparateur de chemin windows

.code

; ================= strcpy =================
; copie source -> destination
my_strcpy:
    push esi            sauvegarde registres utilisés
    push edi
    mov edi,[esp+12]    ; edi = pointeur destination (1er arg)
    mov esi,[esp+16]    ; esi = pointeur source (2e arg)
cpy:
    mov al,[esi]        ; lecture d'un octet dans la source
    mov [edi],al        ; écriture dans la destination
    inc esi             ; avance dans la source (incrément)
    inc edi             ; avance dans la destination (incrément)
    test al,al          ; test si l'octet est nul (fin de chaine)
    jnz cpy             ; si non nul, continue la copie
    pop edi             ; restauration des registres
    pop esi
    ret                 ; retour (octet nul copié = destination terminée)

; ================= strcat =================
; concatène src à la fin de dst
my_strcat:
    push esi            ; sauvegarde des registres
    push edi
    mov edi,[esp+12]    ; edi = pointeur source
    mov esi,[esp+16]    ; esi = pointeur destination

find_end:
    cmp byte ptr [edi],0    ; fin de dst (octet nul) ?
    je append               ; oui --> début d'écriture
    inc edi                 ; non --> avance jusqu'à '\0' de dst
    jmp find_end

append:
    mov al,[esi]        ; lecture d'un octet de src
    mov [edi],al        ; écriture de l'octet à la suite de dst
    inc esi
    inc edi
    test al,al          ; fin de src ?
    jnz append          ; si non, continuer

    pop edi             ; restauration des registres
    pop esi
    ret

; ================= explore =================
; parcourt récursivement un répertoire et affiche tous
; les fichiers/dossiers dans hEdit
LOCAL_HFIND equ -4                                              ; handle FindFirstFile/FindNextFile
LOCAL_FINDDATA equ -(4 + WIN32_FIND_DATA_SIZE)                  ; structure WIN32_FIND_DATA
LOCAL_SEARCHBUF equ -(4 + WIN32_FIND_DATA_SIZE + BUF_SIZE)      ; chemin de recherche
LOCAL_CHILDBUF equ -(4 + WIN32_FIND_DATA_SIZE + 2*BUF_SIZE)     ; chemin complet de l'entrée
LOCAL_TOTAL equ 4 + WIN32_FIND_DATA_SIZE + 2*BUF_SIZE           ; taille totale à réserver

explore:
    push ebp                ; sauvegarde de l'ancien EBP
    mov ebp,esp
    sub esp, LOCAL_TOTAL    ; réservation de l'espace pour les variables locales

    push esi    ; sauvegarde des registres non volatiles
    push edi

    ; construction searchBuf = lpPath + '\*.*'
    lea eax,[ebp+LOCAL_SEARCHBUF]
    push [ebp+8]                    ; src  = lpPath (arg fonction)
    push eax                        ; dst = searchBuf
    call my_strcpy                  ; searchBuf = lpPath
    add esp,8                       ; nettoyage des arguments

    lea eax,[ebp+LOCAL_SEARCHBUF]
    push offset str_star            ; src = '\*.*'
    push eax                        ; dst = searchBuf
    call my_strcat                  ; searchBuf = lpPath + '\*.*'
    add esp,8

    ; énumération répertoire
    lea eax,[ebp+LOCAL_FINDDATA]
    push eax                        ; lpFindFileData : reçoit les infos de la 1ère entrée
    lea eax,[ebp+LOCAL_SEARCHBUF]
    push eax                        ; lpFileName : motif de recherche (ex: "C:\foo\*.*")
    call FindFirstFileA             ; ouverture itérateur ; retourne INVALID_HANDLE_VALUE si échec
    mov [ebp+LOCAL_HFIND],eax       ; sauvegarde handle

    cmp eax, INVALID_HANDLE_VALUE   ; répertoire introuvable ou vide ?
    je end_exp                      ; oui --> quitter

; boucle sur chaque entrée trouvée
loop_exp:
    ; esi pointe sur cFileName dans la structure WIN32_FIND_DATA
    lea esi,[ebp+LOCAL_FINDDATA+CFILENAME_OFFSET]

    ; skip . ..
    cmp byte ptr [esi],'.'  ; nom commence par '.' ?
    je next                 ; oui --> skip

    ; Construction childBuf = lpPath + "\" + cFileName
    lea eax,[ebp+LOCAL_CHILDBUF]
    push [ebp+8]                    ; src = lpPath
    push eax                        ; dst = childBuf
    call my_strcpy                  ; childBuf = lpPath
    add esp,8

    lea eax,[ebp+LOCAL_CHILDBUF]
    push offset str_slash   ; src = '\'
    push eax                ; dst = childBuf
    call my_strcat          ; childBuf = lpPath + '\'
    add esp,8

    lea eax,[ebp+LOCAL_CHILDBUF]
    push esi            ; src = cFileName
    push eax            ; dst = childBuf
    call my_strcat      ; childBuf = lpPath + '\' + cFileName
    add esp,8

    ; affichage chemin complet dans zone texte hEdit
    lea eax,[ebp+LOCAL_CHILDBUF]
    push eax            ; lParam = texte à insérer (childBuf)
    push 0              ; wParam = TRUE
    push EM_REPLACESEL  ; message = remplace la sélection courante par le texte
    push hEdit          ; fenêtre cible = zone de texte de sortie
    call SendMessageA   ; envoi message = le texte apparaît dans hEdit

    push offset newline ; lParam = '\r\n'
    push 0
    push EM_REPLACESEL
    push hEdit
    call SendMessageA   ; saut de ligne après le nom

    ; recursion
    mov eax,[ebp+LOCAL_FINDDATA]        ; Charge dwFileAttributes (1er champ de WIN32_FIND_DATA)
    and eax, FILE_ATTRIBUTE_DIRECTORY   ; Isolation bit "répertoire"
    cmp eax,0                           ; est-ce un répertoire ?
    je next                             ; non = suivant

    lea eax,[ebp+LOCAL_CHILDBUF]
    push eax        ; argument = chemin sous-répertoire
    call explore    ; appel récursif pour descendre dans le sous-répertoire
    add esp,4       ; nettoyage argument

next:
    lea eax,[ebp+LOCAL_FINDDATA]
    push eax                        ; lpFindFileData : reçoit les infos de l'entrée suivante
    push [ebp+LOCAL_HFIND]          ; hFindFile : handle ouvert par FindFirstFileA
    call FindNextFileA              ; Retourne 0 quand il n'y a plus d'entrées
    test eax,eax                    ; Encore des entrées ?
    jnz loop_exp                    ; Oui → reboucle

    ; libération handle recherche
    push [ebp+LOCAL_HFIND]
    call FindClose      ; fermeture itérateur

end_exp:
    pop edi         ; restauration registres sauvegardés
    pop esi
    mov esp,ebp     ; restauration pointeur de pile
    pop ebp
    ret             ; retour à l'appelant

; ================= thread =================
; point d'entrée thread de scan
thread_func:
    push ebp
    mov ebp,esp

    push offset path_buf    ; arg : chemin global saisi
    call explore            ; lancement parcours récursif
    add esp,4               ; nettoyage argument

    push 0                  ; code sortie thread (succès)
    call ExitThread         ; fin thread

; ================= WndProc =================
; fenêtre principale
WndProc:
    push ebp
    mov ebp,esp

    mov eax,[ebp+12]        ; eax = uMsg (ID message)

    cmp eax,WM_CREATE       ; création fenêtre ?
    je wm_create

    cmp eax,WM_COMMAND      ; action sur contrôle ou menu ?
    je wm_command

    cmp eax,WM_DESTROY      ; fermeture fenêtre ?
    je wm_destroy

; message non géré --> traitement par défaut
def:
    push [ebp+20]           ; lParam
    push [ebp+16]           ; wParam
    push [ebp+12]           ; uMsg
    push [ebp+8]            ; hWnd
    call DefWindowProcA     ; traitement windows par défaut
    jmp finish

; création contrôles interface
wm_create:

    ; ================= INPUT =================
    push 0                    ; lpParam
    push hInstance            ; hInstance
    push 100                  ; ID
    push [ebp+8]              ; parent (hWnd)
    push 25                   ; height
    push 500                  ; width
    push 10                   ; y
    push 10                   ; x
    push WS_CHILD or WS_VISIBLE or WS_BORDER    ; style
    push offset emptyStr      ; window name
    push offset editClass     ; "EDIT"
    push 0                    ; exstyle
    call CreateWindowExA      ; création zone de saisie

    mov hInput,eax            ; sauvegarde handle

        ; ================= BOUTON =================
    push 0                    ; lpParam
    push hInstance            ; hInstance
    push 1                    ; ID bouton
    push [ebp+8]              ; parent (fenêtre)
    push 25                   ; height
    push 120                  ; width
    push 10                   ; y
    push 520                  ; x
    push WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON
    push offset btnText       ; "Scanner"
    push offset btnClass      ; "BUTTON"
    push 0                    ; exStyle
    call CreateWindowExA

    ; ================= OUTPUT =================
    ; hEdit
    push 0
    push hInstance
    push 2          ; ID
    push [ebp+8]    ; hWnd parent
    push 400        ; height
    push 760        ; width
    push 50         ; y
    push 10         ; x
    push WS_CHILD or WS_VISIBLE or WS_BORDER or ES_MULTILINE or WS_VSCROLL  ; style
    push offset emptyStr    ; texte initial vide
    push offset editClass   ; class EDIT
    push WS_EX_CLIENTEDGE   ; style étendu : bordure enfoncée
    call CreateWindowExA

    mov hEdit,eax           ; sauvegarde handle

    xor eax,eax             ; retourne 0 --> OK
    jmp finish

; gestion clic bouton
wm_command:
    mov eax,[ebp+16]    ; wParam
    and eax,0FFFFh      ; isolation bits bas (ID contrôle)
    cmp eax,1           ; ID = 1 ?
    jne def             ; Non --> traitement par défaut

    ; récupération du chemin saisi dans hInput
    push 260                ; nMaxCount : taille max buffer
    push offset path_buf    ; lpString : buffer destination
    push hInput             ; hWnd : zone saisie source
    call GetWindowTextA     ; copie du texte de hInput dans path_buf

    ; vide zone de sortie avant nouveau scan
    push 0              ; lParam = ""
    push 0              ; wParam inutilisé
    push WM_SETTEXT     ; Message : définit le texte du contrôle
    push hEdit          ; 
    call SendMessageA   ; effacement du contenu précédent de hEdit

    ; lancement du scan dans un thread séparé
    push 0                      ; lpThreadID : inutile
    push 0                      ; dwCreationFlags : démarre automatiquement
    push 0                      ; lpParameter : pas de paramètre
    push offset thread_func     ; lpStartAddress : point d'entrée du thread
    push 0                      ; dwStackSize : taille par défaut
    push 0                      ; lpThreadAttributes : attributs pas défaut
    call CreateThread           ; création et démarrage du thread

    xor eax,eax     ; retourne 0
    jmp finish

; fermeture appli
wm_destroy:
    push 0                  ; exitCode = 0
    call PostQuitMessage    ; sortie boucle messages
    xor eax,eax             ; retourne 0

finish:
    mov esp,ebp     ; restauration pointeur de pile
    pop ebp
    ret 16          ; retour stdCall : nettoie 4 arguments

; ================= start =================
start:

    call GetModuleHandleA   ; handle instance courante
    mov hInstance,eax       ; sauvegarde variable globale

    mov wc.cbSize, SIZEOF WNDCLASSEX            ; taille de structure
    mov wc.style, CS_HREDRAW or CS_VREDRAW      ; redessine si la fenêtre est redimensionnée
    mov wc.lpfnWndProc, OFFSET WndProc          ; pointeur vers la procédure de fenêtre
    mov wc.cbClsExtra,0                         ; pas d'octets supplémentaires pour la classe
    mov wc.cbWndExtra,0                         ; pas d'octets supplémentaires pour chaque fenêtre
    mov eax,hInstance
    mov wc.hInstance,eax                        ; instance propriétaire de la classe
    mov wc.hbrBackground,COLOR_WINDOW+1         ; couleur de fond : couleur fenêtre système
    mov wc.lpszClassName, OFFSET className      ; nom de la classe : "MyDirApp"
    mov wc.hCursor,0                            ; curseur par défaut hérité
    mov wc.hIcon,0                              ; icône grande
    mov wc.lpszMenuName,0                       ; pas de menu
    mov wc.hIconSm,0                            ; icône petite

    push offset wc
    call RegisterClassExA                       ; enregistrement classe auprès de windows

    ; création fenêtre principale
    push 0                      ; lpParam : données user
    push hInstance              ; hInstance
    push 0                      ; hMenu : pas de menu
    push 0                      ; hWndParent : pas de parent
    push 500                    ; height
    push 800                    ; width
    push CW_USEDEFAULT          ; y
    push CW_USEDEFAULT          ; x
    push WS_OVERLAPPEDWINDOW    ; dwStyle : fenêtre standard
    push OFFSET windowName      ; lpWindowName : titre "DIR GUI"
    push OFFSET className       ; lpClassName : classe "MyDirApp"
    push 0                      ; dwExStyle : pas de style étendu
    call CreateWindowExA        ; création fenêtre eax

    mov ebx,eax                 ; sauvegarde handle fenêtre dans ebx

    ; affichage fenêtre
    push 1                  ; nCmdShow --> affichage normal
    push ebx                ; hWnd
    call ShowWindow         ; rend la fenêtre visible à l'écran

    push ebx
    call UpdateWindow       ; premier dessin forcé

; boucle de messages
msg_loop:
    push 0              ; wMsgFilterMax = 0
    push 0              ; wMsgFilterMin = 0
    push 0              ; hWnd = 0 (tous les messages du thread)
    push offset msg     ; lpMsg : structure MSG à remplir
    call GetMessageA    ; Attend et récupère le prochain message, retourne 0 si WM_QUIT reçu

    cmp eax,0           ; WM_QUIT reçu ?
    je exit             ; oui --> sortie de boucle et fin

    push offset msg
    call TranslateMessage   ; conversion messages clavier virtuels en caractères

    push offset msg
    call DispatchMessageA   ; distribution du message à WndProc

    jmp msg_loop            ; continue la boucle

exit:
    push 0                  ; errorCode 0 (succès)
    call ExitProcess        ; fin processus

end start                   ; indication du point d'entrée à start