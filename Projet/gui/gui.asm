.386
.model flat, stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\user32.inc

includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\user32.lib

BUF_SIZE equ 520
WIN32_FIND_DATA_SIZE equ 592
CFILENAME_OFFSET equ 44

.data
className db "MyDirApp",0
windowName db "DIR GUI",0
emptyStr db 0

btnText db "Scanner",0
editClass db "EDIT",0
btnClass db "BUTTON",0

newline db 13,10,0
path_buf db 260 dup(0)

hInstance dd 0
hEdit dd 0
hInput dd 0

wc WNDCLASSEX <>
msg MSG <>

str_star db "\*.*",0
str_slash db "\",0

.code

; ================= strcpy =================
my_strcpy:
    push esi
    push edi
    mov edi,[esp+12]
    mov esi,[esp+16]
cpy:
    mov al,[esi]
    mov [edi],al
    inc esi
    inc edi
    test al,al
    jnz cpy
    pop edi
    pop esi
    ret

; ================= strcat =================
my_strcat:
    push esi
    push edi
    mov edi,[esp+12]
    mov esi,[esp+16]

find_end:
    cmp byte ptr [edi],0
    je append
    inc edi
    jmp find_end

append:
    mov al,[esi]
    mov [edi],al
    inc esi
    inc edi
    test al,al
    jnz append

    pop edi
    pop esi
    ret

; ================= explore =================
LOCAL_HFIND equ -4
LOCAL_FINDDATA equ -(4 + WIN32_FIND_DATA_SIZE)
LOCAL_SEARCHBUF equ -(4 + WIN32_FIND_DATA_SIZE + BUF_SIZE)
LOCAL_CHILDBUF equ -(4 + WIN32_FIND_DATA_SIZE + 2*BUF_SIZE)
LOCAL_TOTAL equ 4 + WIN32_FIND_DATA_SIZE + 2*BUF_SIZE

explore:
    push ebp
    mov ebp,esp
    sub esp, LOCAL_TOTAL

    push esi
    push edi

    lea eax,[ebp+LOCAL_SEARCHBUF]
    push [ebp+8]
    push eax
    call my_strcpy
    add esp,8

    lea eax,[ebp+LOCAL_SEARCHBUF]
    push offset str_star
    push eax
    call my_strcat
    add esp,8

    lea eax,[ebp+LOCAL_FINDDATA]
    push eax
    lea eax,[ebp+LOCAL_SEARCHBUF]
    push eax
    call FindFirstFileA
    mov [ebp+LOCAL_HFIND],eax

    cmp eax, INVALID_HANDLE_VALUE
    je end_exp

loop_exp:
    lea esi,[ebp+LOCAL_FINDDATA+CFILENAME_OFFSET]

    ; skip . ..
    cmp byte ptr [esi],'.'
    je next

    lea eax,[ebp+LOCAL_CHILDBUF]
    push [ebp+8]
    push eax
    call my_strcpy
    add esp,8

    lea eax,[ebp+LOCAL_CHILDBUF]
    push offset str_slash
    push eax
    call my_strcat
    add esp,8

    lea eax,[ebp+LOCAL_CHILDBUF]
    push esi
    push eax
    call my_strcat
    add esp,8

    ; display
    lea eax,[ebp+LOCAL_CHILDBUF]
    push eax
    push 0
    push EM_REPLACESEL
    push hEdit
    call SendMessageA

    push offset newline
    push 0
    push EM_REPLACESEL
    push hEdit
    call SendMessageA

    ; recursion
    mov eax,[ebp+LOCAL_FINDDATA]
    and eax, FILE_ATTRIBUTE_DIRECTORY
    cmp eax,0
    je next

    lea eax,[ebp+LOCAL_CHILDBUF]
    push eax
    call explore
    add esp,4

next:
    lea eax,[ebp+LOCAL_FINDDATA]
    push eax
    push [ebp+LOCAL_HFIND]
    call FindNextFileA
    test eax,eax
    jnz loop_exp

    push [ebp+LOCAL_HFIND]
    call FindClose

end_exp:
    pop edi
    pop esi
    mov esp,ebp
    pop ebp
    ret

; ================= thread =================
thread_func:
    push ebp
    mov ebp,esp

    push offset path_buf
    call explore
    add esp,4

    push 0
    call ExitThread

; ================= WndProc =================
WndProc:
    push ebp
    mov ebp,esp

    mov eax,[ebp+12]

    cmp eax,WM_CREATE
    je wm_create

    cmp eax,WM_COMMAND
    je wm_command

    cmp eax,WM_DESTROY
    je wm_destroy

def:
    push [ebp+20]
    push [ebp+16]
    push [ebp+12]
    push [ebp+8]
    call DefWindowProcA
    jmp finish

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
    push WS_CHILD or WS_VISIBLE or WS_BORDER
    push offset emptyStr      ; window name
    push offset editClass     ; "EDIT"
    push 0                    ; exstyle
    call CreateWindowExA

    mov hInput,eax

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
    push 0
    push hInstance
    push 2
    push [ebp+8]
    push 400
    push 760
    push 50
    push 10
    push WS_CHILD or WS_VISIBLE or WS_BORDER or ES_MULTILINE or WS_VSCROLL
    push offset emptyStr
    push offset editClass
    push WS_EX_CLIENTEDGE
    call CreateWindowExA

    mov hEdit,eax

    xor eax,eax
    jmp finish

wm_command:
    mov eax,[ebp+16]
    and eax,0FFFFh
    cmp eax,1
    jne def

    push 260
    push offset path_buf
    push hInput
    call GetWindowTextA

    push 0
    push 0
    push WM_SETTEXT
    push hEdit
    call SendMessageA

    push 0
    push 0
    push 0
    push offset thread_func
    push 0
    push 0
    call CreateThread

    xor eax,eax
    jmp finish

wm_destroy:
    push 0
    call PostQuitMessage
    xor eax,eax

finish:
    mov esp,ebp
    pop ebp
    ret 16

; ================= start =================
start:

    call GetModuleHandleA
    mov hInstance,eax

    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc
    mov wc.cbClsExtra,0
    mov wc.cbWndExtra,0
    mov eax,hInstance
    mov wc.hInstance,eax
    mov wc.hbrBackground,COLOR_WINDOW+1
    mov wc.lpszClassName, OFFSET className
    mov wc.hCursor,0
    mov wc.hIcon,0
    mov wc.lpszMenuName,0
    mov wc.hIconSm,0

    push offset wc
    call RegisterClassExA

    push 0
    push hInstance
    push 0
    push 0
    push 500
    push 800
    push CW_USEDEFAULT
    push CW_USEDEFAULT
    push WS_OVERLAPPEDWINDOW
    push OFFSET windowName
    push OFFSET className
    push 0
    call CreateWindowExA

    mov ebx,eax

    push 1
    push ebx
    call ShowWindow

    push ebx
    call UpdateWindow

msg_loop:
    push 0
    push 0
    push 0
    push offset msg
    call GetMessageA

    cmp eax,0
    je exit

    push offset msg
    call TranslateMessage

    push offset msg
    call DispatchMessageA

    jmp msg_loop

exit:
    push 0
    call ExitProcess

end start