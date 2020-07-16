bits 32

%define NULL    dword 0

card_len equ    80

        section .bss

%macro coro 2
        mov     ebx, %%_cnt
        mov     [route_%1], ebx
        jmp     %2
%%_cnt: nop
%endmacro

route_SQUASHER: resd 1                  ; storage of IP, module global data for SQUASHER
route_WRITE:    resd 1                  ; storage of IP, module global data for WRITE

i:      resd    1                       ; module global data for RDCRD and SQUASHER
card:   resb    card_len                ; module global data for RDCRD and SQUASHER

t1:     resd    1                       ; module global data for SQUASHER
t2:     resd    1                       ; module global data for SQUASHER

out:    resd    1                       ; module global data for SQUASHER, WRITE

        section .text

; --------------------------------------------------------------------------------
SYS_READ equ    3
STDIN   equ     0

RDCRD:
        mov     eax, [i]
        cmp     eax, card_len
        jne     .exit

        mov     [i], NULL

        ; read card into card[1:80]

        push    dword card_len          ; maximum number of bytes to read
        push    dword card              ; buffer to read into
        push    dword STDIN             ; file descriptor
        sub     esp, 4                  ; OS X (and BSD) system calls needs "extra space" on stack
        mov     eax, SYS_READ
        int     0x80
        add     esp, 16

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
SYS_WRITE equ   4
STDOUT  equ     1

printEbx:
        push    dword 1                 ; message length
        push    ebx                     ; message to write
        push    dword STDOUT            ; file descriptor
        sub     esp, 4                  ; OS X (and BSD) system calls needs "extra space" on stack
        mov     eax, SYS_WRITE
        int     0x80
        add     esp, 16

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
        mov     ebx, out
        call    printEbx

        mov     eax, [i]
        cmp     eax, card_len
        jne     .loop

        ret

; --------------------------------------------------------------------------------
SYS_EXIT equ    1

_exitProgram:
        mov     eax, SYS_EXIT
        mov     ebx, 0                  ; return code = 0
        int     0x80

; --------------------------------------------------------------------------------
        global  _main

_main:
        ; set up coroutine routers
        mov     ebx, SQUASHER_CORO
        mov     [route_SQUASHER], ebx

        mov     ebx, WRITE_CORO
        mov     [route_WRITE], ebx

        ; set up global data
        mov     [i], dword card_len

        call    WRITE

.finished:
        jmp     _exitProgram
