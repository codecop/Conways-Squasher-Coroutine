bits 32
        ; external functions in system libraries
        extern  _ExitProcess@4          ; https://msdn.microsoft.com/en-us/library/windows/desktop/ms682658%28v=vs.85%29.aspx
        extern  _GetStdHandle@4         ; https://msdn.microsoft.com/en-us/library/windows/desktop/ms683231%28v=vs.85%29.aspx
        extern  _WriteFile@20           ; https://msdn.microsoft.com/en-us/library/windows/desktop/aa365747%28v=vs.85%29.aspx
        extern  _ReadFile@20            ; https://msdn.microsoft.com/en-us/library/windows/desktop/aa365467%28v=vs.85%29.aspx

%define NULL    dword 0

card_len equ    80

        section .bss

%macro coro 2
        lea ebx, [%%_cnt]
        mov [route_%1], ebx
        jmp %2
%%_cnt: nop
%endmacro

route_SQUASHER: resd 1                  ; storage of IP, module global data for SQUASHER
route_WRITE:    resd 1                  ; storage of IP, module global data for WRITE

i:      resd    1                       ; module global data for RDCRD and SQUASHER
card:   resb    card_len                ; module global data for RDCRD and SQUASHER

t1:     resd    1                       ; module global data for SQUASHER
t2:     resd    1                       ; module global data for SQUASHER

bytesRead: resd 1                       ; module local data for SQUASHER

out:    resd    1                       ; module global data for SQUASHER, WRITE

        section .text

; --------------------------------------------------------------------------------
STD_INPUT_HANDLE  equ -10

RDCRD:
        mov     eax, [i]
        cmp     eax, card_len
        jne     .exit

        mov     [i], dword 0

        ; read card into card[1:80]

        ; HANDLE GetStdHandle(_In_ DWORD nStdHandle)
        push    STD_INPUT_HANDLE
        call    _GetStdHandle@4         ; eax fileReadHandle = hstdIn

        ; BOOL ReadFile(fileHandle, buffer, length, &bytes, 0);
        push    NULL                    ; _Inout_opt_ LPOVERLAPPED lpOverlapped
        lea     ebx, [bytesRead]
        push    ebx                     ; _Out_opt_   LPDWORD      bytesRead
        push    dword card_len          ; _In_        DWORD        nNumberOfBytesToRead
        lea     ebx, [card]             ; lpBuffer
        push    ebx                     ; _Out_       LPVOID       lpBuffer
        push    eax                     ; _In_        HANDLE       hFile
        call    _ReadFile@20

.exit:
        ret

; --------------------------------------------------------------------------------
; router
SQUASHER:
        jmp     [route_SQUASHER]

; coroutine
SQUASHER_CORO:                          ; label 1
        call    RDCRD

        mov     esi, [i]
        xor     eax, eax
        mov     al, [card + esi]
        mov     [t1], eax

        inc     esi
        mov     [i], esi

        mov     eax, [t1]               ; redundant, value still in register
        cmp     eax, '*'
        jne     .not_equal_ast

.equal_ast:
        call    RDCRD

        mov     esi, [i]                ; redundant, value still in register
        xor     eax, eax
        mov     al, [card + esi]
        mov     [t2], eax

        inc     esi
        mov     [i], esi

        mov     eax, [t2]               ; redundant, value still in register
        cmp     eax, '*'
        jne     .not_equal_second_ast

.equal_second_ast:
        mov     [t1], dword '^'
        jmp     .not_equal_ast

.not_equal_second_ast:
        mov     eax, [t1]
        mov     [out], eax
        coro    SQUASHER, WRITE

        mov     eax, [t2]
        mov     [out], eax
        coro    SQUASHER, WRITE

        jmp     SQUASHER_CORO

.not_equal_ast:                         ; label 2
        mov     eax, [t1]
        mov     [out], eax
        coro    SQUASHER, WRITE

        jmp     SQUASHER_CORO

; --------------------------------------------------------------------------------
STD_OUTPUT_HANDLE equ -11

printEbx:
        ; `int _getStdOutFileHandle()`
        push    STD_OUTPUT_HANDLE
        call    _GetStdHandle@4

        ; 1 character
        push    NULL            ; LPOVERLAPPED lpOverlapped
        mov     ecx, bytesRead
        push    ecx             ; LPDWORD      lpNumberOfBytesWritten,
        push    dword 1         ; DWORD        nNumberOfBytesToWrite,
        push    ebx             ; LPCVOID      lpBuffer,
        push    eax             ; HANDLE       hFile,
        call    _WriteFile@20

        ret

; --------------------------------------------------------------------------------
; router
WRITE:
        jmp     [route_WRITE]

; coroutine
WRITE_CORO:
.loop:
        coro    WRITE, SQUASHER

        ; out is output area of SQUASHER and only holds a single byte,
        ; so it can only return a single read element. The look ahead
        ; reads a second element and thus needs a switch to return the
        ; looked "ahead" element on next call.
        lea     ebx, [out]
        call    printEbx

        mov     eax, [i]
        cmp     eax, card_len
        jne     .loop

        ret

; --------------------------------------------------------------------------------
_exitProgram:
        push    0
        call    _ExitProcess@4
        hlt                             ; never here

; --------------------------------------------------------------------------------
        global  _main

_main:
        ; set up coroutine routers
        lea     ebx, [SQUASHER_CORO]
        mov     [route_SQUASHER], ebx

        lea     ebx, [WRITE_CORO]
        mov     [route_WRITE], ebx

        ; set up global data
        mov     [i], dword card_len

        call    WRITE

.finished:
        jmp     _exitProgram
