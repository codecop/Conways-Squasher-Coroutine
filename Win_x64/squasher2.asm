bits 64
default rel

%define NULL    qword 0

card_len equ    80

        section .bss

%macro coro 2
        mov     rbx, %%_cnt
        mov     [route_%1], rbx
        jmp     %2
%%_cnt: nop
%endmacro

route_SQUASHER: resq 1                  ; storage of IP, module global data for SQUASHER
route_WRITE:    resq 1                  ; storage of IP, module global data for WRITE

i:      resq    1                       ; module global data for RDCRD and SQUASHER
card:   resb    card_len                ; module global data for RDCRD and SQUASHER

t1:     resq    1                       ; module global data for SQUASHER
t2:     resq    1                       ; module global data for SQUASHER

numBytes: resq  1                       ; module local data for SQUASHER

out:    resq    1                       ; module global data for SQUASHER, WRITE

; --------------------------------------------------------------------------------
        section .text

        extern  GetStdHandle
        extern  ReadFile
        extern  WriteFile
        extern  ExitProcess

; --------------------------------------------------------------------------------
STD_INPUT_HANDLE  equ -10

RDCRD:
        mov     rax, [i]
        cmp     rax, card_len
        jne     .exit

        mov     qword [i], 0

        ; read card into card[1:80]

        ; HANDLE GetStdHandle()
        mov     rcx, STD_INPUT_HANDLE   ; _In_ DWORD nStdHandle
        sub     rsp, 020h               ; Give Win64 API calls room
        call    GetStdHandle
        add     rsp, 020h               ; Restore Stack Pointer

        ; BOOL ReadFile()
        mov     rcx, rax                ; _In_        HANDLE       hFile
        mov     rdx, card               ; _Out_       LPVOID       lpBuffer
        mov     r8, qword card_len      ; _In_        DWORD        nNumberOfBytesToRead
        mov     r9, numBytes            ; _Out_opt_   LPDWORD      numBytes
        push    NULL                    ; _Inout_opt_ LPOVERLAPPED lpOverlapped
        sub     rsp, 020h               ; Give Win64 API calls room
        call    ReadFile
        add     rsp, 028h               ; Restore Stack Pointer

.exit:
        ret

; --------------------------------------------------------------------------------
; router
SQUASHER:
        jmp     [route_SQUASHER]

; coroutine
SQUASHER_CORO:                          ; label 1
        call    RDCRD

        mov     rsi, [i]
        mov     rdi, card
        xor     rax, rax
        mov     al, [rdi + rsi]
        mov     [t1], rax

        inc     rsi
        mov     [i], rsi

        mov     rax, [t1]               ; redundant, value still in register
        cmp     rax, '*'
        jne     .not_equal_ast

.equal_ast:
        call    RDCRD

        mov     rsi, [i]                ; redundant, value still in register
        mov     rdi, card
        xor     rax, rax
        mov     al, [rdi + rsi]
        mov     [t2], rax

        inc     rsi
        mov     [i], rsi

        mov     rax, [t2]               ; redundant, value still in register
        cmp     rax, '*'
        jne     .not_equal_second_ast

.equal_second_ast:
        mov     qword [t1], '^'
        jmp     .not_equal_ast

.not_equal_second_ast:
        mov     rax, [t1]
        mov     [out], rax
        coro    SQUASHER, WRITE

        mov     rax, [t2]
        mov     [out], rax
        coro    SQUASHER, WRITE

        jmp     SQUASHER_CORO

.not_equal_ast:                         ; label 2
        mov     rax, [t1]
        mov     [out], rax
        coro    SQUASHER, WRITE

        jmp     SQUASHER_CORO

; --------------------------------------------------------------------------------
STD_OUTPUT_HANDLE equ -11

printRbx:
        ; HANDLE GetStdHandle()
        mov     rcx, STD_OUTPUT_HANDLE  ; _In_ DWORD nStdHandle
        sub     rsp, 020h               ; Give Win64 API calls room
        call    GetStdHandle
        add     rsp, 020h               ; Restore Stack Pointer

        ; BOOL WriteFile()
        mov     rcx, rax                ; HANDLE       hFile
        mov     rdx, rbx                ; LPCVOID      lpBuffer
        mov     r8, qword 1             ; DWORD        nNumberOfBytesToWrite
        mov     r9, numBytes            ; LPDWORD      lpNumberOfBytesWritten
        push    NULL                    ; LPOVERLAPPED lpOverlapped
        sub     rsp, 020h               ; Give Win64 API calls room
        call    WriteFile
        add     rsp, 028h               ; Restore Stack Pointer

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
        mov     rbx, out
        call    printRbx

        mov     rax, [i]
        cmp     rax, card_len
        jne     .loop

        ret

; --------------------------------------------------------------------------------
_exitProgram:
        ; void ExitProcess()
        mov     rcx, 0                  ; UINT uExitCode
        call    ExitProcess
        xor     rax, rax
        ret

; --------------------------------------------------------------------------------
        global  _main

_main:
        and     rsp, -10h

        ; set up coroutine routers
        mov     rbx, SQUASHER_CORO
        mov     [route_SQUASHER], rbx

        mov     rbx, WRITE_CORO
        mov     [route_WRITE], rbx

        ; set up global data
        mov     qword [i], card_len

        call    WRITE

.finished:
        jmp     _exitProgram
