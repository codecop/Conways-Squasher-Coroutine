bits 32

%define NULL    dword 0

card_len equ    80

        section .bss

switch: resd    1                       ; module global data for SQUASHER
%define ON      dword 1
%define OFF     dword 0

i:      resd    1                       ; module global data for RDCRD and SQUASHER
card:   resb    card_len                ; module global data for RDCRD and SQUASHER

t1:     resd    1                       ; module global data for SQUASHER
t2:     resd    1                       ; module global data for SQUASHER

numBytes: resd  1                       ; module local data for SQUASHER

out:    resd    1                       ; module global data for SQUASHER, WRITE

; --------------------------------------------------------------------------------
        section .text

        extern  _GetStdHandle@4         ; https://msdn.microsoft.com/en-us/library/windows/desktop/ms683231%28v=vs.85%29.aspx
        extern  _ReadFile@20            ; https://msdn.microsoft.com/en-us/library/windows/desktop/aa365467%28v=vs.85%29.aspx
        extern  _WriteFile@20           ; https://msdn.microsoft.com/en-us/library/windows/desktop/aa365747%28v=vs.85%29.aspx
        extern  _ExitProcess@4          ; https://msdn.microsoft.com/en-us/library/windows/desktop/ms682658%28v=vs.85%29.aspx

; --------------------------------------------------------------------------------
STD_INPUT_HANDLE  equ -10

RDCRD:
        mov     eax, [i]
        cmp     eax, card_len
        jne     .exit

        mov     [i], NULL

        ; read card into card[1:80]

        ; HANDLE GetStdHandle()
        push    STD_INPUT_HANDLE        ; _In_ DWORD nStdHandle
        call    _GetStdHandle@4

        ; BOOL ReadFile()
        push    NULL                    ; _Inout_opt_ LPOVERLAPPED lpOverlapped
        mov     ebx, numBytes
        push    ebx                     ; _Out_opt_   LPDWORD      lpNumberOfBytesRead
        push    dword card_len          ; _In_        DWORD        nNumberOfBytesToRead
        mov     ebx, card
        push    ebx                     ; _Out_       LPVOID       lpBuffer
        push    eax                     ; _In_        HANDLE       hFile
        call    _ReadFile@20

.exit:
        ret

; --------------------------------------------------------------------------------
SQUASHER:
        mov     eax, [switch]
        cmp     eax, OFF
        je      .off
.on:
        mov     eax, [t2]
        mov     [out], eax

        mov     [switch], OFF
        jmp     .exit

.off:
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
        mov     [switch], ON
        jmp     .not_equal_ast

.not_equal_ast:                         ; label 1
        mov     eax, [t1]
        mov     [out], eax

.exit:
        ret

; --------------------------------------------------------------------------------
STD_OUTPUT_HANDLE equ -11

printEbx:
        ; HANDLE GetStdHandle()
        push    STD_OUTPUT_HANDLE       ; _In_ DWORD nStdHandle
        call    _GetStdHandle@4

        ; BOOL WriteFile()
        push    NULL                    ; LPOVERLAPPED lpOverlapped
        mov     ecx, numBytes
        push    ecx                     ; LPDWORD      lpNumberOfBytesWritten
        push    dword 1                 ; DWORD        nNumberOfBytesToWrite
        push    ebx                     ; LPCVOID      lpBuffer
        push    eax                     ; HANDLE       hFile
        call    _WriteFile@20

        ret

; --------------------------------------------------------------------------------
WRITE:
.loop:
        call    SQUASHER

        ; out is output area of SQUASHER and only holds a single byte,
        ; so it can only return a single read element. The look ahead
        ; reads a second element and thus needs a switch to return the
        ; looked "ahead" element on next call.
        mov     ebx, out
        call    printEbx

        mov     eax, [i]
        cmp     eax, card_len
        jne     .loop

        ret

; --------------------------------------------------------------------------------
_exitProgram:
        ; void ExitProcess()
        push    0                       ; UINT uExitCode
        call    _ExitProcess@4

; --------------------------------------------------------------------------------
        global  _main

_main:
        ; set up switch
        mov     [switch], OFF

        ; set up global data
        mov     [i], dword card_len

        call    WRITE

.finished:
        jmp     _exitProgram
